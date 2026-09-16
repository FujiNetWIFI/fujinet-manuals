#import "../lib.typ": *
= Command Reference: The Cartridge Itself

Below the FujiBus devices is the cartridge's own protocol: the register file and the hotspots the earlier sections used, the blit port, the path buffers, and the boot doorbells. This is all of it in one place. None of these reaches the adapter; each is decoded by the RP2040 on the console's bus, and takes effect before the next fetch.

#sect[Registers]

Arm with a store to `$1D00` + the register number; commit with a store of the value to `$1DFF`. The library's `FNRW` is the pair; in BASIC, `FNA_*` are the arm addresses and `FNCMT` the commit.

#tbl((auto, auto, 1fr),
  th[Register], th[Name], th[Value],
  [`$00`], [DEVICE], [the device id],
  [`$01`], [CMD], [the command],
  [`$02`], [NPARAM], [parameters at the head of the TX stream],
  [`$05`], [DATA_RST], [any: rewind the TX stream],
  [`$06`], [RXSLICE], [0 or 1: the reply slice shown at `$1B00`; SLICE_ECHO is painted last],
  [`$10`], [SEQ], [ACKSEQ + 1, wrapping 255 to 1: launch],
  [`$11`], [BOOTLOCK], [`$B5`: arm the swap of a staged image],
  [`$12`, `$13`], [BOOTSEL_1, BOOTSEL_2], [`$B5` then `$4A` as consecutive writes: reboot the RP2040 into its USB bootloader for a firmware update. One stray access can never do it.])

#sect[One-shot operations]

The top half of the control page. The store's data byte is the operand, and none of these need a commit.

#tbl((auto, auto, 1fr),
  th[Store to], th[Name], th[Effect],
  [`$1D80` + b], [BANK], [serve bank b at `$1000`; b up to `$6F`],
  [`$1DF0`], [TROW], [begin composing text row = data],
  [`$1DF1`], [TCHR], [append the character; saturates at twelve],
  [`$1DF2`], [TEND], [render the row into the planes; TEXTGEN changes when it has],
  [`$1DF3`], [PATH_CH], [append the character to the selected path buffer],
  [`$1DF4`], [PATH_OP], [a path-buffer operation, below],
  [`$1DF5`--`$1DF9`], [BLIT_SL, SH, DL, DH, CNT], [the blit's source offset, destination offset and count],
  [`$1DFA`], [BLIT_GO], [fire the blit with transform = data; BLITGEN changes when it has landed],
  [`$1DFC`, `$1DFD`], [ARM1, ARM2], [`$B5` then `$4A`: open the decode gate],
  [`$1DFE`], [SWAP], [serve the staged image; only after BOOTLOCK],
  [`$1DFF`], [COMMIT], [commit the armed register with the data])

#sect[The path buffers]

Four 256-byte buffers in the cartridge, one selected at a time. `PATH_CH` appends; `PATH_OP` with one of these values acts:

#tbl((auto, auto, 1fr),
  th[Value], th[Name], th[Effect],
  [0], [RST], [empty the selected buffer],
  [1], [POP], [drop the last path component, keeping the `/`: `/a/b/c/` becomes `/a/b/`, and `/` stays `/`],
  [2], [TX], [emit the buffer into the TX stream, NUL-padded to exactly 256 bytes],
  [3], [TXRAW], [emit just its bytes, unpadded --- for a URL],
  [4], [POPCH], [drop one character: the keyboard's backspace],
  [5--8], [SEL0--SEL3], [subsequent operations act on that buffer; 3 is the edit scratch],
  [9], [COMMIT], [selected = the scratch: accept an edit],
  [10], [SEED], [scratch = selected: begin an edit; cancelling is simply neither])

PATHLEN at `$1F17` is the selected buffer's length, republished on every change and every select, which is how a program pads the rest of a 256-byte payload after the cartridge has emitted the directory part raw.

#pair("        lda     #FP_SEL0        ; buffer 0
        sta     FNRSEL+FH_PATHO
        lda     #FP_RST
        sta     FNRSEL+FH_PATHO
        lda     #'/'
        sta     FNRSEL+FH_PATHC
        ; ... later, inside a transaction:
        lda     #FP_TX          ; 256 bytes, one store
        sta     FNRSEL+FH_PATHO",
