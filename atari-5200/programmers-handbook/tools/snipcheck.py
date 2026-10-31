#!/usr/bin/env python3
"""snipcheck.py -- every example in the text builds, in both languages.

Finds every `asm: "..."` and `c: "..."` argument and every
`pair("...", "...")` call in parts/*.typ, wraps each snippet in a skeleton
that supplies what examples may lean on (the libraries, scratch variables
and buffers, and the labels `failed`, `refused`, `connected` and `done`),
and builds it the way the programs are built:

    assembly   ca65, linked by ld65 with a52init, fujidisp and fujilib
               (a52.cfg), then tools/checkrom.py
    C          cc65, linked with MekkoGX's crt0 and linker config,
               fujinet-lib's atari5200 target and antic.c, then the
               romstamp and tools/checkrom.py

An assembly example that counts in Y around fn_txb fails too (fn_txb takes
its byte in Y). Snippets land in listings/snippets/{asm,c}/<part>-NN.*. Prints one line
per failure with the compiler's complaint; exits 1 if any failed.

    tools/snipcheck.py [part ...]
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
L = os.path.join(ROOT, "listings")
OUT = os.path.join(L, "snippets")
FNLIB = os.environ.get("FNLIB", os.path.expanduser("~/Workspace/a5book-fw/fujinet-lib"))
MEKKO = os.environ.get("MEKKO", os.path.expanduser("~/Workspace/a5book-fw/MekkoGX/mekkogx"))

ASM_HEAD = """        .include "fujinet.inc"
        .include "devdefs.inc"
        .include "netdefs.inc"
        .include "book.inc"
        .import fn_chk, fn_rw, fn_beg, fn_txb, fn_pb, fn_pw, fn_path, fn_go
        .import fn_ack, fn_blk, fn_boot, fn_config, fn_frames, fn_wait
        .import disp_init, disp_at, disp_str, disp_hex, disp_dec, disp_rpl
        .import disp_putc, disp_on
        .export main
        .segment "BSS"
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
        .segment "RODATA"
path:   .byte "/a5200book/", 0
file:   .byte "/a5200book/hello.a52", 0
spec:   .byte "/a5200book/readme.txt|/a5200book/copy.txt", 0
url:    .byte "N:http://127.0.0.1:8768/hello.txt", 0
urlend:
query:  .byte "/0/name", 0
queryend:
ssidpw: .res 97
val:    .byte "HELLO 5200"
valend:
data:   .byte "HELLO"
dataend:
        .include "header.inc"
"""

C_HEAD = """#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <fujinet-fuji.h>
#include <fujinet-network.h>
#include <fujinet-clock.h>
#include <fujinet-atari5200.h>
#include <fujinet-bus-atari5200.h>
#include <atari5200.h>
#include "antic.h"
#include "book.h"

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
const char url[] = "N:http://127.0.0.1:8768/hello.txt";
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

    for m in re.finditer(r'\b(asm|c):\s*"', src):
        text, _ = lit(m.end() - 1)
        yield m.group(1), text
    for m in re.finditer(r'#pair\(', src):
        i = m.end()
        for lang in ("asm", "c"):
            while src[i] in " \n\t,":
                i += 1
            if src.startswith("none", i):
                i += 4
                continue
            if src[i] != '"':
                break
            text, i = lit(i)
            yield lang, text


def run(cmd, cwd):
    r = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    return r.returncode, (r.stdout + r.stderr)


def checkrom(d, name):
    rc, msg = run([sys.executable, os.path.join(ROOT, "tools", "checkrom.py"), "--claim",
                   "--map", os.path.join(d, "obj", name + ".map"),
                   os.path.join(d, "obj", name + ".bin")], d)
    return msg if rc else None


def build_asm(name, text):
    # fn_txb takes its byte in Y: a loop that counts in Y around it is
    # wrong, and assembles cleanly
    if "fn_txb" in text and re.search(r"\biny\b|\bcpy\b", text):
        return "lint: a loop counts in Y around fn_txb, which takes its byte in Y"
    d = os.path.join(OUT, "asm")
    os.makedirs(os.path.join(d, "obj"), exist_ok=True)
    src = os.path.join(d, name + ".s")
    open(src, "w").write(ASM_HEAD + text + ASM_TAIL)
    inc = ["-I", os.path.join(L, "asm"), "-I", os.path.join(L, "common"),
           "-I", os.path.join(L, "asm", "build", "gen")]
    objs = []
    for f in ("a52init", "fujidisp", "fujilib"):
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
    rc, msg = run(["ld65", "-C", os.path.join(L, "common", "a52.cfg"),
                   "-m", os.path.join(d, "obj", name + ".map"),
                   "-o", os.path.join(d, "obj", name + ".bin")] + objs + [o], d)
    return msg if rc else checkrom(d, name)


def build_c(name, text):
    d = os.path.join(OUT, "c")
    os.makedirs(os.path.join(d, "obj"), exist_ok=True)
    src = os.path.join(d, name + ".c")
    open(src, "w").write(C_HEAD + "    {\n" + text + "\n    }\n" + C_TAIL)
    cflags = ["-t", "atari5200", "-O", "--cpu", "6502", "-I", os.path.join(FNLIB, "include"),
              "-I", os.path.join(FNLIB, "bus", "atari5200"), "-I", os.path.join(L, "c")]
    o = os.path.join(d, "obj", name + ".o")
    rc, msg = run(["cl65"] + cflags + ["-c", "-o", o, src], d)
    if rc or "Warning" in msg:
        return msg
    cb = os.path.join(L, "c", "build", "obj")
    out = os.path.join(d, "obj", name + ".bin")
    mp = os.path.join(d, "obj", name + ".map")
    rc, msg = run(["cl65", "-t", "atari5200", "-C", os.path.join(MEKKO, "atari5200-fujinet.cfg"),
                   "-Wl", "-D,__RESERVED_MEMORY__=0x400", "-m", mp, "-o", out,
                   os.path.join(MEKKO, "atari5200-crt0.s"), o,
                   os.path.join(cb, "antic.o"), os.path.join(cb, "antic_dl.o"),
                   os.path.join(FNLIB, "r2r", "atari5200", "fujinet.atari5200.lib")], d)
    if rc:
        return msg
    rc, msg = run([sys.executable, os.path.join(MEKKO, "atari5200-romstamp.py"), "--map", mp, out], d)
    return msg if rc else checkrom(d, name)


def main():
    only = sys.argv[1:]
    builders = {"asm": build_asm, "c": build_c}
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
                print("FAIL %-4s %s\n%s\n" % (lang, name, first))
    print("snipcheck: %d snippets, %d failed" % (total, bad))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
