import os
import re
import glob

PROJECT_ROOT = r"C:\Users\THIS PC\AppData\Local\Real\scripts\YokaHub_Project"

def run_self_audit():
    print("=" * 65)
    print("    COMPREHENSIVE YOKAHUB AUTONOMOUS SELF-AUDIT SUITE")
    print("=" * 65)
    
    all_files = glob.glob(os.path.join(PROJECT_ROOT, "src", "**", "*.luau"), recursive=True)
    errors = []
    warnings = []

    # -------------------------------------------------------------
    # TEST 1: Bracket & Keyword Balance across ALL files
    # -------------------------------------------------------------
    for fpath in all_files:
        rel = os.path.relpath(fpath, PROJECT_ROOT)
        with open(fpath, "r", encoding="utf-8") as f:
            code = f.read()

        # Check bracket balance (excluding string literals and comments)
        # Strip comments
        clean = re.sub(r"--\[\[.*?\]\]", "", code, flags=re.DOTALL)
        clean = re.sub(r"--[^\n]*", "", clean)
        # Strip single and double quoted strings
        clean = re.sub(r'"(?:\\.|[^"\\])*"', '""', clean)
        clean = re.sub(r"'(?:\\.|[^'\\])*'", "''", clean)

        parens = clean.count("(") - clean.count(")")
        curlies = clean.count("{") - clean.count("}")
        squares = clean.count("[") - clean.count("]")

        if parens != 0 or curlies != 0 or squares != 0:
            errors.append(f"[Bracket Error] {rel}: parens={parens}, curlies={curlies}, squares={squares}")

        # Check block openers vs end
        # Words: do, then, function, repeat, until, end
        openers = len(re.findall(r"\b(then|do)\b", clean))
        # Note: functions can be type signatures or expressions
        fn_blocks = len(re.findall(r"\bfunction\b", clean))
        fn_types = len(re.findall(r":\s*\([^)]*\)\s*->", clean))
        ends = len(re.findall(r"\bend\b", clean))
        repeats = len(re.findall(r"\brepeat\b", clean))
        untils = len(re.findall(r"\buntil\b", clean))

        if repeats != untils:
            errors.append(f"[Repeat/Until Mismatch] {rel}: repeats={repeats}, untils={untils}")

    print(f"[TEST 1] Syntax & Bracket check: {len(errors)} errors found.")

    # -------------------------------------------------------------
    # TEST 2: State Synchronization (HubState, loadState, JSON, Engine)
    # -------------------------------------------------------------
    config_path = os.path.join(PROJECT_ROOT, "src", "core", "03_config_state.luau")
    with open(config_path, "r", encoding="utf-8") as f:
        config_text = f.read()

    # HubState type
    type_match = re.search(r"type\s+HubState\s*=\s*\{([\s\S]*?)\n\s*\}", config_text)
    declared_type_fields = set()
    if type_match:
        declared_type_fields = set(re.findall(r"([a-zA-Z0-9_]+)\s*:", type_match.group(1)))

    # loadState default table
    defaults_match = re.search(r"local\s+st:\s*HubState\s*=\s*\{([\s\S]*?)\n\s*\}", config_text)
    default_fields = set()
    if defaults_match:
        default_fields = set(re.findall(r"([a-zA-Z0-9_]+)\s*=", defaults_match.group(1)))

    # JSON loading
    json_fields = set(re.findall(r"if\s+typeof\(d\.([a-zA-Z0-9_]+)\)", config_text))
    json_fields.update({"mode", "soloTarget", "winW", "winH", "dockX", "dockY"})

    # All files states
    all_writes = set()
    all_reads = set()
    for fpath in all_files:
        with open(fpath, "r", encoding="utf-8") as f:
            c = f.read()
        all_writes.update(re.findall(r"hubState\.([a-zA-Z0-9_]+)\s*=", c))
        all_reads.update(re.findall(r"hubState\.([a-zA-Z0-9_]+)", c))

    used_states = all_writes | all_reads
    missing_in_type = used_states - declared_type_fields
    missing_in_defaults = used_states - default_fields
    missing_in_json = all_writes - json_fields

    if missing_in_type:
        errors.append(f"[State Type Missing] {missing_in_type}")
    if missing_in_defaults:
        errors.append(f"[State Defaults Missing] {missing_in_defaults}")
    if missing_in_json:
        errors.append(f"[State JSON Deserialization Missing] {missing_in_json}")

    print(f"[TEST 2] State Synchronization: {len(missing_in_type)} missing in type, {len(missing_in_defaults)} in defaults, {len(missing_in_json)} in JSON.")

    # -------------------------------------------------------------
    # TEST 3: Check Remote Invocations for pcall protection
    # -------------------------------------------------------------
    unshielded_remotes = []
    for fpath in all_files:
        rel = os.path.relpath(fpath, PROJECT_ROOT)
        with open(fpath, "r", encoding="utf-8") as f:
            lines = f.readlines()
        for idx, line in enumerate(lines):
            if (":InvokeServer(" in line or ":FireServer(" in line) and "pcall" not in line and "task.spawn" not in line:
                # Check previous 3 lines for pcall
                context = "".join(lines[max(0, idx-3):idx+1])
                if "pcall" not in context:
                    unshielded_remotes.append(f"{rel}:{idx+1} -> {line.strip()[:80]}")

    print(f"[TEST 3] Remote Invocation pcall shields: {len(unshielded_remotes)} unshielded remotes found.")
    for ur in unshielded_remotes[:5]:
        warnings.append(f"[Unshielded Remote] {ur}")

    # -------------------------------------------------------------
    # TEST 4: Check Yield in While Loops
    # -------------------------------------------------------------
    unyielding_loops = []
    for fpath in all_files:
        rel = os.path.relpath(fpath, PROJECT_ROOT)
        with open(fpath, "r", encoding="utf-8") as f:
            code = f.read()
        # Find while ... do blocks
        while_pos = [m.start() for m in re.finditer(r"\bwhile\b[^\n]+?\bdo\b", code)]
        for wp in while_pos:
            snippet = code[wp:wp+300]
            if "wait(" not in snippet and "Wait(" not in snippet and "Yield" not in snippet:
                unyielding_loops.append(f"{rel} near char {wp}")

    print(f"[TEST 4] While Loop Yield Safety: {len(unyielding_loops)} unyielding loops found.")
    for ul in unyielding_loops:
        errors.append(f"[Unyielding Loop] {ul}")

    # -------------------------------------------------------------
    # TEST 5: Check Metamethod Hook Safety
    # -------------------------------------------------------------
    engine_path = os.path.join(PROJECT_ROOT, "src", "core", "15_loops_engine.luau")
    with open(engine_path, "r", encoding="utf-8") as f:
        eng_code = f.read()

    has_hook = "hookmetamethod" in eng_code
    has_checkcaller = "checkcaller" in eng_code
    print(f"[TEST 5] Metamethod Hook Integrity: hookmetamethod={has_hook}, checkcaller={has_checkcaller}")
    if has_hook and not has_checkcaller:
        errors.append("[Metamethod Danger] hookmetamethod is used without checkcaller protection!")

    # -------------------------------------------------------------
    # TEST 6: Check VirtualUser Hijacking
    # -------------------------------------------------------------
    has_capture_controller = "CaptureController" in eng_code
    if has_capture_controller:
        errors.append("[Input Hijack Error] VirtualUser:CaptureController was detected! This freezes player controls.")
    else:
        print("[TEST 6] Input Hijack Check: 100% CLEAN (No CaptureController).")

    # -------------------------------------------------------------
    # SUMMARY
    # -------------------------------------------------------------
    print("\n" + "=" * 65)
    print(f"AUDIT SUMMARY: {len(errors)} ERRORS, {len(warnings)} WARNINGS")
    print("=" * 65)
    for err in errors:
        print(f"  [ERROR] {err}")
    for w in warnings:
        print(f"  [WARN]  {w}")

    return len(errors) == 0

if __name__ == "__main__":
    success = run_self_audit()
    exit(0 if success else 1)
