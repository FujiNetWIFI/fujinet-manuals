#!/usr/bin/env python3
"""Generate accent-part STLs for the CoCo FujiNet Rev000 case renders.

The case STLs (fujinet-hardware Coco/CoCo-FujiNet-Rev000/3D/STL) ship as
empty shells; the real unit shows LEDs, the red DIP switch, button stems,
the dark port openings, and the captive serial cable.  These small parts
are generated in the case's own coordinate system so they can be passed
to stl2png.py as separately-colored --part entries.

Feature positions were measured from the Upper/Lower STLs (see git
history of this file):
  top face z=18; ports wall x=87.88; cable hole (y-max wall) x=55, z=6.4
  white LED (76.3, 5.3)   orange LED (76.3, 48.0)     r=2.5 holes
  DIP window center (57.7, 5.8) ~6.6 x 9.2
  button holes on ports wall: y=5.3 / 48.1, z=5.5
  micro-USB (y=26.8, z=10.9) 8.4x3.4 / microSD slot (y=26.7, z=2.6) 15x2
"""
import struct
import sys
import numpy as np

OUT = sys.argv[1] if len(sys.argv) > 1 else "tools"


def cylinder(c0, c1, r, segs=24, cap0=True, cap1=True):
    """Tube from point c0 to c1 with radius r."""
    c0, c1 = np.asarray(c0, float), np.asarray(c1, float)
    ax = c1 - c0
    ln = np.linalg.norm(ax)
    ax = ax / ln
    ref = np.array([0, 0, 1.0]) if abs(ax[2]) < 0.9 else np.array([1.0, 0, 0])
    u = np.cross(ax, ref); u /= np.linalg.norm(u)
    v = np.cross(ax, u)
    tris = []
    for i in range(segs):
        a0 = 2 * np.pi * i / segs
        a1 = 2 * np.pi * (i + 1) / segs
        p0 = c0 + r * (np.cos(a0) * u + np.sin(a0) * v)
        p1 = c0 + r * (np.cos(a1) * u + np.sin(a1) * v)
        q0, q1 = p0 + ln * ax, p1 + ln * ax
        tris += [(p0, p1, q0), (p1, q1, q0)]
        if cap0: tris.append((c0, p1, p0))
        if cap1: tris.append((c0 + ln * ax, q0, q1))
    return tris


def dome(c, r, segs=20, rings=6):
    """Hemispherical cap, +z, centered at c."""
    c = np.asarray(c, float)
    tris = []
    for j in range(rings):
        t0 = (np.pi / 2) * j / rings
        t1 = (np.pi / 2) * (j + 1) / rings
        for i in range(segs):
            a0 = 2 * np.pi * i / segs
            a1 = 2 * np.pi * (i + 1) / segs
            def pt(t, a):
                return c + r * np.array([np.cos(t) * np.cos(a),
                                         np.cos(t) * np.sin(a),
                                         np.sin(t)])
            p00, p01, p10, p11 = pt(t0, a0), pt(t0, a1), pt(t1, a0), pt(t1, a1)
            tris.append((p00, p01, p11))
            if j < rings - 1:
                tris.append((p00, p11, p10))
    return tris


def box(x0, x1, y0, y1, z0, z1):
    p = lambda a, b, c: np.array([a, b, c], float)
    v = [p(x0,y0,z0), p(x1,y0,z0), p(x1,y1,z0), p(x0,y1,z0),
         p(x0,y0,z1), p(x1,y0,z1), p(x1,y1,z1), p(x0,y1,z1)]
    f = [(0,2,1),(0,3,2),(4,5,6),(4,6,7),(0,1,5),(0,5,4),
         (1,2,6),(1,6,5),(2,3,7),(2,7,6),(3,0,4),(3,4,7)]
    return [(v[a], v[b], v[c]) for a, b, c in f]


