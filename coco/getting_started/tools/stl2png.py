#!/usr/bin/env python3
"""Render STL assemblies as flat-shaded 'manual illustration' PNGs.

Produces the look of the flat-color spot illustrations in early-80s
Atari manuals (An Introduction to the DOS, DOS II Reference Manual):
orthographic 3/4 view, a few quantized tones per part, heavy black
contour lines, transparent background.

Usage (one or more parts, each with its own base color):
  stl2png.py --part file.stl '#d8c9a3' [--part file2.stl '#4a3c30' ...]
             --azim 35 --elev 22 --out out.png [--width 1600]
             [--roll 0] [--levels 0.62,0.82,1.0] [--floor]
"""
import argparse
import struct
import sys

import numpy as np
from PIL import Image


def load_stl(path):
    with open(path, "rb") as f:
        head = f.read(80)
        rest = f.read()
    if head[:5] == b"solid" and b"facet" in rest[:2000]:
        # ASCII STL
        verts = []
        for line in rest.decode("ascii", "ignore").splitlines():
            line = line.strip()
            if line.startswith("vertex"):
                verts.append([float(v) for v in line.split()[1:4]])
        tris = np.array(verts, dtype=np.float32).reshape(-1, 3, 3)
    else:
        n = struct.unpack("<I", rest[:4])[0]
        data = np.frombuffer(rest[4:4 + n * 50], dtype=np.uint8).reshape(n, 50)
        tris = data[:, 12:48].copy().view("<f4").reshape(n, 3, 3)
    return tris


def rot_z(a):
    c, s = np.cos(a), np.sin(a)
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]], dtype=np.float64)


def rot_x(a):
    c, s = np.cos(a), np.sin(a)
    return np.array([[1, 0, 0], [0, c, -s], [0, s, c]], dtype=np.float64)


def rot_y(a):
    c, s = np.cos(a), np.sin(a)
    return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]], dtype=np.float64)


