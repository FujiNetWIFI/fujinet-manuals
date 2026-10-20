EXECUTABLE = $(R2R_PD)/$(PRODUCT_BASE).sms
LIBRARY = $(R2R_PD)/$(PRODUCT_BASE).$(PLATFORM).lib

MWD := $(realpath $(dir $(lastword $(MAKEFILE_LIST)))..)
include $(MWD)/common.mk
include $(MWD)/toolchains/z88dk.mk

SMS_FLAGS = +sms
CFLAGS += $(SMS_FLAGS)
LDFLAGS += $(SMS_FLAGS)

# A Sega Master System FujiNet client carries the "FUJI" claim at $7FDC and
# leaves $B000-$BFFF of every bank from 2 up to the cartridge's mailbox arena;
# without the claim the cartridge shuts the mailbox down for the session, so
# stamping it is part of linking rather than something each project is left
# to remember.
ifneq ($(IS_LIBRARY),1)
  LDFLAGS += -create-app

.DELETE_ON_ERROR:

$(PLATFORM)/executable-post::
	$(MWD)/sms-romstamp.py --stamp $(EXECUTABLE)
endif

r2r:: $(BUILD_EXEC) $(BUILD_LIB) $(R2R_EXTRA_DEPS)
	make -f $(PLATFORM_MK) $(PLATFORM)/r2r-post
