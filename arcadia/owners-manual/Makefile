TYPST  := $(shell command -v typst 2>/dev/null || echo $(HOME)/.local/bin/typst)
PDF    := fujinet-owners-manual-arcadia.pdf
TFLAGS := --font-path fonts --ignore-system-fonts
# the hardware repo the cartridge drawing reads its anchors from (its working
# tree: the Arcadia board is not committed there yet; nothing is written)
HW     ?= $(HOME)/Workspace/fujinet-hardware
HWDIR  := $(HW)/Emerson-Arcadia/FujiNet-Arcadia-Rev0

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
# file; the console and its hand controllers are parametric
# (tools/make_arcadia.py).
stl:
	python3 tools/make_cart.py "$(HW)" build
	python3 tools/make_arcadia.py build
images: stl
	python3 tools/views.py build images/render
	python3 tools/flatbg.py "$(HWDIR)/docs/board-top.png" images/render/board-inside.png

# ---- the screens: CONFIG and the games in the FujiNet MAME, against the
# book's own fujinet-pc, game servers and Lobby (emu/bench.sh) -------------
src:
	emu/getsrc.sh
shots: src
	emu/bench.sh up games
	emu/rooms.sh
	emu/tour.sh
	emu/games.sh
	emu/bench.sh down

# ---- the online library the book names (needs the network) --------------
LIBRARY := "apps.irata.online:/Arcadia/!FUJINET/5 Card Stud.bin" \
           "apps.irata.online:/Arcadia/!FUJINET/Battleship.bin" \
           "apps.irata.online:/Arcadia/!FUJINET/Fujitzee.bin" \
           "apps.irata.online:/Arcadia/!FUJINET/Texas Hold 'em.bin" \
           "apps.irata.online:/Arcadia/Golf (Europe).bin" \
           "apps.irata.online:/Arcadia/Jungler (USA, Europe).bin" \
           "apps.irata.online:/mule/arcadia/mule.bin"
library:
	python3 tools/tnfsls.py apps.irata.online /Arcadia '/Arcadia/!FUJINET' /mule/arcadia
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

.PHONY: all watch preview clean stl images src shots library check-library wiki check
