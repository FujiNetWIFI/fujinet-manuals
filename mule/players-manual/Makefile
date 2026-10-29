# M.U.L.E. — THE FUJINET MULTIPLAYER EDITION: PLAYER'S GUIDE
# (1983 Electronic Arts M.U.L.E. booklet styling, square pages)
# One source, ten editions, three outputs: PDF, FujiNet wiki, WordPress (WXR),
# plus a one-page cheat sheet (PDF) per edition.
# Requires Typst 0.13+ and python3 with PyYAML and Pillow.

TYPST := $(shell command -v typst 2>/dev/null || echo $(HOME)/.local/bin/typst)
GAME  ?= $(HOME)/Workspace/fujinet-multiplayer-mule
# where the WordPress importer will fetch the pictures from (see README.md)
MEDIA ?= https://apps.irata.online/mule/manual/images/

PLATFORMS := atari apple2 coco msdos adam msx lynx intv astrocade a2600
# file name for each edition
NAME_atari     := Atari-8-bit
NAME_apple2    := Apple-II
NAME_coco      := Color-Computer
NAME_msdos     := MS-DOS
NAME_adam      := Coleco-Adam
NAME_msx       := MSX
NAME_lynx      := Atari-Lynx
NAME_intv      := Intellivision
NAME_astrocade := Bally-Astrocade
NAME_a2600     := Atari-2600
PDFS := $(foreach p,$(PLATFORMS),pdf/MULE-Players-Guide-$(NAME_$(p)).pdf)
SHEETS := $(foreach p,$(PLATFORMS),pdf/MULE-Cheat-Sheet-$(NAME_$(p)).pdf)
TYPSTFLAGS := --font-path fonts --ignore-system-fonts

all: check-facts pdfs sheets wiki wordpress

# copy the screenshots out of the game repo (its screenshots/, made by
# screenshots/make-shots.sh) and cut the map icons
assets:
	python3 tools/pull_assets.py --game $(GAME)

build/%.json: content/*.yaml tools/expand.py $(wildcard assets/*/manifest.json)
	python3 tools/expand.py $*

define PDF_RULE
pdf/MULE-Players-Guide-$(NAME_$(1)).pdf: build/$(1).json manual.typ $(wildcard fonts/*)
	@mkdir -p pdf
	$(TYPST) compile $(TYPSTFLAGS) --input platform=$(1) manual.typ $$@
endef
$(foreach p,$(PLATFORMS),$(eval $(call PDF_RULE,$(p))))

pdfs: $(PDFS)

# the one-page cheat sheet, one per edition
define SHEET_RULE
pdf/MULE-Cheat-Sheet-$(NAME_$(1)).pdf: build/$(1).json cheatsheet.typ $(wildcard fonts/*)
	@mkdir -p pdf
	$(TYPST) compile $(TYPSTFLAGS) --input platform=$(1) cheatsheet.typ $$@
endef
$(foreach p,$(PLATFORMS),$(eval $(call SHEET_RULE,$(p))))

sheets: $(SHEETS)

wiki: $(foreach p,$(PLATFORMS),build/$(p).json)
	python3 tools/build_wiki.py

wordpress: $(foreach p,$(PLATFORMS),build/$(p).json)
	python3 tools/build_wxr.py --media-base $(MEDIA)
	xmllint --noout wordpress/mule-players-guide.wxr

check-facts:
	python3 tools/checkfacts.py --game $(GAME)

# no fallback fonts: every PDF uses only the faces in fonts/; a cheat sheet is one page
check: pdfs sheets
	@for f in $(PDFS) $(SHEETS); do \
	  pdffonts $$f | tail -n +3 | awk '{print $$1}' | grep -vE 'Souvenir|BenguiatGothic' && { echo "unexpected font in $$f"; exit 1; } || true; \
	done; echo "fonts: OK"
	@for f in $(SHEETS); do \
	  pdfinfo $$f | grep -qE '^Pages: +1$$' || { echo "$$f is more than one page"; exit 1; }; \
	done; echo "sheets: one page each"

# PREVIEW=atari make preview
PREVIEW ?= atari
preview: build/$(PREVIEW).json
	rm -rf preview && mkdir -p preview
	$(TYPST) compile $(TYPSTFLAGS) --input platform=$(PREVIEW) --format png --ppi 72 manual.typ "preview/page-{0p}.png"

watch: build/$(PREVIEW).json
	$(TYPST) watch $(TYPSTFLAGS) --input platform=$(PREVIEW) manual.typ preview.pdf

# the style reference: the 1983 EA booklet scan (20 MB, not committed)
learn:
	mkdir -p learn && curl -L -o learn/MULE.pdf https://archive.org/download/Mule_atari8/MULE.pdf

clean:
	rm -rf build preview preview.pdf

.PHONY: all learn assets pdfs sheets wiki wordpress check check-facts preview watch clean
