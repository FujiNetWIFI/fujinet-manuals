TYPST := $(shell command -v typst 2>/dev/null || echo $(HOME)/.local/bin/typst)
PDF   := fujinet-programmers-handbook-studio2.pdf
TFLAGS := --font-path fonts --ignore-system-fonts
PROGS := netget fujidir appkey clock keys glyphs pages netcat

$(PDF): manual.typ lib.typ $(wildcard parts/*.typ) $(wildcard fonts/*) $(wildcard images/*/*) $(wildcard listings/*/*)
	$(TYPST) compile $(TFLAGS) manual.typ $(PDF)

all: $(PDF)
watch:
	$(TYPST) watch $(TFLAGS) manual.typ $(PDF)
preview: $(PDF)
	rm -rf preview/p*.png
	mkdir -p preview
	$(TYPST) compile $(TFLAGS) --format png --ppi 110 manual.typ "preview/p{0p}.png"
sheet: preview
	tools/contact.sh

# Every program, then the three clients against the bench's servers.
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
	rm -rf $(PDF) build-check.pdf preview build listings/*/build listings/snippets

# The checks: every example builds, every command and cartridge name has a
# place, the vendored files are what they say, the sources fit a column,
# every FIT covers its routine, no stranded lines, no stray fonts.
check: $(PDF)
	python3 tools/snipcheck.py
	python3 tools/cmdcheck.py
	python3 tools/cartcheck.py
	python3 tools/defcheck.py
	python3 tools/vendorcheck.py
	python3 tools/linelen.py
	python3 tools/fitcheck.py $(PROGS:%=listings/asm/build/obj/%.lst)
	python3 tools/widows3.py $(PDF)
	python3 tools/fontcheck.py $(PDF) --wordmark && echo "fonts: ok"
	@! pdftotext $(PDF) - | grep -nE "NO SCREEN|page \?\?" && echo "references and screens: ok"

.PHONY: all watch preview sheet listings games bench bench-games bench-down verify verify-games shots clean check
