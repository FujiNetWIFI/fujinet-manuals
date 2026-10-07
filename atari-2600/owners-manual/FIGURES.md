# Figures

No photographs: the Rev1 cartridge has not been built. Every picture is
rendered from the design files, typeset from the sources, or captured from
the FujiNet cartridge running in MAME.

## Rendered (`make images`; `tools/views.py` names each view)

| File | Section | What | Made from |
|---|---|---|---|
| `images/render/cart-hero.png` | 1, cover | the cartridge, label side, three-quarter | Rev1 `CartShell.scad` + `make_cart_bits.py` |
| `images/render/cart-rear.png` | 2 | the back: lights, RESET, service holes, card | same |
| `images/render/cart-top.png` | 2 | top end with a USB-C plug | same |
| `images/render/cart-side.png` | 2 | the microSD side | same |
| `images/render/cart-face.png`, `cart-rear34.png` | — | spare views | same |
| `images/render/board-inside.png` | 2 | the Rev1 board, labelled | `Rev1/docs/board-top.png` (KiCad), `flatbg.py` |
| `images/render/vcs-insert.png` | 4 | console with the cartridge in the slot | `make_vcs.py` |
| `images/render/vcs-rear.png` | 4 | console rear, joystick in LEFT CONTROLLER | `make_vcs.py` |
| `images/render/vcs-panel.png` | 5 | the switch panel, 1977-style labels | `make_vcs.py` |
| `images/render/vcs-cover.png` | cover | console, cartridge, two joysticks | `make_vcs.py` |
| `images/render/vcs-empty.png` | — | spare: console without a cartridge | `make_vcs.py` |

The cartridge label (black field, "network program", FUJINET in Harry Fat,
the band-colour stripe, the FujiNet mark) is the book's own design: the real
cartridge's label is not designed yet.

## Typeset in the cartridge's font (`screens/*.txt`, `make check` runs `tvcheck.py`)

| File | Section | Source of the strings and rows |
|---|---|---|
| `wifi-pick`, `wifi-conn`, `wifi-fail` | 6 | `fujinet-config/atari-2600/src/wifi.asm` (`:548-556`, `WSROW0`, `WSROWH`) — SSIDs invented |
| `kbd-pass` | 6 | `src/edit.asm` (`EDROW0`, grid `:261-291`, `:406-411`) |
| `hosts`, `hosts-menu`, `copy-to` | 7, 9 | `src/hosts.asm:577-601`, `src/menu.inc` (`MNROW0`) — the three default hosts of `fnconfig.tmpl.ini` |
| `browse-root`, `browse`, `browse-menu` | 7 | `src/browse.asm:644-673` — the real listing of `apps.irata.online` (`make library`), sorted folders first as `fnDirCache.cpp`; hint shown as SEL=MENU (errata C1) |
| `info` | 10 | `src/info.asm:147-154` — addresses invented |
| `boot`, `boot-fail` | 8 | `src/boot.asm:29-33, 255-257` — path tail-anchored to 12 columns |
| `copying`, `copied` | 9 | `src/copy.asm:38-42, 232-235` |
| `cb-conn`, `cb-wait`, `cb-play`, `cb-nonet`, `cb-left` | 17 | `fujinet-2600-combat/src/cbsess.inc:397-408` (rows from the `SAY` calls) |
| `dg-play`, `tn-play` | — | Dragster / Tennis paired screens (spare) |

## Captured in MAME (`images/screens/raw/`, scaled ×5 × ×3 by `tools/scale.py`)

| File | Section | Source |
|---|---|---|
| `bs-tables`, `bs-play2`, `bs-play4`, `bs-waiting`, `bs-layout` | 14, cover | `fujinet-battleship/atari2600/build/snap-*` |
| `th-0000`…`th-0016` | 13, cover | `fujinet-texasHoldEm/atari-2600/build/snap/a2600/` |
| `fz-card`, `fz-wait`, `fz-over` | 15, cover | `fujinet-fujitzee/atari2600/build/snap*/` |
| `mule-*` | 16, cover | `fujinet-multiplayer-mule/screenshots/atari-2600/` |
| `lobby` | 11 | `fujinet-lobby/atari-2600` layout image, offline (`tools/shots.sh lobby`) |
| `5cs-tables`, `5cs-table`, `5cs-purses`, `5cs-menu`, `5cs-banner` | 12 | live against 5card.carr-designs.com through fujinet-pc (`emu/5cs.lua`; it leaves the table properly) |
| `5cs-layout` | — | the 5 Card Stud layout ROM, offline (spare) |
| `bs-place` | 14 | live, "AI - 1 on 1" (`emu/bs.lua`) |
| `config-hosts` | 7 | live CONFIG against the running fujinet-pc (Thom's own host list — deliberately "a few more hosts filled in") |
| `combat-play`, `dodgem-play`, `dragster-play`, `tennis-play`, `vo-play` | 17 | offline local play (`emu/dragster.lua` for the finished Dragster run) |
| `combat-nonet`, `dragster-nonet`, `tennis-nonet`, `vo-nonet` | — | the real NO NETWORK / LOCAL PLAY screens (the book typesets Combat's) |

All new captures: `tools/shots.sh [name…|offline|live]`; logs in `build/shots/`.
MAME's TIA blends each frame with the last where they differ, so frames were
picked where moving objects have no half-tone edge.

Text-column screens are cropped to the column (`images/screens/raw/crops.txt`).

## To verify on a built Rev1 (see errata.md)

- The microSD card's orientation in the side slot (the book says printed side
  toward the back of the cartridge, contacts first).
- The lights through the shell's light holes: white/orange status, red power.
- That the cartridge's RESET button returns to CONFIG.
- Console-only power on a 2600 Jr and a 7800.
