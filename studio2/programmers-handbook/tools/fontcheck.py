#!/usr/bin/env python3
"""fontcheck.py -- name every piece of text the book set in the wrong font.

Typst falls back to whatever font it holds for a character Helvetica or
Source Code Pro lacks, and with --ignore-system-fonts that can be Bodoni:
nothing on the page would look wrong enough to notice. This walks each
page's text operators and prints the text drawn in any font that is not
ours, and (with --wordmark) any Bodoni text that is not the console's name.

    fontcheck.py book.pdf [--wordmark]
"""
import sys

import pypdf

OURS = ("Helvetica", "BodoniStd-BookItalic", "SourceCodePro")
# what the Bodoni wordmark may spell: "Studio II", maybe split by the PDF
WORD = {"Studio", "II", "Studio II", "Studio II", "StudioII", "Studio ", "Studio "}
COVER_PAGES = {1}


def main():
    path = sys.argv[1]
    wordmark = "--wordmark" in sys.argv
    reader = pypdf.PdfReader(path)
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
            if not cur[0] or not t.strip():
                return
            name = cur[0].split("+")[-1]
            if not any(o in name for o in OURS):
                stray.append("%r in %s" % (t, name))
            elif wordmark and "Bodoni" in name and n not in COVER_PAGES:
                if t.strip() not in WORD:
                    stray.append("%r in %s (not the wordmark)" % (t, name))

        page.extract_text(visitor_operand_before=operand, visitor_text=text)
        if stray:
            bad += 1
            print("page %d: %s" % (n, "; ".join(sorted(set(stray)))))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
