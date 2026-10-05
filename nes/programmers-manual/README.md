# FujiNet Programmer's Manual for the NES

A programmer's manual for the FujiNet NES cartridge: the cartridge mailbox at
`$5000`, the network, Fuji and clock devices, booting images, the NES-side
libraries, walkthroughs of the four FujiNet games ported to the NES and of
CONFIG, and a network terminal (netcat). Every example is given in 6502
assembly (ca65) and in C (cc65 + fujinet-lib).

House style: the 1985 Nintendo *Gyromite* instruction booklet. It's a 7.5×5.75 in landscape page with
white paper and one spot colour (`#FBB408`). Heads are Helvetica Bold Oblique capitals and the body is
Univers LT Std. The manual uses CAUTION highlights, thin rule boxes, a starfield cover with a tilted
cyan wordmark, and folios at the bottom corner (even pages on the right, odd on the left).

Output: `fujinet-programmers-manual-nes.pdf`. Wiki edition: `wiki/FujiNet-Programming-Guide-for-the-NES.md`.

## Building

```sh
make              # the PDF (Typst 0.15, --font-path fonts --ignore-system-fonts)
make listings     # every program in listings/ (cc65 2.19, fujinet-lib-experimental add-nes)
make check        # snippets build, every dispatched command has a card, widows, no fallback fonts
make preview      # PNG pages in preview/
make sheet        # a contact sheet of every page
```

`make check` runs three tools:

- `tools/snipcheck.py` builds every `asm:`/`c:`/`#pair` snippet in `parts/` inside a skeleton.
  Assembly snippets go through ca65, ld65 and checkrom; C snippets go through cl65 and fujinet-lib.
- `tools/cmdcheck.py` reads the firmware's dispatch tables and requires every command number in its chapter.
- `tools/widows.py` is a pdftotext heuristic that flags stranded lines.

## Running the programs

`emu/run.sh <rom> <name>` runs a ROM in the grafted MAME (`~/Workspace/mame`, with `pico/nes/emu/apply.sh`
applied). It runs against fujinet-pc's BoIP on 127.0.0.1:9995, prints the screen as text and saves
`images/screens/<name>.png`.

- `SCRIPT=$PWD/emu/drive.lua DRIVE="w3 Start A Right*7 Reset w2"` presses buttons on a script.
- The `netget`/`json` examples need the fixtures served: `cd listings/fixture && python3 -m http.server 8765`.
- The netcat test needs `python3 emu/echo.py 7777`, with netcat built using `-DDEFAULT_URL='"N:TCP://127.0.0.1:7777/"'`.
- `boot` loads `/nesbook/hello.bin` from the FujiNet's SD (host slot 1). Copy `listings/build/c/hello.nes` there under that name.
  The fujinet-pc used predates the `.nes` media-type commit, hence `.bin`.

## Sources of truth

| Repository | Branch | Commit | Used for |
|---|---|---|---|
| fn-nes (fujinet-firmware) | nes-bringup | 6c7b031c4 | mailbox (`pico/nes/firmware/include/fuji_mailbox.h`, `fujimail.c`), loader, testrom `fujilib.s`, dispatch tables (`lib/device/*`) |
| fujinet-lib-experimental | add-nes | a9c7667 | NES bus, `fujinet-nes.h`, linker config, romstamp |
| fujinet-config (fn-config-nes) | nes-family-basic | cd33413 | CONFIG (`nes/`) |
| fujinet-5cardstud | main | 7333b1b | game, `src/nes` |
| fujinet-battleship | add-nes | 9de5ef6 + **uncommitted working tree** | game, `src/nes` |
| fujinet-fujitzee | main | 46b0dfa | game, `src/nes` |
| fujinet-texasHoldEm | add-nes | 3e00a1c | game, `src/nes` |
| fujinet-go-nes-desktop | main | 13bd885 | FujiNet Go NES Desktop |
| servers (fujinet-game-system) | main | 19770c3 | game servers |

The files quoted are snapshots in `listings/games/`, `listings/config/` and `listings/lib/`.
`listings/common/fujinet.inc`, `fujilib.s`, `nesinit.s`, `fujidisp.s`, `loader.s` and `checkrom.py`
are verbatim copies from `fn-nes/pico/nes`. Re-copy them, and re-check the callout patterns in
`parts/apx-c.typ`, if the sources change. A callout whose text has gone fails the build.

## Layout

- `manual.typ` holds the page and type setup and the `#include`s.
- `lib.typ` holds the helpers: `cmd` cards, `pair`, `codepanel`, `code-listing` with text-keyed callouts,
  `memmap`, `seq`, `caution`/`note`/`objbox`, `controller`, `shot`.
- `parts/` holds the front matter, chapters 1-16, appendices A-D and the back matter.
- `fonts/` holds vendored fonts: Univers LT Std, Helvetica, Helvetica Neue Black, Apple Garamond Light Italic
  and Source Code Pro.
- `images/` holds the generated starfields (`tools/make_starfield.py`) and `screens/` (MAME snapshots).
- `listings/` holds the programs (`asm/`, `c/`, `netcat/`, `common/`) and the source snapshots.
