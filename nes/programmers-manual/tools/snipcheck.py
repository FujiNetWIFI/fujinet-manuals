#!/usr/bin/env python3
"""snipcheck.py -- every example in the manual's text assembles or compiles.

Pulls each `asm: "..."` and `c: "..."` string, and each `#pair("...", "...")`,
out of parts/*.typ, wraps it in a skeleton that supplies the symbols a
snippet is allowed to assume (the libraries, a few labels and variables), and
builds it: ca65 + ld65 + checkrom.py for assembly, cl65 for C. A snippet that
does not build fails the check, so nothing in the text is untested syntax.

    tools/snipcheck.py         all chapters
    tools/snipcheck.py -v      every snippet's verdict
"""
import glob, os, re, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LST = os.path.join(ROOT, "listings")
OUT = os.path.join(LST, "build", "snippets")
LIB = os.environ.get("FUJINET_LIB", os.path.expanduser("~/Workspace/fujinet-lib-experimental"))
verbose = "-v" in sys.argv

ASM_HEAD = """        .include "book.inc"
        .export main
        .segment "ZEROPAGE"
tmp:    .res 2
        .segment "CODE"
.proc main
"""
ASM_TAIL = """
nocart:
fail:   jmp     fail
.endproc
        .segment "RODATA"
url:    .byte "N:HTTP://127.0.0.1:8765/hello.txt", 0
path:   .byte "/nesbook/hello.bin", 0
data:   .byte "HELLO", 0
ssidpw: .res 97, 0
"""
C_HEAD = """#include <conio.h>
#include <string.h>
#include <fujinet-fuji.h>
#include <fujinet-network.h>
#include <fujinet-clock.h>
#include <fujinet-nes.h>
#include <fujinet-bus-nes.h>
#include <fujinet-commands.h>
#include <fujinet-qrcode.h>
static uint8_t buf[1024];
static char path[256];
static const char url[] = "N:HTTP://127.0.0.1:8765/hello.txt";
static uint16_t avail, len, pos;
static uint8_t conn, err, n, count, status, ok8;
static int16_t n16;
static uint32_t r32;
static unsigned long blen;
static AdapterConfig ac;
static AdapterConfigExtended acx;
static NetConfig nc;
static SSIDInfo info;
static HostSlot hosts[8];
static DeviceSlot slots[8];
static char guid[37];
static uint8_t now[27];
static void fail(void) { for (;;) ; }
static void no_cartridge(void) { for (;;) ; }
void main(void)
{
"""
C_TAIL = """
  for (;;) ;
}
"""

STR = r'"((?:[^"\\]|\\.)*)"'


def unescape(s):
    return re.sub(r'\\(.)', lambda m: {"n": "\n", "t": "\t"}.get(m.group(1), m.group(1)), s)


def snippets():
    for path in sorted(glob.glob(os.path.join(ROOT, "parts", "*.typ"))):
        text = open(path).read()
        name = os.path.basename(path)
        for m in re.finditer(r'\basm:\s*' + STR, text):
            yield name, text[:m.start()].count("\n") + 1, "asm", unescape(m.group(1))
        for m in re.finditer(r'\bc:\s*' + STR, text):
            yield name, text[:m.start()].count("\n") + 1, "c", unescape(m.group(1))
        for m in re.finditer(r'#pair\(\s*' + STR + r'\s*,\s*' + STR, text):
            line = text[:m.start()].count("\n") + 1
            yield name, line, "asm", unescape(m.group(1))
            yield name, line, "c", unescape(m.group(2))


def run(cmd):
    r = subprocess.run(cmd, cwd=LST, capture_output=True, text=True)
    return r.returncode == 0, (r.stdout + r.stderr).strip()


def build_asm(tag, src):
    s = os.path.join(OUT, tag + ".s")
    open(s, "w").write(ASM_HEAD + src + ASM_TAIL)
    o, nes, mp = s[:-2] + ".o", s[:-2] + ".nes", s[:-2] + ".map"
    common = [os.path.join(LST, "build", "asm", f + ".o")
              for f in ("nesinit", "fujilib", "fujidisp", "booklib")]
    for step in (["ca65", "-t", "none", "-I", "common", "-o", o, s],
                 ["ld65", "-C", "common/nes.cfg", "-m", mp, "-o", nes, o] + common,
                 ["python3", "common/checkrom.py", "--claim", "--map", mp, nes]):
        ok, msg = run(step)
        if not ok:
            return False, msg
    return True, ""


def build_c(tag, src):
    s = os.path.join(OUT, tag + ".c")
    open(s, "w").write(C_HEAD + src + C_TAIL)
    nes = s[:-2] + ".nes"
    return run(["cl65", "-t", "nes", "-O", "-I", LIB + "/include", "-I", LIB + "/bus/nes",
                "-C", LIB + "/makefiles/nes-fujinet.cfg", "-o", nes, s,
                LIB + "/r2r/nes/fujinet.nes.lib"])


def main():
    os.makedirs(OUT, exist_ok=True)
    run(["make", "asm"])                  # the common objects
    bad = total = 0
    for i, (name, line, kind, src) in enumerate(snippets()):
        total += 1
        tag = "%s-%d-%s" % (name[:-4], line, kind)
        ok, msg = (build_asm if kind == "asm" else build_c)(tag, src)
        if not ok:
            bad += 1
            print("snipcheck: FAIL %s:%d (%s)\n%s\n" % (name, line, kind,
                  "\n".join(msg.splitlines()[:6])))
        elif verbose:
            print("snipcheck: ok   %s:%d (%s)" % (name, line, kind))
    print("snipcheck: %d/%d snippets build" % (total - bad, total))
    sys.exit(1 if bad else 0)


main()
