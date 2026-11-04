TYPST := $(shell command -v typst 2>/dev/null || echo $(HOME)/.local/bin/typst)
PDF   := fujinet-programmers-handbook-arcadia.pdf
TFLAGS := --font-path fonts --ignore-system-fonts

$(PDF): manual.typ lib.typ $(wildcard parts/*.typ) $(wildcard fonts/*) $(wildcard images/*/*) $(wildcard listings/*/*.asm listings/*/*.inc)
	$(TYPST) compile $(TFLAGS) manual.typ $(PDF)

all: $(PDF)
watch:
	$(TYPST) watch $(TFLAGS) manual.typ $(PDF)
preview: $(PDF)
	rm -rf preview/p*.png
	mkdir -p preview
	$(TYPST) compile $(TFLAGS) --format png --ppi 110 manual.typ "preview/p{0p}.png"

# Every program; then the three clients from their pins, for the bench.
listings:
	cd listings/asm && ./build.sh
games:
	listings/games.sh

# The bench: fujinet-pc, the HTTP fixture and the line server (and with
# bench-games, the two game servers). Nothing touches another rig.
bench:
	bench/up.sh
bench-games:
	bench/up.sh games
bench-down:
	bench/down.sh

# Run every program against the bench and check its screen; then the games
# end to end; then refresh images/screens from the snapshots.
verify: listings
	emu/verify.sh
verify-games: games
	emu/games.sh
shots:
	tools/shots.sh

clean:
	rm -rf $(PDF) preview build listings/asm/build listings/build listings/snippets

# The checks: every example builds, every command and cartridge name has a
# place, the equates and vendored files are what they say, no program is too
# deep, no stranded lines, no stray fonts, no unresolved reference.
check: $(PDF)
	python3 tools/snipcheck.py
	python3 tools/cmdcheck.py
	python3 tools/cartcheck.py
	python3 tools/defcheck.py
	python3 tools/vendorcheck.py
	cd listings/asm && for p in *.asm ../runtime/*.asm; do \
	  python3 ../../tools/depthcheck.py -I ../runtime -I . -I build/gen $$p || exit 1; done
	python3 tools/widows.py $(PDF)
	python3 tools/fontcheck.py $(PDF) && echo "fonts: ok"
	@! pdftotext $(PDF) - | grep -nE "\?\?|To be written" && echo "references: ok"

.PHONY: all watch preview listings games bench bench-games bench-down verify verify-games shots clean check
