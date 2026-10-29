#import "../lib.typ": *
// ---------- the cover -----------------------------------------------
// After the 1977 booklet: the maker's mark at the top left, the console's
// name in big Bodoni italic, the title stacked at the right in black and
// gold, and below them a gold picture in a panel with rounded corners.
#page(columns: 1, margin: 0pt, footer: none, {
  set par(justify: false, leading: 0.2em)
  // the mark, where RCA stood its logo on end
  place(top + left, dx: 0.5in, dy: 0.42in,
    box(width: 0.42in, height: 1.12in, fill: gold, radius: 2pt,
      align(center + horizon, rotate(-90deg, reflow: true,
        image("../images/fujinet-logo-trans.png", width: 1.0in)))))
  place(top + left, dx: 1.1in, dy: 0.3in, {
    text(font: f-word, style: "italic", size: 54pt, fill: ink)[Studio#sym.space.nobreak;II]
  })
  place(top + left, dx: 1.14in, dy: 1.13in,
    text(weight: 700, size: 14pt, fill: gold)[FujiNet Network Cartridge])
  place(top + left, dx: 1.14in, dy: 1.42in,
    text(weight: 700, size: 10pt, fill: gold)[FN-S2])
  place(top + right, dx: -0.5in, dy: 0.4in, align(right, {
    text(weight: 700, size: 30pt, fill: ink)[Programmer’s]
    linebreak()
    text(weight: 700, size: 22pt, fill: gold)[Handbook]
    v(4pt)
    text(weight: 700, size: 16pt, fill: gold)[Assembly \ Network]
  }))
  // the picture: the cartridge in gold, a CONFIG screen beside it
  place(top + left, dx: 0.5in, dy: 2.05in,
    box(width: 9in, height: 5.1in, fill: gold, clip: true,
      radius: (top-left: 0.18in, top-right: 0.75in, bottom-left: 0.18in, bottom-right: 0.18in), {
      place(top + left, dx: 0.45in, dy: 0.55in, rotate(-3deg, crt("fw-fujitest", w: 3.1in)))
      place(top + left, dx: 1.2in, dy: 3.25in, rotate(2deg, crt("fw-hello", w: 2.2in)))
      place(top + right, dx: -0.55in, dy: 0.32in,
        rotate(4deg, image("../images/art/board-gold.png", height: 5.4in)))
    }))
})

// ---------- inside the cover ----------------------------------------
#page(columns: 1, footer: none, {
  set par(justify: false)
  v(1fr)
  grid(columns: (colw, 1fr), column-gutter: gut, [], {
    set text(size: 7.6pt, fill: gray)
    [*FujiNet Studio II Programmer’s Handbook.* First edition, 2026.]
    v(0.5em)
    [Typeset after the 1977 _RCA Studio II Owner’s Manual_ as a tribute. FujiNet is an independent project and is not affiliated with, endorsed by, or sponsored by RCA or its successors. “RCA” and “Studio II” are trademarks of their owners and are used here to name the console this handbook is about.]
    v(0.5em)
    [Every address, register, command and code fragment in this handbook is transcribed from the project sources and verified in the FujiNet MAME cartridge model against a running FujiNet adapter. No FujiNet Studio II cartridge has been built yet: where a timing or a behaviour matters, the handbook says what was measured in emulation. The sources and their commits are listed in the Parts List at the back.]
    v(0.5em)
    [Text and diagrams © 2026 the FujiNet Project, CC BY-SA 4.0. Program listings carry the licence of their repositories.]
  })
})

// ---------- contents and Important ----------------------------------
// The booklet's second page: a gold block holding the contents, and the
// FCC notice in the third column under a gold head.
#page(columns: 1, footer: none, {
  set par(justify: false)
  grid(columns: (2 * colw + gut, 1fr), column-gutter: gut,
    block(width: 100%, height: 100%, fill: gold, inset: (x: 16pt, top: 14pt, bottom: 16pt), {
      place(bottom + left, text(weight: 700, size: 30pt, fill: ink)[Contents])
      grid(columns: (1.75in, 1fr), column-gutter: 14pt, [],
        context {
          set text(size: 8.4pt, fill: ink)
          align(right, text(weight: 400, size: 8pt)[Page])
          v(2pt)
          let hs = query(heading.where(level: 1))
          for h in hs {
            let pg = counter(page).at(h.location()).first()
            let lab = if appendix.at(h.location()) {
              numbering("A", counter(heading).at(h.location()).first()) + ". "
            } else { "" }
            block(above: 0pt, below: 4.6pt,
              link(h.location(), leaders(lab + h.body, str(pg))))
          }
        })
    }),
    {
      v(2.1in)
      text(weight: 700, size: 30pt, fill: gold)[Important]
      v(8pt)
      set text(size: 8.6pt)
      [This handbook describes the FujiNet cartridge for the RCA Studio II as it is built in the FujiNet firmware today. *No cartridge has been made yet.* Every program here runs in the FujiNet model of the cartridge in MAME, talking to a real FujiNet adapter; a real console may differ where timing matters, and the handbook says where.]
      v(0.6em)
      list(
        [Turning the console off is the only way back to CONFIG from a game.],
        [Test programs against your own servers, never against a public game server.],
        [Never read the cartridge’s raster pages from a program: the cartridge serves them by position, and a stray read moves the picture.],
      )
    })
})
#counter(page).update(1)
#front.update(false)
