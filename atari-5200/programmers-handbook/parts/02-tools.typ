#import "../lib.typ": *
= Install the Tools <ch-tools>

Every program in this handbook is built two ways, and every build runs on the same bench: the FujiNet cartridge grafted into MAME’s ATARI 5200, talking over bus-over-IP to a FujiNet adapter running on the same computer. Install the pieces in this order.

#sect[cc65]

The assembler, linker and C compiler are all cc65’s: `ca65`, `ld65` and `cc65`, with `cl65` to drive them. Everything here was built with version 2.19. cc65’s own `atari5200` target supplies the C library: the console, the joystick driver, the clock. The start-up code and the linker configuration come from MekkoGX instead, because cc65’s own start-up leans on the BIOS, and a FujiNet program tells the BIOS to step aside (@ch-map).

```
git clone https://github.com/cc65/cc65.git
cd cc65 && make && sudo make install PREFIX=/usr/local
cc65 --version          # cc65 V2.19
```

#sect[fujinet-lib]

The C programs call fujinet-lib, the same library every FujiNet C program on every platform uses. Its `atari5200` target adds the mailbox transport: the hotspot reads, the transaction, and the calls that hand the console to a new image. Until it is merged, build it from the branch that adds it:

```
git clone -b add-atari5200 https://github.com/tschak909/fujinet-lib.git
cd fujinet-lib && make atari5200
ls r2r/atari5200        # fujinet.atari5200.lib
```

The library is the `.lib`; its headers are `include/` and `bus/atari5200/`. The build scripts in this handbook find it through `FNLIB`.

#sect[MekkoGX]

MekkoGX is the build template FujiNet’s cross-platform programs use. Its `atari5200` platform carries the three files every 5200 FujiNet program in C needs, and that the library leaves out:

#tbl((auto, 1fr),
  th[File], th[What it does],
  [`atari5200-crt0.s`], [The start-up code. It does what the BIOS would have done, keeps the BIOS’s zero page and vectors so cc65’s library works, and takes the keypad’s interrupt (@ch-c).],
  [`atari5200-fujinet.cfg`], [The linker configuration: 32K of ROM around the mailbox, and the console’s 16K of RAM for data, the heap and the C stack.],
  [`atari5200-romstamp.py`], [The checker: the claim, the BIOS header, and the mailbox’s rules (@ch-mailbox).],
)

```
git clone -b add-atari5200 https://github.com/tschak909/MekkoGX.git
ls MekkoGX/mekkogx/atari5200*      # crt0, cfg, romstamp
```

A program built the MekkoGX way, as the games in this handbook are, uses `platforms/atari5200.mk`, which names all three. This handbook’s `listings/c/build.sh` calls `cl65` with them directly, so that every step shows; it finds them through `MEKKO`.

#sect[MAME with the FujiNet cartridge]

The cartridge model lives in the firmware’s `pico/atari-5200/emu/`. Its `apply.sh` grafts it into a MAME source tree; a build of the 5200 driver alone is enough.

```
git clone https://github.com/mamedev/mame.git
fujinet-firmware/pico/atari-5200/emu/apply.sh mame
cd mame
make SUBTARGET=a5200 SOURCES=src/mame/atari/atari400.cpp REGENIE=1 -j$(nproc)
./a5200 -listslots | grep fujinet
```

The last command should print `a5200  cartslot  fujinet  Atari 5200 FujiNet Cartridge`, and the same for `a5200a`, the two-port console. The 5200 BIOS image, `a5200.zip`, goes where MAME’s `-rompath` finds it. The cartridge connects to a FujiNet adapter at `127.0.0.1:9995` unless the environment variable `FUJINET_TCP` names another address.

#important[MAME must run from its own tree, or it ignores `-autoboot_script` and every headless check in this handbook does nothing. With no display, add `-video none -sound none`, as `emu/run.sh` does.]

#sect[A FujiNet adapter]

The adapter is `fujinet-pc`, the FujiNet firmware built to run on a computer, in its RS-232 flavour, which speaks bus-over-IP. Build it from the firmware:

```
cd fujinet-firmware
./build.sh -p RS232
cd build/dist && ./run-fujinet
```

In its `fnconfig.ini`, the `[BOIP]` section names the port it listens on; make it the port the cartridge connects to. Its `SD/` directory is the SD card, host slot 0. Only one MAME can talk to one `fujinet-pc` at a time.

#caution[A `fujinet-pc` older than October 2026 does not know the `.a52` extension. It mounts a 5200 image as a disk, says yes to MOUNT_IMAGE, and pushes nothing, so the cartridge waits for an image that never comes. Build it from current firmware.]

#sect[Running a program]

Each language has a build script, `listings/asm/build.sh` and `listings/c/build.sh`. Each writes a 32K image (64K for a Super Cart), checks it, and leaves it in its `build/` directory. MAME’s `-cart` takes the image as it is, and the cartridge model serves a claimed image as if CONFIG had just booted it.

```
listings/c/build.sh acfg                       # listings/c/build/acfg.bin
emu/run.sh listings/c/build/acfg.bin           # in a window
SHOT_AT=6 WANT="Dummy Cafe" \
  emu/run.sh listings/c/build/acfg.bin drive   # headless, and checked
emu/verify.sh                                  # all 20 programs
```

`emu/drive.lua` presses the controller’s keys and moves its stick on a timetable, then reads the screen as text, saves a snapshot, and with `WANT` passes only if every piece appears. The text is read straight out of the screen memory both languages’ programs use.

#note[There is no FujiNet Go for the 5200. To try a program without building MAME, you need a cartridge.]
