# FujiNet Manual for the H89 FujiNet -- Programming.
#
#   make            the PDF (needs only typst and the fonts in fonts/)
#   make ONLY=08    one chapter, to build/only-08.pdf
#   make preview    PNG pages in preview/
#   make check      no stranded lines, no fallback fonts, every command carded
#   make watch      rebuild on every save
#
# Regenerating what the PDF prints (all of it is committed under data/ and
# screens/; these need z88dk, FujiNet Go H89, fn-h89, fujinet-lib):
#   make rig        fujinet-pc and fujinet-lib built into build/ (see README)
#   make programs   every Z80 and C program, for HDOS and for CP/M
#   make examples   run the exercisers; data/examples.json from the bus log
#   make snips      data/snips.json from the ;@ex / //@ex regions
#   make games      the three games from their pinned trees; their listings
#   make cmds       src/asm/inc/fncmd.inc and data/cmds.json from the firmware

TYPST  := $(shell command -v typst 2>/dev/null || echo $(HOME)/.local/bin/typst)
PDF    := fujinet-h89-programming-manual.pdf
TFLAGS := --font-path fonts --ignore-system-fonts
FW     ?= $(HOME)/Workspace/fn-h89

$(PDF): manual.typ lib.typ prog.typ figs.typ $(wildcard parts/*.typ) $(wildcard screens/*.json) \
        $(wildcard data/*.json) $(wildcard data/*/*.json) $(wildcard fonts/*) $(wildcard images/*.png)
	$(TYPST) compile $(TFLAGS) manual.typ $(PDF)

all: $(PDF)
ifdef ONLY
only:
	mkdir -p build && $(TYPST) compile $(TFLAGS) --input only=$(ONLY) manual.typ build/only-$(ONLY).pdf
endif
watch:
	$(TYPST) watch $(TFLAGS) manual.typ $(PDF)
preview: $(PDF)
	rm -rf preview && mkdir -p preview
	$(TYPST) compile $(TFLAGS) --format png --ppi 110 manual.typ "preview/p{0p}.png"
check: $(PDF)
	python3 tools/layoutcheck.py $(PDF)
	python3 tools/overlapcheck.py $(PDF)
	@pdffonts $(PDF) | awk 'NR>2 && $$0 !~ /yes +yes/ {bad=1; print "not embedded+subset:", $$0} END {exit bad}'
clean:
	rm -rf $(PDF) preview

# ---- what the book prints ------------------------------------------------
cmds:
	python3 tools/mkcmds.py $(FW)
snips:
	python3 tools/mksnips.py
games:
	tools/games.sh
	python3 tools/mklistings.py texasHoldEm battleship fujitzee

.PHONY: all only watch preview check clean cmds snips games
