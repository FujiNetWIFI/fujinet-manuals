#!/usr/bin/env python3
"""Read an H19 screen picture back into characters.

    tools/ppm2cells.py <444-29 rom> <screen.ppm> <out.json>

FujiNet Go H89 draws the H19 from its own character ROM, 80 x 25 cells of
8 x 10 pixels with every pixel row doubled (640 x 500). Each cell's ten rows
are matched against the ROM's 128 glyphs, plain and reversed, and against
the underline cursor (bottom row flipped), so the result is exact: the book
sets the screen in the H19 Screen font from what the terminal really showed,
reverse video and graphics characters included.

out.json: {"rows": [{"text": "...", "rev": "  rrrr  "}, ... 25 rows],
           "cursor": [col, row] or null}
Graphics glyphs (ROM 00H-1FH) come out as U+E000-U+E01F, the ROM's 7FH as
U+E07F -- the same code points tools/make_h19_font.py gives them.
"""
import json
import sys


def read_ppm(path):
    data = open(path, "rb").read()
    parts, i = [], 0
    while len(parts) < 4:                     # P6, width, height, maxval
        while data[i:i + 1].isspace():
            i += 1
        if data[i:i + 1] == b"#":
            while data[i:i + 1] != b"\n":
                i += 1
            continue
        j = i
        while not data[j:j + 1].isspace():
            j += 1
        parts.append(data[i:j])
        i = j
    i += 1
    w, h = int(parts[1]), int(parts[2])
    return w, h, data[i:]


def main():
    rom = open(sys.argv[1], "rb").read()
    w, h, px = read_ppm(sys.argv[2])
    assert (w, h) == (640, 500), (w, h)
    glyphs = [[rom[g * 16 + r] for r in range(10)] for g in range(128)]
    table = {}
    for g in range(128):
        rows = tuple(glyphs[g])
        table.setdefault((rows, False), g)
        table.setdefault((tuple(b ^ 0xFF for b in rows), True), g)

    def lum(x, y):
        o = (y * w + x) * 3
        return px[o] + px[o + 1] + px[o + 2]

    out, cursor = [], None
    for row in range(25):
        text, rev = [], []
        for col in range(80):
            cell = []
            for ra in range(10):
                y = 2 * (row * 10 + ra)
                b = 0
                for c in range(8):
                    if lum(col * 8 + c, y) > 300:
                        b |= 0x80 >> c
                cell.append(b)
            cell = tuple(cell)
            hit = None
            for inv in (False, True):
                if (cell, inv) in table:
                    hit = (table[(cell, inv)], inv)
                    break
            if hit is None:                    # the underline cursor flips row 9
                c2 = cell[:9] + (cell[9] ^ 0xFF,)
                for inv in (False, True):
                    if (c2, inv) in table:
                        hit = (table[(c2, inv)], inv)
                        cursor = [col, row]
                        break
            if hit is None:
                sys.exit(f"{sys.argv[2]}: cell {col},{row} matches no glyph")
            g, inv = hit
            cp = g if g >= 0x20 else 0xE000 + g
            if g == 0x7F:
                cp = 0xE07F
            text.append(chr(cp))
            rev.append("r" if inv else " ")
        out.append({"text": "".join(text), "rev": "".join(rev)})
    json.dump({"rows": out, "cursor": cursor}, open(sys.argv[3], "w"),
              ensure_ascii=False, indent=0)


if __name__ == "__main__":
    main()
