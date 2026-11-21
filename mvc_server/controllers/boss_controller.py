import json
import os
import threading
import time
import urllib.request
from models.boss_model import BossModel


class BossController:
    """Controller layer handling live Boss API requests, validation, and Discord alerts."""

    def __init__(self, boss_model: BossModel, project_root: str, workspace_dir: str):
        self.boss_model = boss_model
        self.project_root = project_root
        self.workspace_dir = workspace_dir

    def _load_discord_webhook(self) -> str:
        env_url = os.environ.get("DISCORD_WEBHOOK_URL", "").strip()
        if env_url.startswith("https://discord.com/api/webhooks/") or env_url.startswith("https://discordapp.com/api/webhooks/"):
            return env_url
        for candidate in (
            os.path.join(self.project_root, "tools", "webhook_boss_api.txt"),
            os.path.join(self.workspace_dir, "YokaHub_BossWebhook.txt"),
        ):
            if os.path.exists(candidate):
                try:
                    with open(candidate, "r", encoding="utf-8") as f:
                        u = f.read().strip()
                    if u.startswith("https://discord.com/api/webhooks/") or u.startswith("https://discordapp.com/api/webhooks/"):
                        return u
                except Exception:
                    pass
        return ""

    def _dispatch_discord_async(self, boss_id: int, entry: dict) -> bool:
        dc_url = self._load_discord_webhook()
        if not dc_url:
            return False

        def worker():
            place_id = int(entry["placeId"])
            job_id = str(entry["jobId"])
            sea_label = "Sea 3" if place_id == 15759515082 else ("Sea 2" if place_id == 6381829480 else "Sea 1")
            hp_cur = entry["hpCur"]
            hp_max = entry["hpMax"]
            hp_pct = entry["hpPct"]
            hp_txt = f"{hp_cur}/{hp_max} ({hp_pct}%)" if hp_max > 0 else f"{hp_pct}%"
            quick_join = f'game:GetService("TeleportService"):TeleportToPlaceInstance({place_id}, "{job_id}", game.Players.LocalPlayer)'
            desc = (
                f"```\n🎮 {entry['eventName']}: Alive | ❤️ {hp_txt}\n```\n"
                f"**🌐 SERVER**\n"
                f"**Game:** King Legacy ({sea_label})\n"
                f"**Players:** {entry['pCur']}/{entry['pMax']}\n\n"
                f"**📌 JobId PC**\n"
                f"```\n{job_id}\n```\n"
                f"**📌 JobId Join Script**\n"
                f"```lua\n{quick_join}\n```\n"
                f"**💻 Executor**\n{entry['executor']}"
            )
            payload = {
                "content": job_id,
                "username": "YokaHub Boss Notifier",
                "embeds": [
                    {
                        "author": {"name": "YokaHub Boss Notifier"},
                        "title": "🔥 BOSS DETECTED",
                        "description": desc,
                        "color": 16724787,
                        "footer": {"text": "YokaHub SQL MVC | Auto Detection System"},
                    }
                ],
            }
            req = urllib.request.Request(
                dc_url,
                data=json.dumps(payload).encode("utf-8"),
                headers={"Content-Type": "application/json", "User-Agent": "YokaHub-MVC/1.0"},
                method="POST",
            )
            try:
                with urllib.request.urlopen(req, timeout=10) as resp:
                    if resp.status in (200, 204):
                        self.boss_model.mark_discord_notified(boss_id)
            except Exception:
                pass

        threading.Thread(target=worker, daemon=True).start()
        return True

    def get_bosses(self, place_id: int | None = None) -> tuple[int, dict]:
        entries = self.boss_model.get_alive_bosses(place_id)
        return 200, {
            "ok": True,
            "updatedAt": int(time.time()),
            "count": len(entries),
            "entries": entries,
        }

    def report_boss(self, body: dict) -> tuple[int, dict]:
        try:
            place_id = int(body.get("placeId") or 0)
        except Exception:
            place_id = 0
        job_id = str(body.get("jobId") or body.get("serverRef") or "").strip()
        event_name = str(body.get("eventName") or "").strip()
        if not place_id or not job_id or not event_name:
            return 400, {"ok": False, "error": "Missing placeId, jobId or eventName"}

        health = body.get("health") if isinstance(body.get("health"), dict) else {}
        players = body.get("players") if isinstance(body.get("players"), dict) else {}
        hp_cur = int(health.get("current") or 0)
        hp_max = int(health.get("max") or 0)
        hp_pct = int(health.get("percent") or 100)
        p_cur = int(players.get("current") or 1)
        p_max = int(players.get("max") or 12)
        source = str(body.get("source") or "yoka_sql")[:64]
        executor_name = str(body.get("executor") or "YokaHub Client")[:64]
        reported_by = str(body.get("reportedBy") or "")[:64]
        alive = body.get("alive", True) is not False

        is_new, boss_id = self.boss_model.upsert_alive_boss(
            place_id=place_id,
            job_id=job_id,
            event_name=event_name[:120],
            source=source,
            hp_cur=hp_cur,
            hp_max=hp_max,
            hp_pct=max(0, min(100, hp_pct)),
            p_cur=max(0, p_cur),
            p_max=max(1, p_max),
            alive=alive,
            executor_name=executor_name,
            reported_by=reported_by,
        )

        discord_dispatched = False
        if is_new and alive:
            discord_dispatched = self._dispatch_discord_async(
                boss_id,
                {
                    "placeId": place_id,
                    "jobId": job_id,
                    "eventName": event_name,
                    "hpCur": hp_cur,
                    "hpMax": hp_max,
                    "hpPct": max(0, min(100, hp_pct)),
                    "pCur": p_cur,
                    "pMax": p_max,
                    "executor": executor_name,
                },
            )

        return 200, {
            "ok": True,
            "id": boss_id,
            "isNew": is_new,
            "discordHandledByServer": discord_dispatched,
        }

    def clear_bosses(self) -> tuple[int, dict]:
        deleted = self.boss_model.clear_all()
        return 200, {"ok": True, "deleted": deleted}
