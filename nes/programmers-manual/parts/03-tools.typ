#import "../lib.typ": *

= Setting Up Your Tools

#lead[A FujiNet NES program is an ordinary NES program with three extra
facts: where the mailbox is, a reserved place for the claim, and a check that
nothing in it breaks the mailbox's one rule.]

== The compiler

Install cc65 2.19. You need `ca65` and `ld65` for assembly, and `cl65`, which
drives the whole chain, for C. Everything in this manual is built with
`-t nes`, cc65's NES target, or `-t none` for plain assembly.

== fujinet-lib

The C programs link against fujinet-lib. Its NES target lives on the
`add-nes` branch of fujinet-lib-experimental:

#codepanel("Building the library",
"git clone -b add-nes https://github.com/FujiNetWIFI/fujinet-lib-experimental
cd fujinet-lib-experimental
make nes                  # -> r2r/nes/fujinet.nes.lib")

Besides the library it provides three files every NES program needs:

#runin(
  ([`makefiles/nes-fujinet.cfg`], [cc65's stock NES linker configuration --
   NROM, 32K PRG, 8K CHR ROM, the cartridge's 8K work RAM at `$6000` -- with
   `$FFF0-$FFF9` carved out for the claim.]),
  ([`makefiles/nes-romstamp.py`], [run after the link: it writes `FUJI` at
   `$FFF0` and refuses an image that has a read-modify-write instruction
   aimed at the mailbox.]),
  ([`makefiles/platforms/nes.mk`], [does both for you if your project builds
   with the library's makefiles.]),
)

== This manual's programs

The `listings/` directory holds every program in Chapters 5 to 9 and the
netcat of Appendix D. `make` builds them all into `listings/build/`:

#codepanel("listings/Makefile, the two recipes",
"build/c/%.nes: c/%.c
	cl65 -t nes -O -I $(FUJINET_LIB)/include -C $(NESCFG) \\
	    -m build/c/$*.map -o $@ $< $(LIBFILE)
	python3 $(STAMP) --stamp --map build/c/$*.map $@
	python3 common/checkrom.py --claim --map build/c/$*.map $@

build/asm/%.nes: build/asm/%.o $(COMMON_O) common/nes.cfg
	ld65 -C common/nes.cfg -m build/asm/$*.map -o $@ $< $(COMMON_O)
	python3 common/checkrom.py --claim --map build/asm/$*.map $@")

The assembly programs share five files in `listings/common/`:

#tbl((auto, 1fr),
  th[File], th[What it holds],
  [`fujinet.inc`], [The mailbox's addresses and registers, and the library's
   zero page. Copied unchanged from the cartridge firmware's own test
   programs.],
  [`fujidefs.inc`], [Every other device and command number, from the
   firmware's headers.],
  [`fujilib.s`], [The mailbox library: begin, append, commit, wait. Also
   copied unchanged.],
  [`booklib.s`], [What this manual adds: a vblank NMI, a non-waiting commit,
   an unpadded string append, a number printer.],
  [`nesinit.s`, `fujidisp.s`], [The iNES header, the claim, the vectors, the
   cold start; a font in CHR RAM and a few text routines.],
  [`nes.cfg`], [The linker configuration: NROM-256, CHR RAM, the claim at
   `$FFF0`.],
)

#codepanel("listings/common/nes.cfg",
"MEMORY {
    ZP:      start = $0000, size = $00E0, type = rw, define = yes;
    RAM:     start = $0300, size = $0500, type = rw, define = yes;
    WRAM:    start = $6000, size = $2000, type = rw, define = yes;
    HEADER:  start = $0000, size = $0010, file = %O, fill = yes;
    PRG:     start = $8000, size = $7FF0, file = %O, fill = yes, fillval = $FF;
    CLAIM:   start = $FFF0, size = $000A, file = %O, fill = yes, fillval = $FF;
    VECTORS: start = $FFFA, size = $0006, file = %O, fill = yes;
}", size: 6.6pt)

Notice two things. Zero page stops at `$E0`, because the mailbox library owns
`$E0-$EF`. And PRG stops at `$FFF0`, ten bytes short of the vectors: the
`CLAIM` segment, which `nesinit.s` fills with `FUJI`, sits there.

== checkrom.py

`checkrom.py` comes from the cartridge firmware's tools. It checks the iNES
header the way the cartridge parses it, that the claim is there, that the
reset vector lands in `$8000-$FFFF`, and -- walking only the code segments
named in the linker map -- that no read-modify-write instruction is aimed at
`$5500-$57FF`.

#codepanel("A clean build",
"$ make -C listings
...
build/c/hello.nes: ok
checkrom: build/c/hello.nes: ok
checkrom: build/asm/hello.nes: ok")

== A FujiNet to talk to

The programs need a FujiNet on the other end of the cartridge's USB link. On
a PC that is *fujinet-pc*, the FujiNet firmware built for Linux, macOS or
Windows with the RS-232 bus. It listens for a cartridge on a TCP port --
*bus over IP*, 127.0.0.1:9995 by default -- and serves its web
configuration page on another. Its SD card is a directory beside it.

== An NES with the cartridge in it

There are two emulated NES machines with the FujiNet cartridge built in.

*MAME, grafted.* The cartridge firmware ships a MAME device, `nes_fujinet`,
that compiles the cartridge's own mailbox, FujiBus and mapper sources into
MAME and connects to fujinet-pc over bus-over-IP. Apply it once and rebuild:

#codepanel("Grafting the cartridge into MAME",
"cd fujinet-firmware/pico/nes
./emu/apply.sh ~/mame               # copies the device into src/devices/bus/nes
cd ~/mame && make REGENIE=1
./mame nes -nes_slot fujinet -cart hello.nes")

MAME's NES driver insists on a `-cart`; the device treats it as the image
the cartridge would have loaded. This manual's `emu/run.sh` wraps that line,
takes a screenshot after a few seconds, and prints the screen as text; its
`emu/drive.lua` presses buttons on a script. Every screen in this manual came
out of those two.

*FujiNet Go NES Desktop.* A self-contained NES -- the MesenCE emulator core,
with the cartridge modelled from the same firmware sources and fujinet-pc
built in. Its FujiNet listens on port 11506 and serves its configuration page
at `http://localhost:11507`. Use *Open Cartridge...* to run your `.nes` in
place of CONFIG, or *Import Cartridge to SD...* to copy it to the FujiNet's
SD card and boot it from CONFIG, which exercises the real network load.
*Reset Game* presses the console's Reset; *Reset to CONFIG* is a power cycle.
Its debugger loads ld65 label files, with the mailbox registers already
named.

#note[Reset Game resets the console but not the cartridge, just as on real
hardware. It is the quickest way to test that your program takes its sequence
numbers from the cartridge (Chapter 4).]
