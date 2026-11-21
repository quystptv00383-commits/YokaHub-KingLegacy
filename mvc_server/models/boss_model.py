from datetime import datetime, timezone
from .db_connection import SqlDatabase


class BossModel:
    """Model layer handling dbo.BossServers on Microsoft SQL Server."""

    def __init__(self, db: SqlDatabase, ttl_seconds: int = 90):
        self.db = db
        self.ttl_seconds = ttl_seconds

    def cleanup_stale(self) -> int:
        return self.db.execute(
            "DELETE FROM dbo.BossServers WHERE DATEADD(SECOND, ?, UpdatedAt) < SYSUTCDATETIME()",
            (self.ttl_seconds,),
        )

    def upsert_alive_boss(
        self,
        place_id: int,
        job_id: str,
        event_name: str,
        source: str,
        hp_cur: int,
        hp_max: int,
        hp_pct: int,
        p_cur: int,
        p_max: int,
        alive: bool = True,
        executor_name: str = "",
        reported_by: str = "",
    ) -> tuple[bool, int]:
        self.cleanup_stale()
        existing = self.db.query_one(
            "SELECT Id, DiscordNotified FROM dbo.BossServers WHERE PlaceId = ? AND JobId = ? AND EventName = ?",
            (place_id, job_id, event_name),
        )
        if existing:
            self.db.execute(
                """
                UPDATE dbo.BossServers
                SET BossSource = ?, HealthCurrent = ?, HealthMax = ?, HealthPercent = ?,
                    PlayersCurrent = ?, PlayersMax = ?, Alive = ?,
                    ExecutorName = COALESCE(NULLIF(?, N''), ExecutorName),
                    ReportedBy = COALESCE(NULLIF(?, N''), ReportedBy),
                    UpdatedAt = SYSUTCDATETIME()
                WHERE Id = ?
                """,
                (
                    source,
                    hp_cur,
                    hp_max,
                    hp_pct,
                    p_cur,
                    p_max,
                    1 if alive else 0,
                    executor_name,
                    reported_by,
                    existing["Id"],
                ),
            )
            return (existing["DiscordNotified"] == 0), int(existing["Id"])

        row = self.db.query_one(
            """
            INSERT INTO dbo.BossServers
                (PlaceId, JobId, EventName, BossSource, HealthCurrent, HealthMax, HealthPercent,
                 PlayersCurrent, PlayersMax, Alive, ExecutorName, ReportedBy, DiscordNotified, FirstSeenAt, UpdatedAt)
            OUTPUT INSERTED.Id
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULLIF(?, N''), NULLIF(?, N''), 0, SYSUTCDATETIME(), SYSUTCDATETIME())
            """,
            (
                place_id,
                job_id,
                event_name,
                source,
                hp_cur,
                hp_max,
                hp_pct,
                p_cur,
                p_max,
                1 if alive else 0,
                executor_name,
                reported_by,
            ),
        )
        new_id = int(row["Id"]) if row else 0
        return True, new_id

    def mark_discord_notified(self, boss_id: int) -> None:
        if boss_id > 0:
            self.db.execute(
                "UPDATE dbo.BossServers SET DiscordNotified = 1 WHERE Id = ?",
                (boss_id,),
            )

    def get_alive_bosses(self, place_id: int | None = None) -> list[dict]:
        self.cleanup_stale()
        sql = """
            SELECT Id, PlaceId, JobId, EventName, BossSource,
                   HealthCurrent, HealthMax, HealthPercent,
                   PlayersCurrent, PlayersMax, Alive,
                   ExecutorName, ReportedBy, DiscordNotified,
                   DATEDIFF(SECOND, UpdatedAt, SYSUTCDATETIME()) AS AgeSec,
                   UpdatedAt
            FROM dbo.BossServers
            WHERE Alive = 1
        """
        params: tuple = ()
        if place_id:
            sql += " AND PlaceId = ?"
            params = (place_id,)
        sql += " ORDER BY UpdatedAt DESC"
        rows = self.db.query_all(sql, params)
        entries = []
        for r in rows:
            upd = r.get("UpdatedAt")
            upd_ts = (
                int(upd.replace(tzinfo=timezone.utc).timestamp())
                if isinstance(upd, datetime)
                else 0
            )
            entries.append(
                {
                    "id": r["Id"],
                    "placeId": r["PlaceId"],
                    "jobId": r["JobId"],
                    "serverRef": r["JobId"],
                    "eventName": r["EventName"],
                    "source": r["BossSource"],
                    "alive": bool(r["Alive"]),
                    "health": {
                        "current": r["HealthCurrent"],
                        "max": r["HealthMax"],
                        "percent": r["HealthPercent"],
                    },
                    "players": {
                        "current": r["PlayersCurrent"],
                        "max": r["PlayersMax"],
                    },
                    "executor": r.get("ExecutorName") or "YokaHub Client",
                    "reportedBy": r.get("ReportedBy") or "",
                    "ageSec": int(r.get("AgeSec") or 0),
                    "updatedAt": upd_ts,
                }
            )
        return entries

    def clear_all(self) -> int:
        return self.db.execute("DELETE FROM dbo.BossServers")
