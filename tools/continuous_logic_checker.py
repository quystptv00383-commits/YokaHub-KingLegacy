# tools/continuous_logic_checker.py
import time
import os
import sys
import datetime

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(PROJECT_ROOT, "tools"))

from yokahub_deep_auditor import run_deep_audit

LOG_FILE = os.path.join(PROJECT_ROOT, "tools", "audit_live.log")

def main():
    print("[*] Starting YokaHub Continuous Logic & System Auditor daemon...")
    iteration = 0
    while True:
        iteration += 1
        now_str = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        try:
            report = run_deep_audit()
            status_line = (
                f"[{now_str}] Iteration #{iteration} | "
                f"Syntax: {report['syntax']['status']} | "
                f"Logic: {report['logic']['status']} | "
                f"Security: {report['security']['status']} | "
                f"Workers: {report['functions']['verified_workers']}/{report['functions']['total_workers']} | "
                f"Cloud: {'OK' if report['deployment']['cloud_gist_ok'] else 'FAIL'}\n"
            )
            with open(LOG_FILE, "a", encoding="utf-8") as f:
                f.write(status_line)
            print(f"[LIVE AUDIT #{iteration}] {status_line.strip()}", flush=True)
        except Exception as e:
            err_line = f"[{now_str}] Iteration #{iteration} ERROR: {e}\n"
            with open(LOG_FILE, "a", encoding="utf-8") as f:
                f.write(err_line)
            print(err_line.strip(), flush=True)

        time.sleep(60)

if __name__ == "__main__":
    main()
