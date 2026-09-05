# Makefile -- FUJINET C DEMO for the Bally Astrocade (z88dk).
#
#   make        build build/cdemo.bin (8K cartridge image)
#   make run    boot it in MAME against a live fujinet-pc (see run.sh)
#   make clean

all:
	./build.sh

run: all
	./run.sh

clean:
	rm -rf build

.PHONY: all run clean

smoke:
	./build.sh
	rm -rf build/astrocde
	FUJINET_DEBUG=$${FUJINET_DEBUG:-1} $${MAME_DIR:-$$HOME/Workspace/mame}/mame astrocde \
	    -rompath $${MAME_DIR:-$$HOME/Workspace/mame}/roms \
	    -cartslot fujinet -cart $(CURDIR)/build/cdemo.bin \
	    -autoboot_script emu/smoke.lua -video none -sound none \
	    -seconds_to_run 20 -snapshot_directory $(CURDIR)/build
	@ls build/astrocde/
