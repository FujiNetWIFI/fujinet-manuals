#!/usr/bin/env python3
"""snipcheck.py -- every example in the text builds, in all three languages.

Finds every `asm: "..."`, `c: "..."` and `bas: "..."` argument and every
`trio("...", "...", "...")` call in parts/*.typ, wraps each snippet in a
skeleton that supplies what examples may lean on (the libraries, scratch
variables and buffers, and the labels `failed`, `refused`, `connected` and
`done`), and builds it the way the programs are built:

    assembly   ca65, linked by ld65 with a78init, fujidisp and fujilib
    C          cc65, linked with fujinet-lib's atari7800 target and maria.s
    7800basic  7800basic, dasm, basfix.py

Snippets land in listings/snippets/{asm,c,bas}/<part>-NN.*. Prints one line
per failure with the compiler's complaint; exits 1 if any failed.

    tools/snipcheck.py [part ...]
"""
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
L = os.path.join(ROOT, "listings")
OUT = os.path.join(L, "snippets")
FNLIB = os.environ.get("FNLIB", os.path.expanduser("~/Workspace/fnlib-7800"))
B7800 = os.environ.get("bas7800dir", os.path.expanduser("~/Workspace/7800basic"))

ASM_HEAD = """        .include "fujinet.inc"
        .include "devdefs.inc"
        .include "netdefs.inc"
        .import fn_chk, fn_rw, fn_beg, fn_txb, fn_pb, fn_pw, fn_path, fn_go
        .import fn_ack, fn_blk, fn_boot
        .import disp_at, disp_str, disp_hex, disp_dec, disp_rpl, disp_putc
        .import disp_on, disp_vbl
        .export main, nmi
        .segment "ZEROPAGE"
idx:    .res 1
cnt:    .res 1
        .segment "CODE"
.proc main
"""
ASM_TAIL = """
failed:
refused:
connected:
done:
@hang:  jmp     @hang
.endproc
.proc nmi
        rti
.endproc
        .segment "RODATA"
path:   .byte "/a7800book/", 0
file:   .byte "/a7800book/hello.bin", 0
spec:   .byte "/a7800book/readme.txt|/a7800book/copy.txt", 0
url:    .byte "N:http://127.0.0.1:8765/hello.txt", 0
urlend:
query:  .byte "/0/name", 0
queryend:
ssidpw: .res 97
val:    .byte "HELLO 7800"
valend:
data:   .byte "HELLO"
dataend:
"""

C_HEAD = """#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <fujinet-fuji.h>
#include <fujinet-network.h>
#include <fujinet-clock.h>
#include <fujinet-atari7800.h>
#include <fujinet-bus-atari7800.h>
#include "maria.h"

uint8_t buf[1024];
char path[256];
AdapterConfigExtended ac;
SSIDInfo si;
NetConfig nc;
HostSlot hosts[8];
DeviceSlot slots[8];
uint8_t count, err, idx;
uint16_t n, pos;
int16_t got;
char guid[37];
uint8_t value[66];
uint8_t when[32];
const char url[] = "N:http://127.0.0.1:8765/hello.txt";
const char query[] = "/0/name";
const uint8_t data[] = "HELLO";

void failed(void) {}
void refused(void) {}
void linked(void) {}

void main(void)
{
"""
C_TAIL = """
    for (;;)
        ;
}
"""

BAS_HEAD = """ incbasic fujinet.bas
 displaymode 320A
 set zoneheight 8
 incgraphic fujifont.png 320A
 characterset fujifont
 alphachars ASCII
 dim buf = $2200
 dim ix = var0
 dim idx = var1
 dim cnt = var2
 dim rssi = var3
 dim avail = var4
 dim last = var5
 dim ch = var6
"""
BAS_TAIL = """
main
 drawscreen
 goto main
failed
refused
connected
done
 goto main

 alphadata path fujifont
 '/a7800book/'
end
 alphadata file fujifont
 '/a7800book/hello.bin'
end
 alphadata spec fujifont
 '/a7800book/readme.txt|/a7800book/copy.txt'
end
 alphadata url fujifont
 'N:http://127.0.0.1:8765/hello.txt'
end
 alphadata query fujifont
 '/0/name'
end
 alphadata value fujifont
 'HELLO 7800'
end
 alphadata ssid fujifont
 'Dummy Cafe'
end

 incbasic fujilib.bas
"""


def strings(src):
    """Yield (lang, text) for every snippet argument in a part."""
    def lit(i):
        # a Typst string literal starting at src[i] == '"'
        j, out = i + 1, []
        while src[j] != '"':
            if src[j] == "\\":
                nxt = src[j + 1]
                out.append({"n": "\n", "t": "\t", '"': '"', "\\": "\\"}.get(nxt, nxt))
                j += 2
            else:
                out.append(src[j])
                j += 1
        return "".join(out), j + 1

    for m in re.finditer(r'\b(asm|c|bas):\s*"', src):
        text, _ = lit(m.end() - 1)
        yield m.group(1), text
    for m in re.finditer(r'#trio\(\s*"', src):
        i, langs = m.end() - 1, ("asm", "c", "bas")
        for lang in langs:
            while src[i] in " \n\t,":
                i += 1
            if src.startswith("none", i):
                i += 4
                continue
            text, i = lit(i)
            yield lang, text


