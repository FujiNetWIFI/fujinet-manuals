' board.bas -- colored-squares (40x24 4x4-block) render kernel for the four
' 10x10 Battleship boards. Requires MODE 0 (Color Stack) -- colored-squares
' cards do not exist in MODE 1 (constants.bas / IntyBASIC manual).
'
' A BACKTAB word with bit 12 = 1 and bit 11 = 0 is not a GROM/GRAM card at
' all: it is four independently-coloured 4x4 pixel quadrants (constants.bas
' calls them "pixels" 0-3, laid out TL/TR/BL/BR). Colours 0-6 are the STIC
' primaries; 7 = transparent (shows the current colour-stack colour). This
' file never uses 7 -- every cell always gets an explicit colour, so unlike
' Carlsson's original battleships-display-example.bas there is no need to
' cycle the colour stack for decoration; MODE 0's four stack slots are left
' at their compiled-in defaults and ignored.
'
' Board layout (screen is 20 cards x 12 rows; each board is 5x5 cards):
'
'   col   0-4    5    6-10       11-19
'   row0  q1  | div |  q2   |  right-hand chrome panel
'    -4              |       |  (player names, ships-left, clock --
'   row5  ---- divider row ----   owned by the caller, not this file)
'   row6  q0  | div |  q3   |
'    -10             |       |
'   row11 .......... 20-char prompt / status line ..........
'
' Quadrant numbering matches the C clients' graphics.h convention: 0-3
' starting bottom-left, going clockwise; the local player is always
' quadrant 0.

    board_col: DATA 0, 0, 6, 6      ' q0..q3 origin column (card coords)
    board_row: DATA 6, 0, 0, 6      ' q0..q3 origin row

