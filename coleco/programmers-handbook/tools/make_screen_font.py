#!/usr/bin/env python3
# Build a pixel-outline TTF from the FujiNet ColecoVision clients' 8x8
# screen font (the 5 Card Stud port's font.bin, which the games load over
# z88dk's CRT_FONT; 96 glyphs, codepoints 20H-7FH). Run under fontforge:
#   fontforge -lang=py -script make_screen_font.py <font.bin> <out.ttf>
#
# font.bin format: 96 glyphs x 8 bytes, one byte per row, bit 7 leftmost.
# The art keeps row 7 clear except for descenders, so the baseline sits
# under row 6; the advance is the full 8-pixel cell, as on the TMS9918.
import sys

import fontforge

bin_path, out_path = sys.argv[1], sys.argv[2]

data = open(bin_path, "rb").read()
if len(data) != 96 * 8:
    sys.exit(f"expected {96*8} bytes of glyph rows, found {len(data)}")

PX = 128          # one pixel = 128 em units; the 8x8 cell is 1024 x 1024
EM = 8 * PX

f = fontforge.font()
f.familyname = "Coleco Screen"
f.fontname = "ColecoScreen"
f.fullname = "Coleco Screen"
f.copyright = ("Glyph shapes from the FujiNet ColecoVision clients' 8x8 "
               "screen font (fujinet-5cardstud src/coleco/font.bin).")
f.em = EM
f.ascent = 7 * PX
f.descent = PX

for glyph in range(96):
    cp = 0x20 + glyph
    g = f.createChar(cp)
    pen = g.glyphPen()
    for r in range(8):
        byte = data[glyph * 8 + r]
        for c in range(8):
            if byte & (0x80 >> c):
                x0 = c * PX
                y1 = 7 * PX - r * PX
                y0 = y1 - PX
                pen.moveTo((x0, y0))
                pen.lineTo((x0, y1))
                pen.lineTo((x0 + PX, y1))
                pen.lineTo((x0 + PX, y0))
                pen.closePath()
    pen = None
    g.width = 8 * PX
    g.removeOverlap()
    g.correctDirection()

f.selection.all()
f.generate(out_path)
print("wrote", out_path)
