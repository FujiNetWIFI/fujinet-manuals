#!/usr/bin/env python3
"""Generate the cart shell's board-anchors.scad OUTSIDE the hardware repo.

The Rev1 cart shell (case/Fujiversal-Atari2600-CartShell.scad) includes
board-anchors.scad, which tools/gen_pcb.py writes from the placement table.
Importing gen_pcb has no side effects (its main() is guarded); we run only
the placement and write_case_anchors(), with PRJ pointed at our build dir,
so nothing in fujinet-hardware is touched.  Also dumps anchors.json for the
accent-part generator.

Run:  python3 -B tools/cart_anchors.py $HW build
"""
import json
import os
import sys

sys.dont_write_bytecode = True
hw, out = os.path.abspath(sys.argv[1]), os.path.abspath(sys.argv[2])
sys.path.insert(0, os.path.join(hw, "tools"))
cwd = os.getcwd()
os.chdir(os.path.join(hw, "tools"))
import gen_pcb as G  # noqa: E402

G.do_placement(G.place)
os.chdir(cwd)
G.PRJ = out
G.write_case_anchors()


def at(key):
    x, y, _ = G.PLACE[G.D.KEY[key]]
    return [x, y]


json.dump({
    "board": [G.X0, G.Y0, G.X1, G.Y1], "shoulder_y": G.SHOULDER,
    "sw_reset": at("SW_RESET"), "sw_bootsel": at("SW_BOOTSEL"),
    "sw_s3rst": at("SW_S3EN"), "sw_s3boot": at("SW_S3BOOT"),
    "ws_led": at("D_WS"), "rp_led": at("D_LED"),
    "usb": at("J_USB"), "sd": at("J_SD"), "ant": at("U_S3"),
    "holes": [[x, y] for x, y, d in G.HOLES],
}, open(os.path.join(out, "case", "anchors.json"), "w"), indent=1)
print("wrote", os.path.join(out, "case", "board-anchors.scad"))
