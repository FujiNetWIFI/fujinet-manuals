#!/usr/bin/env python3
# Build an 8x8 pixel-outline TTF from the Intellivision GROM character set
# (grom.bin cards 0-63 = ASCII 32-95). Run under fontforge:
#   fontforge -script make_grom_font.py <grom.bin> <out.ttf>
import sys
import fontforge
import psMat

grom_path, out_path = sys.argv[1], sys.argv[2]
data = open(grom_path, 'rb').read()

PX = 125          # one pixel = 125 em units; 8 px = 1000 = full em advance
EM = 1000

f = fontforge.font()
f.familyname = "Intellivision GROM"
f.fontname = "IntellivisionGROM"
f.fullname = "Intellivision GROM"
f.copyright = "Glyph shapes from the Intellivision GROM character set (Mattel, 1979)."
f.em = EM
f.ascent = 875
f.descent = 125

for card in range(64):
    cp = 32 + card
    g = f.createChar(cp)
    pen = g.glyphPen()
    rows = data[card*8:(card+1)*8]
    for r, byte in enumerate(rows):
        for c in range(8):
            if byte & (0x80 >> c):
                x0 = c * PX
                # row 0 = top; put glyph top at ascent, bottom row base at -125
                y1 = 875 - r * PX
                y0 = y1 - PX
                pen.moveTo((x0, y0))
                pen.lineTo((x0, y1))
                pen.lineTo((x0 + PX, y1))
                pen.lineTo((x0 + PX, y0))
                pen.closePath()
    pen = None
    g.width = EM
    g.removeOverlap()
    g.correctDirection()

# map lowercase a-z to the uppercase cards so stray lowercase still renders
for i in range(26):
    src = 33 + i   # 'A'+i codepoint = 65+i -> card 33+i; cp 97+i
    g = f.createChar(97 + i)
    g.addReference(f[65 + i].glyphname)
    g.useRefsMetrics(f[65 + i].glyphname)
    g.width = EM

f.selection.all()
f.generate(out_path)
print("wrote", out_path)
