' kbd.bas -- edge-detected input + on-screen character-grid keyboard,
' ported from fujinet-config/intv (input.bas + the scr_recolor helper from
' screen.bas), with one change: the value display spans THREE rows (0-2)
' instead of one, a 60-character tail-anchored window onto a buffer of up
' to 256 bytes -- long N: URLs wrap across the rows and scroll once they
' outgrow them.
'
' All 95 printable characters (32-126) fit in 6 rows x 16 columns, so the
' cursor position IS the character (ch = 32 + gy*16 + gx) -- no SHIFT/SYM
' paging. A row of action buttons (SPC/DEL/OK/ESC) sits below the grid.
' The keypad works too: 0 = space, CLEAR = backspace, ENTER = accept.
'
' grid_entry contract (same as fujinet-config's): caller sets #ge_dst
' (destination buffer) and #g_max (its size, including the NUL) BEFORE
' calling, and primes the buffer -- NUL at offset 0 for a fresh field, or
' existing NUL-terminated text to edit (it is preserved and editable).
' #ge_dst is mutated live REGARDLESS of accept or cancel. Returns fn_ok =
' 1 (OK button or keypad ENTER) or 0 (ESC button only); g_len holds the
' final length and #ge_dst is NUL-terminated there. g_len is an 8-bit
' variable, so the ceiling is #g_max = 256 (255 characters + NUL) -- one
' character shy of what the mailbox TX window could carry to an OPEN, and
' #g_max must be the 16-bit variable it is: as an 8-bit variable, 256
' would silently wrap to 0 and disable grid_append's overflow guard.
'
' Screen layout used by grid_entry (rows 9 and 11 are never touched, so
' the caller can keep hints there):
'   rows 0-2   value window (60 cells, tail-anchored, green cursor block)
'   rows 3-8   the character grid
'   row  10    SPC / DEL / OK / ESC

    ' Color-stack mode foreground colors.
    CONST CS_BLACK      = 0
    CONST CS_BLUE       = 1
    CONST CS_RED        = 2
    CONST CS_TAN        = 3
    CONST CS_DARKGREEN  = 4
    CONST CS_GREEN      = 5
    CONST CS_YELLOW     = 6
    CONST CS_WHITE      = 7

    CONST COL_NORMAL   = CS_WHITE
    CONST COL_HILIGHT  = CS_YELLOW
    CONST COL_DIM      = CS_BLUE
    CONST COL_ERROR    = CS_RED
    CONST COL_VALUE    = CS_TAN
    CONST COL_CURSOR   = CS_GREEN

    CONST SCREEN_COLS = 20
    DEF FN screenpos(aColumn, aRow) = (((aRow)*SCREEN_COLS)+(aColumn))

    ' Disc directions (as reported by in_poll).
    CONST DISC_UP     = $0004
    CONST DISC_RIGHT  = $0002
    CONST DISC_DOWN   = $0001
    CONST DISC_LEFT   = $0008

    ' Keypad, as decoded by CONT.KEY.
    CONST KEYPAD_0      = 0
    CONST KEYPAD_CLEAR  = 10
    CONST KEYPAD_ENTER  = 11
    CONST KEYPAD_NONE   = 12

    ' Grid geometry. Value rows 0-2; charset rows 3-8; actions row 10.
    CONST VAL_ROW0        = 0
    CONST VAL_ROWS        = 3
    CONST VAL_CELLS       = 60    ' VAL_ROWS * SCREEN_COLS
    CONST GRID_ROW0       = 3
    CONST GRID_COL0       = 2
    CONST GRID_ROWS       = 6
    CONST GRID_COLS       = 16
    CONST GRID_ACTION_ROW = 10
    CONST GRID_ACT_COL0   = 2    ' SPC
    CONST GRID_ACT_COL1   = 7    ' DEL
    CONST GRID_ACT_COL2   = 12   ' OK
    CONST GRID_ACT_COL3   = 17   ' ESC

    CONST IN_REPEAT_DELAY = 18   ' frames held before auto-repeat (~0.3s)
    CONST IN_REPEAT_RATE  = 6    ' frames between repeats (~0.1s)

    DIM in_disc, in_pdisc, in_rdelay
    DIM in_braw, in_btn, in_pbtn
    DIM in_key, in_pkey

