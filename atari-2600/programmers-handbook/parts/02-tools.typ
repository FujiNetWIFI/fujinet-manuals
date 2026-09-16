#import "../lib.typ": *
= Install the Tools

Everything in this handbook was built and run on a Linux machine with the tools below. Nothing here needs a real cartridge: the FujiNet cartridge model in MAME is bit-faithful to the RP2040 firmware's bus behaviour, and it talks to a real FujiNet, `fujinet-pc`, over a socket. A program that works here works on the cartridge, with the one exception the handbook flags where it matters: emulation answers inside the store, and hardware answers a little later.

#sect[Macroassembler AS]

The assembly programs are written for Macroassembler AS (`asl` and `p2bin`), the assembler every cartridge bring-up in the FujiNet family shares. It assembles 6502 code, produces a listing, and `p2bin` turns its output into a raw image over an address range:

```
asl -q -L -i ../common netget.asm
p2bin netget.p build/netget.bin -r '$1000-$1FFF' -l 0
```

The handbook's assembly sources are in `listings/asm/`, the library they include in `listings/common/`, and `listings/asm/build.sh` runs the whole flow for every program: the equate check, the assembler, the image, the claim, and the static check described in Section 3.

#sect[batari Basic and dasm]

batari Basic compiles BASIC to 6502 assembly and hands it to dasm. Install batari Basic from its repository, and dasm from `github.com/dasm-assembler/dasm` (any 2.20 release; `make` and copy `bin/dasm` somewhere on your `PATH`). batari Basic finds its own files through the `bB` environment variable, and its native build script is `2600basic.native.sh`:

```
export bB=$HOME/Workspace/batari-Basic
$bB/2600basic.native.sh hello.bas
```

The handbook's BASIC sources are in `listings/bas/`, and `listings/bas/build.sh` does the extra work a FujiNet client needs, which Section 8 explains: it prepends the constants, compiles, appends the fixed half of the cartridge image, and runs the static check.

#sect[MAME with the FujiNet cartridge]

The cartridge bring-up carries a MAME cartridge device that is the RP2040 firmware's own `fujimail.c` and `vcs_render.c`, compiled into MAME. Graft it into a MAME source tree and build:

```
~/Workspace/fn-2600/pico/atari-2600/emu/apply.sh ~/Workspace/mame
make -C ~/Workspace/mame -j$(nproc) NOWERROR=1 REGENIE=1
```

The device is the `fujinet` cartridge slot option. It reaches the adapter through bus-over-IP, on `127.0.0.1:9995` unless `FUJINET_TCP` says otherwise.

#important[MAME must run from its own source tree, or its `-autoboot_script` option is silently ignored. Where there is no display, `SDL_VIDEODRIVER=dummy` must be set, or MAME dies before it reads `-video none`. The handbook's `emu/run.sh` does both.]

#sect[fujinet-pc]

`fujinet-pc-rs232` is the FujiNet firmware built to run on a PC. Its bus-over-IP listener takes one client, so a MAME left running starves the next one and the symptom is a hang, not an error. `emu/run.sh` kills any stray MAME before it starts another.

```
cd ~/Workspace/fujinet-pc-rs232/build/dist
./run-fujinet
```

Its `SD/` directory is the adapter's SD card, host slot 0 in the programs here, and `SD/FujiNet/` holds the appkeys.

#sect[Running a program]

```
emu/run.sh listings/bas/build/hello.bin          # in a window
emu/run.sh listings/bas/build/hello.bin frames   # headless, with a harness
```

The harnesses in `emu/` are how every program in this handbook was checked, and they are described with the programs. Three are worth knowing from the start: `probe.lua` says whether a cartridge is answering and honoured the claim; `txn.lua` reports the last transaction's status cells and the reply; `frames.lua` taps `VSYNC` and reports any frame that is not 262 lines, which is the only honest test of a display kernel.
