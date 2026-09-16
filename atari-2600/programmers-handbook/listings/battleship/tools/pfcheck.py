#!/usr/bin/env python3
"""pfcheck.py -- the board kernel against the raster.

Decodes a MAME snapshot of the layout ROM into cells and compares every cell
of every board with tools/mklayout.py's PICTURE: which lines of the cell are
red, white, yellow or water, and whether the divider is where it should be.
dispcheck.py can only see the text block; this sees the playfield.

Deliberately not "does it look right". A hit whose white core is one line
low, a right-half write that lands one colour clock inside the left board's
last column, or a table read from the wrong pair all LOOK like a board.

Usage: pfcheck.py snapshot.png [--mode 4|2]
"""

import sys

sys.path.insert(0, __file__.rsplit('/', 1)[0])
from mklayout import PICTURE, FLEET, DIM  # noqa: E402

# The frame, in scanlines from the status row's first ink line, from
# dispgame.inc: a text row is six lines (five ink, one seam), then -- in the
# quadrant layout -- a three-line fleet strip whose own seam line IS the
# board's lead-in, then the boards.
STRIP_A = 6 + 6                                 # 12
STRIP_B = STRIP_A + 3 + 1 + 80 + 1 + 2 + 6      # 105
BOARD_A = STRIP_A + 3 + 1                       # 16
BOARD_B = STRIP_B + 3 + 1                       # 109
CELL8 = 8
# Two seats have no strips: a plain lead-in, and only the top pair.
BOARD_A12 = 6 + 6 + 1                           # 13
CELL12 = 12
# The text block is 48 pixels at clocks 52-99, four clocks a column, and the
# leftmost of a column's three ink pixels is the one sampled here.
TEXT_X0, TEXT_W = 52, 4
# MAME's a2600 snapshot: 176 pixels wide, clock 0 at x = 8, one pixel a clock.
X0 = 8


def classify(rgb):
    r, g, b = rgb
    if r > 200 and g > 200 and b > 200:
        return 'W'
    if r > 140 and g > 120 and b < r - 60:
        return 'Y'
    if r > 120 and g < 110 and b < 110 and r > g + 60:
        return 'R'
    if b > 90 and r < 90:
        return 'B'
    if r < 40 and g < 40 and b < 40:
        return 'K'
    return '?'


def expect_lines(ch, tall):
    """The colour of each line of a cell, top to bottom."""
    hit = ch in 'XH'
    mid = ch in 'XOH'
    aux = ch in '#+H'
    if tall:
        plan = ['A'] + ['H'] * 3 + ['M'] * 4 + ['H'] * 3 + ['A']
    else:
        plan = ['A', 'H', 'H', 'M', 'M', 'H', 'H', 'A']
    out = []
    for p in plan:
        if p == 'A':
            out.append('Y' if aux else 'B')
        elif p == 'H':
            out.append('R' if hit else 'B')
        else:
            out.append('W' if mid else 'B')
    return out


def main():
    from PIL import Image
    path = sys.argv[1]
    mode = 4
    if '--mode' in sys.argv:
        mode = int(sys.argv[sys.argv.index('--mode') + 1])
    im = Image.open(path).convert('RGB')
    w, h = im.size
    px = im.load()
    rows = [y for y in range(h) if any(sum(px[x, y]) > 60 for x in range(0, w, 2))]
    if not rows:
        print("FAIL: nothing drawn")
        return 1
    top = rows[0]
    print("snapshot %dx%d, first lit line %d" % (w, h, top))

    fails = 0
    tall = (mode == 2)
    cellh = CELL12 if tall else CELL8
    slots = [0, 1] if tall else [0, 1, 2, 3]

    # The fleet strips, quadrant layout only. Row 0 of '#' is {5,7,5} and of
    # '=' is {0,0,0}, so the FIRST ink line alone separates afloat from sunk:
    # ink where the fleet says afloat, black where it says sunk.
    if not tall:
        for slot in slots:
            y = top + (STRIP_B if slot >> 1 else STRIP_A)
            for i, ch in enumerate(FLEET[slot]):
                col = (slot & 1) * 6 + 1 + i
                x = X0 + TEXT_X0 + col * TEXT_W
                got = classify(px[x, y])
                want = 'K' if ch == '=' else 'Y'
                if got != want:
                    fails += 1
                    print("FAIL: slot %d pip %d '%s': want %s got %s at (%d,%d) rgb %s"
                          % (slot, i, ch, want, got, x, y, px[x, y]))

    for slot in slots:
        half, pair = slot & 1, slot >> 1
        y0 = top + (BOARD_B if pair else (BOARD_A12 if tall else BOARD_A))
        for cy in range(DIM):
            for cx in range(DIM):
                ch = PICTURE[slot][cy][cx]
                want = expect_lines(ch, tall)
                for line, colour in enumerate(want):
                    y = y0 + cy * cellh + line
                    # sample the middle of the cell, away from the divider
                    x = X0 + half * 80 + cx * 8 + 4
                    got = classify(px[x, y])
                    if got != colour:
                        fails += 1
                        if fails <= 12:
                            print("FAIL: slot %d cell (%d,%d) '%s' line %d: want %s got %s at (%d,%d) rgb %s"
                                  % (slot, cx, cy, ch, line, colour, got, x, y, px[x, y]))
        # the divider: black at clock 79-80 on a row of water
        y = y0 + 1
        for clk in (79, 80):
            x = X0 + clk
            if classify(px[x, y]) != 'K':
                fails += 1
                print("FAIL: divider missing at clock %d line %d rgb %s" % (clk, y, px[x, y]))
        for clk in (78, 81):
            x = X0 + clk
            if classify(px[x, y]) == 'K':
                fails += 1
                print("FAIL: divider too wide at clock %d line %d" % (clk, y))
    if fails:
        print("FAIL: %d cell lines differ" % fails)
        return 1
    print("PASS: %d boards, every cell line the colour the picture says, "
          "divider at 79-80%s"
          % (len(slots), "" if tall else ", fleet strips on their scanlines"))
    return 0


if __name__ == '__main__':
    sys.exit(main())
