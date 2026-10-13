#!/usr/bin/env python3
# Build "H19 Screen", a pixel-outline TTF of the H19 terminal's character
# generator ROM (444-29), for the book's screens and listings. Run under
# fontforge:
#   fontforge -lang=py -script tools/make_h19_font.py <444-29 rom> fonts/H19Screen.ttf
#
# The ROM holds 128 glyphs x 16 bytes; the H19 shows rows 0-9 of each, bit 7
# leftmost (as FujiNet Go H89's H19Render does). Glyphs 20H-7FH are ASCII and
# keep their code points; 00H-1FH are the graphics set (ESC F), placed at
# U+E000-U+E01F. The H19's pixels are about twice as tall as wide, so a pixel
# here is 100 units wide and 200 tall: the 8 x 10 cell is 800 x 2000, the em
# is the cell height, and the advance is 0.4 em.
import sys

import fontforge

rom_path, out_path = sys.argv[1], sys.argv[2]
rom = open(rom_path, "rb").read()
if len(rom) != 2048:
    sys.exit(f"expected the 2048-byte 444-29 ROM, found {len(rom)} bytes")

PW, PH = 100, 200
BLEED = 30
ROWS = 10
f = fontforge.font()
f.familyname = "H19 Screen"
f.fontname = "H19Screen"
f.fullname = "H19 Screen"
f.copyright = ("Glyph shapes traced from the Heath H19 terminal's character "
               "generator ROM (444-29), for the FujiNet H89 Operation Manual.")
f.em = ROWS * PH
f.ascent = 8 * PH
f.descent = 2 * PH

for idx in range(128):
    cp = idx if idx >= 0x20 else 0xE000 + idx
    if idx == 0x7F:
        cp = 0xE07F                      # the ROM's 7FH is a solid glyph, not DEL
    g = f.createChar(cp)
    pen = g.glyphPen()
    for r in range(ROWS):
        bits = rom[idx * 16 + r]
        for c in range(8):
            if bits & (0x80 >> c):
                # each pixel reaches a hair into its right and lower
                # neighbours, so lines drawn cell by cell show no seams
                x0 = c * PW
                y1 = 8 * PH - r * PH
                y0 = y1 - PH - BLEED
                pen.moveTo((x0, y0))
                pen.lineTo((x0, y1))
                pen.lineTo((x0 + PW + BLEED, y1))
                pen.lineTo((x0 + PW + BLEED, y0))
                pen.closePath()
    pen = None
    g.width = 8 * PW
    g.removeOverlap()
    g.correctDirection()

# a few typographic stand-ins the book's listings may contain
for cp, src in ((0x00A0, 0x20),):
    f.createChar(cp)
    f.selection.select(src)
    f.copy()
    f.selection.select(cp)
    f.paste()

f.selection.all()
f.generate(out_path)
print("wrote", out_path)
