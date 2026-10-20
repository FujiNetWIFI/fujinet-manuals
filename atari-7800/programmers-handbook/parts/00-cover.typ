#import "../lib.typ": *
// ---------- the cover -----------------------------------------------
// After the 1986 booklet: grey graph paper above, the wordmark in magenta,
// a big white title, a magenta double rule, a perspective floor below, and
// the band across the foot.
#let cover-split = 2.62in
#let floor(w, h) = {
  // a floor of graph paper in perspective, vanishing above the page
  let vx = w / 2
  let vy = -1.9in
  let lines = ()
  for i in range(-16, 17) {
    let bx = vx + i * 0.62in
    // where the ray from the vanishing point crosses y = 0
    let t = (0pt - vy) / (h - vy)
    let tx = vx + (bx - vx) * t
    lines.push(line(start: (tx, 0pt), end: (bx, h), stroke: 0.55pt + ink))
  }
  let y = 0.07in
  let d = 0.07in
  while y < h {
    lines.push(line(start: (0pt, y), end: (w, y), stroke: 0.55pt + ink))
    d = d * 1.32
    y += d
  }
  box(width: w, height: h, clip: true, { for l in lines { place(top + left, l) } })
}

#page(margin: 0pt, footer: none, background: none, fill: white, {
  set par(justify: false)
  // the grey half
  place(top + left, rect(width: 100%, height: cover-split, fill: cover-g))
  place(top + left, rect(width: 100%, height: cover-split, fill: graph(c: white, w: 0.7pt)))
  place(top + right, dx: -0.3in, dy: 0.22in,
    text(font: f-bold, weight: 500, size: 6pt, fill: ink)[FN7800-PH])
  // the lock-up: FUJINET, 7800 turned on its side, ProSystem
  place(top + left, dx: 0.42in, dy: 0.44in, {
    box(text(font: f-ultra, weight: 800, size: 38pt, fill: magenta, tracking: -0.5pt)[FUJINET])
    h(2pt)
    box(baseline: -1pt, rotate(-90deg, reflow: true,
      text(font: f-ultra, weight: 800, size: 11.5pt, fill: magenta)[7800]))
  })
  place(top + left, dx: 0.36in, dy: 1.12in,
    text(font: f-ultra, weight: 800, size: 55pt, fill: white, tracking: -1pt)[ProSystem])
  // the double rule
  place(top + left, dy: cover-split - 0.16in, rect(width: 100%, height: 1.3pt, fill: magenta))
  place(top + left, dy: cover-split - 0.12in, rect(width: 100%, height: 0.12in, fill: magenta))
  // the floor, and real screens standing on it
  place(top + left, dy: cover-split, floor(5in, 7.09in - cover-split - band-h))
  place(top + left, dx: 0.3in, dy: cover-split + 0.42in,
    rotate(-4deg, tvframe("images/screens/config-hosts.png", 1.95in)))
  place(top + left, dx: 2.5in, dy: cover-split + 0.22in,
    rotate(3deg, tvframe("images/screens/bs-game.png", 2.1in)))
  place(top + left, dx: 1.35in, dy: cover-split + 1.72in,
    rotate(-1.5deg, tvframe("images/screens/asm-fujitest.png", 1.75in)))
  // the title, where the booklet says Owner's Manual
  place(bottom + left, dx: 0.42in, dy: -band-h - 0.2in,
    box(fill: white, inset: (x: 5pt, y: 3pt),
      text(font: f-bold, weight: 500, size: 17pt, fill: magenta)[Programmer's Handbook]))
  place(bottom + left, rect(width: 100%, height: band-h, fill: magenta))
})

// ---------- inside cover --------------------------------------------
#page(footer: none, {
  v(1fr)
  set par(justify: false)
  set text(size: 7.2pt, fill: gray)
  [*FujiNet 7800 ProSystem Programmer's Handbook.* First edition, 2026.]
  v(0.5em)
  [Typeset after the 1986 _ATARI 7800 ProSystem Owner's Manual_ as a tribute. FujiNet is an independent project and is not affiliated with, endorsed by, or sponsored by Atari. “Atari”, “7800” and “ProSystem” are trademarks of their owner and are used here to identify the console this handbook is about.]
  v(0.5em)
  [Every address, register, command and code fragment in this handbook is transcribed from the live project sources and verified in the FujiNet MAME cartridge model against a running FujiNet adapter; the sources and their commits are listed in the Parts List at the back.]
  v(0.5em)
  [Text and diagrams © 2026 the FujiNet Project, CC BY-SA 4.0. Program listings carry the licence of their repositories. 7800basic and cc65 are © their authors and are distributed under their own licences.]
})

// ---------- contents ------------------------------------------------
#page(footer: none, {
  tab(none, [Table of Contents])
  set par(justify: false)
  v(4pt)
  // built by hand: the stock entry puts a WORD JOINER before the page
  // number, which Eras lacks
  show outline.entry.where(level: 1): it => {
    v(7.5pt, weak: true)
    link(it.element.location(), text(size: 8.8pt, {
      let pre = it.prefix()
      box(width: 15pt, if pre != none { pre })
      it.body()
      box(width: 1fr, inset: (left: 3pt, right: 3pt), repeat(gap: 2.2pt)[.])
      it.page()
    }))
  }
  outline(title: none, depth: 1, indent: 0pt)
})
#frontmatter.update(false)
#counter(page).update(1)
