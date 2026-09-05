TYPST := $(shell command -v typst 2>/dev/null || echo $(HOME)/.local/bin/typst)
PDF   := fujinet-programmers-handbook-astrocade.pdf

$(PDF): manual.typ $(wildcard images/*) $(wildcard fonts/*) $(wildcard listings/*/*)
	$(TYPST) compile --font-path fonts manual.typ $(PDF)

all: $(PDF)

watch:
	$(TYPST) watch --font-path fonts manual.typ $(PDF)

preview: $(PDF)
	mkdir -p preview
	$(TYPST) compile --font-path fonts --format png --ppi 110 manual.typ "preview/p{0p}.png"

# Regenerate the Astrocade screen font from netcat's 4x6 font art.
# Requires fontforge; the TTF is committed, so this is only needed when
# the source font.inc changes.
font:
	fontforge -lang=py -script tools/make_screen_font.py \
	    listings/netcat/font.inc fonts/AstrocadeScreen.ttf

clean:
	rm -rf $(PDF) preview

# The GitHub-wiki markdown edition is a manual step; the wiki/ copy is
# maintained alongside manual.typ.

.PHONY: all watch preview font clean
