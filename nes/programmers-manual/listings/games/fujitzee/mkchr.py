#!/usr/bin/env python3
"""mkchr.py -- build the NES pattern table for Fujitzee.

The art is the MS-DOS client's: src/msdos/charset.c, 256 glyphs of 8x8 CGA
2bpp, which is exactly an NES tile. Every glyph is carried over (identical
bitmaps share a tile), so graphics.c can draw any MS-DOS glyph number through
sheetTile[] -- the shared code's ICON_* values and the MS-DOS dice table work
unchanged.

The CGA colours are renumbered so BLACK is pixel 0, the NES's universal
background colour:

  CGA 0 blue  -> 1      background palette 0: black blue  cyan white
  CGA 1 cyan  -> 2      background palette 1: black black cyan white
  CGA 2 black -> 0
  CGA 3 white -> 3

Palette 1 is the active player's column (graphics.c setHighlight): the MS-DOS
client turns that column's blue background black, and with blue on its own
pixel value an attribute byte does the same without touching a tile.

Also generated:
  - altTile[]: drawTextAlt()'s cyan text, the MS-DOS MASK_ALT (glyph & 0x55:
    white -> cyan, black -> blue) applied to the font glyphs.
  - T_LOGO_NOBAR: glyph 0x38 (the logo's first cell) without the score-box
    border it carries for its in-game placement, as MS-DOS drawFujitzee()
    erases it for a standalone logo.
  - cursorSprite[]: the MS-DOS dice cursor -- a 30x30 two-pixel cyan/black
    checkerboard frame one pixel outside the die -- cut into the twelve
    border tiles of a 4x4 sprite grid (graphics.c placeCursor()). Sprite palette 0
    is (-, cyan, black, white), so these keep their own numbering.

The budget is the 256 tiles of the pattern table at PPU $1000 (background and
sprites both); the script fails rather than truncate.

Writes src/nes/tiles.h, src/nes/chr.s (the 4K CHARS1 segment) and
support/nes/tilemap.lua (tile -> character, for the MAME smoke test).
The Makefile runs it before every NES build.
"""

import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..', '..')
SHEET = os.path.join(ROOT, 'src', 'msdos', 'charset.c')
TILES_H = os.path.join(HERE, 'tiles.h')
CHR_S = os.path.join(HERE, 'chr.s')
TILEMAP = os.path.join(ROOT, 'support', 'nes', 'tilemap.lua')

CGA_TO_BG = {0: 1, 1: 2, 2: 0, 3: 3}
SPR_CYAN, SPR_BLACK = 1, 2

# Glyphs drawTextAlt() and drawChar(..., alt) render in cyan: the punctuation
# and digit block (ASCII 32-64 less 32) and the letters (lower-case slots;
# upper case folds onto them).
ALT_GLYPHS = list(range(0x00, 0x20)) + list(range(0x61, 0x7B))


def load_sheet():
    src = open(SHEET).read()
    body = src[src.index('{') + 1:]
    groups = re.findall(r'\{([^{}]*)\}', body)
    glyphs = [bytes(int(x, 16) for x in re.findall(r'0x([0-9A-Fa-f]{2})', g)) for g in groups]
    if len(glyphs) != 256 or any(len(g) != 16 for g in glyphs):
        raise SystemExit('mkchr: %s is not 256 glyphs of 16 bytes' % SHEET)
    tiles = []
    for b in glyphs:
        px = []
        for r in range(8):
            w = (b[r * 2] << 8) | b[r * 2 + 1]
            px.append([(w >> (14 - 2 * i)) & 3 for i in range(8)])
        tiles.append(px)
    return tiles


def chr_bytes(px):
    p0 = bytes(sum(((px[r][c] & 1) << (7 - c)) for c in range(8)) for r in range(8))
    p1 = bytes(sum((((px[r][c] >> 1) & 1) << (7 - c)) for c in range(8)) for r in range(8))
    return p0 + p1


def to_bg(px):
    return [[CGA_TO_BG[p] for p in row] for row in px]


def masked(px, mask):
    """The MS-DOS plot_glyph() mask: each 2-bit pixel ANDed with mask."""
    return [[p & mask for p in row] for row in px]


def cursor_frame():
    """The MS-DOS drawDiceCursor() frame, die-relative, as {(dx, dy): cga}."""
    pix = {}

    def ckr(x, y):
        return 2 if (x + y) & 1 else 1

    fl, fr, ft, fb = -3, 26, -3, 26
    for i in range(1, 29):
        pix[(fl + i, ft)] = ckr(fl + i, ft)
        pix[(fl + i, fb)] = ckr(fl + i, fb)
    for i in range(0, 30):
        pix[(fl + i, ft + 1)] = ckr(fl + i, ft + 1)
        pix[(fl + i, fb - 1)] = ckr(fl + i, fb - 1)
    for i in range(2, 28):
        for x in (fl, fl + 1, fr - 1, fr):
            pix[(x, ft + i)] = ckr(x, ft + i)
    return pix


