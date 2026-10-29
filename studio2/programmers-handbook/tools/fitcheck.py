#!/usr/bin/env python3
"""fitcheck.py -- every FIT or RFIT covers the routine after it.

    tools/fitcheck.py listings/asm/build/obj/*.lst

FIT n (s2macro.inc) and RFIT n (CONFIG's, which also keeps out of
$x000-$x3FF) move a routine to the next page unless n bytes still fit. AS
catches an undersized n only when a short branch then lands off its page;
this catches it while the routine happens to fit. A routine runs from its
FIT to the next FIT, an ORG, or the first data line of the program's own
(a DB or DW that is not inside a macro's expansion, such as FCALL's DW).
The runtime's FITs ($0400-$07FF) are skipped: it puts one only before a
routine that branches, so the next routine's bytes would count against it.
The handbook's version of CONFIG's tools/fitcheck.py, which knows only RFIT
and CONFIG's CFG_END.
"""
import re
import sys

LINE = re.compile(r"^(?:\(\d+\))?\s*(\d+)/\s*([0-9A-F]+) :(.*)$")
FIT = re.compile(r"\(MACRO\)\[\d+\]\s+(?:[A-Za-z_]\w*:\s+)?R?FIT\s+(\d+)")
MACRO = re.compile(r"\(MACRO(?:-\d+)?\)")
CODE = re.compile(r"\s*((?:[0-9A-F]{2} )+)")
DATA = re.compile(r"^\s*(?:[0-9A-F]{2} )*\s*(?:[A-Za-z_]\w*:?\s+)?(DB|DW|ORG)\b")
LABEL = re.compile(r"\s([A-Za-z_][A-Za-z0-9_]*):")


def check(path):
    lines = open(path, errors="replace").read().splitlines()
    fits, code, stops = [], [], []
    macro_line = None
    for i, raw in enumerate(lines):
        m = LINE.match(raw)
        if not m:
            continue
        num, rest = m.group(1), m.group(3)
        if MACRO.search(rest):
            macro_line = num
            f = FIT.search(rest)
            if f:
                fits.append((i, int(f.group(1))))
            continue
        if num != macro_line and DATA.match(rest):
            stops.append(i)
        c = CODE.match(rest)
        if c and not rest.lstrip().startswith("=>"):
            code.append((i, int(m.group(2), 16), len(c.group(1).split())))
    bad = []
    for k, (i, size) in enumerate(fits):
        stop = fits[k + 1][0] if k + 1 < len(fits) else len(lines)
        stop = min([s for s in stops if s > i] + [stop])
        body = [c for c in code if i < c[0] < stop]
        if not body or body[0][1] < 0x0800:
            continue            # the runtime's own, at $0400-$07FF
        used = max(a + n for _, a, n in body) - body[0][1]
        if used > size or used > 0x100:
            name = next((LABEL.search(l).group(1) for l in lines[i:i + 12] if LABEL.search(l)), "?")
            bad.append("$%04X %s: FIT %d, but %d bytes" % (body[0][1], name, size, used))
    for b in bad:
        print("fitcheck: %s: %s" % (path, b))
    return len(fits), bad


def main():
    total = nbad = 0
    for p in sys.argv[1:]:
        n, bad = check(p)
        total += n
        nbad += len(bad)
    print("fitcheck: %d files, %d routines, %s" % (len(sys.argv) - 1, total,
          "every FIT covers its routine" if not nbad else "%d short" % nbad))
    return 1 if nbad else 0


if __name__ == "__main__":
    sys.exit(main())
