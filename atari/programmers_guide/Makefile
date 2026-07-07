# PROGRAMMING THE FUJINET — for the Atari 8-bit computers
# A programmer's guide & command reference (1980–82 Atari styling).
# Requires Typst 0.13+ (found on PATH or in ~/.local/bin).

TYPST := $(shell command -v typst 2>/dev/null || echo $(HOME)/.local/bin/typst)
PDF   := fujinet-programmers-guide-atari.pdf

all: $(PDF)

$(PDF): manual.typ $(wildcard images/*.png) $(wildcard fonts/*)
	$(TYPST) compile --font-path fonts manual.typ $(PDF)

watch:
	$(TYPST) watch --font-path fonts manual.typ $(PDF)

preview: $(PDF)
	mkdir -p preview
	$(TYPST) compile --font-path fonts --format png --ppi 72 \
	    manual.typ "preview/page-{0p}.png"

clean:
	rm -rf $(PDF) preview

.PHONY: all watch preview clean
