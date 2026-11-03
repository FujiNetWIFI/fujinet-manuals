#!/usr/bin/env python3
"""strcheck.py -- every screen word the book quotes is in the sources.

The book sets what a screen says with #scr("..."). Each one must be found,
character for character, in one of the Arcadia programs' sources as
emu/getsrc.sh archived them (build/src: CONFIG, the Lobby, 5 Card Stud,
Texas Hold'em, Battleship, Fujitzee), in M.U.L.E.'s Arcadia client, in the
game servers' sources, or on a screen the tours captured (build/tour/*.log,
read back from the console's memory). The 2650 sources split a line where
its colour changes (DB 1,"7",1," WIFI"), so the DB strings of each line are
also joined. A quote with a number the program fills in (8/63, 34) is
looked for without the number; a single character is not looked for at all.

    python3 tools/strcheck.py
"""
import glob
import os
import re
import sys

W = os.path.expanduser("~/Workspace")
files = glob.glob("build/src/*/arcadia/*.inc") + glob.glob("build/src/*/arcadia/*.asm")
files += glob.glob(os.path.join(W, "fujinet-multiplayer-mule/clients/arcadia/src/*.inc"))
files += glob.glob(os.path.join(W, "fujinet-multiplayer-mule/clients/arcadia/*.txt"))
files += glob.glob("build/servers/fujinet-game-system/*/server/*.go")
files += glob.glob("build/tour/*.log")
if not glob.glob("build/src/config/arcadia/*.inc"):
    sys.exit("strcheck: run emu/getsrc.sh first (build/src is empty)")
parts = []
for f in files:
    t = open(f, errors="replace").read()
    parts.append(t)
    if f.endswith((".inc", ".asm")):
        # the DB strings of a statement, joined
        for line in t.splitlines():
            ss = re.findall(r'"([^"]*)"', line.split(";")[0])
            if len(ss) > 1:
                parts.append("".join(ss))
text = "\n".join(parts)
upper = text.upper()

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
        stem = re.sub(r"[ ]?-?\d+(/\d+)?%?$", "", q)
        if not stem.strip():
            continue                      # a number alone
        if q.upper() in upper or stem.upper() in upper:
            continue                      # the Arcadia has only capitals
        print(f"{part}: not in the sources: {q!r}")
        bad += 1
print(f"strcheck: {len(seen)} quotes, {bad} not found")
sys.exit(1 if bad else 0)
