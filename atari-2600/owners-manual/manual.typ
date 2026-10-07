// FUJINET OWNER'S MANUAL FOR THE ATARI 2600
// House style: the 1977 Video Computer System Owner's Manual.
// Build: typst compile --font-path fonts --ignore-system-fonts manual.typ
#import "lib.typ": *

#set document(title: "FujiNet Video Computer System Owner's Manual",
              author: "FujiNet Project")
#set page(width: 5.5in, height: 8.5in, fill: paper,
  margin: (top: 0.5in, bottom: 0.55in, inside: 0.55in, outside: 0.45in),
  footer: context {
    let pg = counter(page).get().first()
    if frontmatter.get() { none } else {
      set text(font: f-head, size: 7pt, fill: gray)
      if calc.odd(here().page()) { align(right, str(pg)) }
      else { align(left, str(pg)) }
    }
  })
#set text(font: f-body, size: 9.2pt, fill: ink, lang: "en")
#set par(justify: false, leading: 0.46em, spacing: 0.8em, first-line-indent: 0pt)
#set text(costs: (hyphenation: 300%, runt: 500%, widow: 1000%, orphan: 1000%))
#set smartquote(enabled: true)
#show emph: set text(font: f-ital, style: "italic")
#set list(marker: text(size: 9pt)[•], indent: 2pt, body-indent: 5pt, spacing: 0.45em)
#set enum(indent: 2pt, body-indent: 5pt, spacing: 0.45em)
#show raw.where(block: false): it => text(font: f-mono, size: 0.9em, it)
#show raw.where(block: true): it => context block(width: 100%, above: 0.7em,
  below: 0.8em, fill: panel, inset: (x: 8pt, y: 6pt),
  stroke: (left: 2pt + band-col.get(), rest: 0.5pt + panel-b),
  { set par(leading: 0.4em); text(font: f-mono, size: 7.6pt, it) })
#show link: set text(fill: ink)

// ---------- headings ------------------------------------------------
#set heading(numbering: "1")
#show heading.where(level: 1): it => {
  let n = counter(heading).get().first()
  let col = if n == 19 { plum } else if n == 20 { magenta }
            else { bands.at(calc.rem(n - 1, 7)) }
  band-col.update(col)
  band(n, it.body, col)
}
#show heading.where(level: 2): it => block(above: 1.1em, below: 0.5em,
  sticky: true, text(font: f-head, weight: 700, size: 10.5pt, it.body))
#show heading.where(level: 3): it => block(above: 0.9em, below: 0.4em,
  sticky: true, text(font: f-head, weight: 700, size: 9.2pt, it.body))

#include "parts/00-cover.typ"
#include "parts/01-unpack.typ"
#include "parts/02-know.typ"
#include "parts/03-how.typ"
#include "parts/04-insert.typ"
#include "parts/05-start.typ"
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
#include "parts/17-classics.typ"
#include "parts/18-maint.typ"
#include "parts/19-trouble.typ"
#include "parts/20-parts.typ"
#include "parts/99-back.typ"
