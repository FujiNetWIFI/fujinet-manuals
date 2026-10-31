#!/usr/bin/env python3
"""patchurl.py in.a52 out.a52 OLD NEW -- a bench copy of a game that talks to
the book's own server: the default server address, OLD, replaced by NEW (no
longer than OLD) and NUL-padded, everything else byte for byte the
published image.  Used only for the screenshots; never published.
"""
import sys

src, dst, old, new = sys.argv[1:5]
data = bytearray(open(src, "rb").read())
o, n = old.encode(), new.encode()
assert len(n) <= len(o), "the new address must not be longer"
i = data.find(o + b"\0")
assert i >= 0 and data.find(o, i + 1) < 0, f"{old} not found exactly once"
data[i:i + len(o)] = n + b"\0" * (len(o) - len(n))
open(dst, "wb").write(data)
print(f"{dst}: {old} -> {new} at ${i:05X}")
