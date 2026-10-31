TYPST  := $(shell command -v typst 2>/dev/null || echo $(HOME)/.local/bin/typst)
PDF    := fujinet-owners-manual-5200.pdf
TFLAGS := --font-path fonts --ignore-system-fonts
# the hardware repo the cartridge drawing reads its anchors from (git show,
# nothing is written there)
HW     ?= $(HOME)/Workspace/fujinet-hardware
HWREV  ?= origin/master

$(PDF): manual.typ lib.typ figs.typ $(wildcard parts/*.typ) $(wildcard fonts/*) $(wildcard images/*/*.png) $(wildcard images/render/*.json)
	$(TYPST) compile $(TFLAGS) manual.typ $(PDF)

all: $(PDF)
watch:
	$(TYPST) watch $(TFLAGS) manual.typ $(PDF)
preview: $(PDF)
	rm -rf preview && mkdir -p preview
	$(TYPST) compile $(TFLAGS) --format png --ppi 110 manual.typ "preview/p{0p}.png"
clean:
	rm -rf $(PDF) preview

# ---- the pictures (committed; these targets rebuild them) ----------------
# The cartridge is the book's own drawing, built round the Rev0 board's anchor
# file; the console and the controller are parametric (tools/make_a5200.py).
stl:
	python3 tools/make_cart.py "$(HW)" "$(HWREV)" build
	python3 tools/make_a5200.py build
images: stl
	python3 tools/views.py build images/render
	git -C "$(HW)" show $(HWREV):ATARI-5200/FujiNet-5200-Rev0/docs/board-top.png > build/board-top.png
	python3 tools/flatbg.py build/board-top.png images/render/board-inside.png

# ---- the screens: CONFIG and the games in the FujiNet MAME, against the
# book's own fujinet-pc and local game servers (emu/bench.sh) -------------
shots:
	emu/bench.sh up games
	emu/tour.sh
	emu/games.sh
	for n in 01-title:title 02-lobby:lobby 07-land-auction-bidding:land-auction-bidding \
	         08-develop-town:develop-town 09-develop-map:develop-map 14-declare:declare; do \
	  python3 tools/pngscale.py $(HOME)/Workspace/fujinet-multiplayer-mule/screenshots/atari5200/$${n%%:*}.png \
	    images/screens/mule-$${n#*:}.png 3 >/dev/null; done
	emu/bench.sh down

# ---- the online library the book names (needs the network) --------------
LIBRARY := "apps.irata.online:/ATARI-5200/FUJINET/Battleship.a52" \
           "apps.irata.online:/ATARI-5200/FUJINET/Five Card Stud.a52" \
           "apps.irata.online:/ATARI-5200/FUJINET/Fujitzee.a52" \
           "apps.irata.online:/ATARI-5200/FUJINET/Texas Hold'em.a52" \
           "apps.irata.online:/mule/atari5200/mule.a52"
library:
	python3 tools/tnfsls.py apps.irata.online /ATARI-5200/FUJINET /mule/atari5200
check-library:
	python3 tools/tnfsls.py --check $(LIBRARY)

# ---- the wiki edition ------------------------------------------------------
wiki:
	python3 tools/mkwiki.py

# The checks: every screen word quoted is in the sources, no stranded lines,
# no fallback fonts, a page count the printer can fold.
check: $(PDF)
	python3 tools/strcheck.py
	python3 tools/widows.py $(PDF)
	python3 tools/fontcheck.py $(PDF) && echo "fonts: ok"
	@n=$$(pdfinfo $(PDF) | awk '/^Pages/{print $$2}'); [ $$((n % 4)) -eq 0 ] && echo "pages: $$n" || { echo "check: $$n pages is not a multiple of 4" >&2; exit 1; }

.PHONY: all watch preview clean stl images shots library check-library wiki check
