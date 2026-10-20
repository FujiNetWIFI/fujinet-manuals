#!/usr/bin/env python3
"""coleco-romstamp.py -- validate (and stamp) a built ColecoVision FujiNet client.

Ported from fujinet-firmware/pico/coleco/tools/checkrom.py, which is the
upstream source of the layout contract. It enforces that contract so a client
that drifts into the mailbox pages fails its build rather than a debugging
session:

  - exactly 32768 bytes. z88dk's appmake pads to --romsize with 0xFF, and 0xFF
    is also what an unmapped cartridge address reads as, so a FujiNet image and
    a stock cartridge agree on the filler byte;
  - the cartridge header magic at $8000: 55 AA to skip the BIOS title screen,
    AA 55 to show it. z88dk emits 55 AA;
  - nothing but filler in 0x7800-0x7FFF except the "FUJI" claim at 0x7CFC.
    Those pages are the reply window, the status page and the three hotspot
    pages, and the client must never place code or data there. This is also
    what makes the client-side NMI rule -- never read $F800 and up from the
    vblank handler -- checkable at build time;
  - the claim signature present. Without it the cartridge shuts the mailbox
    down for the session, silently, for an image that otherwise looks fine.

With --stamp the claim is written first, so the same tool that checks the
layout is the one that declares it. Stamping is idempotent: the claim it writes
lands inside the window it validates and is skipped by the filler check.

A failing image is deleted. There is no .DELETE_ON_ERROR in the shared
makefiles, so an image left behind with a fresh mtime would look up to date and
never be checked again.

Usage: coleco-romstamp.py [--stamp] image.rom [image2.rom ...]
"""

import os
import sys

WINDOW = 0x8000
ROM_TOP = 0x7800
CLAIM_OFF = 0x7CFC
CLAIM_SIG = b"FUJI"
FILLER = (0x00, 0xFF)


def stamp(path):
    with open(path, "r+b") as f:
        f.seek(CLAIM_OFF)
        f.write(CLAIM_SIG)


def check(path):
    with open(path, "rb") as f:
        img = f.read()
    if len(img) != WINDOW:
        return ["size is %d, must be exactly %d" % (len(img), WINDOW)]

    problems = []
    magic = img[0:2]
    if magic not in (b"\x55\xaa", b"\xaa\x55"):
        problems.append("header magic is %s, not 55aa or aa55" % magic.hex())
    if img[CLAIM_OFF:CLAIM_OFF + len(CLAIM_SIG)] != CLAIM_SIG:
        problems.append("claim signature 'FUJI' missing at %#06x" % CLAIM_OFF)
    for off in range(ROM_TOP, WINDOW):
        if CLAIM_OFF <= off < CLAIM_OFF + len(CLAIM_SIG):
            continue
        if img[off] not in FILLER:
            problems.append(
                "code or data at %#06x (%#06x to the console), above the %#06x "
                "ROM top; the mailbox pages must stay clear (first offender)"
                % (off, off + 0x8000, ROM_TOP - 1 + 0x8000))
            break
    return problems


def main():
    args = sys.argv[1:]
    do_stamp = False
    if args and args[0] == "--stamp":
        do_stamp = True
        args = args[1:]
    if not args:
        print(__doc__.strip(), file=sys.stderr)
        return 2

    rc = 0
    for path in args:
        # Stamping a wrong-sized image would only extend it, so size is
        # checked before anything is written.
        if do_stamp and os.path.getsize(path) == WINDOW:
            stamp(path)
        problems = check(path)
        if problems:
            rc = 1
            for p in problems:
                print("%s: %s" % (path, p), file=sys.stderr)
            os.remove(path)
        else:
            print("%s: ok" % path)
    return rc


if __name__ == "__main__":
    sys.exit(main())
