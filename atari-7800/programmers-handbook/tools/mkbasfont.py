#!/usr/bin/env python3
"""mkbasfont.py -- the assembly programs' font as a 7800basic 320A graphic.

7800basic takes its characters from a PNG (`incgraphic fujifont.png 320A`):
one 8 x 8 cell per character, side by side, colour index 1 the ink. With
`alphachars ASCII` a character's code is its cell, so this writes the 128
cells of the bring-up's own 5 x 7 set (tools/mkfont.py), codes $00-$7F, and
the BASIC programs look like the assembly ones.

    mkbasfont.py out.png
"""
import os
import struct
import sys
import zlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mkfont import rows  # noqa: E402

N = 128


def chunk(kind, data):
    c = kind + data
    return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c))


def main():
    glyph = [rows(chr(c)) if 0x20 <= c < 0x80 else [0] * 8 for c in range(N)]
    raw = b""
    for r in range(8):
        raw += b"\x00" + bytes(glyph[c][r] for c in range(N))   # filter 0, 1 bpp
    png = (b"\x89PNG\r\n\x1a\n"
           + chunk(b"IHDR", struct.pack(">IIBBBBB", N * 8, 8, 1, 3, 0, 0, 0))
           + chunk(b"PLTE", bytes([0, 0, 0, 255, 255, 255]))
           + chunk(b"IDAT", zlib.compress(raw))
           + chunk(b"IEND", b""))
    open(sys.argv[1], "wb").write(png)


if __name__ == "__main__":
    main()
