import os
import re

PROJECT_ROOT = r"C:\Users\THIS PC\AppData\Local\Real\scripts\YokaHub_Project"
MODULES_DIR = os.path.join(PROJECT_ROOT, "src", "modules")
ENGINE_FILE = os.path.join(PROJECT_ROOT, "src", "core", "15_loops_engine.luau")
UI_FILE = os.path.join(PROJECT_ROOT, "src", "ui", "04_luna_window.luau")
STATE_FILE = os.path.join(PROJECT_ROOT, "src", "core", "03_config_state.luau")

with open(ENGINE_FILE, "r", encoding="utf-8") as f:
    engine_code = f.read()

with open(UI_FILE, "r", encoding="utf-8") as f:
    ui_code = f.read()

with open(STATE_FILE, "r", encoding="utf-8") as f:
    state_code = f.read()

all_backend_code = engine_code + "\n" + ui_code

controls = []
for fname in sorted(os.listdir(MODULES_DIR)):
    if not fname.endswith(".luau"):
        continue
    fpath = os.path.join(MODULES_DIR, fname)
    with open(fpath, "r", encoding="utf-8") as f:
        content = f.read()

    # Split into control blocks
    pattern = r"(CreateToggle|CreateButton|CreateDropdown|CreateSlider|CreateColorPicker)\s*\(\s*\{"
    indices = [m.start() for m in re.finditer(pattern, content)]
    for i, idx in enumerate(indices):
        end_idx = indices[i+1] if i + 1 < len(indices) else len(content)
        block = content[idx:end_idx]

        m_type = re.search(r"(CreateToggle|CreateButton|CreateDropdown|CreateSlider|CreateColorPicker)", block)
        ctype = m_type.group(1) if m_type else "Unknown"

        m_name = re.search(r'Name\s*=\s*\"([^\"]+)\"', block)
        cname = m_name.group(1) if m_name else "Unknown"

        # Find variables or remotes referenced
        hub_vars = list(set(re.findall(r'hubState\.([a-zA-Z0-9_]+)', block)))
        genv_vars = list(set(re.findall(r'genv\.([a-zA-Z0-9_]+)', block)))
        has_invoke = bool(re.search(r'(InvokeServer|FireServer|Teleport|Destroy|SetAttribute)', block))
        has_callback = "Callback" in block

        # Check if variables are used in engine or ui
        used_vars = []
        unused_vars = []
        for v in (hub_vars + genv_vars):
            if v in engine_code or v in ui_code:
                used_vars.append(v)
            else:
                unused_vars.append(v)

        is_functional = (len(used_vars) > 0) or has_invoke or (ctype == "CreateDropdown" and len(hub_vars) > 0)

        controls.append({
            "module": fname,
            "type": ctype,
            "name": cname,
            "hub_vars": hub_vars,
            "genv_vars": genv_vars,
            "used_vars": used_vars,
            "unused_vars": unused_vars,
            "has_invoke": has_invoke,
            "is_functional": is_functional,
            "block": block[:300]
        })

print(f"Total UI controls scanned across all modules: {len(controls)}")
dead_list = [c for c in controls if not c["is_functional"]]
active_list = [c for c in controls if c["is_functional"]]

print(f"Functional / Connected controls: {len(active_list)}")
print(f"Questionable / Potentially unconnected controls: {len(dead_list)}")

if dead_list:
    print("\n--- LIST OF POTENTIALLY UNCONNECTED CONTROLS ---")
    for d in dead_list:
        print(f"[{d['module']}] {d['type']}: {d['name']}")
        print(f"  Hub vars: {d['hub_vars']} | Genv vars: {d['genv_vars']}")
        print(f"  Snippet: {d['block'][:120]}")
        print()
else:
    print("\nALL CONTROLS ARE FUNCTIONALLY CONNECTED!")
