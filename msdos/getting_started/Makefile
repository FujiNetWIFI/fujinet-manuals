# FUJINET RS-232 for MS-DOS — GUIDE TO OPERATIONS
# (1981 IBM 5150 "Guide to Operations" styling, portrait binder trim)
# Requires Typst 0.13+ (PATH or ~/.local/bin).

TYPST := $(shell command -v typst 2>/dev/null || echo $(HOME)/.local/bin/typst)
PDF   := fujinet-guide-to-operations-msdos.pdf

# fujinet-hardware checkout (for re-rendering the case art)
HW    := $(HOME)/Workspace/fujinet-hardware/RS232/RS232-Rev1b/3D

CASE  := --part tools/asm_bottom.stl "\#e7e3d9" \
         --part tools/asm_top.stl "\#efebe2" \
         --part tools/asm_knob_l.stl "\#bcb4aa" \
         --part tools/asm_knob_r.stl "\#bcb4aa" \
         --part tools/asm_button.stl "\#2a2a2a" \
         --part tools/asm_db9_shell.stl "\#bbb7af" \
         --part tools/asm_db9_pins.stl "\#dcd8d0" \
         --part tools/asm_led_white.stl "\#f6f2e8" \
         --part tools/asm_led_orange.stl "\#e07f1e"

PC    := --part tools/pc_case.stl "\#e9e5db" \
         --part tools/pc_dark.stl "\#39362f" \
         --part tools/pc_keys.stl "\#dad6cc" \
         --part tools/pc_base.stl "\#e2ded4"

all: $(PDF)

$(PDF): manual.typ $(wildcard images/*) $(wildcard fonts/*)
	$(TYPST) compile --font-path fonts manual.typ $(PDF)

watch:
	$(TYPST) watch --font-path fonts manual.typ $(PDF)

preview: $(PDF)
	mkdir -p preview
	$(TYPST) compile --font-path fonts --format png --ppi 110 \
	    manual.typ "preview/page-{0p}.png"

# Re-render the flat-shaded illustrations. make_case.py assembles the
# two Rev1b case shells into a closed clamshell (mirroring the single
# knurled knob into a pair) and generates the DB-9 connector + LED
# domes. make_pc.py builds the parametric IBM 5150 system + rear panel.
images:
	python3 tools/make_case.py tools
	python3 tools/make_pc.py tools
	python3 tools/stl2png.py $(CASE) --levels 0.82,0.92,1.0 --depth-edge 0.5 \
	    --azim 145 --elev 24 --width 1500 --out images/fujinet-rs232-hero.png
	python3 tools/stl2png.py --part tools/asm_bottom.stl "\#e7e3d9" \
	    --part tools/asm_top.stl "\#efebe2" \
	    --part tools/asm_knob_l.stl "\#bcb4aa" --part tools/asm_knob_r.stl "\#bcb4aa" \
	    --part tools/asm_led_white.stl "\#f6f2e8" --part tools/asm_led_orange.stl "\#e07f1e" \
	    --levels 0.82,0.92,1.0 --depth-edge 0.5 --azim 0 --elev 90 \
	    --width 1100 --out images/fujinet-rs232-top.png
	python3 tools/stl2png.py $(CASE) --levels 0.82,0.92,1.0 --depth-edge 0.5 \
	    --azim 162 --elev 16 --width 1300 --out images/fujinet-rs232-connector.png
	python3 tools/stl2png.py $(PC) --levels 0.83,0.93,1.0 --depth-edge 1.5 \
	    --azim 332 --elev 18 --width 1500 --out images/ibm-pc-system.png
	python3 tools/stl2png.py --part tools/pc_rear.stl "\#e6e2d8" \
	    --part tools/pc_rear_dark.stl "\#39362f" \
	    --levels 0.84,0.93,1.0 --depth-edge 1.2 --azim 350 --elev 16 \
	    --width 1200 --out images/ibm-pc-rear.png

clean:
	rm -rf $(PDF) preview

.PHONY: all watch preview images clean