' ---------------------------------------------------------------------------
' in_poll: call once per frame (after WAIT). Sets, per call:
'   in_disc - DISC_UP/DOWN/LEFT/RIGHT on a fresh press or an auto-repeat
'             tick while held; 0 otherwise.
'   in_btn  - 1 on a fresh action-button press (any of B0/B1/B2).
'   in_key  - the decoded keypad value on a fresh press, else KEYPAD_NONE.
' Uses the unqualified CONT.* pseudo-variables (both controllers OR'd).
' ---------------------------------------------------------------------------
in_poll: PROCEDURE
    in_disc = 0
    IF CONT.UP THEN in_disc = DISC_UP
    IF CONT.DOWN THEN in_disc = DISC_DOWN
    IF CONT.LEFT THEN in_disc = DISC_LEFT
    IF CONT.RIGHT THEN in_disc = DISC_RIGHT

    IF in_disc <> 0 THEN
        IF in_disc <> in_pdisc THEN
            in_rdelay = IN_REPEAT_DELAY
        ELSE
            IF in_rdelay > 0 THEN
                in_rdelay = in_rdelay - 1
                in_disc = 0
            ELSE
                in_rdelay = IN_REPEAT_RATE
            END IF
        END IF
    END IF
    in_pdisc = 0
    IF CONT.UP THEN in_pdisc = DISC_UP
    IF CONT.DOWN THEN in_pdisc = DISC_DOWN
    IF CONT.LEFT THEN in_pdisc = DISC_LEFT
    IF CONT.RIGHT THEN in_pdisc = DISC_RIGHT

    in_braw = 0
    IF CONT.B0 OR CONT.B1 OR CONT.B2 THEN in_braw = 1
    IF in_braw <> 0 AND in_pbtn = 0 THEN
        in_btn = 1
    ELSE
        in_btn = 0
    END IF
    in_pbtn = in_braw

    in_key = KEYPAD_NONE
    IF CONT.KEY <> KEYPAD_NONE AND CONT.KEY <> in_pkey THEN
        in_key = CONT.KEY
    END IF
    in_pkey = CONT.KEY
END

' ---------------------------------------------------------------------------
' grid_entry -- see the header comment for the contract.
' ---------------------------------------------------------------------------
    DIM g_x, g_y, g_px, g_py, g_len, g_ch, ga_idx
    DIM #ge_dst, #g_max
    DIM k_row, k_col, k_i, k_c, k_max, k_color
    DIM #k_word

