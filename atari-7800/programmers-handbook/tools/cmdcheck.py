#!/usr/bin/env python3
"""cmdcheck.py -- every command the firmware dispatches has a card.

Enumerates the `case XXX:` labels and command tables the 7800 cartridge's
ESP32 dispatches through (it runs the firmware's RS232 build: rs232Fuji and
its mixins, the shared network device NDevice and clock fujiClock), resolves each to its byte through fujiCommandID.h, and requires
that byte to appear in the matching reference chapter, on a card or in its
list of commands answered with a NAK. Sources are read from a git revision,
so the checkout's own branch does not matter.

    tools/cmdcheck.py [firmware-root [revision]]      default origin/master
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FW = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/Workspace/fujinet-firmware")
REV = sys.argv[2] if len(sys.argv) > 2 else "origin/master"


def show(path):
    return subprocess.run(["git", "-C", FW, "show", "%s:%s" % (REV, path)],
                          capture_output=True, text=True, check=True).stdout


ids = {}
for line in show("include/fujiCommandID.h").splitlines():
    m = re.match(r"\s*([A-Z0-9_]+)\s*=\s*(0x[0-9A-Fa-f]{2}|'.')", line)
    if m:
        v = m.group(2)
        ids[m.group(1)] = ord(v[1]) if v.startswith("'") else int(v, 16)

srcs = {
    "fuji": ["lib/device/rs232/rs232Fuji.cpp", "lib/device/fujiDevice/AppKeyMixin.h",
             "lib/device/fujiDevice/Base64Mixin.h", "lib/device/fujiDevice/HashMixin.h",
             "lib/device/fujiDevice/QRMixin.h"],
    "net": ["lib/device/NDevice/NDevice.cpp"],
    "disk": ["lib/device/rs232/disk.cpp"],
    "printer": ["lib/device/rs232/printer.cpp"],
    "clock": ["lib/device/fujiClock/fujiClock.cpp"],
    "modem": ["lib/device/rs232/modem.cpp"],
}
parts = {"fuji": "16-ref-fuji.typ", "net": "17-ref-net.typ",
         "disk": "18-ref-other.typ", "printer": "18-ref-other.typ",
         "clock": "18-ref-other.typ", "modem": "18-ref-other.typ"}

dispatched = {}
for dev, files in srcs.items():
    for f in files:
        txt = show(f)
        for m in re.finditer(r"case\s+(?:CMD::)?([A-Z0-9_]+)\s*:", txt):
            if m.group(1) in ids:
                dispatched.setdefault(dev, {})[m.group(1)] = ids[m.group(1)]
        for m in re.finditer(r"\{\s*(?:CMD::)?([A-Z0-9_]+)\s*,\s*(?:FM_CMD_HANDLER|\{&)", txt):
            if m.group(1) in ids:
                dispatched.setdefault(dev, {})[m.group(1)] = ids[m.group(1)]

bad = 0
for dev, cmds in dispatched.items():
    text = open(os.path.join(ROOT, "parts", parts[dev])).read()
    codes = set(int(c, 16) for c in re.findall(r"\$([0-9A-Fa-f]{2})\b", text))
    missing = [(n, b) for n, b in sorted(cmds.items(), key=lambda kv: -kv[1]) if b not in codes]
    for name, byte in missing:
        print("MISSING %-8s %-36s $%02X" % (dev, name, byte))
    bad += len(missing)
    print("%-8s %3d dispatched, %s" % (dev, len(cmds),
          "all present" if not missing else "%d missing" % len(missing)))
sys.exit(1 if bad else 0)
