// FujiNet Manual for the Network Adapter, Model H89 FujiNet -- Operation.
// The house style is the 1979 Heathkit H88 Operation Manual (595-2268-02);
// see lib.typ and README.md.
//
//   make            -> fujinet-h89-operation-manual.pdf
//
// Copyright (C) 2026 Thomas Cherryhomes -- GPL v3 (see LICENSE)

#import "lib.typ": *

#set document(title: "FujiNet Manual for the H89 FujiNet: Operation",
  author: "Thomas Cherryhomes", keywords: ("FujiNet", "Heathkit", "H89", "HDOS", "CP/M"))
#set page(paper: "us-letter",
  margin: (top: 0.98in, bottom: 0.72in, inside: 0.72in, outside: 0.72in),
  header: running-head(), header-ascent: 0.2in)
#set text(font: f-body, size: 9.6pt, lang: "en", hyphenate: true, fill: ink,
  costs: (widow: 1000%, orphan: 1000%, runt: 300%, hyphenation: 160%))
#set par(justify: true, leading: 0.52em, spacing: 0.95em)
#set smartquote(enabled: true)
#set list(marker: text(size: 0.8em, baseline: -0.1em, sym.bullet), indent: 1.1em, body-indent: 0.9em, spacing: 0.6em)
#set enum(indent: 0.3em, body-indent: 0.7em, spacing: 0.75em)
#show emph: set text(style: "italic")

#include "parts/00-front.typ"
#include "parts/01-introduction.typ"
#include "parts/02-specifications.typ"
#include "parts/03-setup.typ"
#include "parts/04-configuration.typ"
#include "parts/05-software.typ"
#include "parts/06-config.typ"
#include "parts/07-drives.typ"
#include "parts/08-more.typ"
#include "parts/09-firmware.typ"
#include "parts/10-troubleshooting.typ"
#include "parts/11-circuit.typ"
#include "parts/12-parts.typ"
#include "parts/13-appendix.typ"
#include "parts/99-back.typ"
