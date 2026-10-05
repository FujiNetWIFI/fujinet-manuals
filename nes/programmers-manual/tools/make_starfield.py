#!/usr/bin/env python3
"""make_starfield.py -- the black starfield of the 1985 Nintendo black-box
covers: scattered white, blue and pink points, a few with four-point glints,
and a handful of big lens-flared blue stars.

Usage: make_starfield.py out.png [seed]   (7.5 x 5.75 in at 200 dpi)"""
import math, random, sys
from PIL import Image, ImageDraw, ImageFilter

W, H = 1500, 1150
out = sys.argv[1]
rnd = random.Random(int(sys.argv[2]) if len(sys.argv) > 2 else 1985)

base = Image.new("RGB", (W, H), (1, 1, 1))
glow = Image.new("RGB", (W, H), (0, 0, 0))
d, g = ImageDraw.Draw(base), ImageDraw.Draw(glow)

TINTS = [(255, 255, 255)] * 6 + [(170, 200, 255)] * 3 + [(255, 170, 205)] * 2

def star(x, y, r, col, glint=0):
    d.ellipse((x - r, y - r, x + r, y + r), fill=col)
    if glint:
        for ang in (0, math.pi / 2, math.pi / 4, 3 * math.pi / 4)[: 2 if glint < 2 else 4]:
            L = r * (5 if ang in (0, math.pi / 2) else 3) * glint
            dx, dy = math.cos(ang) * L, math.sin(ang) * L
            g.line((x - dx, y - dy, x + dx, y + dy), fill=col, width=max(1, int(r / 2)))
        g.ellipse((x - 3 * r, y - 3 * r, x + 3 * r, y + 3 * r), fill=tuple(c // 3 for c in col))

for _ in range(520):                       # dust
    star(rnd.uniform(0, W), rnd.uniform(0, H), rnd.choice((0.6, 0.8, 1.0, 1.2)),
         tuple(int(c * rnd.uniform(0.35, 0.9)) for c in rnd.choice(TINTS)))
for _ in range(70):                        # points with a glint
    star(rnd.uniform(0, W), rnd.uniform(0, H), rnd.uniform(1.4, 2.4),
         rnd.choice(TINTS), glint=1)
for _ in range(9):                         # the big blue flares
    star(rnd.uniform(40, W - 40), rnd.uniform(40, H - 40), rnd.uniform(3.0, 4.5),
         (150, 190, 255), glint=2)

glow = glow.filter(ImageFilter.GaussianBlur(2.2))
img = Image.blend(base, glow, 0.0)
px, gp = img.load(), glow.load()
img = Image.eval(base, lambda v: v)
from PIL import ImageChops
img = ImageChops.add(base, glow, scale=0.85)
img.save(out, optimize=True)
print("starfield:", out)
