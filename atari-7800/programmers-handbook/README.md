# FujiNet 7800 ProSystem — Programmer's Handbook

The FujiNet programming manual for the **Atari 7800**: the memory map and the
mailbox, the text display three ways, living in 4K, the 6502 library, C with
fujinet-lib and 7800basic on the mailbox, eight worked programs in all three
languages, the complete command reference for every device the adapter
answers and everything the cartridge itself does, the tile engine, Battleship
and CONFIG, and the things that cost real time.

Every example is given three times: **6502 assembly** (ca65), **C** (cc65 and
fujinet-lib's `atari7800` target) and **7800basic**.

It is typeset after the 1986 *ATARI 7800 ProSystem Owner's Manual*: a small
booklet printed on graph paper, ITC Eras throughout, white titles in magenta
tabs, a magenta band across the foot of every page, square bullets, bold
**Note:** lead-ins, and a Troubleshooting Checklist of Symptom / Probable
Cause and Remedy.

## Building

Requires [Typst](https://typst.app) 0.14 or newer.

```sh
make            # -> fujinet-programmers-handbook-7800.pdf
make watch      # rebuild on save
make preview    # a PNG per page at 110 ppi, into preview/
make listings   # build all 24 programs (ca65, cc65, 7800basic)
make verify     # run each in MAME against fujinet-pc and check its screen
make shots      # verify, then refresh images/screens
make check      # examples build, commands carded, stranded lines, fonts
```

Fonts ship in `fonts/`: ITC Eras Std (Book, Medium, Demi, Bold, Ultra) and
Source Code Pro. The Eras files' OS/2 cap and x heights were wrong (half the
real glyphs), which set lines on top of each other; `tools/fixeras.py`
patched them in place. The book compiles with `--ignore-system-fonts`.

## Layout

```
manual.typ            the book: prelude and #include "parts/*.typ"
lib.typ               all helpers (tabs, callouts, cmd cards, trios, diagrams, excerpts)
parts/                one file per section and appendix
listings/common/      the cartridge bring-up's client library and programs, verbatim (ca65)
listings/asm/         the handbook's assembly programs, devdefs.inc, netdefs.inc, build.sh
listings/c/           the C programs, the tile engine (from CONFIG), the banked config, build.sh
listings/bas/         the 7800basic programs, fujinet.bas, fujilib.bas, fujifont.png, build.sh
listings/battleship/  fujinet-battleship's 7800 layer and shared game, verbatim
listings/fixtures/    hello.txt (served on 127.0.0.1:8765) and the SD card's files
listings/snippets/    scratch: every example in the text, as tools/snipcheck.py builds it
emu/                  run.sh, screen.lua, verify.sh, and the bring-up's harnesses
tools/                the generators and checks
images/screens/       every program's screen, captured from MAME at hard pixels
wiki/                 the GitHub-wiki edition
```

## The programs

All 24 were built and run in the FujiNet MAME cartridge model against a live
`fujinet-pc` (bus-over-IP on `127.0.0.1:9986`), and checked by `emu/verify.sh`:
`emu/screen.lua` walks MARIA's display-list list and every indirect object, so
one reader checks the text on screen in all three languages.

| Program | Assembly | C | 7800basic | Checked for |
|---|---|---|---|---|
| hello | `hello.s` (bring-up) | `hello.c` | `hello.bas` | the text, APP mode |
| first contact | `fujitest.s` (bring-up) | `acfg.c` | `acfg.bas` | SSID and IP |
| netget | `netget.s` | `netget.c` | `netget.bas` | the fixture's lines |
| directory | `fujidir.s` | `dir.c` | `dir.bas` | the SD folder's names |
| boot | `fujiboot.s` (bring-up) | `boot.c` | `boot.bas` | the booted program's screen |
| appkey | `appkey.s` | `appkey.c` | `appkey.bas` | the name, a key read back |
| clock | `clock.s` | `clock.c` | `clock.bas` | local and UTC |
| banks | `fujibank.s` (bring-up) | `bank.c` | `bank.bas` | a transaction from each bank |

### 7800basic

A 7800basic FujiNet program `incbasic`s `fujinet.bas` (the mailbox's names:
in BASIC a register's name is its address) and, after its main loop,
`fujilib.bas` (the transport as subroutines). `tools/basfix.py` stamps the
claim at `$FF70` after dasm and refuses read-modify-writes on the mailbox;
7800basic's `7800header` writes the `.a78`. Section 9 has the rules, including
two silent miscompiles (an expression in an array index, or in a `for` bound).

## Sources of truth

| Source | Path / repo | Revision |
|---|---|---|
| Cartridge: mailbox, loader, mappers, POKEY, HSC, testroms, MAME model | `fujinet-firmware` `pico/atari-7800`, `pico/common` | `07e9bbaa9` (origin/master) |
| Adapter dispatch | `fujinet-firmware` `lib/device/rs232`, `fujiDevice`, `NDevice`, `fujiClock` | `07e9bbaa9` |
| fujinet-pc on the bench | RS232 build | v1.6-5501c94a |
| fujinet-lib `atari7800` | `fujinet-lib-experimental` `add-atari7800` (PR #152) | `1ebf9d0` |
| CONFIG, tile engine | `fujinet-config` `atari7800/` | `f38ed1d` |
| Battleship | `fujinet-battleship` | `87b8cc7` |
| Battleship server | `fujinet-game-system/battleship` | `19770c3` |
| 7800basic | `7800-devtools/7800basic` | `e7c18d2` (v0.41), built natively |
| cc65 | `cc65/cc65` | 2.19, `92fa7cb23` |
| dasm | | 2.20.16 |
| MAME | `mame` + the grafted cartridge (`emu/apply.sh`) | `533800328a2` |
| Style reference | `../learn/atari-7800-prosystem.pdf` | — |
