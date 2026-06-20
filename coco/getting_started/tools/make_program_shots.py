#!/usr/bin/env python3
"""Clean up Rich Stephens' program screenshots for the Program Library.

The CoCo clients (News, Wiki, Netcat) render text through a hi-res
soft-font library ("hirestxt"), not the hardware VDG charset, so they
can't be re-typeset in Hot CoCo the way the CONFIG screens are. Rich's
captures are the authoritative output.

News and Wiki are essentially green-on-black / black-on-green with a
soft anti-aliased font; Netcat adds a buff terminal field and a blue
cursor. We recolour them into the manual's TV palette so they sit
beside the typeset CONFIG figures. The recolour is luminance-preserving
(each pixel is blended between ink and the manual green by its green
level), NOT a hard threshold — that keeps the thin soft-font strokes
legible instead of shattering them.

Weather is a graphics-mode screen with a bitmap icon and coloured value
text, captured off a CRT — it can't be cleanly recoloured, so it is
just trimmed and kept as a photograph.

Writes images/prog-news.png, prog-wiki.png, prog-netcat.png,
prog-weather.png. Re-run with `make images`.
"""
import numpy as np
from PIL import Image

OUT = "images"

# manual VDG palette (matches the #let vg dictionary in manual.typ)
GREEN = np.array([54, 169, 59], float)
INK = np.array([13, 13, 13], float)
BUFF = np.array([233, 231, 223], float)
BLUE = np.array([35, 35, 155], float)

GMAX = 226.0   # the emulator's bright-green G level (full background)


def content_bbox(a, thresh=60):
    lit = a.sum(2) >= thresh
    ys, xs = np.where(lit)
    return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1


def green_lerp(G):
    """Blend ink->green by green level, preserving soft anti-aliasing."""
    t = np.clip(G / GMAX, 0, 1)[:, :, None]
    return INK + (GREEN - INK) * t


def recolour_green(name):
    a = np.asarray(Image.open(f"{OUT}/{name}.png").convert("RGB")).astype(float)
    x0, y0, x1, y1 = content_bbox(a)
    a = a[y0:y1, x0:x1]
    out = green_lerp(a[:, :, 1])
    Image.fromarray(out.clip(0, 255).astype(np.uint8)).save(f"{OUT}/prog-{name}.png")
    print(f"prog-{name}.png  {out.shape[1]}x{out.shape[0]}")


def netcat():
    a = np.asarray(Image.open(f"{OUT}/netcat.png").convert("RGB")).astype(float)
    x0, y0, x1, y1 = content_bbox(a)
    a = a[y0:y1, x0:x1]
    R, G, B = a[:, :, 0], a[:, :, 1], a[:, :, 2]
    out = green_lerp(G)                              # green band + its text
    buff = (R >= 128) & (B >= 110)                   # buff terminal field
    out[buff] = BUFF
    blue = (B >= 110) & (R < 100) & (G < 120)        # blue cursor block
    out[blue] = BLUE
    Image.fromarray(out.clip(0, 255).astype(np.uint8)).save(f"{OUT}/prog-netcat.png")
    print(f"prog-netcat.png  {out.shape[1]}x{out.shape[0]}")


def weather():
    a = np.asarray(Image.open(f"{OUT}/weather.png").convert("RGB"))
    x0, y0, x1, y1 = content_bbox(a, thresh=80)
    Image.fromarray(a[y0:y1, x0:x1]).save(f"{OUT}/prog-weather.png")
    print(f"prog-weather.png  {x1 - x0}x{y1 - y0} (photo, trimmed)")


if __name__ == "__main__":
    recolour_green("news")
    recolour_green("wiki")
    netcat()
    weather()
