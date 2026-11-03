# FujiNet 5200 — Owner's Manual

The user's book for the **FujiNet Atari 5200 cartridge**: what is in the box,
the cartridge's lights, buttons and sockets, a short picture-book account of
how a console that can only *read* a cartridge gets on the network, putting it
in and powering it, the controller in the FujiNet menu (with a keypad
overlay), WiFi and the on-screen keyboard, hosts and the browser, loading
games and which kinds load, copying, INFO and the web control panel, the Game
Lobby, the six FujiNet network games (5 Card Stud, Texas Hold'em, Battleship,
Fujitzee, Fujirkle, M.U.L.E.), maintenance, a Troubleshooting Checklist and a
Parts List, with a record page and a Quick Reference at the back.

It covers the same ground as the [2600 Owner's Manual](../../atari-2600/owners-manual/),
and leaves the technical material to the
[Programmer's Handbook](../programmers-handbook/).

It is typeset after the 1982 *ATARI 5200 Owner's Manual* (archive.org item
`atari-5200-owners-manual-1982`; the scan is too big for this repository),
in the house style the Programmer's Handbook already sets: a 5 × 7 in booklet
on warm paper with a faint graph grid, Helvetica throughout, numbered heads in
blue-violet hung to the left of the text, pictures on lilac bands, bold step
numerals, black key labels lettered in the controller's colours, a keypad
overlay, a Symptom / Probable Cause and Remedy checklist, and black covers
with the rainbow stripe.

## Building

Requires [Typst](https://typst.app) 0.14 or newer.

```sh
make            # -> fujinet-owners-manual-5200.pdf
make watch      # rebuild on save
make preview    # a PNG per page at 110 ppi, into preview/
make check      # quoted screen words in the sources, stranded lines, fonts, pages % 4
make images     # re-render the cartridge, console and controller (numpy, Pillow, git)
make shots      # re-capture every screen (MAME, fujinet-pc, Go, the network)
make library    # list the online folders the book names (TNFS)
make check-library
make wiki       # rebuild the wiki edition's images
```

The book compiles with `--ignore-system-fonts`.

## Fonts

| Font | Use | Source |
|---|---|---|
| Helvetica (Regular, Bold, Oblique, Bold Oblique) | everything | vendored, as the Programmer's Handbook |
| ITC Avant Garde Gothic | the round-zero "5200", the How It Works numerals | same |
| Source Code Pro | file names, `fnconfig.ini` | SIL OFL |

## Pictures

Nothing is photographed; see [FIGURES.md](FIGURES.md).

- **The cartridge** has no shell yet. `tools/make_cart.py` draws the book's
  own round the Rev0 board's anchor file
  (`fujinet-hardware/ATARI-5200/FujiNet-5200-Rev0/case/board-anchors.scad`,
  read with `git show`, nothing written there): the T-shaped outline 3 mm out,
  the RESET button and three service pinholes, the two lights, the label
  recess, the USB-C socket and microSD slot in the top edge.
- **The console and the controller** are parametric (`tools/make_a5200.py`):
  a CX5200 four-port with its silver band, slot, vents, storage lid, POWER
  switch and numbered jacks, and a CX52 with its keypad, START / PAUSE /
  RESET, stick and two buttons a side.
- `tools/views.py` names every view and runs `tools/stl2png.py` (from the 2600
  book, taught to report where named model points land), so `figs.typ` hangs
  each label's leader on the part it names.
- **Screens** are MAME captures of CONFIG and the games on the FujiNet
  cartridge model (`~/Workspace/mame-a5200`), walked by `emu/walk.lua`, which
  waits for each screen's own words before the next key and checks the screen
  before its snapshot. `emu/bench.sh` runs the book's own fujinet-pc (BoIP
  9953, web 8053, run dir `~/Workspace/fnpc-5200-owners`, reset to
  `fnconfig.book.ini` at every start) and the five game servers on 8791–8795,
  built from FujiNetWIFI/servers `origin/main`. Never the public servers.

## Intended behaviour, and errata.md

The book describes the cartridge **as it is meant to work**. Where today's
sources do something else — a stick the CONFIG start-up never turns on, a
Lobby not yet built, two game ports not yet committed — the difference is
listed in [errata.md](errata.md) with the file and line.

## Sources of truth

| Source | Repo / path | Revision |
|---|---|---|
| CONFIG | `fujinet-config/atari5200` | `cb44218` |
| Cartridge firmware, formats, MAME device | `fujinet-firmware/pico/atari-5200` | `7a53805c8` (origin/master `f703133d0`) |
| Adapter firmware (hosts, web panel, `fnconfig.ini`) | `fujinet-firmware` | `f703133d0` |
| Hardware, Rev0 | `fujinet-hardware/ATARI-5200/FujiNet-5200-Rev0` | `1e04ba8` |
| 5 Card Stud | `fujinet-5cardstud` (5200 port `fcs-5200`, merged as `6b2d7e2`) | `344701c` |
| Texas Hold'em | `th-5200` worktree, uncommitted | `a7b2a80` + changes |
| Battleship | `fujinet-battleship` (`bs-5200`, merged as `578a120`) | `297a4d4` |
| Fujitzee | `fujinet-fujitzee` (`fz-5200`, merged as `3aa131f`) | `e78273a` |
| Fujirkle | `fk-5200` worktree, uncommitted | `678f8b0` + changes |
| M.U.L.E. | `fujinet-multiplayer-mule/clients/mekkogx/src/atari5200` | `bfa3569` (local) |
| Game servers | FujiNetWIFI/servers `fujinet-game-system` | `0945622` |
| MAME with the FujiNet cartridge | `mame-a5200` | `533800328a2` |
| Online library | `apps.irata.online` (TNFS), listed 2026-10-30 | — |
| Style reference | `../learn/atari-5200-owners-manual-1982/` | — |

FujiNet is not affiliated with Atari. "Atari" and "5200" are trademarks of
their owner; "M.U.L.E." is a trademark of its owner.
