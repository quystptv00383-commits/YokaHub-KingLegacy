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

COMPACT_SCRIPT = (
    'loadstring(game:HttpGet("https://gist.githubusercontent.com/quystptv00383-commits/7dde495f53b84afb7cf64c06c15dfe2d/raw/loader.luau?t=" .. os.time()))()'
)

def load_webhook_url():
    for path in CANDIDATE_WEBHOOK_FILES:
        if os.path.exists(path):
            with open(path, "r", encoding="utf-8") as f:
                url = f.read().strip()
            if url.startswith("https://discord.com/api/webhooks/") or url.startswith("https://discordapp.com/api/webhooks/"):
                return url
    return None

def post_update(summary_note: str = ""):
    webhook_url = load_webhook_url()
    if not webhook_url:
        print("[i] Discord Auto-Post skipped: chua co tools/webhook_private.txt (tao file nay voi Webhook URL kenh #script de tu dong gui).")
        return False

    now_str = datetime.datetime.now().strftime("%d/%m/%Y %H:%M")
    note_line = f"\n📌 **Ghi chú phiên bản:** {summary_note}\n" if summary_note else ""
    payload = {
        "username": "YokaHub Official",
        "embeds": [
            {
                "title": "🚀 YOKAHUB KING LEGACY — CẬP NHẬT HỆ THỐNG API & SĂN BOSS ĐỘC LẬP",
                "description": (
                    f"⏰ **Cập nhật lúc:** {now_str} (Đồng bộ Cloud Gist tự động 24/7)\n"
                    f"{note_line}\n"
                    f"🌐 **HỆ THỐNG API & HOP SERVER MỚI (ĐỘC LẬP 100%):**\n"
                    f"• **Độc lập hoàn toàn (Không cần Wukong):** Gỡ phụ thuộc chạy chung Wukong khỏi Loader (vẫn giữ comment dự phòng khi cần).\n"
                    f"• **Smart Public Server Hop:** Tự động lấy danh sách server công khai Roblox, lọc phòng còn slot thoáng & ping thấp, chống trùng `JobId` (150s), bay tới đảo kiểm tra boss sống thực tế — săn được cả **Abyssal Tyrant**, **Dragon / Drakenfyr**, **Depth King**, **Hydra**, **Sea King**.\n"
                    f"• **Cổng YokaHub Private Boss API (Cloudflare Worker / VPS):** Cho phép nhập URL API riêng + Secret Key & bật chia sẻ Boss sống (Telemetry) ngay tại **Tab 1** để toàn bộ máy/acc cùng hop thẳng phòng Boss.\n"
                    f"• **Auto Skills V3 & Fix Hop Liên Tục:** 3 lớp kích hoạt chiêu mượt mà, khóa M1 chống khựng, chờ `Playing` + nạp map chuẩn xác chống hop oan.\n\n"
                    f"📜 **SCRIPT RUNNER (CHỈ 1 DÒNG DUY NHẤT — COPY DÁN VÀO EXECUTOR):**\n"
                    f"```lua\n{COMPACT_SCRIPT}\n```"
                ),
                "color": 3461096,
                "footer": {"text": "YokaHub Official • Độc Lập 100% • Uy Tín - Mượt Mà 24/7"},
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
                print("[+] Discord #script updated successfully! Status:", resp.status)
                return True
            print("[!] Discord webhook returned status:", resp.status)
    except Exception as exc:
        print("[!] Failed to post to Discord webhook:", exc)
    return False

if __name__ == "__main__":
    note = " ".join(sys.argv[1:]).strip()
    post_update(note)
