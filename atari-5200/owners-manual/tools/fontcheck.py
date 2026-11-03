#!/usr/bin/env python3
"""fontcheck.py -- name every piece of text the book set in a fallback font.

Typst falls back to Libertinus for any character Helvetica, Avant Garde and Source Code Pro
lack -- a smart quote after a digit becomes a prime, for one -- and
pdftotext cannot always show which. This walks each page's text operators
and prints the text drawn in any other font, with its page.

    fontcheck.py book.pdf
"""
import sys

import pypdf

OURS = ("Helvetica", "AvantGarde", "SourceCodePro")


def main():
    reader = pypdf.PdfReader(sys.argv[1])
    bad = 0
    for n, page in enumerate(reader.pages, 1):
        res = page.get("/Resources", {})
        fonts = {k: str(v.get_object()["/BaseFont"])
                 for k, v in res.get("/Font", {}).items()}
        cur = [None]
        stray = []

        def operand(op, args, cm, tm):
            if op == b"Tf":
                cur[0] = fonts.get(args[0], str(args[0]))

        def text(t, cm, tm, fd, fs):
            if cur[0] and t.strip() and not any(o in cur[0] for o in OURS):
                stray.append("%s in %s" % (repr(t), cur[0].split("+")[-1]))

        page.extract_text(visitor_operand_before=operand, visitor_text=text)
        if stray:
            bad += 1
            print("page %d: %s" % (n, "; ".join(sorted(set(stray)))))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
