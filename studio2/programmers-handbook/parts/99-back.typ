#import "../lib.typ": *
// ---------- the back cover ------------------------------------------
// After the booklet's back: the invitation in gold at the left, what is
// available in the middle, the dealer line across the foot, the mark at
// the bottom right.
#front.update(true)
#pagebreak(to: "even", weak: true)
#page(columns: 1, footer: none, {
  set par(justify: false, leading: 0.3em)
  grid(columns: (colw, colw, colw), column-gutter: gut,
    { v(1.6in)
      text(weight: 700, size: 17pt, fill: gold)[No limit to your fun and action when you add FujiNet programs to your #wordmark() library.] },
    { v(1.6in)
      set par(leading: 0.5em)
      text(weight: 700, size: 13pt)[Here’s what’s currently available:]
      v(6pt)
      [*CONFIG*---hosts, WiFi and the SD card, built into every cartridge.]
      v(4pt)
      [*5 Card Stud*---poker against the world.]
      v(4pt)
      [*Battleship*---four boards, two players and two bots.]
      v(4pt)
      [*netcat*---talk to any TCP server, one line at a time.] },
    { v(1.6in)
      set par(leading: 0.5em)
      text(weight: 700, size: 13pt)[Write your own]
      v(6pt)
      [This handbook carries everything the cartridge and the FujiNet answer, with a program for every part of it.]
      v(6pt)
      [*… and more on the way!*] })
  place(bottom + left, dy: -0.15in, {
    text(weight: 700, size: 26pt, fill: gold)[See the FujiNet project on GitHub.]
    v(6pt)
    text(weight: 700, size: 7.6pt)[github.com/FujiNetWIFI #h(1em) fujinet.online #h(1em) © 2026 the FujiNet Project. CC BY-SA 4.0]
    v(2pt)
    text(size: 6.8pt)[FN-S2-PH (REV.)]
  })
  place(bottom + right, dy: -0.18in, image("../images/fujinet-logo-trans.png", width: 1.3in))
})
