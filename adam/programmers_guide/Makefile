# PROGRAMMING THE FUJINET — for the Coleco ADAM (1983 Coleco house style)
#
#   make            build the PDF
#   make watch      rebuild automatically while editing manual.typ
#   make preview    render every page as PNG into preview/ for proofing
#   make clean      remove built artifacts
#
# Requires Typst 0.13+ (the Makefile looks on PATH, then in ~/.local/bin).

PDF = fujinet-programmers-guide-adam.pdf
SRC = manual.typ

TYPST ?= $(shell command -v typst 2>/dev/null || echo $(HOME)/.local/bin/typst)
TYPSTFLAGS = --font-path fonts

all:
	$(TYPST) compile $(TYPSTFLAGS) $(SRC) $(PDF)

watch:
	$(TYPST) watch $(TYPSTFLAGS) $(SRC) $(PDF)

preview:
	mkdir -p preview
	$(TYPST) compile $(TYPSTFLAGS) --format png --ppi 120 $(SRC) "preview/page-{0p}.png"

clean:
	rm -rf $(PDF) preview

.PHONY: all watch preview clean
