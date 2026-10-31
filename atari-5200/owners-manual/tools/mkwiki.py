#!/usr/bin/env python3
"""Build the wiki edition's images into wiki/images/.

The labelled line art and the How It Works pictures come from figs.typ
through tools/wikifig.typ; the screens are the book's own captures, at half
the book's size (one and a half times the console's pixels). The GitHub wiki
is one flat namespace, so every file is prefixed atari-5200-owners-.

    python3 tools/mkwiki.py
"""
import os
import subprocess

from PIL import Image

OUT = "wiki/images"
P = "atari-5200-owners-"
os.makedirs(OUT, exist_ok=True)
TY = ["typst", "compile", "--root", ".", "--font-path", "fonts",
      "--ignore-system-fonts"]

for f in ("face", "top", "inside", "insert", "jacks", "controller", "side",
          "overlay", "window"):
    subprocess.run(TY + ["--input", f"name={f}", "--format", "png", "--ppi", "170",
                         "tools/wikifig.typ", f"{OUT}/{P}fig-{f}.png"], check=True)
for f in sorted(os.listdir("images/screens")):
    if f.endswith(".png"):
        im = Image.open(f"images/screens/{f}")
        im = im.resize((im.width // 2, im.height // 2), Image.NEAREST)
        im.save(f"{OUT}/{P}shot-{f}", optimize=True)
for f in ("a52-cover", "cart-hero", "cart-power"):
    im = Image.open(f"images/render/{f}.png")
    w = 900 if f == "a52-cover" else 500
    im = im.resize((w, int(im.height * w / im.width)), Image.LANCZOS)
    im.save(f"{OUT}/{P}{f}.png", optimize=True)
print("wiki images:", len(os.listdir(OUT)))
