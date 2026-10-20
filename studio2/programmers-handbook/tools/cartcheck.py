#!/usr/bin/env python3
"""cartcheck.py -- every cartridge register, status field, text operation
and symbol has a place in "The Cartridge Itself".

Reads the cartridge's own headers at the pinned firmware revision -- the
Studio II mailbox layout (fuji_mailbox.h), the protocol constants every
cart shares (fuji_mailbox_proto.h) and the text engine (s2_text.h) -- and
requires every FN_R_*, FN_REG_*, S2T_OP_* and S2T_SYM_* name to appear in
parts/19-ref-cart.typ.

    tools/cartcheck.py [firmware-root [revision]]
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FW = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/Workspace/fn-studio2-board")
REV = sys.argv[2] if len(sys.argv) > 2 else "07e9bbaa9"
HEADERS = ["pico/studio2/firmware/include/fuji_mailbox.h",
           "pico/common/include/fuji_mailbox_proto.h",
           "pico/studio2/firmware/include/s2_text.h"]
PREFIXES = ("FN_R_", "FN_REG_", "S2T_OP_", "S2T_SYM_")


def show(path):
    return subprocess.run(["git", "-C", FW, "show", "%s:%s" % (REV, path)],
                          capture_output=True, text=True, check=True).stdout


names = set()
for h in HEADERS:
    for m in re.finditer(r"#define\s+([A-Z0-9_]+)", show(h)):
        if m.group(1).startswith(PREFIXES):
            names.add(m.group(1))
text = open(os.path.join(ROOT, "parts", "19-ref-cart.typ")).read()
missing = sorted(n for n in names if n not in text)
for n in missing:
    print("MISSING", n)
print("cartcheck: %d names, %s" % (len(names), "all present" if not missing
                                     else "%d missing" % len(missing)))
sys.exit(1 if missing else 0)
