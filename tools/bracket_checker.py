# -*- coding: utf-8 -*-
import os
dist_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "dist", "YokaHub.luau")
with open(dist_path, 'r', encoding='utf-8') as f:
    text = f.read()

stack = []
pairs = {')': '(', ']': '[', '}': '{'}
in_string = None
escaped = False
in_comment = False

lines = text.splitlines()
errors = []

for lnum, line in enumerate(lines, 1):
    i = 0
    while i < len(line):
        ch = line[i]
        if in_comment:
            if line[i:i+2] == ']]':
                in_comment = False
                i += 2
                continue
            i += 1
            continue
        if line[i:i+4] == '--[[':
            in_comment = True
            i += 4
            continue
        if line[i:i+2] == '--':
            break
        if in_string:
            if escaped:
                escaped = False
            elif ch == '\\':
                escaped = True
            elif ch == in_string:
                in_string = None
            i += 1
            continue
        else:
            if ch in ('"', "'"):
                in_string = ch
            elif ch in ('(', '[', '{'):
                stack.append((ch, lnum))
            elif ch in (')', ']', '}'):
                if not stack:
                    errors.append(f'Extra closing {ch} at line {lnum}')
                else:
                    top, top_lnum = stack.pop()
                    if top != pairs[ch]:
                        errors.append(f'Mismatched {top} (line {top_lnum}) and {ch} at line {lnum}')
        i += 1

if len(stack) > 0:
    errors.append(f'Remaining open brackets: {len(stack)}')
print('Remaining open brackets:', len(stack))
if stack:
    for op, lnum in stack[-10:]:
        print(f'Unclosed {op} from line {lnum}')
print('Total bracket errors:', len(errors))
if errors:
    for e in errors[:5]:
        print(e)
