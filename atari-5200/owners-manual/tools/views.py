#!/usr/bin/env python3
"""Every rendered figure in the book: which parts, which colours, which camera.

    python3 tools/views.py build images/render            # all views
    python3 tools/views.py build images/render cart-hero  # some

Each view runs tools/stl2png.py on STLs from build/stl (made by
make_cart.py and make_a5200.py).  The camera conventions are stl2png's:
orthographic, z up, --azim turns the model about z, --elev tilts it toward
the viewer; azim 0 looks along +y, at the player's side of the console and
the cartridge's label.
"""
import json
import os
import subprocess
import sys

B = sys.argv[1]
DST = sys.argv[2]
ONLY = sys.argv[3:]
S = os.path.join(B, "stl")

SHELL = "#3a3940"
BANDS = json.load(open(os.path.join(S, "cart.json")))["bands"]
CART = ([("front", SHELL), ("rear", SHELL), ("pcb", "#2d5a3a"),
         ("fingers", "#d9b23c"), ("button", "#3d3d40"), ("pinholes", "#050505"),
         ("bezels", "#141414"), ("led_white", "#f6f6f6"), ("led_red", "#e8352a"),
         ("label", "#121212"), ("label_word", "#f4f1ea"),
         ("label_num", "#f4f1ea"), ("ports", "#050505"), ("screws", "#a0a0a0")]
        + [(f"stripe{i}", c) for i, c in enumerate(BANDS)])
USB = [("usb_plug", "#e9e9e9"), ("usb_metal", "#c9c9c9"),
       ("usb_cable", "#e9e9e9")]
SD = [("sd_card", "#2b3a67")]

CONSOLE = [("body", "#232225"), ("plinth", "#121214"), ("ribs", "#2d2c30"),
           ("trim", "#cfcfd2"), ("logo", "#2a2a2e"), ("led", "#c8322a"),
           ("lid", "#3b3532"), ("slotrim", "#19191b"), ("slot", "#060606"),
           ("vents", "#2d2c30"), ("jacks", "#0e0e10"), ("jacknum", "#cfcfd2"),
           ("power", "#3a3a3d")]
PAD = [("body", "#1c1c1e"), ("deck", "#28282b"), ("stripe", "#d8d8dc"),
       ("keys", "#2e2e32"), ("keynum", "#e9c46a"), ("top3", "#2e2e32"),
       ("lab_start", "#43c063"), ("lab_pause", "#f2c522"),
       ("lab_reset", "#ee5040"), ("well", "#0f0f10"), ("shaft", "#1e1e20"),
       ("knob", "#1e1e20"), ("fire", "#e8663f"), ("cord", "#1a1a1c"),
       ("plug", "#2a2a2d")]


def c(names):
    return [("c_" + n, col) for n, col in names]


def con(names, pre="v_"):
    return [(pre + n, col) for n, col in names]


def pad(pre, names=PAD, skip=()):
    return [(pre + n, col) for n, col in names if n not in skip]


def vc(names):
    return [("v_cart_" + n, col) for n, col in names]


LV = "0.7,0.85,1.0"
VIEWS = {
    # the cartridge on its own
    "cart-hero": dict(parts=c(CART), azim=335, elev=16),
    "cart-face": dict(parts=c(CART), azim=0, elev=0, width=1100),
    "cart-top": dict(parts=c(CART + USB + SD), azim=330, elev=48),
    "cart-power": dict(parts=c(CART + USB), azim=335, elev=16),
    # the console
    "a52-insert": dict(parts=con(CONSOLE) + vc(CART), azim=-28, elev=30,
                       de=1.5, width=1800),
    "a52-empty": dict(parts=con(CONSOLE), azim=-28, elev=30, de=1.5,
                      width=1800),
    "a52-front": dict(parts=con(CONSOLE) + vc(CART) + pad("j1_", skip=("cord",))
                      + [("j1_cordin", "#1a1a1c")],
                      azim=-12, elev=22, de=1.5, width=1800),
    "a52-cover": dict(parts=con(CONSOLE) + vc(CART) + pad("k_") + pad("m_"),
                      azim=-24, elev=30, de=1.5, width=1900),
    # the controller
    "cx52": dict(parts=pad("p_", skip=("cord", "plug")) + [("p_cordin", "#1a1a1c")],
                 azim=20, elev=52, de=1.0, width=1300),
    "cx52-side": dict(parts=pad("p_", skip=("cord", "plug")) + [("p_cordin", "#1a1a1c")],
                      azim=270, elev=8, de=1.0, width=1300),
}


MARKS = {**{"c_" + k: v for k, v in
             json.load(open(os.path.join(S, "cart.json")))["marks"].items()},
         **json.load(open(os.path.join(S, "a5200.json")))["marks"]}


def render(name, cfg):
    cmd = ["python3", os.path.join(os.path.dirname(__file__), "stl2png.py")]
    # every view reports the marks of its own frame: c_* for the cartridge
    # alone, p_* for the controller alone, the rest for the console
    pre = cfg["parts"][0][0][:2]
    for k, v in MARKS.items():
        mine = (k.startswith("c_") if pre == "c_" else k.startswith("p_")
                if pre == "p_" else not k.startswith(("c_", "p_")))
        if mine:
            cmd += ["--mark", k.split("_", 1)[1] if pre in ("c_", "p_") else k,
                    ",".join(str(c) for c in v)]
    cmd += ["--marks-out", os.path.join(DST, name + ".json")]
    for stem, col in cfg["parts"]:
        f = os.path.join(S, stem + ".stl")
        if not os.path.exists(f):
            sys.exit(f"views: missing {f}")
        cmd += ["--part", f, col]
    cmd += ["--azim", str(cfg["azim"]), "--elev", str(cfg["elev"]),
            "--width", str(cfg.get("width", 1400)),
            "--levels", cfg.get("levels", LV),
            "--depth-edge", str(cfg.get("de", 0.5)),
            "--outline", str(cfg.get("outline", 2.0)),
            "--out", os.path.join(DST, name + ".png")]
    subprocess.run(cmd, check=True)
    print(name)


os.makedirs(DST, exist_ok=True)
for name, cfg in VIEWS.items():
    if not ONLY or name in ONLY:
        render(name, cfg)
