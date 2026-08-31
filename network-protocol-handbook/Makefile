# FujiNet Network Protocol Handbook
# Requires typst 0.13+ (tested with the version on PATH; falls back to
# ~/.local/bin/typst). Fonts are vendored in fonts/ so the build is
# self-contained.

TYPST := $(shell command -v typst 2>/dev/null || echo $(HOME)/.local/bin/typst)
PDF   := fujinet-network-protocol-handbook.pdf

all: $(PDF)

$(PDF): manual.typ $(wildcard images/*) $(wildcard fonts/*)
	$(TYPST) compile --font-path fonts manual.typ $(PDF)

watch:
	$(TYPST) watch --font-path fonts manual.typ $(PDF)

preview: $(PDF)
	mkdir -p preview
	$(TYPST) compile --font-path fonts --format png --ppi 110 manual.typ "preview/p{0p}.png"

clean:
	rm -rf $(PDF) preview

# The GitHub-wiki markdown edition is a manual step; the wiki/ copy is
# maintained alongside manual.typ.

.PHONY: all watch preview clean
