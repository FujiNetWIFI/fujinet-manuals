#!/usr/bin/env python3
"""native.py -- helpers for tools/native.sh (Chapter 5, assembling on the H89).

  native.py z80 dri   SRC OUT           DRI ASM source -> z88dk-z80asm source
  native.py z80 heath SRC OUT ACMDIR    Heath ASM source -> z88dk-z80asm source
  native.py cpmtext SRC OUT             CR LF lines and a ^Z, as CP/M's ED keeps
  native.py hdostext SRC OUT            NL lines, as HDOS's EDIT keeps
  native.py cpmget IMG NAME.EXT OUT     a file off a 100K H17 CP/M disk
  native.py cpmera IMG NAME.EXT         erase it there, as ERA does
  native.py text IN OUT                 a listing off a disk -> plain text
  native.py compare-cpm X.HEX X.COM BIN  ASM's and LOAD's bytes vs z80asm's
  native.py compare-abs X.ABS BIN MAP ORGHEX   Heath ASM's bytes vs z80asm's

The z80asm copies exist only for the cross-check: the same program put
through a second, unrelated assembler (z88dk-z80asm -m8080, which takes
Intel mnemonics) must come out byte for byte the same as what the H89's own
assembler made. The conversions are only the ones the dialects force:
strings in double quotes, labels with colons, Heath's comment field (no
semicolon), its number suffixes (Q, O, A, B, D), SCALL, XTEXT and END.

Heath's ASM evaluates expressions strictly left to right (no precedence),
z80asm does not; a Heath expression that mixes * or / with + or - is
refused here rather than converted wrongly.

Copyright (C) 2026 Thomas Cherryhomes
SPDX-License-Identifier: GPL-3.0-or-later
"""
import os
import re
import sys


def fail(msg):
    sys.exit("native.py: " + msg)


# ---- DRI ASM -> z80asm -----------------------------------------------------

def dq(s):
    """'IT''S' -> "IT'S" (z80asm wants double quotes for strings)."""
    body = s[1:-1].replace("''", "'")
    if '"' in body:
        fail('a " inside a string: %s' % s)
    return '"' + body + '"'


def strings_to_dq(code):
    out, i = [], 0
    for m in re.finditer(r"'(?:[^']|'')*'", code):
        out.append(code[i:m.start()])
        s = m.group(0)
        # one character stays a character constant
        out.append(s if len(s[1:-1].replace("''", "'")) == 1 else dq(s))
        i = m.end()
    out.append(code[i:])
    return "".join(out)


def split_comment(line):
    """code, comment at the first ; outside quotes"""
    q = False
    for i, c in enumerate(line):
        if c == "'":
            q = not q
        elif c == ";" and not q:
            return line[:i], line[i:]
    return line, ""


def dri_to_z80(src):
    out = []
    for line in src.splitlines():
        if line.startswith("*"):
            out.append(";" + line[1:])
            continue
        code, comment = split_comment(line)
        code = strings_to_dq(code)
        code = re.sub(r"^(\s+)END\b.*", r"\1; END", code)
        out.append(code + comment)
    return "\n".join(out) + "\n"


# ---- Heath ASM -> z80asm ---------------------------------------------------

def heath_fields(line):
    """label, opcode, operand, comment -- the operand ends at a blank outside
    quotes, and everything after it is comment"""
    label = ""
    i = 0
    if line and not line[0].isspace():
        while i < len(line) and not line[i].isspace():
            i += 1
        label = line[:i]
    while i < len(line) and line[i].isspace():
        i += 1
    j = i
    while j < len(line) and not line[j].isspace():
        j += 1
    op = line[i:j]
    while j < len(line) and line[j].isspace():
        j += 1
    k, q = j, False
    while k < len(line) and (q or not line[k].isspace()):
        if line[k] == "'":
            q = not q
        k += 1
    return label, op, line[j:k], line[k:].strip()


NOARG = {"RET", "RZ", "RNZ", "RC", "RNC", "RP", "RM", "RPE", "RPO", "RE", "RNE",
         "NOP", "HLT", "EI", "DI", "XCHG", "XTHL", "SPHL", "PCHL", "CMA", "CMC",
         "STC", "DAA", "RLC", "RRC", "RAL", "RAR", "EJECT", "ENDIF", "ELSE"}
ALIAS = {"JE": "JZ", "JNE": "JNZ", "CE": "CZ", "CNE": "CNZ", "RE": "RZ", "RNE": "RNZ"}


