#!/usr/bin/env python3
"""Build a parametric IBM 5150-style Personal Computer for manual line art.

Generates blocky STL geometry for the System Unit (with two 5.25"
diskette bays), the monochrome Display on its tilt/swivel base, and the
83-key Keyboard, plus a separate rear-panel plate showing the serial
(COM) port where the FujiNet plugs in.  Rendered through stl2png.py the
result matches the flat-shaded, black-contour look of the FujiNet case
illustrations.

Units are arbitrary mm-ish; proportions follow the real 5150
(System Unit 19.6 x 16.1 x 5.5 in, Display ~ 15 in deep).

Run:  python3 tools/make_pc.py tools
"""
import sys
import os
import struct
import numpy as np


def save_stl(path, tris):
    tris = np.asarray(tris, dtype=np.float32)
    with open(path, "wb") as f:
        f.write(b"\0" * 80)
        f.write(struct.pack("<I", len(tris)))
        for t in tris:
            n = np.cross(t[1] - t[0], t[2] - t[0])
            ln = np.linalg.norm(n)
            if ln > 1e-12:
                n = n / ln
            f.write(struct.pack("<3f", *n))
            for v in t:
                f.write(struct.pack("<3f", *v))
            f.write(b"\0\0")


def quad(p0, p1, p2, p3):
    p0, p1, p2, p3 = (np.array(p, float) for p in (p0, p1, p2, p3))
    return [[p0, p1, p2], [p0, p2, p3]]


def box(x0, x1, y0, y1, z0, z1):
    c = [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0),
         (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)]
    f = []
    f += quad(c[0], c[3], c[2], c[1])
    f += quad(c[4], c[5], c[6], c[7])
    f += quad(c[0], c[1], c[5], c[4])     # -Y (front)
    f += quad(c[3], c[7], c[6], c[2])     # +Y (back)
    f += quad(c[1], c[2], c[6], c[5])     # +X (right)
    f += quad(c[0], c[4], c[7], c[3])     # -X (left)
    return f


def cyl(cx, cz, y0, y1, r, seg=28):
    """cylinder along Y (knobs poking out of a front face)."""
    f = []
    for i in range(seg):
        a0 = 2 * np.pi * i / seg
        a1 = 2 * np.pi * (i + 1) / seg
        p0 = (cx + r * np.cos(a0), cz + r * np.sin(a0))
        p1 = (cx + r * np.cos(a1), cz + r * np.sin(a1))
        b0 = (p0[0], y0, p0[1]); b1 = (p1[0], y0, p1[1])
        t0 = (p0[0], y1, p0[1]); t1 = (p1[0], y1, p1[1])
        f += quad(b0, b1, t1, t0)
        f += [[np.array([cx, y1, cz]), np.array(t0), np.array(t1)]]
    return f


