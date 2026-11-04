// FUJINET PROGRAMMER'S HANDBOOK FOR THE EMERSON ARCADIA-2001
// House style: the Arcadia Owner's Manual's, after the 1982 Emerson
// ARCADIA-2001 Owner's Manual (ADV-1) and the Emerson game booklets.
// Build: typst compile --font-path fonts --ignore-system-fonts manual.typ
#import "lib.typ": *

#set document(title: "FujiNet Arcadia 2001 Programmer's Handbook",
              author: "FujiNet Project")
#set page(width: 8.5in, height: 11in, fill: paper,
  margin: (top: 0.8in, bottom: 0.95in, left: m-left, right: m-right),
  footer: folio, footer-descent: 0.3in)
#set text(font: f-body, size: 10.5pt, fill: ink, lang: "en")
#set par(justify: false, leading: 0.66em, spacing: 1.1em, first-line-indent: 0pt)
#set text(costs: (hyphenation: 300%, runt: 500%, widow: 1000%, orphan: 1000%))
#set smartquote(enabled: true)
#show strong: it => text(weight: 700, it.body)
#show emph: it => text(style: "oblique", it.body)
#set list(marker: [--], indent: 0pt, body-indent: 8pt, spacing: 0.7em)
#set enum(indent: 0pt, body-indent: 8pt, spacing: 0.7em)
#show link: set text(fill: ink)
#show raw.where(block: false): it => mono(it.text)
#show raw.where(block: true): it => codeblock(it.text)

// ---------- headings ------------------------------------------------
// Each section starts a new page, as the Owner's Manual's do. In a game
// chapter (booklet state set) the second-level heads take the booklets'
// roman numerals.
#set heading(numbering: "1", supplement: [Section])
#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  roman.update(0)
  context {
    let num = if it.numbering == none { none }
      else if appendix.get() { numbering("A", counter(heading).get().first()) }
      else { str(counter(heading).get().first()) }
    if booklet.get() {
      let hf = bandfile.get()
      band(it.body, num: num, host: if hf != none { hf.at(0) },
        file: if hf != none { hf.at(1) })
    } else {
      chap(if appendix.get() and num != none { num } else { num }, it.body)
    }
  }
}
#show heading.where(level: 2): it => context {
  if booklet.get() {
    roman.step()
    block(above: 1.5em, below: 0.75em, sticky: true, {
      set text(weight: 700, size: 13pt, tracking: 0.3pt)
      context box(width: 0.42in, numbering("I.", roman.get().first()))
      upper(it.body)
    })
  } else {
    block(above: 1.5em, below: 0.65em, sticky: true,
      text(weight: 700, size: 12.5pt, tracking: 0.3pt, upper(it.body)))
  }
}
#show heading.where(level: 3): it => block(above: 1.15em, below: 0.5em,
  sticky: true, text(weight: 700, size: 10.8pt, it.body))

#include "parts/00-cover.typ"
#include "parts/01-unpack.typ"
#include "parts/02-tools.typ"
#include "parts/03-map.typ"
#include "parts/04-mailbox.typ"
#include "parts/05-display.typ"
#include "parts/06-ram.typ"
#include "parts/07-library.typ"
#include "parts/08-pages.typ"
#include "parts/09-pads.typ"
#include "parts/10-first-contact.typ"
#include "parts/11-network.typ"
#include "parts/12-netcat.typ"
#include "parts/13-boot.typ"
#include "parts/14-keys.typ"
#include "parts/15-banks.typ"
#include "parts/16-uvi.typ"
#include "parts/17-ref-fuji.typ"
#include "parts/18-ref-net.typ"
#include "parts/19-ref-other.typ"
#include "parts/20-ref-cart.typ"
#include "parts/21-battleship.typ"
#include "parts/22-5cardstud.typ"
#include "parts/23-config.typ"
#include "parts/24-time.typ"
#include "parts/25-trouble.typ"
#include "parts/26-parts.typ"
#include "parts/apx-a.typ"
#include "parts/apx-b.typ"
#include "parts/apx-c.typ"
#include "parts/apx-d.typ"
#include "parts/99-back.typ"
