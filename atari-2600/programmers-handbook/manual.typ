// FUJINET ATARI 2600 PROGRAMMER'S HANDBOOK
// House style: the 1977 Video Computer System Owner's Manual.
// Build: typst compile --font-path fonts --ignore-system-fonts manual.typ
#import "lib.typ": *

#set document(title: "FujiNet Video Computer System Programmer's Handbook",
              author: "FujiNet Project")
#set page(width: 5.5in, height: 8.5in, fill: paper,
  margin: (top: 0.55in, bottom: 0.6in, inside: 0.6in, outside: 0.5in),
  footer: context {
    let pg = counter(page).get().first()
    if frontmatter.get() { none } else {
      set text(font: f-head, size: 7.5pt, fill: ink)
      if calc.odd(pg) { align(right, str(pg)) } else { align(left, str(pg)) }
    }
  })
#set text(font: f-body, size: 9pt, fill: ink, lang: "en")
#set par(justify: false, leading: 0.44em, spacing: 0.75em, first-line-indent: 0pt)
#set text(costs: (hyphenation: 220%, runt: 500%, widow: 900%, orphan: 900%))
#set smartquote(enabled: true)
#show emph: set text(font: f-ital, style: "italic")
#set list(marker: text(size: 9pt)[•], indent: 4pt, body-indent: 6pt, spacing: 0.4em)
#set enum(indent: 4pt, body-indent: 6pt, spacing: 0.4em)
#show raw.where(block: false): it => text(font: f-mono, size: 0.92em, it)
#show raw.where(block: true): it => context block(width: 100%, breakable: true,
  above: 0.8em, below: 0.9em, fill: panel, inset: (x: 8pt, y: 6pt),
  stroke: (left: 2pt + band-col.get(), rest: 0.5pt + panel-b), {
    set par(leading: 0.36em)
    text(font: f-mono, size: codesize(it.text, 7pt), it) })
#show link: set text(fill: ink)

// ---------- headings ------------------------------------------------
#set heading(numbering: "1.1")
#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  let n = counter(heading).get().first()
  context {
    if appendix.get() {
      let letter = numbering("A", n)
      band(letter, it.body, bands.at(calc.rem(n - 1, 7)), letter: true)
    } else {
      band-col.update(bands.at(calc.rem(n - 1, 7)))
      band(n, it.body, bands.at(calc.rem(n - 1, 7)))
    }
  }
}
#show heading.where(level: 2): it => block(above: 1.1em, below: 0.5em,
  sticky: true, text(font: f-head, weight: 700, size: 10.5pt, it.body))
#show heading.where(level: 3): it => block(above: 0.9em, below: 0.4em,
  sticky: true, text(font: f-head, weight: 700, size: 9.2pt, it.body))

#include "parts/00-cover.typ"
#include "parts/01-unpack.typ"
#include "parts/02-tools.typ"
#include "parts/03-window.typ"
#include "parts/04-mailbox.typ"
#include "parts/05-display.typ"
#include "parts/06-ram.typ"
#include "parts/07-library.typ"
#include "parts/08-basic.typ"
#include "parts/09-first-contact.typ"
#include "parts/10-network.typ"
#include "parts/11-boot.typ"
#include "parts/12-keys.typ"
#include "parts/13-banks.typ"
#include "parts/14-board.typ"
#include "parts/15-ref-fuji.typ"
#include "parts/16-ref-net.typ"
#include "parts/17-ref-other.typ"
#include "parts/18-ref-cart.typ"
#include "parts/19-battleship.typ"
#include "parts/20-config.typ"
#include "parts/21-time.typ"
#include "parts/22-trouble.typ"
#include "parts/23-parts.typ"
#include "parts/apx-a.typ"
#include "parts/apx-b.typ"
#include "parts/apx-c.typ"
#include "parts/apx-d.typ"
