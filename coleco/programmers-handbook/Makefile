TYPST := $(shell command -v typst 2>/dev/null || echo $(HOME)/.local/bin/typst)
PDF   := fujinet-programmers-handbook-coleco.pdf

$(PDF): manual.typ $(wildcard fonts/*) $(wildcard listings/*/*)
	$(TYPST) compile --font-path fonts manual.typ $(PDF)

all: $(PDF)

watch:
	$(TYPST) watch --font-path fonts manual.typ $(PDF)

preview: $(PDF)
	mkdir -p preview
	$(TYPST) compile --font-path fonts --format png --ppi 110 manual.typ "preview/p{0p}.png"

# Regenerate the ColecoVision screen font from the 5 Card Stud port's 8x8
# character art (src/coleco/font.bin, 96 glyphs, 20H-7FH). Requires
# fontforge; the TTF is committed, so this is only needed when the source
# font.bin changes.
font:
	fontforge -lang=py -script tools/make_screen_font.py \
	    listings/5cardstud/coleco/font.bin fonts/ColecoScreen.ttf

clean:
	rm -rf $(PDF) preview

# The GitHub-wiki markdown edition is a manual step; the wiki/ copy is
# maintained alongside manual.typ.

.PHONY: all watch preview font clean
