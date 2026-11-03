#!/usr/bin/env python3
"""Every rendered figure in the book: which parts, which colours, which camera.

    python3 tools/views.py build images/render            # all views
    python3 tools/views.py build images/render cart-hero  # some

Each view runs tools/stl2png.py on STLs from build/stl (made by
make_cart.py and make_arcadia.py).  The camera conventions are stl2png's:
orthographic, z up, --azim turns the model about z, --elev tilts it toward
the viewer; azim 0 looks along +y, at the player's side of the console and
the cartridge's label.  The look is the 1982 ADV-1 owner's manual's line
drawing: near-white surfaces, black outlines, a few flat greys.
"""
import json
import os
import subprocess
import sys

B = sys.argv[1]
DST = sys.argv[2]
ONLY = sys.argv[3:]
S = os.path.join(B, "stl")

SHELL = "#d9d9d9"
CART = [("front", SHELL), ("rear", SHELL), ("ribs", "#c8c8c8"),
        ("pcb", "#4a6a50"), ("fingers", "#d9b23c"), ("button", "#bdbdbd"),
        ("pinholes", "#050505"), ("bezels", "#141414"),
        ("led_white", "#f6f6f6"), ("led_red", "#e8352a"),
        ("label", "#141414"), ("label_word", "#f4f1ea"),
        ("label_bars", "#f4f1ea"), ("label_num", "#f4f1ea"),
        ("ports", "#050505")]
USB = [("usb_plug", "#e9e9e9"), ("usb_metal", "#c9c9c9"),
       ("usb_cable", "#e9e9e9")]
SD = [("sd_card", "#8a96b8")]

CONSOLE = [("body", "#efefef"), ("deck", "#e4e4e4"), ("rims", "#e4e4e4"),
           ("wells", "#d4d4d4"), ("grille", "#2a2a2a"),
           ("nameplate", "#141414"), ("buttons", "#bdbdbd"),
           ("power", "#cfcfcf"), ("legends", "#141414"), ("led", "#e8352a"),
           ("slotframe", "#e4e4e4"), ("slot", "#0a0a0a"),
           ("jacks", "#1a1a1a"), ("chan", "#bdbdbd"), ("dcpin", "#bdbdbd"),
           ("grommets", "#bdbdbd"), ("out_cable", "#cfcfcf"),
           ("out_plug", "#9a9a9a")]
PAD = [("body", "#efefef"), ("bevel", "#e6e6e6"), ("keypad", "#d4d4d4"),
       ("keys", "#d8d8d8"), ("keylabels", "#111111"), ("disc_well", "#bdbdbd"),
       ("disc", "#e0e0e0"), ("disc_dot", "#bdbdbd"), ("action", "#cfcfcf"),
       ("cord", "#cfcfcf")]


def c(names):
    return [("c_" + n, col) for n, col in names]


def con(names, pre="v_", cable=False):
    return [(pre + n, col) for n, col in names
            if cable or n not in ("out_cable", "out_plug")]


def pad(pre):
    return [(pre + n, col) for n, col in PAD]


def vc():
    return [("v_cart_" + n, col) for n, col in CART]


LV = "0.82,0.92,1.0"
VIEWS = {
    # the cartridge on its own
    "cart-hero": dict(parts=c(CART), azim=335, elev=16, width=1200),
    "cart-face": dict(parts=c(CART), azim=0, elev=0, width=1100),
    "cart-back": dict(parts=c(CART), azim=180, elev=0, width=1100),
    "cart-top": dict(parts=c(CART + USB + SD), azim=330, elev=48, width=1300),
    "cart-power": dict(parts=c(CART + USB), azim=335, elev=16, width=1300),
    # the console
    "adv1-cover": dict(parts=con(CONSOLE) + vc() + pad("l_") + pad("r_"),
                       azim=-30, elev=30, width=2000),
    "adv1-insert": dict(parts=con(CONSOLE) + vc(), azim=-35, elev=28,
                        width=1900),
    "adv1-empty": dict(parts=con(CONSOLE), azim=-30, elev=30, width=1900),
    "adv1-panel": dict(parts=con(CONSOLE) + vc(), azim=0, elev=55,
                       width=1900),
    "adv1-rear": dict(parts=con(CONSOLE, cable=True) + vc(), azim=205, elev=20,
                      width=1900),
    # the controller
    # upright, the keypad at the top as the player holds it (the handset's
    # long axis lies along x, so the picture is turned a quarter turn
    # clockwise afterwards, its marks with it)
    "ctl": dict(parts=pad("p_"), azim=18, elev=52, turn=True, width=1300),
    "ctl-side": dict(parts=pad("p_"), azim=90, elev=20, width=1300,
                     outline=1.4, de=1.0),
}


MARKS = {**{"c_" + k: v for k, v in
            json.load(open(os.path.join(S, "cart.json")))["marks"].items()},
         **json.load(open(os.path.join(S, "arcadia.json")))["marks"]}


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
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL)
    print(name)


os.makedirs(DST, exist_ok=True)
for name, cfg in VIEWS.items():
    if not ONLY or name in ONLY:
        render(name, cfg)
