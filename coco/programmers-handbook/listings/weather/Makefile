include ../common.mk

all: WEATHER.BIN WEATHER-ASM.BIN

WEATHER-ASM.BIN: weather.asm ../fnlib/fn.inc ../fnlib/fnlow.asm ../fnlib/fnnet.asm ../fnlib/cocoio.asm
	$(AS) $(ASFLAGS) -o $@ weather.asm

WEATHER.BIN: weather.c
	$(CC) $(CFLAGS) -o $@ weather.c $(LDLIBS)

clean:
	rm -f *.BIN *.dsk

.PHONY: all clean
