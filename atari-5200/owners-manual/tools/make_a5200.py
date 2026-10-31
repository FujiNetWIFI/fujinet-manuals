#!/usr/bin/env python3
"""A parametric Atari CX5200 (the 1982 four-port console) and CX52
controller, for line art.

Blocky on purpose: it is drawn through stl2png.py, which flattens it to the
three-tone, black-contour look the book uses for all its hardware.  The
proportions follow the 1982 Owner's Manual's photographs and the published
size (15 x 13 x 4.25 in); the details a reader acts on are the ones drawn:
the cartridge slot, the silver band with the POWER switch and its red light
at the right, the four controller jacks numbered 1-4 on the front, and the
smoke-coloured controller-storage lid at the back.

Console frame, millimetres:
    x  across the console, 0..W, the player's RIGHT is +x
    y  front face at 0, the back at D
    z  up
The controller is built at its own origin, keypad toward the player (-y),
cord leaving the far end, and placed per view.  The FujiNet cartridge
(build/stl/c_*.stl from make_cart.py) stands in the slot with its label to
the player as v_cart_*.stl.

Parts are written as build/stl/<prefix><name>.stl.

Run:  python3 tools/make_a5200.py build
"""
import glob
import json
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from letters import ink_front, ink_top, text_img  # noqa: E402
from stlkit import (bezier, box, cat, cyl, extrude, load_stl, rz,  # noqa: E402
                    save_stl, sphere, tube, xform)

B = sys.argv[1] if len(sys.argv) > 1 else "build"
OUT = os.path.join(B, "stl")
parts = {}


def put(name, tris):
    parts[name] = cat(parts.get(name), tris)


# ======================================================================
# the console
# ======================================================================
W, D = 381.0, 330.0
Z0 = 3.0
# the side silhouette (y, z): front face, ribbed front slope, a black strip,
# the silver band, the slot deck, then the storage lid rising to the back
TOPLINE = [(0.0, 40.0), (42.0, 66.0), (54.0, 67.0), (110.0, 72.0),
           (186.0, 76.0), (D, 92.0)]
prof = [(0.0, Z0), (D, Z0)] + TOPLINE[::-1]
put("v_body", extrude(prof, 0.0, W, axis="x"))
put("v_plinth", box(12, W - 12, 12, D - 12, 0.0, Z0 + 0.5))


def zs(y):
    """the top surface's height at y"""
    for (y0, z0), (y1, z1) in zip(TOPLINE, TOPLINE[1:]):
        if y0 <= y <= y1:
            return z0 + (z1 - z0) * (y - y0) / (y1 - y0)
    return TOPLINE[-1][1]


def onsurf(y0, y1, x0, x1, h0, h1):
    """a slab lying on the top surface between y0 and y1, from h0 to h1
    above it, following its bends"""
    ys = [y0] + [p[0] for p in TOPLINE if y0 < p[0] < y1] + [y1]
    lower = [(y, zs(y) + h0) for y in ys]
    upper = [(y, zs(y) + h1) for y in ys[::-1]]
    return extrude(lower + upper, x0, x1, axis="x")


def slope_strip(t0, t1, x0, x1, h0, h1, a=TOPLINE[0], b=TOPLINE[1]):
    """a strip across the front slope, between fractions t0..t1 of it"""
    (ya, za), (yb, zb) = a, b
    n = np.array([-(zb - za), yb - ya])
    n /= np.linalg.norm(n)

    def P(t, h):
        return (ya + (yb - ya) * t + n[0] * h, za + (zb - za) * t + n[1] * h)
    return extrude([P(t0, h0), P(t1, h0), P(t1, h1), P(t0, h1)], x0, x1,
                   axis="x")


# the vents across the front slope
for i in range(9):
    t = 0.12 + i * 0.095
    put("v_ribs", slope_strip(t, t + 0.035, 16, W - 16, 0.05, 0.35))
# the silver band, edge to edge
put("v_trim", onsurf(56.0, 108.0, 3.0, W - 3.0, 0.05, 1.3))
# the POWER switch and its light at the band's right end
PWR_X = W - 34.0
put("v_power", onsurf(70.0, 92.0, PWR_X - 13, PWR_X + 13, 1.3, 3.2))
put("v_led", onsurf(96.0, 101.0, PWR_X - 3, PWR_X + 3, 1.3, 1.8))
# a dark plate where the console's own nameplate sits, at the band's left
put("v_logo", onsurf(76.0, 88.0, 22.0, 92.0, 1.3, 1.45))
# the cartridge slot, its rim, and the vents either side of it
SLOT_X = W / 2
SLOT_Y0, SLOT_Y1 = 132.0, 160.0
put("v_slotrim", onsurf(SLOT_Y0 - 5, SLOT_Y1 + 5, SLOT_X - 70, SLOT_X + 70,
                        0.05, 0.9))
put("v_slot", onsurf(SLOT_Y0, SLOT_Y1, SLOT_X - 64, SLOT_X + 64, 0.9, 1.0))
for side in (-1, 1):
    for i in range(16):
        gx = SLOT_X + side * (84 + i * 5.2)
        put("v_vents", onsurf(120.0, 176.0, gx - 0.7, gx + 0.7, 0.05, 0.3))
