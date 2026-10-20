// FUJINET RCA STUDIO II PROGRAMMER'S HANDBOOK
// House style: the 1977 RCA Studio II Owner's Manual.
// Build: typst compile --font-path fonts --ignore-system-fonts manual.typ
#import "lib.typ": *

#set document(title: "FujiNet Studio II Programmer's Handbook",
              author: "FujiNet Project")
#set page(width: page-w, height: page-h, fill: paper, columns: 3,
  margin: (top: m-top, bottom: m-bot, inside: m-in, outside: m-out),
  footer: folio, footer-descent: 0.2in)
#set columns(gutter: gut)
#set text(font: f-body, size: 8.8pt, fill: ink, lang: "en")
#set par(justify: false, leading: 0.52em, spacing: 0.95em, first-line-indent: 0pt)
#set text(costs: (hyphenation: 300%, runt: 500%, widow: 1000%, orphan: 1000%))
#set smartquote(enabled: true)
#show "Studio II": wordmark()
#show strong: it => text(weight: 700, it.body)
#show emph: it => text(style: "italic", it.body)
#set list(marker: dot, indent: 1pt, body-indent: 6pt, spacing: 0.6em)
#set enum(indent: 1pt, body-indent: 5pt, spacing: 0.6em)
#show raw.where(block: false): it => mono(it.text)
#show raw.where(block: true): it => codeblock(it.text)
#show link: set text(fill: ink)

// ---------- headings ------------------------------------------------
// A chapter opens on a new page. Plain: the gold head dropped into the
// first column, the text under it. Banner: the head across the top with a
// row of screens beside it, as the booklet opens each game.
#set heading(numbering: none)
#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  context {
    let art = opener-art.get()
    let title = {
      set par(leading: 0.18em, justify: false)
      text(weight: 700, fill: gold, it.body)
    }
    if art == none {
      v(if refpage.get() { 0.15in } else { 1.55in })
      if appendix.get() {
        let n = counter(heading).get().first()
        block(below: 3pt, sticky: true, text(weight: 700, size: 9pt, fill: gold-ink,
          tracking: 0.6pt, "APPENDIX " + numbering("A", n)))
      }
      block(below: 14pt, sticky: true, width: 100%, text(size: 25pt, title))
    } else {
      // the title takes one column (art beside it in two) or two
      let split = art.at("split", default: 2)
      let tw = if split == 1 { colw } else { 2 * colw + gut }
      let ts = if split == 1 { 25pt } else { 34pt }
      place(top, float: true, scope: "parent", clearance: 18pt,
        grid(columns: (tw, 1fr), column-gutter: gut,
          align: (left + bottom, right + bottom), {
            text(size: ts, title)
            if art.at("sub", default: none) != none {
              v(3pt)
              text(weight: 700, size: 15pt, fill: gold, art.sub)
            }
          },
          art.at("art", default: none)))
    }
  }
  opener-art.update(none)
}
// A head never strands at the foot of a column: with too little room left
// it moves to the next one, as the booklet keeps one topic to a column.
#show heading.where(level: 2): it => {
  block(above: 1.4em, below: 0.6em, sticky: true, {
    set par(leading: 0.22em, justify: false)
    text(weight: 700, size: 14.5pt, fill: gold, it.body)
  })
}
#show heading.where(level: 3): it => block(above: 1.1em, below: 0.45em,
  sticky: true, text(weight: 700, size: 9.6pt, it.body))

#include "parts/00-cover.typ"
#include "parts/01-intro.typ"
#include "parts/02-tools.typ"
#include "parts/03-map.typ"
#include "parts/04-mailbox.typ"
#include "parts/05-display.typ"
#include "parts/06-ram.typ"
#include "parts/07-runtime.typ"
#include "parts/08-pages.typ"
#include "parts/09-keypads.typ"
#include "parts/10-first-contact.typ"
#include "parts/11-network.typ"
#include "parts/12-netcat.typ"
#include "parts/13-boot.typ"
#include "parts/14-keys.typ"
#include "parts/15-glyphs.typ"
#include "parts/16-ref-fuji.typ"
#include "parts/17-ref-net.typ"
#include "parts/18-ref-other.typ"
#include "parts/19-ref-cart.typ"
#include "parts/20-battleship.typ"
#include "parts/21-5cardstud.typ"
#include "parts/22-config.typ"
#include "parts/23-time.typ"
#include "parts/24-trouble.typ"
#include "parts/25-parts.typ"
#include "parts/apx-a.typ"
#include "parts/apx-b.typ"
#include "parts/apx-c.typ"
#include "parts/apx-d.typ"
#include "parts/99-back.typ"
