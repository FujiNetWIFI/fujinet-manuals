#import "../lib.typ": *
#import "../figs.typ": *

// "How It Works" is a spread: it starts on a left-hand page so both halves
// face each other.
#pagebreak(weak: true, to: "even")

= How It Works

Your 2600 was built in 1977 to play cartridges. It has no network port, no
keyboard, no letters of its own, and only *128 bytes* of memory -- fewer than
the letters in this paragraph. A FujiNet cartridge puts it on the Internet
anyway. Here is the trick, in pictures.

#v(6pt)
#fig-memory()

The console cannot hold a web page, a list of games or even a long name. So
FujiNet keeps all of that in the *cartridge*, in the 4,096 bytes of address
space every cartridge has, and lets the console look at it. Most of that space
is the game itself. The rest is FujiNet's: a *slot* the console writes
questions into, a *window* where the answers appear, and pages of
*letters* the cartridge draws for it.

#v(1fr)
#let vs(a, b, c) = (text(font: f-head, weight: 700, size: 7.6pt, a), b, c)
#block(breakable: false, width: 100%, {
  set text(size: 8pt)
  table(columns: (0.95in, 1fr, 1fr), inset: (x: 5pt, y: 4pt),
    align: left + top, stroke: (x, y) => (bottom: 0.4pt + panel-b),
    table.cell(fill: ink, text(fill: white, weight: 700, size: 7.4pt)[]),
    table.cell(fill: ink, text(fill: white, weight: 700, size: 7.4pt)[THE CONSOLE, 1977]),
    table.cell(fill: ink, text(fill: white, weight: 700, size: 7.4pt)[THE CARTRIDGE, 2026]),
    ..vs([Computers], [one 6507, about 1.2 million steps a second],
         [two (the game chip and the network chip), each a hundred times faster]),
    ..vs([Memory], [128 bytes], [over a million bytes, and 8 million more beside]),
    ..vs([Storage], [the 4,096 bytes a cartridge shows it], [18 million bytes of its own, and the memory card]),
    ..vs([Network], [none], [WiFi, and through it the whole Internet]),
  )
})
#pagebreak()

== How a Question Gets Answered

#let panel4(n, title, body, back: false) = block(width: 100%, breakable: false,
  above: 0.7em, below: 0.6em, {
  grid(columns: (auto, 1fr), column-gutter: 7pt, align: (left + top, left + top),
    context text(font: f-wordmk, weight: 900, size: 22pt, fill: band-col.get(),
      top-edge: "cap-height", bottom-edge: "baseline", str(n)),
    {
      text(font: f-head, weight: 700, size: 9pt, upper(title))
      v(2pt)
      set text(size: 8.6pt)
      body
    })
  v(4pt)
  fig-chain(calc.min(n - 1, 2), back: back, all: back)
})

#panel4(1, [Ask], [The game writes its question into *the slot*, one byte at a
time. A cartridge is only meant to be read -- the connector does not even
have a wire that says "write". But FujiNet's game chip watches every address
and every byte that crosses the connector, and it catches the question as it
goes by.])

#panel4(2, [Pass it on], [The game chip hands the question to the network
chip beside it.])

#panel4(3, [Fetch], [The network chip does the work a 1977 console never
could: it joins your WiFi, reaches the server, or reads the memory card.])

#panel4(4, [Answer], [The answer goes into the cartridge's *window*. To the
console it looks as though the answer had been printed in the cartridge all
along. It simply reads it.], back: true)

== Letters, and Whole Games

*The letters.* The 2600 has no letters at all: everything on the screen is
drawn a line at a time as the TV's beam sweeps past. FujiNet's cartridge works
out the shape of every letter for it, so all the console does is copy them to
the screen -- which is why every FujiNet screen has the same square, friendly
lettering, twelve letters across and twenty-one lines down.

*Whole games.* When you load a game, FujiNet sends all of it, up to 32,768
bytes, into the cartridge's own memory. Then the menu steps aside and the
cartridge becomes that game's cartridge, page-switching and all. The console
never knows the difference.

#rules[The full story -- every address, every command, and how to write your
own FujiNet programs for the 2600 -- is in the #PH, sections 3 to 6, and in
#TO, Parts I, III and V.]
