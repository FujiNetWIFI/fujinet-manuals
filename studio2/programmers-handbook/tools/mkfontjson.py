#!/usr/bin/env python3
"""mkfontjson.py -- the cartridge's 3 x 5 font, for the book to draw.

Reads s2_font.c from the firmware at the pinned revision and writes
images/art/s2font.json: for each code $00-$7F, its five rows, one number
each, bit 2 the leftmost dot. lib.typ's s2ch() draws a character from it,
so the symbols in the text look as they do on the television.

    tools/mkfontjson.py [firmware-root [revision]]
"""
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FW = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/Workspace/fn-studio2-board")
REV = sys.argv[2] if len(sys.argv) > 2 else "07e9bbaa9"
src = subprocess.run(["git", "-C", FW, "show", REV + ":pico/studio2/firmware/src/s2_font.c"],
                     capture_output=True, text=True, check=True).stdout
rows = [[int(v, 8) for v in m.group(1).split(",")]
        for m in re.finditer(r"\{\s*([0-7 ,]+?)\s*\},\s*/\*", src)]
assert len(rows) == 128, len(rows)
out = os.path.join(ROOT, "images", "art", "s2font.json")
json.dump({"%02X" % i: r for i, r in enumerate(rows)}, open(out, "w"))
print("mkfontjson: 128 characters -> %s" % os.path.relpath(out, ROOT))
