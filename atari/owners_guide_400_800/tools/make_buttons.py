#!/usr/bin/env python3
"""Generate buttons.stl — three cylindrical button caps that sit in the
top-face holes of the FujiNet 400/800 case (FN32ROV-1.7.1 assembly
coordinates). The case STLs ship with empty holes; the real unit has
the tact-switch caps visible in them, so the illustrations should too.

Hole centers measured from the case rim geometry (see git history):
on the front/rear seam at x≈0.9, y = +21.7 (A), +11.5 (B), -22.2 (C).
"""
import struct
import sys

import numpy as np

CENTERS = [(0.9, 21.7), (0.9, 11.5), (0.9, -22.2)]
RADIUS = 1.55          # cap radius, sits inside the ~2.2 mm hole
Z0, Z1 = 70.0, 73.45   # slightly proud of the z=73 top surface
SEGS = 24


def cylinder(cx, cy, r, z0, z1, segs):
    tris = []
    for i in range(segs):
        a0 = 2 * np.pi * i / segs
        a1 = 2 * np.pi * (i + 1) / segs
        p0 = (cx + r * np.cos(a0), cy + r * np.sin(a0))
        p1 = (cx + r * np.cos(a1), cy + r * np.sin(a1))
        # wall
        tris.append(((p0[0], p0[1], z0), (p1[0], p1[1], z0), (p0[0], p0[1], z1)))
        tris.append(((p1[0], p1[1], z0), (p1[0], p1[1], z1), (p0[0], p0[1], z1)))
        # top cap
        tris.append(((cx, cy, z1), (p0[0], p0[1], z1), (p1[0], p1[1], z1)))
    return tris


def main(out):
    tris = []
    for cx, cy in CENTERS:
        tris += cylinder(cx, cy, RADIUS, Z0, Z1, SEGS)
    with open(out, "wb") as f:
        f.write(b"buttons".ljust(80, b"\0"))
        f.write(struct.pack("<I", len(tris)))
        for t in tris:
            f.write(struct.pack("<3f", 0, 0, 0))
            for v in t:
                f.write(struct.pack("<3f", *v))
            f.write(struct.pack("<H", 0))
    print(f"wrote {out} ({len(tris)} tris)")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "tools/buttons.stl")
