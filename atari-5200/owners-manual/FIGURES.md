# Figures

No photographs: the Rev0 cartridge has not been built. Every picture is
rendered from the design files and parametric models, drawn in Typst, or
captured from CONFIG and the games running on the FujiNet cartridge in MAME.

## Rendered (`make images`; `tools/views.py` names every view)

| File | Section | What | Made from |
|---|---|---|---|
| `images/render/cart-hero.png` | 1, inside cover | the cartridge, label side, three-quarter | `tools/make_cart.py` (the book's shell round Rev0's `case/board-anchors.scad`) |
| `images/render/cart-face.png` | 2 | the label face, labelled | same |
| `images/render/cart-top.png` | 2 | the top edge, a USB-C plug and a microSD card in | same |
| `images/render/cart-power.png` | 4 | with a USB-C charger cable | same |
| `images/render/board-inside.png` | 2 | the Rev0 board, labelled | Rev0 `docs/board-top.png` (KiCad), `tools/flatbg.py` |
| `images/render/a52-cover.png` | cover | console, cartridge, two controllers | `tools/make_a5200.py` |
| `images/render/a52-insert.png` | 4 | console with the cartridge in the slot | same |
| `images/render/a52-front.png` | 4 | the front: a controller in jack 1 | same |
| `images/render/cx52.png`, `cx52-side.png` | 5 | the controller from above and from the side | same |
| `images/render/a52-empty.png` | — | spare: the console alone | same |

Each render has a `.json` beside it giving where the model's named points
(the RESET button, the lights, the jacks, the buttons...) land in the picture;
`figs.typ` hangs its leader lines on them, so a label always reaches its part.

The cartridge shell and its label (black, FUJINET over the rainbow, the round
"5200") are the book's own design: no shell exists yet. The console is drawn
from the 1982 Owner's Manual's photographs and the published size
(15 × 13 × 4.25 in). **To check against a real CX5200:** the order of the four
controller jacks on the front (drawn 1–4 from the left, evenly spaced) and the
POWER switch at the right end of the silver band (the 1982 text says "the
lower right side of the console"; the photographs show the switch and its red
light there).

## Drawn in Typst (`figs.typ`)

| Figure | Section | What |
|---|---|---|
| `window-strip` | 3 | the 32K the console sees while CONFIG or a FujiNet game runs: game, answers ($B000–$B4FF), questions ($B500–$B7FF), game |
| the question flow | 3 | console ⇄ game chip ⇄ network chip ⇄ the world |
| `overlay-card` | 5 | a keypad overlay for the FujiNet menu, **not to scale** (no published CX52 overlay size was found) |

## Captured in MAME (`make shots`; scaled ×3 with hard pixels)

CONFIG (`emu/tour.sh`, walking CONFIG with `emu/walk.lua` and checking each
screen's words before the snapshot), against the book's own fujinet-pc
(`emu/bench.sh`, BoIP 9953):

| File | Section | Notes |
|---|---|---|
| `splash`, `hosts` | 6, 7 | the three stock hosts of `fnconfig.tmpl.ini` |
| `wifi-pick`, `wifi-join`, `wifi-ok` | 6 | fujinet-pc's dummy WiFi lists "Dummy Cafe 0–14" at −1 dBm; the walk writes invented names and strengths over those cells in screen memory just before the snapshot (`SWAP` in `emu/tour.sh`) |
| `kbd-pass`, `rename` | 6, (7) | "Fuji5200" typed on the keyboard |
| `info` | 10 | this computer's name and addresses replaced the same way with a home network's |
| `browse-sd`, `browse-games` | 7 | the bench memory card: the published game images in `GAMES/` |
| `browse-irata`, `browse-fujinet` | 7, 8 | the live `apps.irata.online` |
| `loading` | 8 | Battleship from `apps.irata.online`, caught part-way (the walk waits for 25–85%) |
| `copy-to`, `copy-here`, `copied` | 9 | Battleship copied to the memory card |

The games (`emu/games.sh`), each against its own server built from
FujiNetWIFI/servers `origin/main` on localhost, from bench copies of the
published images with only the server address changed (`tools/patchurl.py`):

| File | Section |
|---|---|
| `fcs-name`, `fcs-tables`, `fcs-table`, `fcs-menu` | 12 |
| `th-tables`, `th-table` | 13 |
| `bs-tables`, `bs-place`, `bs-battle` | 14 |
| `fz-tables`, `fz-ready`, `fz-play` | 15 |
| `fk-tables`, `fk-play` | 16 |

M.U.L.E. (`mule-*`, §17) is the game's own committed screenshots,
`fujinet-multiplayer-mule/screenshots/atari5200/`, scaled the same way.
