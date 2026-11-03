#!/usr/bin/env python3
"""make_arcadia -- a parametric Emerson Arcadia 2001 (ADV-1) as STL parts.

    python3 tools/make_arcadia.py build

Reads build/stl/cart.json and build/stl/c_*.stl (make_cart.py), writes
build/stl/<prefix>_<part>.stl and build/stl/arcadia.json ({"marks": ...}).

Console frame (world mm): x to the player's right, 0 at the centre; y away
from the player, 0 at the front face; z up, the floor at z = 0.
  v_       the console
  v_cart_  the cartridge standing in the slot (cart.json frame, moved)
  l_       the left hand controller lying in its well
  r_       the right controller lifted out, set down front-right, on its cord
  p_       one controller alone (own frame: x across, y from the disc end 0 to
           the cord end, z up from its base), keypad up, a stub of cord

Proportions: the service manual gives the main PCB (265 x 145 mm); the rest
is taken from the 1982 owner's-manual drawings (cover, p.3, p.5): the
console is about 1.6 times as wide as deep, two end wells each holding a
handset, a raised centre deck about a quarter of the width either side of
the middle, and a handset about 2.2 times as long as wide.
"""
import json
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from stlkit import (bezier, box, cat, cyl, extrude, load_stl, rx, rz,   # noqa
                    save_stl, xform)
from letters import ink_top, text_img                                    # noqa

OUT = os.path.join(sys.argv[1], "stl")

# ---- console dimensions ---------------------------------------------------
W, D = 380.0, 240.0           # overall width and depth
HALF = W / 2
DECKX = 96.0                  # the centre deck spans x = +-DECKX
ZF, RISE = 20.0, 26.0         # end-top height at the front, and the rise to the back
DECKUP = 14.0                 # the deck stands this much above the end tops
ANG = np.degrees(np.arctan2(RISE, D))
CA, SA = np.cos(np.radians(ANG)), np.sin(np.radians(ANG))
LD = D / CA                   # the top surfaces' length along the slope
TA = RISE / D
ZB = ZF + RISE                # end-top height at the back
ZDK = ZF + DECKUP             # deck origin height (front)

# ---- handset dimensions ---------------------------------------------------
CL, CW = 165.0, 76.0          # length, width
CH = 12.0                     # body height; the bevelled top adds 2
KTOP = CH + 2.0               # the keypad plane
WELLX = 143.0                 # well centres at +-WELLX
WELL_Y0 = 20.0                # the handset's bottom end, along the end-top slope

parts = {}
marks = {}


def put(name, t):
    if t is not None and len(t):
        parts[name] = np.asarray(t, dtype=np.float64).reshape(-1, 3, 3)


def loc(t, z0):
    """A model drawn in a surface frame (y along the slope, z normal)."""
    return xform(t, rx(ANG), (0, 0, z0))


def P(x, yl, zl, z0):
    q = rx(ANG) @ np.array([x, yl, zl], dtype=float)
    return [round(float(q[0]), 2), round(float(q[1]), 2),
            round(float(q[2] + z0), 2)]


def rr(cx, cy, w, h, r, n=6):
    """Rounded-rectangle outline (list of (x, y))."""
    pts = []
    for (sx, sy, a0) in ((1, 1, 0), (-1, 1, 90), (-1, -1, 180), (1, -1, 270)):
        for k in range(n + 1):
            a = np.radians(a0 + 90.0 * k / n)
            pts.append((cx + sx * (w / 2 - r) + r * np.cos(a),
                        cy + sy * (h / 2 - r) + r * np.sin(a)))
    return pts


def ellipse(cx, cy, rxx, ryy, n=20):
    return [(cx + rxx * np.cos(2 * np.pi * i / n),
             cy + ryy * np.sin(2 * np.pi * i / n)) for i in range(n)]


