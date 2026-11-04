#import "../lib.typ": *

= The Text Display <display>

The 2637 draws its picture from 208 bytes of the console’s RAM, `$1800-$18CF`:
13 rows of 16 cells, one byte a cell, row 0 first. Write a byte there and it
is on the screen in the next frame. Nothing about the picture has to be set
up besides a colour and a character height; the 2637 is drawing it from the
moment the console is switched on.

== One byte a cell

#bytefield(([colour bits 7--6], 1.4in), ([glyph, bits 5--0], 2.6in))

The low six bits pick one of 64 glyphs; the top two pick the colour. The
glyphs are the 2637’s own and they are *not ASCII*:

#tbl((0.85in, 1fr),
  [*Glyph*], [*Is*],
  [`$00`], [a space],
  [`$01-$0F`], [graphics: diagonals, a solid block (`$03`), half blocks, edges and corners (`$04-$0B`, Section 16)],
  [`$10-$19`], [the digits 0--9, so `$10` + a nibble is a hex digit for 0--9],
  [`$1A-$33`], [the letters A--Z],
  [`$34-$37`], [`.` `,` `+` `$`],
  [`$38-$3F`], [the eight user-defined characters, drawn from `$1980-$19BF`],
)

There is no lowercase, and no `/ - _ : ! ? ( )` or quotes. `fujidisp.inc`
fills the gap with the user-defined characters: it loads `/` `-` `_` `:` into
`$38-$3B`, and a cursor chevron, a password bullet and a more-pages mark
into `$3C-$3E`. Its `XLAT` table turns ASCII into glyphs: lowercase folds to
capitals, and anything with no glyph becomes `.`. `hello`, the cartridge’s
first program, paints the whole set:

#shots(("hello", [hello: the 64 glyphs]), ("fujitest", [fujitest]), w: 2.5in,
  caption: [The runtime’s programs, with 8 × 8 characters])

#important[The user-defined characters are also the four sprites’ images
(Section 16). A program that uses sprite 0 cannot also print `fujidisp`’s
slash.]

== Height and colour

Two registers set the whole screen, `$19F9` and `$19F8`; `$19F9` is the one
that matters for text:

#bytefield(([7 height], 0.9in), ([6 pot mux], 0.9in), ([5--3 character colour], 1.5in), ([2--0 screen colour], 1.4in))

- *Bit 7 set* draws 8 × 8 characters: 13 rows fill only the top half of the
  picture. That is what `DINIT` sets (`$87`), and why the runtime’s screens
  above sit high. *Bit 7 clear* draws them 8 × 16, and the 13 rows fill the
  screen, as CONFIG and every game do. The handbook’s programs use `BKINIT`,
  which calls `DINIT` and then writes `$07`.
- *Bit 6* is the pot multiplexer (Section 9). A program that reads both axes
  of a disc rewrites `$19F9` every frame, so it keeps its base value apart and
  ORs the multiplexer in.
- *The colours* are 0 white, 1 yellow, 2 cyan, 3 green, 4 magenta, 5 red,
  6 blue, 7 black.

A cell’s colour is three bits: its own two colour bits on top, and bit 3 of
`$19F9` (the low bit of the character colour) under them. With `$19F9` =
`$07`, colour bits `00` are white, `01` cyan, `10` magenta and `11` blue:

#asmp("        BSTA,UN DXLAT           ; R0: 'G' -> its glyph
        IORI,R0 $80             ; colour bits 10: magenta
        STRA,R0 SCREEN+$A5      ; row 10, column 5")

#caution[A cell of exactly `$C0` -- colour bits `11` and a space -- is not a
blue space. It switches the rest of its row to *block graphics*, and `$40`
switches it back. `fujidisp.inc` never paints colour bits `11` for that
reason; any glyph but the space is safe in blue. Section 16 shows the block
graphics on purpose.]

== Printing

`DPRINT` prints the NUL-terminated string at `(DSTRP)`, and `SETSTR` points
`DSTRP` at a label. The cell goes in R2, *minus one*: `DPRINT` stores with
the 2650’s auto-increment, `STRA,R0 SCREEN,R2,+`, which adds one to R2
first. It returns R2 on the last cell written, so a second call carries on
where the first stopped.

#excerpt-at(auto, "listings/runtime/fujidisp.inc", "; Print the string at (DSTRP)", to: "; Print R0 as two hex")

`DSTRP` is a pointer and the load through it is indirect, so the string can
be anywhere: in block 1, in block 2, or in the reply window at `$2B00`.
`fujitest` prints the SSID with `SETSTR FNRDATA` and never copies a byte of
it. The handbook’s `PUTS cell, string` macro is `SETSTR`, the minus one and
the call; `DHEX` prints R0 as two hex digits after R2, and `DREPLY` prints a
count of reply bytes that has no NUL.

#asmp("        PUTS    $00, TITLE      ; row 0: the title
        LODA,R0 *FERRP          ; the last transaction's ERR
        LODI,R2 $C0-1           ; row 12
        BSTA,UN DHEX")

`DCLS` clears all 208 cells to spaces. There is no scrolling in the 2637;
a program that scrolls copies rows itself, as NetCat does (Section 12).

== Changing the screen without tearing

The 2637 reads a row from RAM as it draws it, so a change in the middle of a
frame can show half old and half new for one frame. For text that is rarely
worth worrying about. For a screen that changes every frame, make the
changes in the vertical blank (`TPSU $80`), as `pads` and `sprites` do.
