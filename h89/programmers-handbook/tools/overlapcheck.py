#!/usr/bin/env python3
"""Words printed over other words: what layoutcheck cannot see.

Reads the PDF's word boxes (pdftotext -bbox) and reports any two words on the
same line whose boxes overlap, such as a table column too narrow for its
names. Exits 1 if there are any.

  python3 tools/overlapcheck.py PDF
"""
import html, re, subprocess, sys


def main():
    pdf = sys.argv[1]
    out = subprocess.run(["pdftotext", "-bbox", pdf, "-"], capture_output=True, text=True,
                         check=True).stdout
    word = re.compile(r'<word xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">(.*?)</word>')
    bad = 0
    for pno, page in enumerate(out.split("<page ")[1:], 1):
        words = sorted((float(a), float(b), float(c), float(d), html.unescape(w))
                       for a, b, c, d, w in word.findall(page))
        seen = set()
        for i, (x0, y0, x1, y1, w) in enumerate(words):
            for u0, v0, u1, v1, t in words[i + 1:]:
                if u0 >= x1 - 0.5:
                    break
                # the same line: they share more than half the smaller height
                if min(y1, v1) - max(y0, v0) > 0.5 * min(y1 - y0, v1 - v0) and u0 > x0 + 0.5:
                    key = (round(y0), w, t)
                    if key not in seen:
                        seen.add(key)
                        print("p%d y=%d  %r overprints %r" % (pno, y0, w[:40], t[:30]))
                        bad += 1
    print("overlapcheck: %d overprinted words" % bad)
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
