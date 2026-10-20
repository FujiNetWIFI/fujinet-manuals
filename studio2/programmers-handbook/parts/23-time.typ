#import "../lib.typ": *

= Things That Cost Real Time <time>

Every fact in this handbook was bought with time, and some of them were expensive. Here are the expensive ones, so you do not have to pay again.

== The milestones

The cartridge was brought up in the FujiNet MAME model, one milestone at a time, each with a test that had to pass before the next began.

#wide(at: bottom, tbl((0.75in, 2.6in, 1fr),
  [*Milestone*], [*What it proved*], [*Exit test*],
  [M0], [The BIOS starts a cartridge program; the cartridge serves the picture and the text engine draws.], [`hello`: text on screen, the frame counter moving, a key read, no DMA line short.],
  [M1], [One real transaction, and the cartridge outliving CLEAR and a power cycle.], [`fujitest` shows the live SSID; after CLEAR the next sequence number is 2, after power 1.],
  [M2], [Booting over the network.], [`fujiboot` mounts an image and the cartridge swaps it in.],
  [Tier A], [The cartridge serves each of thirteen known cartridges exactly as MAME’s own does.], [Frame for frame: 13 of 13, and the BIOS refuses the same images both ways.],
  [Tier B], [A swap leaves the console as a power-on would.], [Registers and RAM at each game’s first instruction: 13 of 13.],
  [Tier C], [Each pushed over the network, and played.], [13 of 13.],
))

== In the cartridge

- *There is no write line on the edge.* Every byte a program sends travels in the address of a read, which is why the mailbox and the text engine are made of hotspot pages, and why a program cannot store a dot.
- *A three-cycle instruction shortens a DMA line.* In MAME, an instruction from `$C0` to `$CF` in flight when the 1861 asks for DMA costs the line a byte. The runtime bans them, `checkrom.py` refuses them, and the display interrupt keeps one on purpose, where it lines the first fetch up. Whether a real 1861 does the same is one of the questions a real cartridge will answer.
- *The naive hand-over failed three times in four.* Jumping to `$0000` from anywhere in the frame let the 1861’s DMA read `$0000` first, or an interrupt arrive between the jump and the fetch. The hand-over now waits for the bottom of a frame.
- *A plain nine-instruction interrupt routine re-entered itself at line 79.* The one shaped like the BIOS’s, with its long branch, does not.
- *MAME’s 1802 never runs its reset at power-on:* the interrupt enable stays off until CLEAR. Tests that need a true power-on pulse CLEAR first.
- *A Lua read of the address space is a bus read.* It fires the cartridge’s hotspots. The test scripts read the device’s save items instead.
- *In AS, `^` is power and `!` is exclusive or.* A test written with `^` compiled, and never failed when it should have.

== In this handbook

- *AS takes one include list.* A second `-i` replaces the first, and a long list of absolute paths is cut short without a word: AS then says only that it cannot open a file. The build scripts give one list of relative paths.
- *A program that sleeps misses keys.* The first netcat paused eight frames between polls, and a press of six frames fell in the gap. It now reads the keypads every frame and the network every eighth.
- *A game server counts real seconds.* Run unthrottled, MAME used up twenty seconds of its own time in a fraction of one of the server’s, and the netcat never saw its greeting. Tests that talk to a server run at real speed.
- *A greeting one character too long* wrapped, and the test looking for it on one row never found it. The line server now says `NETCAT SAYS HI`.
- *`FIT` sizes that happen to work* are not the right sizes. Half of the handbook’s first programs had sizes too small that AS let pass because the routines still fit. `tools/fitcheck.py` measures them all.
- *A FIT counts a routine to the next FIT.* The runtime puts one only before a routine that branches, so its routines look short when they are not: the check skips the runtime’s own.
- *Helvetica has no suits and no arrows.* The book draws them from the cartridge’s own font instead.
- *Typst’s bold and italic are not settings but adjustments.* Inside them the Bodoni wordmark came out bold, or upright, until the book replaced both outright.
