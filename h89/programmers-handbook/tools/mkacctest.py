#!/usr/bin/env python3
"""Assemble a keyed-in test program and write what the book prints.

    tools/mkacctest.py test/acctest.asm build

The source is written the way Heath printed listings: octal numbers end in Q,
split-octal addresses in A.  z88dk's z80asm (8080 mode) knows neither, so the
numbers are turned into decimal in a copy with the same line numbers, the copy
is assembled, and the assembler's own listing is read back.  Out comes
build/<name>.json for the book -- one row per listing line, with split-octal
addresses and octal bytes -- and build/<name>.keys, the bytes as typed into the
monitor's Substitute command.  The book never carries a byte the assembler did
not make.
"""
import json
import os
import re
import subprocess
import sys

Z80ASM = os.environ.get("Z80ASM", os.path.expanduser("~/Workspace/z88dk/bin/z88dk-z80asm"))


def split_octal(addr):
    return f"{addr >> 8:03o}.{addr & 0xFF:03o}"


def to_decimal(line):
    """Heath number forms -> decimal, outside quotes and comments."""
    code, sep, comment = line.partition(";")
    out, i = [], 0
    for m in re.finditer(r"'[^']*'|\b([0-7]+)([QqAa])\b", code):
        out.append(code[i:m.start()])
        if m.group(1) is None:
            out.append(m.group(0))                       # a quoted character
        elif m.group(2) in "Qq":
            out.append(str(int(m.group(1), 8)))
        else:                                            # split octal hhhlll
            digits = m.group(1).rjust(6, "0")
            out.append(str(int(digits[:-3], 8) * 256 + int(digits[-3:], 8)))
        i = m.end()
    out.append(code[i:])
    return "".join(out) + sep + comment


def main():
    src, outdir = sys.argv[1], sys.argv[2]
    name = os.path.splitext(os.path.basename(src))[0]
    os.makedirs(outdir, exist_ok=True)
    lines = open(src).read().splitlines()
    work = os.path.join(outdir, name + "_z80asm.asm")
    with open(work, "w") as f:
        # z80asm takes no start address on END; keep the line, drop the word
        f.write("\n".join(re.sub(r"^(\s+)END\b.*", r"\1; END", to_decimal(l), flags=re.I)
                          for l in lines) + "\n")
    subprocess.run([Z80ASM, "-m8080", "-b", "-l", work], check=True)
    lis = open(os.path.join(outdir, name + "_z80asm.lis")).read().splitlines()

    org = None
    for l in lines:
        m = re.match(r"\s+ORG\s+([0-7]+)A", l, re.I)
        if m:
            d = m.group(1).rjust(6, "0")
            org = int(d[:-3], 8) * 256 + int(d[-3:], 8)
    assert org is not None, "no ORG nnnnnnA"

    # The listing is written before linking (relocations are zero there), so
    # it only gives each line's offset and length; the bytes come from the .bin.
    binary = open(os.path.join(outdir, name + "_z80asm.bin"), "rb").read()
    rows, flat = [], []
    for l in lis:
        m = re.match(r"\s*(\d+)\s+([0-9A-Fa-f]{4})\s+((?:[0-9A-Fa-f]{2})+)\s", l + " ")
        n = None
        if m:
            n, off, hexbytes = int(m.group(1)), int(m.group(2), 16), m.group(3)
        else:
            m2 = re.match(r"\s*(\d+)\s", l)
            if not m2:
                continue
            n, off, hexbytes = int(m2.group(1)), None, ""
        if n > len(lines):
            continue
        text = lines[n - 1]
        bs = list(binary[off:off + len(hexbytes) // 2]) if off is not None else []
        addr = org + off if off is not None else None
        if bs:
            for k, b in enumerate(bs):
                flat.append({"addr": split_octal(addr + k), "byte": f"{b:03o}"})
        code, _, comment = text.partition(";")
        label = op = arg = ""
        if code.strip():
            parts = code.split("\t")
            label = parts[0].rstrip(":") if parts[0] else ""
            rest = [p for p in parts[1:] if p.strip()]
            op = rest[0].strip() if rest else ""
            arg = rest[1].strip() if len(rest) > 1 else ""
            if label and not op and ":" not in parts[0] and len(parts) == 1:
                label = parts[0]
        rows.append({
            "line": n,
            "addr": split_octal(addr) if bs else "",
            "bytes": [f"{b:03o}" for b in bs],
            "label": label, "op": op, "arg": arg,
            "comment": comment.strip(),
            "full": text if not code.strip() else "",
        })

    assert len(binary) == len(flat), (len(binary), len(flat))
    # the listing as printed: address, up to three bytes, the source line with
    # its tabs expanded; a long DB carries on over more lines of three
    printed = []
    for r in rows:
        src = lines[r["line"] - 1].expandtabs(8)
        bs = r["bytes"]
        printed.append(f"{r['addr'].replace('.', ''):6s}  {' '.join(bs[:3]):11s}  {src}".rstrip())
        for k in range(3, len(bs), 3):
            printed.append(f"{'':6s}  {' '.join(bs[k:k + 3]):11s}")
    json.dump({"name": name, "org": split_octal(org), "length": len(flat),
               "rows": rows, "flat": flat, "printed": printed},
              open(os.path.join(outdir, name + ".json"), "w"), indent=1)
    with open(os.path.join(outdir, name + ".keys"), "w") as f:
        f.write(" ".join(e["byte"] for e in flat) + "\n")
    print(f"{name}: {len(flat)} bytes at {split_octal(org)}")


if __name__ == "__main__":
    main()
