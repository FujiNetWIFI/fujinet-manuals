#import "../lib.typ": *
= The Text Display

#ini[M]ARIA draws nothing by itself. Every line of the picture, it reads a list of objects from memory, and every object tells it where to find its pixels. A FujiNet program that wants to show text builds those lists once, puts character codes where an object points, and from then on changing the text is just storing bytes.

#fig(flow(
  nodebox("DLL", sub: "DPPH/DPPL"), rarrow(),
  nodebox("display list", sub: "one per zone"), rarrow(),
  nodebox("character codes", sub: "one byte a cell"), rarrow(),
  nodebox("font", sub: "CHARBASE")),
  caption: [How MARIA finds a character. Every box is memory MARIA reads by DMA.])

The *display list list* (DLL) divides the screen into zones of a few lines each and points each zone at its *display list*. A display list holds objects; a text row is one or two *indirect* objects, which point not at pixels but at a row of character codes. MARIA looks each code up in the font whose page `CHARBASE` names. All three roads in this handbook draw text this way.

#important[Never point MARIA at the mailbox. The cartridge answers at `$0600`–`$0FFF` from its microcontroller, not from RAM, and cannot keep up with MARIA’s DMA. A string in the reply window must be copied to RAM — the cartridge’s or the console’s — before MARIA can show it. Every program in this handbook does.]

#sect[Three roads]

#tbl((auto, 1fr, 1fr, 1fr),
  th[], th[Assembly], th[C], th[7800basic],
  [Library], [`fujidisp.s` (the bring-up’s)], [`maria.s` (CONFIG’s tile engine)], [7800basic itself],
  [Mode], [320A, one byte a character], [320B indirect, two bytes a character], [320A, one byte a character],
  [Cells], [40 × 24], [32 × 24], [as you plot them],
  [Text lives], [`$4000`, cartridge RAM], [`$4000`, cartridge RAM], [`$2200`–`$27FF`, console RAM],
  [Font], [`mkfont.py`: 5 × 7, capitals], [`font.txt`: 7 × 7, upper and lower case], [`mkbasfont.py`: the assembly font],
  [Colours], [one: palette 0], [three per cell, two palettes], [palette per plot],
)

The assembly and 7800basic programs use the same glyphs, made from one table, so their screens look alike; lower case comes out as capitals. The C programs use CONFIG’s own font, which has both.

#sect[In assembly: fujidisp]

`fujidisp.s` is the bring-up’s text screen: 40 columns by 24 rows in 320A. It keeps its screen buffer, its display lists and its DLL in the cartridge’s RAM, which is why every bring-up program’s claim sets the RAM flag:

#tbl((auto, auto, 1fr),
  th[Address], th[Size], th[What],
  [`$4000`], [960 bytes], [The screen: 24 rows of 40 character codes. Code = ASCII; `+$80` is the same character in reverse.],
  [`$4400`], [24 × 12], [The display lists: two 20-character indirect objects per row.],
  [`$4600`], [—], [The DLL: 25 blank lines, the 24 rows of 8 lines, then blank lines to the bottom.],
  [`font`], [2K], [The font, page-aligned in ROM; `CHARBASE` points at it.],
)

#tbl((auto, 1fr),
  th[Routine], th[What it does],
  [`disp_init`], [Clears the screen, builds the lists, sets the palette. Display still off.],
  [`disp_on` / `disp_off`], [MARIA’s DMA on (at a frame edge) or off.],
  [`disp_vbl`], [Waits for the start of the next vertical blank.],
  [`disp_at`], [Cursor to row A, column X.],
  [`disp_putc`], [One character at the cursor.],
  [`disp_str`], [The NUL-terminated string at `FN_PTR`, at most 40 characters.],
  [`disp_rpl`], [Up to Y bytes of the reply window from offset X, stopping at a NUL. This is the copy the Important note asks for: from the mailbox into the screen buffer.],
  [`disp_hex`, `disp_dec`], [A as two hex digits, or up to three decimal ones.],
)

