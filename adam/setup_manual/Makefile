# FujiNet CONFIG Set-Up Manual for the Coleco ADAM
#
#   make            build the PDF
#   make watch      rebuild automatically while editing manual.typ
#   make preview    render every page as PNG into preview/ for proofing
#   make clean      remove built artifacts

PDF = fujinet-config-adam-setup-manual.pdf
SRC = manual.typ

# Use typst from PATH, falling back to ~/.local/bin/typst
TYPST ?= $(shell command -v typst 2>/dev/null || echo $(HOME)/.local/bin/typst)
TYPSTFLAGS = --font-path fonts

# Asset filenames may contain spaces, so the PDF is rebuilt unconditionally
# rather than tracked through prerequisites. Typst compiles in well under a
# second, so this costs nothing.
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
