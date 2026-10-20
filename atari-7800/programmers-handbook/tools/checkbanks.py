#!/usr/bin/env python3
"""checkbanks.py -- checkrom.py's rules for a SuperGame image built by ld65.

    checkbanks.py --map prog.map prog.bin

fujinet-lib's romstamp takes flat images of at most 48K, and checkrom.py reads
an image top-aligned, so neither can see code in a switched bank: every bank
runs at $8000 but lives at its own place in the file. This scans each BANKn
segment the map lists at file offset n * $4000, and the fixed bank's code
segments at their own addresses, with checkrom.py's scanner (no RMW on the
mailbox's write pages, no store to $00-$1F, no JMP ($xxFF)), then runs
checkrom.py itself for the claim and the vectors.
"""
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from checkrom import scan, CODE_SEGS  # noqa: E402


def main():
    args = sys.argv[1:]
    mapfile = args[args.index("--map") + 1]
    path = [a for a in args if not a.startswith("--") and a != mapfile][0]
    img = open(path, "rb").read()
    if len(img) % 0x4000:
        sys.exit("checkbanks: %s is not whole 16K banks" % path)
    text = open(mapfile).read()
    seglist = re.search(r"Segment list:\s*\n-+\s*\n(.*?)\n\n", text, re.S).group(1)
    bad = []
    for line in seglist.splitlines():
        parts = line.split()
        if len(parts) < 4 or not re.fullmatch(r"[0-9A-Fa-f]{6}", parts[1]):
            continue
        name, lo, hi = parts[0], int(parts[1], 16), int(parts[2], 16)
        m = re.fullmatch(r"BANK(\d+)", name)
        if m:
            off = int(m.group(1)) * 0x4000 + (lo - 0x8000)
        elif name in CODE_SEGS:
            off = len(img) - (0x10000 - lo)
        else:
            continue
        bad += scan(img[off:], hi + 1 - lo, lo, "%s $%04X-$%04X" % (name, lo, hi), True)
    for b in bad:
        print("checkbanks: %s: %s" % (path, b), file=sys.stderr)
    if bad:
        sys.exit(1)
    rc = subprocess.call([sys.executable, os.path.join(os.path.dirname(__file__), "checkrom.py"),
                          "--claim", "--notia", "--map", mapfile, path])
    sys.exit(rc)


if __name__ == "__main__":
    main()
