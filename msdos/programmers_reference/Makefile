# FUJINET INT F5 — TECHNICAL REFERENCE (MS-DOS)
# (1984 IBM 5150 "Technical Reference" styling, portrait binder trim)
# Requires Typst 0.13+ (PATH or ~/.local/bin).

TYPST := $(shell command -v typst 2>/dev/null || echo $(HOME)/.local/bin/typst)
PDF   := fujinet-int-f5-technical-reference.pdf

all: $(PDF)

$(PDF): manual.typ $(wildcard images/*) $(wildcard fonts/*)
	$(TYPST) compile --font-path fonts manual.typ $(PDF)

watch:
	$(TYPST) watch --font-path fonts manual.typ $(PDF)

preview: $(PDF)
	mkdir -p preview
	$(TYPST) compile --font-path fonts --format png --ppi 110 \
	    manual.typ "preview/p{0p}.png"

clean:
	rm -rf $(PDF) preview

.PHONY: all watch preview clean
