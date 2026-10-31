#!/usr/bin/env python3
"""The FujiNet 5200 cartridge, as the book draws it.

No shell has been designed for the Rev0 board yet, so the book draws its own:
a two-piece case that follows the board's T-shaped outline 3 mm out, with
every hole where the hardware repo's anchor file puts the thing behind it
(ATARI-5200/FujiNet-5200-Rev0/case/board-anchors.scad, generated from the
board's placement table): the RESET button and three service pinholes, the
two lights, the 30 x 20 mm label recess, and the USB-C socket and microSD
slot in the top edge.  The label is the book's own design.

The anchor file is read with `git show`, never written:

    python3 tools/make_cart.py ~/Workspace/fujinet-hardware origin/master build

Cartridge frame, millimetres:
    x  across the label, the player's right is +x (board x - 100)
    z  up from the edge connector's tip (150 - board y)
    y  the label face at -FT faces -y, the player; the board's copper top
       (where the buttons and lights are) is at y = 0
Parts go to build/stl/c_<name>.stl; build/stl/cart.json has the anchors.
"""
import json
import os
import re
import subprocess
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from letters import ink_front, text_img  # noqa: E402
from stlkit import box, cat, cyl, extrude, save_stl, tube  # noqa: E402

HW, REV, B = sys.argv[1], sys.argv[2], sys.argv[3]
OUT = os.path.join(B, "stl")
os.makedirs(OUT, exist_ok=True)
SCAD = "ATARI-5200/FujiNet-5200-Rev0/case/board-anchors.scad"
src = subprocess.run(["git", "-C", HW, "show", f"{REV}:{SCAD}"], check=True,
                     capture_output=True, text=True).stdout
A = {}
for m in re.finditer(r"(\w+)\s*=\s*([^;]+);", re.sub(r"//[^\n]*", "", src)):
    A[m.group(1)] = json.loads(m.group(2).strip())


def cx(x):
    return x - 100.0


def cz(y):
    return A["pcb_y1"] - y


FT = 7.0                       # front half (label side) thickness
BT = 9.0                       # back half
PCB = A["pcb_t"]
M = 3.0                        # the shell stands this far outside the board
TOP = cz(A["pcb_y0"]) + M      # top of the shell
BASE = cz(A["pcb_tab_y"])      # the shell stops where the tab begins
X1 = cx(A["pcb_x1"]) + M       # body half-width
outline = [(xx, zz) for xx, zz in ((cx(x), cz(y)) for x, y in A["pcb_outline"])]
# the board's own outline, for the tab and the look-inside
waist = cx(A["pcb_outline"][4][0]) + M      # the narrow lower part's half-width
shoulder = cz(A["pcb_outline"][3][1]) + 1.2  # where the body steps in
shoulder2 = cz(A["pcb_outline"][4][1]) + 1.2
shell = [(-X1, TOP - 3), (-X1 + 3, TOP), (X1 - 3, TOP), (X1, TOP - 3),
         (X1, shoulder), (waist, shoulder2), (waist, BASE),
         (-waist, BASE), (-waist, shoulder2), (-X1, shoulder)]
parts = {}
parts["c_front"] = extrude(shell, -FT, 0.0, axis="y")
parts["c_rear"] = extrude(shell, PCB, PCB + BT, axis="y")

# the board, seen only at the tab, and its gold fingers on both faces
tab = [(-23.9, BASE), (-23.9, 0.8), (-23.1, 0.0), (23.1, 0.0), (23.9, 0.8),
       (23.9, BASE)]
parts["c_pcb"] = extrude(tab, 0.0, PCB, axis="y")
fing = []
pitch = 2.54
for i in range(18):
    fx = (i - 8.5) * pitch
    fing.append(box(fx - 0.85, fx + 0.85, -0.05, 0.0, 0.6, 7.6))
    fing.append(box(fx - 0.85, fx + 0.85, PCB, PCB + 0.05, 0.6, 7.6))
parts["c_fingers"] = cat(*fing)

# ---- the face: the RESET button, the pinholes, the lights, the label ----
fy = -FT
r = A["sw_reset"]
parts["c_button"] = cat(cyl((cx(r[0]), fy + 0.1, cz(r[1])),
                            (cx(r[0]), fy - 1.6, cz(r[1])), 2.6, seg=24))
pins = []
for k in ("sw_bootsel", "sw_s3_en", "sw_s3_boot"):
    p = A[k]
    pins.append(cyl((cx(p[0]), fy + 0.1, cz(p[1])),
                    (cx(p[0]), fy - 0.12, cz(p[1])), 0.95, seg=16))
parts["c_pinholes"] = cat(*pins)
for k, name in (("led_ws", "c_led_white"), ("led_rp", "c_led_red")):
    p = A[k]
    parts[name] = cyl((cx(p[0]), fy + 0.1, cz(p[1])),
                      (cx(p[0]), fy - 0.7, cz(p[1])), 1.5, seg=20)