def coil(path, rtube=1.9, rad=4.8, pitch=7.5, seg=6):
    """A coiled cord: a helix wound around the polyline `path`."""
    pts = [np.array(p, float) for p in path]
    # resample at ds
    ds = pitch / 9.0
    res, acc = [pts[0]], 0.0
    for a, b in zip(pts[:-1], pts[1:]):
        seglen = np.linalg.norm(b - a)
        if seglen == 0:
            continue
        pos = acc
        while pos < seglen:
            res.append(a + (b - a) * pos / seglen)
            pos += ds
        acc = pos - seglen
    if np.linalg.norm(res[-1] - pts[-1]) > 1e-6:
        res.append(pts[-1])
    res = [p for i, p in enumerate(res)
           if i == 0 or np.linalg.norm(p - res[i - 1]) > 1e-6]
    out, s = [], 0.0
    for i, p in enumerate(res):
        t = res[min(i + 1, len(res) - 1)] - res[max(i - 1, 0)]
        t = t / (np.linalg.norm(t) or 1)
        ref = np.array([0, 0, 1.0]) if abs(t[2]) < 0.9 else np.array([1.0, 0, 0])
        u = np.cross(t, ref); u /= np.linalg.norm(u)
        v = np.cross(t, u)
        ph = 2 * np.pi * s / pitch
        out.append(p + rad * (np.cos(ph) * u + np.sin(ph) * v))
        if i + 1 < len(res):
            s += np.linalg.norm(res[i + 1] - p)
    return cat(*[cyl(out[i], out[i + 1], rtube, seg=seg)
                 for i in range(len(out) - 1)])


# ===========================================================================
# the hand controller (own frame)
# ===========================================================================
KEYS = [("1", 0), ("2", 0), ("3", 0), ("4", 1), ("5", 1), ("6", 1),
        ("7", 2), ("8", 2), ("9", 2), ("CL", 3), ("0", 3), ("EN", 3)]
KX, KPITCH_X, KPITCH_Y = 22.0, 22.0, 17.5
KROW0 = CL - 25.0             # y of the top row
DISC_Y = 42.0


def key_xy(i):
    s, row = KEYS[i]
    col = i % 3
    return (col - 1) * KPITCH_X, KROW0 - row * KPITCH_Y


def controller():
    c = {}
    c["body"] = extrude(rr(0, CL / 2, CW, CL, 9), 0, CH, "z")
    c["bevel"] = extrude(rr(0, CL / 2, CW - 6, CL - 6, 7), CH, KTOP, "z")
    # keypad panel, one step darker
    c["keypad"] = extrude(rr(0, KROW0 - 1.5 * KPITCH_Y, 2 * KPITCH_X + 25,
                             4 * KPITCH_Y + 4, 5), KTOP, KTOP + 0.5, "z")
    keys, lab = [], []
    for i, (s, row) in enumerate(KEYS):
        x, y = key_xy(i)
        keys.append(extrude(ellipse(x, y, 8.6, 6.2), KTOP + 0.5, KTOP + 2.6, "z"))
        im = text_img(s, "Helvetica-Bold.ttf", 64)
        h = 4.6
        # keep glyph widths in proportion when the text is wider than a key
        if im.width * h / im.height > 11:
            h = 11 * im.height / im.width
        lab.append(ink_top(im, x, y, h, KTOP + 2.6, KTOP + 2.9))
    c["keys"] = cat(*keys)
    c["keylabels"] = cat(*lab)
    # the control disc in its dished well
    c["disc_well"] = cyl((0, DISC_Y, KTOP), (0, DISC_Y, KTOP + 0.6), 29.5, seg=48)
    c["disc"] = cyl((0, DISC_Y, KTOP + 0.6), (0, DISC_Y, KTOP + 3.0), 25.0,
                    seg=48)
    c["disc_dot"] = cyl((0, DISC_Y, KTOP + 3.0), (0, DISC_Y, KTOP + 3.25), 5.5,
                        seg=24)
    # one Action button on each long side
    ay0, ay1 = CL - 62.0, CL - 38.0
    c["action"] = cat(box(CW / 2 - 1.0, CW / 2 + 3.2, ay0, ay1, 2.5, CH - 1.5),
                      box(-CW / 2 - 3.2, -CW / 2 + 1.0, ay0, ay1, 2.5, CH - 1.5))
    return c


