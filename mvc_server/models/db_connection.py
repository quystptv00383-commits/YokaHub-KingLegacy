import os
import threading
import pyodbc


def pick_sql_driver() -> str:
    installed = [d for d in pyodbc.drivers() if "SQL Server" in d]
    for preferred in (
        "ODBC Driver 18 for SQL Server",
        "ODBC Driver 17 for SQL Server",
        "SQL Server",
    ):
        if preferred in installed:
            return preferred
    if installed:
        return installed[0]
    raise RuntimeError("Khong tim thay ODBC Driver cho Microsoft SQL Server.")


class SqlDatabase:
    """Thread-safe Microsoft SQL Server connection manager + automatic schema bootstrap."""

    def __init__(self, server: str = None, database: str = None):
        self.server = server or os.environ.get("YOKA_SQL_SERVER", "localhost")
        self.database = database or os.environ.get("YOKA_SQL_DB", "YokaHubDB")
        self.driver = pick_sql_driver()
        self._local = threading.local()
        self._init_lock = threading.Lock()
        self._schema_initialized = False

    def _build_conn_str(self, target_db: str) -> str:
        custom = os.environ.get("YOKA_SQL_CONN_STR", "").strip()
        if custom and target_db == self.database:
            return custom
        trust = "TrustServerCertificate=yes;" if "18" in self.driver or "17" in self.driver else ""
        return (
            f"DRIVER={{{self.driver}}};"
            f"SERVER={self.server};"
            f"DATABASE={target_db};"
            f"Trusted_Connection=yes;"
            f"{trust}"
        )

    def ensure_schema(self):
        with self._init_lock:
            if self._schema_initialized:
                return
            master_conn = pyodbc.connect(self._build_conn_str("master"), autocommit=True, timeout=8)
            try:
                cur = master_conn.cursor()
                cur.execute(
                    f"IF DB_ID(N'{self.database}') IS NULL CREATE DATABASE [{self.database}];"
                )
            finally:
                master_conn.close()

            schema_path = os.path.join(
                os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                "database",
                "schema.sql",
            )
            with open(schema_path, "r", encoding="utf-8") as f:
                raw_sql = f.read()

            # Execute non-CREATE-DB batches on YokaHubDB
            conn = pyodbc.connect(self._build_conn_str(self.database), autocommit=True, timeout=8)
            try:
                cur = conn.cursor()
                batches = [b.strip() for b in raw_sql.split("\nGO") if b.strip()]
                for idx, batch in enumerate(batches):
                    if idx < 2 and ("CREATE DATABASE" in batch or batch.upper().startswith("USE ")):
                        continue
                    cur.execute(batch)
                cur.execute("SELECT @@SERVERNAME")
                row = cur.fetchone()
                self.server_name = str(row[0]) if row else self.server
            finally:
                conn.close()
            self._schema_initialized = True

    def get_connection(self) -> pyodbc.Connection:
        self.ensure_schema()
        conn = getattr(self._local, "conn", None)
        if conn is not None:
            try:
                conn.cursor().execute("SELECT 1").fetchone()
                return conn
            except Exception:
                try:
                    conn.close()
                except Exception:
                    pass
                self._local.conn = None

        conn = pyodbc.connect(self._build_conn_str(self.database), autocommit=False, timeout=8)
        self._local.conn = conn
        return conn

    def query_all(self, sql: str, params: tuple = ()) -> list[dict]:
        conn = self.get_connection()
        cur = conn.cursor()
        cur.execute(sql, params)
        cols = [c[0] for c in cur.description] if cur.description else []
        rows = [dict(zip(cols, r)) for r in cur.fetchall()]
        conn.commit()
        return rows

    def query_one(self, sql: str, params: tuple = ()) -> dict | None:
        rows = self.query_all(sql, params)
        return rows[0] if rows else None

    def execute(self, sql: str, params: tuple = ()) -> int:
        conn = self.get_connection()
        cur = conn.cursor()
        try:
            cur.execute(sql, params)
            affected = cur.rowcount
            conn.commit()
            return affected
        except Exception:
            conn.rollback()
            raise
