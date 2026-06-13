# THE FUJINET WIFI PERIPHERAL — OWNER'S GUIDE (1980–82 styling)
# Requires Typst 0.13+ (PATH or ~/.local/bin) and, for `make images`,
# python3 + numpy + Pillow and a checkout of fujinet-hardware.

TYPST := $(shell command -v typst 2>/dev/null || echo $(HOME)/.local/bin/typst)
PDF   := fujinet-owners-guide-400-800.pdf
HW    ?= $(HOME)/Workspace/fujinet-hardware/ATARI/FN32ROV-1.7.1/3D

# the 400/800-style case is tan all over; only the SIO hardware and
# the button caps are dark
TAN   := \#d8c9a3
DARK  := \#35302a

CASE  := --part "$(HW)/FujiNet 400 800 v1.7 Case Front.stl" "$(TAN)" \
         --part "$(HW)/FujiNet 400 800 v1.6 Case Rear.stl" "$(TAN)" \
         --part "$(HW)/FujiNet v1.6 Plug.stl" "$(DARK)" \
         --part "$(HW)/FujiNet v1.6 Receptacle.stl" "$(DARK)" \
         --part tools/buttons.stl "\#26221e"

all: $(PDF)

$(PDF): manual.typ $(wildcard images/*.png) $(wildcard fonts/*)
	$(TYPST) compile --font-path fonts manual.typ $(PDF)

watch:
	$(TYPST) watch --font-path fonts manual.typ $(PDF)

preview: $(PDF)
	mkdir -p preview
	$(TYPST) compile --font-path fonts --format png --ppi 72 \
	    manual.typ "preview/page-{0p}.png"

# Re-render the flat-shaded illustrations from the fujinet-hardware
# 3D models (set HW=... if your checkout lives elsewhere). The case
# STLs ship with empty button holes, so the three caps are generated
# first and rendered as their own part.
images:
	python3 tools/make_buttons.py tools/buttons.stl
	python3 tools/stl2png.py $(CASE) --azim 32  --elev 16 --width 1600 \
	    --out images/fujinet-hero.png
	python3 tools/stl2png.py $(CASE) --azim 212 --elev 20 --width 1300 \
	    --out images/fujinet-rear34.png
	python3 tools/stl2png.py $(CASE) --azim 90  --elev 4  --width 1300 \
	    --out images/fujinet-front-flat.png
	python3 tools/stl2png.py $(CASE) --azim 270 --elev 4  --width 1300 \
	    --out images/fujinet-rear-flat.png
	python3 tools/stl2png.py \
	    --part "$(HW)/FujiNet 400 800 v1.7 Case Front.stl" "$(TAN)" \
	    --part "$(HW)/FujiNet 400 800 v1.6 Case Rear.stl" "$(TAN)" \
	    --part "$(HW)/FujiNet v1.6 Plug.stl" "$(DARK)" \
	    --part tools/buttons.stl "\#26221e" \
	    --azim 90 --elev 58 --width 1400 --out images/fujinet-top.png
	python3 tools/stl2png.py \
	    --part "$(HW)/FujiNet v1.6 Plug.stl" "\#3a342d" \
	    --azim 60 --elev 28 --width 900 --out images/sio-plug.png
	python3 tools/stl2png.py \
	    --part "$(HW)/FujiNet XL v1.7 Case Front.stl" "\#e8e0cc" \
	    --part "$(HW)/FujiNet XL v1.6 Case Rear.stl" "\#6b6354" \
	    --part "$(HW)/FujiNet v1.6 Plug.stl" "$(DARK)" \
	    --azim 32 --elev 16 --width 800 --out images/fujinet-xl.png
	python3 tools/stl2png.py \
	    --part "$(HW)/FujiNet XE v1.7 Case Front.stl" "\#b8b8b0" \
	    --part "$(HW)/FujiNet XE v1.6 Case Rear.stl" "\#d3d3cd" \
	    --part "$(HW)/FujiNet v1.6 Plug.stl" "$(DARK)" \
	    --azim 212 --elev 20 --width 800 --out images/fujinet-xe.png

clean:
	rm -rf $(PDF) preview

.PHONY: all watch preview images clean
