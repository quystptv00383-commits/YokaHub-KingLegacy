# tools/sync_gist.py
import urllib.request
import json
import os
import sys

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
token_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "private_token.txt")

token = os.environ.get("GITHUB_TOKEN", "")
if not token and os.path.exists(token_file):
    with open(token_file, "r", encoding="utf-8") as f:
        token = f.read().strip()

if not token:
    print("[-] ERROR: GitHub Token not found in environment or private_token.txt!")
    sys.exit(1)

gist_id = "7dde495f53b84afb7cf64c06c15dfe2d"

files_to_sync = {
    "loader.luau": os.path.join(PROJECT_ROOT, "dist", "loader.luau"),
    "YokaHub.luau": os.path.join(PROJECT_ROOT, "dist", "YokaHub.luau"),
    "YokaHub_Keys.json": r"C:\Users\THIS PC\AppData\Local\Real\workspace\YokaHub_Keys.json",
    "YokaHub_Donators.json": r"C:\Users\THIS PC\AppData\Local\Real\workspace\YokaHub_Donators.json",
}

payload_files = {}

for name, path in files_to_sync.items():
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            payload_files[name] = {"content": f.read()}

req = urllib.request.Request(
    f"https://api.github.com/gists/{gist_id}",
    data=json.dumps({"files": payload_files}).encode("utf-8"),
    headers={
        "Content-Type": "application/json",
        "User-Agent": "Mozilla/5.0",
        "Authorization": f"Bearer {token}"
    },
    method="PATCH"
)

try:
    resp = urllib.request.urlopen(req)
    print("[+] GitHub Gist updated successfully! Status:", resp.status)
except Exception as e:
    print("[-] Cloud sync error:", e)