# a ring round each light so it reads even when lit white
parts["c_bezels"] = cat(*[cyl((cx(A[k][0]), fy + 0.1, cz(A[k][1])),
                              (cx(A[k][0]), fy - 0.3, cz(A[k][1])), 2.3, seg=20)
                          for k in ("led_ws", "led_rp")])

# the label: black, sunk 0.4 mm into its recess, FUJINET over the rainbow
lx, lz = cx(A["label_xy"][0]), cz(A["label_xy"][1])
lw, lh = A["label_wh"]
ly = (fy - 0.15, fy + 0.4)
parts["c_label"] = box(lx - lw / 2, lx + lw / 2, *ly, lz - lh / 2, lz + lh / 2)
ink = (fy - 0.3, fy - 0.1)
bands = ["#e8553f", "#d9567f", "#9a5cb8", "#5a6fcf", "#3fa3b5", "#5cbb62",
         "#ecd447"]
sw = lw / len(bands)
for i, _ in enumerate(bands):
    parts[f"c_stripe{i}"] = box(lx - lw / 2 + i * sw, lx - lw / 2 + (i + 1) * sw,
                                *ink, lz - 2.2, lz - 0.6)
parts["c_label_word"] = ink_front(text_img("FUJINET", "Helvetica-Bold.ttf", 120),
                                  lx, lz + 4.6, 4.2, *ink)
parts["c_label_num"] = ink_front(text_img("5200", "AvantGardeGothic-Medium.otf",
                                          120), lx, lz - 6.0, 3.6, *ink)

# ---- the top edge: the USB-C socket and the microSD slot ----------------
u = cx(A["usb_c"][0])
s = cx(A["microsd"][0])
parts["c_ports"] = cat(
    box(u - 4.6, u + 4.6, -0.2, 3.1, TOP - 0.2, TOP + 0.05),      # USB-C mouth
    box(s - 6.2, s + 6.2, 0.2, 1.6, TOP - 0.2, TOP + 0.05))       # card slot
# a USB-C plug and its cable, for the power picture
plug = cat(box(u - 5.5, u + 5.5, -2.3, 5.2, TOP + 0.05, TOP + 14),
           cyl((u, 1.45, TOP + 14), (u, 1.45, TOP + 22), 2.6, r1=2.0))
parts["c_usb_plug"] = plug
parts["c_usb_metal"] = box(u - 4.1, u + 4.1, -0.05, 2.95, TOP - 1.0, TOP + 0.05)
pts = [(u, 1.45, TOP + 22)]
for t in np.linspace(0, 1, 10)[1:]:
    pts.append((u + 18 * t ** 2, 1.45 + 6 * t, TOP + 22 + 40 * t))
parts["c_usb_cable"] = tube(pts, 2.0)
# a microSD card, half in
parts["c_sd_card"] = box(s - 5.5, s + 5.5, 0.3, 1.1, TOP - 0.5, TOP + 7.0)

# screw heads on the back
parts["c_screws"] = cat(*[cyl((cx(h[0]), PCB + BT - 0.1, cz(h[1])),
                              (cx(h[0]), PCB + BT + 0.6, cz(h[1])), 2.6, seg=20)
                          for h in A["pcb_holes"]])

for k, t in parts.items():
    save_stl(os.path.join(OUT, k + ".stl"), t)
anch = {k: [cx(A[k][0]), cz(A[k][1])] for k in
        ("sw_reset", "sw_bootsel", "sw_s3_en", "sw_s3_boot", "led_ws", "led_rp",
         "usb_c", "microsd", "esp32_ant", "label_xy")}
# points the figures label, in this frame
mk = {"reset": [anch["sw_reset"][0], fy - 1.6, anch["sw_reset"][1]],
      "pinholes": [(anch["sw_bootsel"][0] + anch["sw_s3_en"][0]) / 2, fy,
                   (anch["sw_bootsel"][1] + anch["sw_s3_en"][1]) / 2],
      "bootsel": [anch["sw_bootsel"][0], fy, anch["sw_bootsel"][1]],
      "s3en": [anch["sw_s3_en"][0], fy, anch["sw_s3_en"][1]],
      "s3boot": [anch["sw_s3_boot"][0], fy, anch["sw_s3_boot"][1]],
      "led_ws": [anch["led_ws"][0], fy - 0.7, anch["led_ws"][1]],
      "led_rp": [anch["led_rp"][0], fy - 0.7, anch["led_rp"][1]],
      "label": [lx, fy, lz], "label_top": [lx, fy, lz + lh / 2],
      "usb": [u, 1.45, TOP], "sd": [s, 0.9, TOP], "plug": [u, 1.45, TOP + 8],
      "card": [s, 0.7, TOP + 4], "fingers": [0.0, -0.05, 4.0],
      "top": [0.0, 0.0, TOP], "side": [X1, 0.0, TOP - 20]}
json.dump({"FT": FT, "BT": BT, "PCB": PCB, "TOP": TOP, "BASE": BASE, "X1": X1,
           "bands": bands, "anchors": anch, "marks": mk},
          open(os.path.join(OUT, "cart.json"), "w"), indent=1)
print("wrote", len(parts), "cart parts to", OUT)
