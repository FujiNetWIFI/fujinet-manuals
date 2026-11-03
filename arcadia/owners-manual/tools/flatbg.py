#!/usr/bin/env python3
"""Make the lavender gradient behind a KiCad 3D render transparent, trim.

    python3 tools/flatbg.py in.png out.png

KiCad's default background is a blue-grey gradient; the board is green,
gold, white and black.  A pixel is background when it is clearly bluish
(blue above both red and green by a margin) and not dark.
"""
import sys

import numpy as np
from PIL import Image

im = Image.open(sys.argv[1]).convert("RGBA")
a = np.array(im).astype(int)
r, g, b = a[..., 0], a[..., 1], a[..., 2]
bg = (b - r > 12) & (b - g > 12) & (b > 90)
a[bg, 3] = 0
out = Image.fromarray(a.astype(np.uint8), "RGBA")
out = out.crop(out.getbbox())
out.save(sys.argv[2])
print("wrote", sys.argv[2], out.size)
