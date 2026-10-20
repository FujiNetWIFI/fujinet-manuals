#import "../lib.typ": *
= Install the Tools

#ini[E]very program in this handbook is built three ways, and every build runs on the same bench: the FujiNet cartridge grafted into MAME's Atari 7800, talking over bus-over-IP to a FujiNet adapter running on the same computer. Install the pieces in this order.

#sect[cc65]

The assembler, linker and C compiler are all cc65’s: `ca65`, `ld65` and `cc65`, with `cl65` to drive them. Everything here was built with version 2.19. cc65’s own `atari7800` target supplies the C library; the FujiNet library supplies the start-up code and the linker configuration, because cc65’s start-up locks INPTCTRL (Section 3 explains why that matters).

```
git clone https://github.com/cc65/cc65.git
cd cc65 && make && sudo make install PREFIX=/usr/local
cc65 --version          # cc65 V2.19
```

#sect[fujinet-lib]

The C programs call fujinet-lib, the same library every FujiNet C program on every platform uses. Its `atari7800` target adds the mailbox transport, a start-up file that never touches INPTCTRL, a linker configuration and a checker. Until it is merged, build it from the branch that adds it:

```
git clone -b add-atari7800 https://github.com/tschak909/fujinet-lib-experimental.git
cd fujinet-lib-experimental && make atari7800
ls r2r/atari7800        # fujinet.atari7800.lib
```

The library is the `.lib`; its headers are `include/` and `bus/atari7800/`. The build scripts in this handbook find them through `FNLIB`.

#sect[7800basic]

7800basic is a compiled BASIC for the 7800: it turns a program into 6502 assembly and assembles it with dasm. Its release runs on wasmtime; it also builds natively, which is what this handbook used.

```
git clone https://github.com/7800-devtools/7800basic.git
cd 7800basic
make LEX=flex 7800preprocess    # the two lexers share lex.yy.c:
make LEX=flex 7800optimize      #   build them one at a time
make LEX=flex                   # then the rest
export bas7800dir=$PWD PATH=$PWD:$PATH
```

dasm 2.20.16 must be on the `PATH` too. The handbook's `listings/bas/build.sh` runs 7800basic's steps itself, because the native `7800basic.native.sh` runs the compiler under valgrind, and then adds the FujiNet claim (Section 9).

#sect[MAME with the FujiNet cartridge]

The cartridge model lives in the firmware's `pico/atari-7800/emu/`. Its `apply.sh` grafts it into a MAME source tree; a build of the 7800 driver alone is enough.

```
git clone https://github.com/mamedev/mame.git
fujinet-firmware/pico/atari-7800/emu/apply.sh mame
cd mame
make SUBTARGET=a7800 SOURCES=src/mame/atari/a7800.cpp REGENIE=1 -j$(nproc)
./a7800 -listslots | grep fujinet
```

The last line should print `cartslot  fujinet  Atari 7800 FujiNet Cartridge`. The 7800 BIOS images go where MAME's `-rompath` finds them. The cartridge connects to a FujiNet adapter at `127.0.0.1:9995` unless the environment variable `FUJINET_TCP` names another address.

#important[MAME must run from its own tree, or it ignores `-autoboot_script` and every headless check in this handbook does nothing. With no display, set `SDL_VIDEODRIVER=dummy`.]

#sect[A FujiNet adapter]

The adapter is `fujinet-pc`, the FujiNet firmware built to run on a computer, in its RS-232 flavour, which speaks bus-over-IP. Build it from the firmware:

```
cd fujinet-firmware
./build.sh -p RS232
cd build/dist && ./run-fujinet
```

In its `fnconfig.ini`, the `[BOIP]` section names the port it listens on; make it the port the cartridge connects to. Its `SD/` directory is the SD card, host slot 0. Only one MAME can talk to one `fujinet-pc` at a time.

#sect[Running a program]

Each language has a build script: `listings/asm/build.sh`, `listings/c/build.sh` and `listings/bas/build.sh`. Each writes the program twice: a bare image (`.bin`), which is what the cartridge runs, and the same image with the 128-byte header MAME needs (`.a78`), which the cartridge strips.

```
listings/c/build.sh acfg                   # build/acfg.bin, build/acfg.a78
emu/run.sh listings/c/build/acfg.a78       # in a window
SHOT_AT=6 TEXT_WANT="DUMMY CAFE" \
  emu/run.sh listings/c/build/acfg.a78 screen   # headless, and checked
emu/verify.sh                              # all 24 programs
```

`emu/screen.lua` reads the screen the way MARIA does, by walking the display lists, so one check serves all three languages. It prints the cartridge's status and the text on the screen, saves a snapshot, and with `TEXT_WANT` passes only if every piece appears.

#sect[FujiNet Go Atari 7800]

FujiNet Go Atari 7800 is a desktop application with all of this inside it: MAME's 7800, the cartridge model, and a FujiNet adapter, with no BIOS required. Its *Open Cartridge…* menu runs any `.a78` file, and a program that carries the FujiNet claim keeps the mailbox, so every program in this handbook runs there unchanged. It is the quickest way to try one.
