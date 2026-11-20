# -*- coding: utf-8 -*-
import re
import os

dist_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "dist", "YokaHub.luau")
with open(dist_path, 'r', encoding='utf-8') as f:
    text = f.read()

# Strip multi-line comments
text = re.sub(r'--\[\[.*?\]\]', '', text, flags=re.DOTALL)
# Strip single-line comments
text = re.sub(r'--.*$', '', text, flags=re.MULTILINE)
# Strip strings
text = re.sub(r'"(\\.|[^"])*"', '""', text)
text = re.sub(r"'(\\.|[^'])*'", "''", text)

# Find keywords
# Note: 'for ... do', 'while ... do' each have one 'do', which requires one 'end'.
# 'if ... then' has one 'then', which requires one 'end'. (elseif has 'then' but does not add an extra 'end').
# 'function ... end' requires one 'end'.
# 'repeat ... until' requires one 'until'.

# In Lua:
# Tokens that open a block needing 'end':
# 1. function
# 2. then (from if or elseif) - BUT note: 'if .. then .. elseif .. then .. end' only has ONE 'end'!
# So 'if' opens a block, 'elseif' continues it, 'else' continues it, 'end' closes it!
# 3. do (from 'do', 'while .. do', 'for .. do') opens a block needing 'end'.
# 4. repeat opens a block needing 'until'.

lines = text.splitlines()
stack = []
errors = []

# Tokenize
word_re = re.compile(r'\b(if|then|elseif|else|for|while|do|repeat|until|function|end)\b')

for lnum, line in enumerate(lines, 1):
    for m in word_re.finditer(line):
        kw = m.group(1)
        if kw == 'if':
            stack.append(('if', lnum))
        elif kw == 'then':
            pass # handled with if
        elif kw == 'elseif' or kw == 'else':
            if not stack or stack[-1][0] != 'if':
                errors.append(f"Unexpected '{kw}' at line {lnum}")
        elif kw in ('for', 'while'):
            # will be paired with 'do'
            pass
        elif kw == 'do':
            stack.append(('do', lnum))
        elif kw == 'function':
            stack.append(('function', lnum))
        elif kw == 'repeat':
            stack.append(('repeat', lnum))
        elif kw == 'until':
            if not stack or stack[-1][0] != 'repeat':
                errors.append(f"Unexpected 'until' at line {lnum}")
            else:
                stack.pop()
        elif kw == 'end':
            if not stack:
                errors.append(f"Extra 'end' at line {lnum}")
            else:
                top, top_lnum = stack.pop()
                if top not in ('if', 'do', 'function'):
                    errors.append(f"Mismatched end for {top} (line {top_lnum}) at line {lnum}")

print("Remaining unclosed keyword blocks:", len(stack))
if stack:
    for kw, lnum in stack[-10:]:
        print(f"Unclosed '{kw}' from line {lnum}")
print("Total keyword balance errors:", len(errors))
if errors:
    for e in errors[:5]:
        print(e)