def hex_rgb(s):
    s = s.lstrip("#")
    return np.array([int(s[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float64)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--part", nargs=2, action="append", required=True,
                    metavar=("STL", "COLOR"))
    ap.add_argument("--azim", type=float, default=35.0)
    ap.add_argument("--elev", type=float, default=22.0)
    ap.add_argument("--roll", type=float, default=0.0)
    ap.add_argument("--out", required=True)
    ap.add_argument("--width", type=int, default=1600)
    ap.add_argument("--ss", type=int, default=2, help="supersample factor")
    ap.add_argument("--levels", default="0.60,0.80,1.0",
                    help="quantized shade multipliers, dark to light")
    ap.add_argument("--outline", type=float, default=2.6,
                    help="outline thickness in output pixels")
    ap.add_argument("--depth-edge", type=float, default=1.2,
                    help="depth jump (mm) treated as a contour")
    args = ap.parse_args()

    levels = np.array([float(v) for v in args.levels.split(",")])

    # ---- assemble scene -------------------------------------------------
    tris_all, part_id, colors = [], [], []
    for i, (path, col) in enumerate(args.part):
        t = load_stl(path)
        tris_all.append(t)
        part_id.append(np.full(len(t), i, dtype=np.int32))
        colors.append(hex_rgb(col))
    tris = np.concatenate(tris_all).astype(np.float64)
    part_id = np.concatenate(part_id)
    colors = np.stack(colors)

    # ---- view transform (z up, orthographic; +elev looks from above) ----
    R = rot_y(np.radians(args.roll)) @ rot_x(np.radians(args.elev)) \
        @ rot_z(np.radians(args.azim))
    v = tris.reshape(-1, 3) @ R.T
    v = v.reshape(-1, 3, 3)
    # screen: u = x, v = z (flipped), depth = y (camera looks along +y)
    u, w, d = v[:, :, 0], v[:, :, 2], v[:, :, 1]

    # face normals in view space
    e1 = v[:, 1] - v[:, 0]
    e2 = v[:, 2] - v[:, 0]
    nrm = np.cross(e1, e2)
    ln = np.linalg.norm(nrm, axis=1)
    ok = ln > 1e-9
    nrm[ok] /= ln[ok][:, None]
    # make normals face the camera (camera looks along +y, sees -y faces)
    flip = nrm[:, 1] > 0
    nrm[flip] = -nrm[flip]

    # backface cull helps speed; keep near-edge-on faces for silhouettes
    keep = ok
    u, w, d, nrm = u[keep], w[keep], d[keep], nrm[keep]
    part_id = part_id[keep]

    # ---- fit to image ----------------------------------------------------
    pad = 0.04
    umin, umax = u.min(), u.max()
    wmin, wmax = w.min(), w.max()
    span_u, span_w = umax - umin, wmax - wmin
    W = args.width * args.ss
    scale = W * (1 - 2 * pad) / span_u
    H = int(np.ceil(span_w * scale + 2 * pad * W))
    ox = (W - span_u * scale) / 2
    oy = (H - span_w * scale) / 2
    px = (u - umin) * scale + ox
    py = (wmax - w) * scale + oy

    # ---- z-buffer rasterization -----------------------------------------
    zbuf = np.full((H, W), np.inf, dtype=np.float64)
    fid = np.full((H, W), -1, dtype=np.int32)

    order = np.argsort(d.mean(axis=1))  # near-to-far not needed w/ zbuf; any
    for t in order:
        x0, x1 = px[t].min(), px[t].max()
        y0, y1 = py[t].min(), py[t].max()
        ix0, ix1 = int(np.floor(x0)), int(np.ceil(x1)) + 1
        iy0, iy1 = int(np.floor(y0)), int(np.ceil(y1)) + 1
        ix0, iy0 = max(ix0, 0), max(iy0, 0)
        ix1, iy1 = min(ix1, W), min(iy1, H)
        if ix0 >= ix1 or iy0 >= iy1:
            continue
        xs = np.arange(ix0, ix1) + 0.5
        ys = np.arange(iy0, iy1) + 0.5
        gx, gy = np.meshgrid(xs, ys)
        ax, ay = px[t, 0], py[t, 0]
        bx, by = px[t, 1], py[t, 1]
        cx, cy = px[t, 2], py[t, 2]
        den = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
        if abs(den) < 1e-12:
            continue
        l1 = ((by - cy) * (gx - cx) + (cx - bx) * (gy - cy)) / den
        l2 = ((cy - ay) * (gx - cx) + (ax - cx) * (gy - cy)) / den
        l3 = 1 - l1 - l2
        eps = -1e-9
        inside = (l1 >= eps) & (l2 >= eps) & (l3 >= eps)
        if not inside.any():
            continue
        depth = l1 * d[t, 0] + l2 * d[t, 1] + l3 * d[t, 2]
        sub = zbuf[iy0:iy1, ix0:ix1]
        fsub = fid[iy0:iy1, ix0:ix1]
        win = inside & (depth < sub)
        sub[win] = depth[win]
        fsub[win] = t

    # ---- flat shading, quantized ----------------------------------------
    light = np.array([-0.45, -0.75, 0.55])
    light = light / np.linalg.norm(light)
    lam = np.clip((nrm * light).sum(axis=1), 0, 1)
    # quantize lambert into len(levels) buckets
    edges = np.linspace(0, 1, len(levels) + 1)[1:-1]
    bucket = np.digitize(lam, edges)
    shade = levels[bucket]

    img = np.zeros((H, W, 4), dtype=np.float64)
    vis = fid >= 0
    f = fid[vis]
    img[vis, :3] = colors[part_id[f]] * shade[f][:, None]
    img[vis, 3] = 255

    # ---- contour lines ----------------------------------------------------
    # silhouette: visible vs background; crease: depth discontinuity or
    # part change or shade-bucket change between neighbors
    zb = np.where(np.isinf(zbuf), np.nan, zbuf)
    edge = np.zeros((H, W), dtype=bool)
    bgt = ~vis
    for axis, shift in ((0, 1), (1, 1)):
        a = np.roll(vis, shift, axis=axis)
        edge |= vis & ~a  # silhouette against background
        dz = np.abs(zb - np.roll(zb, shift, axis=axis))
        edge |= vis & a & (dz > args.depth_edge)
        pa = np.roll(np.where(vis, part_id[np.clip(fid, 0, None)], -1),
                     shift, axis=axis)
        ph = np.where(vis, part_id[np.clip(fid, 0, None)], -1)
        edge |= vis & a & (pa != ph) & (pa >= 0)
        bu = np.where(vis, bucket[np.clip(fid, 0, None)], -1)
        ba = np.roll(bu, shift, axis=axis)
        # only mark strong shade-steps (2+ buckets) as drawn creases
        edge |= vis & a & (np.abs(bu - ba) >= 2) & (ba >= 0)

    # dilate edge to outline thickness
    r = max(1, int(round(args.outline * args.ss / 2)))
    em = edge.copy()
    for _ in range(r):
        em = em | np.roll(em, 1, 0) | np.roll(em, -1, 0) \
                | np.roll(em, 1, 1) | np.roll(em, -1, 1)
    img[em, :3] = np.array([26, 24, 22], dtype=np.float64)
    img[em, 3] = 255

    out = Image.fromarray(img.clip(0, 255).astype(np.uint8), "RGBA")
    if args.ss > 1:
        out = out.resize((W // args.ss, H // args.ss), Image.LANCZOS)
    out.save(args.out)
    print(f"wrote {args.out} ({out.width}x{out.height})")


if __name__ == "__main__":
    main()
