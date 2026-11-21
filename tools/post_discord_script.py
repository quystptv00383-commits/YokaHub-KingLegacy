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

def post_api_announcement(summary_note: str = ""):
    webhook_url = load_webhook_url([BOSS_API_WEBHOOK_FILE])
    if not webhook_url:
        print("[i] Discord Boss API post skipped: missing tools/webhook_boss_api.txt.")
        return False

    now_str = datetime.datetime.now().strftime("%d/%m/%Y %H:%M")
    note_line = f"\n📌 **Ghi chú:** {summary_note}\n" if summary_note else ""
    desc = (
        f"⏰ **Cập nhật lúc:** {now_str} · Phiên bản YokaHub Độc Lập 100%\n"
        f"{note_line}\n"
        f"🌐 **1. HỆ THỐNG HOP SERVER & API ĐỘC LẬP (`YokaNet`):**\n"
        f"• **Không phụ thuộc Wukong:** Đã tách chạy độc lập hoàn toàn (Wukong chỉ giữ comment dự phòng trong Loader).\n"
        f"• **Smart Public Server Hop:** Tự lấy server công khai Roblox, lọc slot thoáng (`2` → `max-2` người) & ping thấp, phân trang chống lặp `JobId` (`150s`), bay kiểm tra đảo/boss thật trước khi hop.\n"
        f"• **YokaHub Private Boss API:** Hỗ trợ gắn Cloudflare Worker / VPS riêng tại **Tab 1** (`Private Boss API URL` + `Secret Key`) + Telemetry tự báo Boss sống về API.\n\n"
        f"🏆 **2. BẢNG ĐỘ ƯU TIÊN SĂN BOSS SEA 3 (API HOP):**\n"
        f"`1.` **Depth King** (10đ) → `2.` **Dragon / Drakenfyr / Sea Dragon** (8đ) → `3.` **Abyssal Tyrant** (6đ) → `4.` **Kraken** (5đ) → `5.` **Serpent** (4đ) → `6.` **Giant Crab** (3đ) → `7.` **Sea Events** (1đ)\n\n"
        f"🐍 **3. BẢNG ĐỘ ƯU TIÊN SĂN BOSS SEA 2 (API HOP):**\n"
        f"`1.` **Rương Hydra** (7đ) → `2.` **Hydra** (6đ) → `3.` **Rương Sea King** (5đ) → `4.` **Sea King** (4đ) → `5.` **Serpent** (3đ) → `6.` **Rương Tàu Ma** (2đ) → `7.` **Tàu Ma** (1đ)\n\n"
        f"📜 **SCRIPT CHẠY 1 DÒNG DUY NHẤT:**\n"
        f"```lua\n{COMPACT_SCRIPT}\n```"
    )
    return send_embed_webhook(
        webhook_url,
        "YokaHub Boss API",
        "🌐 YOKAHUB API & SMART BOSS HOP — THÔNG BÁO HỆ THỐNG MỚI",
        desc,
        "YokaHub Boss API • Độc Lập 100% • Auto Skills V3 • Smart Public Hop",
        "#boss-api",
    )

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
    if "--boss-api" in args:
        note = " ".join(a for a in args if a != "--boss-api").strip()
        post_api_announcement(note)
    else:
        note = " ".join(args).strip()
        post_update(note)
