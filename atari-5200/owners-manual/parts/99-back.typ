#import "../lib.typ": *
// ---------- a page to write your own settings on --------------------
#let line-field(label) = grid(columns: (1.15in, 1fr), column-gutter: 6pt,
  align: (left + bottom, left + bottom),
  text(weight: 700, size: 8pt, label),
  box(width: 100%, height: 11pt, stroke: (bottom: 0.6pt + ink)))
#page({
  chap(none, [My FujiNet])
  set par(justify: false)
  [Write down your settings here. If you ever start over, everything you need
  is on this page.]
  v(4pt)
  let gap = v(4pt)
  line-field[WiFi network (SSID)]; gap
  line-field[Password]; gap
  line-field[FujiNet’s IP address]; gap
  line-field[Firmware version]; gap
  line-field[Player name]; v(10pt)
  text(weight: 700, size: 9pt, fill: violet)[Hosts]
  v(2pt)
  for i in range(1, 9) {
    grid(columns: (0.25in, 1fr), column-gutter: 6pt, align: (left + bottom, left + bottom),
      text(weight: 700, size: 8pt, str(i)),
      box(width: 100%, height: 11pt, stroke: (bottom: 0.6pt + ink)))
  }
  v(8pt)
  text(weight: 700, size: 9pt, fill: violet)[Games I like, and where they are]
  v(2pt)
  for i in range(2) {
    box(width: 100%, height: 11pt, stroke: (bottom: 0.6pt + ink))
    v(1pt)
  }
})
// ---------- inside back cover: the quick reference ------------------
#frontmatter.update(true)
#pagebreak(to: "odd", weak: true)
#page(footer: none, {
  chap(none, [Quick Reference])
  set par(justify: false, leading: 0.4em)
  set text(size: 7.4pt)
  let h(s) = text(weight: 700, size: 7pt, fill: violet, s)
  let row-sep(title) = (table.cell(colspan: 5, fill: lilac, inset: (x: 4pt, y: 3pt),
    text(weight: 700, size: 7.4pt, title)),)
  table(columns: (0.74in, 1fr, 0.7in, 0.64in, 0.78in),
    inset: (x: 3pt, y: 3.6pt), align: left + top, fill: panel,
    stroke: (x, y) => (bottom: 0.4pt + panel-b),
    table.header(h[Screen], h[Stick or 2 4 6 8], h[Bottom or \#],
      h[Top or \*], h[PAUSE · START]),
    ..row-sep[The FujiNet menu],
    [SELECT NETWORK], [choose], [this one], [skip WiFi], [-- · look again],
    [Keyboard], [move], [type], [erase], [case · OK],
    [HOST SLOTS], [choose], [open], [WiFi], [rename · INFO],
    [Browser], [choose; left/right: page], [open · load], [up a folder],
      [filter · copy],
    [COPY TO …], [choose], [pick · open], [cancel · back], [-- · copy here],
    ..row-sep[The games],
    [5 Card Stud, Hold’em], [choose; your move], [sit · move], [menu],
      [help or menu · move],
    [Battleship], [aim; move a ship], [place · fire], [turn a ship],
      [menu · fire],
    [Fujitzee], [dice; the card], [roll · keep · score], [help],
      [menu · list again],
    [Fujirkle], [dice; up ROLL, down BANK], [roll · keep · bank], [help],
      [menu · menu],
    [M.U.L.E.], [walk · choose · bid], [the button], [rub out], [-- · end turn],
    ..row-sep[Everywhere],
    [Console POWER], table.cell(colspan: 4)[OFF and ON: back to the FujiNet
      menu, from any game.],
    [RESET key], table.cell(colspan: 4)[In the menu, the same as \*; in a game,
      the game’s own.],
  )
  v(1fr)
  align(center, text(size: 7pt, fill: gray)[Help: *fujinet.online* ·
    *github.com/FujiNetWIFI* · *discord.gg/7MfFTvD*])
})
// ---------- the back cover ------------------------------------------
// The booklet's back: black, the stripe, the maker's mark low and centred
// over its address, a double rule, and the part number, copyright and
// printing line along the foot.
#page(margin: 0pt, footer: none, background: none, fill: cover-k, {
  set par(justify: false)
  place(top + left, rect(width: 100%, height: 100%,
    fill: graph(c: rgb("#24232e"), w: 0.5pt, p: 0.135in)))
  place(top + left, dy: 0.84in, rect(width: 100%, height: 0.1in, fill: rainbow))
  place(top + center, dy: 4.55in, align(center, {
    image("../images/fujinet-logo-white.png", width: 0.72in)
    v(3pt)
    text(size: 6.4pt, fill: white)[A FujiNet Project Publication]
    v(9pt)
    text(size: 7.6pt, fill: white)[The FujiNet Project \ fujinet.online · github.com/FujiNetWIFI]
  }))
  place(bottom + left, dx: 0.24in, dy: -0.52in, {
    line(length: 4.52in, stroke: 0.6pt + white)
    v(-8.4pt)
    line(length: 4.52in, stroke: 0.6pt + white)
  })
  place(bottom + left, dx: 0.24in, dy: -0.24in,
    text(size: 6.6pt, fill: white)[FN5200-OM REV. A])
  place(bottom + center, dy: -0.18in, align(center,
    text(weight: 700, size: 7pt, fill: white)[© 2026 the FujiNet Project \ CC BY-SA 4.0]))
  place(bottom + right, dx: -0.24in, dy: -0.24in,
    text(size: 6.6pt, fill: white)[Printed in the FujiNet Project])
})
