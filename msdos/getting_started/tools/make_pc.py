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

    # two full-height 5.25" diskette drives side by side on the right
    # (GTO 2-8 "Component Arrangement"): a recessed opening holding two
    # black drive faces, each with a horizontal slot and a centred
    # vertical load lever
    da_x0, da_x1 = 190.0, SU_W - 22.0
    da_z0, da_z1 = 16.0, SU_H - 16.0
    dark += box(da_x0, da_x1, -3.0, 1.0, da_z0, da_z1)   # recessed opening
    bay_gap = 8.0
    bay_w = (da_x1 - da_x0 - 3 * bay_gap) / 2
    for i in range(2):
        bx0 = da_x0 + bay_gap + i * (bay_w + bay_gap)
        bx1 = bx0 + bay_w
        zm = (da_z0 + da_z1) / 2
        dark += box(bx0, bx1, -6.0, -2.0, da_z0 + 4, da_z1 - 4)  # drive face
        # horizontal diskette slot across the face
        dark += box(bx0 + 14, bx1 - 14, -8.5, -6.0, zm - 5, zm + 5)
        # vertical load lever over the slot centre
        cx = (bx0 + bx1) / 2
        case += box(cx - 8, cx + 8, -10.0, -5.0, zm - 20, zm + 20)

    # IBM badge, top-left front
    base += box(30, 92, -4.0, -1.0, SU_H - 42, SU_H - 22)

    # small vent grille, lower-left front (thin vertical slits)
    for i in range(10):
        vx = 34 + i * 9
        dark += box(vx, vx + 4, -2.5, 1.0, 20, 52)

    # ====================================================================
    # DISPLAY  (monochrome monitor, sits on top toward the back)
    # ====================================================================
    # IBM Monochrome Display (GTO 2-8): boxy body on a shallow inset
    # plinth, screen offset left, control column on the right of the
    # bezel with the IBM badge up top and two knobs below
    MON_W, MON_D, MON_H = 380.0, 330.0 , 290.0
    mon_x = (SU_W - MON_W) / 2 + 10
    mon_y = 25.0                          # set back a little
    mon_z0 = SU_H                         # sits on the system unit
    # shallow inset plinth
    base += box(mon_x + 16, mon_x + MON_W - 16, mon_y + 16, mon_y + MON_D - 16,
                mon_z0, mon_z0 + 16)
    mz = mon_z0 + 16
    # monitor body
    case += box(mon_x, mon_x + MON_W, mon_y, mon_y + MON_D, mz, mz + MON_H)
    # face bezel inset
    fb = 20.0
    case += box(mon_x + fb, mon_x + MON_W - fb, mon_y - 3.0, mon_y,
                mz + fb, mz + MON_H - fb)
    # the screen (dark), offset left of the control column
    dark += box(mon_x + 36, mon_x + MON_W - 88, mon_y - 4.5, mon_y + 6.0,
                mz + 42, mz + MON_H - 34)
    # control column, right of the screen: IBM badge on top,
    # two knobs (contrast / brightness) stacked below
    kx = mon_x + MON_W - 52
    base += box(kx - 16, kx + 16, mon_y - 4.0, mon_y - 1.0,
                mz + MON_H - 62, mz + MON_H - 40)
    for kz in (mz + 132, mz + 96):
        base += cyl(kx, kz, mon_y - 14.0, mon_y + 2.0, 10.0)

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
    # REAR PANEL  (viewed from the rear; layout follows the IBM 5150
    # Guide to Operations "Rear Panel Reference", Setup 2-7: power
    # supply fan and power connectors at left, RF-modulator cable
    # opening and round knockout top-centre, keyboard/cassette DIN
    # sockets bottom-centre, five option-card slots at right)
    # ====================================================================
    rp = []
    rpd = []
    PW, PH = 500.0, 138.0
    rp += box(0, PW, 0, 4, 0, PH)

    # panel screws along the top and bottom edges
    for sx, sz in ((16, 128), (128, 128), (245, 128), (330, 128),
                   (16, 10), (245, 10)):
        rpd += cyl(sx, sz, -0.8, 2, 2.8, seg=14)

    # power supply fan: round dark grille with horizontal louvers
    fcx, fcz, fr = 195.0, 76.0, 34.0
    rpd += cyl(fcx, fcz, -0.8, 5, fr, seg=40)
    zl = fcz - 28.0
    while zl < fcz + 28.0:
        hw = np.sqrt(max(fr * fr - (zl - fcz) ** 2,
                         fr * fr - (zl + 3.5 - fcz) ** 2)) - 1.5
        rp += box(fcx - hw, fcx + hw, -1.4, -0.6, zl, zl + 3.5)
        zl += 8.0

    # recessed well, lower left, holding the two power connectors
    # (video power outlet for the display + system power inlet)
    rpd += box(48, 170, -0.8, 5, 16, 58)
    for px in (58.0, 116.0):
        rp += box(px, px + 44, -1.6, -0.8, 22, 52)      # connector body
        for j in range(3):
            rpd += box(px + 8 + j * 11, px + 14 + j * 11, -2.2, -1.4,
                       33, 40)                          # the three pins

    # cable opening for the RF modulator (stadium-shaped knockout)
    rpd += box(258, 292, -0.8, 5, 106, 120)
    rpd += cyl(258, 113, -0.8, 5, 7, seg=18)
    rpd += cyl(292, 113, -0.8, 5, 7, seg=18)

    # round cable knockout, centre
    rpd += cyl(315, 74, -0.8, 5, 11, seg=24)

    # keyboard and cassette DIN sockets, bottom centre
    for dx in (288.0, 322.0):
        rpd += cyl(dx, 33, -1.2, 5, 13.5, seg=24)       # socket ring
        rp += cyl(dx, 33, -1.8, -0.6, 10.0, seg=24)     # inner face
        rpd += cyl(dx, 33, -2.4, -1.4, 3.0, seg=12)     # centre key

    # option-card cage at right: opening with five vertical slot
    # brackets; two carry D-connectors (long axis vertical, as the
    # cards mount them) — the 9-pin serial COM port and a 25-pin
    rpd += box(342, 495, -1, 5, 14, 124)
    br_w, br_gap = 24.0, 6.0
    for i in range(5):
        bx0 = 347 + i * (br_w + br_gap)
        rp += box(bx0, bx0 + br_w, -2, -1, 16, 122)     # slot cover/bracket
    # 9-pin D serial (COM) connector on the third bracket
    cx = 347 + 2 * (br_w + br_gap) + br_w / 2
    rp += box(cx - 6.5, cx + 6.5, -3.5, -2, 53, 85)     # flange
    rpd += box(cx - 4.5, cx + 4.5, -4.3, -3.0, 58, 80)  # D mouth
    # 25-pin D (printer) connector on the rightmost bracket
    cx = 347 + 4 * (br_w + br_gap) + br_w / 2
    rp += box(cx - 6.5, cx + 6.5, -3.5, -2, 40, 104)    # flange
    rpd += box(cx - 4.5, cx + 4.5, -4.3, -3.0, 46, 98)  # D mouth

    save_stl(os.path.join(outdir, "pc_rear.stl"), rp)
    save_stl(os.path.join(outdir, "pc_rear_dark.stl"), rpd)

    print("wrote PC parts to", outdir)


if __name__ == "__main__":
    main()
