#import "../lib.typ": *
#import "../figs.typ": *

= How It Works

Your 5200 was built in 1982 to play cartridges. It has no network port, no
keyboard and no disk drive, and its connector for a cartridge has no wire that
says “write”: the console can *read* a cartridge, but it has no way to send it
anything at all. A FujiNet cartridge puts it on the Internet anyway. Here is
the trick.

#plate(window-strip, caption: [The 32K the console sees in the cartridge
slot, while the FujiNet menu or a FujiNet game is running.])

The console sees a cartridge as 32,768 bytes it can look at. FujiNet’s game
chip watches *every* look: which address the console reads, at the moment it
reads it. So FujiNet sets aside a few pages of that space. Reading in the
*questions* pages is how the console speaks -- the address it reads spells the
byte it means. The *answers* pages are where FujiNet puts what it found out,
and the console reads them like any other part of a cartridge.

#v(1fr)
#block(breakable: false, tbl((0.8in, 1fr, 1fr),
  th[], th[The console, 1982], th[The cartridge, 2026],
  [*Computers*], [one 6502C, about 1.8 million steps a second],
  [two (the game chip and the network chip), each over a hundred times
   faster],
  [*Memory*], [16,384 bytes], [over half a million bytes, and 8 million more
   beside],
  [*Storage*], [the 32K a cartridge shows it], [18 million bytes of its own,
   and the memory card],
  [*Network*], [none], [WiFi, and through it the whole Internet],
))
#pagebreak()

== How a Question Gets Answered

#let panel4(n, title, body) = block(width: 100%, breakable: false,
  above: 0.8em, below: 0.7em,
  grid(columns: (auto, 1fr), column-gutter: 8pt, align: (left + top, left + top),
    text(font: f-wm, weight: 500, size: 24pt, fill: violet,
      top-edge: "cap-height", bottom-edge: "baseline", str(n)),
    {
      text(weight: 700, size: 8.6pt, fill: violet, upper(title))
      v(2pt, weak: true)
      body
    }))

#panel4(1, [Ask], [The program reads its question out of the questions pages,
one byte at a time: to say 65, it reads the 65th place in the page. Nothing
crosses the connector but the address, and the game chip catches each one as
it goes by.])

#panel4(2, [Pass it on], [The game chip hands the question to the network chip
beside it.])

#panel4(3, [Fetch], [The network chip does the work a 1982 console never
could: it joins your WiFi, reaches the server, or reads the memory card.])

#panel4(4, [Answer], [The answer goes into the answers pages. To the console
it looks as though it had been printed in the cartridge all along. It simply
reads it.])

#plate(flow(
  nodebox([YOUR 5200], sub: [reads], w: 0.8in), biarrow(w: 0.32in),
  nodebox([GAME CHIP], sub: [listens], w: 0.8in), biarrow(w: 0.32in),
  nodebox([NETWORK CHIP], sub: [fetches], w: 0.85in), biarrow(w: 0.32in),
  nodebox([THE WORLD], sub: [WiFi], w: 0.75in)))

== Whole Games

When you load a game, FujiNet sends all of it -- up to 131,072 bytes -- into
the game chip’s own memory. Then the menu steps aside and the cartridge
becomes that game’s cartridge: a plain one, a two-chip one, Bounty Bob Strikes
Back’s, or a 128K Super Cart, page-switching and all. The console starts the
game just as it would at power-on, and never knows the difference.

#rules[The full story -- every address, every command, and how to write your
own FujiNet programs for the 5200 -- is in the #PH, Sections 3, 4, 13 and 15.]
