#!/usr/bin/env python3
"""mkfigures.py -- FIGURES.md: every screen in the book, the run it came
from, and what (if anything) was put in place of the stand-in network.

Reads screens/*.json and data/screenfix.json (written by keepscreen.py).
"""
import json
import os

BOOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
fix = json.load(open(os.path.join(BOOK, "data", "screenfix.json")))
names = sorted(f[:-5] for f in os.listdir(os.path.join(BOOK, "screens")) if f.endswith(".json"))
out = ["# Figures and screens", "",
       "Every H19 screen in the book was read cell by cell from FujiNet Go H89's",
       "picture of the terminal (`tools/ppm2cells.py`), in a run of the program",
       "on the book's rig (see README.md).",
       "",
       "The rig's FujiNet is fujinet-pc on the same computer, so its screens show",
       "a stand-in network:",
       "",
       "- the WiFi network \"Dummy Cafe\";",
       "- the FujiNet at 127.0.0.1, named after the computer;",
       "- the test servers at 127.0.0.1.",
       "",
       "`tools/keepscreen.py` puts the Operation Manual's example network in their",
       "place:",
       "",
       "- the FujiNet at 192.168.1.89 on \"Workshop\", named FujiNet;",
       "- the servers at 192.168.1.10.",
       "",
       "Every replacement is listed below. Nothing else on any screen was changed.",
       "The byte strips under the command cards are never edited, so they show",
       "the stand-in values.",
       "",
       "| Screen | Run | Replaced |", "|---|---|---|"]
for n in names:
    d = json.load(open(os.path.join(BOOK, "screens", n + ".json")))
    if d.get("placeholder"):
        out.append("| %s | (to come) | |" % n)
        continue
    f = fix.get(n, {})
    rep = ", ".join("%s -> %s" % (a, b) for a, b in f.get("replaced", [])) or "nothing"
    out.append("| %s | %s | %s |" % (n, f.get("run", "?"), rep))
open(os.path.join(BOOK, "FIGURES.md"), "w").write("\n".join(out) + "\n")
print("mkfigures: %d screens" % len(names))
