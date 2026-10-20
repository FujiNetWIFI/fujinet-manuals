#!/usr/bin/env python3
"""mkchr.py -- build the MARIA tile set for Fuji Battleship on the Atari 7800.

The art is the MS-DOS client's, as on the NES: support/msdos/charset.dat (the
game sheet) and support/msdos/ascii.dat (the font), 8x8 CGA 2bpp. MARIA's
320B cells are 2bpp too, but the engine (maria.h) gives a screen 128 tiles
and two palettes of three colours, so where the NES baked a colour pair into
extra glyph sets this uses the two palettes instead:

  palette 0  1 white  2 red   3 white     text, active board chrome
  palette 1  1 red    2 cyan  3 white     red capitals, inactive chrome, art

The font draws in value 1, so the same glyph is white text in palette 0 and
red alternate text in palette 1. Chrome draws red as 2 and white as 3, so the
active (palette 0) and inactive (palette 1, red -> cyan) boards share tiles.
Other art is recoded to palette 1. A tile that is only white or blank looks
the same in both and is marked AGNOSTIC: drawing it leaves the cell's palette
alone. Name plates have no glyph set of their own: names are font text over
the plate tile.

The font sits at its ASCII codes ($20-$5F, so tile $20 is the blank) and the
art fills $00-$1F and $60-$7F. Identical bitmaps share a tile; the script
fails rather than truncate.

Writes build/atari7800/art.chr (NES CHR layout), runs mktiles.py on it into
src/atari7800/tiles.s, and writes src/atari7800/tiles.h and
support/atari7800/tilemap.lua (tile -> character, for the MAME smoke test).
The Makefile runs it before every 7800 build.
"""

import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..', '..')
SHEET = os.path.join(ROOT, 'support', 'msdos', 'charset.dat')
ASCII = os.path.join(ROOT, 'support', 'msdos', 'ascii.dat')
CHR = os.path.join(ROOT, 'build', 'atari7800', 'art.chr')
TILES_S = os.path.join(HERE, 'tiles.s')
TILES_H = os.path.join(HERE, 'tiles.h')
TILEMAP = os.path.join(ROOT, 'support', 'atari7800', 'tilemap.lua')

BLUE, CYAN, RED, WHITE = 0, 1, 2, 3
PAL_TEXT, PAL_ART, AGNOSTIC = 0, 1, 2

# Board chrome: drawn as-is for the active player (palette 0) and +0x80 for
# everyone else (palette 1). 0x60 is the solid name plate.
CHROME = [0x02, 0x03, 0x08, 0x09, 0x0A, 0x0B, 0x20, 0x21, 0x22, 0x23, 0x24,
          0x25, 0x27, 0x28, 0x29, 0x2C, 0x2D, 0x2E, 0x2F, 0x31, 0x5C, 0x5D,
          0x5E, 0x5F, 0x60]
# Everything else graphics.c or the shared code (vars.h ICON_*) draws.
OTHER = ([0x00, 0x05, 0x19, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F, 0x2A, 0x2B]
         + list(range(0x32, 0x49))      # ships, hit, icons, box, line, cursor
         + [0x5B, 0xE1, 0xE2]
         + list(range(0xE3, 0xE9)))     # attack animation, 217 + 10..15

# The shared border row where two boards meet (graphics.c plotTilePair).
PAIRS = [(0x08, 0x0A), (0x0A, 0x08), (0x27, 0x29), (0x29, 0x27),
         (0x09, 0x0B), (0x0B, 0x09)]

# What the smoke test prints for the art; the font never shows lower case.
READS = {**{c: 's' for c in range(0x32, 0x38)},
         0x39: 'x', 0x1B: 'x', 0x1C: 'x', 0xE1: 'o', 0x2A: 'p', 0x2B: 'm',
         0x3F: '-', 0xE2: '~', 0x5B: '>', 0x3A: '_',
         **{c: 'c' for c in range(0x41, 0x49)},
         **{c: 'a' for c in range(0xE3, 0xE9)}}

ART_SLOTS = list(range(0x00, 0x20)) + list(range(0x60, 0x80))


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


def recode(px, values):
    return tuple(tuple(values[p] for p in row) for row in px)


def merge(a, b):
    return [[pa if pa else pb for pa, pb in zip(ra, rb)] for ra, rb in zip(a, b)]


def chr_bytes(px):
    p0 = bytes(sum(((px[r][c] & 1) << (7 - c)) for c in range(8)) for r in range(8))
    p1 = bytes(sum((((px[r][c] >> 1) & 1) << (7 - c)) for c in range(8)) for r in range(8))
    return p0 + p1


FONT_CODE = {BLUE: 0, CYAN: 0, RED: 0, WHITE: 1}
CHROME_CODE = {BLUE: 0, CYAN: 2, RED: 2, WHITE: 3}
ART_CODE = {BLUE: 0, RED: 1, CYAN: 2, WHITE: 3}


