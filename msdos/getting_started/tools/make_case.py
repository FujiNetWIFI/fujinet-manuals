#!/usr/bin/env python3
"""Assemble the FujiNet RS232 Rev1b case for manual illustration.

The fujinet-hardware Rev1b STLs ship as two separate printable shells
(Case Top, Case Bottom) laid out side by side, plus a single Knurled
Knob and a Button.  This script:

  * recentres each half on the XY origin,
  * flips the Top over and stacks it on the Bottom to form the closed
    clamshell,
  * mirrors the one knurled knob into the pair that flanks the DB-9,
  * keeps the button,
  * generates the DB-9 male connector (shell + pins) that plugs into
    the PC's serial port, and two LED light-pipe domes,

and writes the transformed/!generated parts as STL files that the
Makefile feeds to stl2png.py.  Output goes in this tools/ directory.

Run:  python3 tools/make_case.py tools
"""
import sys
import os
import struct
import numpy as np

HW = os.path.expanduser(
    "~/Workspace/fujinet-hardware/RS232/RS232-Rev1b/3D")
TOP = os.path.join(HW, "FujiNet RS232-Rev1b Case Top.stl")
BOT = os.path.join(HW, "FujiNet RS232-Rev1b Case Bottom.stl")
KNOB = os.path.join(HW, "FujiNet-RS232-Rev1-Knurled-Knob.stl")
BTN = os.path.join(HW, "FujiNet-RS232-Rev1-Button.stl")


# ---------- STL io ----------------------------------------------------
def load_stl(path):
    with open(path, "rb") as f:
        head = f.read(80)
        rest = f.read()
    if head[:5] == b"solid" and b"facet" in rest[:2000]:
        verts = []
        for line in rest.decode("ascii", "ignore").splitlines():
            line = line.strip()
            if line.startswith("vertex"):
                verts.append([float(v) for v in line.split()[1:4]])
        return np.array(verts, dtype=np.float64).reshape(-1, 3, 3)
    n = struct.unpack("<I", rest[:4])[0]
    data = np.frombuffer(rest[4:4 + n * 50], dtype=np.uint8).reshape(n, 50)
    return data[:, 12:48].copy().view("<f4").reshape(n, 3, 3).astype(np.float64)


def save_stl(path, tris):
    tris = tris.astype(np.float32)
    n = len(tris)
    with open(path, "wb") as f:
        f.write(b"\0" * 80)
        f.write(struct.pack("<I", n))
        for t in tris:
            e1 = t[1] - t[0]
            e2 = t[2] - t[0]
            nrm = np.cross(e1, e2)
            ln = np.linalg.norm(nrm)
            if ln > 1e-12:
                nrm = nrm / ln
            f.write(struct.pack("<3f", *nrm))
            for v in t:
                f.write(struct.pack("<3f", *v))
            f.write(b"\0\0")


# ---------- geometry helpers -----------------------------------------
def bbox(t):
    v = t.reshape(-1, 3)
    return v.min(0), v.max(0)


def center_xy(t, cx, cy):
    out = t.copy()
    out[:, :, 0] -= cx
    out[:, :, 1] -= cy
    return out


def quad(p0, p1, p2, p3):
    return [[p0, p1, p2], [p0, p2, p3]]


def box(x0, x1, y0, y1, z0, z1):
    c = [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0),
         (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)]
    c = [np.array(p, dtype=np.float64) for p in c]
    f = []
    f += quad(c[0], c[3], c[2], c[1])   # bottom
    f += quad(c[4], c[5], c[6], c[7])   # top
    f += quad(c[0], c[1], c[5], c[4])   # front
    f += quad(c[3], c[7], c[6], c[2])   # back
    f += quad(c[1], c[2], c[6], c[5])   # right
    f += quad(c[0], c[4], c[7], c[3])   # left
    return np.array(f, dtype=np.float64)


def cyl(cx, cy, z0, z1, r, seg=40, axis="z"):
    f = []
    for i in range(seg):
        a0 = 2 * np.pi * i / seg
        a1 = 2 * np.pi * (i + 1) / seg
        if axis == "z":
            p0 = (cx + r * np.cos(a0), cy + r * np.sin(a0))
            p1 = (cx + r * np.cos(a1), cy + r * np.sin(a1))
            b0 = np.array([p0[0], p0[1], z0]); b1 = np.array([p1[0], p1[1], z0])
            t0 = np.array([p0[0], p0[1], z1]); t1 = np.array([p1[0], p1[1], z1])
        else:  # axis == 'y'  (cylinder along Y, cx=x center, cy=z center)
            p0 = (cx + r * np.cos(a0), cy + r * np.sin(a0))
            p1 = (cx + r * np.cos(a1), cy + r * np.sin(a1))
            b0 = np.array([p0[0], z0, p0[1]]); b1 = np.array([p1[0], z0, p1[1]])
            t0 = np.array([p0[0], z1, p0[1]]); t1 = np.array([p1[0], z1, p1[1]])
        f += quad(b0, b1, t1, t0)
        cap0 = (np.array([cx, cy, z0]) if axis == "z"
                else np.array([cx, z0, cy]))
        cap1 = (np.array([cx, cy, z1]) if axis == "z"
                else np.array([cx, z1, cy]))
        f += [[cap0, b1, b0]]
        f += [[cap1, t0, t1]]
    return np.array(f, dtype=np.float64)


