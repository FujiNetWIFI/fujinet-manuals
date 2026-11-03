#!/usr/bin/env python3
"""The FujiNet Arcadia 2001 cartridge, as the book draws it.

No shell has been designed for the Rev0 board yet (the board itself waits
on a real cartridge's measurements: its README's "Questions for fozztexx"),
so the book draws its own: a two-piece case 3 mm outside the board's body,
the 40 mm contact tab left bare below it, with every opening where the
hardware repo's anchor file puts the part behind it
(Emerson-Arcadia/FujiNet-Arcadia-Rev0/case/board-anchors.scad, generated
from the board's placement table): the RESET button and the three service
pinholes, the two lights, the USB-C socket in the top edge and the microSD
slot in the side. The board's parts face the television, so the buttons and
the lights are on the back; the label is on the front, toward the player.
The label is the book's own design.

The anchor file is uncommitted in the hardware repo, so it is read from the
working tree (README.md records its md5); nothing is written there:

    python3 tools/make_cart.py ~/Workspace/fujinet-hardware build

Cartridge frame, millimetres:
    x  across the label, the player's right is +x (100 - board x: the board
       drawings look at the parts face, from the television's side)
    z  up from the contact edge (130 - board y)
    y  the label face at -FT faces -y, the player; the board's label (solder)
       face is y = 0, its parts face y = PCB; the back shell's outside, with
       the buttons and lights, is y = PCB + BT
Parts go to build/stl/c_<name>.stl; build/stl/cart.json has the anchors.
"""
import json
import os
import re
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from letters import ink_front, text_img  # noqa: E402
from stlkit import box, cat, cyl, extrude, save_stl, tube  # noqa: E402

HW, B = sys.argv[1], sys.argv[2]
OUT = os.path.join(B, "stl")
os.makedirs(OUT, exist_ok=True)
SCAD = os.path.join(HW, "Emerson-Arcadia/FujiNet-Arcadia-Rev0/case/board-anchors.scad")
src = open(SCAD).read()
A = {}
for m in re.finditer(r"(\w+)\s*=\s*([^;]+);", re.sub(r"//[^\n]*", "", src)):
    A[m.group(1)] = json.loads(m.group(2).strip())

X0, Y0, X1B, Y1 = A["board"]          # 72, 50, 128, 130


def cx(x):
    return 100.0 - x


def cz(y):
    return Y1 - y


PCB = 1.6
FT = 4.0                         # front half (label side): nothing on that face
BT = 9.0                         # back half, over the parts (the S3 module, USB-C)
M = 3.0                          # the shell stands this far outside the board
TOP = cz(Y0) + M                 # top of the shell
BASE = cz(A["shoulder_y"])       # the shell stops where the contact tab begins
HW_ = (X1B - X0) / 2 + M         # body half-width
TABW = 20.0                      # the tab: 40 mm wide (edge_geom.py)
BY = PCB + BT                    # the back's outside face
R = 4.0                          # top corner radius


def rounded(xa, za, xb, zb, r, n=6):
    pts = [(xa, za), (xb, za)]
    for i in range(n + 1):
        a = np.pi / 2 * i / n
        pts.append((xb - r + r * np.cos(a), zb - r + r * np.sin(a)))
    for i in range(n + 1):
        a = np.pi / 2 + np.pi / 2 * i / n
        pts.append((xa + r + r * np.cos(a), zb - r + r * np.sin(a)))
    return pts


shell = rounded(-HW_, BASE, HW_, TOP, R)
parts = {}
parts["c_front"] = extrude(shell, -FT, 0.0, axis="y")
parts["c_rear"] = extrude(shell, PCB, BY, axis="y")
# a shallow grip, three ribs across the back near the top, as Emerson's
# cartridges have them
parts["c_ribs"] = cat(*[box(-HW_ + 6, HW_ - 6, BY, BY + 0.8, TOP - 9 - 3.2 * i,
                            TOP - 7.6 - 3.2 * i) for i in range(3)])

# the board, seen at the tab, and its gold contacts on both faces (2 x 15,
# 2.54 mm; odd pins on the parts face, toward the television)
tab = [(-TABW, BASE), (-TABW, 0.8), (-TABW + 0.8, 0.0), (TABW - 0.8, 0.0),
       (TABW, 0.8), (TABW, BASE)]
parts["c_pcb"] = extrude(tab, 0.0, PCB, axis="y")
fing = []
for i in range(15):
    fx = (i - 7) * 2.54
    fing.append(box(fx - 0.9, fx + 0.9, -0.05, 0.0, 0.5, 8.0))
    fing.append(box(fx - 0.9, fx + 0.9, PCB, PCB + 0.05, 0.5, 8.0))
parts["c_fingers"] = cat(*fing)

# ---- the back (the television's side): RESET, the pinholes, the lights ---
r = A["sw_reset"]
parts["c_button"] = cyl((cx(r[0]), BY - 0.1, cz(r[1])),
                        (cx(r[0]), BY + 1.6, cz(r[1])), 2.6, seg=24)
pins = []
for k in ("sw_bootsel", "sw_s3rst", "sw_s3boot"):
    p = A[k]
    pins.append(cyl((cx(p[0]), BY - 0.1, cz(p[1])),
                    (cx(p[0]), BY + 0.12, cz(p[1])), 0.95, seg=16))
