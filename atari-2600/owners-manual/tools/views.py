#!/usr/bin/env python3
"""Every rendered figure in the book: which parts, which colours, which camera.

    python3 tools/views.py build images/render            # all views
    python3 tools/views.py build images/render cart-hero  # some

Each view runs tools/stl2png.py on STLs from build/stl (made by
make_cart_bits.py and make_vcs.py).  The camera conventions are stl2png's:
orthographic, z up, --azim turns the model about z, --elev tilts it toward
the viewer; azim 0 looks along +y.  For the cart that is its rear face; for
the console it is the front, the player's side.
"""
import os
import subprocess
import sys

B = sys.argv[1]
DST = sys.argv[2]
ONLY = sys.argv[3:]
S = os.path.join(B, "stl")

SHELL = "#5b5753"
BLACK = "#1d1d1d"
CART_LABEL = [("label_black", BLACK), ("label_cream", "#efe9dc"),
              ("stripe_lime", "#b8d433"), ("stripe_blue", "#1d9ad6"),
              ("stripe_orange", "#f6921e"), ("stripe_red", "#ef4b2d"),
              ("stripe_magenta", "#c4268c"), ("endlabel", BLACK),
              ("label_word", "#f4f1ea"), ("label_sub", "#f4f1ea"),
              ("label_logo", BLACK)]
CART = [("front", SHELL), ("rear", SHELL)] + CART_LABEL
LEDS = [("led_white", "#ffffff"), ("led_red", "#e8352a")]
SD = [("sd_card", "#2b3a67")]
USB = [("usb_plug", "#2a2a2a"), ("usb_metal", "#c9c9c9"),
       ("usb_cable", "#2a2a2a")]

CONSOLE = [("body", "#2b2927"), ("plinth", "#151515"), ("wood", "#94603a"),
           ("grain", "#6d4426"), ("ribs", "#2b2927"), ("trim", "#bdbdb5"),
           ("panel", "#202020"), ("swslot", "#0c0c0c"), ("lever", "#2e2e2e"),
           ("levcap", "#c8c8c0"), ("slotrim", "#1e1e1e"), ("slot", "#090909")]
REAR = [("jack_left", "#a9a9a4"), ("jackin_left", "#151515"),
        ("jack_right", "#a9a9a4"), ("jackin_right", "#151515"),
        ("power", "#a9a9a4"), ("powerin", "#151515"), ("chan", "#2e2e2e"),
        ("tvcable", "#1c1c1c")]
STICK = [("j_base", "#1e1e1e"), ("j_boot", "#2c2c2c"), ("j_shaft", "#1e1e1e"),
         ("j_knob", "#1e1e1e"), ("j_fire", "#d9452b"), ("j_plug", "#2c2c2c"),
         ("j_cable", "#1e1e1e")]


def c(names):
    return [("c_" + n, col) for n, col in names]


def v(names):
    return [("v_" + n, col) for n, col in names]


def vc(names):
    return [("v_cart_" + n, col) for n, col in names]


LV = "0.7,0.85,1.0"
VIEWS = {
    # the cartridge on its own
    "cart-hero": dict(parts=c(CART), azim=155, elev=18),
    "cart-face": dict(parts=c(CART), azim=180, elev=0, width=1100),
    "cart-rear": dict(parts=c(CART + LEDS + SD), azim=0, elev=0, width=1100),
    "cart-rear34": dict(parts=c(CART + LEDS + SD), azim=25, elev=14),
    "cart-top": dict(parts=c(CART + USB), azim=205, elev=40),
    "cart-side": dict(parts=c(CART + SD + LEDS), azim=300, elev=12),
    # the console
    "vcs-insert": dict(parts=v(CONSOLE + REAR) + vc(CART), azim=-28,
                       elev=26, de=1.5, width=1800),
    "vcs-empty": dict(parts=v(CONSOLE + REAR), azim=-28, elev=26, de=1.5,
                      width=1800),
    "vcs-panel": dict(parts=v(CONSOLE) + vc(CART), azim=0, elev=40, de=1.0,
                      width=1800),
    "vcs-rear": dict(parts=[(n, col) for n, col in
                            [("v_" + a, b) for a, b in CONSOLE + REAR]
                            + [(a, b) for a, b in STICK]] + vc(CART),
                     azim=155, elev=22, de=1.5, width=1800),
    "vcs-cover": dict(parts=v(CONSOLE + REAR) + vc(CART)
                      + [("k_" + a[2:], b) for a, b in STICK if a != "j_plug"]
                      + [("m_" + a[2:], b) for a, b in STICK if a != "j_plug"],
                      azim=-20, elev=22, de=1.5, width=1800),
}


def render(name, cfg):
    cmd = ["python3", os.path.join(os.path.dirname(__file__), "stl2png.py")]
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


os.makedirs(DST, exist_ok=True)
for name, cfg in VIEWS.items():
    if not ONLY or name in ONLY:
        render(name, cfg)
