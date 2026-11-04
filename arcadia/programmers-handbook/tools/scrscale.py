#!/usr/bin/env python3
"""scrscale.py in.png out.png [kx ky] -- an Arcadia screen at print size.

MAME's Arcadia snapshot is the 2637's whole raster, 192 x 262, which MAME
shows at 4:3: each pixel is 1.82 times as wide as it is tall. Every pixel is
copied kx across and ky down (default 9 x 5, 1.8:1), so the picture keeps
its shape and its pixels stay square-edged and sharp.
"""
import sys

from PIL import Image

src, dst = sys.argv[1], sys.argv[2]
kx, ky = (int(sys.argv[3]), int(sys.argv[4])) if len(sys.argv) > 4 else (9, 5)
im = Image.open(src).convert("RGB")
w, h = im.size
im.resize((w * kx, h * ky), Image.NEAREST).save(dst, optimize=True)
print(f"{dst}: {w}x{h} -> {w * kx}x{h * ky}")
