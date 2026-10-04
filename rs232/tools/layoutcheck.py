#!/usr/bin/env python3
"""layoutcheck.py manual.pdf -- geometric checks on the typeset PDF.

Uses `pdftotext -bbox` (word boxes) and flags:
  * words outside the type area (past a side margin, or between the body
    floor at 720 pt and the footer band);
  * a heading-sized line that is the last thing in a page's body
    (a stranded heading);
  * short pages: a page whose body ends high up although the next page is
    not a chapter opener or part divider (something too big to split was
    pushed over, leaving a hole).
The page is US Letter with 1.0 in top/bottom margins, 1.05 in inside and
0.9 in outside (odd pages bind on the left).
"""
import re, subprocess, sys
from html import unescape

pdf = sys.argv[1]
xml = subprocess.run(["pdftotext", "-bbox", pdf, "-"], capture_output=True,
                     text=True).stdout
pages = re.findall(r'<page width="([\d.]+)" height="([\d.]+)">(.*?)</page>', xml, re.S)
W, H = 612.0, 792.0
TOP, BOT, INS, OUTS = 72.0, 72.0, 75.6, 64.8
TOL = 1.5
flags = 0
info = []
for n, (_, _, body) in enumerate(pages, 1):
    words = [(float(a), float(b), float(c), float(d), unescape(t)) for a, b, c, d, t in
             re.findall(r'<word xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">(.*?)</word>', body)]
    left = INS if n % 2 == 1 else OUTS
    right = W - (OUTS if n % 2 == 1 else INS)
    bodyw = [w for w in words if TOP - 2 < w[1] and w[3] < H - BOT + 6]
    for x0, y0, x1, y1, t in bodyw:
        # Typst hangs trailing punctuation and hyphens into the margin
        # (optical alignment): allow those a little more.
        tol = 3.5 if re.search(r"[.,;:)\-\u2014]$", t) else TOL
        if x0 < left - TOL or x1 > right + tol:
            print("p%3d  overflow x  %.1f-%.1f  %r" % (n, x0, x1, t)); flags += 1
    for x0, y0, x1, y1, t in words:
        if H - BOT + 4 < y1 < H - BOT + 20:      # between body floor and footer
                                                 # (4 pt for descenders)
            print("p%3d  overflow y  %.1f  %r" % (n, y1, t)); flags += 1
    # lines of the body, top to bottom
    lines = {}
    for x0, y0, x1, y1, t in bodyw:
        key = round(y1)
        lines.setdefault(key, []).append((x0, y0, x1, y1, t))
    ys = sorted(lines)
    info.append((n, ys, lines))

def is_opener(n):
    """True if page n starts a chapter/appendix or is a part divider."""
    if n > len(info):
        return True
    _, ys, lines = info[n - 1]
    text = " ".join(w[4] for y in ys[:3] for w in lines[y])
    flat = text.replace(" ", "")
    return bool(re.search(r"(CHAPTER|APPENDIX)", flat)) or (len(ys) < 12 and "PART" in flat)

for n, ys, lines in info:
    if not ys:
        continue
    last = lines[ys[-1]]
    h = max(w[3] - w[1] for w in last)
    if h > 12.2 and n < len(info):
        print("p%3d  stranded heading?  %r" % (n, " ".join(w[4] for w in last)[:60])); flags += 1
    bottom = ys[-1]
    if bottom < 560 and not is_opener(n + 1) and not is_opener(n) and n > 6:
        print("p%3d  short page: body ends at %d pt" % (n, bottom)); flags += 1
print("layoutcheck: %d flags over %d pages" % (flags, len(info)))
