EXECUTABLE = $(R2R_PD)/$(PRODUCT_BASE).bin
LIBRARY = $(R2R_PD)/$(PRODUCT_BASE).$(PLATFORM).lib

MWD := $(realpath $(dir $(lastword $(MAKEFILE_LIST)))..)
include $(MWD)/common.mk
include $(MWD)/toolchains/cc65.mk

# A 7800 FujiNet client is a 32K image at $8000 with the cart's RAM at $4000,
# started by the lib's own crt0 (cc65's locks INPTCTRL). The romstamp checks
# the claim, the mailbox's no-RMW rule and that nothing stores to $00-$1F,
# and writes the .a78 MAME's -cart needs next to the .bin the cart takes.
ATARI7800_CFG ?= $(MWD)/atari7800-fujinet.cfg
ATARI7800_MAP ?= $(EXECUTABLE:.bin=.map)

ifneq ($(IS_LIBRARY),1)
  LDFLAGS += -C $(ATARI7800_CFG) -m $(ATARI7800_MAP)

.DELETE_ON_ERROR:

$(PLATFORM)/executable-post::
	$(MWD)/atari7800-romstamp.py --stamp --map $(ATARI7800_MAP) \
	    --a78 $(EXECUTABLE:.bin=.a78) $(EXECUTABLE)
endif

r2r:: $(BUILD_EXEC) $(BUILD_LIB) $(R2R_EXTRA_DEPS)
	make -f $(PLATFORM_MK) $(PLATFORM)/r2r-post
