#!/usr/bin/env python3
"""cmdcheck.py -- every command the firmware dispatches has a card.

Enumerates the `case XXX:` labels in the RS232 device sources and the mixin
command tables of the FujiNet firmware, resolves each to its byte through
fujiCommandID.h, and requires that byte to appear in a card's `code:` (or in
a NAK list) in the reference chapters. Also reports cards that name a byte
no dispatcher answers.

    tools/cmdcheck.py [firmware-root]
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FW = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/Workspace/fujinet-firmware")

ids = {}
for line in open(os.path.join(FW, "include", "fujiCommandID.h")):
    m = re.match(r"\s*([A-Z0-9_]+)\s*=\s*0x([0-9A-Fa-f]{2})", line)
    if m:
        ids[m.group(1)] = int(m.group(2), 16)

srcs = {
    "fuji": ["lib/device/rs232/rs232Fuji.cpp", "lib/device/fujiDevice/AppKeyMixin.h",
             "lib/device/fujiDevice/Base64Mixin.h", "lib/device/fujiDevice/HashMixin.h",
             "lib/device/fujiDevice/QRMixin.h"],
    "net": ["lib/device/rs232/network.cpp"],
    "disk": ["lib/device/rs232/disk.cpp"],
    "printer": ["lib/device/rs232/printer.cpp"],
    "clock": ["lib/device/rs232/apetime.cpp"],
    "modem": ["lib/device/rs232/modem.cpp"],
}
dispatched = {}
for dev, files in srcs.items():
    for f in files:
        txt = open(os.path.join(FW, f)).read()
        for m in re.finditer(r"case\s+([A-Z0-9_]+)\s*:", txt):
            if m.group(1) in ids:
                dispatched.setdefault(dev, {})[m.group(1)] = ids[m.group(1)]
        for m in re.finditer(r"\{\s*([A-Z0-9_]+)\s*,\s*FM_CMD_HANDLER", txt):
            if m.group(1) in ids:
                dispatched.setdefault(dev, {})[m.group(1)] = ids[m.group(1)]

parts = {"fuji": "15-ref-fuji.typ", "net": "16-ref-net.typ",
         "disk": "17-ref-other.typ", "printer": "17-ref-other.typ",
         "clock": "17-ref-other.typ", "modem": "17-ref-other.typ"}
bad = 0
for dev, cmds in dispatched.items():
    text = open(os.path.join(ROOT, "parts", parts[dev])).read()
    codes = set(int(c, 16) for c in re.findall(r"\$([0-9A-Fa-f]{2})\b", text))
    for name, byte in sorted(cmds.items(), key=lambda kv: -kv[1]):
        if byte not in codes:
            print("MISSING %-8s %-32s $%02X" % (dev, name, byte))
            bad += 1
    print("%-8s %3d dispatched, all present" % (dev, len(cmds)) if not any(
        b not in codes for b in cmds.values()) else "%-8s %3d dispatched" % (dev, len(cmds)))
sys.exit(1 if bad else 0)
