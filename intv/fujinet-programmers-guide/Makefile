TYPST ?= typst
OUT = fujinet-programmers-guide-intv.pdf

all: $(OUT)

$(OUT): manual.typ $(wildcard listings/*.bas listings/*/*.bas fonts/*)
	$(TYPST) compile --font-path fonts manual.typ $(OUT)

watch:
	$(TYPST) watch --font-path fonts manual.typ $(OUT)

preview: $(OUT)
	mkdir -p preview
	pdftoppm -png -r 110 $(OUT) preview/page

clean:
	rm -rf $(OUT) preview

.PHONY: all watch preview clean