def heath_number(tok):
    """Heath's number forms: H hex, Q or O octal, A split octal (hhhlll),
    B binary, D or nothing decimal"""
    if not tok[:1].isdigit():
        return None
    body, suf = tok[:-1], tok[-1]
    try:
        if suf == "H":
            return int(body, 16)
        if suf in "QO":
            return int(body, 8)
        if suf == "A":
            d = body.rjust(6, "0")
            return int(d[:-3], 8) * 256 + int(d[-3:], 8)
        if suf == "B":
            return int(body, 2)
        if suf == "D":
            return int(body, 10)
        return int(tok, 10)
    except ValueError:
        return None


def heath_name(n):
    return n.replace(".", "_").replace("$", "_S_")


def heath_expr(e):
    """numbers to decimal, names made legal; strings left as they are. A
    numbers-only expression is worked out here, left to right as Heath's ASM
    does; one with names may not mix * or / with + or -, where z80asm's
    precedence would give another answer"""
    toks = re.findall(r"'(?:[^']|'')*'|[0-9][0-9A-Z]*|[A-Z.$][A-Z0-9.$]*|.", e)
    if all(heath_number(t) is not None or t in "+-*/" for t in toks) and \
            heath_number(toks[0]) is not None:
        return str(left_to_right(toks))
    bare = [t for t in toks if not t.startswith("'")]
    if any(t in "*/" for t in bare[1:]) and any(t in "+-" for t in bare[1:]):
        fail("mixed * / and + - in a Heath expression: %s" % e)
    out = []
    for i, t in enumerate(toks):
        if t.startswith("'"):
            out.append(t)
        elif t[0].isdigit():
            v = heath_number(t)
            if v is None:
                fail("not a Heath number: %s" % t)
            out.append(str(v))
        elif t[0].isalpha() or t[0] in ".$":
            out.append(heath_name(t))
        elif t == "*" and i == 0:
            out.append("$")            # * alone is the location counter
        else:
            out.append(t)
    return "".join(out)


def left_to_right(toks):
    v = heath_number(toks[0])
    for op, t in zip(toks[1::2], toks[2::2]):
        n = heath_number(t)
        v = v + n if op == "+" else v - n if op == "-" else v * n if op == "*" else v // n
    return v & 0xFFFF


def acm_equates(path):
    """An XTEXT'd .ACM file reduced to EQUs: its DS/ORG lines only number the
    names (HOSDEF numbers the system calls that way), so they become values."""
    loc, out = 0, []
    for line in open(path, "rb").read().replace(b"\0", b"").decode("latin-1").splitlines():
        if not line.strip() or line.startswith("*"):
            continue
        label, op, arg, _ = heath_fields(line)
        if op in ("SPACE", "STL", "TITLE", "EJECT", "LON", "LOF"):
            continue
        if op == "ORG":
            loc = eval_simple(arg, {}, loc)
        elif op == "DS":
            if label:
                out.append("%s\tEQU\t%d" % (heath_name(label), loc))
            loc += eval_simple(arg, {}, loc)
        elif op == "EQU":
            out.append("%s\tEQU\t%s" % (heath_name(label),
                                        str(loc) if arg == "*" else heath_expr(arg)))
        else:
            fail("%s: %s is more than definitions" % (path, op))
    return out


def eval_simple(arg, names, loc):
    v = 0
    for sign, t in re.findall(r"([+-]?)([^+-]+)", arg):
        n = loc if t == "*" else heath_number(t)
        if n is None:
            fail("cannot evaluate %s" % arg)
        v = v - n if sign == "-" else v + n
    return v


