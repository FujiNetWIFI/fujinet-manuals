# THE FUJINET BASIC EXTENSION — command reference (mid-80s tech-ref styling)
# Requires Typst 0.13+ (PATH or ~/.local/bin).
#
# The complete source listing in Appendix E is read LIVE from the extension
# sources: `make` copies them from ../../../fujinet-nhandler/apple2-new into
# listing/ so the printed listing can never drift from the shipped binary.

TYPST := $(shell command -v typst 2>/dev/null || echo $(HOME)/.local/bin/typst)
PDF   := fujinet-basic-extension-apple2.pdf
SRC   := ../../../fujinet-nhandler/apple2-new/src/apple2

LISTINGS := listing/equ.inc listing/fujiapple.s listing/smartport.inc

# Refresh the listing from the extension tree when it's checked out
# alongside; otherwise build from the committed listing/ snapshot.
ifneq ($(wildcard $(SRC)),)
DEPS := $(LISTINGS)
endif

all: $(PDF)

listing/%: $(SRC)/%
	@mkdir -p listing
	cp $< $@

$(PDF): manual.typ $(DEPS) $(wildcard images/*) $(wildcard fonts/*)
	$(TYPST) compile --font-path fonts manual.typ $(PDF)

watch: $(DEPS)
	$(TYPST) watch --font-path fonts manual.typ $(PDF)

preview: $(PDF)
	mkdir -p preview
	$(TYPST) compile --font-path fonts --format png --ppi 110 \
	    manual.typ "preview/page-{0p}.png"

clean:
	rm -rf $(PDF) preview

.PHONY: all watch preview clean
