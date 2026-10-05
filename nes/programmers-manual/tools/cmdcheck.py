#!/usr/bin/env python3
"""cmdcheck.py -- every command the FujiNet dispatches is in the manual.

Reads the firmware's dispatch tables -- the Fuji device's `handlers` map and
its mixins' tables, the rs232 switch, the network device's dispatch_table, the
clock's, the disk's and the printer's cases -- turns each CMD::NAME into its
number through include/fujiCommandID.h, and requires that number to appear as
`$XX` (or inside a `$XX-$YY` range) in the chapter that documents that device.

    tools/cmdcheck.py            FW defaults to ~/Workspace/fn-nes
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FW = os.environ.get("FW", os.path.expanduser("~/Workspace/fn-nes"))
DEV = os.path.join(FW, "lib", "device")


def read(*p):
    return open(os.path.join(*p)).read()


ids = {m.group(1): int(m.group(2), 16) for m in
       re.finditer(r"\b([A-Z][A-Z0-9_]*)\s*=\s*0x([0-9A-Fa-f]+)",
                   read(FW, "include", "fujiCommandID.h"))}


def names(text):
    return set(re.findall(r"CMD::([A-Z0-9_]+)", text))


def block(text, start, end="};"):
    i = text.index(start)
    return text[i:text.index(end, i)]


fd = read(DEV, "fujiDevice", "fujiDevice.cpp")
fuji = names(block(fd, "handlers = {"))
for mixin in ("AppKeyMixin.h", "Base64Mixin.h", "HashMixin.h", "QRMixin.h"):
    fuji |= names(read(DEV, "fujiDevice", mixin))
rf = read(DEV, "rs232", "rs232Fuji.cpp")
fuji |= set(re.findall(r"case CMD::([A-Z0-9_]+)", rf))

net = names(block(read(DEV, "NDevice", "NDevice.cpp"), "dispatch_table = {"))
clock = names(read(DEV, "fujiClock", "fujiClock.cpp"))
disk = set(re.findall(r"case CMD::(DISK_[A-Z0-9_]+)", read(DEV, "rs232", "disk.cpp")))
printer = set(re.findall(r"case CMD::(PRINTER_[A-Z0-9_]+)", read(DEV, "rs232", "printer.cpp")))

parts = {
    "fuji": (fuji, ["07-fuji.typ", "08-boot.typ"]),
    "network": (net, ["06-network.typ"]),
    "clock": (clock, ["09-clock.typ"]),
    "disk": (disk, ["09-clock.typ"]),
    "printer": (printer, ["09-clock.typ"]),
}


def documented(files):
    text = "".join(read(ROOT, "parts", f) for f in files)
    seen = set()
    for m in re.finditer(r"\$([0-9A-F]{2})(?![0-9A-Fa-f])(?:\s*-\s*\$([0-9A-F]{2})(?![0-9A-Fa-f]))?", text):
        a = int(m.group(1), 16)
        b = int(m.group(2), 16) if m.group(2) else a
        seen |= set(range(min(a, b), max(a, b) + 1))
    return seen


bad = 0
for dev, (cmds, files) in parts.items():
    seen = documented(files)
    missing = []
    for n in sorted(cmds):
        if n not in ids:
            continue                    # not a command id (e.g. a reply code)
        if ids[n] not in seen:
            missing.append("%s $%02X" % (n, ids[n]))
    if missing:
        bad += len(missing)
        print("cmdcheck: %s: not documented in %s: %s" % (dev, ", ".join(files),
              ", ".join(missing)))
    else:
        print("cmdcheck: %s: all %d commands documented" % (dev, len(cmds)))
sys.exit(1 if bad else 0)