def main():
    sheet = load(SHEET)
    font = load(ASCII)

    tiles = {}          # tile -> bitmap
    chars = {}          # tile -> what tilemap.lua reads it as
    index = {}          # bitmap -> tile
    free = list(ART_SLOTS)

    for c in range(0x20, 0x60):
        px = recode(font[c], FONT_CODE)
        tiles[c] = px
        chars[c] = chr(c)
        index.setdefault(px, c)

    def art(px, ch):
        if px in index:
            return index[px]
        if not free:
            raise SystemExit('mkchr: out of tiles: the engine holds 128')
        t = free.pop(0)
        tiles[t] = px
        chars[t] = ch
        index[px] = t
        return t

    def agnostic(px):
        return all(v in (0, 3) for row in px for v in row)

    sheetTile = [0x20] * 256
    sheetPal = [AGNOSTIC] * 256
    for n in CHROME:
        t = art(recode(sheet[n], CHROME_CODE), '#')
        sheetTile[n] = sheetTile[n + 0x80] = t
        sheetPal[n], sheetPal[n + 0x80] = PAL_TEXT, PAL_ART
    # The tiles the smoke test reads first, so a cursor that shares a bitmap
    # with a miss reads as the miss.
    for n in sorted(OTHER, key=lambda n: n not in READS or READS[n] == 'c'):
        px = recode(sheet[n], ART_CODE)
        sheetTile[n] = art(px, READS.get(n, '#'))
        sheetPal[n] = AGNOSTIC if agnostic(px) else PAL_ART

    pairTile = [art(recode(merge(sheet[a], sheet[b]), CHROME_CODE), '#')
                for a, b in PAIRS]

    used = len(tiles)
    blank = tuple(tuple([0] * 8) for _ in range(8))

    os.makedirs(os.path.dirname(CHR), exist_ok=True)
    with open(CHR, 'wb') as f:
        for t in range(128):
            f.write(chr_bytes(tiles.get(t, blank)))
    subprocess.run([sys.executable, os.path.join(HERE, 'mktiles.py'), '--chr', CHR,
                    TILES_S], check=True)

    def table(name, values, per=16):
        out = ['static const unsigned char %s[%d] = {' % (name, len(values))]
        for i in range(0, len(values), per):
            out.append('    ' + ', '.join('0x%02X' % v for v in values[i:i + per]) + ',')
        out.append('};')
        return '\n'.join(out)

    with open(TILES_H, 'w') as f:
        f.write('/* GENERATED by src/atari7800/mkchr.py from support/msdos/charset.dat\n'
                ' * and ascii.dat. Tile numbers in mt_tiles; %d of 128 used. The font\n'
                ' * is at its ASCII codes. Include from graphics.c only (it defines\n'
                ' * tables). Do not edit. */\n'
                '#ifndef TILES_H\n#define TILES_H\n\n' % used)
        f.write('#define T_BLANK          0x20\n\n')
        f.write('#define PAL_TEXT         %d\n' % PAL_TEXT)
        f.write('#define PAL_ART          %d\n' % PAL_ART)
        f.write('#define AGNOSTIC         %d  /* white or blank: keep the cell\'s palette */\n\n'
                % AGNOSTIC)
        f.write('/* MS-DOS sheet index -> tile. Unlisted indices are blank. */\n')
        f.write(table('sheetTile', sheetTile) + '\n\n')
        f.write('/* MS-DOS sheet index -> PAL_TEXT, PAL_ART or AGNOSTIC. */\n')
        f.write(table('sheetPal', sheetPal) + '\n\n')
        f.write('/* Merged border pairs, in plotTilePair() order: (08,0A) (0A,08)\n'
                ' * (27,29) (29,27) (09,0B) (0B,09); palette 1 for the +0x80 set. */\n')
        f.write(table('pairTile', pairTile, per=6) + '\n\n')
        f.write('#endif /* TILES_H */\n')

    os.makedirs(os.path.dirname(TILEMAP), exist_ok=True)
    with open(TILEMAP, 'w') as f:
        f.write('-- GENERATED by src/atari7800/mkchr.py: what each tile reads as.\n'
                '-- Text is itself; art is a lower-case letter or a symbol (s ship, x hit, o miss, c cursor,\n'
                '-- p player, m mark, > active, a attack, - ~ _ lines, # chrome).\n'
                'return {\n')
        for t in range(128):
            ch = chars.get(t, ' ')
            f.write('  [%d] = %s,\n' % (t, '"\\""' if ch == '"' else '"%s"' % ch.replace('\\', '\\\\')))
        f.write('}\n')
    print('mkchr: %d of 128 tiles' % used)


if __name__ == '__main__':
    main()
