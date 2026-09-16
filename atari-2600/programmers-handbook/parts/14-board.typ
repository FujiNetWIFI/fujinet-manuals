#import "../lib.typ": *
= The Playfield Board

Text is twelve columns of white. A game board wants colour, and on this console colour comes from the playfield: forty bits across the screen, one colour per scanline, redrawn by the processor every line. Battleship draws up to four 10 × 10 boards at once in blue, red, white and gold on that hardware, and the trick is shared between the cartridge, which composes the tables, and a kernel that reads them on a schedule with no slack.

#sect[Two boards in forty bits]

A cell is two playfield bits, eight pixels wide, so two boards side by side are the whole 40-bit asymmetric playfield: `PF0`, `PF1` and `PF2` rewritten twice a scanline, once for the left board and once for the right. The colour is decided by the line *within* the cell. Each line of an eight-line cell draws a different table in a different colour:

#tbl((auto, auto, auto, 1fr),
  th[Cell line], th[Table], th[Colour], th[Shows],
  [0], [AUX], [gold], [your own hulls; the cursor on an enemy board],
  [1--2], [HIT], [red], [the top of a hit],
  [3--4], [MID], [white], [a hit's core, or the whole of a miss],
  [5--6], [HIT], [red], [the bottom of a hit],
  [7], [AUX], [gold], [])

So a hit is a red block with a white core, a miss a white dash, and a hull or the cursor a pair of gold bars above and below the cell: a bracket that never hides what is under it, which is why the cursor does not blink.

#sect[The tables]

Six registers --- `PF0`, `PF1`, `PF2` for the left half, then the right --- times three kinds is eighteen tables, one entry per cell row, twenty rows for a top pair and a bottom pair. They live in the text-plane region, which nothing but a text render ever writes: plane _r_ holds register _r_'s three tables at bytes 30 to 89, after text rows 0--4 and before rows 15--20. A program in board mode never renders text rows 5 to 14.

#tbl((auto, 1fr),
  th[Cells], th[Bits],
  [0--1], [`PF0` bits 4--5, 6--7],
  [2--5], [`PF1` bits 7--6, 5--4, 3--2, 1--0],
  [6--9], [`PF2` bits 0--1, 2--3, 4--5, 6--7])

The TIA draws `PF0` and `PF2` low bit first and `PF1` high bit first, which is why the map above zigzags. A slot is a board position --- 0 top-left, 1 top-right, 2 bottom-left, 3 bottom-right --- and every table byte is written whole and in place, so the kernel's `LDA table,Y` never sees a half-composed byte. The highest table byte is `$1AD9`, so every table sits inside one page and every read is four cycles.

#sect[Composing them]

Four blit transforms fill the tables straight from the reply window, and the console never sees a cell:

#tbl((auto, 1fr),
  th[Transform], th[Effect],
  [PFCLR (10)], [clear the kinds in a mask --- `src` low byte: 1 HIT, 2 MID, 4 AUX --- in slot `dst`],
  [PFIELD (11)], [a game field of 100 bytes (0 sea, 1 hit, 2 miss) at reply offset `src` into slot `dst`: 1 sets HIT and MID, 2 sets MID; AUX is untouched],
  [PFHULL (12)], [`cnt` ship placements (`pos + 100 × dir`) at reply offset `src` OR-ed into slot `dst`'s AUX; never clears],
  [PFCELL (13)], [one cell, `cnt` = 0--99, of slot `dst`: set the kinds in `src`, or clear them if `src` bit 7 is set --- how the cursor moves])

Doing that on the console would be four hundred reads through a 16-bit reply cursor in a bank that has not got the bytes, into RAM it has not got at all. The blit costs six stores.

#excerpt-at("bscomp.asm: the boards, from the reply", "listings/battleship/src/bscomp.asm", "GBOARDS: lda", to: "GBAUX:", size: 6.5pt)

#sect[The kernel]

Each line of a board is six table reads and six playfield writes, with deadlines the TIA sets: the left `PF0` before colour clock 22, `PF1` before 28, `PF2` before 38; the right `PF0` between 28 and 49, `PF1` between 39 and 54, `PF2` between 50 and 65. The three line bodies are identical but for the table base and the colour:

#excerpt-at("dispgame.inc: one line of a board", "listings/battleship/src/dispgame.inc", "LAUX:   sta", to: "LHIT:", size: 6.5pt)

#important[The `NOP`s are not padding. Without them the right half's `PF2` lands at cycle 49, and its first colour clock is inside pixel 79, the left board's last column. Every window here has at least ten colour clocks of margin, and `tools/pfcheck.py` in the Battleship tree reads every cell line of every board back from a snapshot and requires the colour the picture says.]

Between the two boards of a pair runs a two-clock black missile, the divider, positioned once in `DINIT` and enabled only on board lines --- because a missile replicates with its player's copy count, and the three close copies the text needs would put three dividers across the boards.

#sect[Four seats]

Three or four players use the quadrant layout: two pairs of 8-line cells, 80 lines each, with the names over each pair and a three-line fleet strip under the names. Two players get one pair of 12-line cells, which is square on a 4:3 set, and the lower half of the screen becomes text. The 262 lines of the quadrant frame are counted below, and there is no slack in them: the kernel is 191 lines of a band of 192.

```
  1  the unblank line
  6  status row        (text row 0: five ink lines and a seam)
  6  names over pair A (text row 1)
  3  fleet strip       (text row 3)
  1  the strip's seam, WHICH IS ALSO the board's lead-in
 80  board pair A
  1  lead-out
  2  gap
  6  names over pair B (text row 2)
  3  fleet strip       (text row 4)
  1  seam and lead-in
 80  board pair B
  1  lead-out
  1  timed pad
```

The fleet strips are three ink lines rather than five because that is what the gap and the pad could pay for, and the font survives the clip: `#` keeps its hash and `=` its bar. Digits would not --- clipped to three rows, `8` and `9` are the same picture --- which is why the strips show pips and not a count.

#sect[Trying it without a network]

`layout.asm` in the Battleship tree is the board kernel with tables baked into the image from a picture in `tools/mklayout.py`: four boards, no two alike, every mark on every one.

#shot("bs-layout", w: 2.0in, caption: [The layout ROM: every kind of mark on every board, so that a table read from the wrong slot or the wrong row is visible.]) `make layout && make shot` builds it, snapshots it in MAME and reads every cell back. It is the place to start when changing anything about the kernel, because a wrong table read and a right one look the same until the picture is compared, cell by cell, against what was asked for.