# the storage lid, smoke-coloured, behind a groove
put("v_vents", onsurf(188.0, 191.0, 10.0, W - 10.0, 0.05, 0.3))
put("v_lid", onsurf(194.0, D - 6.0, 10.0, W - 10.0, 0.05, 1.2))

# the four controller jacks on the front face, numbered 1-4 from the left
JZ = 19.0
JACK = {n: SLOT_X + (n - 2.5) * 62.0 for n in (1, 2, 3, 4)}
for n, x in JACK.items():
    put("v_jacks", box(x - 15, x + 15, -0.8, 0.2, JZ - 7, JZ + 7))
    put("v_jacknum", ink_front(text_img(str(n), "Helvetica-Bold.ttf", 120),
                               x, JZ + 13.5, 5.0, -0.5, 0.05))

CART_Z = 32.0   # the cartridge's z=0 (its connector's tip) in console z
cart = {}
for f in sorted(glob.glob(os.path.join(OUT, "c_*.stl"))):
    name = os.path.basename(f)[2:-4]
    if name.startswith("usb") or name == "sd_card":
        continue
    t_ = xform(load_stl(f), None, (SLOT_X, (SLOT_Y0 + SLOT_Y1) / 2 - 0.8,
                                   CART_Z))
    save_stl(os.path.join(OUT, "v_cart_" + name + ".stl"), t_)
    cart[name] = t_


# ======================================================================
# the controller
# ======================================================================
L, HW = 172.0, 36.0          # length; half-width
DECK = 22.0                  # the keypad deck's height
TOPZ = 34.0                  # the stick end's height
STICK = (0.0, 132.0)
# side silhouette (y, z): low keypad end, a slope, the high stick end
cprof = [(0.0, 0.0), (L, 0.0), (L, TOPZ - 4), (L - 6, TOPZ), (120.0, TOPZ),
         (98.0, DECK + 3), (0.0, DECK)]


def czs(y):
    pts = [(0.0, DECK), (98.0, DECK + 3), (120.0, TOPZ), (L - 6, TOPZ)]
    for (y0, z0), (y1, z1) in zip(pts, pts[1:]):
        if y0 <= y <= y1:
            return z0 + (z1 - z0) * (y - y0) / (y1 - y0)
    return TOPZ


KEYS = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], ["*", "0", "#"]]


def controller():
    c = {}
    c["body"] = extrude(cprof, -HW, HW, axis="x")
    deck = [(4.0, czs(4) + 0.02), (94.0, czs(94) + 0.02),
            (94.0, czs(94) + 0.6), (4.0, czs(4) + 0.6)]
    c["deck"] = extrude(deck, -HW + 4, HW - 4, axis="x")
    # the white stripe across the slope
    s0, s1 = 103.0, 110.0
    c["stripe"] = extrude([(s0, czs(s0) + 0.02), (s1, czs(s1) + 0.02),
                           (s1, czs(s1) + 0.7), (s0, czs(s0) + 0.7)],
                          -HW + 1, HW - 1, axis="x")
    keys, nums = [], []
    for r, row in enumerate(KEYS):
        ky = 82.0 - r * 21.0
        for k, ch in enumerate(row):
            kx = (k - 1) * 20.0
            top = czs(ky) + 3.4
            keys.append(box(kx - 8, kx + 8, ky - 7.5, ky + 7.5, czs(ky), top))
            img = text_img(ch, "Helvetica-Bold.ttf", 120)
            nums.append(ink_top(img, kx, ky, 7.5 if ch != "*" else 5.0,
                                top, top + 0.2))
    c["keys"] = cat(*keys)
    c["keynum"] = cat(*nums)
    # START, PAUSE, RESET across the far end
    t3, labs = [], {}
    for k, word in enumerate(("START", "PAUSE", "RESET")):
        bx = (k - 1) * 21.0
        t3.append(box(bx - 9.5, bx + 9.5, 152.0, 163.0, TOPZ, TOPZ + 2.2))
        labs["lab_" + word.lower()] = ink_top(
            text_img(word, "Helvetica-Bold.ttf", 120), bx, 157.5, 3.0,
            TOPZ + 2.2, TOPZ + 2.4)
    c["top3"] = cat(*t3)
    c.update(labs)
    # the stick: a well, a boot, a shaft and a fat knob
    sx, sy = STICK
    c["well"] = cyl((sx, sy, TOPZ - 0.6), (sx, sy, TOPZ + 0.8), 19.0, seg=48)
    c["shaft"] = cat(cyl((sx, sy, TOPZ + 0.8), (sx, sy, TOPZ + 8), 10.0,
                         r1=5.5, seg=32),
                     cyl((sx, sy, TOPZ + 8), (sx, sy, TOPZ + 26), 4.6, seg=24))
    c["knob"] = cat(cyl((sx, sy, TOPZ + 22), (sx, sy, TOPZ + 40), 8.6, seg=40),
                    sphere((sx, sy, TOPZ + 40), 8.6, zmin=0.0, seg=40))
    # two fire buttons on either side, one over the other
    fire = []
    for side in (-1, 1):
        x0, x1 = (HW, HW + 2.6) if side > 0 else (-HW - 2.6, -HW)
        fire.append(box(x0, x1, 126.0, 146.0, 6.0, 14.5))      # bottom
        fire.append(box(x0, x1, 126.0, 146.0, 17.5, 26.0))     # top
    c["fire"] = cat(*fire)
    return c