def heath_to_z80(src, acmdir):
    out = []
    for line in src.splitlines():
        if not line.strip():
            out.append("")
            continue
        if line.startswith("*"):
            out.append(";" + line[1:])
            continue
        label, op, arg, comment = heath_fields(line)
        if op in NOARG:
            comment = (arg + " " + comment).strip()
            arg = ""
        op = ALIAS.get(op, op)
        com = ("\t; " + comment) if comment else ""
        lab = heath_name(label)
        if op == "XTEXT":
            out.append("; XTEXT " + arg + com)
            out.extend(acm_equates(os.path.join(acmdir, arg + ".ACM")))
        elif op == "END":
            out.append("; END " + arg + com)
        elif op == "SCALL":
            out.append((lab + ":" if lab else "") + "\tRST\t7" + com)
            out.append("\tDB\t" + heath_expr(arg))
        elif op in ("EQU", "SET"):
            out.append("%s\t%s\t%s%s" % (lab, "EQU" if op == "EQU" else "DEFL",
                                         heath_expr(arg), com))
        elif op in ("SPACE", "STL", "TITLE", "EJECT"):
            out.append("; " + line.strip())
        elif op == "DS":
            # Heath's ASM writes a DS area into the .ABS as it finds it (its
            # buffer's leftovers); the marks let compare-abs skip it
            nds = sum(1 for o in out if o.startswith("DS_BEGIN"))
            out.append("DS_BEGIN%d:" % nds)
            out.append(("%s:" % lab if lab else "") + "\tDS\t" + heath_expr(arg) + com)
            out.append("DS_END%d:" % nds)
        else:
            a = ",".join(strings_to_dq(heath_expr(x)) if x.startswith("'") else heath_expr(x)
                         for x in split_args(arg)) if arg else ""
            out.append(("%s:" % lab if lab else "") + "\t" + op + ("\t" + a if a else "") + com)
    return "\n".join(out) + "\n"


def split_args(arg):
    parts, cur, q = [], "", False
    for c in arg:
        if c == "'":
            q = not q
        if c == "," and not q:
            parts.append(cur)
            cur = ""
        else:
            cur += c
    parts.append(cur)
    return parts


# ---- disks and files -------------------------------------------------------

SKEW = [0, 4, 8, 2, 6, 1, 5, 9, 3, 7]   # hz89: 3 system tracks, 10 x 256, 1K blocks


