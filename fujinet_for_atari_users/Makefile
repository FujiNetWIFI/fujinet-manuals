XSLTPROC=xsltproc
FOP=fop
FOP_CFG=fop.xml
SOURCE_FILE=fujinet_for_atari_users
DOCBOOK_STYLESHEET=/usr/share/xml/docbook/stylesheet/nwalsh/fo/docbook.xsl
FO=/tmp/tmp.fo

all: pdf

pdf: $(SOURCE_FILE).dbk
	$(XSLTPROC) -o $(FO) \
		$(DOCBOOK_STYLESHEET) \
		$(SOURCE_FILE).dbk
	$(FOP) -c $(FOP_CFG) -pdf $(SOURCE_FILE).pdf \
		-fo $(FO)

clean:
	$(RM) $(SOURCE_FILE).pdf