def cord_stub():
    path = bezier((0, CL, 7), (0, CL + 22, 7), (6, CL + 34, 9),
                  (14, CL + 56, 12), n=14)
    return coil(path)


# ===========================================================================
# the console
# ===========================================================================
def wedge(x0, x1, top_f, top_b):
    prof = [(0, 0), (D, 0), (D, top_b), (0, top_f)]
    return extrude(prof, x0, x1, "x")


body = [wedge(-HALF, -DECKX, ZF, ZB), wedge(DECKX, HALF, ZF, ZB),
        wedge(-DECKX, DECKX, ZF + DECKUP, ZB + DECKUP)]
put("v_body", cat(*body))

# ---- deck (local frame: y along the slope, z = 0 at the deck surface) -----
DZ = 0.8                                   # the inset panel's thickness
dk = {}
dk["deck"] = box(-DECKX + 6, DECKX - 6, 5.0, LD - 6.0, 0.0, DZ)
# speaker grille: a row of slots across the front of the deck
g = []
GY0 = 10.0
for i in range(8):
    y = GY0 + i * 5.2
    g.append(box(-84, 84, y, y + 2.2, DZ, DZ + 0.3))
dk["grille"] = cat(*g)
# the nameplate: ARCADIA-2001 and the three slanted bars
nm = text_img("ARCADIA-2001", "HarryObese.otf", 90)
NM_Y, NM_H = 114.0, 8.0
nmw = nm.width * NM_H / nm.height
NM_X = -62.0 + nmw / 2
dk["nameplate"] = cat(ink_top(nm, NM_X, NM_Y, NM_H, DZ, DZ + 0.3),
                      *[extrude([(-90 + i * 6.0 + dx, NM_Y - 6.5 + dy)
                                 for dx, dy in ((0, 0), (4.5, 0), (7.5, 13),
                                                (3, 13))], DZ, DZ + 0.3, "z")
                        for i in range(3)])
# the round buttons RESET SELECT OPTION START, and the wider POWER switch
BTN_Y = 68.0
BTN_X = {"reset": -82.0, "select": -54.0, "option": -26.0, "start": 2.0}
PW_X0, PW_X1 = 30.0, 86.0
dk["buttons"] = cat(*[extrude(ellipse(x, BTN_Y, 10.0, 10.0, 28), DZ, DZ + 3.2, "z")
                      for x in BTN_X.values()])
dk["power"] = extrude(rr((PW_X0 + PW_X1) / 2, BTN_Y, PW_X1 - PW_X0, 20, 3),
                      DZ, DZ + 3.6, "z")
leg = []
for name, x in list(BTN_X.items()) + [("power", (PW_X0 + PW_X1) / 2)]:
    leg.append(ink_top(text_img(name.upper(), "Helvetica.ttf", 50), x, 88.0, 3.0,
                       DZ, DZ + 0.25))
dk["legends"] = cat(*leg)
LED_X, LED_Y = (PW_X0 + PW_X1) / 2, 101.0
dk["led"] = cyl((LED_X, LED_Y, DZ), (LED_X, LED_Y, DZ + 2.2), 3.4, seg=24)
# the cartridge slot: a raised frame and a dark opening
SL_X, SL_Y0, SL_Y1, FR = 62.0, 156.0, 190.0, 5.0
fr = [box(-SL_X, SL_X, SL_Y0, SL_Y0 + 5, DZ, FR),
      box(-SL_X, SL_X, SL_Y1 - 5, SL_Y1, DZ, FR),
      box(-SL_X, -SL_X + 6, SL_Y0 + 5, SL_Y1 - 5, DZ, FR),
      box(SL_X - 6, SL_X, SL_Y0 + 5, SL_Y1 - 5, DZ, FR)]
dk["slotframe"] = cat(*fr)
dk["slot"] = box(-SL_X + 6, SL_X - 6, SL_Y0 + 5, SL_Y1 - 5, DZ, DZ + 0.6)
for k, t in dk.items():
    put("v_" + k, loc(t, ZDK))

