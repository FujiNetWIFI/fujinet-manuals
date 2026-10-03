# FUJINET FOR THE ATARI 2600 -- THEORY OF OPERATION (Engineering Series)
# Typst 0.15+; vendored fonts in fonts/
# Requires Typst 0.13+ (PATH or ~/.local/bin).

TYPST := $(shell command -v typst 2>/dev/null || echo $(HOME)/.local/bin/typst)
PDF   := fujinet-2600-theory-of-operation.pdf

all: $(PDF)

$(PDF): manual.typ lib.typ $(wildcard parts/*.typ) $(wildcard images/*) $(wildcard images/*/*) $(wildcard fonts/*)
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
