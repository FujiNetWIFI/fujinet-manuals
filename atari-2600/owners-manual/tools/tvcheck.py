#!/usr/bin/env python3
"""Every typeset TV screen must fit the cartridge's display: at most 21 rows
of at most 12 characters, every character one the cartridge's font draws.

    python3 tools/tvcheck.py screens

A row may start "@#rrggbb " to colour it (lib.typ's tvtext); that prefix is
not part of the row.  The font is the cartridge's own 3x5 table, so the
printable ASCII range 0x20-0x7E is the whole of it.
"""
import os
import sys

d = sys.argv[1] if len(sys.argv) > 1 else "screens"
bad = 0
for f in sorted(os.listdir(d)):
    if not f.endswith(".txt"):
        continue
    rows = open(os.path.join(d, f), encoding="utf-8").read().split("\n")
    if rows and rows[-1] == "":
        rows.pop()
    if len(rows) > 21:
        print(f"{f}: {len(rows)} rows (max 21)")
        bad += 1
    for i, r in enumerate(rows):
        if r.startswith("@#"):
            r = r[9:]
        if len(r) > 12:
            print(f"{f}:{i}: {len(r)} columns (max 12): {r!r}")
            bad += 1
        for ch in r:
            if not 0x20 <= ord(ch) <= 0x7E:
                print(f"{f}:{i}: {ch!r} is not in the cartridge's font")
                bad += 1
print("tvcheck:", "ok" if not bad else f"{bad} problem(s)")
sys.exit(1 if bad else 0)
