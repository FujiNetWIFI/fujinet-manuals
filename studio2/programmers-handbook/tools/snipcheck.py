#!/usr/bin/env python3
"""snipcheck.py -- every 1802 example in the text assembles.

Finds every `asm: "..."` argument (the command cards) and every
`asmp("...")` call in parts/*.typ, wraps each snippet in a skeleton that
supplies what examples may lean on -- the runtime at $0400, the handbook's
booklib.inc, scratch variables, the strings and buffers below, and the
labels `failed`, `refused`, `connected` and `done` -- and builds it the way
the programs are built: AS (case-sensitive), checkrom.py, mkst2.py.

Snippets land in listings/snippets/<part>-NN.asm. Prints one line per
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
ASL = os.environ.get("ASL", os.path.expanduser("~/asl/asl"))
TOOLS = os.path.join(L, "runtime", "tools")

HEAD = """        CPU     1802
        INCLUDE "fujinet.inc"
        INCLUDE "s2macro.inc"
        INCLUDE "s2defs.inc"
idx     EQU     V_APP           ; scratch the examples use
cnt     EQU     V_APP+1
ORIGIN  EQU     1802H

        ORG     0400H
        INCLUDE "s2call.inc"
        INCLUDE "fujilib.inc"
        INCLUDE "fujidisp.inc"
        INCLUDE "input.inc"

        ORG     0C00H
        INCLUDE "booklib.inc"

        ORG     1400H           ; the snippet, a page of its own
main:
"""
TAIL = """
failed:
refused:
connected:
done:
sk_hang: BR     sk_hang

        ORG     2400H
path:   DB      "/s2book/", 0
file:   DB      "/s2book/hello.st2", 0
spec:   DB      "/s2book/readme.txt|/s2book/copy.txt", 0
url:    DB      "N:http://127.0.0.1:8766/hello.txt", 0
query:  DB      "/0/name", 0
tz:     DB      "EST5EDT", 0
val:    DB      "HELLO STUDIO II", 0
data:   DB      "HELLO", 0
ssidpw: DB      97 DUP (0)

        S2CLAIM
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

    for m in re.finditer(r'\basm:\s*"|#asmp\(\s*"', src):
        yield lit(m.end() - 1)


def build(name, text):
    os.makedirs(OUT, exist_ok=True)
    asm = os.path.join(OUT, name + ".asm")
    open(asm, "w").write(HEAD + text + TAIL)
    gen = os.path.join(L, "asm", "build", "gen")
    inc = ":".join(os.path.relpath(p, OUT) for p in
                   (os.path.join(L, "asm"), os.path.join(L, "runtime"), gen))
    r = subprocess.run([ASL, "-q", "-U", "-L", "-i", inc, "-o", name + ".p",
                        "-olist", name + ".lst", name + ".asm"],
                       cwd=OUT, capture_output=True, text=True)
    if r.returncode or "error" in r.stdout + r.stderr:
        return (r.stdout + r.stderr).strip()
    for cmd in (["python3", os.path.join(TOOLS, "checkrom.py"), name + ".lst"],
                ["python3", os.path.join(TOOLS, "mkst2.py"), name + ".p", name + ".st2"]):
        r = subprocess.run(cmd, cwd=OUT, capture_output=True, text=True)
        if r.returncode:
            return (r.stdout + r.stderr).strip()
    return None


def main():
    if not os.path.exists(os.path.join(L, "asm", "build", "gen", "bookcfg.inc")):
        subprocess.run([os.path.join(L, "asm", "build.sh"), "hello"], check=True,
                       capture_output=True)
    want = sys.argv[1:]
    n = bad = 0
    for part in sorted(glob.glob(os.path.join(ROOT, "parts", "*.typ"))):
        base = os.path.basename(part)[:-4]
        if want and not any(w in base for w in want):
            continue
        for k, text in enumerate(strings(open(part).read()), 1):
            n += 1
            err = build("%s-%02d" % (base, k), text)
            if err:
                bad += 1
                print("FAIL %s-%02d: %s" % (base, k, err.splitlines()[-1] if err else ""))
                for line in err.splitlines()[:4]:
                    print("    " + line)
    print("snipcheck: %d snippets, %d failed" % (n, bad))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