def main():
    outdir = sys.argv[1] if len(sys.argv) > 1 else "tools"
    os.makedirs(outdir, exist_ok=True)

    bottom = load_stl(BOT)
    top = load_stl(TOP)
    knob = load_stl(KNOB)
    btn = load_stl(BTN)

    bmin, bmax = bbox(bottom)
    bcx, bcy = (bmin[0] + bmax[0]) / 2, (bmin[1] + bmax[1]) / 2

    # --- Bottom: recentre XY, leave Z (outer floor at z=0) ---
    bottom = center_xy(bottom, bcx, bcy)
    knob = center_xy(knob, bcx, bcy)
    btn = center_xy(btn, bcx, bcy)
    part_z = bmax[2]                      # parting plane height (~5.1)

    # --- Top: recentre XY on its own bbox, flip Z, sit on parting line ---
    tmin, tmax = bbox(top)
    tcx, tcy = (tmin[0] + tmax[0]) / 2, (tmin[1] + tmax[1]) / 2
    top = center_xy(top, tcx, tcy)
    # Close the clamshell by rotating the lid 180 deg about the long (Y)
    # axis: x -> -x, z -> -z.  This keeps the connector neck at +Y (it
    # must sit over the base's neck) while turning the lid over so its
    # rim mates onto the base rim and the outer face points up.
    top[:, :, 0] = -top[:, :, 0]
    top[:, :, 2] = -top[:, :, 2]
    top = top[:, ::-1, :]                 # restore winding after mirror
    top[:, :, 2] += part_z + (tmax[2] - tmin[2])   # lift onto parting line
    top[:, :, 2] -= 0.6                    # slight rim overlap

    # --- knob: mirror across X to make the pair ---
    knob_l = knob
    knob_r = knob.copy()
    knob_r[:, :, 0] = -knob_r[:, :, 0]    # mirror about case X centre
    # mirroring flips winding; reverse vertex order so normals stay sane
    knob_r = knob_r[:, ::-1, :]

    # --- DB-9 male connector at the +Y (connector) end ---------------
    yfront = bmax[1] - bcy                # +Y rim of the case
    zc = part_z                           # connector centred on parting plane
    # metal shell: D-shaped, approximated by a flat trapezoidal box
    shell = []
    sx = 15.5                             # half width of shell
    sh0, sh1 = zc - 5.2, zc + 5.2
    y0, y1 = yfront - 1.0, yfront + 7.5
    # trapezoid cross-section (wider at base) extruded along Y
    top_w, bot_w = sx - 1.2, sx
    pa = np.array([-bot_w, y1, sh0]); pb = np.array([bot_w, y1, sh0])
    pc = np.array([top_w, y1, sh1]); pd = np.array([-top_w, y1, sh1])
    qa = np.array([-bot_w, y0, sh0]); qb = np.array([bot_w, y0, sh0])
    qc = np.array([top_w, y0, sh1]); qd = np.array([-top_w, y0, sh1])
    shell += quad(pa, pb, pc, pd)         # front face (mouth)
    shell += quad(qa, qd, qc, qb)         # back face
    shell += quad(pa, pd, qd, qa)         # left
    shell += quad(pb, qb, qc, pc)         # right
    shell += quad(pd, pc, qc, qd)         # top
    shell += quad(pa, qa, qb, pb)         # bottom
    shell = np.array(shell, dtype=np.float64)
    # 9 pins poking out of the mouth (two rows: 5 + 4)
    pins = []
    for (px, pz) in ([(-8 + 4 * i, zc + 1.6) for i in range(5)] +
                     [(-6 + 4 * i, zc - 1.6) for i in range(4)]):
        pins.append(cyl(px, pz, y1, y1 + 3.0, 0.55, seg=10, axis="y"))
    pins = np.concatenate(pins) if pins else np.zeros((0, 3, 3))

    # --- two LED light-pipe domes near the connector end -------------
    # placed just inside the +Y rim, flanking centre (flagged for
    # verification against the board in FIGURES.md)
    ledz = top[:, :, 2].max()             # outer top face height
    led_w = cyl(-5.0, yfront - 9.0, ledz - 0.4, ledz + 0.8, 1.4, seg=20)
    led_o = cyl(5.0, yfront - 9.0, ledz - 0.4, ledz + 0.8, 1.4, seg=20)

    save_stl(os.path.join(outdir, "asm_bottom.stl"), bottom)
    save_stl(os.path.join(outdir, "asm_top.stl"), top)
    save_stl(os.path.join(outdir, "asm_knob_l.stl"), knob_l)
    save_stl(os.path.join(outdir, "asm_knob_r.stl"), knob_r)
    save_stl(os.path.join(outdir, "asm_button.stl"), btn)
    save_stl(os.path.join(outdir, "asm_db9_shell.stl"), shell)
    save_stl(os.path.join(outdir, "asm_db9_pins.stl"), pins)
    save_stl(os.path.join(outdir, "asm_led_white.stl"), led_w)
    save_stl(os.path.join(outdir, "asm_led_orange.stl"), led_o)
    print("wrote assembled parts to", outdir)
    print("  parting plane z =", round(part_z, 2),
          " case top z =", round(ledz, 2))


if __name__ == "__main__":
    main()