def cpm_sector(img, n):
    off = ((3 + n // 10) * 10 + SKEW[n % 10]) * 256
    return img[off:off + 256]


def cpmget(image, name, out):
    img = open(image, "rb").read()
    base, _, ext = name.upper().partition(".")
    want = base.ljust(8).encode() + ext.ljust(3).encode()
    directory = b"".join(cpm_sector(img, n) for n in range(8))
    extents = []
    for e in range(0, len(directory), 32):
        ent = directory[e:e + 32]
        if ent[0] <= 15 and bytes(b & 0x7F for b in ent[1:12]) == want:
            extents.append((ent[12] + 32 * ent[14], ent))
    if not extents:
        fail("%s: no %s" % (image, name))
    data = b""
    for _, ent in sorted(extents):
        blocks = [b for b in ent[16:32] if b]
        chunk = b"".join(cpm_sector(img, 4 * b + i) for b in blocks for i in range(4))
        data += chunk[:ent[15] * 128]
    open(out, "wb").write(data)


def cpmera(image, name):
    """erase a file the way ERA does: E5 in the first byte of its entries"""
    img = bytearray(open(image, "rb").read())
    base, _, ext = name.upper().partition(".")
    want = base.ljust(8).encode() + ext.ljust(3).encode()
    hit = 0
    for n in range(8):
        off = ((3 + n // 10) * 10 + SKEW[n % 10]) * 256
        for e in range(off, off + 256, 32):
            if img[e] <= 15 and bytes(b & 0x7F for b in img[e + 1:e + 12]) == want:
                img[e] = 0xE5
                hit += 1
    if not hit:
        fail("%s: no %s" % (image, name))
    open(image, "wb").write(img)


def text(src, out):
    """CP/M's ends at the ^Z; HDOS's is NUL-padded to a sector, and Heath's
    ASM pads " No Errors" with NULs too, which print as nothing: all go.
    The form feeds between pages stay."""
    d = open(src, "rb").read()
    d = d.split(b"\x1a")[0].replace(b"\0", b"")
    t = d.decode("latin-1").replace("\r\n", "\n").replace("\r", "\n")
    open(out, "w").write(t)


def hexfile(path):
    """Intel HEX (what DRI's ASM writes) -> {address: byte}"""
    mem = {}
    for line in open(path, "rb").read().split(b"\x1a")[0].decode("latin-1").split():
        if not line.startswith(":"):
            continue
        rec = bytes.fromhex(line[1:])
        if sum(rec) & 0xFF:
            fail("%s: bad HEX checksum: %s" % (path, line))
        n, addr, typ = rec[0], rec[1] << 8 | rec[2], rec[3]
        if typ == 0:
            for i in range(n):
                mem[addr + i] = rec[4 + i]
    return mem


def compare_cpm(hexpath, compath, z80bin):
    """every byte ASM put in the .HEX must be z80asm's byte at that address,
    and LOAD's .COM must hold the .HEX bytes from 0100H on"""
    mem = hexfile(hexpath)
    com = open(compath, "rb").read()
    z = open(z80bin, "rb").read()
    lo, hi = min(mem), max(mem)
    bad = [a for a in sorted(mem) if a - 0x100 >= len(z) or z[a - 0x100] != mem[a]]
    badcom = [a for a in sorted(mem) if a - 0x100 >= len(com) or com[a - 0x100] != mem[a]]
    tail = z[hi + 1 - 0x100:]
    name = os.path.basename(compath)
    print("compare %s: HEX %04XH-%04XH (%d bytes), COM %d bytes (%d records)"
          % (name, lo, hi, len(mem), len(com), len(com) // 128))
    print("  HEX vs z80asm -m8080: %s" % ("identical" if not bad else "DIFFER at %04XH" % bad[0]))
    print("  COM vs HEX:           %s" % ("identical" if not badcom else "DIFFER at %04XH" % badcom[0]))
    print("  z80asm beyond %04XH:  %d bytes, %s" % (hi, len(tail),
          "all zero (the DS areas)" if not any(tail) else "NOT ALL ZERO"))
    return 1 if bad or badcom or any(tail) else 0


def ds_ranges(mapfile):
    """[begin, end) of each DS area, from the DS_BEGINn/DS_ENDn marks in
    z80asm's map"""
    sym = {}
    for line in open(mapfile):
        m = re.match(r"\s*(DS_(?:BEGIN|END)\d+)\s*=\s*\$([0-9A-Fa-f]+)", line)
        if m:
            sym[m.group(1)] = int(m.group(2), 16)
    return [(sym[k], sym["DS_END" + k[8:]]) for k in sorted(sym) if k.startswith("DS_BEGIN")]


def compare_abs(abspath, z80bin, mapfile, org):
    """the .ABS header, then its LENGTH bytes = z80asm's bytes, except in
    the DS areas, which Heath's ASM fills with whatever its buffer held"""
    n = open(abspath, "rb").read()
    z = open(z80bin, "rb").read()
    if n[0:2] != b"\xff\x00":
        fail("%s is not an HDOS .ABS file" % abspath)
    lda, length, ent = n[2] | n[3] << 8, n[4] | n[5] << 8, n[6] | n[7] << 8
    body = n[8:8 + length]
    skip = set()
    for b, e in ds_ranges(mapfile):
        skip.update(range(b - org, e - org))
    checked = [i for i in range(max(length, len(z))) if i not in skip]
    bad = [i for i in checked if i >= length or i >= len(z) or body[i] != z[i]]
    print("compare %s: header FF 00, load %04XH, length %d, entry %04XH"
          % (os.path.basename(abspath), lda, length, ent))
    print("  code vs z80asm -m8080: %s (%d bytes compared, %d in DS areas skipped)"
          % ("identical" if not bad else "DIFFER at offset %d" % bad[0], len(checked), len(skip)))
    print("  z80asm length %d, ABS length %d: %s" % (len(z), length,
          "same" if len(z) == length else "DIFFERENT"))
    return 0 if not bad and len(z) == length else 1


def main():
    a = sys.argv[1:]
    if a[:2] == ["z80", "dri"]:
        open(a[3], "w").write(dri_to_z80(open(a[2], encoding="latin-1").read()))
    elif a[:2] == ["z80", "heath"]:
        open(a[3], "w").write(heath_to_z80(open(a[2], encoding="latin-1").read(), a[4]))
    elif a[0] == "cpmtext":
        t = open(a[1], encoding="latin-1").read().splitlines()
        open(a[2], "wb").write(("\r\n".join(t) + "\r\n").encode("latin-1") + b"\x1a")
    elif a[0] == "hdostext":
        t = open(a[1], encoding="latin-1").read().splitlines()
        open(a[2], "wb").write(("\n".join(t) + "\n").encode("latin-1"))
    elif a[0] == "cpmget":
        cpmget(a[1], a[2], a[3])
    elif a[0] == "cpmera":
        cpmera(a[1], a[2])
    elif a[0] == "text":
        text(a[1], a[2])
    elif a[0] == "compare-cpm":
        sys.exit(compare_cpm(a[1], a[2], a[3]))
    elif a[0] == "compare-abs":
        sys.exit(compare_abs(a[1], a[2], a[3], int(a[4], 16)))
    else:
        fail("usage: see the top of this file")


if __name__ == "__main__":
    main()
