#!/usr/bin/env python3
"""Build the wiki edition's images into wiki/images/.

Every picture keeps the book's look: the labelled line art and the How It
Works diagrams come from figs.typ through tools/wikifig.typ, the TV screens
from screens/*.txt in the cartridge's font, and the game screens are the
book's own scaled captures.  The GitHub wiki is one flat namespace, so every
file is prefixed atari-2600-owners-.

    python3 tools/mkwiki.py
"""
import os
import shutil
import subprocess

from PIL import Image

OUT = "wiki/images"
P = "atari-2600-owners-"
os.makedirs(OUT, exist_ok=True)
TY = ["typst", "compile", "--root", ".", "--font-path", "fonts",
      "--ignore-system-fonts"]


def typ(kind, name, out, ppi=170):
    subprocess.run(TY + ["--input", f"kind={kind}", "--input", f"name={name}",
                         "--format", "png", "--ppi", str(ppi),
                         "tools/wikifig.typ", out], check=True)


for f in ("hero", "rear", "top", "side", "inside", "insert", "jacks", "panel",
          "memory"):
    typ("fig", f, f"{OUT}/{P}fig-{f}.png")
for n in range(1, 5):
    typ("chain", str(n), f"{OUT}/{P}chain-{n}.png", ppi=150)
for f in sorted(os.listdir("screens")):
    if f.endswith(".txt"):
        typ("tv", f[:-4], f"{OUT}/{P}tv-{f[:-4]}.png", ppi=150)
for f in sorted(os.listdir("images/screens")):
    if f.endswith(".png"):
        im = Image.open(f"images/screens/{f}")
        im = im.resize((im.width // 2, im.height // 2), Image.NEAREST)
        im.save(f"{OUT}/{P}shot-{f}", optimize=True)
for f in ("vcs-cover", "cart-hero"):
    im = Image.open(f"images/render/{f}.png")
    w = 900
    im = im.resize((w, int(im.height * w / im.width)), Image.LANCZOS)
    im.save(f"{OUT}/{P}{f}.png", optimize=True)
print("wiki images:", len(os.listdir(OUT)))
