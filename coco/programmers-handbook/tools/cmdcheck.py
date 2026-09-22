#!/usr/bin/env python3
"""
cmdcheck.py --- the completeness gate.

Every command the FujiNet firmware dispatches on the DriveWire bus must
have a reference card in manual.typ, and every card must name a command
the firmware actually dispatches.  This reads both sides and diffs them.

It needs a fujinet-firmware checkout.  Point FUJINET_FIRMWARE at one, or
let it find the usual place.  With no checkout it says so and exits 0 ---
a missing source tree is not a book error.
"""

import os
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent
MANUAL = HERE / "manual.typ"

CANDIDATES = [
    os.environ.get("FUJINET_FIRMWARE", ""),
    str(Path.home() / "Workspace" / "fujinet-firmware"),
    str(HERE.parent.parent.parent / "fujinet-firmware"),
]

# Commands that are answered by the bus itself rather than by a device,
# and so appear in no dispatch table.
BUS_ANSWERED = {"DEVICE_READY", "SEND_RESPONSE", "SEND_ERROR"}

# Cards that document a bus opcode rather than a device command.  These
# live in chapters 14 and 15 and are checked by eye, not by this tool.
BUS_OPCODE_CARDS = {
    "OP_READEX", "OP_WRITE", "OP_TIME", "OP_JEFF", "OP_DWINIT",
    "OP_RESET", "OP_NOP", "OP_NAMEOBJ_MNT", "PRINT",
    "CPM_BOOT", "CPM_READ", "CPM_WRITE", "CPM_STATUS",
    "GET_TIME (simple)", "GET_TIME (APETIME)", "GET_TIME (hundredths)",
    "GET_TIME (ProDOS)", "GET_TIME (SOS)", "GET_TIME (ISO)",
    "GET_TZ", "SET_TZ",
}


def find_firmware():
    for c in CANDIDATES:
        if c and (Path(c) / "include" / "fujiCommandID.h").is_file():
            return Path(c)
    return None


def command_values(fw):
    """name -> value, from include/fujiCommandID.h"""
    text = (fw / "include" / "fujiCommandID.h").read_text()
    out = {}
    for m in re.finditer(r"^\s*([A-Z0-9_]+)\s*=\s*(0x[0-9A-Fa-f]+|\d+)", text, re.M):
        out[m.group(1)] = int(m.group(2), 0)
    return out


def dispatched(fw):
    """The CMD:: names the DriveWire bus answers, from the dispatch tables."""
    names = set()
    sources = [
        fw / "lib" / "device" / "fujiDevice" / "fujiDevice.cpp",
        fw / "lib" / "device" / "drivewire" / "drivewireFuji.cpp",
        fw / "lib" / "device" / "NDevice" / "NDevice.cpp",
    ]
    sources += sorted((fw / "lib" / "device" / "fujiDevice").glob("*Mixin.h"))

    for src in sources:
        if not src.is_file():
            continue
        text = src.read_text()
        # strip #if 0 ... #endif so commented-out handlers do not count
        text = re.sub(r"#if 0\b.*?#endif", "", text, flags=re.S)
        for m in re.finditer(r"\{\s*CMD::([A-Z0-9_]+)\s*,", text):
            names.add(m.group(1))
        for m in re.finditer(r"case\s+CMD::([A-Z0-9_]+)\s*:", text):
            names.add(m.group(1))
    return names


def carded():
    """(name, code) for every #cmd() card in the manual."""
    text = MANUAL.read_text()
    out = []
    for m in re.finditer(r'#cmd\("([^"]+)",\s*code:\s*"([^"]*)"', text):
        out.append((m.group(1), m.group(2)))
    return out


def card_codes(cards):
    """Every hex byte a card claims, as a set of ints."""
    codes = set()
    for name, code in cards:
        for h in re.findall(r"\$([0-9A-Fa-f]{2})", code):
            codes.add(int(h, 16))
    return codes


def main():
    fw = find_firmware()
    if fw is None:
        print("cmdcheck: no fujinet-firmware checkout found; skipping.")
        print("          set FUJINET_FIRMWARE to enable this check.")
        return 0

    values = command_values(fw)
    names = dispatched(fw)
    cards = carded()
    codes = card_codes(cards)
    card_names = {n for n, _ in cards}

    problems = 0

    # Every dispatched command needs a card.
    missing = []
    for n in sorted(names):
        if n in values and values[n] not in codes:
            missing.append("%-34s $%02X" % (n, values[n]))
    if missing:
        problems += len(missing)
        print("cmdcheck: dispatched but not carded:")
        for line in missing:
            print("   ", line)

    # Every card should name something the firmware answers, unless it is
    # one of the bus-level opcodes this tool does not track.
    stray = []
    dispatched_codes = {values[n] for n in names if n in values}
    for name, code in cards:
        if name in BUS_OPCODE_CARDS or name in BUS_ANSWERED:
            continue
        hexes = [int(h, 16) for h in re.findall(r"\$([0-9A-Fa-f]{2})", code)]
        if hexes and not any(h in dispatched_codes for h in hexes):
            stray.append("%-34s %s" % (name, code))
    if stray:
        problems += len(stray)
        print("cmdcheck: carded but not dispatched:")
        for line in stray:
            print("   ", line)

    if problems:
        print("cmdcheck: %d problem(s)" % problems)
        return 1

    print("cmdcheck: %d cards cover %d dispatched commands: ok"
          % (len(cards), len(names)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
