TYPST := $(shell command -v typst 2>/dev/null || echo $(HOME)/.local/bin/typst)
PDF   := fujinet-programmers-handbook-5200.pdf
TFLAGS := --font-path fonts --ignore-system-fonts

$(PDF): manual.typ lib.typ $(wildcard parts/*.typ) $(wildcard fonts/*) $(wildcard images/*/*) $(wildcard listings/*/*)
	$(TYPST) compile $(TFLAGS) manual.typ $(PDF)

all: $(PDF)
watch:
	$(TYPST) watch $(TFLAGS) manual.typ $(PDF)
preview: $(PDF)
	mkdir -p preview
	$(TYPST) compile $(TFLAGS) --format png --ppi 110 manual.typ "preview/p{0p}.png"

# Every program, in both languages.
listings:
	cd listings/asm && ./build.sh hello fujitest pads netget netcat fujidir fujiboot appkey clock bank fujibank
	cd listings/c && ./build.sh hello acfg pads netget netcat dir boot appkey clock bank conio

# Run every program against the bench (bench/up.sh) and check its screen,
# then refresh images/screens from the snapshots.
verify:
	emu/verify.sh
shots: verify
	tools/shots.sh

clean:
	rm -rf $(PDF) preview build listings/*/build listings/snippets

# The checks: every example in the text builds in its language, every
# dispatched command has a card, no stranded lines, no fallback fonts.
check: $(PDF)
	python3 tools/snipcheck.py
	python3 tools/cmdcheck.py
	python3 tools/widows.py $(PDF)
	python3 tools/fontcheck.py $(PDF) && echo "fonts: ok"

.PHONY: all watch preview listings verify shots clean check