The start-up code `a78init.s` calls `disp_init` before `main`, so a program starts with a blank screen and the display off; it turns the display on when it has something to show.

#sect[In C: the tile engine]

The C programs use the MARIA engine CONFIG and all five FujiNet games share, `maria.s` and `maria.h`. It is a 32 × 24 grid of 8 × 8 tiles in 320B, three colours and the background per tile, two palettes, with the map and the display lists in the cartridge’s RAM and the tiles in ROM. Text is just tiles whose numbers are ASCII codes. Section 15 takes it apart; for text, five calls are enough:

#tbl((auto, 1fr),
  th[Call], th[What it does],
  [`mt_init(blank)`], [Measures the TV standard, clears to tile `blank`, builds the lists, turns the display on.],
  [`mt_palette(p, c1, c2, c3)`, `mt_background(c)`], [Colours. In CONFIG’s font, colour 1 is the ink and colour 2 the paper.],
  [`mt_at(col, row)`], [The write cursor.],
  [`mt_puts(s)`, `mt_put(t)`], [Tiles from a string, or one tile.],
  [`mt_text(s, max)`], [Like `mt_puts`, but at most `max` characters, and anything outside 32–126 shows as a space: the call for text that came from the network.],
  [`mt_sync()`], [Once a frame: waits for the vertical blank and rebuilds any row whose palette changed.],
)

`mt_text` copies into the map, so it is also the copy out of the mailbox; fujinet-lib’s calls copy their replies into your buffers anyway.

#sect[In 7800basic]

7800basic has its own display system: zones of `zoneheight` lines, objects plotted into them each frame or once, and characters from a PNG. Three statements set it up for text, and the rest of the handbook’s BASIC programs begin with them:

```
 displaymode 320A
 set zoneheight 8
 incgraphic fujifont.png 320A
 characterset fujifont
 alphachars ASCII
 BACKGRND = $00
 P0C2 = $0F
```

`fujifont.png` is the assembly font, drawn by `tools/mkbasfont.py` as 128 cells side by side; `alphachars ASCII` makes a character’s code its cell. Then:

- `plotchars 'TEXT' palette x y` puts a quoted string on the screen. `x` counts in units of two pixels, so a column is 4; `y` is the zone, which with 8-line zones is the text row.
- `plotchars array palette x y count` plots `count` bytes of a RAM array. MARIA reads the array every frame, so storing into it later changes the screen; there is no need to plot again.
- `plotmap array palette x y width height` plots a whole block of an array as rows, `width` characters each: a text screen in one statement.

A 7800basic program copies a reply out of the mailbox with a loop into an array `dim`'d in the console’s free RAM, `$2200`–`$27FF`, and plots the array. Section 9 has the rules for those loops.

#sect[Hello, three times]

The smallest program in each language puts some text up and checks that a FujiNet cartridge is there. None of them talks to the FujiNet yet.

#trio-at(
  asm: (path: "listings/common/hello.s", from: ".proc main", to: "jsr     disp_on"),
  c: (path: "listings/c/hello.c", from: "void main", to: "for (;;)"),
  bas: (path: "listings/bas/hello.bas", from: " clearscreen", to: "main"),
)

#fig(grid(columns: 3, column-gutter: 6pt,
  tvframe("images/screens/asm-hello.png", 1.2in),
  tvframe("images/screens/c-hello.png", 1.2in),
  tvframe("images/screens/bas-hello.png", 1.2in)),
  caption: [Hello in assembly, C and 7800basic. The assembly one also shows the cartridge’s model of INPTCTRL, unlocked, and counts frames.])

#sect[PAL]

A PAL 7800 draws 50 frames a second and 50 more lines than an NTSC one. The tile engine measures the console when it starts, keeps the answer in `mt_pal`, and puts 50 blank lines above the picture instead of 25, so it sits in the middle of either screen. fujidisp’s list is the same on both, so on PAL its text sits higher. The cartridge knows too (it watched which BIOS ran) and says so at `$0C1E`; 7800basic measures at start-up and keeps the answer in `paldetected`.
