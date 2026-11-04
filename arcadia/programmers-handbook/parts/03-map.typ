#import "../lib.typ": *

= The Memory Map <map>

The 2650 addresses 32K, `$0000-$7FFF`. The ARCADIA-2001 puts three things
in it: the cartridge, the 2637 video chip with the console’s RAM, and
nothing.

== What the console sees

#let cart = rgb("#d9d9d9")
#let uvi = rgb("#f2f2f2")
#let none-c = paper
#fig(memmap((
  (0x0000, 0x0FFF, [CARTRIDGE BLOCK 1], cart, [image `0x0000-0x0FFF`: your program’s first 4K], 30pt),
  (0x1000, 0x17FF, [nothing], none-c, [A12 high deselects the cartridge; reads float], 18pt),
  (0x1800, 0x1AFF, [2637 AND RAM], uvi, [the screen, the RAM, the controllers, the video chip’s registers], 26pt),
  (0x1B00, 0x1FFF, [nothing], none-c, [], 15pt),
  (0x2000, 0x2FFF, [CARTRIDGE BLOCK 2], cart, [image `0x1000-0x1FFF`: 2,816 bytes of program, then the mailbox at `$2B00`], 30pt),
  (0x3000, 0x3FFF, [reads \$FF], none-c, [the decode serves nothing here], 15pt),
  (0x4000, 0x4FFF, [BLOCK 1 AGAIN], cart, [A14 is not on the connector: an alias, hotspots and all], 18pt),
  (0x5000, 0x5FFF, [reads \$FF], none-c, [], 15pt),
  (0x6000, 0x6FFF, [BLOCK 2 AGAIN], cart, [an alias of `$2000-$2FFF`, the mailbox included], 18pt),
  (0x7000, 0x7FFF, [reads \$FF], none-c, [], 15pt),
)), caption: [The 2650’s 32K, as the ARCADIA-2001 decodes it])

The cartridge connector carries the address lines A0--A13, the data lines
D0--D7, +5 V and ground, and nothing else: no write strobe, no clock, no
reset. A12 is the cartridge’s chip select, low for `$0000-$0FFF` and
`$2000-$2FFF`; A13 picks which 4K block. Everything follows from that wiring:

- *The console can only read the cartridge.* There is no write line, so a
  store into cartridge space reaches nothing -- and on a real console it is
  worse than nothing (Section 15). Every word your program says to the
  FujiNet, it says by reading (Section 4).
- *A program is at most 8K*, two 4K blocks with a hole between them. Section
  15 shows how a program bigger than that pages through a window.
- *The two blocks are in different 8K pages of the 2650.* Block 1 is page 0
  (`$0000-$1FFF`, shared with the video chip and the RAM); block 2 is page 1.
  A 2650 load or store reaches only its own page, so where a piece of code
  lives decides what it can touch directly (Section 8).

== The cartridge image

The image a FujiNet program is built into is exactly 8,192 bytes:
#tbl((1.25in, 1.1in, 1fr),
  [*Image*], [*Console*], [*Holds*],
  [`0x0000-0x0002`], [`$0000`], [`BCTA,UN START`: the console starts at `$0000`; there is no BIOS],
  [`0x0003`], [`$0003`], [`$17`, a `RETC,UN`: an interrupt guard, so a stray interrupt returns at once],
  [`0x0004-0x0FFF`], [`$0004-$0FFF`], [your program (the runtime starts at `$0020`)],
  [`0x1000-0x1AFF`], [`$2000-$2AFF`], [more program: 2,816 bytes],
  [`0x1B00-0x1BFF`], [`$2B00-$2BFF`], [the mailbox’s reply slice (Section 4)],
  [`0x1C00-0x1CFB`], [`$2C00-$2CFB`], [the mailbox’s status page],
  [`0x1CFC-0x1CFF`], [`$2CFC-$2CFF`], [the claim: the four letters `FUJI`],
  [`0x1D00-0x1FFF`], [`$2D00-$2FFF`], [the three hotspot pages],
)
So a client has 4,096 + 2,816 = *6,912 bytes* of code and data. `mkimage.py`
refuses a byte of it in the hole or in the mailbox, and `checkrom.py`
refuses an image without the header, the guard or the claim.

