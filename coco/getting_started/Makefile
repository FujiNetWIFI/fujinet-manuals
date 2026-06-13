# FUJINET COLOR COMPUTER — GETTING STARTED MANUAL
# (1980 TRS-80 Color Computer Operation Manual styling, landscape)
# Requires Typst 0.13+ (PATH or ~/.local/bin).

TYPST := $(shell command -v typst 2>/dev/null || echo $(HOME)/.local/bin/typst)
PDF   := fujinet-getting-started-coco.pdf

# fujinet-hardware checkout (for re-rendering the case art)
HW    := $(HOME)/Workspace/fujinet-hardware/Coco/CoCo-FujiNet-Rev000/3D/STL
CASE  := --part "$(HW)/CoCo-FujiNet-Rev000-Upper.stl" "\#e9e5dc" \
         --part "$(HW)/CoCo-FujiNet-Rev000-Lower.stl" "\#d8d4ca" \
         --part tools/interior.stl "\#55504a" \
         --part tools/led_white.stl "\#f4f1e6" \
         --part tools/led_orange.stl "\#e07820" \
         --part tools/dip_body.stl "\#c23b2a" \
         --part tools/dip_nubs.stl "\#f0ede4" \
         --part tools/buttons.stl "\#262422" \
         --part tools/ports_dark.stl "\#3a3733"
CABLE := --part tools/cable.stl "\#2e2b28" --part tools/plug.stl "\#1f1d1b"

all: $(PDF)

$(PDF): manual.typ $(wildcard images/*) $(wildcard fonts/*)
	$(TYPST) compile --font-path fonts manual.typ $(PDF)

watch:
	$(TYPST) watch --font-path fonts manual.typ $(PDF)

preview: $(PDF)
	mkdir -p preview
	$(TYPST) compile --font-path fonts --format png --ppi 72 \
	    manual.typ "preview/page-{0p}.png"

# Re-render the flat-shaded illustrations from the fujinet-hardware
# Rev000 case models (set HW=... if your checkout lives elsewhere).
# The case STLs ship as empty shells; make_accents.py generates the
# LEDs, DIP switch, button stems, port inserts, and serial cable that
# the real unit shows.  make_starfield.py draws the cover stock.
images:
	python3 tools/make_accents.py tools
	python3 tools/make_starfield.py images/starfield.png
	python3 tools/make_loading.py \
	    $(HOME)/Workspace/fujinet-config/src/coco/cfgload/cfgload.c \
	    images/loading-splash.png
	python3 tools/stl2png.py $(CASE) $(CABLE) --depth-edge 0.45 \
	    --azim 325 --elev 20 --width 1600 --out images/cocofuji-hero.png
	python3 tools/stl2png.py $(CASE) --depth-edge 0.45 \
	    --azim 0 --elev 78 --width 1400 --out images/cocofuji-top.png
	python3 tools/stl2png.py $(CASE) --depth-edge 0.45 \
	    --azim 270 --elev 4 --width 1400 --out images/cocofuji-ports.png
	python3 tools/stl2png.py $(CASE) $(CABLE) --depth-edge 0.45 \
	    --azim 145 --elev 22 --width 1300 --out images/cocofuji-rear34.png

clean:
	rm -rf $(PDF) preview

.PHONY: all watch preview images clean
