# FujiNet NES Programmer's Manual
#   make            build the PDF
#   make listings   build every program in listings/ (cc65 2.19)
#   make check      snippets build, every command has a card, no widows, no stray fonts
#   make preview    PNG pages in preview/
#   make sheet      a contact sheet of every page
PDF    = fujinet-programmers-manual-nes.pdf
TFLAGS = --font-path fonts --ignore-system-fonts

all: $(PDF)

$(PDF): manual.typ lib.typ parts/*.typ images/*.png images/screens/*.png fonts/* listings/*/*
	typst compile $(TFLAGS) manual.typ $(PDF)

watch:
	typst watch $(TFLAGS) manual.typ $(PDF)

listings:
	$(MAKE) -C listings

preview: $(PDF)
	rm -rf preview && mkdir -p preview
	typst compile $(TFLAGS) --ppi 110 manual.typ 'preview/page-{0p}.png'

sheet: $(PDF)
	rm -rf preview/sheet && mkdir -p preview/sheet
	typst compile $(TFLAGS) --ppi 40 manual.typ 'preview/sheet/p-{0p}.png'
	magick montage preview/sheet/p-*.png -tile 6x -geometry +4+4 -background '#888' preview/sheet.png

wiki:
	python3 tools/mkwiki.py

check: $(PDF)
	python3 tools/snipcheck.py
	python3 tools/cmdcheck.py
	python3 tools/widows.py $(PDF)
	@if pdffonts $(PDF) | grep -i -E 'libertinus|dejavu|computer modern'; then \
	    echo "check: a fallback font was embedded"; exit 1; fi
	@echo "check: fonts ok"

clean:
	rm -rf preview

.PHONY: all watch listings preview sheet wiki check clean
