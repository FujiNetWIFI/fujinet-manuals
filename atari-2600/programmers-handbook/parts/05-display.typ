#import "../lib.typ": *
= The Text Display

The Video Computer System has no framebuffer and no character generator. The processor races the beam, and every scanline of every picture is built by hand, in the forty-odd cycles the kernel has before the next one begins. On every other console in the FujiNet family, "draw a string" is a memory write. Here it would be a kernel, and a kernel the console has neither the RAM nor the cycles to feed with glyphs.

So the cartridge draws. It keeps the font, renders ASCII into bytes already in the exact shape a 48-pixel player kernel wants, and publishes them in the window. The console's part is to stream those bytes into two TIA registers on a cycle-exact schedule, and that part is written once, in `fujidisp.inc`, and shared by every client.

#sect[Six planes]

Text is twelve columns by twenty-one rows. A glyph is three pixels wide and five tall in a four-by-six cell; twelve cells are the 48 pixels that two players with three copies each can cover. Each row of the screen is six scanlines, and each scanline of the block needs six bytes, one per `GRP` write. The cartridge keeps those six bytes in six separate planes, 128 bytes each, indexed by the absolute scanline:

#tbl((auto, auto, auto, 1fr),
  th[Plane], th[Address], th[Write], th[Text columns],
  [0], [`$1800`], [1st GRP0], [0--1],
  [1], [`$1880`], [1st GRP1], [2--3],
  [2], [`$1900`], [2nd GRP0], [4--5],
  [3], [`$1980`], [2nd GRP1], [6--7],
  [4], [`$1A00`], [3rd GRP0], [8--9],
  [5], [`$1A80`], [3rd GRP1], [10--11])

The index is Y = row × 6 + line, and that is the whole trick. Because a plane is 128-byte aligned and Y is always below 128, the address arithmetic can never carry: `LDA $1800,Y` is always exactly four cycles, never five. A kernel that spends an unpredictable number of cycles does not draw, it tears, so the alignment is not tidiness but the difference between a display and a mess. It also means the kernel needs no zero-page pointers and no per-row setup: Y simply counts from 0 to 125 down the whole screen, and the rows are implicit in the data.

Within a byte, bit 7 is the leftmost pixel. The left column of the pair occupies bits 7 to 5 with bit 4 as its inter-character gap; the right column bits 3 to 1 with bit 0 as its gap.

#bytefield(([7], 22pt), ([6], 22pt), ([5], 22pt), ([4 gap], 34pt), ([3], 22pt), ([2], 22pt), ([1], 22pt), ([0 gap], 34pt))

#sect[Composing a row]

A program never touches the planes to write text. It tells the cartridge, through three one-shot operations on the control page:

#tbl((auto, auto, 1fr),
  th[Store to], th[Data], th[Effect],
  [`$1DF0`], [row 0--20], [begin composing that row; the cursor is at column 0],
  [`$1DF1`], [a character], [append it; past twelve, further characters are dropped],
  [`$1DF2`], [0], [render the composed row into the planes])

The render happens on the cartridge's other core, so it is not instantaneous on hardware: a program that begins the next row's characters at once hands the render a row that is already being overwritten. The cell TEXTGEN at `$1F0D` holds the row last rendered in its low bits and flips its top bit every time, and a careful program waits for it to change --- bounded, since emulation renders inside the store and the cell has already changed by the time the wait begins.

#pair("; FNROWA / FNCHR / FNENDR are the library's names for the three stores.
        lda     #3
        jsr     FNROWA          ; row 3
        lda     #'H'
        sta     FNRSEL+FH_TCHR
        lda     #'I'
        sta     FNRSEL+FH_TCHR
        ldx     FNBTXG          ; the generation before...
        jsr     FNENDR          ; ...render...
        ldy     #0
WAITR:  cpx     FNBTXG          ; ...and until it changes
        bne     DONE
        dey
        bne     WAITR
DONE:",
" FNH_TROW = 3
 FNH_TCHR = 72
 FNH_TCHR = 73
 gen = FNBTXG
 FNH_TEND = 0
 for l = 0 to 100
 if FNBTXG <> gen then goto done
 next
done")

Anything the reply window holds can go straight into a row the same way, byte by byte, without ever passing through RAM: the library's `FNRRPL` renders up to Y bytes of the reply at offset X into row A, stopping at a NUL. That is how every program in this handbook shows what the adapter said.

#sect[The font]

The font is the cartridge's, generated from one Python table in the bring-up. It covers `$20` to `$7F`; lowercase folds to uppercase, and anything else renders as `?`. At three by five pixels several pairs of characters would be identical, and three of them were redrawn: `0` is rounded against `O`'s square, `S` is curved against `5`'s flat top, `[` is half-width against `C`. The only remaining collision is `?` against DEL, which is deliberate.

