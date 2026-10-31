#import "../lib.typ": *
// ---------- the cover -----------------------------------------------
// After the 1982 booklet: black, ruled with a fine grid, the rainbow stripe
// across the top, the lock-up above it at the right and the title under it,
// the console with its controllers below, the maker's mark low at the right.
#let stripe-y = 0.84in
#let stripe-h = 0.1in

#page(margin: 0pt, footer: none, background: none, fill: cover-k, {
  set par(justify: false)
  place(top + left, rect(width: 100%, height: 100%,
    fill: graph(c: rgb("#2c2b38"), w: 0.6pt, p: 0.135in)))
  // the lock-up: FUJINET 5200, the zeros round
  place(top + right, dx: -0.3in, dy: stripe-y - 0.47in, {
    text(weight: 700, size: 23pt, fill: white, tracking: -0.2pt)[FUJINET]
    h(5pt)
    text(font: f-wm, weight: 500, size: 25pt, fill: white)[5200]
  })
  place(top + left, dy: stripe-y, rect(width: 100%, height: stripe-h, fill: rainbow))
  place(top + right, dx: -0.3in, dy: stripe-y + stripe-h + 0.1in,
    text(size: 19pt, fill: white)[Owner’s Manual])
  // the console, where the booklet stands its own
  place(top + center, dy: 2.05in, image("../images/render/a52-cover.png",
    width: 4.55in))
  // the mark, where the booklet has the maker's
  place(bottom + right, dx: -0.3in, dy: -0.28in, align(center, {
    image("../images/fujinet-logo-white.png", width: 0.62in)
    v(1pt)
    text(size: 5.6pt, fill: white)[A FujiNet Project Publication]
  }))
})

// ---------- inside cover --------------------------------------------
// The booklet's inside cover is the console on a lilac band; this one is
// the cartridge.
#page(footer: none, {
  set par(justify: false)
  v(0.3in)
  bleed(inset: (y: 0.22in), align(center, {
    image("../images/render/cart-hero.png", width: 1.75in)
    v(4pt)
    text(weight: 700, size: 12pt, fill: violet)[FUJINET]
    h(4pt)
    text(font: f-wm, weight: 500, size: 13pt, fill: violet)[5200]
  }))
  v(1fr)
  set text(size: 7pt, fill: gray)
  [*FujiNet 5200 Owner’s Manual.* First edition, 2026.]
  v(0.45em)
  [Typeset after the 1982 _ATARI 5200 Owner’s Manual_ as a tribute. FujiNet is an independent project and is not affiliated with, endorsed by, or sponsored by Atari. “Atari” and “5200” are trademarks of their owner and are used here to identify the console this manual is about. The games named in it are the FujiNet project’s own, except M.U.L.E., a trademark of its owner.]
  v(0.45em)
  [This manual describes the FujiNet cartridge for the ATARI 5200 as it is meant to work. The cartridge is new, and the drawings of it are the manual’s own; where today’s firmware and games still differ, the differences are listed in the manual’s errata, kept with its sources.]
  v(0.45em)
  [Text and pictures © 2026 the FujiNet Project, CC BY-SA 4.0.]
})

// ---------- contents ------------------------------------------------
#page(footer: none, {
  v(0.25in)
  bleed(block(height: 1.05in), inset: 0pt)
  v(0.3in)
  chap(none, [Table of Contents])
  set par(justify: false)
  // built by hand: the stock entry puts a WORD JOINER before the page
  // number, and the booklet sets no leaders
  show outline.entry.where(level: 1): it => {
    v(5.6pt, weak: true)
    link(it.element.location(), text(size: 8.2pt, {
      let pre = it.prefix()
      box(width: 15pt, if pre != none { pre })
      it.body()
      h(1fr)
      it.page()
    }))
  }
  outline(title: none, depth: 1, indent: 0pt)
})
#frontmatter.update(false)
#counter(page).update(1)
