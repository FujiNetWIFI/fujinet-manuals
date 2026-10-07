#import "../lib.typ": *
// ---------- inside back cover: the quick reference ---------------------
// ---------- a page to write your own settings on, as 1977 asked for the
// model number -------------------------------------------------------
#page({
  block(width: 100%, fill: ink, inset: (x: 8pt, y: 5pt),
    text(font: f-head, weight: 700, size: 12.5pt, fill: white)[MY FUJINET])
  v(6pt)
  set par(justify: false)
  [Write down your settings here. If you ever start over, everything you
  need is on this page.]
  v(8pt)
  let line-field(label, w: 1fr) = grid(columns: (1.1in, w), column-gutter: 6pt,
    align: (left + bottom, left + bottom),
    text(font: f-head, weight: 700, size: 8pt, label),
    box(width: 100%, height: 14pt, stroke: (bottom: 0.6pt + ink)))
  let gap = v(7pt)
  line-field[WiFi network (SSID)]; gap
  line-field[Password]; gap
  line-field[FujiNet's IP address]; gap
  line-field[Firmware version]; gap
  line-field[Player name]; v(14pt)
  text(font: f-head, weight: 700, size: 9pt)[HOSTS]
  v(2pt)
  for i in range(1, 9) {
    grid(columns: (0.25in, 1fr), column-gutter: 6pt, align: (left + bottom, left + bottom),
      text(font: f-head, weight: 700, size: 8pt, str(i)),
      box(width: 100%, height: 14pt, stroke: (bottom: 0.6pt + ink)))
    v(4pt)
  }
  v(10pt)
  text(font: f-head, weight: 700, size: 9pt)[GAMES I LIKE, AND WHERE THEY ARE]
  v(2pt)
  for i in range(3) {
    box(width: 100%, height: 14pt, stroke: (bottom: 0.6pt + ink))
    v(4pt)
  }
})
#page(footer: none, {
  block(width: 100%, fill: ink, inset: (x: 8pt, y: 5pt),
    text(font: f-head, weight: 700, size: 12.5pt, fill: white)[QUICK REFERENCE])
  v(6pt)
  set par(justify: false, leading: 0.35em)
  set text(size: 7pt)
  let h(s) = text(font: f-head, weight: 700, size: 6.6pt, fill: white, s)
  let row-sep(title) = (table.cell(colspan: 5, fill: panel, inset: (x: 4pt, y: 2.5pt),
    text(font: f-head, weight: 700, size: 6.8pt, upper(title))),)
  table(columns: (0.95in, 1fr, 0.78in, 0.78in, 0.78in),
    inset: (x: 3.5pt, y: 3pt), align: left + top,
    stroke: (x, y) => (bottom: 0.4pt + panel-b),
    table.header(
      table.cell(fill: ink, h[SCREEN]), table.cell(fill: ink, h[JOYSTICK]),
      table.cell(fill: ink, h[FIRE]), table.cell(fill: ink, h[GAME SELECT]),
      table.cell(fill: ink, h[GAME RESET])),
    ..row-sep[The FujiNet menu],
    [PICK NET], [up/down: network], [choose it], [skip WiFi], [--],
    [Keyboard], [move the \^], [type], [ACCEPT · CANCEL · CLEAR], [--],
    [FN HOSTS], [up/down: host], [open it], [INFO · RENAME · WIFI · LOBBY], [--],
    [FN BROWSE], [up/down; right: next page; left: back page / up a folder], [open folder · load game], [UP DIR · FILTER · INFO · COPY · COPY HERE], [--],
    [Any menu], [], [], [closes the menu], [],
    ..row-sep[The Lobby],
    [LOBBY], [up/down: table; left/right: page], [join], [your name], [refresh],
    [ENTER NAME], [move], [type], [erase], [done],
    ..row-sep[The games],
    [5 Card Stud, Texas Hold'em], [up/down: move; right: poll; left: menu], [make the move], [hold: purses], [TABLE MENU],
    [Battleship: placing], [move the ship], [place it], [turn it], [GAME MENU],
    [Battleship: battle], [aim], [fire], [poll], [GAME MENU],
    [Fujitzee], [dice; up to the card; up/down rows], [roll · hold · score · ready], [MENU], [poll],
    [M.U.L.E.], [walk · choose · bid · declare], [start · join · claim · install …], [end turn], [hold 1 s: leave],
    [Name screens (games)], [move], [type; OK finishes], [--], [Fujitzee: done],
    ..row-sep[Switches],
    [Left difficulty], table.cell(colspan: 4)[At *A*: Fujitzee shows the standings; M.U.L.E. turns the sound off. In the networked classics each player's own switch counts.],
    [TV Type], table.cell(colspan: 4)[Colour or black and white, as always. In the networked classics it stays your own.],
    [Cartridge RESET], table.cell(colspan: 4)[Back to the FujiNet menu, from anywhere.],
  )
  v(1fr)
  align(center, text(size: 7pt, fill: gray)[Help: *fujinet.online* · *github.com/FujiNetWIFI* · *discord.gg/7MfFTvD*])
})
// ---------- the back cover: black, the logo, the address, as 1977 ------
#page(fill: rgb("#0b0b0b"), margin: 0.45in, footer: none, {
  set text(fill: white)
  v(1fr)
  align(center, image("../images/fujinet-logo-white.png", width: 1.5in))
  v(0.12in)
  align(center, text(font: f-head, size: 8pt, fill: rgb("#cfcfcf"))[A Worldwide Community Project])
  v(0.22in)
  align(center, text(font: f-head, size: 6.8pt, fill: rgb("#cfcfcf"))[FUJINET PROJECT · fujinet.online · github.com/FujiNetWIFI · discord.gg/7MfFTvD])
})
