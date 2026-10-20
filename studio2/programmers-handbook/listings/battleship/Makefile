# studio2/Makefile -- RCA Studio II build.
#
# Standalone, like arcadia/ and channelf/: Macroassembler AS, not the root's
# cc65 family. build.sh does the work; this is the convenience wrapper.
#
#   make            build/battleship.st2 (ENDPOINT=... for another server)
#   make demo       the canned four-seat position, no network
#   make shot       the demo in MAME, headless: build/snap + the cell map
#   make run        play it in a MAME window
#   make drive      a whole game against $ENDPOINT, headless (emu/bsdrive.lua)

# Every target rebuilds: ENDPOINT and DEMO are not files make can see, and a
# stale image built for another server (or the demo) is worse than a second.

.PHONY: all demo shot run drive clean

all:
	./build.sh

demo:
	DEMO=1 ./build.sh

shot: demo
	SECS=$${SECS:-30} ./run.sh shot

run: all
	./run.sh

drive: all
	SECS=$${SECS:-1500} ./run.sh bsdrive

clean:
	rm -rf build