' cs_mask(sub): AND-mask that clears sub-square `sub`'s bits (0=TL,1=TR,
' 2=BL,3=BR) plus bit 11 (must always be 0 on a colored-squares card) and
' bit 12 (the enable bit) -- cs_plot ADDs CS_COLOUR_SQUARES_ENABLE back in
' unconditionally afterward, so the mask must clear it here rather than
' preserve it. An earlier version of this table preserved bit 12: on a card
' that was already a colored square (true for every cell after its first
' write), that left the ADD doubling an already-set bit 12, which carries
' into bit 13 and clears bit 12 -- turning the card back into a plain GROM/
' GRAM text card and rendering as a stray letter instead of a color.
' $D1FF (BR) additionally clears bit 13 (the BR quadrant's relocated high
' colour bit -- see cs_val below).
    cs_mask: DATA $E7F8, $E7C7, $E63F, $C1FF

' cs_val(sub*8 + color): pre-shifted bit pattern for sub-square `sub` (0-3)
' showing STIC colour `color` (0-6 primary, 7 = transparent/background).
' Pulled directly from constants.bas's CS_PIX0_*..CS_PIX3_* -- CS_PIX3_*
' already has the bit11->bit13 relocation baked in for colours 4-6 (a
' straight *512 shift for colour>=4 would land in bit 11, illegal on a
' colored-squares card; the STIC expects the BR quadrant's high colour bit
' at bit 13 instead).
    cs_val: DATA CS_PIX0_BLACK, CS_PIX0_BLUE, CS_PIX0_RED, CS_PIX0_TAN, CS_PIX0_DARKGREEN, CS_PIX0_GREEN, CS_PIX0_YELLOW, CS_PIX0_BACKGROUND
    DATA CS_PIX1_BLACK, CS_PIX1_BLUE, CS_PIX1_RED, CS_PIX1_TAN, CS_PIX1_DARKGREEN, CS_PIX1_GREEN, CS_PIX1_YELLOW, CS_PIX1_BACKGROUND
    DATA CS_PIX2_BLACK, CS_PIX2_BLUE, CS_PIX2_RED, CS_PIX2_TAN, CS_PIX2_DARKGREEN, CS_PIX2_GREEN, CS_PIX2_YELLOW, CS_PIX2_BACKGROUND
    DATA CS_PIX3_BLACK, CS_PIX3_BLUE, CS_PIX3_RED, CS_PIX3_TAN, CS_PIX3_DARKGREEN, CS_PIX3_GREEN, CS_PIX3_YELLOW, CS_PIX3_BACKGROUND

' Cell-state colours. Chosen so "empty/unknown" reads calmly (blue water)
' and hit/miss/ship read at a glance; see board_draw below for the mapping
' from the server's gamefield byte values (state.bas: 0 unknown, 1 hit,
' 2 miss) to these.
    CONST BCOL_MISS    = 0   ' black
    CONST BCOL_WATER   = 1   ' blue  -- unknown/untouched cell
    CONST BCOL_HIT     = 2   ' red
    CONST BCOL_SUNKSHIP = 3  ' tan   -- winner's revealed ships at game over
    CONST BCOL_SHIP    = 5   ' green -- own ship, own board only
    CONST BCOL_CURSOR  = 6   ' yellow
    CONST BCOL_DIVIDER = 0   ' black

' ---------------------------------------------------------------------------
' cs_fill: paint an entire card (all four sub-squares) with one colour.
' Inputs: cs_col, cs_row (card coords), cs_color.
' ---------------------------------------------------------------------------
DIM cs_col, cs_row, cs_q, cs_color
DIM #cs_word, cs_addr
cs_fill: PROCEDURE
    #cs_word = CS_COLOUR_SQUARES_ENABLE + cs_val(cs_color) + cs_val(8 + cs_color) + cs_val(16 + cs_color) + cs_val(24 + cs_color)
    cs_addr = screenpos(cs_col, cs_row)
    #BACKTAB(cs_addr) = #cs_word
END

' ---------------------------------------------------------------------------
' cs_plot: read-modify-write a single sub-square, preserving the other
' three. Inputs: cs_col, cs_row (card coords), cs_q (0-3), cs_color.
' ---------------------------------------------------------------------------
cs_plot: PROCEDURE
    cs_addr = screenpos(cs_col, cs_row)
    #BACKTAB(cs_addr) = (#BACKTAB(cs_addr) AND cs_mask(cs_q)) + CS_COLOUR_SQUARES_ENABLE + cs_val(cs_q * 8 + cs_color)
END

' ---------------------------------------------------------------------------
' board_init: paint all four boards to water and the dividers to black.
' Call once after MODE 0 / CLS, before the first board_draw.
' ---------------------------------------------------------------------------
DIM bi_bq, bi_cc, bi_cr
board_init: PROCEDURE
    FOR bi_bq = 0 TO 3
        FOR bi_cr = 0 TO 4
            FOR bi_cc = 0 TO 4
                cs_col = board_col(bi_bq) + bi_cc
                cs_row = board_row(bi_bq) + bi_cr
                cs_color = BCOL_WATER
                GOSUB cs_fill
            NEXT bi_cc
        NEXT bi_cr
        WAIT
    NEXT bi_bq

    ' Divider: column 5 for all 11 board rows, row 5 for all 11 board
    ' columns except column 5 itself (already painted by the first loop).
    FOR bi_cr = 0 TO 10
        cs_col = 5 : cs_row = bi_cr : cs_color = BCOL_DIVIDER : GOSUB cs_fill
    NEXT bi_cr
    FOR bi_cc = 0 TO 10
        IF bi_cc <> 5 THEN
            cs_col = bi_cc : cs_row = 5 : cs_color = BCOL_DIVIDER : GOSUB cs_fill
        END IF
    NEXT bi_cc
    WAIT
END

' ---------------------------------------------------------------------------
' board_draw: full 25-card repaint of quadrant bd_bq's 10x10 grid from a
' 100-byte gamefield buffer (state.bas values: 0 unknown, 1 hit, 2 miss) at
' RAM address #bd_field. One WAIT per board -- 25 single-write cards per
' frame stays well inside vblank; the lesson from 5cardstud's differential
' renderer (5card.bas) is that an unbroken multi-region burst does not.
' Ship overlay (own board only) is layered on afterward by the caller via
' board_cell, since the gamefield alone doesn't carry ship positions.
' ---------------------------------------------------------------------------
DIM bd_bq, #bd_field
DIM bd_cc, bd_cr, bd_sub, bd_cell, bd_state, bd_color
DIM #bd_word, bd_addr
board_draw: PROCEDURE
    FOR bd_cr = 0 TO 4
        FOR bd_cc = 0 TO 4
            #bd_word = CS_COLOUR_SQUARES_ENABLE
            FOR bd_sub = 0 TO 3
                ' sub 0=TL(x even,y even) 1=TR(x odd,y even)
                ' sub 2=BL(x even,y odd)  3=BR(x odd,y odd)
                bd_cell = (bd_cr * 2 + bd_sub / 2) * 10 + (bd_cc * 2 + (bd_sub AND 1))
                bd_state = PEEK(#bd_field + bd_cell) AND 255
                IF bd_state = 1 THEN
                    bd_color = BCOL_HIT
                ELSEIF bd_state = 2 THEN
                    bd_color = BCOL_MISS
                ELSE
                    bd_color = BCOL_WATER
                END IF
                #bd_word = #bd_word + cs_val(bd_sub * 8 + bd_color)
            NEXT bd_sub
            bd_addr = screenpos(board_col(bd_bq) + bd_cc, board_row(bd_bq) + bd_cr)
            #BACKTAB(bd_addr) = #bd_word
        NEXT bd_cc
        WAIT
    NEXT bd_cr
END

' ---------------------------------------------------------------------------
' board_cell: update a single cell (x,y both 0-9) on quadrant bc_bq to
' bc_color. Used for incremental attack-result updates, own-ship overlay
' during/after placement, and the targeting cursor (caller is responsible
' for restoring the underlying colour when the cursor moves off a cell --
' this file is stateless and does not remember what was drawn).
' ---------------------------------------------------------------------------
DIM bc_bq, bc_x, bc_y, bc_color
board_cell: PROCEDURE
    cs_col = board_col(bc_bq) + bc_x / 2
    cs_row = board_row(bc_bq) + bc_y / 2
    cs_q = (bc_y AND 1) * 2 + (bc_x AND 1)
    cs_color = bc_color
    GOSUB cs_plot
END
