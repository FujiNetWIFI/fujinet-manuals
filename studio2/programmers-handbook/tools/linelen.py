#!/usr/bin/env python3
"""linelen.py -- the handbook's own 1802 sources fit a column.

Code is quoted in the booklet's columns, about 52 characters wide at a
readable size, so every line the handbook wrote -- listings/asm/*.asm and
*.inc -- stays within 52. Lines inside osk.inc's copied blocks (between
"; >>>" and "; <<<") are CONFIG's and are left alone.

    tools/linelen.py [limit]
"""
import glob
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIMIT = int(sys.argv[1]) if len(sys.argv) > 1 else 52
bad = n = 0
for f in sorted(glob.glob(os.path.join(ROOT, "listings", "asm", "*.asm")) +
                glob.glob(os.path.join(ROOT, "listings", "asm", "*.inc"))):
    copied = False
    for k, line in enumerate(open(f).read().split("\n"), 1):
        if line.startswith("; >>>"):
            copied = True
        elif line.startswith("; <<<"):
            copied = False
            continue
        if copied:
            continue
        n += 1
        if len(line.expandtabs()) > LIMIT:
            bad += 1
            print("%s:%d: %d characters" % (os.path.relpath(f, ROOT), k, len(line)))
print("linelen: %d lines, %s" % (n, "all within %d" % LIMIT if not bad else "%d too long" % bad))
sys.exit(1 if bad else 0)
