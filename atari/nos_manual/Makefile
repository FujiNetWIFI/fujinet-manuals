# FUJINET NOS — AN INTRODUCTION TO THE NETWORK OPERATING SYSTEM
# (styled after the 1982 "ATARI 1050 Disk Drive: An Introduction
# to the Disk Operating System", C061529)
# Requires Typst 0.13+ (PATH or ~/.local/bin).

TYPST := $(shell command -v typst 2>/dev/null || echo $(HOME)/.local/bin/typst)
PDF   := fujinet-nos-introduction.pdf
NOS   ?= $(HOME)/Workspace/fujinet-nhandler/nos

all: $(PDF)

$(PDF): manual.typ listings/nos.s $(wildcard images/*.png) $(wildcard fonts/*)
	$(TYPST) compile --font-path fonts manual.typ $(PDF)

watch:
	$(TYPST) watch --font-path fonts manual.typ $(PDF)

preview: $(PDF)
	mkdir -p preview
	$(TYPST) compile --font-path fonts --format png --ppi 72 \
	    manual.typ "preview/page-{0p}.png"

# Re-stage the NOS source listing from the fujinet-nhandler checkout
# (set NOS=... if your checkout lives elsewhere).
listing:
	cp $(NOS)/src/nos.s listings/nos.s

clean:
	rm -rf $(PDF) preview

.PHONY: all watch preview listing clean
