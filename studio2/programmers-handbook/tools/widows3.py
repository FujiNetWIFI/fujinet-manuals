#!/usr/bin/env python3
"""widows3.py -- stranded lines and heads, column by column.

The booklet sets its prose in three columns, so a page's first and last
lines say little: what matters is the top and the foot of each column.
This reads the PDF's text runs with their positions and sizes (pypdf),
groups them into lines, assigns each line to a column by its x, and flags
in each column:

  head     a head (11pt or more) as the column's last line: stranded
  widow    a column that opens with one short line ending a paragraph
  orphan   a column whose last line is a paragraph's first, alone

Heuristic; the contact sheet is the real check.

    tools/widows3.py handbook.pdf
"""
import sys

import pypdf

PT = 72.0
LEFT = 0.55 * PT
COLW = (10 * PT - 1.1 * PT - 0.6 * PT) / 3
GUT = 0.3 * PT
BODY = 8.8


def lines_of(page):
    runs = []

    def text(t, cm, tm, fd, fs):
        if not t.strip():
            return
        size = abs(tm[3] * cm[3]) * fs if fs else 0
        x = tm[4] * cm[0] + cm[4]
        y = tm[5] * cm[3] + cm[5]
        runs.append((round(y, 1), x, size, t))

    page.extract_text(visitor_text=text)
    rows = {}
    for y, x, size, t in runs:
        rows.setdefault((y, int((x - LEFT) // (COLW + GUT))), []).append((x, size, t))
    out = []
    for (y, col), parts in rows.items():
        parts.sort()
        size = max(p[1] for p in parts)
        txt = "".join(p[2] for p in parts).strip()
        width = sum(len(p[2]) for p in parts) * size * 0.5
        out.append((col, -y, size, width, txt))
    return sorted(out)


def main():
    reader = pypdf.PdfReader(sys.argv[1])
    flags = 0
    for n, page in enumerate(reader.pages, 1):
        lines = [l for l in lines_of(page) if l[4] and not l[4].isdigit()]
        cols = {}
        for l in lines:
            cols.setdefault(l[0], []).append(l)
        def beside(col, line):
            # a hanging label or a head over a hanging block: text at the
            # same height in the next column, or just under it
            return any(-3 < o[1] - line[1] < 24 for o in cols.get(col + 1, []))
        for col, ls in sorted(cols.items()):
            if len(ls) < 3 or col < 0 or col > 2:
                continue
            if n <= 3:
                continue            # the cover, the colophon, the contents
            body = [l for l in ls if abs(l[2] - BODY) < 0.6]
            if not body:
                continue
            last, first = ls[-1], ls[0]
            if last[2] >= 11 and len(ls) > 1 and not beside(col, last):
                print("p%3d col %d  head    %s" % (n, col + 1, last[4][:60])); flags += 1
            # a paragraph gap is wider than a line
            lead = min((b[1] - a[1] for a, b in zip(ls, ls[1:]) if b[1] - a[1] > 2), default=12)
            gap_after_first = ls[1][1] - first[1]
            if (abs(first[2] - BODY) < 0.6 and first[3] < COLW * 0.45
                    and first[4].endswith((".", ":", "!", "?")) and gap_after_first > lead * 1.4
                    and col > 0):
                print("p%3d col %d  widow   %s" % (n, col + 1, first[4][:60])); flags += 1
            gap_before_last = last[1] - ls[-2][1]
            # (a line holding the Bodoni wordmark sits a little lower)
            if (abs(last[2] - BODY) < 0.6 and gap_before_last > lead * 1.6
                    and not last[4].endswith((".", ":", "!", "?")) and col < 2
                    and not beside(col, last)):
                print("p%3d col %d  orphan  %s" % (n, col + 1, last[4][:60])); flags += 1
    print("widows3: %d flags over %d pages" % (flags, len(reader.pages)))


if __name__ == "__main__":
    main()