parts["c_pinholes"] = cat(*pins)
for k, name in (("ws_led", "c_led_white"), ("rp_led", "c_led_red")):
    p = A[k]
    parts[name] = cyl((cx(p[0]), BY - 0.1, cz(p[1])),
                      (cx(p[0]), BY + 0.7, cz(p[1])), 1.5, seg=20)
parts["c_bezels"] = cat(*[cyl((cx(A[k][0]), BY - 0.1, cz(A[k][1])),
                              (cx(A[k][0]), BY + 0.3, cz(A[k][1])), 2.3, seg=20)
                          for k in ("ws_led", "rp_led")])

# ---- the front: the label --------------------------------------------------
# black, sunk 0.4 mm, FUJINET over the three bars, ARCADIA-2001 under them
lw, lh = 2 * HW_ - 10, (TOP - BASE) - 16
lx, lz = 0.0, BASE + 6 + lh / 2
fy = -FT
parts["c_label"] = box(lx - lw / 2, lx + lw / 2, fy - 0.15, fy + 0.4,
                       lz - lh / 2, lz + lh / 2)
ink = (fy - 0.3, fy - 0.1)
parts["c_label_word"] = ink_front(text_img("FUJINET", "Helvetica-Bold.ttf", 120),
                                  lx, lz + 11, 5.2, *ink)
bars = []
for i in range(3):                      # the /// -- three slanted bars
    x0 = lx - 9 + i * 6.4
    bars.append(extrude([(x0, lz - 4), (x0 + 3.6, lz - 4), (x0 + 6.8, lz + 5),
                         (x0 + 3.2, lz + 5)], *ink, axis="y"))
parts["c_label_bars"] = cat(*bars)
parts["c_label_num"] = ink_front(text_img("ARCADIA-2001", "HarryObese.otf", 120),
                                 lx, lz - 11, 4.0, *ink)

# ---- the top edge (USB-C) and the side (microSD) -------------------------
u = cx(A["usb_x"])
parts["c_ports"] = cat(
    box(u - 4.6, u + 4.6, PCB + 0.2, PCB + 3.4, TOP - 0.2, TOP + 0.05),   # USB-C
    box(HW_ - 0.2, HW_ + 0.05, PCB + 0.1, PCB + 1.7, cz(A["sd_y"]) - 6.2,
        cz(A["sd_y"]) + 6.2))                                            # card slot
# a USB-C plug and its cable, for the power picture
uy = PCB + 1.8
plug = cat(box(u - 5.5, u + 5.5, uy - 3.7, uy + 3.7, TOP + 0.05, TOP + 14),
           cyl((u, uy, TOP + 14), (u, uy, TOP + 22), 2.6, r1=2.0))
parts["c_usb_plug"] = plug
parts["c_usb_metal"] = box(u - 4.1, u + 4.1, uy - 1.5, uy + 1.5, TOP - 1.0, TOP + 0.05)
pts = [(u, uy, TOP + 22)]
for t in np.linspace(0, 1, 10)[1:]:
    pts.append((u - 18 * t ** 2, uy + 6 * t, TOP + 22 + 40 * t))
parts["c_usb_cable"] = tube(pts, 2.0)
# a microSD card, half in
sz = cz(A["sd_y"])
parts["c_sd_card"] = box(HW_ - 0.5, HW_ + 7.0, PCB + 0.5, PCB + 1.3, sz - 5.5, sz + 5.5)

for k, t in parts.items():
    save_stl(os.path.join(OUT, k + ".stl"), t)
anch = {k: [cx(A[k][0]), cz(A[k][1])] for k in
        ("sw_reset", "sw_bootsel", "sw_s3rst", "sw_s3boot", "ws_led", "rp_led", "ant")}
mk = {"reset": [anch["sw_reset"][0], BY + 1.6, anch["sw_reset"][1]],
      "bootsel": [anch["sw_bootsel"][0], BY, anch["sw_bootsel"][1]],
      "s3rst": [anch["sw_s3rst"][0], BY, anch["sw_s3rst"][1]],
      "s3boot": [anch["sw_s3boot"][0], BY, anch["sw_s3boot"][1]],
      "led_ws": [anch["ws_led"][0], BY + 0.7, anch["ws_led"][1]],
      "led_rp": [anch["rp_led"][0], BY + 0.7, anch["rp_led"][1]],
      "label": [lx, fy, lz], "label_top": [lx, fy, lz + lh / 2],
      "usb": [u, uy, TOP], "sd": [HW_, PCB + 0.9, sz], "plug": [u, uy, TOP + 8],
      "card": [HW_ + 4, PCB + 0.9, sz], "fingers": [0.0, -0.05, 4.0],
      "fingers_back": [0.0, PCB + 0.05, 4.0],
      "top": [0.0, 0.0, TOP], "side": [HW_, 0.0, TOP - 20], "ribs": [0.0, BY + 0.8, TOP - 12]}
json.dump({"FT": FT, "BT": BT, "PCB": PCB, "TOP": TOP, "BASE": BASE, "HW": HW_,
           "TABW": TABW, "anchors": anch, "marks": mk},
          open(os.path.join(OUT, "cart.json"), "w"), indent=1)
print("wrote", len(parts), "cart parts to", OUT)
