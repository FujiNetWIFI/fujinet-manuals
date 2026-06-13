#!/usr/bin/env python3
"""Reconstruct the CONFIG loading splash from fujinet-config source.

cfgload (fujinet-config/src/coco/cfgload/cfgload.c) shows a PMODE 4
screen (256x192, 1bpp, 32 bytes/row, MSB leftmost): pcls(0xff) then
fujinet_bitmap[] — the logo band with its all-white top rows and the
bottom LOGO_BOTTOM_TRIMMED_BYTES trimmed off — memcpy'd at
LOGO_FULL_SIZE - LOGO_BOTTOM_TRIMMED_BYTES - sizeof(bitmap).

In SCREEN 1,1 a set bit is buff and a clear bit is black; we render
with the manual's palette (buff #e9e7df, ink #0d0d0d) at 4x.

Usage: make_loading.py [path-to-cfgload.c] [out.png]
"""
import re
import sys

from PIL import Image

SRC = sys.argv[1] if len(sys.argv) > 1 else \
    "../../../fujinet-config/src/coco/cfgload/cfgload.c"
OUT = sys.argv[2] if len(sys.argv) > 2 else "images/loading-splash.png"

text = open(SRC).read()

full_size = int(re.search(r"#define\s+LOGO_FULL_SIZE\s+(\d+)", text).group(1))
trimmed = int(re.search(r"#define\s+LOGO_BOTTOM_TRIMMED_BYTES\s+(\d+)",
                        text).group(1))
body = re.search(r"fujinet_bitmap\[\]\s*=\s*\{(.*?)\};", text,
                 re.S).group(1)
data = bytes(int(b, 16) for b in re.findall(r"0[xX]([0-9a-fA-F]{2})", body))
print(f"bitmap: {len(data)} bytes, full {full_size}, bottom trim {trimmed}")

fb = bytearray(b"\xff" * full_size)
off = full_size - trimmed - len(data)
fb[off:off + len(data)] = data

img = Image.new("RGB", (256, 192))
buff, ink = (0xE9, 0xE7, 0xDF), (0x0D, 0x0D, 0x0D)
px = img.load()
for y in range(192):
    for x in range(256):
        bit = fb[y * 32 + x // 8] & (0x80 >> (x % 8))
        px[x, y] = buff if bit else ink

img = img.resize((1024, 768), Image.NEAREST)
img.save(OUT)
print("wrote", OUT)