def main():
    sheet = load_sheet()

    tiles, chars, index = [], {}, {}
    defs = []

    def add(px, ch):
        data = chr_bytes(px)
        if data in index:
            return index[data]
        tiles.append(data)
        chars[len(tiles) - 1] = ch
        index[data] = len(tiles) - 1
        return len(tiles) - 1

    def define(name, idx, note=''):
        defs.append('#define %-16s 0x%02X%s' % (name, idx, ('  /* %s */' % note) if note else ''))

    def glyph_char(g):
        if g < 0x20:
            return chr(g + 0x20)
        if 0x61 <= g <= 0x7A:
            return chr(g - 0x20)
        return '#'

    # Glyph 0 (all blue) first, so a blank reads as ' ', then the font, so a
    # text tile reads as its character even when an art tile shares it.
    sheetTile = [0] * 256
    for g in [0] + ALT_GLYPHS + list(range(256)):
        sheetTile[g] = add(to_bg(sheet[g]), glyph_char(g))
    define('T_BLANK', sheetTile[0])

    altTile = [0] * 128
    for g in range(128):
        altTile[g] = add(to_bg(masked(sheet[g], 0x55)), glyph_char(g)) if g in ALT_GLYPHS else sheetTile[g]

    logo = [row[:] for row in sheet[0x38]]
    for row in logo:
        row[0:4] = [0, 0, 0, 0]
    define('T_LOGO_NOBAR', add(to_bg(logo), '#'), 'glyph 0x38 without the score-box border')

    # The cursor frame on a 4x4 sprite grid whose top left is (-4, -4) from
    # the die's. The four middle tiles are empty and not emitted.
    frame = cursor_frame()
    sprTiles = []
    for ty in range(4):
        for tx in range(4):
            if 1 <= tx <= 2 and 1 <= ty <= 2:
                continue
            px = [[0] * 8 for _ in range(8)]
            for r in range(8):
                for c in range(8):
                    p = frame.get((tx * 8 - 4 + c, ty * 8 - 4 + r))
                    if p:
                        px[r][c] = SPR_CYAN if p == 1 else SPR_BLACK
            sprTiles.append((tx, ty, add(px, '#')))

    used = len(tiles)
    if used > 256:
        raise SystemExit('mkchr: %d tiles, the pattern table holds 256' % used)
    while len(tiles) < 256:
        tiles.append(bytes(16))
        chars[len(tiles) - 1] = ' '

    def table(name, values, per=16):
        out = ['static const unsigned char %s[%d] = {' % (name, len(values))]
        for i in range(0, len(values), per):
            out.append('    ' + ', '.join('0x%02X' % v for v in values[i:i + per]) + ',')
        out.append('};')
        return '\n'.join(out)

    with open(TILES_H, 'w') as f:
        f.write('/* GENERATED by src/nes/mkchr.py from src/msdos/charset.c. Tile numbers\n'
                ' * in the CHARS1 pattern table; %d of 256 used.\n'
                ' * Include from graphics.c only (it defines tables). Do not edit. */\n'
                '#ifndef TILES_H\n#define TILES_H\n\n' % used)
        f.write('\n'.join(defs) + '\n\n')
        f.write('/* MS-DOS glyph -> tile, as plotted with MASK_WHITE. */\n')
        f.write(table('sheetTile', sheetTile) + '\n\n')
        f.write('/* MS-DOS glyph 0-127 -> tile, as plotted with MASK_ALT (cyan text). */\n')
        f.write(table('altTile', altTile) + '\n\n')
        f.write('/* Dice cursor sprites: grid column, grid row (8px steps from 4px\n'
                ' * above and left of the die), tile. */\n')
        f.write('#define CURSOR_SPRITES %d\n' % len(sprTiles))
        f.write(table('cursorSprite', [v for t in sprTiles for v in t], per=3) + '\n\n')
        f.write('#endif /* TILES_H */\n')

    with open(CHR_S, 'w') as f:
        f.write('; GENERATED by src/nes/mkchr.py -- the pattern table at PPU $1000, for\n'
                '; the background and the sprites both. cc65\'s own font occupies CHARS\n'
                '; ($0000). Do not edit.\n\n        .segment "CHARS1"\n\n')
        for i, t in enumerate(tiles):
            f.write('        .byte %s ; tile $%02X\n' % (', '.join('$%02X' % b for b in t), i))

    os.makedirs(os.path.dirname(TILEMAP), exist_ok=True)
    with open(TILEMAP, 'w') as f:
        f.write('-- GENERATED by src/nes/mkchr.py: what each background tile reads as.\n'
                '-- "#" is game art, " " a blank.\n'
                'return {\n')
        for i in range(256):
            ch = chars[i]
            f.write('  [%d] = %s,\n' % (i, '"\\""' if ch == '"' else '"%s"' % ch.replace('\\', '\\\\')))
        f.write('}\n')
    print('mkchr: %d of 256 tiles' % used)


if __name__ == '__main__':
    main()
