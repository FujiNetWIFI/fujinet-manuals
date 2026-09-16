#!/usr/bin/env python3
"""snipcheck.py -- every example in the handbook's text assembles or compiles.

Pulls each `asm: "..."` / `bas: "..."` string and each `#pair("...", "...")`
out of the chapter sources, wraps it in a skeleton that supplies the symbols
an excerpt is allowed to assume (the library, a few data labels and cells),
and runs Macroassembler AS or batari Basic over it. A snippet that does not
build fails the check, so nothing in the reference is untested syntax.

    tools/snipcheck.py            # all chapters
    tools/snipcheck.py -v         # show each snippet's verdict
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "listings", "snippets")
AS = os.path.expanduser("~/asl/asl")
if os.system("command -v asl >/dev/null 2>&1") == 0:
    AS = "asl"
BB = os.environ.get("bB", os.path.expanduser("~/Workspace/batari-Basic"))
verbose = "-v" in sys.argv

ASM_HEAD = """        CPU     6502
        INCLUDE "vcs.inc"
PAD3    EQU     $81
SAVSP   EQU     $82
APERR   EQU     $8F
IDX     EQU     $90
WANT    EQU     $91
SECLO   EQU     $92
SECHI   EQU     $93
PAGE0   EQU     $94
        INCLUDE "fujinet.inc"
        INCLUDE "netdefs.inc"
        INCLUDE "devdefs.inc"
        ORG     $1000
START:  sei
        cld
        ldx     #$FF
        txs
        jsr     FNARM
SNIP:
"""
ASM_TAIL = """
FAILED: jmp     FAILED
        jmp     START
SSIDPW: DB      "ssid",0
PATH:   DB      "/game.bin",0
TURL:   DB      "N:https://fujinet.online/",0
MSG:    DB      "HELLO"
MSGE:
TXT:    DB      "HELLO"
TXTE:
LINE:   DB      "A LINE",0
GFIELD  EQU     110
        INCLUDE "fujilib.inc"
        INCLUDE "fujidisp.inc"
APPVBL: rts
FNBARG: rts
FNBLIT: rts
        ORG     $1FFC
        DW      START
        DW      START
        END
"""
BAS_HEAD = """ include fujinet.h
 include fujibas.h
 include netdefs.h
 include devdefs.h
 set romsize 2k
 dim fnseq = a
 dim err = b
 dim dev = c
 dim cmd = d
 dim npar = e
 dim gen = f
 dim tries = g
 dim ch = h
 dim idx = j
 dim rssi = k
 dim avlo = m
 dim avhi = n
 dim want = o
 dim len = p
 dim src = q
 dim seclo = r
 dim sechi = s
 dim page0 = t
 data url
 "N:https://fujinet.online/"
end
 data msg
 "HELLO"
end
 data path
 "/0/name"
end
 data txt
 "HELLO"
end
 data line
 "A LINE"
end
 data ssidpw
 1,2,3
end
 goto snip
main
 drawscreen
 goto main
fnbeg
 return
fngo
 return
fnend
 return
connected
fail
 goto main
snip
"""
BAS_TAIL = """
 goto main
entry
atend
landed
done
 goto main
"""


def unescape(s):
    return s.replace('\\"', '"').replace("\\\\", "\\")


def snippets():
    parts = sorted(os.listdir(os.path.join(ROOT, "parts")))
    for part in parts:
        src = open(os.path.join(ROOT, "parts", part)).read()
        n = 0
        for m in re.finditer(r'\b(asm|bas):\s*"((?:[^"\\]|\\.)*)"', src):
            n += 1
            yield part, n, m.group(1), unescape(m.group(2))
        for m in re.finditer(r'#pair\(\s*"((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"', src):
            n += 1
            yield part, n, "asm", unescape(m.group(1))
            n += 1
            yield part, n, "bas", unescape(m.group(2))


def check_asm(name, body):
    d = os.path.join(OUT, "asm")
    os.makedirs(d, exist_ok=True)
    p = os.path.join(d, name + ".asm")
    open(p, "w").write(ASM_HEAD + body + "\n" + ASM_TAIL)
    r = subprocess.run([AS, "-q", "-i", os.path.join(ROOT, "listings", "common"), p],
                       capture_output=True, text=True)
    for f in (p[:-4] + ".p", p[:-4] + ".lst"):
        if os.path.exists(f):
            os.remove(f)
    return r.returncode == 0, (r.stdout + r.stderr).strip()


def check_bas(name, body):
    d = os.path.join(OUT, "bas")
    os.makedirs(d, exist_ok=True)
    for f in ("fujinet.h", "fujibas.h", "netdefs.h", "devdefs.h"):
        t = os.path.join(d, f)
        if not os.path.exists(t):
            os.symlink(os.path.join(ROOT, "listings", "dasm", f), t)
    consts = open(os.path.join(ROOT, "listings", "bas", "fujiconst.bas")).read()
    p = os.path.join(d, name + ".bas")
    own = set(re.findall(r"^([a-z][a-z0-9]*)\s*$", body, re.M))
    head = "\n".join(l for l in BAS_HEAD.split("\n") if l.strip() not in own or l.startswith(" "))
    tail = "\n".join(l for l in BAS_TAIL.split("\n") if l.strip() not in own)
    open(p, "w").write(consts + head + body + "\n" + tail)
    env = dict(os.environ, bB=BB, PATH=os.path.expanduser("~/.local/bin") + ":" + os.environ["PATH"])
    r = subprocess.run([os.path.join(BB, "2600basic.native.sh"), name + ".bas"],
                       cwd=d, capture_output=True, text=True, env=env)
    out = r.stdout + r.stderr
    ok = (os.path.exists(p + ".bin") and os.path.getsize(p + ".bin") == 2048
          and "error:" not in out and "Unresolved" not in out and "Error" not in out)
    for ext in (".asm", ".bin", ".lst", ".sym"):
        f = p + ext
        if os.path.exists(f):
            os.remove(f)
    for f in ("bB.asm", "includes.bB", "2600basic_variable_redefs.h"):
        t = os.path.join(d, f)
        if os.path.exists(t):
            os.remove(t)
    return ok, out.strip()


bad = 0
total = 0
for part, n, kind, body in snippets():
    total += 1
    name = "%s-%02d" % (part.replace(".typ", ""), n)
    ok, out = (check_asm if kind == "asm" else check_bas)(name, body)
    if verbose or not ok:
        print("%s %s [%s]" % ("ok  " if ok else "FAIL", name, kind))
    if not ok:
        bad += 1
        print("    " + "\n    ".join(out.splitlines()[-6:]))
print("snipcheck: %d snippets, %d failed" % (total, bad))
sys.exit(1 if bad else 0)
