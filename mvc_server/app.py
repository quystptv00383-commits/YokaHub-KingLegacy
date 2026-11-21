import json
import os
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

MVC_ROOT = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(MVC_ROOT)
WORKSPACE_DIR = r"C:\Users\THIS PC\AppData\Local\Real\workspace"

if MVC_ROOT not in sys.path:
    sys.path.insert(0, MVC_ROOT)

from controllers.analytics_controller import AnalyticsController
from controllers.boss_controller import BossController
from controllers.view_controller import ViewController
from models.analytics_model import AnalyticsModel
from models.boss_model import BossModel
from models.db_connection import SqlDatabase


def create_app():
    db = SqlDatabase()
    db.ensure_schema()

    boss_model = BossModel(db, ttl_seconds=90)
    analytics_model = AnalyticsModel(db)
    analytics_model.seed_from_workspace(WORKSPACE_DIR)

    boss_ctrl = BossController(boss_model, PROJECT_ROOT, WORKSPACE_DIR)
    analytics_ctrl = AnalyticsController(db, boss_model, analytics_model, WORKSPACE_DIR)
    view_ctrl = ViewController(analytics_ctrl, os.path.join(MVC_ROOT, "views"))

    api_secret = os.environ.get("YOKA_API_KEY", "").strip()

    class YokaMvcHandler(BaseHTTPRequestHandler):
        protocol_version = "HTTP/1.1"

        def log_message(self, format, *args):
            # Keep console logs clean
            return

        def _send_json(self, status: int, data: dict):
            raw = json.dumps(data, ensure_ascii=False).encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(raw)))
            self.end_headers()
            self.wfile.write(raw)

        def _send_html(self, status: int, html: str):
            raw = html.encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(raw)))
            self.end_headers()
            self.wfile.write(raw)

        def _check_auth(self) -> bool:
            if not api_secret:
                return True
            return (self.headers.get("x-yoka-key") or "").strip() == api_secret

        def _read_json_body(self) -> dict | None:
            try:
                length = int(self.headers.get("Content-Length") or 0)
                if length <= 0 or length > 1048576:
                    return {}
                raw = self.rfile.read(length).decode("utf-8")
                obj = json.loads(raw)
                return obj if isinstance(obj, dict) else {}
            except Exception:
                return None

        def do_OPTIONS(self):
            self.send_response(204)
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
            self.send_header("Access-Control-Allow-Headers", "Content-Type, x-yoka-key")
            self.send_header("Content-Length", "0")
            self.end_headers()

        def do_GET(self):
            parsed = urlparse(self.path)
            path = parsed.path.rstrip("/") or "/"
            qs = parse_qs(parsed.query)

            if path == "/" or path == "/dashboard":
                st, html = view_ctrl.render_dashboard()
                self._send_html(st, html)
                return

            if path == "/api/health":
                st, res = analytics_ctrl.health()
                self._send_json(st, res)
                return

            if not self._check_auth():
                self._send_json(401, {"ok": False, "error": "Unauthorized"})
                return

            if path == "/api/bosses":
                pid = int(qs["placeId"][0]) if "placeId" in qs and qs["placeId"][0].isdigit() else None
                st, res = boss_ctrl.get_bosses(pid)
                self._send_json(st, res)
            elif path == "/api/drops":
                limit = int(qs["limit"][0]) if "limit" in qs and qs["limit"][0].isdigit() else 40
                self._send_json(200, {"ok": True, "drops": analytics_model.get_recent_drops(limit)})
            elif path == "/api/config":
                key = qs["key"][0] if "key" in qs else "default"
                st, res = analytics_ctrl.get_config(key)
                self._send_json(st, res)
            elif path == "/api/dashboard":
                st, res = analytics_ctrl.dashboard_data()
                self._send_json(st, res)
            else:
                self._send_json(404, {"ok": False, "error": "Not found"})

        def do_POST(self):
            if not self._check_auth():
                self._send_json(401, {"ok": False, "error": "Unauthorized"})
                return
            body = self._read_json_body()
            if body is None:
                self._send_json(400, {"ok": False, "error": "Invalid JSON"})
                return

            path = urlparse(self.path).path.rstrip("/")
            if path == "/api/report":
                st, res = boss_ctrl.report_boss(body)
                self._send_json(st, res)
            elif path == "/api/bosses/clear":
                st, res = boss_ctrl.clear_bosses()
                self._send_json(st, res)
            elif path == "/api/drops":
                st, res = analytics_ctrl.record_drop(body)
                self._send_json(st, res)
            elif path == "/api/session":
                st, res = analytics_ctrl.upsert_session(body)
                self._send_json(st, res)
            elif path == "/api/config":
                st, res = analytics_ctrl.save_config(body)
                self._send_json(st, res)
            elif path == "/api/keys/sync":
                st, res = analytics_ctrl.sync_keys()
                self._send_json(st, res)
            else:
                self._send_json(404, {"ok": False, "error": "Not found"})

    return db, YokaMvcHandler


if __name__ == "__main__":
    host = os.environ.get("YOKA_MVC_HOST", "127.0.0.1")
    port = int(os.environ.get("YOKA_MVC_PORT", "8787"))
    db, handler_cls = create_app()
    server = ThreadingHTTPServer((host, port), handler_cls)
    print(f"[+] YokaHub MVC Server connected to SQL Server ({db.server_name} -> {db.database})")
    print(f"[+] Dashboard & API listening on http://{host}:{port}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[+] Shutting down YokaHub MVC Server...")
        server.server_close()
