TYPST := $(shell command -v typst 2>/dev/null || echo $(HOME)/.local/bin/typst)
Z80ASM := $(shell command -v z88dk-z80asm 2>/dev/null || echo $(HOME)/Workspace/z88dk/bin/z88dk-z80asm)
PDF   := fujinet-rs232-users-manual.pdf
ASM   := listings/hello/hello.asm listings/config/fncfg.asm \
         listings/netcat/netcat.asm listings/5cs/stud.asm

$(PDF): manual.typ examples.json $(wildcard fonts/*) $(wildcard listings/*/*)
	$(TYPST) compile --font-path fonts manual.typ $(PDF)

all: $(PDF)

watch:
	$(TYPST) watch --font-path fonts manual.typ $(PDF)

preview: $(PDF)
	mkdir -p preview
	rm -f preview/*.png
	$(TYPST) compile --font-path fonts --format png --ppi 110 manual.typ "preview/p{0p}.png"

# Assemble every Z80 listing to a .bin (load and run at 0100h).
listings: $(ASM:.asm=.bin)

%.bin: %.asm listings/common/altair.inc listings/common/conio.inc listings/common/fujibus.inc
	cd $(dir $<) && $(Z80ASM) -b $(notdir $<)

# Re-capture examples.json from a running fujinet-pc (BoIP on port 1985).
examples:
	cd tools && python3 examples.py

# The GitHub-wiki edition: wiki/*.md.in with the byte streams filled in
# from examples.json.
wiki:
	python3 tools/mkwiki.py

# Typesetting checks: margins, stranded heads, short pages, widows.
check: $(PDF)
	python3 tools/layoutcheck.py $(PDF)
	python3 tools/widows.py $(PDF)
	pdffonts $(PDF)

clean:
	rm -rf $(PDF) preview listings/*/*.bin listings/*/*.o

.PHONY: all watch preview listings examples wiki check clean
