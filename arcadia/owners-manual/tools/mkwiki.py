#!/usr/bin/env python3
"""Build the wiki edition's images into wiki/images/.

The labelled line art and the How It Works picture come from figs.typ
through tools/wikifig.typ; the screens are the book's own captures, at half
the book's size. The GitHub wiki is one flat namespace, so every file is
prefixed arcadia-owners-.

    python3 tools/mkwiki.py
"""
import os
import re
import subprocess

from PIL import Image

OUT = "wiki/images"
P = "arcadia-owners-"
os.makedirs(OUT, exist_ok=True)
for f in os.listdir(OUT):
    os.remove(os.path.join(OUT, f))
TY = ["typst", "compile", "--root", ".", "--font-path", "fonts",
      "--ignore-system-fonts"]

for f in ("back", "top", "inside", "insert", "rear", "panel", "controller",
          "overlay", "window"):
    subprocess.run(TY + ["--input", f"name={f}", "--format", "png", "--ppi", "150",
                         "tools/wikifig.typ", f"{OUT}/{P}fig-{f}.png"], check=True)
# only the screens the wiki page shows
md = open("wiki/FujiNet-Owners-Manual-for-the-Emerson-Arcadia-2001.md").read()
for f in sorted(set(re.findall(r"arcadia-owners-shot-([a-z0-9-]+)\.png", md))):
    im = Image.open(f"images/screens/{f}.png")
    im = im.resize((im.width // 2, im.height // 2), Image.NEAREST)
    im.save(f"{OUT}/{P}shot-{f}.png", optimize=True)
for f, w in (("adv1-cover", 900), ("cart-hero", 420), ("cart-power", 420)):
    im = Image.open(f"images/render/{f}.png")
    im = im.resize((w, int(im.height * w / im.width)), Image.LANCZOS)
    im.save(f"{OUT}/{P}{f}.png", optimize=True)
print("wiki images:", len(os.listdir(OUT)))