def main():
    outdir = sys.argv[1] if len(sys.argv) > 1 else "tools"

    case = []        # beige plastic
    dark = []        # screen / slots / dark recesses
    keys = []        # keycaps
    base = []        # display base / table accents

    # ====================================================================
    # SYSTEM UNIT  (front face at Y=0, depth toward +Y, height up +Z)
    # ====================================================================
    SU_W, SU_D, SU_H = 500.0, 360.0, 138.0
    case += box(0, SU_W, 0, SU_D, 0, SU_H)

    # recessed front bezel frame (shallow inset so an outline reads)
    bz = 10.0
    case += box(bz, SU_W - bz, -2.0, 0.0, bz, SU_H - bz)

    # two 5.25" diskette drive bays on the right half, front face
    bay_w, bay_h = 150.0, 46.0
    bay_x = SU_W - bay_w - 26.0
    for i, bz0 in enumerate((SU_H - 30 - bay_h, SU_H - 30 - 2 * bay_h - 12)):
        dark += box(bay_x, bay_x + bay_w, -3.0, 1.0, bz0, bz0 + bay_h)
        # the horizontal door slot
        dark += box(bay_x + 12, bay_x + bay_w - 12, -5.0, -3.0,
                    bz0 + bay_h / 2 - 4, bz0 + bay_h / 2 + 4)
        # load lever (small square, left of slot)
        case += box(bay_x + 14, bay_x + 30, -6.0, -3.0,
                    bz0 + bay_h / 2 - 7, bz0 + bay_h / 2 + 7)

    # left-front cooling vents (thin vertical raised ribs)
    for i in range(7):
        vx = 40 + i * 16
        case += box(vx, vx + 7, -3.0, 0.0, 34, SU_H - 34)

    # little IBM logo plate, lower-left front
    base += box(36, 96, -4.0, -1.0, 14, 30)

    # ====================================================================
    # DISPLAY  (monochrome monitor, sits on top toward the back)
    # ====================================================================
    MON_W, MON_D, MON_H = 360.0, 330.0, 300.0
    mon_x = (SU_W - MON_W) / 2 + 10
    mon_y = 30.0                          # set back a little
    mon_z0 = SU_H                         # sits on the system unit
    # tilt/swivel base (smaller block under the monitor)
    base += box(mon_x + 40, mon_x + MON_W - 40, mon_y + 40, mon_y + MON_D - 40,
                mon_z0, mon_z0 + 26)
    mz = mon_z0 + 26
    # monitor body
    case += box(mon_x, mon_x + MON_W, mon_y, mon_y + MON_D, mz, mz + MON_H)
    # face bezel inset
    fb = 26.0
    case += box(mon_x + fb, mon_x + MON_W - fb, mon_y - 3.0, mon_y,
                mz + fb, mz + MON_H - fb - 36)
    # the screen (dark, recessed), slightly inboard of the bezel
    sb = 46.0
    dark += box(mon_x + sb, mon_x + MON_W - sb - 60, mon_y - 1.0, mon_y + 6.0,
                mz + sb, mz + MON_H - sb - 40)
    # two control knobs, front-right below the screen
    kx = mon_x + MON_W - 44
    for kz in (mz + 70, mz + 40):
        base += cyl(kx, kz, mon_y - 16.0, mon_y - 2.0, 11.0)
    # brand plate lower-right of bezel
    base += box(mon_x + MON_W - 96, mon_x + MON_W - 54, mon_y - 4.0, mon_y - 1.0,
                mz + 26, mz + 46)

    # ====================================================================
    # KEYBOARD  (in front of the system unit, on the table, wedge profile)
    # ====================================================================
    KB_W, KB_D = 470.0, 185.0
    kb_x = (SU_W - KB_W) / 2
    kb_y = -KB_D - 70.0                   # in front (toward -Y / viewer)
    kb_zf, kb_zb = 14.0, 40.0             # front lower, back higher (wedge)
    # wedge body: 8 triangle/quads
    fx0, fx1 = kb_x, kb_x + KB_W
    fy0, fy1 = kb_y, kb_y + KB_D
    c = {
        "flb": (fx0, fy0, 0), "frb": (fx1, fy0, 0),
        "blb": (fx0, fy1, 0), "brb": (fx1, fy1, 0),
        "flt": (fx0, fy0, kb_zf), "frt": (fx1, fy0, kb_zf),
        "blt": (fx0, fy1, kb_zb), "brt": (fx1, fy1, kb_zb),
    }
    case += quad(c["flb"], c["blb"], c["brb"], c["frb"])   # base
    case += quad(c["flt"], c["frt"], c["brt"], c["blt"])   # top (slanted)
    case += quad(c["flb"], c["frb"], c["frt"], c["flt"])   # front
    case += quad(c["blb"], c["blt"], c["brt"], c["brb"])   # back
    case += quad(c["flb"], c["flt"], c["blt"], c["blb"])   # left
    case += quad(c["frb"], c["brb"], c["brt"], c["frt"])   # right
    # recessed key well
    well = 18.0

    def slant_z(y):
        t = (y - fy0) / (fy1 - fy0)
        return kb_zf + t * (kb_zb - kb_zf)

    # keycaps: 4 rows x 14 (main), a function block of 2x... keep simple:
    # one tidy grid of raised caps with a gap for the numeric pad
    rows, cols = 5, 19
    gx0, gx1 = kb_x + well, kb_x + KB_W - well
    gy0, gy1 = kb_y + well, kb_y + KB_D - well
    cw = (gx1 - gx0) / cols
    rd = (gy1 - gy0) / rows
    for r in range(rows):
        for cidx in range(cols):
            # leave a vertical gap to suggest pad separations
            if cidx in (14,):
                continue
            x0 = gx0 + cidx * cw + 1.5
            x1 = gx0 + (cidx + 1) * cw - 1.5
            y0 = gy0 + r * rd + 1.5
            y1 = gy0 + (r + 1) * rd - 1.5
            zc = slant_z((y0 + y1) / 2)
            keys += box(x0, x1, y0, y1, zc - 3, zc + 4)

    save_stl(os.path.join(outdir, "pc_case.stl"), case)
    save_stl(os.path.join(outdir, "pc_dark.stl"), dark)
    save_stl(os.path.join(outdir, "pc_keys.stl"), keys)
    save_stl(os.path.join(outdir, "pc_base.stl"), base)

    # ====================================================================
    # REAR PANEL  (a flat plate with the option-card cutouts + COM DB9)
    # ====================================================================
    rp = []
    rpd = []
    PW, PH = 500.0, 138.0
    rp += box(0, PW, 0, 4, 0, PH)
    # five option-card slot openings across the right two-thirds
    for i in range(5):
        sx = 150 + i * 64
        rpd += box(sx, sx + 40, -1, 5, 24, PH - 18)
    # power connectors / fan on the left
    rpd += box(20, 70, -1, 5, 30, 80)                 # power inlet
    rpd += box(84, 120, -1, 5, 30, 70)                # aux power
    # the DB9 male serial connector protruding from one card slot
    db = 150 + 3 * 64
    rp += box(db + 4, db + 36, -16, -1, 52, 84)        # connector shell
    for row, n, z in ((0, 5, 70), (1, 4, 62)):
        for j in range(n):
            rpd += box(db + 8 + j * 6, db + 11 + j * 6, -18, -15,
                       z, z + 3)                       # pins
    save_stl(os.path.join(outdir, "pc_rear.stl"), rp)
    save_stl(os.path.join(outdir, "pc_rear_dark.stl"), rpd)

    print("wrote PC parts to", outdir)


if __name__ == "__main__":
    main()
