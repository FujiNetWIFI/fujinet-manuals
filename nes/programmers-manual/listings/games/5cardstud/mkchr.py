#!/usr/bin/env python3
"""mkchr.py -- build the NES background pattern table for 5 Card Stud.

The NES has no per-cell colour: a tile carries its own four colours. So every
glyph the ColecoVision port draws with an ink/paper pair becomes one tile here,
converted from the same sources -- src/coleco/font.bin (the Namco text font,
0x20-0x7F) and src/coleco/udg.h (the card art) -- with the colours baked in:

  0 felt green (the universal background), 1 white, 2 red, 3 black

Writes src/nes/tiles.h (tile numbers and the UDG_ glyph codes graphics.c keys
its shadow screen on), src/nes/chr.s (the 4K CHARS1 segment) and
support/nes/tilemap.lua (tile -> character, for the MAME smoke test).
Run it by hand after changing the font or the art; the outputs are committed.
"""

import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
FONT = os.path.join(HERE, '..', 'coleco', 'font.bin')
UDG = os.path.join(HERE, '..', 'coleco', 'udg.h')
TILES_H = os.path.join(HERE, 'tiles.h')
CHR_S = os.path.join(HERE, 'chr.s')
TILEMAP = os.path.join(HERE, '..', '..', 'support', 'nes', 'tilemap.lua')

G, W, R, K = 0, 1, 2, 3
UL_CHARS = ' 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
RANKS = ['2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K', 'A']


def load_font():
    data = open(FONT, 'rb').read()
    return {0x20 + i: data[i * 8:(i + 1) * 8] for i in range(96)}


def load_udg():
    text = open(UDG).read()
    codes = {n: int(c, 16) for n, c in re.findall(r'#define (UDG_\w+) (0x[0-9A-Fa-f]+)', text)}
    body = re.sub(r'/\*.*?\*/', '', text[text.index('udg[] ='):], flags=re.S)
    raw = [int(h, 16) for h in re.findall(r'0x([0-9A-Fa-f]{2})', body)]
    art = {code: bytes(raw[(code - 0x80) * 8:(code - 0x80) * 8 + 8]) for code in codes.values()}
    return codes, art


def tile(rows, ink, paper, ink_rows=None, fill_rows=None):
    """One 2bpp tile: set pixels take `ink`, clear ones `paper`. ink_rows
    recolours the set pixels of given rows; fill_rows paints whole rows."""
    px = []
    for r in range(8):
        row = []
        for c in range(8):
            on = (rows[r] >> (7 - c)) & 1
            col = (ink_rows or {}).get(r, ink) if on else paper
            if fill_rows and r in fill_rows:
                col = fill_rows[r]
            row.append(col)
        px.append(row)
    p0 = bytes(sum(((px[r][c] & 1) << (7 - c)) for c in range(8)) for r in range(8))
    p1 = bytes(sum((((px[r][c] >> 1) & 1) << (7 - c)) for c in range(8)) for r in range(8))
    return p0 + p1


