// FujiNet Manual for the Network Adapter, Model H89 FujiNet -- Programming.
// The house style is the 1979 Heathkit H88 Operation Manual (595-2268-02),
// as in the Operation Manual beside this one; see lib.typ, prog.typ and
// README.md.
//
//   make                         -> fujinet-h89-programming-manual.pdf
//   typst compile --input only=08 manual.typ   one chapter (no contents)
//
// Copyright (C) 2026 Thomas Cherryhomes -- GPL v3 (see LICENSE)

#import "lib.typ": *

#set document(title: "FujiNet Manual for the H89 FujiNet: Programming",
  author: "Thomas Cherryhomes",
  keywords: ("FujiNet", "Heathkit", "H89", "HDOS", "CP/M", "Z80", "z88dk", "fujinet-lib"))
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

#let only = sys.inputs.at("only", default: none)
#let part(n, file) = if only == none or only == n { include file }

#part("00", "parts/00-front.typ")
#part("01", "parts/01-introduction.typ")
#part("02", "parts/02-model.typ")
#part("03", "parts/03-fujibus.typ")
#part("04", "parts/04-assembly.typ")
#part("05", "parts/05-native.typ")
#part("06", "parts/06-c.typ")
#part("07", "parts/07-library.typ")
#part("08", "parts/08-fuji.typ")
#part("09", "parts/09-disk.typ")
#part("10", "parts/10-network.typ")
#part("11", "parts/11-protocols.typ")
#part("12", "parts/12-clock-printer-modem.typ")
#part("13", "parts/13-netcat.typ")
#part("14", "parts/14-nget-nput.typ")
#part("15", "parts/15-iss.typ")
#part("16", "parts/16-games.typ")
#part("17", "parts/17-texas.typ")
#part("18", "parts/18-battleship.typ")
#part("19", "parts/19-fujitzee.typ")
#part("20", "parts/20-appendix.typ")
#part("99", "parts/99-back.typ")
