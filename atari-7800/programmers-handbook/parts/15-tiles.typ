#import "../lib.typ": *
= The Tile Engine

#ini[C]ONFIG and all five FujiNet games for the 7800 draw their screens with the same small engine, `maria.s` and `maria.h`, which each project copies into its own tree. The C programs in this handbook use it for their text. It is worth understanding on its own, because it is the shape of the problem every 7800 program with a lot on the screen has to solve: how much MARIA can read in a line, and how to change the picture without MARIA ever reading half a change.

#sect[The screen]

32 × 24 cells of 8 × 8 pixels: 256 × 192, centred. The mode is 320B, where every pixel is two bits, so a tile has three colours and the background, the way NES tiles do. A cell holds a tile number (0–127) and a palette select (0 or 1). Pixel value 0 is `BACKGRND` in either palette; 1–3 are the selected palette’s three colours. MARIA has eight palettes, but 320B honours only their top bit, so the two selects are palettes 0 and 4.

#sect[How it is drawn]

Each row of cells is one 8-line zone. Its display list reads the row’s 32 map bytes as *indirect two-byte characters*: each map byte is a tile number times two, and MARIA fetches two bytes of pixels for it from the tile set at `CHARBASE`. A row needs one object header per *run* of cells that share a palette, five bytes each:

#bytefield(([map low], 50pt), ([`$E0`], 36pt), ([map high], 50pt), ([pal · 32−width], 74pt), ([hpos], 36pt))

`$E0` says extended header, indirect, write mode 1. So writing a tile costs nothing but the store: MARIA reads the map every line, and the next frame shows it. Changing a palette is different, because it can split or join runs and so change the list. `mt_setpal` marks the row; `mt_sync`, once a frame, rebuilds each marked row’s list into the row’s *spare* slot and then publishes it with one store to the row’s DLL entry. MARIA reads either the old list or the new one, never half of each.

#ex((path: "listings/c/maria.s", from: "; Row X", to: "        ldy     #0"), t-asm)

#sect[What it costs]

MARIA has 426 clocks a line to read its lists and the graphics, and it takes them from the 6502. A zone line here costs 16 clocks, plus 10 per run, plus 9 per cell (3 for the map byte, 6 for the two bytes of pixels). A one-run row is 314 clocks, leaving the 6502 about a third of every displayed line and about half of the whole frame. Rows are capped at 12 runs, 434 clocks being past the line; cells after the twelfth run take its palette.

#tbl((auto, auto, auto),
  th[Runs in a row], th[Clocks a line], th[Left for the 6502],
  [1], [314], [112],
  [4], [344], [82],
  [12], [424], [2],
)

#sect[Memory]

#tbl((auto, auto, 1fr),
  th[Segment], th[Size], th[What],
  [`VIDEO` (cartridge RAM)], [768], [The map: tile × 2 per cell.],
  [], [768], [The palette selects, three pages after the map.],
  [], [3072], [Two display-list slots of 64 bytes per row, both in one page.],
  [], [—], [The DLL, a null list, a dirty flag and a slot flag per row.],
  [`TILES` (ROM)], [2048], [The tile set: 8 pages of 256 bytes, page 7 the top pixel row (MARIA counts a zone’s lines downward), tile _t_ at bytes 2 × _t_ and 2 × _t_ + 1 of each page.],
)

The linker configuration puts both on page boundaries. The engine uses MARIA’s own `WSYNC` at `$24`, owns `CTRL`, `CHARBASE`, `DPPH`/`DPPL`, `OFFSET`, `BACKGRND` and the palette registers it is told to set, and never stores below `$20`. It uses no display-list interrupts, so the NMI hook (`fuji_a7800_nmi`) is free for a game.

#sect[Making tiles]

`mktiles.py` builds the tile set from either or both of two sources:

- *`font.txt`*, CONFIG’s format: a header line `= c` (a character) or `= $hh` (a tile number), optionally `plane 1`, then up to eight rows of `#` and `.`. `#` is colour 1 (or 3 with `plane 1`), `.` is colour 2. CONFIG uses colour 2 as the paper, which palette 1 turns into a selection bar.
- *NES CHR* (`--chr file`), 16 bytes a tile, plane 0 then plane 1: the FujiNet games’ NES art converts unchanged, which is how most of the games got their 7800 graphics.

```
python3 mktiles.py font.txt build/tiles.s        # then assemble build/tiles.s
python3 mktiles.py --chr game.chr --chr-at 128 font.txt build/tiles.s
```

#sect[The calls]

#tbl((auto, 1fr),
  th[Call], th[What it does],
  [`mt_init(blank)`], [Measures NTSC or PAL, clears to tile `blank` in palette 0, builds the lists, display on at the next vertical blank.],
  [`mt_off()`, `mt_on()`], [MARIA’s DMA off (the 6502 runs flat out) and on.],
  [`mt_sync()`], [Once a frame: waits for the vertical blank, counts it in `mt_frames`, rebuilds marked rows.],
  [`mt_background(c)`, `mt_palette(p, c1, c2, c3)`], [Colours: hue × 16 + luminance.],
  [`mt_clear(blank)`], [Every cell to `blank`, palette 0.],
  [`mt_at(col, row)`], [The write cursor. Writes move it along the row and stop at the end.],
  [`mt_put(t)`, `mt_fill(t, n)`], [One tile, or `n` of them.],
  [`mt_puts(s)`, `mt_text(s, max)`], [Tiles from a string; `mt_text` stops at `max` and shows anything outside 32–126 as a space.],
  [`mt_setpal(p, n)`], [`n` cells from the cursor to palette `p`, cursor unmoved.],
  [`mt_get(col, row)`], [The tile at a cell.],
)

The map and palette selects are `mt_map` and `mt_attr`, for a program that wants to write them directly. A map byte is the tile number times two.
