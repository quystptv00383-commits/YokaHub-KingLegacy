# tools/obfuscate.py
import os
import sys
import secrets
import random


def strip_luau_comments(src: str) -> str:
    """Safely strip Luau comments and excess whitespace without touching string literals."""
    out = []
    n = len(src)
    i = 0

    while i < n:
        ch = src[i]

        # String literals: "..." or '...' or `...`
        if ch in ('"', "'", '`'):
            quote = ch
            out.append(ch)
            i += 1
            while i < n:
                c = src[i]
                out.append(c)
                if c == '\\' and i + 1 < n:
                    out.append(src[i + 1])
                    i += 2
                    continue
                i += 1
                if c == quote:
                    break
            continue

        # Long bracket string: [[...]] or [=[...]=]
        if ch == '[':
            j = i + 1
            while j < n and src[j] == '=':
                j += 1
            if j < n and src[j] == '[':
                eq_count = j - (i + 1)
                close_seq = ']' + ('=' * eq_count) + ']'
                end_idx = src.find(close_seq, j + 1)
                if end_idx != -1:
                    out.append(src[i:end_idx + len(close_seq)])
                    i = end_idx + len(close_seq)
                    continue

        # Comments: --[[ ... ]] or -- ...
        if ch == '-' and i + 1 < n and src[i + 1] == '-':
            if i + 2 < n and src[i + 2] == '[':
                j = i + 3
                while j < n and src[j] == '=':
                    j += 1
                if j < n and src[j] == '[':
                    eq_count = j - (i + 3)
                    close_seq = ']' + ('=' * eq_count) + ']'
                    end_idx = src.find(close_seq, j + 1)
                    if end_idx != -1:
                        i = end_idx + len(close_seq)
                        out.append(' ')
                        continue
            nl = src.find('\n', i + 2)
            if nl == -1:
                break
            out.append('\n')
            i = nl + 1
            continue

        out.append(ch)
        i += 1

    cleaned_lines = []
    for line in ''.join(out).splitlines():
        s = line.strip()
        if s:
            cleaned_lines.append(s)
    return '\n'.join(cleaned_lines)


def modinv_256(a: int) -> int:
    for x in range(1, 256, 2):
        if (a * x) % 256 == 1:
            return x
    raise ValueError(f"No modinv for {a}")


def build_safe_alphabet(rng: random.Random) -> str:
    # Exclude quotes, backslash, brackets, and minus (so '--' never appears in chunks)
    excluded = {'"', "'", '\\', '`', '[', ']', '-'}
    pool = [chr(c) for c in range(33, 127) if chr(c) not in excluded]
    rng.shuffle(pool)
    return ''.join(pool[:85])


def base85_encode(data: bytes, alphabet: str) -> str:
    pad = (4 - (len(data) % 4)) % 4
    padded = data + (b'\x00' * pad)
    chars = []
    a = alphabet
    for i in range(0, len(padded), 4):
        v = (padded[i] << 24) | (padded[i + 1] << 16) | (padded[i + 2] << 8) | padded[i + 3]
        c4 = a[v % 85]; v //= 85
        c3 = a[v % 85]; v //= 85
        c2 = a[v % 85]; v //= 85
        c1 = a[v % 85]; v //= 85
        c0 = a[v % 85]
        chars.append(c0 + c1 + c2 + c3 + c4)
    return ''.join(chars)


def make_obf_ident(rng: random.Random, used: set) -> str:
    while True:
        first = rng.choice(['l', 'I', '_'])
        body = ''.join(rng.choice(['l', 'I', '1', 'O', '0', '_']) for _ in range(rng.randint(8, 12)))
        name = first + body
        if name not in used and not name[0].isdigit():
            used.add(name)
            return name


