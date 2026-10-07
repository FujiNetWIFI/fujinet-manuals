#!/usr/bin/env python3
"""A parametric Atari CX2600 console (the 1977 "heavy sixer") for line art.

Blocky on purpose: it is drawn through stl2png.py, which flattens it to the
three-tone, black-contour look of the 1977 Owner's Manual drawings.  The
model is in millimetres with

    x  across the console, 0..340, the player's RIGHT is +x
    y  front face at 0, the back at 235
    z  up

Order of the switches along the panel, as the 1977 manual's "TO START
PLAY" drawing shows them: POWER, TV TYPE, LEFT DIFFICULTY | the cartridge
slot | RIGHT DIFFICULTY, GAME SELECT, GAME RESET.  The rear carries the
power jack and the two controller jacks, LEFT CONTROLLER on the player's
left (as the 1977 "ASSEMBLE CONSOLE" rear view has them), and the TV cable.

Parts are written as build/stl/v_<name>.stl so the Makefile can pick a set
per view.  The FujiNet cartridge (build/stl/c_*.stl from make_cart_bits.py)
is turned to face the player and stood in the slot as v_cart_*.stl, and a
CX40-style joystick is plugged into LEFT CONTROLLER.

Run:  python3 tools/make_vcs.py build
"""
import glob
import json
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from stlkit import (bezier, box, cat, cyl, extrude, load_stl, rz,  # noqa
                    save_stl, sphere, tube, xform)

B = sys.argv[1] if len(sys.argv) > 1 else "build"
OUT = os.path.join(B, "stl")

W, D = 340.0, 235.0
Z0 = 4.0                     # body bottom (a plinth fills below)
FRONT_TOP = 34.0             # top of the front face
DECK0 = (8.0, 40.0)          # deck: front edge (y, z) ...
DECK1 = (138.0, 52.0)        # ... rising to the foot of the switch slope
SLOPE1 = (170.0, 88.0)       # top of the switch slope
TOPZ = 88.0
SIDE = 6.0                   # side margin for deck ribs and panel

parts = {}


def put(name, tris):
    parts[name] = cat(parts.get(name), tris)


# ---------- the body: one side profile extruded across ----------------
prof = [(0.0, Z0), (D, Z0), (D, TOPZ), SLOPE1, DECK1, DECK0,
        (1.5, FRONT_TOP + 2.0), (0.0, FRONT_TOP)]
put("v_body", extrude(prof, 0.0, W, axis="x"))
put("v_plinth", box(10, W - 10, 10, D - 10, 0.0, Z0 + 0.5))

# ---------- the wood fascia on the front face, with a little grain ----
put("v_wood", box(4, W - 4, -2.2, 0.01, 7.0, FRONT_TOP - 3.0))
for i, z in enumerate((10.5, 15.0, 19.0, 24.5, 27.5)):
    x0 = 12 + (i * 37) % 60
    put("v_grain", box(x0, W - 12 - (i * 23) % 50, -2.45, -2.15, z, z + 0.7))

# ---------- ribs across the deck, parallel to the front edge ----------
(y0, z0), (y1, z1) = DECK0, DECK1
slope = (z1 - z0) / (y1 - y0)
ang = np.arctan(slope)
n = np.array([-np.sin(ang), np.cos(ang)])      # deck normal in (y, z)
t = np.array([np.cos(ang), np.sin(ang)])
pitch, rw, rh = 9.4, 4.4, 2.4
k = 0
while True:
    s = 6.0 + k * pitch
    if s + rw > (y1 - y0) / np.cos(ang) - 5:
        break
    base = np.array([y0, z0]) + t * s
    q = [base, base + t * rw, base + t * rw + n * rh, base + n * rh]
    put("v_ribs", extrude([tuple(p) for p in q], SIDE + 4, W - SIDE - 4,
                          axis="x"))
    k += 1

