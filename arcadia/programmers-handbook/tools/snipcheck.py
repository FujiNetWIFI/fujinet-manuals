#!/usr/bin/env python3
"""snipcheck.py -- every 2650 example in the text assembles.

Finds every `asm: "..."` argument (the command cards) and every
`asmp("...")` call in parts/*.typ, puts each in a skeleton that supplies
what examples lean on -- the runtime, the handbook's bookdefs.inc,
booklib.inc and netlib.inc, and the labels DONE and NOCART -- and builds it
as the programs are built: asl, p2bin, mkimage.py, the claim, checkrom.py.

An example may name data of its own (a string, a buffer, a variable) that
the text never shows: the first assembly finds the symbols AS calls
undefined, and the second defines each as a byte of data after the
snippet. Any other complaint is a failure.

Snippets land in listings/snippets/<part>-NN.asm. Prints one line for each
failure with the assembler's complaint; exits 1 if any failed.

    tools/snipcheck.py [part ...]
"""
import glob
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
L = os.path.join(ROOT, "listings")
OUT = os.path.join(L, "snippets")
TOOLS = os.path.join(L, "runtime", "tools")
ASL = os.environ.get("ASL", os.path.expanduser("~/asl/asl"))
P2BIN = os.path.join(os.path.dirname(ASL), "p2bin")

HEAD = """        CPU     2650
        ORG     $0000
        BCTA    UN,START
        DB      $17
        ORG     $0020
        INCLUDE "fujidisp.inc"
        INCLUDE "fujilib.inc"
        INCLUDE "bookdefs.inc"
        INCLUDE "booklib.inc"
        INCLUDE "netlib.inc"
START:
"""
TAIL = """
DONE:
NOCART:
SKHANG: BCTA,UN SKHANG
"""


def strings(src):
    """Yield every snippet: asm: "..." and asmp("...")."""
    def lit(i):
        j, out = i + 1, []
        while src[j] != '"':
            if src[j] == "\\":
                nxt = src[j + 1]
                out.append({"n": "\n", "t": "\t", '"': '"', "\\": "\\"}.get(nxt, nxt))
                j += 2
            else:
                out.append(src[j])
                j += 1
        return "".join(out)
    for m in re.finditer(r'asm:\s*"|asmp\("', src):
        yield lit(m.end() - 1)


def assemble(path):
    d = os.path.dirname(path)
    rel = os.path.relpath(L, d)
    inc = ":".join([os.path.join(rel, "asm"), os.path.join(rel, "runtime"),
                    os.path.join(rel, "asm", "build", "gen")])
    r = subprocess.run([ASL, "-q", "-L", "-i", inc, os.path.basename(path)],
                       cwd=d, capture_output=True, text=True)
    return r.returncode, r.stdout + r.stderr


def known():
    """Every symbol the skeleton's includes define."""
    names = set()
    for f in glob.glob(os.path.join(L, "asm", "*.inc")) + \
            glob.glob(os.path.join(L, "runtime", "*.inc")):
        for line in open(f):
            m = re.match(r"^([A-Za-z_]\w*)(:|\s+(EQU|MACRO)\b)", line, re.I)
            if m:
                names.add(m.group(1).upper())
    return names | {"DONE", "NOCART", "SKHANG", "START"}


REGS = {"R0", "R1", "R2", "R3", "UN", "EQ", "GT", "LT", "Z", "P", "N"}


def undefined(path, log):
    lines = open(path).read().split("\n")
    names = set()
    have = known()
    for m in re.finditer(r"\((\d+)\)([^:\n]*):(\d+): error: symbol undefined", log):
        ln, inmac, col = int(m.group(1)), m.group(2).strip(), int(m.group(3))
        line = lines[ln - 1].split(";")[0]
        if not inmac:
            n = re.match(r"\*?([A-Za-z_][\w]*)", line[col - 1:])
            if n:
                names.add(n.group(1))
            continue
        # inside a macro: the operands of the line that called it
        ops = line.split(None, 2)[-1] if len(line.split()) > 1 else ""
        for t in re.findall(r"[A-Za-z_]\w*", ops):
            if t.upper() not in have and t.upper() not in REGS:
                names.add(t)
    return names


def build(path):
    base = path[:-4]
    subprocess.run([P2BIN, "-q", base + ".p", base + ".flat", "-r", "$0000-$2FFF", "-l", "0"],
                   check=True, capture_output=True)
    subprocess.run([sys.executable, os.path.join(TOOLS, "mkimage.py"), base + ".flat",
                    base + ".bin"], check=True, capture_output=True)
    with open(base + ".bin", "r+b") as f:
        f.seek(0x1CFC)
        f.write(b"FUJI")
    r = subprocess.run([sys.executable, os.path.join(TOOLS, "checkrom.py"), base + ".bin"],
                       capture_output=True, text=True)
    return r.returncode, r.stdout + r.stderr


def main():
    want = sys.argv[1:]
    os.makedirs(OUT, exist_ok=True)
    n = bad = 0
    for part in sorted(glob.glob(os.path.join(ROOT, "parts", "*.typ"))):
        name = os.path.basename(part)[:-4]
        if want and name not in want:
            continue
        for i, snip in enumerate(strings(open(part).read())):
            n += 1
            path = os.path.join(OUT, "%s-%02d.asm" % (name, i + 1))
            body = HEAD + snip + "\n" + TAIL
            open(path, "w").write(body)
            rc, log = assemble(path)
            if rc:
                extra = undefined(path, log)
                if extra:
                    body += "".join("%-8sDB      0\n" % (x + ":") for x in sorted(extra))
                    open(path, "w").write(body)
                    rc, log = assemble(path)
            if rc == 0:
                rc, log = build(path)
            if rc:
                bad += 1
                errs = [l for l in log.splitlines() if "error" in l.lower() or "checkrom" in l]
                print("FAIL %s: %s" % (os.path.relpath(path, ROOT), "; ".join(errs[:3]) or log.strip()[:200]))
    print("snipcheck: %d snippets, %s" % (n, "all assemble" if not bad else "%d failed" % bad))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
