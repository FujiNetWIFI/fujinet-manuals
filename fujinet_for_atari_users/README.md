# fujinet_for_atari_users

FujiNet User's Guide for Atari Users

## Dependencies

``` sh
apt-get install docbook docbook-book docbook-defguide docbook-dsssl docbook-utils docbook-xml docbook-xsl docbook-xsl-doc-html docbook-xsl-doc-pdf docbook-xsl-doc-text docbook-xsl-nons docbook-xsl-ns fop xsltproc
```

## Building

``` sh
make
```

## Meaning of files

* figs/ All graphic figures go here.
* fonts/ All embedded fonts go here.
* fop.xml - Primarily handles font embedding referenced by stylesheet.
* fujinet_for_atari_users.xsl - The stylesheet.
* fujinet_for_atari_Users.dbk - The main docbook file.
* guide_structure.org - Used for holding notes on structure.