def place(pre, x, y, turn, cord=None, cordname="cord"):
    for k, t in controller().items():
        put(pre + k, xform(t, rz(turn), (x, y, 0.0)))
    exit_ = xform(np.array([[[0.0, L, 14.0]] * 3]), rz(turn), (x, y, 0))[0, 0]
    if cord is not None:
        put(pre + cordname, tube([exit_] + [np.array(p) for p in cord], 2.6))


# P: the controller alone (its own figures); a stub of cord
place("p_", 0.0, 0.0, 0.0, bezier((0, L, 14), (0, L + 30, 10),
                                  (10, L + 60, 6), (30, L + 80, 4), n=10)[1:],
      cordname="cordin")
# J1: plugged into jack 1, lying in front of the console, turned a little
px = JACK[1]
JX, JY = px - 40.0, -230.0
put("j1_plug", cat(box(px - 13, px + 13, -16, -0.8, JZ - 6, JZ + 6),
                   cyl((px, -16, JZ), (px, -26, JZ), 4.5, r1=3.4)))
place("j1_", JX, JY, 8.0, bezier((JX - 24, JY + L, 14), (JX - 30, JY + L + 40, 4),
                                 (px, -70, 3), (px, -26, JZ), n=16)[1:],
      cordname="cordin")
# K, M: the cover's pair, in front of the console at either side
for pre, (x, y, turn, side) in (("k_", (40.0, -150.0, 14, 1)),
                                ("m_", (W - 40.0, -150.0, -14, -1))):
    j = JACK[1] if side > 0 else JACK[2]
    ex = xform(np.array([[[0.0, L, 14.0]] * 3]), rz(turn), (x, y, 0))[0, 0]
    place(pre, x, y, turn, bezier(tuple(ex), (ex[0], ex[1] + 40, 4),
                                  (j, -60, 3), (j, -26, JZ), n=16)[1:])
    put(pre + "plug", cat(box(j - 13, j + 13, -16, -0.8, JZ - 6, JZ + 6),
                          cyl((j, -16, JZ), (j, -26, JZ), 4.5, r1=3.4)))

# points the figures label, in the console frame (controllers: p_ in their own)
cart_j = json.load(open(os.path.join(OUT, "cart.json")))
cm = {"v_" + k: [p[0] + SLOT_X, p[1] + (SLOT_Y0 + SLOT_Y1) / 2 - 0.8, p[2] + CART_Z]
      for k, p in cart_j["marks"].items()}
mk = dict(cm)
mk.update({
    "slot": [SLOT_X, SLOT_Y0, zs(SLOT_Y0)], "power": [PWR_X, 81.0, zs(81.0) + 3.2],
    "pled": [PWR_X, 98.5, zs(98.5) + 1.8], "trim": [W * 0.6, 82.0, zs(82.0) + 1.3],
    "lid": [W * 0.5, 262.0, zs(262.0) + 1.2], "vents": [W * 0.5, 20.0, 52.0],
    **{f"jack{n}": [x, -0.8, JZ] for n, x in JACK.items()},
    "p_keypad": [0.0, 51.0, czs(51) + 3.4], "p_k1": [-20.0, 82.0, czs(82) + 3.4],
    "p_hash": [20.0, 19.0, czs(19) + 3.4], "p_star": [-20.0, 19.0, czs(19) + 3.4],
    "p_start": [-21.0, 157.5, TOPZ + 2.4], "p_pause": [0.0, 157.5, TOPZ + 2.4],
    "p_reset": [21.0, 157.5, TOPZ + 2.4], "p_knob": [0.0, 132.0, TOPZ + 48.0],
    "p_fire_top": [HW + 2.6, 136.0, 21.75], "p_fire_bot": [HW + 2.6, 136.0, 10.25],
    "p_fire_top_l": [-HW - 2.6, 136.0, 21.75], "p_fire_bot_l": [-HW - 2.6, 136.0, 10.25],
    "p_overlay": [0.0, 2.0, czs(2)], "p_cord": [0.0, L, 14.0],
})

os.makedirs(OUT, exist_ok=True)
for k_, t_ in parts.items():
    save_stl(os.path.join(OUT, k_ + ".stl"), t_)
json.dump({"W": W, "D": D, "slot": [SLOT_X, SLOT_Y0, SLOT_Y1], "jacks": JACK,
           "jz": JZ, "power_x": PWR_X, "cart_z": CART_Z, "marks": mk},
          open(os.path.join(OUT, "a5200.json"), "w"), indent=1)
print("wrote", len(parts), "console/controller parts and", len(cart),
      "cart parts to", OUT)
