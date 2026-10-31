#import "../lib.typ": *
= Display Lists, Fonts and Players <ch-antic>

The text screen of @ch-display is the simplest thing ANTIC can do. A game wants more: characters of its own design in four colours, a few rows of bigger letters, a cursor that moves smoothly over the board. All of it is the display list, the font and GTIA’s players, and all of it is the same as on the Atari 400 and 800, at the 5200’s addresses.

#sect[The display list]

A display list is a string of one-byte instructions, some followed by an address. ANTIC reads it with DMA, one instruction per *mode line*, every frame.

#tbl((auto, 1fr),
  th[Byte], th[Instruction],
  [`$00`–`$70`], [Blank lines: `$00` is one, `$10` two, up to `$70`, eight.],
  [`$01`], [Jump: the next two bytes are where the list continues. Used to cross a 1K boundary, which a display list may not otherwise do.],
  [`$41`], [Jump and wait for the vertical blank: the end of the list, pointing back at its start.],
  [`$02`–`$0F`], [A mode line of that mode (below).],
  [+ `$40`], [Load the memory counter: the next two bytes are the address of this line’s data. The first mode line needs it; lines after it carry on from where the last one stopped.],
  [+ `$80`], [Display-list interrupt at the end of this line (below).],
  [+ `$20`, + `$10`], [Fine scrolling, vertical and horizontal.],
)

#tbl((auto, auto, auto, 1fr),
  th[Mode], th[Bytes a line], th[Scan lines], th[What it is],
  [2], [40], [8], [Text: 40 characters, two shades of one colour. The handbook’s screen.],
  [3], [40], [10], [Text with descenders.],
  [4], [40], [8], [Text in four colours: each character is 4 × 8 coloured pixels. Battleship’s screen.],
  [5], [40], [16], [Mode 4, twice as tall.],
  [6], [20], [8], [Big text: 20 characters in five colours. cc65’s console.],
  [7], [20], [16], [Mode 6, twice as tall.],
  [8–`$F`], [10–40], [1–8], [Bitmaps, from 4 colours at 40 × 24 down to one colour at 320 × 192.],
)

A display list must not cross a 1K boundary, and a mode line’s data must not cross a 4K boundary, without a jump or a fresh load. And none of it may be in the mailbox at `$B000`–`$B7FF` (@ch-map).

#sect[Fonts]

`CHBASE` (`$D409`) is the page number of the font, which must start on a 1K boundary for modes 2 and 3 and a 512-byte one for modes 6 and 7. A font in ROM is the cheapest, and is what the handbook’s programs use. A game that redefines its characters while it runs copies its font into RAM first: Battleship copies its own to `$3000` and draws its ships by changing characters.

#sect[Players and missiles]

GTIA has four *players*, each a strip 8 pixels wide and the height of the screen, and four *missiles*, 2 pixels wide, all in front of (or behind) the playfield and positioned to the pixel. ANTIC reads their shapes from *player/missile memory* by DMA, one byte per line for each:

#tbl((auto, auto, 1fr),
  th[Register], th[Where], th[What],
  [`PMBASE`], [`$D407`], [The page number of player/missile memory: 2K-aligned for single-line players. Missiles at +`$300`, player 0 at +`$400`, then every `$100`.],
  [`SDMCTL`], [`$07`], [`$3E`: the normal playfield and display list, players and missiles, single-line.],
  [`GRACTL`], [`$C01D`], [3: GTIA shows players and missiles.],
  [`HPOSP0`–`3`], [`$C000`–`$C003`], [Each player’s horizontal position. 48 is the left edge of the normal playfield.],
  [`PCOLR0`–`3`], [`$08`–`$0B`], [Their colours (shadows).],
)

#pair(
"        lda     #$38            ; player/missile memory at $3800
        sta     PMBASE
        lda     #$3E            ; playfield, players, missiles, single-line
        sta     SDMCTL
        lda     #3              ; GTIA: show them
        sta     GRACTL
        lda     #120            ; player 0 across the screen...
        sta     GTIA            ; ...HPOSP0
        lda     #$46            ; ...in red
        sta     PCOLR0",
"ANTIC.pmbase = 0x38;             /* player/missile memory at $3800 */
OS.sdmctl = 0x3E;                /* playfield, players, missiles, single-line */
GTIA_WRITE.gractl = 3;           /* GTIA: show them */
GTIA_WRITE.hposp0 = 120;         /* player 0 across the screen... */
OS.pcolr0 = 0x46;                /* ...in red */")

Then draw the player’s shape into its strip, at the lines where it should appear, and move it by changing its horizontal position and where in the strip the shape is.

#sect[Display-list interrupts]

A display list instruction with bit 7 set raises an NMI at the end of its line. The BIOS’s NMI handler sends it through `VDSLST` (`$0206`); enable it with `$C0` in `NMIEN` (`$D40E`), the VBI and display-list interrupts together. A handler that changes a colour or `CHBASE` for the next rows stores to `WSYNC` (`$D40A`) first, which holds the 6502 until the end of the scan line, so the change lands in the margin.

#caution[MAME’s ANTIC reads `CHBASE` once per mode line, when it fetches the line’s instruction, not on every scan line. A handler that does work before its `WSYNC` can miss that moment on a busy line, and the next row comes out in the old font, in MAME only. Have every value ready in zero page before the interrupt, and store it immediately after `WSYNC`.]

#sect[Colours]

A colour is a byte: the top four bits are one of 16 hues, the next three one of 8 luminances. `$84` is the handbook’s blue, `$0E` its white, `$46` a red. Set the shadows (`PCOLR0`–`3`, `COLOR0`–`4`), and the VBI copies them to GTIA every frame. After several minutes without a key press, the VBI’s attract mode cycles them to save the television’s screen; a key press stops it.
