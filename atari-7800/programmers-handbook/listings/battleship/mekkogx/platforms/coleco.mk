EXECUTABLE = $(R2R_PD)/$(PRODUCT_BASE).rom
LIBRARY = $(R2R_PD)/$(PRODUCT_BASE).$(PLATFORM).lib

MWD := $(realpath $(dir $(lastword $(MAKEFILE_LIST)))..)
include $(MWD)/common.mk
include $(MWD)/toolchains/z88dk.mk

COLECO_FLAGS = +coleco
CFLAGS += $(COLECO_FLAGS)
LDFLAGS += $(COLECO_FLAGS)

# A ColecoVision FujiNet client is always a flat 32K image with nothing of its
# own in $F800-$FFFF: those pages are the mailbox, and the cartridge keeps
# painting and decoding them after the image boots. The claim at $FCFC is what
# promises that; without it the cartridge shuts the mailbox down for the
# session, so stamping it is part of linking rather than something each project
# is left to remember.
ifneq ($(IS_LIBRARY),1)
  LDFLAGS += -create-app
  LDFLAGS += -Cz--romsize=32768 -Cz--rombase=32768
  LDFLAGS += -Cz--code-fence=0xF800 -Cz--data-fence=0xF800

.DELETE_ON_ERROR:

$(PLATFORM)/executable-post::
	$(MWD)/coleco-romstamp.py --stamp $(EXECUTABLE)
endif

r2r:: $(BUILD_EXEC) $(BUILD_LIB) $(R2R_EXTRA_DEPS)
	make -f $(PLATFORM_MK) $(PLATFORM)/r2r-post
