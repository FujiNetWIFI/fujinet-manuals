#import "../lib.typ": *

= Install the Tools <tools>

A Studio II program for the FujiNet is a file of CDP1802 machine code in the ST2 format, the one the console’s emulators and cartridge copiers have used for years. Four tools make and run one: an assembler, a few Python scripts, MAME with the FujiNet cartridge grafted in, and a FujiNet to talk to.

== The assembler

Every program in this handbook is written for the Macroassembler AS by Alfred Arnold, which knows the 1802 as `CPU 1802`. Build it from its source, or take a package; the handbook was checked with version 1.42, build 306.

#nsteps(
  [Unpack AS and run its `make`. Put `asl` and `p2bin` where you like; the build scripts look in `~/asl/` first, then on your `PATH`, and `ASL=` names any other place.],
  [Run AS with `-U`. It makes names case-sensitive, and the runtime depends on it: `fn_frames` is a routine, `FN_FRAMES` a status byte.],
)

#important[AS takes one include list. Give it one `-i` with the folders separated by colons, and keep the paths relative: a long list of absolute paths is cut short without a word, and AS then reports only that it cannot open a file.]

== The Python tools

Three scripts from the cartridge’s firmware come with the handbook’s listings, in `listings/runtime/tools/`, and every build runs them:

- `checkrom.py` reads AS’s listing and refuses an instruction the cartridge cannot live with (The 1802 Runtime, page #pg(<runtime>)).
- `mkst2.py` turns AS’s `.p` file into an ST2 image, one 256-byte block for every page the program touched, and refuses a page a FujiNet program may not use.
- `st2.py` holds the format and the page rules for both.

They need Python 3 and nothing else.

== MAME and the cartridge

No FujiNet Studio II cartridge has been built yet, so the cartridge you will use is MAME’s. The firmware carries a model of it, `pico/studio2/emu/`, which runs the cartridge’s own C sources inside MAME’s `studio2` driver: the same mailbox, the same text engine, the same loader.

#nsteps(
  [Check out MAME and the FujiNet firmware.],
  [Graft the cartridge in: `pico/studio2/emu/apply.sh ~/Workspace/mame`. It copies the sources into `src/mame/rca/` and adds the device to the console.],
  [Build only the Studio II: `make SUBTARGET=studio2 SOURCES=src/mame/rca/studio2.cpp REGENIE=1 NOWERROR=1`. It takes a minute; afterwards an edit to the cartridge’s sources rebuilds in seconds.],
  [Put the console’s BIOS, `studio2.zip`, in MAME’s `roms` folder.],
)

The device is asleep unless the environment wakes it: `FUJINET=1` serves CONFIG from power-on, as a real cartridge would, and `FUJINET_BOOT=` names an ST2 image to serve in its place. `FUJINET_TCP` says where the FujiNet is.

== The FujiNet

The cartridge’s ESP32-S3 runs the FujiNet firmware’s RS-232 build. On your computer the same build runs as `fujinet-pc`, and MAME reaches it over _bus-over-IP_ (BoIP), a TCP connection in place of the USB cable inside the cartridge.

#nsteps(
  [Build it from the firmware: `./build.sh -p RS232`. The result is in `build/dist/`.],
  [Copy `fujinet`, `run-fujinet` and `data/` to a folder of their own, with an `SD/` folder beside them for the SD card.],
  [Give it an `fnconfig.ini` with BoIP on: `[BOIP]`, `enabled=1`, `host=localhost` and a `port=` that nothing else on your computer uses.],
  [Start it: `./run-fujinet -u http://127.0.0.1:8073 -c fnconfig.ini -s SD`. The web page at that address is the adapter’s, as on any FujiNet.],
)

#important[Always set `FUJINET_TCP` when you start MAME. Unset, the cartridge model tries `127.0.0.1:9995`, and on a computer with other FujiNet rigs that port may belong to one of them. Only one MAME may talk to a `fujinet-pc` at a time.]

== The handbook’s bench

The handbook keeps its whole bench in one place. `bench/ports.env` names its ports, and `bench/up.sh` starts `fujinet-pc` on BoIP 9973, a small web server for the network chapter’s test file, and the line server the netcat talks to; `bench/up.sh games` adds the Battleship and 5 Card Stud servers. `bench/down.sh` stops them all.

#tbl((1.3in, 1fr),
  [*Command*], [*Does*],
  [`make listings`], [assembles every program into `listings/asm/build/`],
  [`make verify`], [runs each one in MAME and checks its screen],
  [`make games`], [builds CONFIG, 5 Card Stud and Battleship],
  [`make check`], [checks the handbook against its sources],
)

== Running a program

`emu/run.sh` starts MAME with a program served from power-on:

```
emu/run.sh listings/asm/build/netget.st2
```

Named with a second argument, a Lua script drives MAME instead of you, with no window: `emu/run.sh netget.st2 screen` is how `make verify` checks a program’s screen.

#fig(stack(dir: ltr, spacing: 0.3in,
  keypad(name: [KEYPAD A], s: 16pt, subs: ("1": "Q", "2": "W", "3": "E", "4": "A",
    "5": "S", "6": "D", "7": "Z", "8": "X", "9": "C", "0": "Alt")),
  keypad(name: [KEYPAD B], s: 16pt, subs: ("1": "7", "2": "8", "3": "9", "4": "4",
    "5": "5", "6": "6", "7": "1", "8": "2", "9": "3", "0": "0"))),
  caption: [MAME’s keys: Q W E, A S D, Z X C and left Alt are keypad A’s 1 to 9 and 0; the numeric pad’s 7 8 9, 4 5 6, 1 2 3 and 0 are keypad B’s. F3 is CLEAR.])

== On a real console

When the cartridge exists, a program will travel the way every FujiNet program does. Copy the `.st2` file to the FujiNet’s SD card or a TNFS server, choose it in CONFIG, and CONFIG mounts it and hands the console over (Directories, Mount and Boot, page #pg(<boot>)).
