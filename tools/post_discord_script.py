# tools/post_discord_script.py
import os
import sys
import json
import datetime
import urllib.request

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CANDIDATE_WEBHOOK_FILES = [
    os.path.join(PROJECT_ROOT, "tools", "webhook_private.txt"),
    os.path.join(PROJECT_ROOT, "webhook_private.txt"),
]
BOSS_API_WEBHOOK_FILE = os.path.join(PROJECT_ROOT, "tools", "webhook_boss_api.txt")

COMPACT_SCRIPT = (
    'loadstring(game:HttpGet("https://gist.githubusercontent.com/quystptv00383-commits/7dde495f53b84afb7cf64c06c15dfe2d/raw/loader.luau?t=" .. os.time()))()'
)

def load_webhook_url(paths=CANDIDATE_WEBHOOK_FILES):
    for path in paths:
        if os.path.exists(path):
            with open(path, "r", encoding="utf-8") as f:
                url = f.read().strip()
            if url.startswith("https://discord.com/api/webhooks/") or url.startswith("https://discordapp.com/api/webhooks/"):
                return url
    return None

def send_embed_webhook(webhook_url: str, username: str, title: str, description: str, footer_text: str, label: str):
    payload = {
        "username": username,
        "embeds": [
            {
                "title": title,
                "description": description,
                "color": 3461096,
                "footer": {"text": footer_text},
            }
        ],
    }
    req = urllib.request.Request(
        webhook_url,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "User-Agent": "YokaHub-ReleaseBot/1.0",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            if resp.status in (200, 204):
                print(f"[+] Discord {label} updated successfully! Status:", resp.status)
                return True
            print(f"[!] Discord {label} webhook returned status:", resp.status)
    except Exception as exc:
        print(f"[!] Failed to post to Discord {label} webhook:", exc)
    return False

def post_boss_detected(boss_name: str, sea_name: str, place_id: int, job_id: str, hp_cur: int, hp_max: int, p_cur: int, p_max: int = 12):
    webhook_url = load_webhook_url([BOSS_API_WEBHOOK_FILE])
    if not webhook_url:
        print("[i] Discord Boss Alert skipped: missing tools/webhook_boss_api.txt.")
        return False

    pct = max(1, min(100, round((hp_cur / hp_max) * 100))) if hp_max > 0 else 100
    quick_join = f'game:GetService("TeleportService"):TeleportToPlaceInstance({place_id}, "{job_id}", game.Players.LocalPlayer)'
    desc = (
        f"```\n🎮 {boss_name}: Alive | ❤️ {hp_cur}/{hp_max} ({pct}%)\n```\n"
        f"**🌐 SERVER**\n"
        f"**Game:** King Legacy ({sea_name})\n"
        f"**Players:** {p_cur}/{p_max}\n\n"
        f"**📌 JobId PC**\n"
        f"```\n{job_id}\n```\n"
        f"**📌 JobId Join Script**\n"
        f"```lua\n{quick_join}\n```"
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
                "footer": {"text": "YokaHub | Auto Detection System"},
            }
        ],
    }
    req = urllib.request.Request(
        webhook_url,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "User-Agent": "YokaHub-BossDetector/1.0",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            if resp.status in (200, 204):
                print("[+] Discord #boss-alert sent successfully! Status:", resp.status)
                return True
            print("[!] Discord #boss-alert webhook returned status:", resp.status)
    except Exception as exc:
        print("[!] Failed to send #boss-alert:", exc)
    return False

def post_update(summary_note: str = ""):
    webhook_url = load_webhook_url()
    if not webhook_url:
        print("[i] Discord Auto-Post skipped: chua co tools/webhook_private.txt (tao file nay voi Webhook URL kenh #script de tu dong gui).")
        return False

    now_str = datetime.datetime.now().strftime("%d/%m/%Y %H:%M")
    note_line = f"\n📌 **Ghi chú phiên bản:** {summary_note}\n" if summary_note else ""
    desc = (
        f"⏰ **Cập nhật lúc:** {now_str} (Đồng bộ Cloud Gist tự động 24/7)\n"
        f"{note_line}\n"
        f"🌐 **HỆ THỐNG API & HOP SERVER MỚI (ĐỘC LẬP 100%):**\n"
        f"• **Độc lập hoàn toàn (Không cần Wukong):** Gỡ phụ thuộc chạy chung Wukong khỏi Loader (vẫn giữ comment dự phòng khi cần).\n"
        f"• **Smart Public Server Hop:** Tự động lấy danh sách server công khai Roblox, lọc phòng còn slot thoáng & ping thấp, chống trùng `JobId` (150s), bay tới đảo kiểm tra boss sống thực tế — săn được cả **Abyssal Tyrant**, **Dragon / Drakenfyr**, **Depth King**, **Hydra**, **Sea King**.\n"
        f"• **Cổng YokaHub Private Boss API (Cloudflare Worker / VPS):** Cho phép nhập URL API riêng + Secret Key & bật chia sẻ Boss sống (Telemetry) ngay tại **Tab 1** để toàn bộ máy/acc cùng hop thẳng phòng Boss.\n"
        f"• **Auto Skills V3 & Fix Hop Liên Tục:** 3 lớp kích hoạt chiêu mượt mà, khóa M1 chống khựng, chờ `Playing` + nạp map chuẩn xác chống hop oan.\n\n"
        f"📜 **SCRIPT RUNNER (CHỈ 1 DÒNG DUY NHẤT — COPY DÁN VÀO EXECUTOR):**\n"
        f"```lua\n{COMPACT_SCRIPT}\n```"
    )
    return send_embed_webhook(
        webhook_url,
        "YokaHub Official",
        "🚀 YOKAHUB KING LEGACY — CẬP NHẬT HỆ THỐNG API & SĂN BOSS ĐỘC LẬP",
        desc,
        "YokaHub Official • Độc Lập 100% • Uy Tín - Mượt Mà 24/7",
        "#script",
    )

if __name__ == "__main__":
    args = sys.argv[1:]
    if len(args) >= 8 and args[0] == "--boss-alert":
        post_boss_detected(args[1], args[2], int(args[3]), args[4], int(args[5]), int(args[6]), int(args[7]), int(args[8]) if len(args) > 8 else 12)
    else:
        note = " ".join(args).strip()
        post_update(note)
