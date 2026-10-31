"""stlkit -- the few mesh helpers the 2600 owner's-manual art needs.

Lifted from msdos/getting_started/tools/make_case.py and make_pc.py (binary
STL io, box, cylinder) and extended with what a console and a cartridge
need: a profile extruded along an axis with ear-clipped caps (the console's
side silhouette is not convex), rotations, and a tube along a polyline (a
joystick cable).  Triangles are numpy (n, 3, 3) float64 arrays throughout.
"""
import struct

import numpy as np


# ---------- io ---------------------------------------------------------
def load_stl(path):
    with open(path, "rb") as f:
        head = f.read(80)
        rest = f.read()
    if head[:5] == b"solid" and b"facet" in rest[:2000]:
        verts = []
        for line in (head + rest).decode("ascii", "ignore").splitlines():
            line = line.strip()
            if line.startswith("vertex"):
                verts.append([float(v) for v in line.split()[1:4]])
        return np.array(verts, dtype=np.float64).reshape(-1, 3, 3)
    n = struct.unpack("<I", rest[:4])[0]
    data = np.frombuffer(rest[4:4 + n * 50], dtype=np.uint8).reshape(n, 50)
    return data[:, 12:48].copy().view("<f4").reshape(n, 3, 3).astype(np.float64)


def save_stl(path, tris):
    tris = np.asarray(tris, dtype=np.float32).reshape(-1, 3, 3)
    e1 = tris[:, 1] - tris[:, 0]
    e2 = tris[:, 2] - tris[:, 0]
    nrm = np.cross(e1, e2)
    ln = np.linalg.norm(nrm, axis=1)
    nrm[ln > 1e-12] /= ln[ln > 1e-12][:, None]
    rec = np.zeros(len(tris), dtype=[("n", "<f4", 3), ("v", "<f4", (3, 3)),
                                     ("a", "<u2")])
    rec["n"] = nrm
    rec["v"] = tris
    with open(path, "wb") as f:
        f.write(b"\0" * 80)
        f.write(struct.pack("<I", len(tris)))
        f.write(rec.tobytes())


def cat(*parts):
    parts = [np.asarray(p, dtype=np.float64).reshape(-1, 3, 3)
             for p in parts if p is not None and len(p)]
    return np.concatenate(parts) if parts else np.zeros((0, 3, 3))


# ---------- transforms -------------------------------------------------
def rx(deg):
    a = np.radians(deg); c, s = np.cos(a), np.sin(a)
    return np.array([[1, 0, 0], [0, c, -s], [0, s, c]])


def ry(deg):
    a = np.radians(deg); c, s = np.cos(a), np.sin(a)
    return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])


def rz(deg):
    a = np.radians(deg); c, s = np.cos(a), np.sin(a)
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])


def xform(tris, R=None, t=(0, 0, 0)):
    """Rotate (about the origin) then translate."""
    v = np.asarray(tris, dtype=np.float64).reshape(-1, 3)
    if R is not None:
        v = v @ np.asarray(R).T
    v = v + np.asarray(t, dtype=np.float64)
    return v.reshape(-1, 3, 3)


def mirror(tris, axis):
    out = np.array(tris, dtype=np.float64)
    out[:, :, axis] = -out[:, :, axis]
    return out[:, ::-1, :]          # keep the winding outward


def bbox(tris):
    v = np.asarray(tris).reshape(-1, 3)
    return v.min(0), v.max(0)


# ---------- primitives -------------------------------------------------
def quad(p0, p1, p2, p3):
    p0, p1, p2, p3 = (np.array(p, float) for p in (p0, p1, p2, p3))
    return [[p0, p1, p2], [p0, p2, p3]]


def box(x0, x1, y0, y1, z0, z1):
    c = [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0),
         (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)]
    f = []
    f += quad(c[0], c[3], c[2], c[1])
    f += quad(c[4], c[5], c[6], c[7])
    f += quad(c[0], c[1], c[5], c[4])
    f += quad(c[3], c[7], c[6], c[2])
    f += quad(c[1], c[2], c[6], c[5])
    f += quad(c[0], c[4], c[7], c[3])
    return np.array(f, dtype=np.float64)


def _area2(pts):
    a = 0.0
    for i in range(len(pts)):
        x0, y0 = pts[i]; x1, y1 = pts[(i + 1) % len(pts)]
        a += x0 * y1 - x1 * y0
    return a


