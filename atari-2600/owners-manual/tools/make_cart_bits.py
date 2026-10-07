#!/usr/bin/env python3
"""Stand the Rev1 cart shell up and add the parts a picture needs.

Input: build/stl/cart_front.stl + cart_rear.stl (assembled position, from
tools/cartviews.scad) and build/case/anchors.json (tools/cart_anchors.py).

The shell frame is X across the cart, Y = -(board y) with the open end at
the bottom, Z from the label face (0) to the screw face (20.22).  Rotating
+90 deg about X stands it up -- a proper rotation, not an axis swap, so the
component side still reads left-to-right as in KiCad.  The CART frame:

    x  across, centred (player's RIGHT is -x: the player faces the label)
    y  label face at 0 facing +y; the rear (screw) face at -20.22
    z  the open end at 0, the top end at 98

so stl2png --azim 180 shows the label, --azim 0 the rear face with the
lights and RESET.  Writes build/stl/c_*.stl.

Run:  python3 tools/make_cart_bits.py build
"""
import json
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from stlkit import (box, cat, cyl, extrude, load_stl, rx, save_stl,  # noqa
                    xform, bezier, tube)

B = sys.argv[1] if len(sys.argv) > 1 else "build"
A = json.load(open(os.path.join(B, "case", "anchors.json")))

T, CW, CH = 20.22, 81.49, 98.0
EDGE = 6.5
bx0, by0, bx1, by1 = A["board"]
XC = (bx0 + bx1) / 2
YO = -(by1 + EDGE)                  # the open end, shell Y
Z_B, PCB = 11.25, 1.6
Z_F = Z_B + PCB


def stand(t):
    return xform(t, rx(90), (-XC, 0, -YO))


def cx(x):            # board x -> cart x
    return x - XC


def cz(y):            # board y -> cart z
    return -y - YO


def cy(z):            # shell Z -> cart y
    return -z


out = os.path.join(B, "stl")
front = stand(load_stl(os.path.join(out, "cart_front.stl")))
rear = stand(load_stl(os.path.join(out, "cart_rear.stl")))
save_stl(os.path.join(out, "c_front.stl"), front)
save_stl(os.path.join(out, "c_rear.stl"), rear)

# ---- the label: a black field, a stripe of the booklet's band colours, and
# a cream foot -- the shape of a 1977 text-label cartridge.
LX = 35.0
lab_y = (0.0, 0.35)
parts = {
    "c_label_black": box(-LX, LX, *lab_y, 61.0, 93.0),
    "c_label_cream": box(-LX, LX, *lab_y, 27.0, 55.0),
}
stripes = ["lime", "blue", "orange", "red", "magenta"]
z = 55.0
for s in stripes:
    parts["c_stripe_" + s] = box(-LX, LX, *lab_y, z, z + 1.2)
    z += 1.2
# the end label on the top end (norm8332's 0.8 mm recess, filled)
parts["c_endlabel"] = box(-CW / 2 + 4.75, CW / 2 - 4.75, -T + 2.6, -2.5,
                          CH - 0.05, CH + 0.25)

# ---- the lights, seen through the rear face's light holes
yr = -T
parts["c_led_white"] = cyl((cx(A["ws_led"][0]), yr + 0.6, cz(A["ws_led"][1])),
                           (cx(A["ws_led"][0]), yr - 0.25, cz(A["ws_led"][1])),
                           1.45, seg=24)
parts["c_led_red"] = cyl((cx(A["rp_led"][0]), yr + 0.6, cz(A["rp_led"][1])),
                         (cx(A["rp_led"][0]), yr - 0.25, cz(A["rp_led"][1])),
                         0.95, seg=24)

# ---- USB-C plug, standing a little clear of the top end, with its cable
ux = cx(A["usb"][0])
uy = cy(Z_F + 1.63)
gap = 9.0
plug = cat(box(ux - 6.0, ux + 6.0, uy - 3.1, uy + 3.1, CH + gap, CH + gap + 22),
           cyl((ux, uy, CH + gap + 22), (ux, uy, CH + gap + 30), 2.6, r1=2.0))
shell_ = box(ux - 4.2, ux + 4.2, uy - 1.3, uy + 1.3, CH + gap - 6.6, CH + gap)
cable = tube(bezier((ux, uy, CH + gap + 29), (ux, uy, CH + gap + 55),
                    (ux + 22, uy, CH + gap + 60), (ux + 40, uy, CH + gap + 48),
                    n=10), 2.0)
parts["c_usb_plug"] = plug
parts["c_usb_metal"] = shell_
parts["c_usb_cable"] = cable
# the same plug pushed home (for the insert figures)
home = -gap + 1.0
parts["c_usbin_plug"] = xform(plug, None, (0, 0, home))
parts["c_usbin_cable"] = xform(cable, None, (0, 0, home))

