#!/usr/bin/env python3
"""defcheck.py -- the equates the programs use agree with the firmware.

Two files carry numbers the firmware defines:
  - listings/runtime/fujilib.inc, the cartridge's own hand mirror of the
    mailbox headers: each of its equates is compared with the header name it
    stands for (the table below);
  - listings/asm/bookdefs.inc, the handbook's: every equate whose comment
    carries a firmware name (FCSCAN ... ; SCAN_NETWORKS) is resolved through
    include/fujiCommandID.h (FUJI_, NET_ or APETIME_ in front) or
    include/fujiDeviceID.h, at the pinned revision.

    tools/defcheck.py [firmware-root [revision]]
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FW = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/Workspace/fujinet-firmware")
REV = sys.argv[2] if len(sys.argv) > 2 else "e3923e881"


def show(path):
    return subprocess.run(["git", "-C", FW, "show", "%s:%s" % (REV, path)],
                          capture_output=True, text=True, check=True).stdout


def num(s):
    s = s.strip()
    if s.startswith("$"):
        return int(s[1:], 16)
    if s.lower().startswith("0x"):
        return int(s, 16)
    if s.upper().endswith("H") and re.match(r"^[0-9][0-9A-F]*H$", s.upper()):
        return int(s[:-1], 16)
    return int(s)


# the mailbox headers: #define NAME value (values may be expressions of hex)
hdr = {}
for h in ("pico/arcadia/firmware/include/fuji_mailbox.h",
          "pico/common/include/fuji_mailbox_proto.h"):
    for m in re.finditer(r"#define\s+([A-Z0-9_]+)\s+(0x[0-9A-Fa-f]+|\d+)\b", show(h)):
        hdr[m.group(1)] = int(m.group(2), 0)
CONSOLE = lambda off: off + 0x1000 if off >= 0x1000 else off   # image -> console
MIRROR = {   # fujilib.inc name: (header name, console address?)
    "FNRDATA": ("FN_R_DATA", True), "FNACKSQ": ("FN_R_ACKSEQ", True),
    "FNSTATS": ("FN_R_STATUS", True), "FNERR": ("FN_R_ERR", True),
    "FNREPLY": ("FN_R_REPLY_CMD", True), "FNRXLL": ("FN_R_RXLEN_LO", True),
    "FNRXLH": ("FN_R_RXLEN_HI", True), "FNBSTAT": ("FN_R_BOOT_STATE", True),
    "FNBPCT": ("FN_R_BOOT_PCT", True), "FNBERR": ("FN_R_BOOT_ERR", True),
    "FNMAGF": ("FN_R_MAGIC0", True), "FNMAGN": ("FN_R_MAGIC1", True),
    "FNPVER": ("FN_R_PROTO_VER", True), "FNSECHO": ("FN_R_SLICE_ECHO", True),
    "FNTIKL": ("FN_R_TICK_LO", True), "FNTIKH": ("FN_R_TICK_HI", True),
    "FNRSEL": ("FN_H_REGSEL", True), "FNRDAT": ("FN_H_REGDATA", True),
    "FNDATA": ("FN_H_DATA", True),
    "FRDEVIC": ("FN_REG_DEVICE", False), "FRCMD": ("FN_REG_CMD", False),
    "FRNPARM": ("FN_REG_NPARAM", False), "FRDATRS": ("FN_REG_DATA_RST", False),
    "FRRXSLC": ("FN_REG_RXSLICE", False), "FRSEQ": ("FN_REG_SEQ", False),
    "FRBOOTL": ("FN_REG_BOOTLOCK", False), "FRBSEL1": ("FN_REG_BOOTSEL_1", False),
    "FRBSEL2": ("FN_REG_BOOTSEL_2", False), "FRRAMP0": ("FN_REG_RAMPTR0", False),
    "FRRAMP3": ("FN_REG_RAMPTR3", False), "FRRAMPK": ("FN_REG_RAMPOKE", False),
    "FBIDLE": ("FN_BOOT_IDLE", False), "FBXFER": ("FN_BOOT_XFER", False),
    "FBREADY": ("FN_BOOT_READY", False), "FBFAIL": ("FN_BOOT_FAILED", False),
    "FNBLMAG": ("FN_BOOTLOCK_MAGIC", False),
    "FEOK": ("FN_ERR_OK", False), "FENOLNK": ("FN_ERR_NOLINK", False),
    "FETMOUT": ("FN_ERR_TIMEOUT", False),
}
lib = {}
for line in open(os.path.join(ROOT, "listings", "runtime", "fujilib.inc")):
    m = re.match(r"^([A-Z0-9_]+)\s+EQU\s+(\$[0-9A-Fa-f]+|\d+)", line)
    if m:
        lib[m.group(1)] = num(m.group(2))
bad = n = 0
for name, (h, console) in MIRROR.items():
    n += 1
    want = hdr.get(h)
    if want is None:
        print("UNKNOWN %s: no %s in the headers" % (name, h)); bad += 1
        continue
    if console:
        want = CONSOLE(want)
    if lib.get(name) != want:
        print("WRONG   %s = %s, firmware %s = $%04X" % (name, lib.get(name), h, want)); bad += 1
# FNSWAP and FNBANK: the REGSEL page plus the one-shot offsets
for name, h in (("FNSWAP", "FN_HOT_SWAP"), ("FNBANK", "FN_HOT_BANK")):
    n += 1
    want = CONSOLE(hdr["FN_H_REGSEL"]) + hdr[h]
    if lib.get(name) != want:
        print("WRONG   %s = %s, firmware %s = $%04X" % (name, lib.get(name), h, want)); bad += 1

ids = {}
for line in show("include/fujiCommandID.h").splitlines():
    m = re.match(r"\s*([A-Z0-9_]+)\s*=\s*(0x[0-9A-Fa-f]+)", line)
    if m:
        ids.setdefault(m.group(1), int(m.group(2), 16))
dev, seen = {}, False
for line in show("include/fujiDeviceID.h").splitlines():
    m = re.match(r"\s*([A-Z0-9_]+)\s*=\s*(0x[0-9A-Fa-f]+)", line)
    if m and m.group(1) == "FUJINET" and int(m.group(2), 16) == 0x70:
        seen = True
    if m and seen:
        dev.setdefault(m.group(1), int(m.group(2), 16))
for line in open(os.path.join(ROOT, "listings", "asm", "bookdefs.inc")):
    m = re.match(r"^([A-Z0-9_]+)\s+EQU\s+(\$[0-9A-Fa-f]+)\s*;\s*([A-Z0-9_]+)\b", line)
    if not m:
        continue
    name, v, fw = m.group(1), num(m.group(2)), m.group(3)
    n += 1
    if name.startswith("DV"):
        got = dev.get(fw)
    else:
        pre = {"FC": "FUJI_", "NC": "NET_", "CK": "APETIME_"}.get(name[:2], "")
        got = ids.get(pre + fw)
    if got is None:
        print("UNKNOWN %s: %s not in the firmware's headers" % (name, fw)); bad += 1
    elif got != v:
        print("WRONG   %s = $%02X, firmware %s = $%02X" % (name, v, fw, got)); bad += 1
print("defcheck: %d equates, %s" % (n, "all agree" if not bad else "%d wrong" % bad))
sys.exit(1 if bad else 0)
