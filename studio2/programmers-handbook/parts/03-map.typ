#import "../lib.typ": *

#let c-bios = rgb("#d9d5cc")
#let c-cart = gold-lt
#let c-ram  = rgb("#cfe0c8")
#let c-none = white
#let c-arena = rgb("#f1c76a")
#let c-rast = rgb("#bcc9d6")

= The Memory Map <map>

The CDP1802 has sixteen address lines, but the Studio II was built with very little behind them: 2K of BIOS in two ROMs, 512 bytes of RAM, and a cartridge socket that was meant for a 1K or 2K ROM. The FujiNet cartridge fills most of the rest.

It can, because the socket carries every read the console makes. The 1802 puts the high byte of an address on its eight address lines, then the low byte, and the socket carries both, with the strobe that says a read is happening. The cartridge sees the whole address of every read, and when the page is one of its own it pulls the socket’s CS line, which switches the console’s RAM off the bus, and answers the read itself.

== The pages

A FujiNet program lives on the cartridge’s pages and the console’s RAM. The low four pages of every 4K block, `$x000` to `$x3FF`, belong to no one: the BIOS ROMs decode only some of their address lines and may answer there too, so the cartridge never claims them. That leaves, for a program:

- `$0400-$07FF`, where the BIOS starts it. The runtime fills it.
- `$0A00`, and `$0C00-$0FFF`, where the program’s own code begins.
- `$x400-$xFFF` for x from 1 to D: twelve pages in each of thirteen 4K blocks.

A program may use any 64 of those pages; an ST2 image holds no more.

#wide(at: bottom, align(center, grid(columns: (auto, auto), column-gutter: 0.45in,
  memmap((
    (0x0000, 0x03FF, [BIOS ROM], c-bios, [never the cartridge’s]),
    (0x0400, 0x07FF, [cartridge: runtime, claim], c-cart, [`$0400` entry, `"FUJI"` at `$07FC`]),
    (0x0800, 0x09FF, [console RAM], c-ram, [512 bytes, all the program’s]),
    (0x0A00, 0x0AFF, [cartridge], c-cart, [a program may use it]),
    (0x0B00, 0x0BFF, [park page], c-none, [RF rests here between hotspots]),
    (0x0C00, 0x0FFF, [cartridge: program], c-cart, [the program’s own code starts here]),
  ), scale: 0.012pt, minh: 15pt, w: 1.45in, notew: 2.1in),
  memmap((
    (0x1000, 0x13FF, [never: may mirror the BIOS], c-none, [`$x000-$x3FF`, x = 1 to F]),
    (0x1400, 0x1FFF, [cartridge: program], c-cart, [`$x400-$xFFF`, x = 1 to D]),
    (0x2000, 0xDFFF, [… the same, block by block …], c-none, [`$2000` to `$DFFF`], 22pt),
    (0xE000, 0xE3FF, [never], c-none, []),
    (0xE400, 0xE7FF, [reply window], c-arena, [the reply, 1K]),
    (0xE800, 0xE8FF, [status page], c-arena, [ACKSEQ, ERR, RXLEN ...]),
    (0xE900, 0xEBFF, [mailbox hotspots], c-arena, [REGSEL, REGDATA, TX]),
    (0xEC00, 0xEFFF, [text hotspots], c-arena, [cursor, PUTC, op, parameter]),
    (0xF000, 0xF3FF, [never], c-none, []),
    (0xF400, 0xF7FF, [raster], c-rast, [64 × 128: the 1861’s picture]),
    (0xF800, 0xFFFF, [raster again], c-rast, [served by position]),
  ), scale: 0.012pt, minh: 15pt, w: 1.45in, notew: 2.1in))))

#note[The first program in this handbook, `fujitest.asm`, checks the mirror on its last row: an `M` for every 4K block whose `$x200` reads the same as the BIOS’s `$0200`. In MAME every block shows a dot; on a real console, nobody knows yet.]

== The arena

Pages `$E4` to `$EF` are the cartridge’s _arena_, where a program talks to it. The reply window and the status page are ordinary memory the cartridge paints; the six hotspot pages are not memory at all, and a read there is a message (How the Mailbox Works, page #pg(<mailbox>)). Pages `$F4` to `$FF` are the picture the 1861 shows, which the cartridge serves in the order the 1861 asks for it, whatever address it is read at. A program never reads them (The Text Display, page #pg(<display>)).

== The claim

What decides between a FujiNet program and an old cartridge is four bytes: `"FUJI"` at `$07FC`. An image that carries them is a FujiNet program, and the cartridge serves the arena and the picture with it. An image without them is a _game_: the cartridge serves its pages and nothing else, as a plain ROM cartridge would, and the mailbox is gone until the console is turned off.

#tbl((1.4in, 1fr, 1fr),
  [*Pages*], [*A FujiNet program*], [*A game*],
  [`$x0-$x3`, `$08`, `$09`], [never], [never],
  [`$0B`], [never: the park page], [yes],
  [`$E4` and up], [never: the arena and the picture], [yes],
  [the others], [yes], [yes],
)

The runtime’s `S2CLAIM` macro puts the four bytes in place; it is the last line of every program in this handbook.

== The ST2 image

An ST2 file is a 256-byte header and then up to 64 blocks of 256 bytes, each block one page of the console’s memory:

#tbl((0.9in, 1fr),
  [*Offset*], [*Holds*],
  [0--3], [`"RCA2"`],
  [4], [the number of blocks, the header included: 2 to 65],
  [5], [the version, 1],
  [16--24], [the catalogue number, 9 characters],
  [32--63], [the title, 31 characters and a NUL],
  [64 + _i_], [the console page block _i_ goes to],
  [256 × (_i_ + 1)], [block _i_’s 256 bytes],
)

`mkst2.py` writes one from AS’s output: a block for every page the program touched, and `$04-$07` always, so the runtime is there. It refuses a page the claim does not allow, and the cartridge refuses it again when the image arrives. The largest image is 16,640 bytes.

#note[When an image has page `$0C`, the cartridge maps all of `$0C00-$0FFF`, with zeros where the image has nothing, because MAME’s own cartridge does.]