# ---- the microSD card, half out of its side slot (+x is the player's LEFT)
sz = cz(A["sd"][1])
sy0, sy1 = cy(Z_F + 1.35), cy(Z_F + 0.55)
xw = CW / 2
card = extrude([(sy0, sz - 5.5), (sy1, sz - 5.5), (sy1, sz + 5.5),
                (sy0, sz + 5.5)], xw - 6.0, xw + 9.0, axis="x")
parts["c_sd_card"] = card

# ---- the board and its fingers, visible in the open end
tabx = (cx(83.8), cx(116.2))
zb0 = cz(by1)
parts["c_board"] = box(tabx[0], tabx[1], cy(Z_F), cy(Z_B), zb0, zb0 + 26)
fing = []
for i in range(12):
    fx = tabx[0] + 2.2 + i * 2.54
    for yy in ((cy(Z_F) - 0.05, cy(Z_F)), (cy(Z_B), cy(Z_B) + 0.05)):
        fing.append(box(fx - 0.8, fx + 0.8, *yy, zb0 + 0.5, zb0 + 8.0))
parts["c_fingers"] = cat(*fing)

# ---- lettering, as geometry so it foreshortens with the face: the text is
# rasterised (Pillow) and every run of ink pixels on a row becomes a box.
from PIL import Image, ImageDraw, ImageFont  # noqa: E402

FONTS = os.path.join(os.path.dirname(__file__), "..", "fonts")


def ink_boxes(img, x0, z1, mm, y0, y1):
    """img: L-mode, ink > 127.  Placed with its top-left at (x0, z1) in the
    label plane, `mm` per pixel; the player reads it from +y, so the image's
    left is the cart's +x."""
    a = np.array(img) > 127
    out = []
    for r in range(a.shape[0]):
        row = a[r]
        c = 0
        while c < len(row):
            if row[c]:
                e = c
                while e < len(row) and row[e]:
                    e += 1
                out.append(box(x0 - e * mm, x0 - c * mm, y0, y1,
                               z1 - (r + 1) * mm, z1 - r * mm))
                c = e
            else:
                c += 1
    return cat(*out)


def text_img(s, font, size, track=0):
    f = ImageFont.truetype(os.path.join(FONTS, font), size)
    w = int(sum(f.getlength(ch) + track for ch in s)) + 4
    h = int(size * 1.3)
    im = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(im)
    x = 2
    for ch in s:
        d.text((x, 0), ch, fill=255, font=f)
        x += f.getlength(ch) + track
    bb = im.getbbox()
    return im.crop(bb)


ly = (0.35, 0.55)
sub = text_img("network program", "NimbusSans-Italic.otf", 40)
sm = 0.15
parts["c_label_sub"] = ink_boxes(sub, LX - 5.0, 89.0, sm, *ly)
mm = 0.13
word = text_img("FUJINET", "HarryFat.otf", 120)
parts["c_label_word"] = ink_boxes(word, word.width * mm / 2, 82.5, mm, *ly)
# the FujiNet mark (the logo's cluster of discs), cropped from the logo
logo = Image.open(os.path.join(os.path.dirname(__file__), "..", "images",
                               "fujinet-logo.png")).convert("RGBA")
logo = Image.alpha_composite(Image.new("RGBA", logo.size, "white"),
                             logo).convert("L")
logo = Image.eval(logo, lambda v: 255 - v)
logo.paste(0, (1340, 0, logo.width, 495))      # the N of NET
logo = logo.crop((700, 0, 1400, logo.height))
logo = logo.crop(logo.getbbox())
mh = 22.0
logo = logo.resize((int(logo.width * 0.4), int(logo.height * 0.4)))
lm = mh / logo.height
parts["c_label_logo"] = ink_boxes(logo, logo.width * lm / 2, 52.5, lm, *ly)

for k, t in parts.items():
    save_stl(os.path.join(out, k + ".stl"), t)
json.dump({"T": T, "CW": CW, "CH": CH, "usb": [ux, uy], "sd_z": sz,
           "reset": [cx(A["sw_reset"][0]), cz(A["sw_reset"][1])],
           "bootsel": [cx(A["sw_bootsel"][0]), cz(A["sw_bootsel"][1])],
           "s3rst": [cx(A["sw_s3rst"][0]), cz(A["sw_s3rst"][1])],
           "s3boot": [cx(A["sw_s3boot"][0]), cz(A["sw_s3boot"][1])],
           "ws_led": [cx(A["ws_led"][0]), cz(A["ws_led"][1])],
           "rp_led": [cx(A["rp_led"][0]), cz(A["rp_led"][1])]},
          open(os.path.join(out, "cart.json"), "w"), indent=1)
print("wrote", len(parts) + 2, "cart parts to", out)
