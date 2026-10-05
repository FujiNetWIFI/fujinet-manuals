# Build every program in this book.
#
#   make            all of them, into build/
#   make c          the C programs only
#   make asm        the assembly programs only
#
# Needs cc65 2.19 and fujinet-lib-experimental (branch add-nes) built for the
# nes target:  make -C $(FUJINET_LIB) nes

FUJINET_LIB ?= $(HOME)/Workspace/fujinet-lib-experimental
LIBFILE     := $(FUJINET_LIB)/r2r/nes/fujinet.nes.lib
NESCFG      := $(FUJINET_LIB)/makefiles/nes-fujinet.cfg
STAMP       := $(FUJINET_LIB)/makefiles/nes-romstamp.py
CHECK       := common/checkrom.py

CPROGS   := hello netget json dir boot appkey clock
ASMPROGS := hello netget json dir boot appkey clock
B := build

all: c asm netcat
c:   $(CPROGS:%=$(B)/c/%.nes)
asm: $(ASMPROGS:%=$(B)/asm/%.nes)
netcat: $(B)/netcat.nes

$(B)/c/%.nes: c/%.c $(LIBFILE)
	@mkdir -p $(B)/c
	cl65 -t nes -O -I $(FUJINET_LIB)/include -C $(NESCFG) \
	    -m $(B)/c/$*.map -o $@ $< $(LIBFILE)
	python3 $(STAMP) --stamp --map $(B)/c/$*.map $@
	python3 $(CHECK) --claim --map $(B)/c/$*.map $@

COMMON_O := $(B)/asm/nesinit.o $(B)/asm/fujilib.o $(B)/asm/fujidisp.o $(B)/asm/booklib.o

$(B)/asm/%.o: asm/%.s common/*.inc
	@mkdir -p $(B)/asm
	ca65 -t none -I common -o $@ $<
$(B)/asm/%.o: common/%.s common/*.inc
	@mkdir -p $(B)/asm
	ca65 -t none -I common -o $@ $<

$(B)/asm/%.nes: $(B)/asm/%.o $(COMMON_O) common/nes.cfg
	ld65 -C common/nes.cfg -m $(B)/asm/$*.map -o $@ $< $(COMMON_O)
	python3 $(CHECK) --claim --map $(B)/asm/$*.map $@

NETCAT_SRC := $(wildcard netcat/*.c)
$(B)/netcat.nes: $(NETCAT_SRC) $(wildcard netcat/*.h) $(LIBFILE)
	@mkdir -p $(B)
	cl65 -t nes -O -I $(FUJINET_LIB)/include -C $(NESCFG) \
	    -m $(B)/netcat.map -o $@ $(NETCAT_SRC) $(LIBFILE)
	python3 $(STAMP) --stamp --map $(B)/netcat.map $@
	python3 $(CHECK) --claim --map $(B)/netcat.map $@

clean:
	rm -rf $(B)

.PHONY: all c asm netcat clean
.PRECIOUS: $(B)/asm/%.o