# ---- the end wells (local frame on the end-top slope) ----------------------
WX0, WX1 = 100.0, 188.0
rims, floors = [], []
for sg in (-1, 1):
    a, b = sorted((sg * WX0, sg * WX1))
    rims += [box(a, a + 3, 12, 198, 0, 5.5), box(b - 3, b, 12, 198, 0, 5.5),
             box(a + 3, b - 3, 195, 198, 0, 5.5), box(a + 3, b - 3, 12, 15, 0, 3.0)]
    floors.append(box(a + 3, b - 3, 15, 195, 0, 0.4))
put("v_rims", loc(cat(*rims), ZF))
put("v_wells", loc(cat(*floors), ZF))

# ---- the rear face (y = D) -----------------------------------------------
BK = D
JACKX = {"jack_l": -34.0, "jack_r": -4.0}
jk = [box(x - 9, x + 9, BK, BK + 0.5, 22, 34) for x in JACKX.values()]
dc_x, ch_x, out_x = 78.0, 40.0, -86.0
jk.append(cyl((dc_x, BK, 28), (dc_x, BK + 0.5, 28), 6.0, seg=24))
jk.append(box(ch_x - 14, ch_x + 14, BK, BK + 0.5, 27, 33))
put("v_jacks", cat(*jk))
put("v_chan", box(ch_x - 8, ch_x - 2, BK, BK + 2.0, 25.5, 34.5))
put("v_dcpin", cyl((dc_x, BK + 0.5, 28), (dc_x, BK + 1.0, 28), 1.6, seg=12))
# the two coil cords go into grommets at the rear corners
put("v_grommets", cat(*[cyl((sg * WELLX, BK, 33), (sg * WELLX, BK + 3, 33), 5.5,
                            seg=20) for sg in (-1, 1)]))
# output cable with its pin plug, looping out across the floor
oc = bezier((out_x, BK + 3, 30), (out_x, BK + 60, 30), (out_x + 10, BK + 100, 2.4),
            (out_x + 50, BK + 130, 2.4), n=18)
oc += bezier((out_x + 50, BK + 130, 2.4), (out_x + 85, BK + 150, 2.4),
             (out_x + 120, BK + 140, 2.4), (out_x + 150, BK + 170, 2.4), n=18)[1:]
put("v_out_cable", cat(cyl((out_x, BK, 30), (out_x, BK + 6, 30), 5.0, seg=16),
                       *[cyl(oc[i], oc[i + 1], 2.4, seg=8)
                         for i in range(len(oc) - 1)]))
e0 = np.array(oc[-1]); e1 = e0 + np.array([22.0, 18.0, 0])
e1 = e0 + (e1 - e0) / np.linalg.norm(e1 - e0) * 22
put("v_out_plug", cat(cyl(e0, e0 + (e1 - e0) * 0.6, 4.0, seg=14),
                      cyl(e0 + (e1 - e0) * 0.6, e1, 1.6, seg=10)))

# ---- console marks -----------------------------------------------------------
ZT = DZ + 3.2
marks.update({
    "power": P((PW_X0 + PW_X1) / 2, BTN_Y, DZ + 3.6, ZDK),
    "led": P(LED_X, LED_Y, DZ + 2.2, ZDK),
    "reset": P(BTN_X["reset"], BTN_Y, ZT, ZDK),
    "select": P(BTN_X["select"], BTN_Y, ZT, ZDK),
    "option": P(BTN_X["option"], BTN_Y, ZT, ZDK),
    "start": P(BTN_X["start"], BTN_Y, ZT, ZDK),
    "slot": P(-44.0, 173.0, DZ + 0.6, ZDK),
    "grille": P(-40.0, GY0 + 2 * 5.2 + 1.1, DZ + 0.3, ZDK),
    "nameplate": P(NM_X + nmw * 0.25, NM_Y, DZ + 0.3, ZDK),
    "jack_l": [JACKX["jack_l"], BK + 0.5, 28.0],
    "jack_r": [JACKX["jack_r"], BK + 0.5, 28.0],
    "dc_jack": [dc_x, BK + 0.5, 28.0],
    "chan_sw": [ch_x + 6, BK + 0.5, 30.0],
    "out_cable": [out_x, BK + 6, 35.0],
    "well_l": P(-WELLX, 13.5, 3.0, ZF),
    "well_r": P(WELLX, 13.5, 3.0, ZF),
})

