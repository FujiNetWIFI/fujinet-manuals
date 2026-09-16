#!/usr/bin/env python3
"""widows.py -- a first pass over the PDF's text for stranded lines.

Runs pdftotext -layout page by page and flags: a page whose first text line
ends a paragraph (a widow: one short line at the top), a page whose last line
starts a paragraph (an orphan), and a heading within three lines of a page's
bottom. Heuristic; the eyeball pass over the contact sheets is the real one.

    tools/widows.py handbook.pdf
"""
import re
import subprocess
import sys

pdf = sys.argv[1]
n = int(re.search(r"Pages:\s+(\d+)", subprocess.run(["pdfinfo", pdf],
        capture_output=True, text=True).stdout).group(1))
flags = 0
for p in range(1, n + 1):
    txt = subprocess.run(["pdftotext", "-layout", "-f", str(p), "-l", str(p), pdf, "-"],
                         capture_output=True, text=True).stdout
    lines = [l.rstrip() for l in txt.split("\n")]
    lines = [l for l in lines if l.strip()]
    if len(lines) < 4:
        continue
    body = lines[:-1] if re.match(r"^\s*\d+\s*$", lines[-1]) or re.match(r"^\d+\s*$", lines[-1].strip()) else lines
    if not body:
        continue
    first = body[0].strip()
    # a widow: a short first line ending a sentence, followed by a blank or a heading
    if len(first) < 45 and first.endswith((".", ":", ";")) and not first.isupper():
        print("p%3d widow?   %s" % (p, first[:60])); flags += 1
    last = body[-1].strip()
    # a heading at the bottom: short, no terminal punctuation, Title/UPPER case
    if len(last) < 40 and not last.endswith((".", ",", ";", ":", ")")) and \
       (last.isupper() or last[:1].isupper()) and len(body) > 8 and \
       not re.search(r"[=;]", last) and not re.match(r"^[\$\w]+\s+[\$\w#]", last):
        print("p%3d orphan?  %s" % (p, last[:60])); flags += 1
print("widows: %d flags over %d pages" % (flags, n))
