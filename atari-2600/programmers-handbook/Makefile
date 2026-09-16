TYPST := $(shell command -v typst 2>/dev/null || echo $(HOME)/.local/bin/typst)
PDF   := fujinet-programmers-handbook-2600.pdf
TFLAGS := --font-path fonts --ignore-system-fonts

$(PDF): manual.typ lib.typ $(wildcard parts/*.typ) $(wildcard fonts/*) $(wildcard images/*/*) $(wildcard listings/*/*)
	$(TYPST) compile $(TFLAGS) manual.typ $(PDF)

all: $(PDF)
watch:
	$(TYPST) watch $(TFLAGS) manual.typ $(PDF)
preview: $(PDF)
	mkdir -p preview
	$(TYPST) compile $(TFLAGS) --format png --ppi 110 manual.typ "preview/p{0p}.png"
# Regenerate the cartridge's 3x5 screen font (needs fontforge; the TTF is committed).
font:
	fontforge -lang=py -script tools/make_screen_font.py $(HOME)/Workspace/fn-2600/pico/atari-2600/tools fonts/VCSScreen.ttf
# The dasm twin of the assembly library is generated; the build must not drift.
listings:
	cd listings/asm && ./build.sh
	for f in vcs.inc:vcs2600.h fujinet.inc:fujinet.h fujilib.inc:fujilib.asm fujidisp.inc:fujidisp.asm netdefs.inc:netdefs.h devdefs.inc:devdefs.h; do \
	  python3 tools/as2dasm.py listings/common/$${f%%:*} listings/dasm/$${f##*:} >/dev/null; done
	python3 tools/mkfujiconst.py listings/dasm/fujinet.h listings/dasm/fujibas.h listings/dasm/netdefs.h listings/dasm/devdefs.h > listings/bas/fujiconst.bas
	cd listings/bas && for p in hello arm text netget dir boot; do ./build.sh $$p; done
shots:
	tools/shots.sh
clean:
	rm -rf $(PDF) preview

.PHONY: all watch preview font listings shots clean

# The checks: every example in the text builds, every dispatched command has a
# card, no stranded lines, no fallback fonts.
check: $(PDF)
	python3 tools/snipcheck.py
	python3 tools/cmdcheck.py
	python3 tools/widows.py $(PDF)
	@pdffonts $(PDF) | awk 'NR>2{print $$1}' | sed 's/^[A-Z]*+//' | sort -u | tee /dev/stderr | grep -qi libertinus && { echo "check: a fallback font is embedded" >&2; exit 1; } || echo "fonts: ok"
.PHONY: check
