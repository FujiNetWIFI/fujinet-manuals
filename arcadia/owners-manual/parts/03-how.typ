#import "../lib.typ": *
#import "../figs.typ": *

= How It Works

Your ARCADIA-2001 has no network port, no keyboard and no disk drive, and
its cartridge slot has no wire that says “write”. It carries the address the
console wants to read, the eight data lines that bring the answer back, and
power -- nothing else. The console can *read* a cartridge, but it has no way
to send it anything at all. A FujiNet cartridge puts it on the Internet
anyway. Here is the trick.

#fig(window-strip, caption: [The 8K the console sees in the cartridge slot,
while CONFIG or a FujiNet game is running])

The console sees a cartridge as two blocks of 4,096 bytes it can look at.
FujiNet’s game chip watches *every* look: which address the console reads,
at the moment it reads it. So FujiNet sets aside the last pages of the second
block. Reading in the *questions* pages is how the console speaks -- the
address it reads spells the byte it means. The *answers* pages are where
FujiNet puts what it found out, and the console reads them like any other
part of a cartridge.

#tbl((1.1in, 1fr, 1fr),
  th[], th[The console, 1982], th[The cartridge, 2026],
  [*Computers*], [one Signetics 2650, about 900,000 steps a second],
  [two (the game chip and the network chip), each running over a hundred
   times faster],
  [*Memory*], [768 bytes, most of them the picture], [about a million
   bytes, and 8 million more beside],
  [*Storage*], [the 8K a cartridge shows it], [18 million bytes of its own,
   and the memory card],
  [*Network*], [none], [WiFi, and through it the whole Internet],
)

== How a Question Gets Answered

#let panel4(n, title, body) = block(width: 100%, breakable: false,
  above: 1em, below: 0.8em,
  grid(columns: (0.5in, 1fr), column-gutter: 6pt, align: (left + top, left + top),
    text(font: f-wm, size: 30pt, top-edge: "cap-height", bottom-edge: "baseline",
      str(n)),
    {
      text(weight: 700, upper(title))
      v(3pt, weak: true)
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

#fig(flow(
  nodebox([YOUR ARCADIA], sub: [reads], w: 1.15in), biarrow(w: 0.42in),
  nodebox([GAME CHIP], sub: [listens], w: 1.15in), biarrow(w: 0.42in),
  nodebox([NETWORK CHIP], sub: [fetches], w: 1.2in), biarrow(w: 0.42in),
  nodebox([THE WORLD], sub: [WiFi], w: 1.05in)),
  caption: [The way a question goes, and the answer comes back])

== Whole Games

When you load a game, FujiNet sends all of it -- up to 8,192 bytes, as large
as any ARCADIA-2001 cartridge -- into the game chip’s own memory. Then CONFIG
steps aside and the cartridge becomes that game’s cartridge. The console
starts the game just as it would at power-on, and never knows the difference.

Programs written for FujiNet may be larger. M.U.L.E. is 51,200 bytes: the
cartridge shows it to the console a 2K *page* at a time, in a window in the
first block, and turns to another page whenever the program asks. A
FujiNet program can be up to 71,680 bytes in all.
