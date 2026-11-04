#import "../lib.typ": *

= The 2637 Up Close <uvi>

The FujiNet programs keep the 2637 simple: 13 rows of white text. The chip
can do more, and the games use it: colour, block graphics, a 26-row screen,
eight characters of your own and four sprites that know when they touch
something. `sprites` shows most of it on one screen.

#shot("sprites", [sprites: the colour bits, a block-graphics row, a box of built-in glyphs, and two sprites, met])

== Colour

The 2637 has eight colours: 0 white, 1 yellow, 2 cyan, 3 green, 4 magenta,
5 red, 6 blue, 7 black. `$19F9` holds the screen colour (bits 0--2) and the
character colour (bits 3--5); a cell’s two colour bits pick among four
character colours, the character colour’s low bit underneath them. Row 2 of
`sprites` is the same digit with colour bits `00`, `01`, `10` and `11`:

#excerpt-at(auto, "listings/asm/sprites.asm", "COLROW: DB", n: 3)

Bit 7 of `$18FD` turns on the _multicolour_ mode, in which each cell also
chooses its background: colour bit 6 picks the character colour of `$19F9`
or of `$19F8`, colour bit 7 the screen colour of one or the other. `$19F8`
bits 0--5 are those alternate colours. (Bit 7 of `$18FD` is also the tone’s
register: write the pitch with the mode bit you want.)

== Block graphics

A cell of exactly `$C0` turns the rest of its row into _block graphics_:
each cell after it is a 3 × 2 grid of blocks, its glyph bits saying which are
lit, the low three the top row. `$40` turns the row back to characters, and
the next row starts as characters anyway. Bit 7 of `$19F8` makes the whole
screen block graphics.

#excerpt-at(auto, "listings/asm/sprites.asm", "BLKROW: DB", n: 2)

Alien Invaders draws its shields this way. It is also why a text program
must never paint a blue space: `$C0` is colour bits `11` and glyph 0
(Section 5).

== The built-in frame

Glyphs `$04` to `$0B` are edges and corners, a complete kit for drawing a
box without spending a user-defined character on it:

#tbl((0.5in, 1fr, 0.5in, 1fr),
  [`$04`], [top edge], [`$08`], [top right corner],
  [`$05`], [right edge], [`$09`], [top left corner],
  [`$06`], [bottom edge], [`$0A`], [bottom left corner],
  [`$07`], [left edge], [`$0B`], [bottom right corner],
)

#excerpt-at(auto, "listings/asm/sprites.asm", "BOXTOP: DB", n: 3)

== Characters of your own

The eight user-defined characters, glyphs `$38` to `$3F`, are drawn from
`$1980-$19BF`, eight bytes each, the top row first and bit 7 on the left.
Write them at any time; the next frame draws the new shapes everywhere they
are on the screen. `fujidisp.inc` loads its own eight at start; a program
may load its own instead -- CONFIG changes one while its editor runs, to
preview the character under the cursor.

== Sprites

The 2637 has four sprites, 8 pixels wide, drawn over everything. Their
_images_ are the first four user-defined characters: sprite 0 is glyph `$38`,
`$1980-$1987`, and so on. A program that uses a sprite gives up that
character.

#tbl((1.05in, 1fr),
  [*Register*], [*Holds*],
  [`$18F0`, `$18F1`], [sprite 0’s vertical and horizontal position; sprites 1--3 follow in pairs to `$18F7`],
  [`$19FB`], [bits 3--5 sprite 0’s colour, 0--2 sprite 1’s; bit 7 sprite 0 8 × 8 (1) or 8 × 16 (0), bit 6 sprite 1’s],
  [`$19FA`], [the same for sprites 2 and 3],
)

The positions count oddly. The horizontal register is 43 plus the pixel
column, so a sprite sits on text column _c_ at 43 + 8 _c_. The vertical
register counts _up_: 256 less the line, so with 8 × 16 characters row _r_ is
at 256 -- 16 _r_. `sprites` parks sprite 1 on row 7, column 13, and runs
sprite 0 to and fro along the row:

#excerpt-at(auto, "listings/asm/sprites.asm", "        LODI,R0 $0D", to: "        PUTS    $A0, TX")

== Collisions

As it draws a frame the 2637 notes which sprites touched a lit pixel of the
characters and which touched each other. A bit reads *0* for a collision:

#tbl((0.6in, 1fr),
  [*Reg.*], [*Bit 0 ... 5*],
  [`$19FC`], [sprites 0, 1, 2, 3 against the characters (bits 0--3)],
  [`$19FD`], [sprites 0 and 1, 0 and 2, 0 and 3, 1 and 2, 1 and 3, 2 and 3],
)

Read them in the vertical blank, for the frame just drawn:

#excerpt-at(auto, "listings/asm/sprites.asm", "MAIN:   TPSU    $80", to: "MAIN4:")

`emu/verify.sh` waits until `sprites` has printed both SPRITE HIT and BOX
HIT, so both registers are tested on every run.

== The 26-row screen

Bit 6 of `$19F8` adds a lower screen: rows 13 to 25, from `$1A00-$1ACF`.
With 8 × 8 characters the 26 rows fill the picture, twice the text of the
13-row screen. The cost is the RAM: the lower screen is the 208 bytes
Section 6 gave to the program, and only 84 bytes are left -- `$18D0-$18EF`,
`$18F8-$18FB` and `$1AD0-$1AFF`. M.U.L.E. runs in this mode and keeps its
state in the cartridge RAM of Section 15.

== Scrolling and position

Bits 5--7 of `$18FE` shift the whole screen 0 to 7 pixels left, and `$18FC`
sets how far down the character display starts, as a complement. `$18FF`
reads the character row the 2637 is drawing, which a game can use to change
things part way down the frame. None of the FujiNet programs do.
