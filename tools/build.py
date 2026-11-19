# tools/build.py
import os
import sys
import subprocess
import shutil

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIST_DIR = os.path.join(PROJECT_ROOT, "dist")
os.makedirs(DIST_DIR, exist_ok=True)

MODULES_ORDER = [
    os.path.join(PROJECT_ROOT, "src", "core", "01_header.luau"),
    os.path.join(PROJECT_ROOT, "src", "security", "02_gateway.luau"),
    os.path.join(PROJECT_ROOT, "src", "core", "03_config_state.luau"),
    os.path.join(PROJECT_ROOT, "src", "ui", "04_luna_window.luau"),
    os.path.join(PROJECT_ROOT, "src", "modules", "05_tab1_bosshop.luau"),
    os.path.join(PROJECT_ROOT, "src", "modules", "06_tab2_farm.luau"),
    os.path.join(PROJECT_ROOT, "src", "modules", "07_tab3_fruits.luau"),
    os.path.join(PROJECT_ROOT, "src", "modules", "08_tab4_metrics.luau"),
    os.path.join(PROJECT_ROOT, "src", "modules", "09_tab5_utility.luau"),
    os.path.join(PROJECT_ROOT, "src", "modules", "10_tab6_donate_exit.luau"),
    os.path.join(PROJECT_ROOT, "src", "core", "11_loops_engine.luau"),
]

TARGET_DIST = os.path.join(DIST_DIR, "YokaHub.luau")
TARGET_SCRIPTS = r"C:\Users\THIS PC\AppData\Local\Real\scripts\YokaHub.luau"
TARGET_WORKSPACE = r"C:\Users\THIS PC\AppData\Local\Real\workspace\YokaHub.luau"

print("==================================================")
print("       [YOKAHUB BUNDLER & TEAM COMPILER]          ")
print("==================================================")

combined_content = []
total_lines = 0

for idx, mod in enumerate(MODULES_ORDER, start=1):
    if not os.path.exists(mod):
        print(f"[-] ERROR: Missing module file: {mod}")
        sys.exit(1)
    with open(mod, "r", encoding="utf-8") as f:
        mod_text = f.read()
    mod_lines = len(mod_text.splitlines())
    total_lines += mod_lines
    print(f"[{idx:02d}/11] Bundled: {os.path.basename(mod):<30} ({mod_lines:>4} lines)")
    combined_content.append(mod_text)

full_script = "".join(combined_content)

# Write to dist first
with open(TARGET_DIST, "w", encoding="utf-8") as f:
    f.write(full_script)

print("--------------------------------------------------")
print(f"[+] Total Assembly: {total_lines} lines | Size: {len(full_script):,} bytes")
print("[+] Running Syntax & Balance Checkers...")

# Run Bracket Checker
bracket_script = os.path.join(PROJECT_ROOT, "tools", "bracket_checker.py")
b_res = subprocess.run([sys.executable, bracket_script], capture_output=True, text=True)
if b_res.returncode != 0 or "Total bracket errors: 0" not in b_res.stdout:
    print("[-] BRACKET CHECK FAILED!")
    print(b_res.stdout)
    sys.exit(1)
print("[v] Bracket Check: PASSED (0 errors)")

# Run Keyword Checker
keyword_script = os.path.join(PROJECT_ROOT, "tools", "keyword_checker.py")
k_res = subprocess.run([sys.executable, keyword_script], capture_output=True, text=True)
if k_res.returncode != 0 or "Total keyword balance errors: 0" not in k_res.stdout:
    print("[-] KEYWORD BALANCE CHECK FAILED!")
    print(k_res.stdout)
    sys.exit(1)
print("[v] Keyword Balance Check: PASSED (0 errors)")

# Deploy to scripts and workspace
shutil.copyfile(TARGET_DIST, TARGET_SCRIPTS)
shutil.copyfile(TARGET_DIST, TARGET_WORKSPACE)
print("[v] Deployed to Local Real/scripts/YokaHub.luau")
print("[v] Deployed to Local Real/workspace/YokaHub.luau")

# Cloud Sync if requested
if "--sync" in sys.argv:
    print("[*] Synchronizing with GitHub Gist Cloud...")
    sync_script = os.path.join(PROJECT_ROOT, "tools", "sync_gist.py")
    s_res = subprocess.run([sys.executable, sync_script], capture_output=True, text=True)
    print(s_res.stdout.strip())

print("==================================================")
print("  BUILD SUCCESSFUL - READY FOR PRODUCTION / TEST  ")
print("==================================================")