# ---------- the switch panel on the slope -----------------------------
(sy0, sz0), (sy1, sz1) = DECK1, SLOPE1
sang = np.arctan2(sz1 - sz0, sy1 - sy0)
st = np.array([np.cos(sang), np.sin(sang)])
sn = np.array([-np.sin(sang), np.cos(sang)])
L = np.hypot(sy1 - sy0, sz1 - sz0)


def on_slope(s, h):
    p = np.array([sy0, sz0]) + st * s + sn * h
    return tuple(p)


def slab(s0, s1, h0, h1):
    return [on_slope(s0, h0), on_slope(s1, h0), on_slope(s1, h1),
            on_slope(s0, h1)]


put("v_trim", extrude(slab(3.0, L - 3.0, 0.0, 1.2), SIDE + 8, W - SIDE - 8,
                      axis="x"))
put("v_panel", extrude(slab(6.0, L - 6.0, 1.2, 2.2), SIDE + 12, W - SIDE - 12,
                       axis="x"))
SW_X = (36.0, 72.0, 108.0, 232.0, 268.0, 304.0)
SW_NAMES = ("power", "tvtype", "ldiff", "rdiff", "select", "reset")
for x, nm in zip(SW_X, SW_NAMES):
    put("v_swslot", extrude(slab(L / 2 - 13, L / 2 + 13, 2.2, 2.6),
                            x - 4.5, x + 4.5, axis="x"))
    up = 5.0 if nm in ("power", "tvtype", "ldiff", "rdiff") else 0.0
    lev = slab(L / 2 - 5 + up, L / 2 + 5 + up, 2.6, 14.0)
    put("v_lever", extrude(lev, x - 5.0, x + 5.0, axis="x"))
    put("v_levcap", extrude(slab(L / 2 - 5 + up, L / 2 + 5 + up, 14.0, 15.2),
                            x - 5.0, x + 5.0, axis="x"))

# ---------- the cartridge slot on the flat top ------------------------
SLOT_X, SLOT_Y0, SLOT_Y1 = W / 2, SLOPE1[0] + 6.0, SLOPE1[0] + 34.0
put("v_slotrim", box(SLOT_X - 50, SLOT_X + 50, SLOT_Y0 - 5, SLOT_Y1 + 5,
                     TOPZ, TOPZ + 1.6))
put("v_slot", box(SLOT_X - 45, SLOT_X + 45, SLOT_Y0, SLOT_Y1, TOPZ + 1.6,
                  TOPZ + 1.75))

# ---------- the rear: jacks, power, TV cable --------------------------
JACK = {"left": 100.0, "right": 146.0}
JZ = 36.0


def de9_socket(x):
    """A male DE-9 on the rear face (the console's jack): a D-shaped metal
    shell and a dark insulator."""
    shell = cat(box(x - 15.5, x + 15.5, D - 0.2, D + 1.0, JZ - 6.5, JZ + 6.5))
    d = []
    wt, wb, h = 9.4, 7.8, 4.6
    pts = [(-wt, h), (wt, h), (wb, -h), (-wb, -h)]
    d.append(extrude([(x + a, JZ + b) for a, b in pts], D + 1.0, D + 6.0,
                     axis="y"))
    ins = extrude([(x + a * 0.8, JZ + b * 0.75) for a, b in pts], D + 1.0,
                  D + 6.1, axis="y")
    return cat(shell, *d), ins


for side, x in JACK.items():
    s, i = de9_socket(x)
    put("v_jack_" + side, s)
    put("v_jackin_" + side, i)
put("v_power", cyl((60.0, D, JZ), (60.0, D + 4.0, JZ), 5.0))
put("v_powerin", cyl((60.0, D + 4.0, JZ), (60.0, D + 4.2, JZ), 2.4))
put("v_chan", box(250, 262, D, D + 3, JZ - 4, JZ + 4))
tvc = bezier((290, D, 30), (290, D + 40, 30), (300, D + 60, 10),
             (330, D + 90, 4), n=12)
