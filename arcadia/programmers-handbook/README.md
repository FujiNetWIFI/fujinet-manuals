# FujiNet Arcadia 2001 — Programmer's Handbook

The FujiNet programming manual for the **Emerson ARCADIA-2001**: the memory
map and the mailbox the console reaches by reads alone, the 2637's text
display, living in 288 bytes, the 2650 library and the 2650's 8K pages, the
hand controllers and the tone, eleven worked programs (a NetCat among them),
the complete command reference for every device the adapter answers and
everything the cartridge itself does, programs bigger than 8K (protocol 2),
the 2637 up close, Battleship, 5 Card Stud and CONFIG, and the things that
cost real time.

Every example is **2650 assembly** (Macroassembler AS): no compiler has ever
targeted the Arcadia.

No cartridge has been built yet. Every program here runs on the FujiNet MAME
model of the cartridge, which compiles the cartridge's own firmware sources,
against a fujinet-pc built from the same firmware.

## Style

The Arcadia Owner's Manual's (`../owners-manual/`), after the 1982 Emerson
*ARCADIA-2001 Owner's Manual* (ADV-1) and the Emerson game booklets in
`../learn/`: letter pages in black ink, Helvetica, numbered bold-caps heads,
"— n —" folios, Fig. N captions, CAUTION and NOTE lines, a ruled Trouble
Shooting Check List; NetCat, Battleship, 5 Card Stud and CONFIG set as game
booklets (VIDEO GAME INSTRUCTIONS band, roman heads, an OVERLAY card); screens
in TV outlines, the only colour. A programmer's book adds code panels in
Source Code Pro, command cards hung on a narrow left column, memory maps, byte
strips and a sequence diagram.

## Building

Requires [Typst](https://typst.app) 0.14 or newer.

```sh
make                 # fujinet-programmers-handbook-arcadia.pdf
make preview         # preview/pNN.png
make listings        # assemble every program (listings/asm/build/)
make bench           # start the bench; make bench-games adds the game servers
make verify          # run every program in MAME and check its screen
make verify-games    # Battleship, 5 Card Stud and CONFIG end to end
make shots           # snapshots -> images/screens/
make check           # the checks below
```

Fonts are vendored in `fonts/`: Helvetica (Regular, Bold, Oblique, Bold
Oblique), Harry Obese (the ARCADIA-2001 lettering) and Nimbus Sans Narrow Bold
from the Owner's Manual, and Source Code Pro. The book compiles with
`--font-path fonts --ignore-system-fonts`.

## The bench

`bench/ports.env` names the ports, clear of the other rigs: BoIP 9963, web
8063, the HTTP fixture 8790, the netcat line server 8791, the Battleship and
5 Card Stud servers 8792 and 8793. `bench/up.sh` refuses a port something else
holds, resets fujinet-pc (`~/Workspace/fnpc-arcadia-book`, its own copy, a
token-free `fnconfig.book.ini`) and its memory card (`listings/fixtures/sd` and
the built programs), and starts it with the fixture and the line server;
`bench/up.sh games` adds the game servers, built from FujiNetWIFI/servers at
the pin with `GO_PROD` unset. `bench/down.sh` stops everything by pid.

MAME is `~/Workspace/mame` with the cartridge grafted in by the firmware's
`pico/arcadia/emu/apply.sh`; `emu/run.sh image.bin` runs one, and with `SNAP=`,
`STEPS=` and `WANT=` set `emu/walk.lua` drives it headless, counting frames.
Anything that talks to a live server runs with `THROTTLE=1`.

## Programs

| Program | Source | Checked for |
|---|---|---|
| hello | runtime | the 64 glyphs, HELLO FUJINET |
| fujitest | runtime | DUMMY CAFE, the version, 127.0.0.1 |
| pads | `asm/pads.asm` | LAST KEY 5, LAST DISC UP, LAST START (driven) |
| netget | `asm/netget.asm` | the fixture's three lines, CLOSED |
| netcat | `asm/netcat.asm` | the greeting, then HI typed on the wheel, sent and echoed |
| fujidir | `asm/fujidir.asm` | the book's programs on the memory card, CLOSED |
| fujiboot | runtime | hello.bin booted through the swap |
| appkey | `asm/appkey.asm` | PLAYER 1, HELLO ARCADIA read back |
| clock | `asm/clock.asm` | LOCAL, UTC |
| sprites | `asm/sprites.asm` | SPRITE HIT and BOX HIT: both collision registers |
| fujibank | runtime | the firmware's bankprobe.lua: pages, cart RAM, the tick |

`hello`, `fujitest`, `fujiboot` and `fujibank` are the cartridge bring-up's,
unchanged, and build byte for byte as the firmware's `build.sh` builds them.
`emu/games.sh` walks CONFIG (hosts, the memory card), 5 Card Stud (the tables,
a hand) and Battleship (placement, a shot answered), built from their pins by
`listings/games.sh`, which also checks CONFIG against the firmware's baked
image byte for byte.

## Checks

| Check | Holds the book to |
|---|---|
| `tools/snipcheck.py` | every 2650 example in the text assembles inside a program and builds an image |
| `tools/cmdcheck.py` | every command the adapter dispatches has a card or a NAK entry |
| `tools/cartcheck.py` | every FN_R_, FN_H_, FN_REG_, FN_HOT_, FN_BOOT_ name is in Section 20 |
| `tools/defcheck.py` | `fujilib.inc`'s and `bookdefs.inc`'s equates agree with the firmware's headers |
| `tools/vendorcheck.py` | every vendored file matches its pin |
| `tools/depthcheck.py` | no program deeper than the 2650's 8 return addresses, counting branches and fall-through |
| `tools/widows.py` | no stranded head, widow or orphan |
| `tools/fontcheck.py` | no fallback font |

## Sources of truth

| What | Where | Revision |
|---|---|---|
| Cartridge firmware, runtime, tools, MAME device | fujinet-firmware `pico/arcadia`, `pico/common` | `e3923e881` (arcadia last changed `193d18f53`) |
| Adapter dispatch (cmdcheck) | fujinet-firmware RS-232 build | `e3923e881` |
| fujinet-pc on the bench | the Owner's Manual's build | `v1.6-f0b62cb09` (dispatch unchanged to `e3923e881`) |
| CONFIG | fujinet-config `arcadia/` | `6f0a60a` |
| Battleship | fujinet-battleship `arcadia/` | `3f2a548` |
| 5 Card Stud | fujinet-5cardstud `arcadia/` | `d5db857` |
| Game servers | FujiNetWIFI/servers `fujinet-game-system` | `0945622` |
| MAME | `~/Workspace/mame` + the graft | `533800328a2` |
| Macroassembler AS | | 1.42 Beta, build 306 |
| Typst | | 0.14.2 |

`listings/VENDOR` lists every vendored file and its pin. Three CONFIG screens
(booting, the character grid, INFO) are the Owner's Manual's, from the same
CONFIG revision; every other screen was captured on this book's bench.

FujiNet is not affiliated with Emerson. "Emerson" and "Arcadia 2001" are
trademarks of their owners; "M.U.L.E." is a trademark of its owner.
