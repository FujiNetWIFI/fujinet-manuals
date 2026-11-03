#!/usr/bin/env python3
"""pngscale.py in.png out.png factor -- integer upscale with hard pixels.
MAME's 2600 snapshot is 176 x 2xx at one pixel per colour clock; a print-size
copy needs every pixel kept square and sharp, which a bilinear resize would
smear. Pure Python (zlib + struct), so it needs no imaging library."""
import struct
import sys
import zlib

src, dst, k = sys.argv[1], sys.argv[2], int(sys.argv[3])
data = open(src, "rb").read()
assert data[:8] == b"\x89PNG\r\n\x1a\n"
pos, chunks, idat = 8, [], b""
while pos < len(data):
    ln, typ = struct.unpack(">I4s", data[pos:pos + 8])
    body = data[pos + 8:pos + 8 + ln]
    if typ == b"IHDR":
        w, h, depth, ctype, comp, filt, inter = struct.unpack(">IIBBBBB", body)
    elif typ == b"IDAT":
        idat += body
    elif typ == b"PLTE":
        plte = body
    pos += 12 + ln
assert depth == 8 and inter == 0, "unsupported PNG"
bpp = {2: 3, 6: 4, 3: 1, 0: 1}[ctype]
raw = zlib.decompress(idat)
stride = w * bpp
rows, prev = [], bytearray(stride)
p = 0
for y in range(h):
    f = raw[p]; p += 1
    cur = bytearray(raw[p:p + stride]); p += stride
    for i in range(stride):
        a = cur[i - bpp] if i >= bpp else 0
        b = prev[i]
        c = prev[i - bpp] if i >= bpp else 0
        if f == 1: cur[i] = (cur[i] + a) & 255
        elif f == 2: cur[i] = (cur[i] + b) & 255
        elif f == 3: cur[i] = (cur[i] + (a + b) // 2) & 255
        elif f == 4:
            pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
            pr = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
            cur[i] = (cur[i] + pr) & 255
    rows.append(bytes(cur)); prev = cur
out = bytearray()
for r in rows:
    big = b"".join(r[i * bpp:(i + 1) * bpp] * k for i in range(w))
    for _ in range(k):
        out += b"\x00" + big
def chunk(t, b):
    return struct.pack(">I", len(b)) + t + b + struct.pack(">I", zlib.crc32(t + b) & 0xffffffff)
png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w * k, h * k, 8, ctype, 0, 0, 0))
if ctype == 3: png += chunk(b"PLTE", plte)
png += chunk(b"IDAT", zlib.compress(bytes(out), 9)) + chunk(b"IEND", b"")
open(dst, "wb").write(png)
print("%s: %dx%d -> %dx%d" % (dst, w, h, w * k, h * k))