def earclip(pts):
    """Triangulate a simple polygon (list of (a, b)); returns index triples,
    counter-clockwise."""
    idx = list(range(len(pts)))
    if _area2(pts) < 0:
        idx.reverse()
    out = []

    def inside(p, a, b, c):
        def s(p1, p2, p3):
            return (p1[0] - p3[0]) * (p2[1] - p3[1]) - (p2[0] - p3[0]) * (p1[1] - p3[1])
        d1, d2, d3 = s(p, a, b), s(p, b, c), s(p, c, a)
        neg = d1 < 0 or d2 < 0 or d3 < 0
        pos = d1 > 0 or d2 > 0 or d3 > 0
        return not (neg and pos)

    guard = 0
    while len(idx) > 3 and guard < 10000:
        guard += 1
        n = len(idx)
        for k in range(n):
            i0, i1, i2 = idx[k - 1], idx[k], idx[(k + 1) % n]
            a, b, c = pts[i0], pts[i1], pts[i2]
            cross = (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])
            if cross <= 1e-12:
                continue
            if any(inside(pts[j], a, b, c) for j in idx
                   if j not in (i0, i1, i2)):
                continue
            out.append((i0, i1, i2))
            del idx[k]
            break
        else:
            break
    if len(idx) == 3:
        out.append(tuple(idx))
    return out


def extrude(profile, a0, a1, axis="x"):
    """Prism: a 2-D profile extruded from a0 to a1 along `axis`.
    axis 'x': profile is (y, z); 'y': (x, z); 'z': (x, y)."""
    def P(p, a):
        u, v = p
        if axis == "x":
            return np.array([a, u, v], float)
        if axis == "y":
            return np.array([u, a, v], float)
        return np.array([u, v, a], float)
    n = len(profile)
    f = []
    for i in range(n):
        p, q = profile[i], profile[(i + 1) % n]
        f += quad(P(p, a0), P(q, a0), P(q, a1), P(p, a1))
    for i, j, k in earclip(profile):
        f.append([P(profile[i], a0), P(profile[k], a0), P(profile[j], a0)])
        f.append([P(profile[i], a1), P(profile[j], a1), P(profile[k], a1)])
    return np.array(f, dtype=np.float64)


def cyl(c0, c1, r, seg=32, r1=None):
    """Cylinder (or cone frustum if r1 given) from point c0 to point c1."""
    c0, c1 = np.array(c0, float), np.array(c1, float)
    r1 = r if r1 is None else r1
    ax = c1 - c0
    ax /= np.linalg.norm(ax)
    tmp = np.array([1, 0, 0]) if abs(ax[0]) < 0.9 else np.array([0, 1, 0])
    u = np.cross(ax, tmp); u /= np.linalg.norm(u)
    v = np.cross(ax, u)
    f = []
    for i in range(seg):
        a0 = 2 * np.pi * i / seg
        a1 = 2 * np.pi * (i + 1) / seg
        d0 = u * np.cos(a0) + v * np.sin(a0)
        d1 = u * np.cos(a1) + v * np.sin(a1)
        f += quad(c0 + r * d0, c0 + r * d1, c1 + r1 * d1, c1 + r1 * d0)
        f.append([c0, c0 + r * d1, c0 + r * d0])
        f.append([c1, c1 + r1 * d0, c1 + r1 * d1])
    return np.array(f, dtype=np.float64)


def sphere(c, r, seg=24, ring=12, zmin=-1.0):
    """Sphere (or a cap of one: rings below zmin*r are dropped)."""
    c = np.array(c, float)
    f = []
    for j in range(ring):
        t0 = np.pi * j / ring - np.pi / 2
        t1 = np.pi * (j + 1) / ring - np.pi / 2
        if np.sin(t1) < zmin:
            continue
        for i in range(seg):
            p0 = 2 * np.pi * i / seg
            p1 = 2 * np.pi * (i + 1) / seg

            def pt(t, p):
                return c + r * np.array([np.cos(t) * np.cos(p),
                                         np.cos(t) * np.sin(p), np.sin(t)])
            f += quad(pt(t0, p0), pt(t0, p1), pt(t1, p1), pt(t1, p0))
    return np.array(f, dtype=np.float64)


def tube(points, r, seg=12):
    """A round cable along a polyline."""
    pts = [np.array(p, float) for p in points]
    return cat(*[cyl(pts[i], pts[i + 1], r, seg=seg)
                 for i in range(len(pts) - 1)],
               *[sphere(p, r, seg=seg, ring=6) for p in pts[1:-1]])


def bezier(p0, p1, p2, p3, n=16):
    p0, p1, p2, p3 = (np.array(p, float) for p in (p0, p1, p2, p3))
    return [(1 - t) ** 3 * p0 + 3 * (1 - t) ** 2 * t * p1 +
            3 * (1 - t) * t ** 2 * p2 + t ** 3 * p3
            for t in np.linspace(0, 1, n)]
