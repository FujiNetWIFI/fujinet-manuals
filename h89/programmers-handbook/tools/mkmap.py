#!/usr/bin/env python3
"""mkmap.py -- the ISS tracker's world map, as assembly and as C.

Reads the 72 x 18 ASCII-art map of the Earth (NASA's Blue Marble, drawn in
characters) from fujinet-iss-tracker's rc2014/src/blue_marb_ascii_72.h,
where it is a C array of bytes, and writes it as 18 readable strings:

  src/asm/iss/map.inc     map_rows: 18 x defm "...72 characters..."
  src/c/iss/map.h         static const char map[18][73] = { "...", ... };

Copyright (C) 2026 Thomas Cherryhomes
SPDX-License-Identifier: GPL-3.0-or-later
"""
import os
import re
import sys

BOOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.expanduser(sys.argv[1] if len(sys.argv) > 1 else
                         "~/Workspace/fujinet-iss-tracker/rc2014/src/blue_marb_ascii_72.h")
text = open(SRC).read()
data = bytes(int(h, 16) for h in re.findall(r"0x([0-9a-fA-F]{2})", text))
rows = data.decode("ascii").split("\n")
rows = [r.ljust(72)[:72] for r in rows if r != ""]
assert len(rows) == 18, len(rows)
head = ("the world, 72 x 18: NASA's Blue Marble as characters, from\n"
        "fujinet-iss-tracker (rc2014/src/blue_marb_ascii_72.h), GPL-3.0.\n"
        "Made by tools/mkmap.py; do not edit.")
with open(os.path.join(BOOK, "src", "asm", "iss", "map.inc"), "w") as f:
    f.write("".join("; " + l + "\n" for l in head.split("\n")))
    f.write("MAP_W           equ     72\nMAP_H           equ     18\nmap_rows:\n")
    for r in rows:
        f.write('        defm    "%s"\n' % r)
with open(os.path.join(BOOK, "src", "c", "iss", "map.h"), "w") as f:
    f.write("/*\n" + "".join(" * " + l + "\n" for l in head.split("\n")) + " */\n")
    f.write("#define MAP_W 72\n#define MAP_H 18\n\nstatic const char map[MAP_H][MAP_W + 1] = {\n")
    for r in rows:
        f.write('    "%s",\n' % r)
    f.write("};\n")
print("mkmap: 18 rows of 72")
