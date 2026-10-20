#!/usr/bin/env python3
"""basfix.py -- make a 7800basic ROM a FujiNet app.

    basfix.py prog.bas.bin prog.bas.list.txt dasm.log

7800basic fills its last 4K upward from $F000 and keeps $FF7E-$FFFF for its
checksum, the signature and the vectors. The FujiNet claim is ten bytes at
$FF70: "FUJI", version 1, kind+1 (0 = let the cartridge decide), flags
($01 = 16K of cart RAM at $4000), three zeros. This tool

  - refuses if 7800basic's code reaches $FF70 (dasm's output says how many
    bytes of the reserved area are left below $FF7E),
  - stamps the claim,
  - and refuses any read-modify-write instruction aimed at $0D00-$0FFF, read
    from dasm's listing so graphics are never mistaken for code.

The image is stamped in place; 7800header then writes the .a78 header, with
the bank scheme 7800basic chose.
"""
import re
import sys

CLAIM = 0xFF70
WR_LO, WR_HI = 0x0D00, 0x0FFF
RMW = {0x0E: "ASL", 0x1E: "ASL", 0x2E: "ROL", 0x3E: "ROL", 0x4E: "LSR",
       0x5E: "LSR", 0x6E: "ROR", 0x7E: "ROR", 0xCE: "DEC", 0xDE: "DEC",
       0xEE: "INC", 0xFE: "INC"}


def main():
    binp, listp, logp = sys.argv[1:4]
    img = bytearray(open(binp, "rb").read())
    if len(img) % 1024:
        sys.exit("basfix: %s is %d bytes, not whole KiB" % (binp, len(img)))

    m = re.search(r"(\d+) bytes left in the 7800basic reserved area", open(logp).read())
    if not m:
        sys.exit("basfix: %s does not say where 7800basic's code ends" % logp)
    last = 0xFF7E - int(m.group(1)) - 1

    # Every listing line that assembled bytes: "  line  addr  bytes  source".
    bad = []
    rx = re.compile(r"^\s*\d+\s+([0-9a-f]{4,5})\s+((?:[0-9a-f]{2}\s)+)\s*(\S.*)?$", re.I)
    for line in open(listp, errors="replace"):
        m = rx.match(line.rstrip("\n"))
        if not m:
            continue
        code = [int(b, 16) for b in m.group(2).split()]
        src = (m.group(3) or "").strip().lower()
        if len(code) == 3 and code[0] in RMW and not src.startswith((".byte", "dc", ".word", "hex")):
            tgt = code[1] | code[2] << 8
            if WR_LO <= tgt <= WR_HI:
                bad.append("%s: %s $%04X writes the old value first -- the cartridge "
                           "counts both writes" % (m.group(1), RMW[code[0]], tgt))
    for msg in bad:
        print("basfix: %s %s" % (binp, msg), file=sys.stderr)
    if bad:
        sys.exit(1)

    at = len(img) - (0x10000 - CLAIM)             # the last bank is at the top
    if last >= CLAIM or any(img[at + i] not in (0, 0xFF) for i in range(10)):
        sys.exit("basfix: 7800basic's code reaches $%04X; no room for the claim at $FF70" % last)
    img[at:at + 10] = b"FUJI" + bytes([1, 0, 0, 0, 0, 0])
    vec = img[-4] | img[-3] << 8
    if vec < 0x4000:
        sys.exit("basfix: reset vector $%04X is below $4000" % vec)
    open(binp, "wb").write(img)
    print("basfix: %s: claim at $FF70, code ends at $%04X, %d bytes" % (binp, last, len(img)))


if __name__ == "__main__":
    main()
