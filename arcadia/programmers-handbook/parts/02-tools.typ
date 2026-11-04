#import "../lib.typ": *

= Install the Tools <tools>

A FujiNet program for the Arcadia is an 8,192-byte cartridge image: the
two 4K blocks the console’s slot shows, with the mailbox in the top of the
second. Four tools make and run one: an assembler, three Python scripts,
MAME with the FujiNet cartridge grafted in, and a FujiNet to talk to.

== The assembler

Every program in this handbook is written for the Macroassembler AS by
Alfred Arnold, which knows the 2650 as `CPU 2650`. Build it from its source
(the `Macroassembler-AS/asl-releases` repository) or take a package; the
handbook was checked with version 1.42, build 306.

#steps(
  [Unpack AS and run its `make`. Keep `asl` and `p2bin` together; the build
   scripts look on your `PATH` first, then in `~/asl/`.],
  [AS assembles a program to a `.p` file of address-tagged records. `p2bin`
   turns that into a flat binary, and the cartridge’s `mkimage.py` folds the
   flat into the image (below).],
)

#important[Give a macro’s arguments their own parentheses inside the
macro: `(adr)>>8`, never `adr>>8`. AS substitutes the text, so an argument
of `TABLE+2` becomes `TABLE+2>>8` and shifts the 2.]

== The Python tools

Three scripts from the cartridge’s firmware come with the listings, in
`listings/runtime/tools/`, and every build runs them:

#partlist(
  ([mkimage.py], [Folds the `$0000-$2FFF` flat that `p2bin` writes into
   the cartridge image: CPU `$0000-$0FFF` is image `0x0000`, CPU
   `$2000-$2FFF` is image `0x1000`. It refuses code in the `$1000-$1FFF` hole
   (the console’s own RAM and video chip) and in the mailbox,
   `$2B00-$2FFF`.]),
  ([checkrom.py], [Checks the image: 8,192 bytes (or the protocol 2 sizes of
   Section 15), the `BCTA` header at `$0000`, the `RETC` guard at `$0003`,
   nothing in the mailbox but the claim, and the claim itself.]),
  ([checkdepth.py], [Bounds the depth of the program’s subroutine calls:
   the 2650’s return stack is eight deep and on the chip, and a ninth call
   overwrites the first return address without a word (Section 7).]),
)

The handbook adds a stricter fourth, `tools/depthcheck.py`, which also
follows branches and fall-through into a routine’s own labels; Section 7
shows what the firmware’s script misses. They need Python 3 and nothing
else.

== MAME and the cartridge

The cartridge you will use is MAME’s. The firmware carries a model of it,
`pico/arcadia/emu/`, which compiles the cartridge’s own C sources -- the
mailbox, the image store, the bus decode -- into MAME’s `arcadia` driver.

#steps(
  [Check out MAME and the FujiNet firmware.],
  [Graft the cartridge in: `pico/arcadia/emu/apply.sh ~/Workspace/mame`. It
   copies the device and the firmware’s sources into
   `src/devices/bus/arcadia/`, adds the device to the bus, and the option
   `fujinet` to the cartridge slot.],
  [Build MAME: `make -j$(nproc) REGENIE=1`. A build of the Arcadia alone is
   quicker: add `SUBTARGET=arcadia SOURCES=src/mame/arcadia/arcadia.cpp`.],
)

The `arcadia` driver needs no BIOS: the console has none. The cartridge
serves the image named on the command line, and `FUJINET_TCP` says where
the FujiNet is:

```
FUJINET_TCP=127.0.0.1:9963 ./mame arcadia -cartslot fujinet -cart hello.bin
```

== The FujiNet

The network chip runs the FujiNet firmware’s `fujiversal-arcadia` build, an
RS-232 build (`BUILD_RS232`) that speaks to the game chip over USB. On a computer the
same build runs as `fujinet-pc`, and MAME reaches it over _bus-over-IP_
(BoIP), a TCP connection in place of the USB cable inside the cartridge.

#steps(
  [Build it from the firmware: `./build.sh -p RS232`. The result is in
   `build/dist/`.],
  [Copy `fujinet`, `run-fujinet` and `data/` to a folder of their own, with
   an `SD/` folder beside them for the memory card.],
  [Give it an `fnconfig.ini` with BoIP on: `[BOIP]`, `enabled=1`,
   `host=localhost` and a `port=` nothing else on your computer uses.],
  [Start it: `./run-fujinet -u http://127.0.0.1:8063 -c fnconfig.ini -s SD`.
   The page at that address is the adapter’s web control panel, as on any
   FujiNet.],
)

#important[Always set `FUJINET_TCP` when you start MAME. Unset, the
cartridge tries `127.0.0.1:9995`, and on a computer with other FujiNet rigs
that port may be one of theirs. Only one MAME may talk to a fujinet-pc at a
time.]

== The handbook’s bench

The handbook keeps its whole bench in one place. `bench/ports.env` names its
ports; `bench/up.sh` refuses any of them that something else holds, then
starts fujinet-pc on BoIP 9963 (web page on 8063) with a fresh copy of the
book’s memory card, a small web server for the network chapter’s test file
(8790), and the line server the netcat talks to (8791). `bench/up.sh games`
adds the Battleship and 5 Card Stud servers (8792, 8793), built from the
FujiNet game servers with production mode off, so they never tell the public
Lobby. `bench/down.sh` stops them all.

#tbl((1.45in, 1fr),
  [*Command*], [*Does*],
  [`make listings`], [assembles every program into `listings/asm/build/`],
  [`make verify`], [runs each one in MAME against the bench and checks its screen],
  [`make shots`], [refreshes the screens in this book from the last runs],
  [`make check`], [checks the book against its sources (Section 26)],
)

== Running a program

`emu/run.sh` starts MAME with a program in the cartridge, in a window:

```
emu/run.sh listings/asm/build/netget.bin
```

With `SNAP=` set it runs with no window and `emu/walk.lua` drives it:
`STEPS=` is a list of things to wait for and keys to press, `WANT=` the
words that must be on the screen at the end. That is how `emu/verify.sh`
checks every program.

#tbl((1.3in, 1.6in, 1fr),
  [*Console*], [*MAME’s key*], [*Note*],
  [Left keypad], [the numeric pad], [CLEAR is the pad’s `-`, ENTER its `+`],
  [Left disc], [the arrows], [read as a pot; Section 9],
  [Action buttons], [the pad’s 2], [one wire with the keypad’s 2],
  [Right keypad], [Z X C, A S D, Q W E, V F R], [1 2 3 on Z X C: the keypad upside down],
  [START, SELECT, OPTION], [1, 5, O], [RESET is not wired in MAME’s driver],
)

#note[MAME’s second disc takes R, F, D and G, which are also keys of the
right keypad. Give one of them other keys in MAME’s input menu (Tab) before
you test a two-player program.]

== On a real console

When the cartridge exists, a program travels the way every FujiNet program
does: copy the `.bin` to the FujiNet’s memory card or a TNFS server, choose it
in CONFIG, and CONFIG mounts it and hands the console over (Section 13). To
come back to CONFIG, press the cartridge’s own RESET, then the console’s.