def obfuscate_luau(source_text: str) -> str:
    rng = random.Random(secrets.randbits(128))
    stripped = strip_luau_comments(source_text)
    raw = stripped.encode('utf-8')
    orig_len = len(raw)

    # 1. Dynamic 32-byte key + affine substitution + rolling state + IEEE-754 exact checksum
    key = [secrets.randbelow(256) for _ in range(32)]
    odd_muls = [x for x in range(3, 255, 2) if x % 5 != 0]
    mul = rng.choice(odd_muls)
    mul_inv = modinv_256(mul)
    add_c = rng.randint(17, 239)
    seed = rng.randint(1000, 60000)

    enc = bytearray(orig_len)
    s = seed
    chk = 5381
    for idx in range(orig_len):
        s = (s * 73 + 199 + idx) & 0xFFFF
        ks = (key[idx & 31] ^ (s & 0xFF) ^ ((s >> 8) & 0xFF)) & 0xFF
        eb = (((raw[idx] ^ ks) * mul) + add_c) & 0xFF
        enc[idx] = eb
        # Max intermediate = 2147483647 * 65599 = 1.408e14 << 2^53 (exact in Luau double!)
        chk = ((chk ^ eb) * 65599) & 0x7FFFFFFF

    # 2. Custom shuffled 85-char alphabet Base85 encoding
    alphabet = build_safe_alphabet(rng)
    encoded = base85_encode(bytes(enc), alphabet)

    chunks = []
    pos = 0
    while pos < len(encoded):
        step = rng.randint(6000, 9500)
        step -= (step % 5)
        chunks.append(encoded[pos:pos + step])
        pos += step

    used_names = set()
    v = lambda: make_obf_ident(rng, used_names)
    v_alpha = v()
    v_map = v()
    v_key = v()
    v_chunks = v()
    v_enc = v()
    v_len = v()
    v_out = v()
    v_state = v()
    v_chk = v()
    v_idx = v()
    v_i = v()
    v_v = v()
    v_b = v()
    v_ks = v()
    v_step = v()
    v_src = v()
    v_fn = v()
    v_bxor = v()
    v_band = v()
    v_rsh = v()
    v_byte = v()
    v_char = v()
    v_tc = v()
    v_usebuf = v()
    v_buf = v()

    key_lua = "{" + ",".join(str(k) for k in key) + "}"
    chunks_lua = "{" + ",".join(f'"{c}"' for c in chunks) + "}"
    add_sub = 256 - add_c

    loader_line = (
        f'return (function() '
        f'local {v_bxor},{v_band},{v_rsh}=bit32.bxor,bit32.band,bit32.rshift '
        f'local {v_byte},{v_char},{v_tc}=string.byte,string.char,table.concat '
        f'local {v_alpha}="{alphabet}" '
        f'local {v_map}=table.create(128,0) '
        f'for {v_i}=1,85 do {v_map}[{v_byte}({v_alpha},{v_i})]={v_i}-1 end '
        f'local {v_key}={key_lua} '
        f'local {v_chunks}={chunks_lua} '
        f'local {v_enc}={v_tc}({v_chunks}) '
        f'local {v_len}={orig_len} '
        f'local {v_usebuf}=(type(buffer)=="table" and type(buffer.create)=="function" and type(buffer.writeu8)=="function" and type(buffer.tostring)=="function") '
        f'local {v_buf}={v_usebuf} and buffer.create({v_len}) or nil '
        f'local {v_out}=(not {v_usebuf}) and table.create({v_len}) or nil '
        f'local {v_state}={seed} '
        f'local {v_chk}=5381 '
        f'local {v_idx}=0 '
        f'local function {v_step}({v_b}) '
        f'if {v_idx}>={v_len} then return end '
        f'{v_chk}={v_band}({v_bxor}({v_chk},{v_b})*65599,2147483647) '
        f'{v_state}={v_band}({v_state}*73+199+{v_idx},65535) '
        f'local {v_ks}={v_band}({v_bxor}({v_bxor}({v_key}[{v_band}({v_idx},31)+1],{v_band}({v_state},255)),{v_band}({v_rsh}({v_state},8),255)),255) '
        f'local dec={v_bxor}({v_band}(({v_b}+{add_sub})*{mul_inv},255),{v_ks}) '
        f'if {v_usebuf} then buffer.writeu8({v_buf},{v_idx},dec) else {v_out}[{v_idx}+1]={v_char}(dec) end '
        f'{v_idx}={v_idx}+1 '
        f'end '
        f'for {v_i}=1,#{v_enc},5 do '
        f'local {v_v}=(((({v_map}[{v_byte}({v_enc},{v_i})]*85+{v_map}[{v_byte}({v_enc},{v_i}+1)])*85+{v_map}[{v_byte}({v_enc},{v_i}+2)])*85+{v_map}[{v_byte}({v_enc},{v_i}+3)])*85+{v_map}[{v_byte}({v_enc},{v_i}+4)]) '
        f'{v_step}({v_band}({v_rsh}({v_v},24),255)) '
        f'{v_step}({v_band}({v_rsh}({v_v},16),255)) '
        f'{v_step}({v_band}({v_rsh}({v_v},8),255)) '
        f'{v_step}({v_band}({v_v},255)) '
        f'end '
        f'if {v_chk}~={chk} then return end '
        f'local {v_src}={v_usebuf} and buffer.tostring({v_buf}) or {v_tc}({v_out}) '
        f'local {v_fn}=loadstring({v_src}) '
        f'if {v_fn} then return {v_fn}() end '
        f'end)()'
    )

    header = "--[[ YokaHub Protected Build | King Legacy | Multi-Layer Encrypted Payload | Unauthorized redistribution prohibited ]]"
    footer = "-- YokaHub Official Protected"
    return f"{header}\n{loader_line}\n{footer}\n"


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python obfuscate.py <input.luau> [output.luau]")
        sys.exit(1)
    inp = sys.argv[1]
    outp = sys.argv[2] if len(sys.argv) >= 3 else inp
    with open(inp, "r", encoding="utf-8") as f:
        src = f.read()
    obf = obfuscate_luau(src)
    with open(outp, "w", encoding="utf-8") as f:
        f.write(obf)
    print(f"[+] Obfuscated {len(src):,} bytes -> {len(obf):,} bytes ({len(obf.splitlines())} lines)")
