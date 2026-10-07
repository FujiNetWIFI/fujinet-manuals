// figs.typ -- the labelled line art, shared by the book and the wiki
// edition (tools/wikifig.typ renders each to a PNG).
#import "lib.typ": *

#let fig-hero() = labelled("images/render/cart-hero.png", w: 50%,
  pad: (left: 1.05in, right: 1.05in, top: 4pt, bottom: 4pt), (
  (0.30, 0.16, -0.18, 0.06, [Label\ (faces you)], left),
  (0.80, 0.07, 1.16, 0.02, [Top End\ (USB-C socket)], right),
  (0.42, 0.93, -0.18, 0.86, [Game\ Connector\ (inside the\ open end)], left),
  (0.98, 0.52, 1.18, 0.48, [Side\ (memory card\ slot is on\ the far side)], right),
))

#let fig-rear() = labelled("images/render/cart-rear.png", w: 52%,
  pad: (left: 1.0in, right: 1.0in, top: 2pt, bottom: 2pt), (
  (0.455, 0.145, 1.12, 0.07, [Status Light\ (white / orange)], right),
  (0.455, 0.215, 1.12, 0.21, [Power Light\ (red)], right),
  (0.455, 0.28, 1.12, 0.34, [Service Hole], right),
  (0.21, 0.385, -0.12, 0.30, [Service\ Holes], left),
  (0.21, 0.52, -0.12, 0.55, [RESET\ Button], left),
  (0.96, 0.24, 1.12, 0.47, [Memory\ Card], right),
))

#let fig-top() = labelled("images/render/cart-top.png", w: 88%,
    pad: (top: 2pt, right: 0.2in), (
    (0.43, 0.115, 0.92, 0.03, [USB-C\ Socket], right),
  ))

#let fig-side() = labelled("images/render/cart-side.png", w: 66%,
    pad: (top: 2pt, right: 0.4in), (
    (0.71, 0.41, 1.15, 0.30, [microSD\ Card], right),
  ))

#let fig-inside() = labelled("images/render/board-inside.png", w: 54%,
  pad: (left: 0.95in, right: 0.95in, top: 4pt, bottom: 4pt), size: 7.2pt, (
  (0.19, 0.17, -0.08, 0.10, [NETWORK CHIP\ (ESP32-S3)], left),
  (0.19, 0.03, -0.08, 0.01, [WiFi antenna], left),
  (0.087, 0.417, -0.08, 0.36, [S3 EN], left),
  (0.087, 0.49, -0.08, 0.44, [S3 BOOT], left),
  (0.087, 0.562, -0.08, 0.53, [RESET], left),
  (0.88, 0.067, 1.08, 0.03, [USB-C socket], right),
  (0.486, 0.119, 1.08, 0.11, [Status light], right),
  (0.488, 0.209, 1.08, 0.18, [Power light], right),
  (0.75, 0.24, 1.08, 0.26, [microSD socket], right),
  (0.49, 0.277, 1.08, 0.34, [BOOTSEL], right),
  (0.56, 0.565, 1.08, 0.56, [GAME CHIP\ (RP2354A)], right),
  (0.49, 0.948, 1.08, 0.90, [Game connector\ (to the console)], right),
))

#let fig-insert() = labelled("images/render/vcs-insert.png", w: 88%,
  pad: (top: 0.3in, left: 2pt, right: 2pt), (
  (0.5, 0.06, 0.20, -0.17, [FujiNet Cartridge], left),
  (0.6, 0.24, 0.80, -0.17, [Game Program Slot], right),
))

#let fig-jacks() = labelled("images/render/vcs-rear.png", w: 78%,
  pad: (top: 0.34in, left: 0.1in, right: 0.1in), (
  (0.37, 0.56, 0.18, -0.10, [Right Controller], left),
  (0.445, 0.565, 0.62, -0.10, [Left Controller], right),
  (0.43, 0.86, 0.12, 0.92, [Joystick], left),
))

