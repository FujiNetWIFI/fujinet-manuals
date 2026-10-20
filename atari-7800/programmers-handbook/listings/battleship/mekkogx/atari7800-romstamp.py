#!/usr/bin/env python3
"""atari7800-romstamp.py -- check (and stamp) a built Atari 7800 FujiNet client.

Ported from fujinet-firmware/pico/atari-7800/tools/checkrom.py, which enforces
the layout contract in fuji_mailbox.h:

  - a headerless image of whole KiB, top-aligned so it ends at $FFFF;
  - the claim at $FF70: "FUJI", version 1, kind, flags with the cart-RAM bit
    (the linker config puts DATA, BSS and the stack in that RAM). Without it
    the cart shuts the mailbox down when the image boots. --stamp writes the
    default claim if the four letters are missing;
  - a reset vector at $4000 or above;
  - no read-modify-write instruction aimed at the mailbox's write pages
    ($0D00-$0FFF): the 6502 writes the old value first, a spurious event;
  - no absolute or zero-page store to $00-$1F or its mirrors: until locked,
    each one replaces INPTCTRL, and a game can only be handed to the
    console's BIOS while it is unlocked. Indexed stores cannot be seen here;
  - no JMP ($xxFF): the 6502 fetches its high byte from the wrong page.

With --map the scan walks only the code segments the ld65 map (-m) lists,
so tables cannot pass for opcodes. --a78 also writes the image with the
128-byte header MAME's -cart needs (the cart strips it). A failing image is
deleted, with its .a78, so a stale one cannot look up to date.

Usage: atari7800-romstamp.py [--stamp] [--map file.map] [--a78 out.a78] image.bin
"""

import os
import re
import sys

CLAIM = 0xFF70
CLAIM_DEFAULT = b"FUJI" + bytes([1, 0, 1, 0, 0, 0])
CLAIMF_RAM = 0x01
WR_LO, WR_HI = 0x0D00, 0x0FFF

RMW = {0x0E, 0x1E, 0x2E, 0x3E, 0x4E, 0x5E, 0x6E, 0x7E, 0xCE, 0xDE, 0xEE, 0xFE,
       0x0F, 0x1F, 0x2F, 0x3F, 0x4F, 0x5F, 0x6F, 0x7F, 0xCF, 0xDF, 0xEF, 0xFF}
ZP_WRITES = {0x85, 0x86, 0x84, 0x06, 0x26, 0x46, 0x66, 0xC6, 0xE6}
ABS_WRITES = {0x8D, 0x8E, 0x8C, 0x0E, 0x2E, 0x4E, 0x6E, 0xCE, 0xEE}
JMP_IND = 0x6C

LEN = [1] * 256
for op in (0x69, 0x29, 0xC9, 0xE0, 0xC0, 0x49, 0xA9, 0xA2, 0xA0, 0x09, 0xE9,
           0xA5, 0xA6, 0xA4, 0x85, 0x86, 0x84, 0x65, 0x25, 0x06, 0x24, 0xC5,
           0xC6, 0x45, 0xE6, 0x46, 0x26, 0x66, 0xE5, 0x05, 0x75, 0x35, 0x16,
           0xD5, 0xD6, 0x55, 0xF6, 0x56, 0x36, 0x76, 0xF5, 0x15, 0xB5, 0xB4,
           0x95, 0x94, 0xB6, 0x96, 0x61, 0x21, 0xC1, 0x41, 0xA1, 0x01, 0xE1,
           0x81, 0x71, 0x31, 0xD1, 0x51, 0xB1, 0x11, 0xF1, 0x91, 0xC4, 0xE4,
           0x10, 0x30, 0x50, 0x70, 0x90, 0xB0, 0xD0, 0xF0):
    LEN[op] = 2
for op in (0x6D, 0x2D, 0x0E, 0x2C, 0xCD, 0xEC, 0xCC, 0xCE, 0x4D, 0xEE, 0x4C,
           0x20, 0xAD, 0xAE, 0xAC, 0x4E, 0x0D, 0x2E, 0x6E, 0xED, 0x8D, 0x8E,
           0x8C, 0x7D, 0x3D, 0x1E, 0xDD, 0xDE, 0x5D, 0xFD, 0xFE, 0x5E, 0xBD,
           0xBC, 0x3E, 0x7E, 0x1D, 0x9D, 0x79, 0x39, 0xD9, 0x59, 0xB9, 0xBE,
           0x19, 0xF9, 0x99, 0x6C):
    LEN[op] = 3

