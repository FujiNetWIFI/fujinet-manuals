#!/usr/bin/env python3
# Build a pixel-outline TTF from the FujiNet 2600 cartridge's 3x5 screen font
# (the glyph table the RP2040 composes text with). Run under fontforge:
#   fontforge -lang=py -script make_screen_font.py <fn-2600 tools dir> <out.ttf>
#
# The single source of the glyph shapes is tools/vcsfont.py in the cartridge
# bring-up (its `_F` dict is what generates firmware/include/vcs_font.h), so
# this imports it rather than carrying a copy: a font that drifted from the
# cartridge would show a '5' where the console shows an 'S'.
#
# Geometry (fuji_mailbox.h): a 3x5 glyph in a 4x6 cell -- 3 pixels of ink, one
# of gap, 5 rows of ink, one blank row of leading. Advance is the whole cell.
import sys

import fontforge

tools_dir, out_path = sys.argv[1], sys.argv[2]
sys.path.insert(0, tools_dir)
from vcsfont import _F, INK_H  # noqa: E402

PX = 170                     # one pixel = 170 em units; the 4x6 cell is 680 x 1020
EM = 6 * PX

f = fontforge.font()
f.familyname = "VCS Screen"
f.fontname = "VCSScreen"
f.fullname = "VCS Screen"
f.copyright = ("Glyph shapes from the FujiNet Atari 2600 cartridge's 3x5 "
               "screen font (pico/atari-2600/tools/vcsfont.py).")
f.em = EM
f.ascent = 5 * PX
f.descent = PX

for cp in range(0x20, 0x80):
    ch = chr(cp)
    rows = _F.get(ch)
    if rows is None:
        rows = _F.get(ch.upper(), _F['?'])
    g = f.createChar(cp)
    pen = g.glyphPen()
    for r in range(INK_H):
        for c in range(3):
            if rows[r][c] == '#':
                x0 = c * PX
                y1 = 5 * PX - r * PX
                y0 = y1 - PX
                pen.moveTo((x0, y0))
                pen.lineTo((x0, y1))
                pen.lineTo((x0 + PX, y1))
                pen.lineTo((x0 + PX, y0))
                pen.closePath()
    pen = None
    g.width = 4 * PX
    g.removeOverlap()
    g.correctDirection()

f.selection.all()
f.generate(out_path)
print("wrote", out_path)
