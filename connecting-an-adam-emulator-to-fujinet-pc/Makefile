# CONNECTING AN EMULATOR TO FUJINET-PC  (developer / engineering manual)
# Worked example: the Coleco ADAM emulator ADAMEm <-> fujinet-pc over AdamNet
# "Bus over IP". Requires Typst 0.13+ (PATH or ~/.local/bin).

TYPST := $(shell command -v typst 2>/dev/null || echo $(HOME)/.local/bin/typst)
PDF   := connecting-an-emulator-to-fujinet-pc.pdf

all: $(PDF)

$(PDF): manual.typ $(wildcard images/*) $(wildcard fonts/*)
	$(TYPST) compile --font-path fonts manual.typ $(PDF)

watch:
	$(TYPST) watch --font-path fonts manual.typ $(PDF)

preview: $(PDF)
	mkdir -p preview
	$(TYPST) compile --font-path fonts --format png --ppi 120 \
	    manual.typ "preview/p{0p}.png"

# The GitHub-wiki markdown in wiki/ is maintained alongside manual.typ by hand;
# see README.md.

clean:
	rm -rf $(PDF) preview

.PHONY: all watch preview clean
