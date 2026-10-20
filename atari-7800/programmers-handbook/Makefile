TYPST := $(shell command -v typst 2>/dev/null || echo $(HOME)/.local/bin/typst)
PDF   := fujinet-programmers-handbook-7800.pdf
TFLAGS := --font-path fonts --ignore-system-fonts

$(PDF): manual.typ lib.typ $(wildcard parts/*.typ) $(wildcard fonts/*) $(wildcard images/*/*) $(wildcard listings/*/*)
	$(TYPST) compile $(TFLAGS) manual.typ $(PDF)

all: $(PDF)
watch:
	$(TYPST) watch $(TFLAGS) manual.typ $(PDF)
preview: $(PDF)
	mkdir -p preview
	$(TYPST) compile $(TFLAGS) --format png --ppi 110 manual.typ "preview/p{0p}.png"

# Every program, in all three languages.
listings:
	cd listings/asm && ./build.sh hello fujitest netget fujidir fujiboot appkey clock fujibank
	cd listings/c && ./build.sh hello acfg netget dir boot appkey clock
	cd listings/c && CFG=bank.cfg EXTRA=crt0bank.s ./build.sh bank
	cd listings/bas && ./build.sh hello acfg netget dir boot appkey clock bank

# Run every program against the live FujiNet and check its screen, then
# refresh images/screens from the snapshots.
verify:
	emu/verify.sh
shots: verify
	tools/shots.sh

# The 7800basic font, from the assembly font's own table.
font:
	python3 tools/mkbasfont.py listings/bas/fujifont.png

clean:
	rm -rf $(PDF) preview build listings/*/build listings/snippets

# The checks: every example in the text builds in its language, every
# dispatched command has a card, no stranded lines, no fallback fonts.
check: $(PDF)
	python3 tools/snipcheck.py
	python3 tools/cmdcheck.py
	python3 tools/widows.py $(PDF)
	python3 tools/fontcheck.py $(PDF) && echo "fonts: ok"

.PHONY: all watch preview listings verify shots font clean check
