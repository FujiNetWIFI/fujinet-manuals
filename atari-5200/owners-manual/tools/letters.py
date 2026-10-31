"""letters -- lettering as geometry, so it foreshortens with the face it sits on.

Text is rasterised with Pillow and every run of ink pixels on a row becomes a
thin box (the 2600 Owner's Manual's trick, tools/make_cart_bits.py there).
Two planes are needed here: a FRONT face read from -y (the player's side of
the console and the cartridge's label), and a TOP face read from above with
+y pointing away from the reader (the controller's keys).
"""
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFont

from stlkit import box, cat

FONTS = os.path.join(os.path.dirname(__file__), "..", "fonts")


def text_img(s, font, size, track=0):
    f = ImageFont.truetype(os.path.join(FONTS, font), size)
    w = int(sum(f.getlength(ch) + track for ch in s)) + 4
    h = int(size * 1.4)
    im = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(im)
    x = 2
    for ch in s:
        d.text((x, 0), ch, fill=255, font=f)
        x += f.getlength(ch) + track
    return im.crop(im.getbbox())


def _runs(img):
    a = np.array(img) > 127
    for r in range(a.shape[0]):
        row = a[r]
        c = 0
        while c < len(row):
            if row[c]:
                e = c
                while e < len(row) and row[e]:
                    e += 1
                yield r, c, e
                c = e
            else:
                c += 1


def ink_front(img, xc, zc, h, y0, y1):
    """A face read from -y: the image centred on (xc, zc), `h` mm tall,
    standing between y0 and y1 (y0 < y1, y0 nearer the reader)."""
    mm = h / img.height
    x0 = xc - img.width * mm / 2
    z1 = zc + h / 2
    return cat(*[box(x0 + c * mm, x0 + e * mm, y0, y1,
                     z1 - (r + 1) * mm, z1 - r * mm) for r, c, e in _runs(img)])


def ink_top(img, xc, yc, h, z0, z1):
    """A face read from above, +y away from the reader: the image centred on
    (xc, yc), `h` mm from its top row to its bottom one, between z0 and z1."""
    mm = h / img.height
    x0 = xc - img.width * mm / 2
    y1 = yc + h / 2
    return cat(*[box(x0 + c * mm, x0 + e * mm, y1 - (r + 1) * mm, y1 - r * mm,
                     z0, z1) for r, c, e in _runs(img)])