def sweep(path, r, segs=16):
    """Tube swept along a 3D polyline (no caps between segments)."""
    path = [np.asarray(p, float) for p in path]
    tris = []
    rings = []
    for i, p in enumerate(path):
        if i == 0:
            ax = path[1] - path[0]
        elif i == len(path) - 1:
            ax = path[-1] - path[-2]
        else:
            ax = path[i + 1] - path[i - 1]
        ax = ax / np.linalg.norm(ax)
        ref = np.array([0, 0, 1.0]) if abs(ax[2]) < 0.9 else np.array([1.0, 0, 0])
        u = np.cross(ax, ref); u /= np.linalg.norm(u)
        v = np.cross(ax, u)
        ring = [p + r * (np.cos(2 * np.pi * k / segs) * u +
                         np.sin(2 * np.pi * k / segs) * v) for k in range(segs)]
        rings.append(ring)
    for i in range(len(rings) - 1):
        for k in range(segs):
            a, b = rings[i][k], rings[i][(k + 1) % segs]
            c, d = rings[i + 1][k], rings[i + 1][(k + 1) % segs]
            tris += [(a, b, c), (b, d, c)]
    # end caps
    for ring, ctr in ((rings[0], path[0]), (rings[-1], path[-1])):
        for k in range(segs):
            tris.append((ctr, ring[k], ring[(k + 1) % segs]))
    return tris


def write_stl(name, tris):
    with open(f"{OUT}/{name}", "wb") as f:
        f.write(name.encode().ljust(80, b"\0"))
        f.write(struct.pack("<I", len(tris)))
        for t in tris:
            f.write(struct.pack("<3f", 0, 0, 0))
            for v in t:
                f.write(struct.pack("<3f", *v))
            f.write(struct.pack("<H", 0))
    print(f"wrote {OUT}/{name} ({len(tris)} tris)")


# --- LEDs: stem + dome, proud of the z=18 top face -------------------
def led(cx, cy):
    return cylinder((cx, cy, 16.5), (cx, cy, 18.4), 2.25) + \
           dome((cx, cy, 18.4), 2.25)

write_stl("led_white.stl", led(76.3, 5.3))
write_stl("led_orange.stl", led(76.3, 48.0))

# --- DIP switch: red body recessed in its window, two white actuators
write_stl("dip_body.stl", box(54.6, 60.8, 1.4, 10.2, 15.6, 17.0))
write_stl("dip_nubs.stl",
          box(55.6, 59.8, 2.6, 4.6, 17.0, 17.4) +
          box(55.6, 59.8, 6.6, 8.6, 17.0, 17.4))

# --- button stems through the ports wall (x = 87.88) ------------------
def stem(y):
    return cylinder((86.0, y, 5.5), (89.2, y, 5.5), 1.5)

write_stl("buttons.stl", stem(5.3) + stem(48.1))

# --- dark interior floor: shows through the cut-out lettering --------
write_stl("interior.stl", box(0.0, 85.0, -24.0, 77.5, 14.6, 15.2))

# --- dark inserts behind the micro-USB and microSD openings ----------
write_stl("ports_dark.stl",
          box(86.2, 87.6, 22.6, 31.0, 9.2, 12.6) +   # micro-USB
          box(86.2, 87.6, 19.2, 34.2, 1.6, 3.6))     # microSD slot

# --- captive serial cable out the rear wall (x=55, y=80.8, z=6.4) ----
# gentle S-curve up and away, ending in the DIN-4 plug
t = np.linspace(0, 1, 24)
px = 55 + 6 * t + 26 * t * t
py = 80.8 + 46 * t - 14 * t * t
pz = 6.4 + 2 * t + 30 * t * t * t
path = list(zip(px, py, pz))
write_stl("cable.stl", sweep(path, 2.1))

# DIN-4 plug continuing along the cable's end direction
end = np.array(path[-1])
d = np.array(path[-1]) - np.array(path[-2]); d /= np.linalg.norm(d)
write_stl("plug.stl",
          cylinder(end, end + 11 * d, 3.0) +          # strain relief
          cylinder(end + 11 * d, end + 26 * d, 6.6) + # barrel
          cylinder(end + 26 * d, end + 32 * d, 5.6))  # metal shell
