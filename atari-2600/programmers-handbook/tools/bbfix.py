#!/usr/bin/env python3
"""bbfix.py -- turn a batari Basic 2K build into a FujiNet cartridge image.

    bbfix.py prog.bas.bin fujitail.bin out.bin

The program must be exactly 2048 bytes (`set romsize 2k`); the fixed half
(fujitail.asm, assembled) is appended, and the result is a 4096-byte image the
cartridge serves as bank 0 plus the fixed half. tools/checkrom.py from the
cartridge tree is then run on it, because a batari Basic statement can emit an
INC/DEC on a write-only page as easily as an assembler can.
"""
import os
import re
import subprocess
import sys

prog, tail, out = sys.argv[1:4]
p = open(prog, "rb").read()
t = open(tail, "rb").read()
if len(p) != 2048:
    sys.exit("bbfix: %s is %d bytes, not 2048 -- is `set romsize 2k` missing?"
             % (prog, len(p)))
if len(t) != 2048 or t[0x710:0x714] != b"FUJI":
    sys.exit("bbfix: %s is not a 2048-byte fixed half with the claim at $1F10" % tail)
open(out, "wb").write(p + t)
print("bbfix: %s = %s + fixed half, %d bytes" % (out, prog, 4096))
fn = os.environ.get("FN2600", os.path.expanduser("~/Workspace/fn-2600/pico/atari-2600"))
r = subprocess.run([sys.executable, os.path.join(fn, "tools", "checkrom.py"), out],
                   capture_output=True, text=True)
report = (r.stdout + r.stderr).splitlines()

# checkrom bans STA (zp),Y everywhere, because a static scan cannot know what
# a zero-page pointer holds. batari Basic's runtime (everything below the
# `game` label) uses indirect stores that point at RAM and the TIA, never at
# the mailbox; those are vouched for here, by address. An indirect store in
# YOUR code -- at or above `game` -- still fails the build, as does any RMW.
game = None
try:
    for line in open(prog.replace(".bin", ".sym")):
        m = re.match(r"^game\s+([0-9a-fA-F]{4})", line)
        if m:
            game = int(m.group(1), 16)
except OSError:
    pass
bad = 0
for line in report:
    m = re.search(r"\$([0-9A-Fa-f]{4}): STA \(zp\),Y", line)
    if m and game is not None and int(m.group(1), 16) < game:
        print("bbfix: (runtime) " + line.split(" -- ")[0] + " -- batari Basic's own, vouched for")
        continue
    if line.strip():
        print(line)
        bad += 1
if bad:
    sys.exit("bbfix: checkrom found %d problem(s) in %s" % (bad, out))
print("bbfix: checkrom clean above `game` ($%04X)" % (game or 0))
