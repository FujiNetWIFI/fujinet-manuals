# Figures

Every picture in the book, and where it comes from. Nothing is photographed.

## Rendered (`make images`)

`tools/views.py` renders each from STLs made by `tools/make_cart.py` (the
book's cartridge round the Rev0 anchor file) and `tools/make_arcadia.py` (the
ADV-1 console and hand controllers), with `tools/stl2png.py`. Each PNG has a
JSON beside it saying where named model points land, for the leader lines in
`figs.typ`.

| File | Section | What | Camera |
|---|---|---|---|
| `adv1-cover` | cover | console, cartridge, left controller in its well, right controller out on its cord | azim -30, elev 30 |
| `cart-hero` | 1 | the cartridge, label side | 335 / 16 |
| `cart-back` | 2 | the back: lights, RESET, service holes, contacts (numbered) | 180 / 0 |
| `cart-top` | 2 | the top edge and right side, a USB-C plug and a microSD card in | 330 / 48 |
| `board-inside` | 2 | the Rev0 board from its parts side: `docs/board-top.png` (kicad-cli) through `tools/flatbg.py` | — |
| `adv1-rear` | 4 | the console from behind: output cable, channel switch, AC jack, the cartridge's back | 205 / 20 |
| `adv1-insert` | 4 | the cartridge in the console | -35 / 28 |
| `cart-power` | 4 | the cartridge with a USB-C charger | 335 / 16 |
| `ctl` | 5 | the hand controller, upright (rendered on its side, turned a quarter turn with its marks) | 18 / 52 |
| `adv1-panel` | 5 | the deck, square on: RESET, SELECT, OPTION, START, POWER, the slot | 0 / 55 |

Not used in the book (kept for the wiki or later): `adv1-empty`, `cart-face`, `ctl-side`.

## Drawn in Typst

| What | Where |
|---|---|
| The cover's lettering, three bars, television outline | `parts/00-cover.typ`, `lib.typ` `bars` |
| The cartridge window strip, the question flow | `figs.typ` `window-strip`, `parts/03-how.typ` |
| The keyboard overlays (CONFIG, 5 Card Stud, Battleship, Fujitzee) | `lib.typ` `overlay` |
| The television outline round every screen, and the screens' callouts | `lib.typ` `tv`, `tvlab`, `cell` |
| The game sections' title bands | `lib.typ` `band` |

## Captured in MAME (`make shots`)

`emu/tour.sh` (CONFIG, the Lobby) and `emu/games.sh` (the games), each screen a
run of `emu/walk.lua` against the bench; scaled 9 × 5 by `tools/scrscale.py`.
The screen as text is in `build/tour/<name>.log`.

| File | Section | What |
|---|---|---|
| `wifi-pick`, `wifi-conn` | 6 | SELECT NETWORK (names and signal cells swapped in), CONNECTING |
| `wifi-pass` | 6 | the character grid, "Fuji2001" typed |
| `hosts`, `rename` | 7 | FUJINET HOSTS as it comes; HOST NAME |
| `browse-irata`, `browse-arcadia`, `filter` | 7 | apps.irata.online, its Arcadia folder, filtered by `*JU*` |
| `booting`, `browse-fujinet`, `browse-sd`, `browse-games` | 8 | BOOTING (M.U.L.E. from the card), the network games, the memory card |
| `copy-to`, `copy-here` | 9 | copying Battleship to the card |
| `info` | 10 | FUJINET INFO (addresses swapped in) |
| `lobby-name`, `lobby-list` | 11 | the Lobby (branch build) against the bench Lobby's rooms |
| `fcs-name`, `fcs-tables`, `fcs-table` | 12 | 5 Card Stud, an AI room |
| `th-table` | 13 | Texas Hold'em after the flop |
| `bs-place`, `bs-battle` | 14 | Battleship, AI 1 on 1 |
| `fz-turn` | 15 | Fujitzee after the first roll |
| `mule-title`, `mule-develop-map`, `mule-land-grant`, `mule-develop-town` | 16 | from `fujinet-multiplayer-mule/screenshots/arcadia` |

Also captured, not in the book: `copied`, `filter-edit`, `notcart`, `mule-lobby`, `mule-auction`.

## To check against a real ADV-1 and a built Rev0

- Console and handset proportions are drawn from the 1982 drawings (the service manual gives only the PCB, 265 × 145 mm); the slot is drawn narrower than the real one, so the cartridge reads at a useful size.
- The cartridge shell is the book's own (errata H3); where its light windows and RESET hole fall depends on the shell to come.
