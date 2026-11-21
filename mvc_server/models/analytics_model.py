import json
import os
from datetime import datetime, timezone
from .db_connection import SqlDatabase


class AnalyticsModel:
    """Model layer handling DropLogs, HunterSessions, HubConfigs, and LicenseKeys in SQL Server."""

    def __init__(self, db: SqlDatabase):
        self.db = db

    def record_drop(
        self,
        player_name: str,
        item_key: str,
        item_name: str,
        category: str,
        delta_count: int,
        total_count: int,
        sea_place_id: int,
        job_id: str = "",
    ) -> int:
        row = self.db.query_one(
            """
            INSERT INTO dbo.DropLogs
                (PlayerName, ItemKey, ItemName, Category, DeltaCount, TotalCount, SeaPlaceId, JobId, DroppedAt)
            OUTPUT INSERTED.Id
            VALUES (?, ?, ?, ?, ?, ?, ?, NULLIF(?, N''), SYSUTCDATETIME())
            """,
            (
                player_name or "Unknown",
                item_key,
                item_name,
                category or "mat",
                max(1, int(delta_count)),
                max(1, int(total_count)),
                int(sea_place_id or 15759515082),
                job_id or "",
            ),
        )
        return int(row["Id"]) if row else 0

    def get_recent_drops(self, limit: int = 40) -> list[dict]:
        rows = self.db.query_all(
            """
            SELECT TOP (?) Id, PlayerName, ItemKey, ItemName, Category,
                   DeltaCount, TotalCount, SeaPlaceId, JobId, DroppedAt
            FROM dbo.DropLogs
            ORDER BY DroppedAt DESC, Id DESC
            """,
            (max(1, min(int(limit), 200)),),
        )
        out = []
        for r in rows:
            dt = r.get("DroppedAt")
            out.append(
                {
                    "id": r["Id"],
                    "playerName": r["PlayerName"],
                    "itemKey": r["ItemKey"],
                    "itemName": r["ItemName"],
                    "category": r["Category"],
                    "deltaCount": r["DeltaCount"],
                    "totalCount": r["TotalCount"],
                    "seaPlaceId": r["SeaPlaceId"],
                    "jobId": r.get("JobId") or "",
                    "droppedAt": dt.strftime("%d/%m %H:%M:%S") if isinstance(dt, datetime) else "",
                }
            )
        return out

    def upsert_session(
        self,
        player_name: str,
        job_id: str,
        place_id: int,
        mode: str,
        hops_count: int,
        start_beli: int,
        cur_beli: int,
        start_gems: int,
        cur_gems: int,
    ) -> None:
        pname = (player_name or "Unknown")[:64]
        existing = self.db.query_one(
            "SELECT PlayerName FROM dbo.HunterSessions WHERE PlayerName = ?",
            (pname,),
        )
        if existing:
            self.db.execute(
                """
                UPDATE dbo.HunterSessions
                SET JobId = NULLIF(?, N''), PlaceId = ?, Mode = ?, HopsCount = ?,
                    StartBeli = ?, CurrentBeli = ?, StartGems = ?, CurrentGems = ?,
                    UpdatedAt = SYSUTCDATETIME()
                WHERE PlayerName = ?
                """,
                (job_id or "", place_id, mode or "off", hops_count, start_beli, cur_beli, start_gems, cur_gems, pname),
            )
        else:
            self.db.execute(
                """
                INSERT INTO dbo.HunterSessions
                    (PlayerName, JobId, PlaceId, Mode, HopsCount, StartBeli, CurrentBeli, StartGems, CurrentGems, StartedAt, UpdatedAt)
                VALUES (?, NULLIF(?, N''), ?, ?, ?, ?, ?, ?, ?, SYSUTCDATETIME(), SYSUTCDATETIME())
                """,
                (pname, job_id or "", place_id, mode or "off", hops_count, start_beli, cur_beli, start_gems, cur_gems),
            )

    def get_sessions(self, limit: int = 20) -> list[dict]:
        rows = self.db.query_all(
            """
            SELECT TOP (?) PlayerName, JobId, PlaceId, Mode, HopsCount,
                   StartBeli, CurrentBeli, StartGems, CurrentGems, UpdatedAt
            FROM dbo.HunterSessions
            ORDER BY UpdatedAt DESC
            """,
            (max(1, min(int(limit), 100)),),
        )
        out = []
        for r in rows:
            dt = r.get("UpdatedAt")
            out.append(
                {
                    "playerName": r["PlayerName"],
                    "jobId": r.get("JobId") or "",
                    "placeId": r["PlaceId"],
                    "mode": r["Mode"],
                    "hopsCount": r["HopsCount"],
                    "beliDelta": int(r["CurrentBeli"]) - int(r["StartBeli"]),
                    "gemsDelta": int(r["CurrentGems"]) - int(r["StartGems"]),
                    "updatedAt": dt.strftime("%H:%M:%S") if isinstance(dt, datetime) else "",
                }
            )
        return out

    def save_config(self, config_key: str, config_obj: dict | str) -> None:
        raw_json = config_obj if isinstance(config_obj, str) else json.dumps(config_obj, ensure_ascii=False)
        existing = self.db.query_one("SELECT ConfigKey FROM dbo.HubConfigs WHERE ConfigKey = ?", (config_key,))
        if existing:
            self.db.execute(
                "UPDATE dbo.HubConfigs SET ConfigJson = ?, UpdatedAt = SYSUTCDATETIME() WHERE ConfigKey = ?",
                (raw_json, config_key),
            )
        else:
            self.db.execute(
                "INSERT INTO dbo.HubConfigs (ConfigKey, ConfigJson, UpdatedAt) VALUES (?, ?, SYSUTCDATETIME())",
                (config_key, raw_json),
            )

    def get_config(self, config_key: str = "default") -> dict | None:
        row = self.db.query_one("SELECT ConfigJson FROM dbo.HubConfigs WHERE ConfigKey = ?", (config_key,))
        if not row:
            return None
        try:
            return json.loads(row["ConfigJson"])
        except Exception:
            return None

    def sync_license_keys_from_file(self, keys_json_path: str) -> int:
        if not os.path.exists(keys_json_path):
            return 0
        with open(keys_json_path, "r", encoding="utf-8") as f:
            kdb = json.load(f)

        items: list[tuple[str, str, str]] = []
        for h in kdb.get("admin_hashes", []):
            items.append((h, "ADMIN", "Admin Hash"))
        for h in kdb.get("lifetime_hashes", []):
            items.append((h, "LIFETIME", "Lifetime VIP Hash"))
        for h in kdb.get("vip_1m_hashes", []):
            items.append((h, "VIP_1M", "1 Month VIP Hash"))
        for h in kdb.get("vip_3m_hashes", []):
            items.append((h, "VIP_3M", "3 Months VIP Hash"))
        if kdb.get("free_hash"):
            items.append((kdb["free_hash"], "FREE", "Daily Free Hash"))
        for h in kdb.get("free_hashes", []):
            items.append((h, "FREE", "Free Hash"))
        vip_map = kdb.get("vip_hashes", {})
        if isinstance(vip_map, dict):
            for h, meta in vip_map.items():
                note = json.dumps(meta, ensure_ascii=False) if isinstance(meta, dict) else str(meta)
                items.append((h, "VIP", note[:250]))

        synced = 0
        for key_hash, tier, note in items:
            ex = self.db.query_one("SELECT KeyHash FROM dbo.LicenseKeys WHERE KeyHash = ?", (key_hash,))
            if ex:
                self.db.execute(
                    "UPDATE dbo.LicenseKeys SET KeyTier = ?, Note = ?, UpdatedAt = SYSUTCDATETIME() WHERE KeyHash = ?",
                    (tier, note, key_hash),
                )
            else:
                self.db.execute(
                    "INSERT INTO dbo.LicenseKeys (KeyHash, KeyTier, IsActive, Note, UpdatedAt) VALUES (?, ?, 1, ?, SYSUTCDATETIME())",
                    (key_hash, tier, note),
                )
            synced += 1
        return synced

    def get_summary_stats(self) -> dict:
        boss_row = self.db.query_one("SELECT COUNT(*) AS C FROM dbo.BossServers WHERE Alive = 1")
        drop_row = self.db.query_one("SELECT COUNT(*) AS C FROM dbo.DropLogs")
        sess_row = self.db.query_one("SELECT COUNT(*) AS C, ISNULL(SUM(HopsCount), 0) AS H FROM dbo.HunterSessions")
        key_row = self.db.query_one("SELECT COUNT(*) AS C FROM dbo.LicenseKeys WHERE IsActive = 1")
        return {
            "aliveBosses": int(boss_row["C"]) if boss_row else 0,
            "totalDrops": int(drop_row["C"]) if drop_row else 0,
            "totalSessions": int(sess_row["C"]) if sess_row else 0,
            "totalHops": int(sess_row["H"]) if sess_row else 0,
            "activeKeys": int(key_row["C"]) if key_row else 0,
        }

    def seed_from_workspace(self, workspace_dir: str) -> None:
        key_row = self.db.query_one("SELECT COUNT(*) AS C FROM dbo.LicenseKeys")
        if not key_row or int(key_row["C"]) == 0:
            self.sync_license_keys_from_file(os.path.join(workspace_dir, "YokaHub_Keys.json"))

        cfg_row = self.db.query_one("SELECT COUNT(*) AS C FROM dbo.HubConfigs WHERE ConfigKey = N'default'")
        state_path = os.path.join(workspace_dir, "YokaHub_State.json")
        if (not cfg_row or int(cfg_row["C"]) == 0) and os.path.exists(state_path):
            with open(state_path, "r", encoding="utf-8") as f:
                self.save_config("default", f.read())

        drop_row = self.db.query_one("SELECT COUNT(*) AS C FROM dbo.DropLogs")
        drops_path = os.path.join(workspace_dir, "YokaHub_Drops.json")
        if (not drop_row or int(drop_row["C"]) == 0) and os.path.exists(drops_path):
            try:
                with open(drops_path, "r", encoding="utf-8") as f:
                    d = json.load(f)
                drops = d.get("drops", {})
                if isinstance(drops, dict):
                    # Seed top 25 historical drops chronologically
                    sorted_items = sorted(
                        drops.items(),
                        key=lambda kv: int(kv[1].get("lastAt") or 0),
                    )[-25:]
                    for k, info in sorted_items:
                        self.record_drop(
                            "WorkspaceSeed",
                            k,
                            str(info.get("name") or k),
                            str(info.get("cat") or "mat"),
                            1,
                            int(info.get("count") or 1),
                            15759515082,
                            "",
                        )
            except Exception:
                pass
