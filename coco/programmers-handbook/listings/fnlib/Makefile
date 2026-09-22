include ../common.mk

all: FCDEMO.BIN FCDEMO-C.BIN

FCDEMO.BIN: fcdemo.asm fn.inc fnlow.asm cocoio.asm
	$(AS) $(ASFLAGS) -I. -o $@ fcdemo.asm

FCDEMO-C.BIN: fcdemo.c
	$(CC) $(CFLAGS) -o $@ fcdemo.c $(LDLIBS)

clean:
	rm -f *.BIN *.dsk

.PHONY: all clean
