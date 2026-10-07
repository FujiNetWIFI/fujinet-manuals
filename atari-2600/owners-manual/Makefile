TYPST  := $(shell command -v typst 2>/dev/null || echo $(HOME)/.local/bin/typst)
PDF    := fujinet-owners-manual-2600.pdf
TFLAGS := --font-path fonts --ignore-system-fonts
HW     ?= $(HOME)/Workspace/fujinet-hardware/ATARI-2600/Fujiversal-Atari2600-Rev1
HWREV  := $(HW)/case/Fujiversal-Atari2600-CartShell.scad

$(PDF): manual.typ lib.typ $(wildcard parts/*.typ) $(wildcard screens/*.txt) $(wildcard fonts/*) $(wildcard images/*/*.png)
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
# The cart shell's board-anchors.scad is generated INTO build/ from the
# hardware repo's placement table -- nothing is written into fujinet-hardware.
anchors:
	python3 -B tools/cart_anchors.py "$(HW)" build
stl: anchors
	mkdir -p build/stl
	OPENSCADPATH="build/case:$(HW)/case" openscad -D 'view="front"' -o build/stl/cart_front.stl tools/cartviews.scad
	OPENSCADPATH="build/case:$(HW)/case" openscad -D 'view="rear"' -o build/stl/cart_rear.stl tools/cartviews.scad
	python3 tools/make_cart_bits.py build
	python3 tools/make_vcs.py build
images: stl
	python3 tools/views.py build images/render
	python3 tools/flatbg.py "$(HW)/docs/board-top.png" images/render/board-inside.png
# MAME captures (needs the FujiNet MAME, fujinet-pc on :9995 for the live ones,
# and the game servers); then scale every raw capture to TV shape.
shots:
	tools/shots.sh
	python3 tools/scale.py images/screens/raw images/screens
scale:
	python3 tools/scale.py images/screens/raw images/screens

# ---- the online library the book names (needs the network) --------------
LIBRARY := apps.irata.online:/Atari_2600/battleship.bin \
           apps.irata.online:/Atari_2600/fujitzee.bin \
           apps.irata.online:/Atari_2600/texas.bin \
           apps.irata.online:/Atari_2600/5card.bin \
           apps.irata.online:/mule/atari-2600/mule2600.bin
library:
	python3 tools/tnfsls.py apps.irata.online / /Atari_2600 /mule/atari-2600
check-library:
	python3 tools/tnfsls.py --check $(LIBRARY)

# ---- the wiki edition ------------------------------------------------------
wiki:
	python3 tools/mkwiki.py

.PHONY: all watch preview clean anchors stl images shots scale library check-library wiki

# The checks: no stranded lines, no fallback fonts, every TV screen fits the
# cartridge's 12 x 21 grid in its own font, a page count the printer can fold.
check: $(PDF)
	python3 tools/widows.py $(PDF)
	python3 tools/tvcheck.py screens
	@pdffonts $(PDF) | awk 'NR>2{print $$1}' | sed 's/^[A-Z]*+//' | sort -u | tee /dev/stderr | grep -qi -e libertinus -e dejavu && { echo "check: a fallback font is embedded" >&2; exit 1; } || echo "fonts: ok"
	@n=$$(pdfinfo $(PDF) | awk '/^Pages/{print $$2}'); [ $$((n % 4)) -eq 0 ] && echo "pages: $$n" || { echo "check: $$n pages is not a multiple of 4" >&2; exit 1; }
.PHONY: check
