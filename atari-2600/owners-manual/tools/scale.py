#!/usr/bin/env python3
"""Scale raw MAME 2600 snapshots to the shape a TV gives them.

    python3 tools/scale.py images/screens/raw images/screens [name ...]

A 2600 pixel is one colour clock wide and one scanline tall, which a TV
shows about 1.7 times wider than tall (MAME frames its 176x223 snapshot at
4:3, ratio 1.69).  Nearest-neighbour x5 by x3 (1.667) keeps every pixel
hard and the file small; the book prints them at about 650 dpi.
"""
import os
import sys

from PIL import Image

SX, SY = 5, 3
src, dst = sys.argv[1], sys.argv[2]
# close-ups: a screen whose text is a narrow column in the middle of the TV
# is cropped to that column (x0 y0 x1 y1, raw pixels) so it reads in print
CROPS = {}
cf = os.path.join(src, "crops.txt")
if os.path.exists(cf):
    for line in open(cf):
        p = line.split("#")[0].split()
        if len(p) == 5:
            CROPS[p[0]] = tuple(int(v) for v in p[1:])
names = sys.argv[3:] or sorted(f[:-4] for f in os.listdir(src) if f.endswith(".png"))
os.makedirs(dst, exist_ok=True)
for n in names:
    im = Image.open(os.path.join(src, n + ".png")).convert("RGB")
    if n in CROPS:
        im = im.crop(CROPS[n])
    out = im.resize((im.width * SX, im.height * SY), Image.NEAREST)
    out.save(os.path.join(dst, n + ".png"), optimize=True)
    print("scaled", n, im.size, "->", out.size)
