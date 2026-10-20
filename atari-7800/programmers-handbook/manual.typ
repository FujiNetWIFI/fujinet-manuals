// FUJINET ATARI 7800 PROGRAMMER'S HANDBOOK
// House style: the 1986 ATARI 7800 ProSystem Owner's Manual.
// Build: typst compile --font-path fonts --ignore-system-fonts manual.typ
#import "lib.typ": *

#set document(title: "FujiNet 7800 ProSystem Programmer's Handbook",
              author: "FujiNet Project")
#set page(width: 5in, height: 7.09in, fill: paper, background: page-bg,
  margin: (top: 0.5in, bottom: 0.66in, inside: 0.5in, outside: 0.42in),
  footer: folio, footer-descent: 0.12in)
#set text(font: f-body, size: 8.6pt, fill: ink, lang: "en")
#set par(justify: false, leading: 0.66em, spacing: 1.1em, first-line-indent: 0pt)
#set text(costs: (hyphenation: 220%, runt: 500%, widow: 900%, orphan: 900%))
#set smartquote(enabled: true)
#show strong: it => text(font: f-bold, weight: 600, it.body)
#show emph: it => text(font: f-bold, weight: 500, it.body)
#set list(marker: sq, indent: 2pt, body-indent: 6pt, spacing: 0.62em)
#set enum(indent: 2pt, body-indent: 6pt, spacing: 0.62em)
#show raw.where(block: false): it => text(font: f-mono, size: 0.9em, it)
#show raw.where(block: true): it => block(width: 100%, breakable: true,
  above: 0.8em, below: 0.9em, fill: panel, inset: (x: 7pt, y: 5.5pt),
  stroke: (left: 2pt + magenta, rest: 0.5pt + panel-b), {
    set par(leading: 0.36em)
    text(font: f-mono, size: codesize(it.text, 7pt), it) })
#show link: set text(fill: ink)

// ---------- headings ------------------------------------------------
#set heading(numbering: "1")
#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  context {
    let n = counter(heading).get().first()
    let num = if it.numbering == none { none }
      else if appendix.get() { numbering("A", n) } else { str(n) }
    tab(num, it.body)
  }
}
#show heading.where(level: 2): it => block(above: 1.15em, below: 0.5em,
  sticky: true, text(font: f-bold, weight: 600, size: 9.8pt, it.body))
#show heading.where(level: 3): it => block(above: 0.95em, below: 0.4em,
  sticky: true, text(font: f-bold, weight: 600, size: 8.8pt, it.body))

#include "parts/00-cover.typ"
#include "parts/01-unpack.typ"
#include "parts/02-tools.typ"
#include "parts/03-map.typ"
#include "parts/04-mailbox.typ"
#include "parts/05-display.typ"
#include "parts/06-ram.typ"
#include "parts/07-library.typ"
#include "parts/08-c.typ"
#include "parts/09-basic.typ"
#include "parts/10-first-contact.typ"
#include "parts/11-network.typ"
#include "parts/12-boot.typ"
#include "parts/13-keys.typ"
#include "parts/14-banks.typ"
#include "parts/15-tiles.typ"
#include "parts/16-ref-fuji.typ"
#include "parts/17-ref-net.typ"
#include "parts/18-ref-other.typ"
#include "parts/19-ref-cart.typ"
#include "parts/20-battleship.typ"
#include "parts/21-config.typ"
#include "parts/22-time.typ"
#include "parts/23-trouble.typ"
#include "parts/24-parts.typ"
#include "parts/apx-a.typ"
#include "parts/apx-b.typ"
#include "parts/apx-c.typ"
#include "parts/apx-d.typ"
#include "parts/99-back.typ"
