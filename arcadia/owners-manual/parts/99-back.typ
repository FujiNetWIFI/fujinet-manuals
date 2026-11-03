#import "../lib.typ": *
// ---------- a page to write your own settings on --------------------
#let line-field(label) = grid(columns: (1.9in, 1fr), column-gutter: 8pt,
  align: (left + bottom, left + bottom),
  text(weight: 700, size: 10pt, upper(label)),
  box(width: 100%, height: 15pt, stroke: (bottom: 0.7pt + ink)))
#pagebreak(weak: true)
#chap(none, [My FujiNet])
Write down your settings here. If you ever start over, everything you need is
on this page.
#v(8pt)
#{
  let gap = v(9pt)
  line-field[WiFi network (SSID)]; gap
  line-field[Password]; gap
  line-field[FujiNet’s IP address]; gap
  line-field[Firmware version]; gap
  line-field[Player name]; v(16pt)
  text(weight: 700, size: 11pt)[HOSTS]
  v(4pt)
  for i in range(1, 9) {
    grid(columns: (0.35in, 1fr), column-gutter: 8pt, align: (left + bottom, left + bottom),
      text(weight: 700, size: 10pt, str(i)),
      box(width: 100%, height: 16pt, stroke: (bottom: 0.7pt + ink)))
  }
  v(14pt)
  text(weight: 700, size: 11pt)[GAMES I LIKE, AND WHERE THEY ARE]
  v(4pt)
  for i in range(4) {
    box(width: 100%, height: 16pt, stroke: (bottom: 0.7pt + ink))
    v(2pt)
  }
}

// ---------- the quick reference -------------------------------------
#pagebreak(weak: true)
#chap(none, [Quick Reference])
#{
  set par(justify: false, leading: 0.45em)
  set text(size: 9.5pt)
  let h(s) = text(weight: 700, size: 9pt, s)
  let row-sep(title) = (table.cell(colspan: 5, fill: tint, inset: (x: 5pt, y: 4pt),
    text(weight: 700, size: 9.5pt, upper(title))),)
  table(columns: (1.35in, 1.45in, 1.2in, 1.45in, 0.9in),
    inset: (x: 5pt, y: 5pt), align: left + top,
    stroke: (x, y) => (top: if y == 0 { 1pt + ink } else { none },
      bottom: 0.5pt + ink),
    table.header(h[SCREEN], h[DISC], h[ACTION, 2, ENTER], h[KEYBOARD],
      h[CLEAR]),
    ..row-sep[The FujiNet CONFIG (left hand controller)],
    [Select network], [choose], [this one], [0 skip WiFi], [listen again],
    [Character grid], [move (or 4 6 8)], [type · ENTER: OK], [0 leave],
      [erase],
    [FujiNet hosts], [choose (or 8)], [open], [1 rename · 3 info · 7 WiFi ·
      9 Lobby], [--],
    [Browser], [choose; left, right: page], [open · load], [1 up · 4 6 page ·
      5 copy · 7 filter], [to hosts],
    [Copy to host], [choose], [pick · open], [5 copy here], [cancel],
    [Game Lobby], [choose; left, right: page], [join], [0 list again],
      [your name],
    ..row-sep[The games],
    [5 Card Stud, \ Texas Hold’em], [choose a table], [join · move 2],
      [1 to 5 your move · 0 ask now], [leave],
    [Battleship], [aim; move a ship], [fire · place · ready], [5 turn · 4 6
      enemy · 0 ask now], [leave],
    [Fujitzee], [boxes; dice; ROLL], [roll · keep · score], [0 ask now],
      [leave],
    [M.U.L.E.], [walk · choose · bid], [the button], [0 sit out · START end
      turn · OPTION leave · SELECT sound], [rub out],
    ..row-sep[Everywhere],
    [Back to CONFIG], table.cell(colspan: 4)[RESET on the back of the
      cartridge, then the console’s RESET.],
    [Console RESET], table.cell(colspan: 4)[Starts the game you are playing
      over.],
  )
  v(1fr)
  align(center, text(size: 9pt, fill: gray)[Help: *fujinet.online* ·
    *github.com/FujiNetWIFI* · *discord.gg/7MfFTvD*])
}

// ---------- the back cover ------------------------------------------
// As the Owner's Manual's last page: blank, but for the line along its foot.
#pagebreak(weak: true)
#frontmatter.update(true)
#page(footer: none, {
  v(1fr)
  align(center, {
    image("../images/fujinet-logo-trans.png", width: 1.6in)
    v(6pt)
    text(size: 9pt)[A FujiNet Project Publication \ fujinet.online ·
      github.com/FujiNetWIFI]
  })
  v(1.2in)
  grid(columns: (1fr, 1fr, 1fr), align: (left + bottom, center + bottom, right + bottom),
    text(size: 9pt)[FN2001-OM REV. A],
    text(size: 9pt)[© 2026 the FujiNet Project · CC BY-SA 4.0],
    text(size: 9pt)[Printed in the FujiNet Project])
})
