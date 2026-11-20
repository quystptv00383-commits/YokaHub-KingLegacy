import os
import re

PROJECT_ROOT = r"C:\Users\THIS PC\AppData\Local\Real\scripts\YokaHub_Project"
MODULES_DIR = os.path.join(PROJECT_ROOT, "src", "modules")
ENGINE_FILE = os.path.join(PROJECT_ROOT, "src", "core", "15_loops_engine.luau")

with open(ENGINE_FILE, "r", encoding="utf-8") as f:
    engine_code = f.read()

for fname in sorted(os.listdir(MODULES_DIR)):
    if not fname.endswith(".luau"): continue
    fpath = os.path.join(MODULES_DIR, fname)
    with open(fpath, "r", encoding="utf-8") as f:
        content = f.read()
    
    print(f"\n=== MODULE: {fname} ===")
    matches = re.finditer(r'(CreateToggle|CreateButton|CreateDropdown|CreateSlider|CreateParagraph)\s*\(\s*\{', content)
    indices = [m.start() for m in matches]
    for i, idx in enumerate(indices):
        end_idx = indices[i+1] if i + 1 < len(indices) else len(content)
        block = content[idx:end_idx]
        ctype = re.search(r'(CreateToggle|CreateButton|CreateDropdown|CreateSlider|CreateParagraph)', block).group(1)
        m_name = re.search(r'Name\s*=\s*\"([^\"]+)\"|Title\s*=\s*\"([^\"]+)\"', block)
        cname = (m_name.group(1) or m_name.group(2)) if m_name else "Unknown"
        
        # Analyze callback
        cb_match = re.search(r'Callback\s*=\s*function\s*\(([^\)]*)\)(.*?)(end,\s*\}|\}\s*\))', block, re.DOTALL)
        if cb_match:
            cb_body = cb_match.group(2).strip()
            # Check what it modifies or calls
            modifies_hub = re.findall(r'hubState\.([a-zA-Z0-9_]+)\s*=', cb_body)
            modifies_genv = re.findall(r'genv\.([a-zA-Z0-9_]+)\s*=', cb_body)
            calls_fn = re.findall(r'([a-zA-Z0-9_]+)\s*\(', cb_body)
            
            # Check if modifies_hub is in engine_code
            hub_handled = [v for v in modifies_hub if v in engine_code]
            genv_handled = [v for v in modifies_genv if v in engine_code]
            
            print(f"  [{ctype}] {cname}")
            print(f"     Hub vars: {modifies_hub} (Handled in engine: {hub_handled})")
            print(f"     Genv vars: {modifies_genv} (Handled in engine: {genv_handled})")
            if not hub_handled and not genv_handled and not any(f in ['applyMode', 'doExitToGateway', 'safeNotify', 'saveState', 'pickDropdownValue', 'table', 'pcall'] for f in calls_fn):
                print(f"     [!] WARNING: Callback seems to have no backend effect!")
        else:
            print(f"  [{ctype}] {cname} (No callback / display only)")