# ---- the cartridge in the slot ---------------------------------------------
cj = json.load(open(os.path.join(OUT, "cart.json")))
CART_Y = 170.0                              # cart y = 0 in the console frame
CART_Z = ZDK + (CART_Y - 5) * TA + DZ + 0.6 - cj["BASE"] - 0.2
cart_move = (0.0, CART_Y, CART_Z)
for f in sorted(os.listdir(OUT)):
    if f.startswith("c_") and f.endswith(".stl"):
        n = f[2:-4]
        if n.startswith("usb") or n == "sd_card":
            continue
        put("v_cart_" + n, xform(load_stl(os.path.join(OUT, f)), None, cart_move))
marks["cart_label_top"] = [round(v + m, 2) for v, m in
                           zip(cj["marks"]["label_top"], cart_move)]

# ===========================================================================
# the handsets
# ===========================================================================
CTL = controller()
KEYMARK = {}
for i, (s, row) in enumerate(KEYS):
    x, y = key_xy(i)
    nm_ = {"CL": "clr", "EN": "ent"}.get(s, "k" + s)
    KEYMARK[nm_] = [round(x, 2), round(y, 2), KTOP + 2.6]


def place(pre, move, cordpath=None, stub=False):
    for k, t in CTL.items():
        put(pre + k, move(t))
    if stub:
        put(pre + "cord", move(cord_stub()))
    elif cordpath is not None:
        put(pre + "cord", coil(cordpath))


# p_: alone
place("p_", lambda t: t, stub=True)
pm = {"p_" + k: v for k, v in KEYMARK.items()}
pm.update({"p_keypad": [0.0, KROW0 - 1.5 * KPITCH_Y - 7 - 2.5, KTOP + 0.5],
           "p_disc": [0.0, DISC_Y, KTOP + 3.0],
           "p_action_l": [-CW / 2 - 3.2, CL - 50.0, CH / 2],
           "p_action_r": [CW / 2 + 3.2, CL - 50.0, CH / 2],
           "p_cord": [14.0, CL + 56.0, 12.0]})
# keypad mark: on the panel's rim between the keys, not on a key
pm["p_keypad"] = [0.0, KROW0 + 0.5 * KPITCH_Y + 0.0, KTOP + 0.5]
marks.update(pm)

# l_: docked in the left well
LX = -WELLX
placeL = lambda t: loc(xform(t, None, (LX, WELL_Y0, 0.4)), ZF)       # noqa
topL = np.array(P(LX, WELL_Y0 + CL, 7.4, ZF))
cordL = bezier(tuple(topL), (LX, 218.0, ZB + 10), (LX, BK + 16, ZB - 2),
               (LX, BK + 2, 33.0), n=24)
place("l_", placeL, cordpath=cordL)

# r_: lifted out, set down front-right of the console, on its cord
TURN = -8.0
RX, RY = 240.0, -80.0
placeR = lambda t: xform(t, rz(TURN), (RX, RY, 0.0))                  # noqa
topR = rz(TURN) @ np.array([0, CL, 7.0]) + np.array([RX, RY, 0.0])
cordR = bezier(tuple(topR), (topR[0] + 14, topR[1] + 70, 6.0),
               (215.0, BK + 70, 26.0), (WELLX, BK + 2, 33.0), n=36)
place("r_", placeR, cordpath=cordR)

# ---- write -----------------------------------------------------------------
os.makedirs(OUT, exist_ok=True)
for f in os.listdir(OUT):
    if f[:2] in ("v_", "l_", "r_", "p_"):
        os.remove(os.path.join(OUT, f))
for k, t in parts.items():
    save_stl(os.path.join(OUT, k + ".stl"), t)
json.dump({"W": W, "D": D, "marks": marks}, open(os.path.join(OUT, "arcadia.json"),
                                                 "w"), indent=1)
print("wrote", len(parts), "console/controller parts")