#let fig-panel() = labelled("images/render/vcs-panel.png", w: 84%,
  pad: (top: 0.22in, bottom: 0.34in, left: 2pt, right: 2pt), (
  (0.137, 0.37, 0.07, -0.10, [Power Switch], center),
  (0.5, 0.15, 0.5, -0.10, [FujiNet Cartridge], center),
  (0.863, 0.37, 0.93, -0.10, [Game Reset Switch], center),
  (0.235, 0.42, 0.17, 1.10, [TV Type Switch], center),
  (0.333, 0.42, 0.50, 1.10, [Left and Right Difficulty Switches], center),
  (0.667, 0.42, 0.50, 1.075, none),
  (0.765, 0.42, 0.84, 1.10, [Game Select Switch], center),
))

// ---- How It Works: the console's memory and the cartridge's window ----
// ---- 128 bytes vs the cartridge window --------------------------------
#let ram-grid = {
  let cell(c) = box(width: 8.4pt, height: 8.4pt, fill: c, stroke: 0.4pt + ink)
  grid(columns: 16, column-gutter: 1.2pt, row-gutter: 1.2pt,
    ..range(128).map(i => cell(if i >= 4 and i < 12 { lime.lighten(30%) }
      else { rgb("#d6d6cf") })))
}
#let win-row(h, fill, title, sub) = grid(columns: (0.9in, 1fr),
  column-gutter: 6pt, align: (left + horizon, left + horizon),
  box(width: 0.9in, height: h, fill: fill, stroke: 0.7pt + ink),
  {
    text(font: f-head, weight: 700, size: 7.4pt, title)
    linebreak()
    text(size: 6.8pt, fill: gray, sub)
  })
#let window = stack(dir: ttb, spacing: 0pt,
  win-row(96pt, lime.lighten(25%), [GAME PROGRAM], [2,048 bytes of the game at a time; the cartridge swaps in more as it plays]),
  win-row(36pt, bblue.lighten(45%), [LETTERS], [the cartridge draws them here]),
  win-row(24pt, orange.lighten(30%), [ANSWERS], [replies land here]),
  win-row(24pt, red.lighten(40%), [THE SLOT], [the console writes here]),
  win-row(12pt, rgb("#cfcfc8"), [STATUS], [is it done yet?]),
)
#let fig-memory() = grid(columns: (auto, 1fr), column-gutter: 16pt, align: (left + top, left + top),
  {
    text(font: f-head, weight: 700, size: 8pt)[THE CONSOLE'S MEMORY]
    v(3pt)
    ram-grid
    v(3pt)
    set text(size: 7.2pt)
    set par(leading: 0.35em)
    box(width: 2.25in)[All 128 bytes of it, one square to a byte. A FujiNet
    program borrows only a handful
    #box(width: 6pt, height: 6pt, fill: lime.lighten(30%), stroke: 0.4pt + ink)
    to talk to the cartridge; everything else stays in the cartridge.]
  },
  {
    text(font: f-head, weight: 700, size: 8pt)[THE CARTRIDGE'S 4,096 BYTES]
    v(3pt)
    window
  },
)

// a four-stop chain with one link lit
#let fig-chain(n, back: false, all: false) = {
  let names = ([CONSOLE], [GAME\ CHIP], [NETWORK\ CHIP], [INTERNET\ OR CARD])
  let node(i) = box(width: 0.62in, height: 0.34in, radius: 2pt,
    stroke: 0.7pt + ink,
    fill: if all or i == n or i == n + 1 { band-col.get().lighten(35%) } else { panel },
    align(center + horizon, par(leading: 0.2em,
      text(font: f-head, weight: 700, size: 6.2pt, names.at(i)))))
  let arrow(i) = box(width: 0.16in, height: 0.34in, {
    let lit = all or i == n
    let c = if lit { ink } else { panel-b }
    place(horizon + left, line(start: (1pt, 0pt), end: (0.16in - 1pt, 0pt),
      stroke: (if lit { 1.2pt } else { 0.7pt }) + c))
    if lit {
      if back {
        place(horizon + left, dx: 0pt, polygon(fill: c, (0pt, 0pt), (4.5pt, -3pt), (4.5pt, 3pt)))
      } else {
        place(horizon + left, dx: 0.16in - 5pt, polygon(fill: c, (0pt, -3pt), (4.5pt, 0pt), (0pt, 3pt)))
      }
    }
  })
  context align(center, stack(dir: ltr, spacing: 0pt,
    node(0), arrow(0), node(1), arrow(1), node(2), arrow(2), node(3)))
}
