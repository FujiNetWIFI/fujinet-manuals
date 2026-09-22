TYPST := $(shell command -v typst 2>/dev/null || echo $(HOME)/.local/bin/typst)
PDF   := fujinet-programmers-handbook-coco.pdf

all: $(PDF)

$(PDF): manual.typ $(wildcard fonts/*) $(wildcard images/*) \
        $(wildcard listings/*/*) listings/common.mk
	$(TYPST) compile --font-path fonts manual.typ $(PDF)

watch:
	$(TYPST) watch --font-path fonts manual.typ $(PDF)

preview: $(PDF)
	mkdir -p preview
	$(TYPST) compile --font-path fonts --format png --ppi 110 \
	    manual.typ "preview/p{0p}.png"

# Build every program in listings/.  Appendix C reads the same files at
# typeset time, so a listing in the book cannot drift from one that builds.
listings:
	$(MAKE) -C listings clean
	$(MAKE) -C listings

# The checks: every dispatched command has a card, every inline snippet
# assembles or compiles, and no fallback font crept into the PDF.
check: $(PDF) listings
	python3 tools/cmdcheck.py
	python3 tools/snipcheck.py
	@pdffonts $(PDF) | awk 'NR>2{print $$1}' | sed 's/^[A-Z]*+//' \
	    | sort -u | tee /dev/stderr \
	    | grep -qi -e libertinus -e 'DejaVu' \
	    && { echo "check: a fallback font is embedded" >&2; exit 1; } \
	    || echo "fonts: ok"

clean:
	rm -rf $(PDF) preview
	$(MAKE) -C listings clean

# The GitHub-wiki markdown edition is a manual step; the wiki/ copy is
# maintained alongside manual.typ.
.PHONY: all watch preview listings check clean
