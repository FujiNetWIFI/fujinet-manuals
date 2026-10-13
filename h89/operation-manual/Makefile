# FujiNet Manual for the H89 FujiNet -- Operation.
#
#   make            the PDF (needs only typst and the fonts in fonts/)
#   make watch      rebuild on every save
#   make preview    PNG pages in preview/
#   make check      no stranded lines, no fallback fonts
#   make acctest    reassemble the keyed-in programs into data/ (needs z88dk)
#   make verify     key the acceptance test into MTR-88/89/90 on FujiNet Go H89
#   make shots      recapture every screen from FujiNet Go H89 (needs the emulator,
#                   its ROMs, fujinet-h89, fujinet-config, z88dk)
#   make cover      the cover picture from the photo
#   make font       the H19 Screen font from the 444-29 ROM
#   make wiki       the wiki edition

TYPST  := $(shell command -v typst 2>/dev/null || echo $(HOME)/.local/bin/typst)
PDF    := fujinet-h89-operation-manual.pdf
TFLAGS := --font-path fonts --ignore-system-fonts
GO     ?= $(HOME)/Workspace/fujinet-go-h89-desktop
ROMZIP := $(GO)/tools/roms/heath_tlb.zip
FONTROM := build/roms/2716_444-29_h19font.u420

$(PDF): manual.typ lib.typ figs.typ $(wildcard parts/*.typ) $(wildcard screens/*.json) $(wildcard data/*.json) $(wildcard fonts/*) $(wildcard images/*.png) $(wildcard images/*/*)
	$(TYPST) compile $(TFLAGS) manual.typ $(PDF)

all: $(PDF)
watch:
	$(TYPST) watch $(TFLAGS) manual.typ $(PDF)
preview: $(PDF)
	rm -rf preview && mkdir -p preview
	$(TYPST) compile $(TFLAGS) --format png --ppi 110 manual.typ "preview/p{0p}.png"
clean:
	rm -rf $(PDF) preview

# ---- the keyed-in programs: the book prints what the assembler made ------
acctest:
	python3 tools/mkacctest.py test/acctest.asm build
	python3 tools/mkacctest.py test/flashmode.asm build
	cp build/acctest.json build/flashmode.json data/
verify: acctest $(FONTROM)
	tools/run-acctest.sh

# ---- the screens: captured from the real programs on FujiNet Go H89 ------
$(FONTROM):
	mkdir -p build/roms
	unzip -o -q -j $(ROMZIP) 2716_444-29_h19font.u420 -d build/roms
boot-disks:
	mkdir -p build/disks
	$(HOME)/Workspace/fujinet-h89/tests/make-hdos-boot.sh $(CURDIR)/build/disks/hdos-fn.h8d
	$(HOME)/Workspace/fujinet-h89/tests/make-62k-boot.sh $(CURDIR)/build/disks/cpm62.h8d
shots: $(FONTROM)
	tools/rigcfg.sh
	z88dk-z80asm -m8080 -b -O=build -o=build/HI.COM test/hi.asm
	tools/shots-config.sh
	tools/shots-drivers.sh
	tools/run-acctest.sh
	python3 tools/screenfix.py build/cells screens

# ---- pictures and the screen font ------------------------------------------
cover:
	tools/duotone.sh images/photo/board.jpg images/cover-board.png
font: $(FONTROM)
	fontforge -lang=py -script tools/make_h19_font.py $(FONTROM) fonts/H19Screen.ttf

wiki:
	python3 tools/mkwiki.py

# ---- checks ----------------------------------------------------------------
check: $(PDF)
	python3 tools/widows.py $(PDF)
	python3 tools/layoutcheck.py $(PDF)
	@if pdffonts $(PDF) | grep -iE 'libertinus|dejavu|newcm'; then echo "FAIL: a fallback font is embedded"; exit 1; else echo "fonts: OK"; fi

.PHONY: all watch preview clean acctest verify boot-disks shots cover font wiki check
