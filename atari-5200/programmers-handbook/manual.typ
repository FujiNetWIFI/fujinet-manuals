// FUJINET ATARI 5200 PROGRAMMER'S HANDBOOK
// House style: the 1982 ATARI 5200 Owner's Manual.
// Build: typst compile --font-path fonts --ignore-system-fonts manual.typ
#import "lib.typ": *

#set document(title: "FujiNet 5200 Programmer's Handbook",
              author: "FujiNet Project")
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
#show raw.where(block: false): it => text(font: f-mono, size: 0.94em, it)
#show raw.where(block: true): it => block(width: 100%, breakable: true,
  above: 0.8em, below: 0.9em, fill: panel, inset: (x: 7pt, y: 5.5pt),
  stroke: (left: 2pt + violet, rest: 0.5pt + panel-b), {
    set par(leading: 0.36em)
    text(font: f-mono, size: codesize(it.text, 7pt), it) })
#show link: set text(fill: ink)

// ---------- headings ------------------------------------------------
#set heading(numbering: "1", supplement: [Section])
#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  context {
    let n = counter(heading).get().first()
    let num = if it.numbering == none { none }
      else if appendix.get() { numbering("A", n) } else { str(n) }
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
#include "parts/02-tools.typ"
#include "parts/03-map.typ"
#include "parts/04-mailbox.typ"
#include "parts/05-display.typ"
#include "parts/06-ram.typ"
#include "parts/07-library.typ"
#include "parts/08-c.typ"
#include "parts/09-pads.typ"
#include "parts/10-first-contact.typ"
#include "parts/11-network.typ"
#include "parts/12-netcat.typ"
#include "parts/13-boot.typ"
#include "parts/14-keys.typ"
#include "parts/15-banks.typ"
#include "parts/16-antic.typ"
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
