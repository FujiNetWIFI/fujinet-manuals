// FUJINET NES PROGRAMMER'S MANUAL
// House style: the 1985 Nintendo "Gyromite" instruction booklet.
// Build: make   (typst compile --font-path fonts --ignore-system-fonts)
#import "lib.typ": *

#set document(title: "FujiNet Programmer's Manual for the Nintendo Entertainment System",
              author: "FujiNet Project")
#set page(width: 7.5in, height: 5.75in, fill: paper,
  margin: (top: 0.42in, bottom: 0.55in, x: 0.5in),
  footer: context {
    if frontmatter.get() { return none }
    let pg = counter(page).get().first()
    set text(font: f-body, size: 7.5pt, tracking: 0pt, fill: ink)
    // the booklet's own placement: even folios at the right, odd at the left
    if calc.even(pg) { align(right, str(pg)) } else { align(left, str(pg)) }
  })
#set text(font: f-body, size: 8.8pt, fill: ink, lang: "en", tracking: track,
  costs: (hyphenation: 300%, runt: 500%, widow: 1000%, orphan: 1000%))
#set par(justify: false, leading: 0.5em, spacing: 0.85em, first-line-indent: 0pt)
#set smartquote(enabled: false)
#show emph: set text(style: "italic")
#set list(marker: text(baseline: -0.15em)[\*], indent: 0pt, body-indent: 5pt,
  spacing: 0.45em)
#set enum(indent: 0pt, body-indent: 5pt, spacing: 0.45em,
  numbering: n => text(weight: 700)[#n.])
#show raw.where(block: false): it => text(font: f-mono, size: 1.17em,
  tracking: 0pt, it)
#show link: set text(fill: ink)
#show "→": set text(font: f-mono, tracking: 0pt)
#show "←": set text(font: f-mono, tracking: 0pt)

// ---------- headings ------------------------------------------------
// Level 1: the booklet's section head -- Helvetica Bold Oblique capitals,
// flush left, no rule. Numbered like its "3. GAME A".
#set heading(numbering: "1.1")
#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  let n = counter(heading).get().first()
  block(above: 0pt, below: 0.75em, sticky: true, context {
    let num = if appendix.get() { "APPENDIX " + numbering("A", n) + ". " }
              else { str(n) + ". " }
    text(font: f-head, weight: 700, style: "italic", size: 16pt,
      tracking: 0.01em, fill: ink, num + upper(it.body))
  })
}
// Level 2: bold upright capitals, as "LOCATION OF GYRO ACCESSORIES".
#show heading.where(level: 2): it => block(above: 1.15em, below: 0.55em,
  sticky: true, text(font: f-body, weight: 700, size: 9.6pt,
    tracking: 0.05em, upper(it.body)))
// Level 3: bold, mixed case.
#show heading.where(level: 3): it => block(above: 0.95em, below: 0.4em,
  sticky: true, text(font: f-body, weight: 700, size: 9pt, it.body))

#include "parts/00-front.typ"
#include "parts/01-intro.typ"
#include "parts/02-cartridge.typ"
#include "parts/03-tools.typ"
#include "parts/04-mailbox.typ"
#include "parts/05-first.typ"
#include "parts/06-network.typ"
#include "parts/07-fuji.typ"
#include "parts/08-boot.typ"
#include "parts/09-clock.typ"
#include "parts/10-libraries.typ"
#include "parts/11-ppu.typ"
#include "parts/12-5cardstud.typ"
#include "parts/13-battleship.typ"
#include "parts/14-fujitzee.typ"
#include "parts/15-holdem.typ"
#include "parts/16-config.typ"
#include "parts/apx-a.typ"
#include "parts/apx-b.typ"
#include "parts/apx-c.typ"
#include "parts/apx-d.typ"
#include "parts/99-back.typ"
