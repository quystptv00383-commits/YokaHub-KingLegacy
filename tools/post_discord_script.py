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
    'loadstring(game:HttpGet("https://gist.githubusercontent.com/quystptv00383-commits/7dde495f53b84afb7cf64c06c15dfe2d/raw/loader.luau?t=" .. os.time()))()\n'
    'loadstring(game:HttpGet("https://api.luarmor.net/files/v4/loaders/aa53ff8c86c6c5711408096c227bbe91.lua"))()'
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
    note_line = f"\n**Nội dung cập nhật:** {summary_note}" if summary_note else ""
    payload = {
        "username": "YokaHub Official",
        "embeds": [
            {
                "title": "🚀 YOKAHUB KING LEGACY — BẢN CẬP NHẬT MỚI NHẤT",
                "description": (
                    f"⏰ **Cập nhật lúc:** {now_str} (Đồng bộ Cloud Gist tự động 24/7)\n\n"
                    f"✨ **NỘI DUNG NÂNG CẤP & TỐI ƯU:**\n"
                    f"• **Săn Sea Event & Boss biển:** Tích hợp trực tiếp cơ chế tự động nhặt rương sự kiện biển (Hydra, Vua Biển, Thuyền Ma, Depth King) sau khi hạ Boss.\n"
                    f"• **Ưu tiên chiến đấu 100%:** Chỉ tập trung diệt Boss khi Boss còn sống, chấm dứt hoàn toàn tình trạng nhặt rương bừa bãi.\n"
                    f"• **Script thu gọn 2 dòng:** Cực kỳ ngắn gọn, tích hợp sẵn YokaHub + Wukong API bổ trợ.\n\n"
                    f"📜 **SCRIPT RUNNER (COPY 2 DÒNG DƯỚI ĐÂY DÁN VÀO EXECUTOR):**\n"
                    f"```lua\n{COMPACT_SCRIPT}\n```"
                ),
                "color": 3461096,
                "footer": {"text": "YokaHub Official • Uy Tín - An Toàn - Mượt Mà 24/7"},
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
