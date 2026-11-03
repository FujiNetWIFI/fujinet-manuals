// FUJINET OWNER'S MANUAL FOR THE EMERSON ARCADIA-2001
// House style: the 1982 Emerson ARCADIA-2001 Owner's Manual (ADV-1) and the
// Emerson game booklets (arcadia/learn/).
// Build: typst compile --font-path fonts --ignore-system-fonts manual.typ
#import "lib.typ": *

#set document(title: "FujiNet Arcadia 2001 Owner's Manual", author: "FujiNet Project")
#set page(width: 8.5in, height: 11in, fill: paper,
  margin: (top: 0.8in, bottom: 0.95in, left: m-left, right: m-right),
  footer: folio, footer-descent: 0.3in)
#set text(font: f-body, size: 11pt, fill: ink, lang: "en")
#set par(justify: false, leading: 0.68em, spacing: 1.15em, first-line-indent: 0pt)
#set text(costs: (hyphenation: 300%, runt: 500%, widow: 900%, orphan: 900%))
#set smartquote(enabled: true)
#show strong: it => text(weight: 700, it.body)
#show emph: it => text(style: "oblique", it.body)
#set list(marker: [--], indent: 0pt, body-indent: 8pt, spacing: 0.75em)
#set enum(indent: 0pt, body-indent: 8pt, spacing: 0.75em)
#show link: set text(fill: ink)
// file names and addresses: the Owner's Manual has no typewriter face
#show raw: it => text(font: f-body, weight: 700, it.text)

// ---------- headings ------------------------------------------------
// Each section starts a new page, as the Owner's Manual's do. In a game
// section (booklet state set) the second-level heads take the booklets'
// roman numerals and the steps their double spacing.
#set heading(numbering: "1", supplement: [Section])
#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  roman.update(0)
  context {
    let num = if it.numbering == none { none }
      else { str(counter(heading).get().first()) }
    if booklet.get() {
      let hf = bandfile.get()
      band(it.body, num: num, host: if hf != none { hf.at(0) },
        file: if hf != none { hf.at(1) })
    } else {
      chap(num, it.body)
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
#show heading.where(level: 3): it => block(above: 1.1em, below: 0.5em,
  sticky: true, text(weight: 700, size: 11pt, it.body))

#include "parts/00-cover.typ"
#include "parts/01-unpack.typ"
#include "parts/02-know.typ"
#include "parts/03-how.typ"
#include "parts/04-insert.typ"
#include "parts/05-controller.typ"
#include "parts/06-wifi.typ"
#include "parts/07-hosts.typ"
#include "parts/08-loading.typ"
#include "parts/09-copy.typ"
#include "parts/10-info.typ"
#include "parts/11-lobby.typ"
#include "parts/12-5cs.typ"
#include "parts/13-holdem.typ"
#include "parts/14-battleship.typ"
#include "parts/15-fujitzee.typ"
#include "parts/16-mule.typ"
#include "parts/17-library.typ"
#include "parts/18-go.typ"
#include "parts/19-maint.typ"
#include "parts/20-trouble.typ"
#include "parts/21-parts.typ"
#include "parts/99-back.typ"