CODE_SEGMENTS = ("STARTUP", "LOWCODE", "ONCE", "CODE")


def in_tia(a):
    return (a & 0xFCE0) == 0


def code_ranges(mapfile):
    """(start, end) console-address ranges of the code segments, from ld65 -m."""
    if not mapfile:
        return None
    ranges = []
    for name, start, end in re.findall(r"^(\w+)\s+([0-9A-F]{6})\s+([0-9A-F]{6})\s+[0-9A-F]{6}",
                                       open(mapfile).read(), re.M):
        if name in CODE_SEGMENTS:
            ranges.append((int(start, 16), int(end, 16)))
    return ranges


def scan(img, base, lo, hi):
    bad = []
    pc = lo - base
    stop = hi + 1 - base
    while pc < stop:
        op = img[pc]
        n = LEN[op]
        if pc + n > len(img):
            break
        if n == 3:
            tgt = img[pc + 1] | (img[pc + 2] << 8)
            if op in RMW and WR_LO <= tgt <= WR_HI:
                bad.append("$%04X: RMW opcode $%02X targets the write page $%04X"
                           % (base + pc, op, tgt))
            if op in ABS_WRITES and in_tia(tgt):
                bad.append("$%04X: a store to $%04X rewrites INPTCTRL" % (base + pc, tgt))
            if op == JMP_IND and (tgt & 0xFF) == 0xFF:
                bad.append("$%04X: JMP ($%04X) hits the 6502 page-wrap bug" % (base + pc, tgt))
        elif n == 2 and op in ZP_WRITES and img[pc + 1] < 0x20:
            bad.append("$%04X: a store to $%02X rewrites INPTCTRL" % (base + pc, img[pc + 1]))
        pc += n
    return bad


def check(img, mapfile):
    if not img or len(img) % 1024 or len(img) > 0xC000:
        return ["image is %d bytes: not whole KiB of at most 48K" % len(img)]
    base = 0x10000 - len(img)
    mem = lambda a: img[a - base]
    bad = []
    claim = bytes(mem(CLAIM + i) for i in range(7))
    if claim[:4] != b"FUJI":
        bad.append("no \"FUJI\" claim at $FF70: the mailbox would go dead at boot")
    elif not claim[6] & CLAIMF_RAM:
        bad.append("the claim does not ask for the cart's RAM at $4000")
    vec = mem(0xFFFC) | (mem(0xFFFD) << 8)
    if vec < 0x4000:
        bad.append("reset vector $%04X is below $4000" % vec)
    for lo, hi in code_ranges(mapfile) or [(max(base, 0x8000), CLAIM - 1)]:
        if lo >= base and hi <= 0xFFFF:
            bad += scan(img, base, lo, hi)
    return bad


def a78(img, title):
    h = bytearray(128)
    h[0] = 1
    h[1:10] = b"ATARI7800"
    title = title.encode()[:32]
    h[17:17 + len(title)] = title
    h[49:53] = len(img).to_bytes(4, "big")
    h[55] = 1                   # joysticks in both ports
    h[56] = 1
    h[100:128] = b"ACTUAL CART DATA STARTS HERE"
    return bytes(h) + img


def main():
    args = sys.argv[1:]
    do_stamp = False
    mapfile = a78out = None
    while args and args[0].startswith("--"):
        opt = args.pop(0)
        if opt == "--stamp":
            do_stamp = True
        elif opt == "--map" and args:
            mapfile = args.pop(0)
        elif opt == "--a78" and args:
            a78out = args.pop(0)
        else:
            args = []
    if len(args) != 1:
        print(__doc__.strip(), file=sys.stderr)
        return 2
    path = args[0]
    img = bytearray(open(path, "rb").read())
    if do_stamp and len(img) >= 0x90 and img[-0x90:-0x8C] != b"FUJI":
        img[-0x90:-0x86] = CLAIM_DEFAULT
        open(path, "wb").write(img)
    problems = check(img, mapfile)
    if problems:
        for p in problems:
            print("%s: %s" % (path, p), file=sys.stderr)
        os.remove(path)
        if a78out and os.path.exists(a78out):
            os.remove(a78out)
        return 1
    if a78out:
        name = os.path.splitext(os.path.basename(path))[0].upper()
        open(a78out, "wb").write(a78(bytes(img), "FUJINET " + name))
    print("%s: ok (%dK, claim at $FF70)" % (path, len(img) // 1024))
    return 0


if __name__ == "__main__":
    sys.exit(main())
