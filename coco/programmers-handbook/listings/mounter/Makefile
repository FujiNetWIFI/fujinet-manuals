include ../common.mk

all: MOUNTER.BIN MOUNTER-ASM.BIN

MOUNTER-ASM.BIN: mounter.asm ../fnlib/fn.inc ../fnlib/fnlow.asm ../fnlib/cocoio.asm
	$(AS) $(ASFLAGS) -o $@ mounter.asm

MOUNTER.BIN: mounter.c
	$(CC) $(CFLAGS) -o $@ mounter.c $(LDLIBS)

clean:
	rm -f *.BIN *.dsk

.PHONY: all clean