def main():
    font = load_font()
    codes, art = load_udg()
    tiles, defs, chars = [], [], {}

    def add(data, ch='#'):
        tiles.append(data)
        chars[len(tiles) - 1] = ch
        return len(tiles) - 1

    def define(name, idx, note=''):
        defs.append('#define %-22s 0x%02X%s' % (name, idx, ('  /* %s */' % note) if note else ''))

    define('T_TEXT', len(tiles), 'ASCII 0x20-0x5F, white on felt')
    for c in range(0x20, 0x60):
        add(tile(font[c], W, G), chr(c))
    define('T_STATUS', len(tiles), 'ASCII 0x20-0x5F, white on black')
    for c in range(0x20, 0x60):
        add(tile(font[c], W, K), chr(c))

    for n in ['CARD_TL', 'CARD_BL', 'CARD_TOP', 'CARD_BOT', 'CARD_TOP_TRIM', 'CARD_BOT_TRIM',
              'CARD_VERT', 'CARD_BR_STUB', 'CARD_TR_STUB',
              'BOX_TL', 'BOX_TR', 'BOX_H', 'BOX_BL', 'BOX_BR', 'BOX_V', 'CHIP']:
        define('T_%s_RG' % n, add(tile(art[codes['UDG_' + n]], R, G)))
    for n in ['CARD_VERT', 'BACK_RCOL_TOP', 'BACK_RCOL_MID', 'BACK_RCOL_BOT',
              'BACK_L_TOP', 'BACK_R_TOP', 'BACK_L_MID', 'BACK_R_MID', 'BACK_L_BOT', 'BACK_R_BOT']:
        define('T_%s_RW' % n, add(tile(art[codes['UDG_' + n]], R, W)))
    # The hole-card marker's double rule is black on the MS-DOS original.
    for n in ['HIDDEN_L', 'HIDDEN_R']:
        define('T_%s_RW' % n, add(tile(art[codes['UDG_' + n]], R, W, ink_rows={1: K, 6: K})))
    define('T_BLANK_W', add(tile(bytes(8), W, W), ' '), 'card face interior')

    define('T_RANK_RW', len(tiles), '13 ranks 2..A, red on white')
    for r in RANKS:
        add(tile(art[codes['UDG_RANK_' + r]], R, W))
    define('T_RANK_KW', len(tiles), '13 ranks 2..A, black on white')
    for r in RANKS:
        add(tile(art[codes['UDG_RANK_' + r]], K, W))
    for n, ink in [('DIAMOND', R), ('HEART', R), ('SPADE', K), ('CLUB', K)]:
        define('T_SUIT_%s_%sW' % (n, 'R' if ink == R else 'K'), add(tile(art[codes['UDG_SUIT_' + n]], ink, W)))
    for n in ['SCREEN_TL', 'SCREEN_TR', 'SCREEN_BL', 'SCREEN_BR']:
        define('T_%s_GK' % n, add(tile(art[codes['UDG_' + n]], G, K)))

    # drawLine() on the status row: the move under the cursor gets a red
    # underline. Only the characters a move name or a timer can hold.
    define('T_STATUS_UL', len(tiles), 'T_UL_CHARS order, red underline')
    for ch in UL_CHARS:
        add(tile(font[ord(ch)], W, K, fill_rows={7: R}), ch)
    # drawLine() elsewhere: a red bar across the top of the row under the active
    # player's name -- blank cells, or the tops of that player's cards.
    define('T_TOPBAR_SPACE', add(tile(font[0x20], W, G, fill_rows={0: R, 1: R}), ' '))
    for n in ['CARD_TL', 'CARD_TOP', 'CARD_TR_STUB', 'CARD_TOP_TRIM']:
        define('T_TOPBAR_%s' % n, add(tile(art[codes['UDG_' + n]], R, G, fill_rows={0: R, 1: R})))

    assert len(tiles) <= 256, len(tiles)
    used = len(tiles)
    while len(tiles) < 256:
        add(bytes(16), ' ')

    with open(TILES_H, 'w') as f:
        f.write('/* GENERATED by src/nes/mkchr.py from src/coleco/font.bin and udg.h.\n'
                ' * Tile numbers in the CHARS1 pattern table, and the glyph codes the\n'
                ' * shadow screen is kept in. %d of 256 tiles used. Do not edit. */\n'
                '#ifndef TILES_H\n#define TILES_H\n\n' % used)
        for n in sorted(codes, key=codes.get):
            f.write('#define %-22s 0x%02X\n' % (n, codes[n]))
        f.write('\n#define T_UL_CHARS "%s"\n\n' % UL_CHARS)
        f.write('\n'.join(defs) + '\n\n#endif /* TILES_H */\n')

    with open(CHR_S, 'w') as f:
        f.write('; GENERATED by src/nes/mkchr.py -- the background pattern table at PPU $1000.\n'
                '; cc65\'s own font occupies CHARS ($0000); this is the one the game points\n'
                '; PPUCTRL at. Do not edit.\n\n        .segment "CHARS1"\n\n')
        for i, t in enumerate(tiles):
            f.write('        .byte %s ; tile $%02X\n' % (', '.join('$%02X' % b for b in t), i))

    with open(TILEMAP, 'w') as f:
        f.write('-- GENERATED by src/nes/mkchr.py: what each background tile reads as.\n'
                '-- "#" is card art, " " a blank of any colour.\n'
                'return {\n')
        for i in range(256):
            ch = chars[i]
            f.write('  [%d] = %s,\n' % (i, '"\\""' if ch == '"' else '"%s"' % ch.replace('\\', '\\\\')))
        f.write('}\n')
    print('mkchr: %d tiles' % used)


if __name__ == '__main__':
    main()
