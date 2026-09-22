include ../common.mk

# An OS-9 module, not a LOADM binary.  fujinet-lib is not linked:
# its Color Computer build calls the Disk BASIC ROM, which is not
# mapped under OS-9.  FNBUS.C is the part we need, rebuilt above
# a transport we supply ourselves.

all: fnstat

fnstat: fnstat.c fnbus.c dwport.c fnbus.h dwport.h
	$(CC) --os9 -o $@ fnstat.c fnbus.c dwport.c

clean:
	rm -f fnstat *.o

.PHONY: all clean
