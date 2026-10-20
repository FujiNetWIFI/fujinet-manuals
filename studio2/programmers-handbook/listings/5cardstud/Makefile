# studio2/Makefile -- RCA Studio II build.
#
# Standalone, like o2/ and arcadia/: Macroassembler AS, not the root's cc65
# family. build.sh does the work; this is the convenience wrapper.

PRODUCT = 5card
SOURCES = $(wildcard src/*.asm src/*.inc)

.PHONY: all clean

all: build/$(PRODUCT).st2

build/$(PRODUCT).st2: $(SOURCES) build.sh
	./build.sh

clean:
	rm -rf build
