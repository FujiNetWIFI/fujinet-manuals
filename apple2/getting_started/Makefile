# GETTING STARTED WITH FUJINET — for the Apple II (1984 IIc styling)
# Requires Typst 0.13+ (PATH or ~/.local/bin).

TYPST := $(shell command -v typst 2>/dev/null || echo $(HOME)/.local/bin/typst)
PDF   := fujinet-getting-started-apple2.pdf

all: $(PDF)

$(PDF): manual.typ $(wildcard images/*) $(wildcard fonts/*)
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