def run(cmd, cwd):
    r = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    return r.returncode, (r.stdout + r.stderr)


def build_asm(name, text):
    d = os.path.join(OUT, "asm")
    os.makedirs(os.path.join(d, "obj"), exist_ok=True)
    src = os.path.join(d, name + ".s")
    open(src, "w").write(ASM_HEAD + text + ASM_TAIL)
    inc = ["-I", os.path.join(L, "asm"), "-I", os.path.join(L, "common"),
           "-I", os.path.join(L, "asm", "build", "gen")]
    objs = []
    for f in ("a78init", "fujidisp", "fujilib"):
        o = os.path.join(d, "obj", f + ".o")
        if not os.path.exists(o):
            rc, msg = run(["ca65"] + inc + ["-o", o, os.path.join(L, "common", f + ".s")], d)
            if rc:
                return msg
        objs.append(o)
    o = os.path.join(d, "obj", name + ".o")
    rc, msg = run(["ca65"] + inc + ["-o", o, src], d)
    if rc:
        return msg
    rc, msg = run(["ld65", "-C", os.path.join(L, "common", "a78.cfg"), "-o",
                   os.path.join(d, "obj", name + ".bin")] + objs + [o], d)
    return msg if rc else None


def build_c(name, text):
    d = os.path.join(OUT, "c")
    os.makedirs(os.path.join(d, "obj"), exist_ok=True)
    src = os.path.join(d, name + ".c")
    open(src, "w").write(C_HEAD + "    {\n" + text + "\n    }\n" + C_TAIL)
    cflags = ["-t", "atari7800", "-O", "--cpu", "6502", "-I", os.path.join(FNLIB, "include"),
              "-I", os.path.join(FNLIB, "bus", "atari7800"), "-I", os.path.join(L, "c")]
    o = os.path.join(d, "obj", name + ".o")
    rc, msg = run(["cl65"] + cflags + ["-c", "-o", o, src], d)
    if rc or "Warning" in msg:
        return msg
    cb = os.path.join(L, "c", "build")
    rc, msg = run(["cl65", "-t", "atari7800", "-C",
                   os.path.join(FNLIB, "makefiles", "atari7800-fujinet.cfg"),
                   "-o", os.path.join(d, "obj", name + ".bin"), o,
                   os.path.join(cb, "maria.o"), os.path.join(cb, "tiles.o"),
                   os.path.join(FNLIB, "r2r", "atari7800", "fujinet.atari7800.lib")], d)
    return msg if rc else None


def build_bas(name, text):
    d = os.path.join(OUT, "bas", name)
    shutil.rmtree(d, ignore_errors=True)
    os.makedirs(d)
    for f in ("fujinet.bas", "fujilib.bas", "fujifont.png"):
        shutil.copy(os.path.join(L, "bas", f), d)
    open(os.path.join(d, name + ".bas"), "w").write(BAS_HEAD + text + BAS_TAIL)
    env = dict(os.environ, bas7800dir=B7800, PATH=B7800 + os.pathsep + os.environ["PATH"])
    steps = [
        "7800preprocess < {n}.bas > {n}.bas.pre",
        "7800basic -i $bas7800dir -b {n}.bas -p {n}.bas.pre > {n}.log",
        "7800postprocess -i $bas7800dir > {n}.bas.asm",
        "dasm {n}.bas.asm -I$bas7800dir/includes -f3 -l{n}.bas.list.txt -p20 "
        "-s{n}.bas.symbol.txt -o{n}.bas.bin | 7800filter > dasm.log",
    ]
    for s in steps:
        r = subprocess.run(s.format(n=name), shell=True, cwd=d, env=env,
                           capture_output=True, text=True)
        log = open(os.path.join(d, "dasm.log")).read() if os.path.exists(os.path.join(d, "dasm.log")) else ""
        if r.returncode or "rror" in r.stdout + r.stderr:
            return r.stdout + r.stderr
    if "Complete" not in log:
        return log
    rc, msg = run([sys.executable, os.path.join(ROOT, "tools", "basfix.py"),
                   name + ".bas.bin", name + ".bas.list.txt", "dasm.log"], d)
    return msg if rc else None


def main():
    only = sys.argv[1:]
    builders = {"asm": build_asm, "c": build_c, "bas": build_bas}
    total = bad = 0
    for part in sorted(os.listdir(os.path.join(ROOT, "parts"))):
        stem = part[:-4]
        if not part.endswith(".typ") or (only and stem not in only and part not in only):
            continue
        src = open(os.path.join(ROOT, "parts", part)).read()
        for k, (lang, text) in enumerate(strings(src), 1):
            name = "%s-%02d" % (stem, k)
            total += 1
            err = builders[lang](name, text)
            if err:
                bad += 1
                first = "\n".join(l for l in err.splitlines() if l.strip())[:600]
                print("FAIL %-6s %s\n%s\n" % (lang, name, first))
    print("snipcheck: %d snippets, %d failed" % (total, bad))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
