# common.mk --- shared settings for every listing in this book
#
# fujinet-lib ships as a flat directory: the headers, the .inc
# files and one .lib.  Point FNDIR at wherever you unpacked it.
# The default is where an installed cmoc keeps its headers.

FNDIR ?= /usr/share/cmoc/include
ifeq ($(wildcard $(FNDIR)/fujinet-fuji.h),)
FNDIR := $(HOME)/Workspace/fujinet-lib
endif

CC      := cmoc
AS      := lwasm

CFLAGS  := -I$(FNDIR)
LDLIBS  := -lfujinet

ASFLAGS := --6809 --format=decb -I../fnlib

%.BIN: %.c
	$(CC) $(CFLAGS) -o $@ $< $(LDLIBS)