#fig(grid(columns: 2, column-gutter: 12pt, align: bottom,
  box(stroke: 0.6pt + ink, image("../images/screens/asm-hello.png", width: 1.7in)),
  tv(read("../listings/asm/screen.txt"), size: 6.2pt, w: 2.0in)),
  caption: [The bring-up's first screen: the whole font, baked into the planes of a plain 4K image and shown by the kernel --- as MAME drew it, and as the cartridge's font renders the same `screen.txt`. Every one of its 756 plane bytes was byte-compared against the renderer.])

#sect[The kernel]

`fujidisp.inc` is two routines. `DINIT` sets the TIA up once: two players, three copies each eight pixels apart (`NUSIZ` = `$03`) so that P0 draws groups 0, 2 and 4 and P1 groups 1, 3 and 5, interleaving into 48 contiguous pixels; vertical delay on both, which is what makes the six-write sequence land in the right copies; and the positioning, transcribed from batari Basic's kernel: sixteen `NOP`s and one three-cycle store so that `RESP0` lands on cycle 38, `RESP1` three cycles later, `HMP0` of `$F0` to pull player 0 right one pixel, and an early `HMOVE` on the line after.

#important[The four positioning constants are the coordinates of a one-pixel-wide window and must not be retimed. The six copies are 2.67 cycles apart and the kernel's stores are three, so where the block sits decides whether each update lands between copies or inside one. Every wrong setting still looks like text. They were found by decoding the raster back into plane bytes and comparing, not by eye.]

`DLOOP` draws frames forever: three lines of `VSYNC`, 37 of `VBLANK` during which it calls the client's `APPVBL` hook, 33 blank lines, the 126 lines of text, 33 more, and 30 of overscan --- 262 in all. The text lines are the body below, 53 of the 76 cycles a line has:

```
KERN:   sta     WSYNC
        lda     TP0,y           ; 4
        sta     GRP0            ; 3   ->  7   new GRP0 = group 0
        lda     TP1,y           ; 4   -> 11
        sta     GRP1            ; 3   -> 14   displays group 0
        lda     TP2,y           ; 4   -> 18
        sta     GRP0            ; 3   -> 21   displays group 1
        lda     TP4,y           ; 4   -> 25
        tax                     ; 2   -> 27
        txs                     ; 2   -> 29   park group 4 in S
        lda     TP3,y           ; 4   -> 33
        tax                     ; 2   -> 35
        lda     TP5,y           ; 4   -> 39
        stx     GRP1            ; 3   -> 42   displays group 2
        tsx                     ; 2   -> 44   recover group 4
        stx     GRP0            ; 3   -> 47   displays group 3
        sta     GRP1            ; 3   -> 50   displays group 4
        sty     GRP0            ; 3   -> 53   displays group 5; value unused
        iny
        cpy     #TLINES
        bne     KERN
```

Three things in it are not style. The stack pointer is a register: the four late writes drift a full cycle across the block, recovering a byte from zero page costs three cycles and `TSX` costs two, and that one cycle is the whole difference between a schedule that closes and one that does not. The seventh write, `STY GRP0`, exists because with vertical delay six data bytes need seven writes, and its value is a don't-care, so the scanline counter serves. And nothing between the `TXS` and the restore may touch the stack: no `JSR`, and the 6507 has no interrupts to worry about.

After the last line both players are blanked with three writes, not two: with `VDELP` set, a write to `GRP0` reloads only the delayed `GRP1` and vice versa. The obvious-looking alternative, toggling `VDELP` off and on, restores the stale delayed registers, and the blank lines below the text then redraw the last kernel line. That was one of the three bugs the bring-up's raster comparison found; the missing seventh write and the `LDX`-versus-`TSX` cycle were the others.

#sect[The pixel that cannot be drawn]

The 48-pixel block is six player copies and the kernel's seven writes; the four late ones span 33 pixels, while the distance from the end of group 0 to the start of group 5 is 32. No position serves all 48, so every position loses exactly one pixel, and the least bad one to lose is pixel 7 --- bit 0 of plane 0, which the text renderer already spends as column 1's inter-character gap. Text never notices. Anything else drawn through the planes, such as the card art of Section 18, has to know.

#sect[What the cartridge can draw for you]

Beyond text rows, the cartridge's blit port moves and transforms bytes into the planes with six stores --- source, destination, count and a transform --- so that a screenful that the console has neither the RAM nor the raster time to build itself costs it 24 cycles. Section 18 lists all fourteen transforms. Four are text: a raw copy, a text row composed straight from the reply window, a single cell changed in place (which is how a list moves its cursor without recomposing the row), and a row rendered from a cartridge path buffer, which is how a program sees what it has typed into a buffer it cannot read back.

#note[A blit is a single-slot request on the RP2040: the bus core hands it to the other core and there is no queue. Fire two in a row and the second overwrites the first before it has run --- on hardware. In emulation the blit runs inside the store and nothing is lost. Poll BLITGEN at `$1F19` for a change before the next one.]

#sect[batari Basic]

A BASIC program keeps batari Basic's own kernel for its playfield and sprites, and shows the cartridge's text through a minikernel, `fujitext.asm`, that draws a band of rows from the planes between the playfield and the score. It is the body above, verbatim, with the positioning folded in. Section 8 explains how many rows a frame can afford.
