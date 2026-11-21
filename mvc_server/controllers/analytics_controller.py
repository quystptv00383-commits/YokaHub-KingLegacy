import os
from models.analytics_model import AnalyticsModel
from models.boss_model import BossModel
from models.db_connection import SqlDatabase


class AnalyticsController:
    """Controller layer handling Drops, Sessions, Configs, LicenseKeys, and Health."""

    def __init__(self, db: SqlDatabase, boss_model: BossModel, analytics_model: AnalyticsModel, workspace_dir: str):
        self.db = db
        self.boss_model = boss_model
        self.analytics_model = analytics_model
        self.workspace_dir = workspace_dir

    def health(self) -> tuple[int, dict]:
        row = self.db.query_one("SELECT @@SERVERNAME AS srv, DB_NAME() AS db")
        stats = self.analytics_model.get_summary_stats()
        return 200, {
            "ok": True,
            "engine": "Microsoft SQL Server",
            "serverName": row["srv"] if row else self.db.server,
            "database": row["db"] if row else self.db.database,
            "stats": stats,
        }

    def dashboard_data(self) -> tuple[int, dict]:
        row = self.db.query_one("SELECT @@SERVERNAME AS srv, DB_NAME() AS db")
        return 200, {
            "ok": True,
            "serverName": row["srv"] if row else self.db.server,
            "database": row["db"] if row else self.db.database,
            "stats": self.analytics_model.get_summary_stats(),
            "bosses": self.boss_model.get_alive_bosses(),
            "drops": self.analytics_model.get_recent_drops(35),
            "sessions": self.analytics_model.get_sessions(15),
        }

    def record_drop(self, body: dict) -> tuple[int, dict]:
        item_key = str(body.get("itemKey") or "").strip()
        item_name = str(body.get("itemName") or item_key).strip()
        if not item_key:
            return 400, {"ok": False, "error": "Missing itemKey"}
        new_id = self.analytics_model.record_drop(
            player_name=str(body.get("playerName") or "Unknown")[:64],
            item_key=item_key[:128],
            item_name=item_name[:128],
            category=str(body.get("category") or "mat")[:32],
            delta_count=int(body.get("deltaCount") or 1),
            total_count=int(body.get("totalCount") or 1),
            sea_place_id=int(body.get("seaPlaceId") or 15759515082),
            job_id=str(body.get("jobId") or "")[:64],
        )
        return 200, {"ok": True, "id": new_id}

    def upsert_session(self, body: dict) -> tuple[int, dict]:
        player_name = str(body.get("playerName") or "Unknown").strip()
        self.analytics_model.upsert_session(
            player_name=player_name,
            job_id=str(body.get("jobId") or "")[:64],
            place_id=int(body.get("placeId") or 15759515082),
            mode=str(body.get("mode") or "off")[:32],
            hops_count=int(body.get("hopsCount") or 0),
            start_beli=int(body.get("startBeli") or 0),
            cur_beli=int(body.get("currentBeli") or 0),
            start_gems=int(body.get("startGems") or 0),
            cur_gems=int(body.get("currentGems") or 0),
        )
        return 200, {"ok": True}

    def get_config(self, key: str = "default") -> tuple[int, dict]:
        cfg = self.analytics_model.get_config(key)
        return 200, {"ok": True, "configKey": key, "config": cfg}

    def save_config(self, body: dict) -> tuple[int, dict]:
        key = str(body.get("configKey") or "default")[:64]
        cfg = body.get("config")
        if not isinstance(cfg, dict):
            return 400, {"ok": False, "error": "Invalid config object"}
        self.analytics_model.save_config(key, cfg)
        return 200, {"ok": True, "configKey": key}

    def sync_keys(self) -> tuple[int, dict]:
        cnt = self.analytics_model.sync_license_keys_from_file(
            os.path.join(self.workspace_dir, "YokaHub_Keys.json")
        )
        return 200, {"ok": True, "synced": cnt}
