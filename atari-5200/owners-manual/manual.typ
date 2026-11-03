// FUJINET OWNER'S MANUAL FOR THE ATARI 5200
// House style: the 1982 ATARI 5200 Owner's Manual.
// Build: typst compile --font-path fonts --ignore-system-fonts manual.typ
#import "lib.typ": *

#set document(title: "FujiNet 5200 Owner's Manual", author: "FujiNet Project")
#set page(width: 5in, height: 7in, fill: paper, background: page-bg,
  margin: (top: 0.5in, bottom: 0.62in, left: m-left, right: m-right),
  footer: folio, footer-descent: 0.14in)
#set text(font: f-body, size: 8.8pt, fill: ink, lang: "en")
#set par(justify: false, leading: 0.62em, spacing: 1.05em, first-line-indent: 0pt)
#set text(costs: (hyphenation: 220%, runt: 500%, widow: 900%, orphan: 900%))
#set smartquote(enabled: true)
#show strong: it => text(weight: 700, it.body)
#show emph: it => text(style: "oblique", it.body)
#set list(marker: dot, indent: 1pt, body-indent: 5pt, spacing: 0.6em)
#set enum(indent: 1pt, body-indent: 5pt, spacing: 0.6em)
#show raw.where(block: false): it => text(font: f-mono, size: 0.92em, it)
#show raw.where(block: true): it => block(width: 100%, above: 0.8em,
  below: 0.9em, fill: panel, inset: (x: 7pt, y: 5.5pt),
  stroke: (left: 2pt + violet, rest: 0.5pt + panel-b), {
    set par(leading: 0.4em)
    text(font: f-mono, size: 7.4pt, it) })
#show link: set text(fill: ink)

// ---------- headings ------------------------------------------------
// Each section starts a new page, as the booklet's do, unless the part
// asks to run on (the booklet's 6 and 7 share a page).
#set heading(numbering: "1", supplement: [Section])
#show heading.where(level: 1): it => {
  context if not run-on.get() { pagebreak(weak: true) }
  run-on.update(false)
  context {
    let num = if it.numbering == none { none }
      else { str(counter(heading).get().first()) }
    chap(num, it.body)
  }
}
#show heading.where(level: 2): it => block(above: 1.2em, below: 0.55em,
  sticky: true, pad(left: -hang,
    text(weight: 700, size: 10.2pt, fill: violet, it.body)))
#show heading.where(level: 3): it => block(above: 0.95em, below: 0.45em,
  sticky: true, text(weight: 700, size: 9pt, fill: violet, it.body))

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
#include "parts/16-fujirkle.typ"
#include "parts/17-mule.typ"
#include "parts/18-maint.typ"
#include "parts/19-trouble.typ"
#include "parts/20-parts.typ"
#include "parts/99-back.typ"