put("v_tvcable", tube(tvc, 2.6))

# ---------- the cartridge, turned to face the player, in the slot -----
CART_DROP = 34.0                       # how far the cart sits in the slot
cart = {}
for f in sorted(glob.glob(os.path.join(OUT, "c_*.stl"))):
    name = os.path.basename(f)[2:-4]
    t_ = load_stl(f)
    # cart frame: label at y=0 facing +y, rear at -20.22, open end z=0.
    # Turn 180 deg about z (label now faces -y, the player), centre it.
    t_ = xform(t_, rz(180), (SLOT_X, (SLOT_Y0 + SLOT_Y1) / 2 - 10.11,
                             TOPZ - CART_DROP))
    save_stl(os.path.join(OUT, "v_cart_" + name + ".stl"), t_)
    cart[name] = t_

# ---------- CX40-style joysticks ------------------------------------
# Built at the origin with the cable leaving the TOP edge (+y, away from the
# player) and the fire button in the top-left corner, as on the CX40; then
# turned by `turn` degrees about z and moved to (x, y).
def joystick(prefix, x, y, turn, cable):
    j = {
        "base": cat(box(-36, 36, -36, 36, 0, 26), box(-33, 33, -33, 33, 26, 29)),
        "boot": cyl((0, 0, 29), (0, 0, 44), 17, r1=7),
        "shaft": cyl((0, 0, 44), (0, 0, 96), 4.2),
        "knob": cat(cyl((0, 0, 92), (0, 0, 100), 5.6),
                    sphere((0, 0, 100), 5.6, zmin=0)),
        "fire": cyl((-24, 24, 29), (-24, 24, 34), 7.5),
    }
    for k_, t_ in j.items():
        put(prefix + k_, xform(t_, rz(turn), (x, y, 0)))
    # the cable, in world coordinates, from the base's top edge
    exit_ = xform(np.array([[[0, 36, 14]] * 3]), rz(turn), (x, y, 0))[0, 0]
    put(prefix + "cable", tube([exit_] + [np.array(p) for p in cable], 2.4))


# J: plugged into LEFT CONTROLLER, lying behind the console (the rear view)
px = JACK["left"]
plug_y = D + 6.0
put("j_plug", cat(box(px - 17, px + 17, plug_y, plug_y + 18, JZ - 8, JZ + 8),
                  cyl((px, plug_y + 18, JZ), (px, plug_y + 30, JZ), 4.0,
                      r1=3.0)))
JX, JY = 20.0, D + 175.0
joystick("j_", JX, JY, 180 - 25, bezier(
    (JX + 15, JY - 50, 14), (JX + 40, JY - 90, 8),
    (px, plug_y + 90, JZ - 6), (px, plug_y + 29, JZ), n=16)[1:])
# K, M: the cover's pair, in front of the console at either side; their
# cables run back out of sight
for pre, (x, y, turn, side) in (("k_", (-75.0, 70.0, 12, 1)),
                                ("m_", (415.0, 70.0, -12, -1))):
    ex = x - side * 7.5
    joystick(pre, x, y, turn, bezier(
        (ex, y + 36, 14), (ex, y + 60, 2.4), (x + side * 40, y + 90, 2.4),
        (x + side * 70, y + 150, 2.4), n=12)[1:])

for k_, t_ in parts.items():
    save_stl(os.path.join(OUT, k_ + ".stl"), t_)
json.dump({"W": W, "D": D, "TOPZ": TOPZ, "slot": [SLOT_X, SLOT_Y0, SLOT_Y1],
           "switches": dict(zip(SW_NAMES, SW_X)), "jacks": JACK, "jz": JZ,
           "slope": [list(DECK1), list(SLOPE1)]},
          open(os.path.join(OUT, "vcs.json"), "w"), indent=1)
print("wrote", len(parts), "console parts and", len(cart), "cart parts to", OUT)
