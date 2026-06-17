# FUJINET PLATFORM BRING-UP GUIDE  (developer / engineering manual)
# Worked example: the 8-bit PC ISA bus on the ESP32 + RP2350 tandem design.
# Requires Typst 0.13+ (PATH or ~/.local/bin).

TYPST := $(shell command -v typst 2>/dev/null || echo $(HOME)/.local/bin/typst)
PDF   := fujinet-platform-bringup-guide.pdf

all: $(PDF)

$(PDF): manual.typ $(wildcard images/*) $(wildcard fonts/*)
	$(TYPST) compile --font-path fonts manual.typ $(PDF)

watch:
	$(TYPST) watch --font-path fonts manual.typ $(PDF)

preview: $(PDF)
	mkdir -p preview
	$(TYPST) compile --font-path fonts --format png --ppi 120 \
	    manual.typ "preview/p{0p}.png"

# Regenerate the GitHub-wiki markdown is a manual step; the wiki/ copy is
# maintained alongside manual.typ. See README.md.

clean:
	rm -rf $(PDF) preview

.PHONY: all watch preview clean
