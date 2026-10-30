# FujiNet 5200 — Programmer's Handbook

The FujiNet programming manual for the **Atari 5200**: the memory map and the
mailbox the console reaches by reads alone, the text display three ways,
living in 16K, the 6502 library and C with fujinet-lib, the controllers, ten
worked programs, the complete command reference for every device the adapter
answers and everything the cartridge itself does, display lists and players,
Battleship, 5 Card Stud and CONFIG, and the things that cost real time.

Every example is given twice: **6502 assembly** (ca65) and **C** (cc65,
fujinet-lib's `atari5200` target and MekkoGX's start-up code).

It is typeset after the 1982 *ATARI 5200 Owner's Manual* (archive.org item
`atari-5200-owners-manual-1982`; the scan is too big for this repository): a
small booklet on warm paper with a faint graph grid,
Helvetica throughout, numbered heads in blue-violet hung to the left of the
text, pictures in white panels on a lilac band, black key labels lettered in
the controller's own colours, a Troubleshooting Checklist of Symptom /
Probable Cause and Remedy between rules, and black covers with the rainbow
stripe.

## Building

Requires [Typst](https://typst.app) 0.14 or newer.

```sh
make            # -> fujinet-programmers-handbook-5200.pdf
make watch      # rebuild on save
make preview    # a PNG per page at 110 ppi, into preview/
make listings   # build all 20 programs (ca65, cc65)
make verify     # run each in MAME against the bench and check its screen
make shots      # verify, then refresh images/screens
make check      # examples build, commands carded, stranded lines, fonts
```

Fonts ship in `fonts/`: Helvetica (Regular, Bold, Oblique, Bold Oblique),
ITC Avant Garde Gothic (the round-zero "5200") and Source Code Pro. The book
compiles with `--ignore-system-fonts`.

## The bench

`make verify` needs MAME with the cartridge grafted in and a private
fujinet-pc, both described in Section 2:

```sh
bench/up.sh          # fujinet-pc (BoIP 9952, web 8052), the HTTP fixture
                     # (8768) and the netcat line server (8769)
bench/up.sh games    # ...and the Battleship and 5 Card Stud servers (8781, 8782)
emu/verify.sh        # 20 programs, PASS or FAIL each, into build/verify.txt
bench/down.sh
```

Ports and paths are in `bench/ports.env`; `bench/ports.sh` refuses to start on
a port something else holds. `emu/run.sh image.bin [script]` runs any image;
`emu/drive.lua` presses the controller's keys and stick on a timetable and
checks the screen.

## Layout

```
manual.typ            page setup, heads, the part list
lib.typ               the house style: page, heads, callouts, key labels,
                      code panels, pairs, figures, tables, cards, diagrams
parts/                one file per section and appendix
listings/common/      the bring-up's library and test programs, unchanged
listings/asm/         the assembly programs and their build.sh
listings/c/           the C programs, CONFIG's antic.c, and their build.sh
listings/battleship/  Battleship's 5200 layer (quoted, Appendix D)
listings/5cardstud/   5 Card Stud's 5200 layer
listings/config/      CONFIG's 5200 source
listings/fixtures/    the HTTP file, the netcat server, the SD card's files
images/screens/       MAME snapshots, three times size, hard pixels
emu/                  run.sh, verify.sh, the Lua harnesses
bench/                the private fujinet-pc and servers
tools/                snipcheck, cmdcheck, checkrom, widows, fontcheck,
                      mkfont, pngscale, shots
wiki/                 the wiki condensation
```

## Programs

| Program | Assembly | C | Checked for |
|---|---|---|---|
| hello | `common/hello.s` | `c/hello.c` | the cartridge's magic, the frame counter |
| first contact | `common/fujitest.s` | `c/acfg.c` | SSID, IP, ERR 0 |
| pads | `asm/pads.s` | `c/pads.c` | stick, both buttons, keypad, tone (driven) |
| netget | `asm/netget.s` | `c/netget.c` | the fixture's two lines |
| netcat | `asm/netcat.s` | `c/netcat.c` | the server's greeting and echo (typed) |
| dir | `asm/fujidir.s` | `c/dir.c` | the SD card's `/a5200book/` |
| boot | `common/fujiboot.s` | `c/boot.c` | the pushed hello running |
| appkey | `asm/appkey.s` | `c/appkey.c` | the player name, our key read back |
| clock | `asm/clock.s` | `c/clock.c` | local time and UTC |
| bank | `asm/bank.s` | `c/bank.c` | a transaction from each Super Cart bank |

## Sources of truth

| Repository | Path | Revision |
|---|---|---|
| fujinet-firmware | `pico/atari-5200`, `pico/common` | `7a53805c8` |
| fujinet-firmware | command dispatch, fujinet-pc | `f0b62cb09` |
| tschak909/fujinet-lib | `add-atari5200` (FujiNetWIFI/fujinet-lib PR 139) | `7cf47dc` |
| tschak909/MekkoGX | `add-atari5200` (FozzTexx/MekkoGX PR 27) | `faeb3fd` |
| fujinet-lib-experimental | `add-atari5200` (CONFIG and the games) | `7101377` |
| fujinet-config | `atari5200/` | `1bd6ec8` |
| fujinet-battleship | `src/atari5200/` | `3f2a548` |
| fujinet-5cardstud | `src/atari5200/` | `d5db857` |
| fujinet-game-system | the game servers | `19770c3` |
| cc65 | | V2.19 `92fa7cb23` |
