#!/usr/bin/env python3
"""Generate the cover starfield — the 1980 Operation Manual covers are
black card stock with sparse white stars and a faint smoky nebula.
Writes images/starfield.png (1800x1440 = 10x8in at 180dpi).
"""
import sys
import numpy as np
from PIL import Image, ImageFilter

W, H = 1800, 1440
rng = np.random.default_rng(802600)  # 26-3001, scrambled

# near-black card stock with a hint of texture
base = rng.normal(16, 3, (H, W))

# faint nebula: a few big soft blobs, brightened subtly
neb = np.zeros((H, W))
for _ in range(7):
    cx, cy = rng.uniform(0, W), rng.uniform(0, H)
    sx, sy = rng.uniform(W * 0.10, W * 0.30), rng.uniform(H * 0.10, H * 0.30)
    amp = rng.uniform(4, 12)
    y, x = np.mgrid[0:H, 0:W]
    neb += amp * np.exp(-(((x - cx) / sx) ** 2 + ((y - cy) / sy) ** 2))
img = np.clip(base + neb, 0, 60)

out = Image.fromarray(img.astype(np.uint8), "L").convert("RGB")
px = out.load()

# stars: mostly faint specks, a few bright ones
for _ in range(420):
    x, y = int(rng.uniform(0, W)), int(rng.uniform(0, H))
    b = int(rng.uniform(70, 255))
    px[x, y] = (b, b, b)
    if b > 200 and rng.uniform() < 0.5:        # bright stars get a glow
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if 0 <= x + dx < W and 0 <= y + dy < H:
                px[x + dx, y + dy] = (b // 2, b // 2, b // 2)

out = out.filter(ImageFilter.GaussianBlur(0.4))
dest = sys.argv[1] if len(sys.argv) > 1 else "images/starfield.png"
out.save(dest)
print("wrote", dest)
