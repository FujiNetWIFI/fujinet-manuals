# FujiNet Studio II Programmer's Handbook

A programmer's handbook for the FujiNet cartridge for the RCA Studio II: how a
CDP1802 program reaches the network through the cartridge's mailbox, every
command the FujiNet answers with an 1802 example, a dozen verified programs
(netcat among them), and chapters on Battleship, 5 Card Stud and CONFIG.

No cartridge has been built yet. Every program here runs in the FujiNet MAME
model of the cartridge, which compiles the cartridge's own firmware sources,
against a `fujinet-pc` built from the same firmware revision.

## House style

The 1977 RCA Studio II Owner's Manual (`../learn/Owners_Manual.pdf`): a
landscape booklet, 10 x 7.56 in, on off-white paper with one spot colour, RCA
gold. Helvetica throughout; every "Studio II" in Bodoni italic, the console's
wordmark. Big gold heads hung in the first of three columns, game chapters
opened with a row of television screens, gold figure panels with black
callouts, NOTE: and IMPORTANT: in gold capitals. The reference chapters, the
checklist and the appendices draw the same grid on single-column pages.

## Building

```sh
make                 # fujinet-programmers-handbook-studio2.pdf
make preview         # preview/pNN.png
make sheet           # preview/sheet/: the pages twelve to a sheet
make listings        # assemble every program (listings/asm/build/)
make games           # CONFIG, 5 Card Stud and Battleship, against the bench
make bench           # start the bench (bench/up.sh); make bench-down stops it
make verify          # run every program in MAME and check its screen
make verify-games    # Battleship and 5 Card Stud end to end (real time)
make shots           # snapshots -> images/screens/
make check           # the checks below
```

Fonts are vendored in `fonts/`: Helvetica (Regular, Bold, Oblique, Bold
Oblique) and Adobe Bodoni Std (Book, Book Italic, Italic, Bold Italic) from
font.download, and Source Code Pro. The book compiles with
`--font-path fonts --ignore-system-fonts`.

## The bench

`bench/ports.env` names the ports, clear of the other rigs on this computer:
BoIP 9973, web 8073, the HTTP fixture 8766, the netcat line server 8767, the
Battleship and 5 Card Stud servers 8771 and 8772. `bench/up.sh` starts
`fujinet-pc` (`~/Workspace/fnpc-studio2-book`, its own copy with a config of
its own), the HTTP fixture and the line server; `bench/up.sh games` adds the
two game servers, built from `~/Workspace/servers` and run with `GO_PROD`
unset so they never tell the public lobby. `bench/down.sh` stops them by pid.

MAME is the `studio2` single-driver build with the cartridge grafted in by the
firmware's `pico/studio2/emu/apply.sh`; `emu/run.sh` runs
`~/Workspace/mame-studio2/studio2-s2book`.

## Programs

| Program | Does | Checked for |
|---|---|---|
| hello | text, symbols, the frame count, a key | HELLO STUDIO II, FRAME |
| fujitest | GET_ADAPTERCONFIG_EXTENDED | SEQ 01, ERR 00, Dummy Cafe, 127.0.0.1 |
| netget | an HTTP GET through the N: device | the file's lines, CLOSED |
| fujidir | a directory on the SD card | hello.st2, netget.st2, readme.txt |
| fujiboot | mount an image and hand over | the booted program's text, one swap |
| appkey | the shared name, and a key of our own | PLAYER 1, HELLO STUDIO II |
| clock | SETTZ, then local time and UTC | LOCAL, UTC |
| keys | both keypads and the beeper | the pressed keys lit, B9 |
| glyphs | GLYPH, TILE, MOSAIC, REPEAT, inverse | the glyph codes, a mosaic cell, inverse |
| pages | one program on fourteen pages | 0C, 14, D4, ALL OK |
| netcat | a TCP line terminal with a keyboard | greeting, typed line echoed, back to CONFIG |

`hello`, `fujitest` and `fujiboot` are the cartridge bring-up's, unchanged.

## Checks

| Check | Holds the book to |
|---|---|
| `tools/snipcheck.py` | every 1802 example in the text assembles, passes checkrom and packs |
| `tools/cmdcheck.py` | every command the firmware dispatches has a card |
| `tools/cartcheck.py` | every cartridge register, status field, text operation and symbol is in "The Cartridge Itself" |
| `tools/defcheck.py` | `s2defs.inc`'s equates agree with the firmware's headers |
| `tools/vendorcheck.py` | every vendored file, and `osk.inc`'s copied blocks, match their pins |
| `tools/linelen.py` | the handbook's own sources fit a column (52 characters) |
| `tools/fitcheck.py` | every FIT covers its routine |
| `tools/widows3.py` | no stranded head, widow or orphan, column by column |
| `tools/fontcheck.py --wordmark` | no fallback font, and Bodoni only for the wordmark |

## Sources of truth

| What | Where | Revision |
|---|---|---|
| Cartridge firmware, runtime, tools, MAME model | fujinet-firmware `pico/studio2`, `pico/common` | 07e9bbaa9 |
| Adapter firmware (fujinet-pc on the bench) | fujinet-firmware, RS232 build | 07e9bbaa9 |
| CONFIG | fujinet-config `studio2/` | 86c763d |
| 5 Card Stud | fujinet-5cardstud `studio2/` | 1008f9a |
| Battleship | fujinet-battleship `studio2/` | 87b8cc7 |
| Game servers | servers `fujinet-game-system` | 19770c3 |
| Board | fujinet-hardware `RCA-Studio-II/FujiNet-StudioII-Rev0` | 0e539b8 |
| MAME | mame-studio2 + the graft | 533800328a2 |
| Macroassembler AS | | 1.42 Beta, build 306 |
| Typst | | 0.14.2 |

`listings/VENDOR` lists every vendored file and its pin.
