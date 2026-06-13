#! /usr/bin/env bash

schema_location="$(xmlcatalog "" "http://docbook.org/xml/5.0/rng/docbookxi.rnc" |
    grep "^file:///" | sed 's#^file://##')"

cat >schemas.xml <<EOF
<locatingRules xmlns="http://thaiopensource.com/ns/locating-rules/1.0">
<namespace ns="http://docbook.org/ns/docbook" uri="$schema_location"/>
</locatingRules>
EOF
