#!/usr/bin/env python3
"""checkbanks.py -- how much of a 2K bank a listing actually used.

p2bin ALWAYS emits its full -r range, so an over-long bank is truncated in
SILENCE: the image builds, its size is right, checkrom passes, and the
instructions past $17FF are simply gone -- what a jump into them finds is the
next bank's bytes at the same offset. Nothing else in the build can tell, so
this reads the assembler's own listing and asks.

Why not `sed` the listing's END address, which is what the sibling clients do:
a flat image ends with `ORG $1FFC` for the vectors, so its END address is
$2000 and the check fails on every build. This measures the highest byte
actually emitted BELOW the fixed half instead, which is the number that
matters in both layouts.

Usage: checkbanks.py listing.lst LIMIT [NAME]
       LIMIT is the first address the bank may not reach, e.g. 0x1800.
"""

import re
import sys

# Top level:      `     201/1FFC : 00 10      DW      START`
# Inside INCLUDE:  `(1)  196/1400 : 86 1C      stx     GRP1`
#
# That `(1)` is the include depth, and missing it is not a cosmetic bug: the
# first version of this regex matched only the top-level file and reported a
# 1146-byte image as 331 bytes used, which is a check that says a bank fits no
# matter what is in it. Everything this program does of any size is in an
# INCLUDE.
LINE = re.compile(r"^\s*(?:\(\d+\)\s*)?\d+/([0-9A-Fa-f]{4})\s*:\s*"
                  r"((?:[0-9A-Fa-f]{2} )*)")

ORG = re.compile(r"^\s*(?:\(\d+\)\s*)?\d+/([0-9A-Fa-f]{4})\s*:\s+ORG\b")


def main():
    path, limit = sys.argv[1], int(sys.argv[2], 0)
    name = sys.argv[3] if len(sys.argv) > 3 else path
    end = 0x1000
    over = []
    deliberate = False

    for line in open(path):
        # A segment explicitly ORG'd at or above the limit is deliberate --
        # the flat layout ROM puts its vectors at $1FFC. Everything else that
        # reaches the limit is the bank overflowing.
        #
        # The first version of this skipped every address >= $1800 instead,
        # which meant a bank whose code ran from $1000 to $1A28 was reported
        # as fitting: it flagged five bytes of a string that happened to
        # straddle $1800 and hid the other 550. A check that cannot see the
        # failure it exists for is worse than no check, because it is believed.
        o = ORG.match(line)
        if o:
            deliberate = int(o.group(1), 16) >= limit
            continue
        m = LINE.match(line)
        if not m or not m.group(2).strip() or deliberate:
            continue
        addr = int(m.group(1), 16)
        stop = addr + len(m.group(2).split())
        end = max(end, stop)
        if stop > limit:
            over.append((addr, line.rstrip()))

    if over:
        print("checkbanks: %s reaches $%04X, past $%04X -- %d byte(s) over, "
              "and p2bin would truncate it without saying so"
              % (name, end, limit, end - limit), file=sys.stderr)
        print("  first line past the limit: %s" % over[0][1], file=sys.stderr)
        return 1

    used = end - 0x1000
    room = limit - 0x1000
    print("  %-8s $1000-$%04X, %4d of %d bytes (%d spare)"
          % (name, end, used, room, limit - end))
    return 0


if __name__ == "__main__":
    sys.exit(main())
