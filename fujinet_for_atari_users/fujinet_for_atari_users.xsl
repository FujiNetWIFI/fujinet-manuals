<?xml version='1.0'?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  version="1.0">
  <xsl:import href="file:///usr/share/xml/docbook/stylesheet/docbook-xsl/fo/docbook.xsl" />

  <xsl:param name="body.font.family" select="'Optima LT Std'"/>
  <xsl:param name="title.font.family" select="'Optima LT Std'"/>
  <!-- <xsl:param name="page.width">5in</xsl:param> -->
  <!-- <xsl:param name="page.height">7in</xsl:param> -->
  <!-- <xsl:param name="page.margin.inner">0.350in</xsl:param> -->
  <!-- <xsl:param name="page.margin.outer">0.350in</xsl:param> -->
  <xsl:param name="force.blank.pages" select="1"></xsl:param>

  <!-- Set Chapter numbering to roman numerals -->
  <xsl:param name="chapter.autolabel" select="'I'"/>

  <!-- Get rid of "Chapter" gentext in chapter headers -->
  <xsl:param name="local.l10n.xml" select="document('')"/>
  <l:i18n xmlns:l="http://docbook.sourceforge.net/xmlns/l10n/1.0">
    <l:l10n language="en">
      <l:context name="title-numbered">
	<l:template name="chapter" text="%n.&#160;%t"/>
	<l:template name="appendix" text="%n.&#160;%t"/>
      </l:context>
      <l:gentext key="TableofContents" text="TABLE OF CONTENTS" />
      <l:gentext key="Acknowledgements" text="ACKNOWLEDGEMENTS" />
    </l:l10n>
  </l:i18n>

  <!-- The following sets the default color to blue, selectively overriden to black so that TOC will be the right color, urgh. -->
  <xsl:attribute-set name="root.properties">
    <xsl:attribute name="color">#0374B6</xsl:attribute>
  </xsl:attribute-set>

  <xsl:attribute-set name="toc.line.properties">
    <xsl:attribute name="color">black</xsl:attribute>
  </xsl:attribute-set>

  <xsl:attribute-set name="para.properties">
    <xsl:attribute name="color">black</xsl:attribute>
  </xsl:attribute-set>

  <!-- Set chapter title properties -->
  <xsl:attribute-set name="component.title.properties">
    <xsl:attribute name="color">#0374B6</xsl:attribute>
  </xsl:attribute-set>

  <!-- Table properties -->
  <xsl:template name="table.cell.properties">
    <xsl:attribute name="color">black</xsl:attribute>
    <xsl:attribute name="keep-together.within-column">always</xsl:attribute>
  </xsl:template>

  <!-- List items -->
  <xsl:param name="orderedlist.label.width">2.2em</xsl:param>
  <xsl:attribute-set name="orderedlist.label.properties">
    <xsl:attribute name="text-align">right</xsl:attribute>
  </xsl:attribute-set>

  <!-- Cover -->
  <xsl:template name="front.cover">
    <xsl:call-template name="page.sequence">
      <xsl:with-param name="master-reference">titlepage</xsl:with-param>
      <xsl:with-param name="content">
	<fo:block xmlns:fo="http://www.w3.org/1999/XSL/Format" text-align="center">
	  <fo:external-graphic src="url(manual_images/cover.jpg)"
			       content-width="7cm"/>
	</fo:block>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>