" FNH_PATHO = FP_SEL0
 FNH_PATHO = FP_RST
 FNH_PATHC = 47
 rem ... later, inside a transaction:
 FNH_PATHO = FP_TX")

#sect[The blit port]

Six stores: source offset into the reply window (two bytes), destination offset into the text planes (two), a count, and the transform, which fires it. What each field means depends on the transform.

#tbl((auto, auto, 1fr),
  th[Transform], th[Name], th[What it does],
  [0], [RAW], [copy `cnt` bytes from the reply to the planes unchanged],
  [1], [TEXT], [compose text row `dst` from up to twelve ASCII bytes at reply offset `src`],
  [2], [FIELD], [a 10 × 10 game field at reply offset `src` (0 sea, 1 hit, 2 miss) into ten text rows from `dst`, with a row digit in column 0; `cnt` is the cursor cell or `$FF` for none],
  [3], [HULLS], [`cnt` ship placements (`pos + 100 × dir`) at reply offset `src` as `#` over the composed board, then paint from row `dst`],
  [4, 5, 6], [SEA, CELL, PAINT], [compose a board that is not in the reply: fill with sea; set `board[cnt]` to the low byte of `src`; paint it into ten rows from `dst`],
  [7], [PATH], [`cnt` characters of the selected path buffer from offset `src` into text row `dst`: how a program sees what it typed],
  [8], [TCELL], [one character, the low byte of `src`, into one cell, `dst` = row × 12 + column: how a list moves its cursor],
  [9], [CARD], [five playing cards from `hand[11]` at reply offset `src` --- two lowercase bytes each, rank then suit --- across the top two text rows from `dst`; `cnt` bit 0 draws the first face down],
  [10], [PFCLR], [clear kinds `src` (a mask) in playfield slot `dst`],
  [11], [PFIELD], [a game field at reply offset `src` into playfield slot `dst`: hits and misses],
  [12], [PFHULL], [`cnt` placements at reply offset `src` OR-ed into slot `dst`'s hull plane],
  [13], [PFCELL], [one cell `cnt` of slot `dst`: set the kinds in the mask `src`, or clear them if bit 7 is set])

The playfield transforms (10--13) compose the six tables the Battleship board kernel reads; Section 14 explains them. The cell glyphs are `.` sea, `X` hit, `O` miss, `#` hull, `+` cursor.

#pair("; FNBARG: A = src low, X = dst low, Y = cnt; FNBLIT: fire A and wait
        lda     #GFIELD         ; reply offset of gamefield[100]
        ldx     #0              ; slot 0
        ldy     #0
        jsr     FNBARG
        lda     #FB_PFLD
        jsr     FNBLIT",
" FNH_BLSL = 110 : rem reply offset of the field
 FNH_BLSH = 0
 FNH_BLDL = 0 : rem slot 0
 FNH_BLDH = 0
 FNH_BLCNT = 0
 gen = FNBGEN
 FNH_BLGO = FB_PFLD
 for l = 0 to 100
 if FNBGEN <> gen then goto landed
 next
landed")

#caution[A blit is a single-slot request. On the RP2040 the bus core hands it to the other core and there is no queue, so the next blit's argument stores would overwrite this one's before it ran. Wait for BLITGEN at `$1F19` to change before the next --- bounded, because in emulation it has already changed by the time you look.]

#sect[The card transform]

A suit is not in ASCII, and at three pixels wide a heart, a spade and a club are nearly the same picture, so a card is a transform and not a glyph. Five cards sit on a six-pixel pitch --- five of art, one of gap --- filling pixels 2 to 30, which is planes 0 to 3; planes 4 and 5 are untouched, so a name or a purse can share the row. A card is two text rows tall, the rank above and the pip below, with the blank sixth line of the cell keeping them apart. The bed starts at pixel 2 because pixel 7 cannot be drawn by any client (Section 5). `hand[11]` is a C string: rank in `23456789tjqka`, suit in `hdcs`, `??` for a hole card, and the first NUL rank ends the hand.

#sect[The boot doorbells]

BOOTLOCK is honoured only once an image is staged (BOOT_STATE = 2), and SWAP only once BOOTLOCK has been honoured; an unarmed swap hotspot is inert. BOOTSEL wants its two registers written consecutively with `$B5` then `$4A`, and the cartridge reboots into the RP2040's USB bootloader, from which a new firmware is copied as a file. There is no acknowledgement to poll.