#important[The claim is a promise. "FUJI" at `$2CFC` says the image keeps
`$2B00-$2FFF` free, so the cartridge leaves the mailbox alive when it boots
the image. An image without it -- any of the console’s own 1982 games --
kills the mailbox for the rest of the session, so that a game which happens
to read a hotspot address can never start a transaction by accident.]

== The 2637 and the console’s RAM

The video chip, Signetics’ 2637 Universal Video Interface (UVI), sits at
`$1800-$1AFF`, and the console’s RAM is threaded through it:

#tbl((1.1in, 0.65in, 1fr),
  [*Address*], [*Use*], [*What it is*],
  [`$1800-$18CF`], [r/w], [the upper screen: 13 rows of 16 cells (Section 5)],
  [`$18D0-$18EF`], [r/w], [32 bytes of RAM: the runtime’s and the boot stub’s],
  [`$18F0-$18F7`], [w], [the four sprites’ vertical and horizontal positions],
  [`$18F8-$18FB`], [r/w], [4 bytes of RAM],
  [`$18FC`], [w], [where the character display starts, as a complement],
  [`$18FD`], [w], [bits 0--6 the tone’s pitch, bit 7 the colour mode],
  [`$18FE`], [w], [bits 0--2 loudness, 3 tone on, 4 noise on, 5--7 a scroll of 0--7 pixels left],
  [`$18FF`], [r], [the character row being drawn, in bits 0--3],
  [`$1900-$1902`], [r], [the left keypad, one column each (Section 9)],
  [`$1904-$1906`], [r], [the right keypad],
  [`$1908`], [r], [START, OPTION, SELECT],
  [`$1980-$19BF`], [w], [the eight user-defined characters `$38-$3F`, 8 bytes each; the first four are the sprites’ images],
  [`$19F8`], [w], [bit 7 block-graphics mode, bit 6 the 26-row screen, 0--5 the alternate colours],
  [`$19F9`], [w], [bit 7 character height, bit 6 the pot multiplexer, 3--5 and 0--2 the colours],
  [`$19FA-$19FB`], [w], [the sprites’ colours and heights],
  [`$19FC`], [r], [sprite against character collisions (a 0 is a hit)],
  [`$19FD`], [r], [sprite against sprite collisions],
  [`$19FE-$19FF`], [r], [the right and left discs’ pots, valid in the vertical blank],
  [`$1A00-$1ACF`], [r/w], [the lower screen in the 26-row mode; otherwise RAM],
  [`$1AD0-$1AFF`], [r/w], [48 bytes of RAM],
)

In the 13-row mode every program in this book uses, `$1A00-$1AFF` is 256
bytes of plain RAM, and with `$18D0-$18EF` that is the console’s working
memory: *288 bytes* (Section 6). The 2650 has no RAM stack -- its return
addresses live on the chip -- so all of it is yours.

== Frame time

The 2637 raises the 2650’s SENSE input during the vertical blank, and
`TPSU $80` tests it: CC is EQ while the blank lasts. There are no interrupts
to use instead; every program in this book waits for the blank in a loop:

```
WAITVB: TPSU    $80             ; SENSE: 1 in the vertical blank
        BCFR,EQ WAITVB
```

The pots, the collision registers and a flicker-free screen change all want
the blank, and a frame is 1/60 s. The 2650 runs at 3.58 MHz ÷ 4, about
895 kHz, three clocks to a processor cycle of 3.35 µs: some 5,000 cycles a
frame. An instruction takes two to four cycles -- a register move two, an
absolute load four -- so a frame holds 1,500 or so of them.
