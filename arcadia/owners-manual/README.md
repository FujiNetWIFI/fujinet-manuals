# FujiNet Arcadia 2001 — Owner's Manual

The user's book for the **FujiNet cartridge for the Emerson ARCADIA-2001**:
- what is in the box;
- the cartridge's lights, buttons and sockets;
- a short picture-book account of how a console that can only *read* a
  cartridge gets on the network;
- putting it in and powering it;
- the hand controller in CONFIG, with a keyboard overlay;
- WiFi and the character grid, hosts and the browser;
- loading games and which kinds load, copying, INFO and the web control panel;
- the Game Lobby;
- every FujiNet program for the Arcadia, each in game-booklet form (5 Card
  Stud, Texas Hold'em, Battleship, Fujitzee, M.U.L.E.);
- the 48-game Cartridge Library, and FujiNet Go for those with no console;
- maintenance, a Trouble Shooting Check List and a Parts List;
- a record page and a Quick Reference at the back.

It covers the same ground as the [2600](../../atari-2600/owners-manual/) and
[5200](../../atari-5200/owners-manual/) Owner's Manuals.

## Style

It is typeset after the Emerson books in [`../learn/`](../learn/): the 1982
*ARCADIA-2001 Owner's Manual* (model ADV-1) for the frame, and the *Baseball*
and *Space Mission* instruction booklets for the game sections.

**The frame:**
- letter-size pages printed in black ink: Helvetica throughout, bold capital
  heads, no rules;
- numbered line drawings with leader lines and the "1) NAME / what it does"
  lists under them;
- CAUTION and NOTE lines, and folios centred between dashes;
- a ruled Trouble Shooting Check List of Symptom / Cause And Remedy;
- a cover after the ADV-1's: the ARCADIA-2001 lettering, the three bars, a
  television's outline with the product's name in condensed capitals, the
  console drawn over its corner, OWNER'S MANUAL and a model number along the
  foot. FujiNet's mark stands where Emerson's was.

**The game sections**, as the booklets set them:
- "VIDEO GAME INSTRUCTIONS" over a black title band, with the host and file
  where a booklet has CART. NO. and PART NO.;
- roman-numbered heads (I. GENERAL, II. OBJECT OF THE GAME ...) and
  double-spaced steps;
- a keyboard OVERLAY figure;
- screens in television outlines with leader-line callouts.

The screens are the only colour.

## Building

Requires [Typst](https://typst.app) 0.14 or newer.

```sh
make            # -> fujinet-owners-manual-arcadia.pdf
make watch      # rebuild on save
make preview    # a PNG per page at 110 ppi, into preview/
make check      # quoted screen words in the sources, stranded lines, fonts, pages % 4
make images     # re-render the cartridge, console and controllers (numpy, Pillow)
make src        # archive and build every Arcadia program the book shows, into build/src
make shots      # re-capture every screen (MAME, fujinet-pc, Go, asl, the network)
make library    # list the online folders the book names (TNFS)
make check-library
make wiki       # rebuild the wiki edition's images
```

The book compiles with `--ignore-system-fonts`.

## Fonts

| Font | Use | Source |
|---|---|---|
| Helvetica (Regular, Bold, Oblique, Bold Oblique) | everything | vendored, as the 5200 books |
| Harry Obese | the ARCADIA-2001 lettering, the How It Works numerals | Thom's licensed Harry family |
| Nimbus Sans Narrow Bold | the cover's condensed capitals | URW (gsfonts), AGPL with font exception |

## Pictures

Nothing is photographed; see [FIGURES.md](FIGURES.md).

- **The cartridge** has no shell yet. `tools/make_cart.py` draws the book's own
  round the Rev0 board's anchor file
  (`fujinet-hardware/Emerson-Arcadia/FujiNet-Arcadia-Rev0/case/board-anchors.scad`).
  That file is not committed in the hardware repo yet, so it is read from the
  working tree; nothing is written there. The drawing has:
  - the body 3 mm outside the board, and the bare 40 mm contact tab;
  - on the back (the parts face, toward the television): the RESET button,
    the three service pinholes and the two lights;
  - the label on the front;
  - the USB-C socket in the top edge and the microSD slot in the right side.
- **The console and its hand controllers** are parametric
  (`tools/make_arcadia.py`). Proportions come from the 1982 drawings; the ADV-1
  service manual gives only the PCB size. The console has:
  - two end wells and a centre deck with the slot, nameplate, RESET / SELECT /
    OPTION / START and POWER;
  - the rear jacks.

  The handsets have the 12-key keyboard, the disc, an Action button a side
  and coil cords.
- `tools/views.py` names every view and runs `tools/stl2png.py`, which reports
  where named model points land, so `figs.typ` hangs each label's leader on
  the part it names. Line-drawing tones: levels 0.82, 0.92, 1.0.
- **Screens** are MAME captures (`~/Workspace/mame`, its `arcadia` driver with
  the FujiNet cartridge device) of CONFIG and the games, walked by
  `emu/walk.lua`. It waits for each screen's own words before the next key and
  checks the screen before its snapshot. `tools/scrscale.py` scales each 9 × 5
  (MAME's 192 × 262 at 4:3).
  - **CONFIG** is fujinet-config main's `arcadia/`, built by `emu/getsrc.sh`
    and checked byte for byte against the image fujinet-firmware master bakes
    (`pico/arcadia/firmware/baked/fujiconfigrom.h`).
  - **The bench.** `emu/bench.sh` runs the book's own fujinet-pc (BoIP 9961,
    web 8061, run dir `~/Workspace/fnpc-arcadia-owners`, reset to
    `fnconfig.book.ini` at every start), the four game servers on 8781–8784
    (FujiNetWIFI/servers `origin/main`) and the Lobby's server on 8786
    (fujinet-lobby `origin/arcadia`). `emu/rooms.sh` gives the Lobby the real
    Lobby's Arcadia-able rooms. The games are bench copies built with
    `ENDPOINT=` the bench. Never the public servers; the only network reads
    are of `apps.irata.online` (TNFS, read-only).
  - **M.U.L.E.'s screens** are its own repo's (`screenshots/arcadia`).

## Intended behaviour, and errata.md

The book describes the cartridge **as it is meant to work**. Where today's
sources do something else, the difference is listed in
[errata.md](errata.md) with the file and line. Examples: a Lobby not yet
published, a game source never committed, a board not yet built.

## Sources of truth

| Source | Repo / path | Revision |
|---|---|---|
| CONFIG | `fujinet-config/arcadia` | main `6f0a60a` (arcadia/ from PR #308, `f9075b3`) |
| Cartridge firmware, formats, MAME device | `fujinet-firmware/pico/arcadia` | origin/master `e3923e881` (pico/arcadia last changed `193d18f53`, #2259) |
| Adapter firmware (hosts, web panel, `fnconfig.ini`) | `fujinet-firmware` | origin/master `e3923e881` |
| Hardware, Rev0 | `fujinet-hardware/Emerson-Arcadia/FujiNet-Arcadia-Rev0` | untracked on master `2022e39`; `board-anchors.scad` md5 `f2dd66c9` |
| Game Lobby | `fujinet-lobby` `arcadia/` and `server/` | origin/arcadia `b94520a` |
| 5 Card Stud | `fujinet-5cardstud/arcadia` | origin/main `d5db857` |
| Texas Hold'em | `fujinet-texasHoldEm/arcadia` (tschak909 fork) | origin/add-arcadia `84acc8f` |
| Battleship | `fujinet-battleship/arcadia` | origin/main `3f2a548` |
| Fujitzee | `fujinet-fujitzee/arcadia` | origin/main `03d5ee2` + `fujitzee.asm` from the working tree (md5 `59d8166d`; errata G1) |
| M.U.L.E. | `fujinet-multiplayer-mule/clients/arcadia`, `screenshots/arcadia` | `d11eae9` |
| Game servers | FujiNetWIFI/servers `fujinet-game-system` | `0945622` |
| FujiNet Go Arcadia 2001 Desktop | `fujinet-go-arcadia-desktop` | `v0.1.0` |
| MAME with the FujiNet cartridge | `~/Workspace/mame` | `533800328a2` |
| Online library | `apps.irata.online` (TNFS), listed 2026-11-03 | — |
| Style reference | `../learn/` | — |

FujiNet is not affiliated with Emerson. "Emerson" and "Arcadia 2001" are
trademarks of their owners; "M.U.L.E." is a trademark of its owner.
