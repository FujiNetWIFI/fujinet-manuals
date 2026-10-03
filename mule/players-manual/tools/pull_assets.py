#!/usr/bin/env python3
"""pull_assets.py -- copy each edition's pictures out of the game repo.

usage: pull_assets.py [--game ~/Workspace/fujinet-multiplayer-mule] [TARGET...]

For every screenshots/<target>/ folder of fujinet-multiplayer-mule this writes
assets/<target>/:
  screens/<scene>.png   the screen, scaled by whole numbers (nearest
                        neighbour) so its shape is right on paper
  icons/<name>.png      single map plots cut from the land-auction screen:
                        plains, river, mountains 1-3, town, and the four
                        outfitted M.U.L.E.s
  manifest.json         which scenes and icons exist (Typst can't test for
                        a file, so the book asks this instead)

The test mode's board (clients/mekkogx/src/teststart.c) puts its plots at
known places, so the icons are cut by plot number from the grid below.
The 2600 draws its map from the cartridge's composer; its icons are rendered
from that composer's model (clients/atari-2600/tools/mulemap.py) for the
same board.
"""
import argparse
import json
import os
import shutil
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

# target: (sx, sy) screen scale, crop box for the screen (or None),
#         map grid (ox, oy, plot w, plot h) in the native screenshot
TARGETS = {
    "atari":      ((1, 1), None,               (48, 64, 64, 64)),
    "apple2":     ((1, 2), None,               (30, 16, 56, 32)),
    "coco":       ((3, 3), (58, 25, 314, 217), (75, 41, 24, 32)),
    "msdos-pcjr": ((1, 2), None,               (32, 20, 64, 32)),
    "msdos-cga":  ((2, 2), None,               (16, 20, 32, 32)),
    "adam":       ((2, 2), None,               (28, 28, 24, 32)),
    "msx":        ((1, 1), None,               (32, 32, 48, 64)),
    "lynx":       ((4, 4), None,               (8, 10, 16, 16)),
    "intv":       ((1, 1), None,               (64, 48, 64, 64)),
    "astrocade":  ((2, 2), None,               (32, 34, 32, 24)),
    "atari-2600": ((4, 2), None,               None),
}

# the test board's plots (teststart.c): plot number per icon
ICONS = {
    "plain": 2, "river": 31, "mountain1": 25, "mountain2": 5, "mountain3": 15,
    "town": 22, "food": 10, "energy": 12, "smithore": 20, "crystite": 34,
}
ICON_SCENE = "06-land-auction-show"


def scale(im, sx, sy):
    return im.resize((im.width * sx, im.height * sy), Image.NEAREST)


def icon_up(im, sx, sy):
    """An icon, aspect-corrected, then whole-number scaled to >= 120 px wide."""
    im = scale(im, sx, sy)
    k = max(1, -(-120 // im.width))
    return scale(im, k, k)


def a2600_icons(game, out):
    sys.path.insert(0, os.path.join(game, "clients", "atari-2600", "tools"))
    import mulemap
    st = mulemap.test_state()
    # the same board as the other targets' test mode
    for p in (31, 40, 5):
        st["owner"][p], st["mule"][p] = None, None
    st["owner"][20], st["mule"][20], st["prod"][20] = 0, mulemap.G_SMITHORE, 8
    st["owner"][34], st["mule"][34] = 2, mulemap.G_CRYSTITE
    tmp = os.path.join(out, "_map.png")
    mulemap.render_png(st, tmp, scale=1)          # 320 x 160: a plot is 32 x 32
    m = Image.open(tmp).convert("RGB")
    os.remove(tmp)
    names = []
    for name, p in ICONS.items():
        r, c = divmod(p, 9)
        x, y = 16 + c * 32, r * 32
        icon_up(m.crop((x, y, x + 32, y + 32)), 1, 1).save(os.path.join(out, name + ".png"))
        names.append(name)
    return names


def pull(game, t):
    (sx, sy), box, grid = TARGETS[t]
    src = os.path.join(game, "screenshots", t)
    dst = os.path.join(ROOT, "assets", t)
    if os.path.isdir(dst):
        shutil.rmtree(dst)
    os.makedirs(os.path.join(dst, "screens"))
    os.makedirs(os.path.join(dst, "icons"))
    scenes = []
    for f in sorted(os.listdir(src)):
        if not f.endswith(".png"):
            continue
        im = Image.open(os.path.join(src, f)).convert("RGB")
        if box:
            im = im.crop(box)
        scale(im, sx, sy).save(os.path.join(dst, "screens", f))
        scenes.append(f[:-4])
    icons = []
    if grid:
        f = os.path.join(src, ICON_SCENE + ".png")
        if os.path.exists(f):
            im = Image.open(f).convert("RGB")
            ox, oy, pw, ph = grid
            for name, p in ICONS.items():
                r, c = divmod(p, 9)
                x, y = ox + c * pw, oy + r * ph
                icon_up(im.crop((x, y, x + pw, y + ph)), sx, sy).save(
                    os.path.join(dst, "icons", name + ".png"))
                icons.append(name)
    else:
        icons = a2600_icons(game, os.path.join(dst, "icons"))
    json.dump({"scenes": scenes, "icons": icons}, open(os.path.join(dst, "manifest.json"), "w"), indent=1)
    print(f"{t}: {len(scenes)} screens, {len(icons)} icons")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--game", default=os.path.expanduser("~/Workspace/fujinet-multiplayer-mule"))
    ap.add_argument("targets", nargs="*")
    a = ap.parse_args()
    for t in a.targets or TARGETS:
        pull(a.game, t)


if __name__ == "__main__":
    main()
