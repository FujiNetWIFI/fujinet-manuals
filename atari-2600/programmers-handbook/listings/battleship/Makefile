# Makefile -- a convenience wrapper. build.sh is the real build.
#
# The root build (mekkogx) drives the cc65/cmoc-family C toolchains; this port
# is 6502 assembly under Macroassembler AS, which is a different toolchain
# entirely, so it stands alone next to intv/, arcadia/, astrocade/ and
# channelf/ rather than being forced through machinery it would only
# complicate.

ENDPOINT ?= https://battleship.carr-designs.com/
FUJI_FIRMWARE ?= $(HOME)/Workspace/fujinet-firmware
MAME_DIR ?= $(HOME)/Workspace/mame
SECS ?= 240
BS_TABLE ?= AI1

SRC := $(wildcard src/*.asm src/*.inc)

.PHONY: all layout run runlayout shot drive drive4 frames resettest \
        resetleave sounds emu hosttest clean frames4

all: build/battleship.bin

build/battleship.bin: $(SRC) build.sh tools/checkbanks.py tools/mktail.py
	ENDPOINT="$(ENDPOINT)" FUJI_FIRMWARE="$(FUJI_FIRMWARE)" ./build.sh

# The screen with no network at all: the kernel, the colours, the geometry,
# and the composed boards, from tables baked into the image.
layout: build/layout.bin
build/layout.bin: $(SRC) build.sh
	ENDPOINT="$(ENDPOINT)" FUJI_FIRMWARE="$(FUJI_FIRMWARE)" ./build.sh layout

run: all
	MAME=$(MAME_DIR) ./run.sh battleship
runlayout: layout
	MAME=$(MAME_DIR) ./run.sh layout

# A snapshot of the layout ROM, then tools/pfcheck.py reads it back.
shot: layout
	MAME=$(MAME_DIR) FAST=1 SECS=8 ./run.sh layout shot
	python3 tools/pfcheck.py build/snap/a2600/0000.png build/layout.lst

# Headless, against the live server. NOT -nothrottle: the server's countdown
# and move clock are wall clock.
drive: all
	MAME=$(MAME_DIR) SECS=$(SECS) BS_TABLE=$(BS_TABLE) ./run.sh battleship drive
drive4: all
	MAME=$(MAME_DIR) SECS=$(SECS) BS_TABLE=AI3 ./run.sh battleship drive
# Every frame must be 262 lines, through polls, shots and recomposes. The
# quadrant layout is the one with the fleet strips in it, and its kernel is
# 191 lines of a band of 192, so frames4 is not optional.
frames: all
	MAME=$(MAME_DIR) SECS=$(SECS) BS_TABLE=$(BS_TABLE) \
	    DRIVE_LUA=$(PWD)/emu/drive.lua ./run.sh battleship frames
frames4: all
	MAME=$(MAME_DIR) SECS=$(SECS) BS_TABLE=AI3 \
	    DRIVE_LUA=$(PWD)/emu/drive.lua ./run.sh battleship frames
# The cues, logged as they start, over a played game.
sounds: all
	MAME=$(MAME_DIR) SECS=$(SECS) BS_TABLE=$(BS_TABLE) DRIVE_MODE=sounds \
	    ./run.sh battleship drive
# A 6507 restart at the table: the cartridge's sequence must carry across.
resettest: all
	MAME=$(MAME_DIR) SECS=150 BS_TABLE=$(BS_TABLE) DRIVE_MODE=resettest \
	    ./run.sh battleship drive
# The RESET SWITCH, which is a different thing: it must give the seat up
# rather than abandon it.
resetleave: all
	MAME=$(MAME_DIR) SECS=150 BS_TABLE=$(BS_TABLE) DRIVE_MODE=resetleave \
	    ./run.sh battleship drive

hosttest:
	$(MAKE) -C $(FUJI_FIRMWARE)/pico/atari-2600/firmware/host_test

# Re-graft the cartridge device into MAME. Needed after ANY edit to a shared
# firmware source -- MAME compiles its own copies.
emu:
	$(FUJI_FIRMWARE)/pico/atari-2600/emu/apply.sh $(MAME_DIR)
	$(MAKE) -C $(MAME_DIR) -j$$(nproc) NOWERROR=1

clean:
	rm -rf build
