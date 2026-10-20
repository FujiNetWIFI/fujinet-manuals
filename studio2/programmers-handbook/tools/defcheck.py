#!/usr/bin/env python3
"""defcheck.py -- the handbook's s2defs.inc agrees with the firmware.

Every command equate in listings/asm/s2defs.inc carries the firmware's
name in its comment (FNCSCAN ... ; SCAN_NETWORKS); this resolves that name
through include/fujiCommandID.h at the pinned revision and compares the
values. Device ids are checked against include/fujiDeviceID.h.

    tools/defcheck.py [firmware-root [revision]]
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FW = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/Workspace/fn-studio2-board")
REV = sys.argv[2] if len(sys.argv) > 2 else "07e9bbaa9"


def show(path):
    return subprocess.run(["git", "-C", FW, "show", "%s:%s" % (REV, path)],
                          capture_output=True, text=True, check=True).stdout


fw = {}
for line in show("include/fujiCommandID.h").splitlines():
    m = re.match(r"\s*([A-Z0-9_]+)\s*=\s*(0x[0-9A-Fa-f]+)", line)
    if m:
        fw.setdefault(m.group(1), int(m.group(2), 16))
# the header holds a second, smaller numbering first; the bus ids follow
# the FUJINET = 0x70 line
dev = {}
seen = False
for line in show("include/fujiDeviceID.h").splitlines():
    m = re.match(r"\s*([A-Z0-9_]+)\s*=\s*(0x[0-9A-Fa-f]+)", line)
    if m and m.group(1) == "FUJINET" and int(m.group(2), 16) == 0x70:
        seen = True
    if m and seen:
        dev.setdefault(m.group(1), int(m.group(2), 16))


def val(s):
    s = s.strip()
    return int(s[:-1], 16) if s.upper().endswith("H") else int(s)


bad = n = 0
for line in open(os.path.join(ROOT, "listings", "asm", "s2defs.inc")):
    m = re.match(r"^(FNC\w+)\s+EQU\s+(\w+)\s*;\s*([A-Z0-9_]+)", line)
    if not m:
        continue
    name, v, fwname = m.group(1), val(m.group(2)), "FUJI_" + m.group(3)
    n += 1
    if fwname not in fw:
        print("UNKNOWN %s: %s not in fujiCommandID.h" % (name, fwname)); bad += 1
    elif fw[fwname] != v:
        print("WRONG   %s = $%02X, firmware %s = $%02X" % (name, v, fwname, fw[fwname])); bad += 1
want = {"DSKDEV": "DISK", "PRNDEV": "PRINTER", "CLKDEV": "CLOCK",
        "MDMDEV": "SERIAL", "NETDEV": "NETWORK"}
for line in open(os.path.join(ROOT, "listings", "asm", "s2defs.inc")):
    m = re.match(r"^(\w+DEV)\s+EQU\s+(\w+)", line)
    if m and m.group(1) in want:
        n += 1
        f = want[m.group(1)]
        if dev.get(f) != val(m.group(2)):
            print("WRONG   %s = %s, firmware %s = %s" % (m.group(1), m.group(2), f, dev.get(f))); bad += 1
print("defcheck: %d equates, %s" % (n, "all agree" if not bad else "%d wrong" % bad))
sys.exit(1 if bad else 0)
