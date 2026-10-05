#!/usr/bin/env python3
"""mkchr.py -- build the NES background pattern table for Fuji Battleship.

The art is the MS-DOS client's: support/msdos/charset.dat (the game sheet) and
support/msdos/ascii.dat (the font). Both are 8x8 CGA 2bpp, four colours, which
is exactly an NES tile -- the pixel values carry straight over and one
background palette reproduces the CGA one:

  0 blue (the universal background), 1 cyan, 2 red, 3 white

So, unlike the TMS9918 ports, nothing is recoloured per cell and every tile
uses palette 0. What the TMS ports did with a per-row colour byte -- red alt
text, the white-on-red / blue-on-cyan name plates -- becomes its own glyph set
here, baked in these four colours.

Only the sheet tiles the drawing code reaches are kept (SHEET_USED), identical
bitmaps share a tile, and the two border tiles the 24-row layout overlays on
one row (graphics.c plotTilePair) are pre-merged. The budget is the 256 tiles
of the pattern table at PPU $1000; the script fails rather than truncate.

Writes src/nes/tiles.h, src/nes/chr.s (the 4K CHARS1 segment) and
support/nes/tilemap.lua (tile -> character, for the MAME smoke test).
The Makefile runs it before every NES build.
"""

import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..', '..')
SHEET = os.path.join(ROOT, 'support', 'msdos', 'charset.dat')
ASCII = os.path.join(ROOT, 'support', 'msdos', 'ascii.dat')
TILES_H = os.path.join(HERE, 'tiles.h')
CHR_S = os.path.join(HERE, 'chr.s')
TILEMAP = os.path.join(ROOT, 'support', 'nes', 'tilemap.lua')

BLUE, CYAN, RED, WHITE = 0, 1, 2, 3

# Board chrome: drawn as-is for the active player and +0x80 (red -> cyan) for
# everyone else.
CHROME = [0x02, 0x03, 0x08, 0x09, 0x0A, 0x0B, 0x20, 0x21, 0x22, 0x23, 0x24,
          0x25, 0x27, 0x28, 0x29, 0x2C, 0x2D, 0x2E, 0x2F, 0x31, 0x5C, 0x5D,
          0x5E, 0x5F, 0x60]
# Everything else src/nes/graphics.c or the shared code (vars.h ICON_*) draws.
OTHER = ([0x00, 0x05, 0x19, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F, 0x2A, 0x2B]
         + list(range(0x32, 0x49))      # ships, hit, icons, box, line, cursor
         + [0x5B, 0xE1, 0xE2]
         + list(range(0xE3, 0xE9)))     # attack animation, 217 + 10..15
SHEET_USED = sorted(set(CHROME + [c + 0x80 for c in CHROME] + OTHER))

# The shared border row where two boards meet (graphics.c plotTilePair).
PAIRS = [(a + add, b + add)
         for add in (0x00, 0x80)
         for a, b in [(0x08, 0x0A), (0x0A, 0x08), (0x27, 0x29), (0x29, 0x27),
                      (0x09, 0x0B), (0x0B, 0x09)]]

# Name plates: names are letters and digits (the server lowercases them).
NAME_CHARS = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'


def load(path):
    data = open(path, 'rb').read()
    tiles = []
    for t in range(256):
        b = data[t * 16:t * 16 + 16]
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


def merge(a, b):
    return [[pa if pa else pb for pa, pb in zip(ra, rb)] for ra, rb in zip(a, b)]


def recolour(px, ink, paper):
    return [[ink if p else paper for p in row] for row in px]


def main():
    sheet = load(SHEET)
    font = load(ASCII)

    tiles, chars, index = [], {}, {}
    defs = []

    def add(px, ch, share=True):
        data = chr_bytes(px)
        if share and data in index:
            return index[data]
        tiles.append(data)
        chars[len(tiles) - 1] = ch
        if share:
            index[data] = len(tiles) - 1
        return len(tiles) - 1

    def define(name, idx, note=''):
        defs.append('#define %-16s 0x%02X%s' % (name, idx, ('  /* %s */' % note) if note else ''))

    blank = [[BLUE] * 8 for _ in range(8)]
    define('T_BLANK', add(blank, ' '))

    # Font first, so a text tile reads as its character in tilemap.lua even
    # when a sheet tile happens to share the bitmap. Lower case folds onto
    # upper case: the MS-DOS font draws them the same.
    fontTile = []
    for c in range(0x20, 0x80):
        g = c - 0x20 if not (0x61 <= c <= 0x7A) else c - 0x40
        fontTile.append(add(font[0x20 + g], chr(0x20 + g)))

    sheetTile = [0] * 256
    for n in SHEET_USED:
        sheetTile[n] = add(sheet[n], '#')

    pairTile = []
    for a, b in PAIRS:
        pairTile.append(add(merge(sheet[a], sheet[b]), '#'))

    # drawTextAlt: capitals in red.
    define('T_ALT_A', len(tiles), "'A'..'Z', red on blue")
    for c in range(26):
        add(recolour(font[0x41 + c], RED, BLUE), chr(0x41 + c), share=False)

    # Name plates: white on red for the player whose turn it is, blue on cyan
    # for the rest -- the plate tiles 0x60 / 0xE0 are solid red / cyan.
    define('T_NAME_ON', len(tiles), 'NAME_CHARS order, white on red')
    for ch in NAME_CHARS:
        add(recolour(font[ord(ch)], WHITE, RED), ch, share=False)
    define('T_NAME_OFF', len(tiles), 'NAME_CHARS order, blue on cyan')
    for ch in NAME_CHARS:
        add(recolour(font[ord(ch)], BLUE, CYAN), ch, share=False)

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
        f.write('/* GENERATED by src/nes/mkchr.py from support/msdos/charset.dat and\n'
                ' * ascii.dat. Tile numbers in the CHARS1 pattern table; %d of 256 used.\n'
                ' * Include from graphics.c only (it defines tables). Do not edit. */\n'
                '#ifndef TILES_H\n#define TILES_H\n\n' % used)
        f.write('\n'.join(defs) + '\n\n')
        f.write('#define NAME_CHARS "%s"\n\n' % NAME_CHARS)
        f.write('/* MS-DOS sheet index -> tile. Unlisted indices are blank. */\n')
        f.write(table('sheetTile', sheetTile) + '\n\n')
        f.write('/* ASCII 0x20-0x7F -> tile, white on blue. */\n')
        f.write(table('fontTile', fontTile) + '\n\n')
        f.write('/* Merged border pairs, in plotTilePair() order: for add 0x00 then\n'
                ' * 0x80, (08,0A) (0A,08) (27,29) (29,27) (09,0B) (0B,09). */\n')
        f.write(table('pairTile', pairTile, per=6) + '\n\n')
        f.write('#endif /* TILES_H */\n')

    with open(CHR_S, 'w') as f:
        f.write('; GENERATED by src/nes/mkchr.py -- the background pattern table at PPU $1000.\n'
                '; cc65\'s own font occupies CHARS ($0000); this is the one the game points\n'
                '; PPUCTRL at. Do not edit.\n\n        .segment "CHARS1"\n\n')
        for i, t in enumerate(tiles):
            f.write('        .byte %s ; tile $%02X\n' % (', '.join('$%02X' % b for b in t), i))

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
