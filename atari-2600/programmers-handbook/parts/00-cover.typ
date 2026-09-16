#import "../lib.typ": *
// ---------- the cover -----------------------------------------------
#page(fill: rgb("#0b0b0b"), margin: 0.45in, footer: none, {
  set text(fill: white)
  set par(justify: false)
  place(top + left, text(font: f-head, size: 6.5pt, fill: rgb("#cfcfcf"))[© 2026 FUJINET PROJECT])
  place(top + right, text(font: f-head, size: 6.5pt, fill: rgb("#cfcfcf"))[FN2600-PH])
  v(0.35in)
  align(center, {
    text(font: f-wordmk, weight: 900, size: 44pt, fill: white)[FUJINET]
    v(-4pt)
    text(font: f-wordmk, weight: 900, size: 30pt, fill: white)[VIDEO]
    v(-10pt)
    text(font: f-wordmk, weight: 900, size: 30pt, fill: white)[COMPUTER]
    v(-10pt)
    text(font: f-wordmk, weight: 900, size: 30pt, fill: white)[SYSTEM]
  })
  v(0.22in)
  // the photo panel: real screens from the FujiNet MAME
  align(center, box(fill: rgb("#1c1c1c"), stroke: 1pt + rgb("#5a5a5a"),
    inset: 6pt, grid(columns: 4, column-gutter: 5pt,
      image("../images/screens/asm-acfg.png", width: 0.92in),
      image("../images/screens/bs-layout.png", width: 0.92in),
      image("../images/screens/bas-netget.png", width: 0.92in),
      image("../images/screens/bs-lobby.png", width: 0.92in))))
  v(0.28in)
  align(center, {
    text(font: f-head, weight: 700, size: 22pt, fill: white)[PROGRAMMER'S HANDBOOK]
    v(2pt)
    text(font: f-head, size: 10pt, fill: white)[MODEL CX2600 · FUJINET CARTRIDGE]
  })
  v(1fr)
  align(center, image("../images/fujinet-logo-white.png", width: 1.1in))
  v(0.12in)
  align(center, text(font: f-head, size: 7.5pt, fill: rgb("#cfcfcf"))[A FujiNet Project Publication])
  v(0.12in)
  align(center, text(font: f-head, size: 6.8pt, fill: rgb("#cfcfcf"))[FUJINET PROJECT · fujinet.online · github.com/FujiNetWIFI])
})

// ---------- inside cover --------------------------------------------
#page(footer: none, {
  v(1fr)
  set par(justify: false)
  set text(size: 7.6pt, fill: gray)
  [*FujiNet Video Computer System Programmer's Handbook.* First edition, 2026.]
  v(0.5em)
  [Typeset after the 1977 _Video Computer System Owner's Manual_ as a tribute. FujiNet is an independent project and is not affiliated with, endorsed by, or sponsored by Atari. "Atari" and "Video Computer System" are trademarks of their owner and are used here to identify the console this handbook is about.]
  v(0.5em)
  [Every address, register, command and code fragment in this handbook is transcribed from the live project sources and verified in the FujiNet MAME cartridge model against a running FujiNet adapter; the sources and their commits are listed in the Parts List at the back.]
  v(0.5em)
  [Text and diagrams © 2026 the FujiNet Project, CC BY-SA 4.0. Program listings carry the licence of their repositories. batari Basic is © its authors and is distributed under its own licence.]
})

// ---------- contents ------------------------------------------------
#page(footer: none, {
  block(width: 100%, fill: ink, inset: (x: 8pt, y: 5pt),
    text(font: f-head, weight: 700, size: 12.5pt, fill: white)[CONTENTS])
  v(8pt)
  set par(justify: false)
  show outline.entry.where(level: 1): it => {
    v(5pt, weak: true)
    text(font: f-head, weight: 700, size: 8.6pt, it)
  }
  show outline.entry.where(level: 2): it => text(size: 8pt, it)
  outline(title: none, depth: 2, indent: 10pt)
})
#frontmatter.update(false)
#counter(page).update(1)
