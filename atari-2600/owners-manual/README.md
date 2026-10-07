# FujiNet Video Computer System — Owner's Manual

The user's book for the **FujiNet Atari 2600 cartridge**: what is in the box,
the cartridge's lights and buttons, a short picture-book account of how a
console with 128 bytes of RAM gets on the network, setting up WiFi with a
joystick, hosts and the browser, loading games from the Internet, the memory
card or your own file server, copying, the web control panel, the Game Lobby,
the five FujiNet network games (5 Card Stud, Texas Hold'em, Battleship,
Fujitzee, M.U.L.E.), the five classics being taught to play over the network
(Combat, Dodge 'Em, Dragster, Tennis, Video Olympics), maintenance, a trouble
shooting checklist and a parts list.

The technical material is not repeated here; the book points to the
[Programmer's Handbook](../programmers-handbook/) and the
[Theory of Operation](../theory-of-operation/).

It is typeset after the 1977 *Video Computer System Owner's Manual*
(`../learn/`): a half-letter booklet, Helvetica, numbered colour section bands
with a big **Harry Fat** numeral in the band's own colour at the outer edge of
the page (the colours eyedropped from the scan, in the booklet's own order,
with the checklist and the parts list in plum and magenta), black cover with a
white-framed picture, bold NOTE / IMPORTANT paragraphs between thin blue rules,
lettered steps, leader-line labels on line art, a SYMPTOM / PROBABLE CAUSE AND
REMEDY table, a Parts List and a black back cover. Sections run on one under
another, as the booklet's 6, 7 and 8 do.

## Building

Requires [Typst](https://typst.app) 0.15 or newer.

```sh
make            # -> fujinet-owners-manual-2600.pdf
make watch      # rebuild on save
make preview    # a PNG per page at 110 ppi, into preview/
make check      # stranded lines, fallback fonts, TV screens fit 12x21, pages % 4
make images     # re-render the cartridge and console art (OpenSCAD, numpy, Pillow)
make shots      # re-capture the MAME screens, then scale them to TV shape
make library    # list the online library the book names (TNFS, needs the network)
make wiki       # rebuild the wiki edition's images
```

The book compiles with `--ignore-system-fonts`, because the system's Harry
family carries two cuts at the same weight.

## Fonts

| Font | Use | Source |
|---|---|---|
| Helvetica, Helvetica Bold | body, heads, bands | vendored (as the Programmer's Handbook) |
| Nimbus Sans Italic | emphasis (Helvetica has no oblique here) | URW, GPL |
| Harry Fat | the cover wordmark and the section numerals | Thom's licensed copy |
| Source Code Pro | file names, `fnconfig.ini` | SIL OFL |
| VCS Screen | every typeset TV screen | generated from the cartridge's own 3×5 font table by `../programmers-handbook/tools/make_screen_font.py` |

## Pictures

Nothing is photographed; the hardware does not exist yet.

- **The cartridge** is the Rev1 cart shell
  (`fujinet-hardware/ATARI-2600/Fujiversal-Atari2600-Rev1/case/Fujiversal-Atari2600-CartShell.scad`,
  a re-model of norm8332's CC-BY "Easy Print" shell). `tools/cart_anchors.py`
  generates the shell's `board-anchors.scad` **into `build/`** from the
  hardware repo's placement table (importing `gen_pcb.py`, never running its
  `main()`), `tools/cartviews.scad` exports the halves in assembled position,
  `tools/make_cart_bits.py` stands it up and adds the label (lettering
  rasterised into geometry, so it foreshortens with the face), the lights,
  a USB-C plug and a microSD card.
- **The console** is a parametric CX2600 "heavy sixer"
  (`tools/make_vcs.py`): ribbed deck, wood fascia, six switches in the 1977
  order, the cartridge slot, the rear jacks with LEFT CONTROLLER on the
  player's left, and CX40-style joysticks.
- `tools/views.py` names every view (parts, colours, camera) and runs
  `tools/stl2png.py` (from `../../atari/owners_guide_400_800/tools/`) for the
  flat three-tone, black-outline look of the 1977 drawings.
- **Inside the cartridge** is the KiCad render `Rev1/docs/board-top.png` with
  its background removed (`tools/flatbg.py`).
- **TV screens** of CONFIG and the classics' status screens are typeset in
  VCS Screen from `screens/*.txt`, cell for cell from the source string tables
  and row equates, stretched 1.7× to the shape a TV gives a 2600 pixel.
- **Game screens** are MAME captures (`images/screens/raw/`, see
  `tools/shots.sh` and FIGURES.md), scaled ×5 by ×3 with hard pixels by
  `tools/scale.py`; text-column screens are cropped to the column
  (`images/screens/raw/crops.txt`) so they read in print.

## Intended behaviour, and errata.md

The book describes the cartridge **as it is meant to work**. Where today's
sources do something else — a hint that says SEL=UP, a WIFI FAILED screen that
ignores SELECT, a Lobby file not yet published — the difference is listed in
[errata.md](errata.md) with the file and line, to be fixed in the source.

## Sources of truth

| Source | Repo / path | Revision |
|---|---|---|
| Cartridge firmware, mailbox, MAME device | `fn-2600/pico/atari-2600` (`2600-experiment`) | `7432186c0` |
| Adapter firmware (formats, hosts, config) | `fn-2600` | `7432186c0` |
| CONFIG | `fujinet-config/atari-2600` | `ea103e0` |
| Game Lobby | `fujinet-lobby/atari-2600` | `d6df4e0` |
| Hardware, Rev1 | `fujinet-hardware/ATARI-2600/Fujiversal-Atari2600-Rev1` | `e26c9b4` |
| 5 Card Stud | `fujinet-5cardstud/atari-2600` | `7333b1b` |
| Texas Hold'em | `fujinet-texasHoldEm/atari-2600/build` (no committed source) | `31967e3` |
| Battleship | `fujinet-battleship/atari2600` | `92fda74` |
| Fujitzee | `fujinet-fujitzee/atari2600` | `46b0dfa` |
| M.U.L.E. | `fujinet-multiplayer-mule/clients/atari-2600` | `ea798b3` |
| Game rules | `servers/fujinet-game-system/*/server/gameLogic.go` | — |
| Combat · Dodge 'Em · Dragster · Tennis · Video Olympics | `fujinet-2600-{combat,dodgem,dragster,tennis,video-olympics}` | `40b4de1` · `3af4e19` · `cc16e9c` · `e158764` · `4f946ea` |
| fujinet-pc (captures) | `fujinet-pc-rs232` | `1c5dcb807` |
| Online library | `apps.irata.online` (TNFS), listed 2026-10-07 | — |
| Style reference | `../learn/Atari 2600 Manual ... (1977).pdf` | — |

FujiNet is not affiliated with Atari. "Atari", "Video Computer System",
"Combat", "Video Olympics" and "Dodge 'Em" are trademarks of their owners;
"Dragster" and "Tennis" are Activision titles; "M.U.L.E." is a trademark of
its owner.
