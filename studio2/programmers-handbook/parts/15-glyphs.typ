#import "../lib.typ": *

#opener-art.update((sub: [32 glyphs · 16 tiles · mosaic cells],
  art: tvrow("glyphs", w: 1.6in)))
= Glyphs, Tiles and Mosaics <glyphs>

A program cannot store into the picture, but the text engine draws more than letters. It holds 32 characters of your own, and 16 small tiles that build cells of a finer grain. Battleship draws its four boards with them, and 5 Card Stud its cards. `glyphs.asm` shows each kind.

== Glyphs

Codes `$80` to `$9F` are yours to define. A glyph is a whole cell, 4 dots by 12 scanlines, with no blank line or column around it: put two side by side, or one above another, and they join. Push the code, then the twelve rows, top first, each row a byte whose bit 3 is the leftmost dot; then GLYPH (`$40`).

#excerpt-at(auto, "listings/asm/glyphs.asm", "        LDR     RA, g_mark", to: "        PUTS    20H, t_glyph")

`params` pushes D bytes from RA, so a glyph is a table:

#excerpt-at(auto, "listings/asm/glyphs.asm", "g_mark: DB      80H", n: 8)

Four glyphs make an 8 × 24 dot mark: dots of two by six, which look round on a television. Redefining a glyph redraws every cell already holding it, which makes them good for animation and poor for a picture of many different parts.

== Tiles and mosaics

For finer pictures there are 16 tiles, each 2 dots by 4 scanlines, four row bytes with bit 1 the left dot. A _mosaic_ cell is two tiles across and three down, six tiles in one character cell, and any cell may hold any six. TILE (`$41`) takes the tile’s number and its four rows:

#excerpt-at(auto, "listings/asm/glyphs.asm", "t_tiles: DB     0, 0, 0, 0, 0", n: 3)

MOSAIC (`$42`) draws cells at the cursor and moves on, like PUTC. Each takes three bytes, its top, middle and bottom thirds, and each byte holds two tiles, the left in the high nibble. Up to five cells go in one operation:

#excerpt-at(auto, "listings/asm/glyphs.asm", "m_cells: DB     22H, 22H, 11H", n: 5)

Redefining a tile redraws only the mosaic cells that use it. SCROLL carries mosaic cells along, PUTC and CLS replace them, and inverse video inverts the whole cell.

== Repeats and inverse video

REPEAT (`$30`) takes a character and a count and draws it that many times, with one read for each parameter and one for the operation:

#excerpt-at(auto, "listings/asm/glyphs.asm", "        LDI     SYM_BLOCK", n: 5)

INV_ON and INV_OFF bracket what is drawn in inverse video; CLS turns it off.

== The marquee

A row armed with MARQUEE (`$20`) scrolls a PRINT that is too long for it, a step every quarter of a second, up to 64 characters and three blanks, round and round. `fujitest` uses one for the network’s name. One row at a time can have it; MQ_OFF (`$21`) or CLS stops it.

#note[While a transaction is running the cartridge is busy, and the marquee stands still until it is done.]
