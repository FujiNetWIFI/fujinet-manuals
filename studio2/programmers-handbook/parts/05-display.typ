#import "../lib.typ": *

#opener-art.update((sub: [16 columns · 10 rows · 32 glyphs of your own],
  art: tvrow("hello", "fujitest", w: 1.3in)))
= The Text Display <display>

The Studio II draws its picture with the CDP1861: sixty-four dots across, fetched by DMA straight out of memory, one byte for every eight dots. The console’s own games keep a 64 × 32 picture in 256 bytes of RAM. A FujiNet program does better: the cartridge serves a picture of 64 × 128 dots from its own memory, and draws text into it for you.

You never store a dot. The cartridge has a _text engine_, a screen of 16 columns by 10 rows, and you drive it the same way you drive the mailbox, with reads of hotspot pages.

== The four text pages

#tbl((0.55in, 1fr),
  [*Read*], [*Does*],
  [`$EC`_rc_], [moves the cursor to row r, column c],
  [`$ED`_cc_], [draws character cc at the cursor and moves on],
  [`$EE`_op_], [runs operation op with the parameters pushed so far],
  [`$EF`_vv_], [pushes the parameter vv],
)

A character cell is four dots wide and twelve scanlines tall: a 3 × 5 letter with every row doubled, a blank line above and below, and a blank column between letters. Lower case is drawn as small capitals, so the case shows by height. PUTC wraps from column 15 to the next row, and past row 9 it draws nothing: the screen never scrolls by itself.

#note[On a television a dot is about three scanlines wide, so a cell is a little wider than it is tall and the picture fills the screen from side to side.]

== Hello

The first program of every FujiNet book prints a greeting. On the Studio II it is a cursor move and a string, through the runtime’s `d_at` and `d_puts`:

#excerpt-at(auto, "listings/runtime/hello.asm", "main:", n: 6)

`d_at` takes the row and column in one byte, the row in the high nibble: `$21` is row 2, column 1. `d_puts` reads the string from console memory and sends every character as one read of `$ED`. The text engine draws while your program runs: every call is a few reads and returns at once. There is no frame to wait for and no buffer to flip.

== The characters

#tbl((0.75in, 1fr),
  [*Code*], [*Draws*],
  [`$20-$7F`], [the font; lower case as small capitals],
  [`$01-$04`], [the suits: #s2ch(1) #s2ch(2) #s2ch(3) #s2ch(4)],
  [`$05`], [a solid block #s2ch(5)],
  [`$06-$09`], [arrows: right, left, up, down #s2ch(6) #s2ch(7) #s2ch(8) #s2ch(9)],
  [`$0A`], [“10” in one cell, for playing cards #s2ch(10)],
  [`$0B`], [a card’s back #s2ch(11)],
  [`$80-$9F`], [your own glyphs (Glyphs, Tiles and Mosaics, page #pg(<glyphs>))],
)

Every other code draws a blank.

== The operations

Push the parameters with `$EF` first, then read the operation’s `$EE` address; every operation clears the parameters after it.

#tbl((0.78in, 0.42in, 1fr),
  [*Op*], [*Code*], [*Does*],
  [CLS], [`$00`], [clears rows 0-9, cursor home, inverse off, marquee off],
  [INV_ON / INV_OFF], [`$01` `$02`], [inverse video for what is drawn next],
  [CLREOL], [`$03`], [blanks from the cursor to the end of the row],
  [SCROLL], [`$04`], [moves rows 1-9 up one; row 9 comes up blank],
  [PRINT], [`$10`], [prints reply text: offset (two bytes), then the most to print (0: 256)],
  [PRINT_PAD], [`$11`], [the same, then spaces out to the most],
  [MARQUEE], [`$20`], [a later PRINT on this row that is too long scrolls across it],
  [MQ_OFF], [`$21`], [the marquee stops],
  [REPEAT], [`$30`], [a character, a count: draws it that many times],
  [GLYPH], [`$40`], [defines one of your 32 glyphs],
  [TILE / MOSAIC], [`$41` `$42`], [small tiles, and cells built from them],
)

PRINT is the one to remember. It prints text straight out of the reply window: the cartridge reads its own memory, and the bytes never cross into the console. `d_rpl` and `d_rplpad` wrap it: R8 is the offset into the reply, D the most to print. This is how `fujitest` shows the adapter’s IP address, which starts at byte 140 of GET_ADAPTERCONFIG_EXTENDED’s reply:

#excerpt-at(auto, "listings/runtime/fujitest.asm", "PUTS    30H, t_ip", n: 5)

== The status strip

The text rows take scanlines 0 to 119. Scanlines 120 to 127 belong to the cartridge: while an image is coming over the network it draws a progress bar there, and the program cannot write over it.

== Where the picture comes from

The 1861 asks for its 1024 bytes a frame by DMA through R0, which the display interrupt points at `$F400`. The cartridge does not look at the address: it hands out the picture in the order the 1861 asks for it, a line of eight bytes at a time, starting over each frame. That is why the runtime’s interrupt routine, in `s2call.inc`, must be what it is (The 1802 Runtime, page #pg(<runtime>)).

#important[Never read `$F400-$FFFF` from a program. The cartridge would count the read as one of the 1861’s and the picture would slip by a byte.]
