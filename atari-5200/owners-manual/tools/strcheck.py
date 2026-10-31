#!/usr/bin/env python3
"""strcheck.py -- every screen word the book quotes is in the sources.

The book sets what a screen says with #scr("..."). Each one must be found,
character for character, in CONFIG's 5200 source or in one of the games'
(paths below, relative to ~/Workspace), in the game servers' move names, or
on a screen the tours captured (build/tour/*.log, read back from the
console's memory). A quote with a number the program fills in
(?LOAD ERROR 01, HOST 3, -42) is looked for without the number, a keyboard
prompt without the "?" CONFIG adds, and CONFIG's "?WHAT ERROR" by its WHAT;
a single character is not looked for at all.

    python3 tools/strcheck.py
"""
import glob
import os
import re
import sys

W = os.path.expanduser("~/Workspace")
TREES = ["fujinet-config/atari5200", "fcs-5200/src", "th-5200/src", "bs-5200/src",
         "fz-5200/src", "fk-5200/src",
         "fujinet-multiplayer-mule/clients/mekkogx/src"]
files = [f for t in TREES
         for f in glob.glob(os.path.join(W, t, "**", "*.[chs]"), recursive=True)]
files += [os.path.join(W, "fujinet-multiplayer-mule/clients/mekkogx/Makefile")]
files += glob.glob("build/servers/fujinet-game-system/*/server/*.go")
files += glob.glob("build/tour/*.log")
text = "".join(open(f, errors="replace").read() for f in files)
# M.U.L.E. builds its prompts from macros its Makefile sets for the 5200
# ("UP/DOWN, " BUTTON_NAME ...): put the values in
mk = open(os.path.join(W, "fujinet-multiplayer-mule/clients/mekkogx/Makefile")).read()
block = mk[mk.index("CFLAGS_EXTRA_ATARI5200"):].split("\nEXTRA_INCLUDE")[0]
for name, val in re.findall(r"-D(\w+)='\"(.*?)\"'", block):
    text = text.replace(f'" {name} "', val)
# Texas Hold'em's font draws "/" and "-" where the tour's reading of its
# screen says "|" and "}"
text += open("build/tour/th-table.log", errors="replace").read().replace(
    "|", "/").replace("}", "-") if os.path.exists("build/tour/th-table.log") else ""
lower = text.lower()

bad = 0
seen = set()
for part in sorted(glob.glob("parts/*.typ")):
    src = open(part).read()
    for m in re.finditer(r'#scr\("((?:[^"\\]|\\.)*)"\)', src):
        q = m.group(1).replace('\\"', '"').replace("\\\\", "\\")
        q = re.sub(r"\s+", " ", q)
        if q in seen or len(q) <= 1:
            continue
        seen.add(q)
        stem = re.sub(r"[ ]?-?\d+$", "", q)
        if not stem.strip():
            continue                      # a number alone (a signal strength)
        if q in text or stem in text:
            continue
        if q.endswith("?") and q[:-1] in text:
            continue                      # a keyboard prompt
        e = re.fullmatch(r"\?([A-Z ]+) ERROR", stem)
        if e and f'"{e.group(1)}"' in text:
            continue                      # CONFIG's "?%s ERROR %02X"
        # the games keep some lines in lower case and draw them in capitals
        if stem.lower() in lower:
            continue
        print(f"{part}: not in the sources: {q!r}")
        bad += 1
print(f"strcheck: {len(seen)} quotes, {bad} not found")
sys.exit(1 if bad else 0)
