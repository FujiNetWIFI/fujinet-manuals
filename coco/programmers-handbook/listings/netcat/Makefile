include ../common.mk

all: NETCAT.BIN NETCAT-C.BIN

NETCAT.BIN: netcat.asm ../fnlib/fn.inc ../fnlib/fnlow.asm ../fnlib/fnnet.asm ../fnlib/cocoio.asm
	$(AS) $(ASFLAGS) -o $@ netcat.asm

NETCAT-C.BIN: netcat.c
	$(CC) $(CFLAGS) -o $@ netcat.c $(LDLIBS)

clean:
	rm -f *.BIN *.dsk

.PHONY: all clean
