#!/usr/bin/env python3
"""layoutcheck.py manual.pdf -- geometric checks on the two-column PDF.

From `pdftotext -bbox` word boxes, column by column:
  * words outside the type area (past a side margin, or below the body floor);
  * a short all-capitals line (a sub-head) that is the last line of a column;
  * a column whose first line is short and ends a sentence (a widow);
  * a column whose last line follows a paragraph's end and is not one (an
    orphan: one line of a new paragraph left at the bottom).
US Letter, 0.72 in inside and outside, body floor 0.72 in from the bottom.
Heuristic: the eyeball pass over the preview pages is the real one. Lines
set in the H19 Screen font (screens, sessions) carry private-use characters
or box-drawing and are skipped for the paragraph checks.
"""
import re
import subprocess
import sys
from html import unescape

pdf = sys.argv[1]
xml = subprocess.run(["pdftotext", "-bbox", pdf, "-"], capture_output=True, text=True).stdout
pages = re.findall(r'<page width="([\d.]+)" height="([\d.]+)">(.*?)</page>', xml, re.S)
W, H = 612.0, 792.0
SIDE, BOT, TOP = 51.84, 51.84, 70.0
MID = W / 2
TOL = 1.5
flags = 0


def screenish(t):
    return any(0xE000 <= ord(c) <= 0xF8FF for c in t)


for n, (_, _, body) in enumerate(pages, 1):
    words = [(float(a), float(b), float(c), float(d), unescape(t)) for a, b, c, d, t in
             re.findall(r'<word xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">(.*?)</word>', body)]
    if n <= 3 or n == len(pages) or not words:   # covers and title page
        continue
    bodyw = [w for w in words if w[1] > TOP]
    for x0, y0, x1, y1, t in bodyw:
        tol = 3.5 if re.search(r"[.,;:)\-\u2014\u00ad]$", t) else TOL
        if x0 < SIDE - TOL or x1 > W - SIDE + tol:
            print("p%3d  overflow x  %.1f-%.1f  %r" % (n, x0, x1, t)); flags += 1
        if y1 > H - BOT + 4:
            print("p%3d  overflow y  %.1f  %r" % (n, y1, t)); flags += 1
    # the columns' lines
    for col, inside in (("L", lambda w: w[2] < MID + 2), ("R", lambda w: w[0] > MID - 2)):
        cw = [w for w in bodyw if inside(w)]
        lines = {}
        for w in cw:
            lines.setdefault(round(w[3]), []).append(w)
        ys = sorted(lines)
        text = [" ".join(w[4] for w in sorted(lines[y])) for y in ys]
        if len(text) < 6:
            continue
        # skip the screen and session lines
        prose = [(y, t) for y, t in zip(ys, text) if not screenish(t)]
        if len(prose) < 4:
            continue
        (fy, first), (ly, last) = prose[0], prose[-1]
        if ly < H - BOT - 90:                    # the column ends well up: a section end
            continue
        if re.fullmatch(r"[A-Z0-9 ():,'\-/&\.]{3,40}", last) and not last.endswith("."):
            print("p%3d%s stranded head?  %r" % (n, col, last)); flags += 1
        if len(first) < 30 and first.endswith((".", ":")) and not first.isupper() and fy > TOP + 40:
            print("p%3d%s widow?  %r" % (n, col, first)); flags += 1
        prev = prose[-2][1]
        if prev.endswith((".", ":")) and len(prev) < 48 and not last.endswith((".", ":")) \
           and not last.startswith("(") and not re.match(r"^[•\-\d]", last):
            print("p%3d%s orphan?  %r" % (n, col, last)); flags += 1
print("layoutcheck: %d flags over %d pages" % (flags, len(pages)))