grid_entry: PROCEDURE
    GOSUB grid_draw_charset
    GOSUB grid_draw_actions

    g_len = 0
    WHILE (g_len < #g_max - 1) AND ((PEEK(#ge_dst + g_len) AND 255) <> 0)
        g_len = g_len + 1
    WEND
    GOSUB grid_draw_value

    g_x = 0 : g_y = 0
    g_px = 255 : g_py = 255

    DO WHILE 1
        WAIT
        GOSUB grid_draw_cursor
        GOSUB in_poll

        IF in_disc = DISC_UP AND g_y > 0 THEN g_y = g_y - 1
        IF in_disc = DISC_DOWN AND g_y < GRID_ROWS THEN g_y = g_y + 1
        IF in_disc = DISC_LEFT AND g_x > 0 THEN g_x = g_x - 1
        IF in_disc = DISC_RIGHT THEN
            IF g_y = GRID_ROWS THEN
                IF g_x < 3 THEN g_x = g_x + 1
            ELSE
                IF g_x < GRID_COLS - 1 THEN g_x = g_x + 1
            END IF
        END IF
        IF g_y = GRID_ROWS AND g_x > 3 THEN g_x = 3

        IF in_key = KEYPAD_0 THEN g_ch = 32 : GOSUB grid_append
        IF in_key = KEYPAD_CLEAR THEN GOSUB grid_backspace
        IF in_key = KEYPAD_ENTER THEN
            fn_ok = 1
            EXIT DO
        END IF

        IF in_btn <> 0 THEN
            IF g_y < GRID_ROWS THEN
                g_ch = 32 + g_y * GRID_COLS + g_x
                IF g_ch <= 126 THEN GOSUB grid_append
            ELSE
                IF g_x = 0 THEN g_ch = 32 : GOSUB grid_append
                IF g_x = 1 THEN GOSUB grid_backspace
                IF g_x = 2 THEN
                    fn_ok = 1
                    EXIT DO
                END IF
                IF g_x = 3 THEN
                    fn_ok = 0
                    EXIT DO
                END IF
            END IF
        END IF
    LOOP
END

' grid_draw_charset: paints all 96 cells (95 real chars + one always-blank).
grid_draw_charset: PROCEDURE
    FOR g_y = 0 TO GRID_ROWS - 1
        FOR g_x = 0 TO GRID_COLS - 1
            g_ch = 32 + g_y * GRID_COLS + g_x
            IF g_ch > 126 THEN g_ch = 32
            #BACKTAB((GRID_ROW0 + g_y) * SCREEN_COLS + GRID_COL0 + g_x) = (g_ch - 32) * 8 + COL_VALUE
        NEXT g_x
    NEXT g_y
END

grid_draw_actions: PROCEDURE
    PRINT AT screenpos(GRID_ACT_COL0, GRID_ACTION_ROW) COLOR COL_DIM,"SPC"
    PRINT AT screenpos(GRID_ACT_COL1, GRID_ACTION_ROW) COLOR COL_DIM,"DEL"
    PRINT AT screenpos(GRID_ACT_COL2, GRID_ACTION_ROW) COLOR COL_DIM," OK"
    PRINT AT screenpos(GRID_ACT_COL3, GRID_ACTION_ROW) COLOR COL_DIM,"ESC"
END

' grid_recolor: change only the COLOR of k_max+1 already-drawn cells on row
' k_row starting at column k_col -- the glyphs underneath stay. (The
' scr_recolor helper from fujinet-config's screen.bas, renamed so a program
' including this file can keep its own s_* variables.)
grid_recolor: PROCEDURE
    FOR k_i = 0 TO k_max
        #k_word = (#BACKTAB(k_row * SCREEN_COLS + k_col + k_i) AND $FFF8) + k_color
        #BACKTAB(k_row * SCREEN_COLS + k_col + k_i) = #k_word
    NEXT k_i
END

' grid_draw_cursor: un-highlight the previous cell (g_px/g_py), highlight
' the current one (g_x/g_y). g_px=255 on the very first call skips the
' un-highlight.
grid_draw_cursor: PROCEDURE
    IF g_px <> 255 THEN
        IF g_py = GRID_ROWS THEN
            ga_idx = g_px : GOSUB grid_action_col
            k_row = GRID_ACTION_ROW : k_max = 2 : k_color = COL_DIM
            GOSUB grid_recolor
        ELSE
            g_ch = 32 + g_py * GRID_COLS + g_px
            IF g_ch > 126 THEN g_ch = 32
            #BACKTAB((GRID_ROW0 + g_py) * SCREEN_COLS + GRID_COL0 + g_px) = (g_ch - 32) * 8 + COL_VALUE
        END IF
    END IF

    IF g_y = GRID_ROWS THEN
        ga_idx = g_x : GOSUB grid_action_col
        k_row = GRID_ACTION_ROW : k_max = 2 : k_color = COL_HILIGHT
        GOSUB grid_recolor
    ELSE
        g_ch = 32 + g_y * GRID_COLS + g_x
        IF g_ch > 126 THEN g_ch = 32
        #BACKTAB((GRID_ROW0 + g_y) * SCREEN_COLS + GRID_COL0 + g_x) = (g_ch - 32) * 8 + COL_HILIGHT
    END IF

    g_px = g_x : g_py = g_y
END

' grid_action_col: given ga_idx (0-3), sets k_col to that action button's
' starting column.
grid_action_col: PROCEDURE
    IF ga_idx = 0 THEN k_col = GRID_ACT_COL0
    IF ga_idx = 1 THEN k_col = GRID_ACT_COL1
    IF ga_idx = 2 THEN k_col = GRID_ACT_COL2
    IF ga_idx = 3 THEN k_col = GRID_ACT_COL3
END

' grid_draw_value: tail-anchored 60-cell window (rows 0-2) onto #ge_dst,
' with a trailing cursor block. A value longer than 59 characters scrolls:
' the window always shows the tail, where typing is happening.
grid_draw_value: PROCEDURE
    k_i = 0
    IF g_len > VAL_CELLS - 1 THEN k_i = g_len - (VAL_CELLS - 1)
    FOR k_col = 0 TO VAL_CELLS - 1
        k_c = 32
        IF k_i + k_col < g_len THEN k_c = PEEK(#ge_dst + k_i + k_col) AND 255
        IF k_c < 32 OR k_c > 126 THEN k_c = 32
        #BACKTAB(VAL_ROW0 * SCREEN_COLS + k_col) = (k_c - 32) * 8 + COL_VALUE
    NEXT k_col
    IF g_len - k_i < VAL_CELLS THEN
        #BACKTAB(VAL_ROW0 * SCREEN_COLS + (g_len - k_i)) = (95 - 32) * 8 + COL_CURSOR
    END IF
END

grid_append: PROCEDURE
    IF g_len >= #g_max - 1 THEN RETURN
    POKE (#ge_dst + g_len), g_ch
    g_len = g_len + 1
    POKE (#ge_dst + g_len), 0
    GOSUB grid_draw_value
END

grid_backspace: PROCEDURE
    IF g_len = 0 THEN RETURN
    g_len = g_len - 1
    POKE (#ge_dst + g_len), 0
    GOSUB grid_draw_value
END
