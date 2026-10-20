#!/usr/bin/env python3
"""fixeras.py -- repair ITC Eras Std's OS/2 cap and x heights in place.

The vendored TTFs report sCapHeight 666 and sxHeight 494 (of 2048), about
half the real glyphs, so Typst's default top edge (cap-height) sets lines
on top of each other. Measure H and x and write the true values.
"""
import sys
from fontTools.ttLib import TTFont
from fontTools.pens.boundsPen import BoundsPen

for path in sys.argv[1:]:
    f = TTFont(path)
    gs, cm = f.getGlyphSet(), f.getBestCmap()
    def top(ch):
        p = BoundsPen(gs)
        gs[cm[ord(ch)]].draw(p)
        return p.bounds[3]
    os2 = f["OS/2"]
    os2.sCapHeight, os2.sxHeight = round(top("H")), round(top("x"))
    f.save(path)
    print(f"{path}: cap {os2.sCapHeight} x {os2.sxHeight}")
