# WRITING CROSS-PLATFORM FUJINET APPS — a developer's guide to building C
# apps with fujinet-lib, defoogi, github.dev, and CI/CD.
# Terminal/build-tooling-styled technical reference, US-Letter portrait.
# Requires Typst 0.13+ (PATH or ~/.local/bin).

TYPST := $(shell command -v typst 2>/dev/null || echo $(HOME)/.local/bin/typst)
PDF   := writing-cross-platform-fujinet-apps.pdf

all: $(PDF)

$(PDF): manual.typ $(wildcard fonts/*) $(wildcard images/*)
	$(TYPST) compile --font-path fonts manual.typ $(PDF)

watch:
	$(TYPST) watch --font-path fonts manual.typ $(PDF)

preview: $(PDF)
	mkdir -p preview
	$(TYPST) compile --font-path fonts --format png --ppi 110 \
	    manual.typ "preview/page-{0p}.png"

clean:
	rm -rf $(PDF) preview

.PHONY: all watch preview clean
