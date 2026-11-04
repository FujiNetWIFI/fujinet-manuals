#!/usr/bin/env python3
"""cartcheck.py -- every name in the cartridge's mailbox headers has a place
in "The Cartridge Itself".

Reads the Arcadia mailbox layout (pico/arcadia/firmware/include/
fuji_mailbox.h) and the protocol every cart shares (pico/common/include/
fuji_mailbox_proto.h) at the pinned firmware revision, and requires every
FN_R_*, FN_H_*, FN_REG_*, FN_HOT_* and FN_BOOT_* name to appear in
parts/20-ref-cart.typ.

    tools/cartcheck.py [firmware-root [revision]]
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FW = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/Workspace/fujinet-firmware")
REV = sys.argv[2] if len(sys.argv) > 2 else "e3923e881"
HEADERS = ["pico/arcadia/firmware/include/fuji_mailbox.h",
           "pico/common/include/fuji_mailbox_proto.h"]
PREFIXES = ("FN_R_", "FN_H_", "FN_REG_", "FN_HOT_", "FN_BOOT_")


def show(path):
    return subprocess.run(["git", "-C", FW, "show", "%s:%s" % (REV, path)],
                          capture_output=True, text=True, check=True).stdout


names = set()
for h in HEADERS:
    for m in re.finditer(r"#define\s+([A-Z0-9_]+)", show(h)):
        if m.group(1).startswith(PREFIXES):
            names.add(m.group(1))
text = open(os.path.join(ROOT, "parts", "20-ref-cart.typ")).read()
missing = sorted(n for n in names if n not in text)
for n in missing:
    print("MISSING", n)
print("cartcheck: %d names, %s" % (len(names), "all present" if not missing
                                     else "%d missing" % len(missing)))
sys.exit(1 if missing else 0)
