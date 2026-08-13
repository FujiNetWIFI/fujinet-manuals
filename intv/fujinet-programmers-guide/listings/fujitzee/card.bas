' card.bas -- scorecard grid rendering, cursor, seat strip and standings
' overlay for the round 1..13 game screen. One player's full 15-category
' card is shown at a time (BACKTAB rows 1-8); a permanent 6-seat strip
' (row 9) shows who's who, and holding keypad ENTER swaps rows 1-8 for a
' name+total standings list.
'
' Layout (20x12 BACKTAB):
'   row0  viewed player's name, round
'   row1-6  ONE..SIX   | SET3,SET4,HOUS,SRUN,LRUN,CNT,FUJI (rows1-7)
'   row7    UP (computed) | FUJI (row7 of the right column)
'   row8    BON (computed) | TOT (computed)
'   row9    6-seat strip (alias letters, color-coded)
'   row10   5 dice + rolls-left
'   row11   server prompt + move timer
'
' Category placement:
'   left column,  rows 1-6: score indices 0-5  (ONE..SIX)
'   left column,  row 7:    UP   (computed upper total, index 6 on the wire)
'   left column,  row 8:    BON  (computed bonus, index 7 on the wire)
'   right column, rows 1-7: score indices 8-14 (SET3,SET4,HOUS,SRUN,LRUN,CNT,FUJI)
'   right column, row 8:    TOT  (computed running grand total)

    CONST CARD_ROW0    = screenpos(0, 0)
    CONST CARD_LCOL_LABEL = 0
    CONST CARD_LCOL_VALUE = 5
    CONST CARD_RCOL_LABEL = 10
    CONST CARD_RCOL_VALUE = 15
    CONST SEAT_ROW     = 9

    ' Page background is blue (cls_blue in fujitzee.bas fills every CLS'd
    ' screen with this), so every color below pairs with BG_BLUE instead
    ' of BG_BLACK -- anything still paired with black would sit on an
    ' invisible matching square rather than actually showing a black box.
    CONST COL_TEXT     = FG_WHITE + BG_BLUE
    CONST COL_LABEL    = FG_TAN + BG_BLUE
    CONST COL_HILITE   = FG_YELLOW + BG_BLUE
    CONST COL_POTENTIAL = FG_GREEN + BG_BLUE
    CONST COL_DASH     = FG_BLACK + BG_BLUE
    CONST COL_CURSOR   = FG_BLACK + BG_YELLOW
    CONST COL_ACTIVE   = FG_BLACK + BG_YELLOW
    CONST COL_VIEWED   = FG_BLACK + BG_GREEN
    CONST COL_SEATEMPTY = FG_BLACK + BG_BLUE
    ' MODE 1's foreground palette is fixed at 8 colors (no orange) --
    ' orange only exists as one of the 16 background shades. So "orange
    ' text" for the round indicator is rendered as black-on-orange
    ' instead of a foreground color.
    CONST COL_ROUND    = FG_BLACK + BG_ORANGE

' ---------------------------------------------------------------------------
' player_color_tbl / player_color: a distinct FG color per seat (0-5),
' used everywhere a player's name is drawn (header, seat strip, standings,
' lobby, score reveal) so a given player reads consistently across every
' screen. FG_BLUE is deliberately excluded -- it would be invisible on
' the page's own blue background. Only 6 colors are available without
' reusing COL_TEXT/COL_LABEL/the status colors above, matching
' MAX_PLAYERS; seats beyond that (spectators, in the standings/lobby
' lists which show up to 8) fall back to plain COL_TEXT.
' ---------------------------------------------------------------------------
player_color_tbl: DATA FG_RED, FG_TAN, FG_DARKGREEN, FG_GREEN, FG_YELLOW, FG_WHITE

DIM pc_idx, #pc_color
player_color: PROCEDURE
    IF pc_idx < 6 THEN
        #pc_color = player_color_tbl(pc_idx) + BG_BLUE
    ELSE
        #pc_color = COL_TEXT
    END IF
END

' ---------------------------------------------------------------------------
' card_init: draw the static label frame once (labels never change; only
' the values in the adjoining 3-char fields do). Callers CLS and call this
' on the transition into round 1..13; the value cells drawn each poll after
' this leave the labels alone.
' ---------------------------------------------------------------------------
card_init: PROCEDURE
    PRINT AT CARD_ROW0 + screenpos(0, 1) COLOR COL_LABEL, "ONE "
    PRINT AT CARD_ROW0 + screenpos(0, 2) COLOR COL_LABEL, "TWO "
    PRINT AT CARD_ROW0 + screenpos(0, 3) COLOR COL_LABEL, "THR "
    PRINT AT CARD_ROW0 + screenpos(0, 4) COLOR COL_LABEL, "FOU "
    PRINT AT CARD_ROW0 + screenpos(0, 5) COLOR COL_LABEL, "FIV "
    PRINT AT CARD_ROW0 + screenpos(0, 6) COLOR COL_LABEL, "SIX "
    PRINT AT CARD_ROW0 + screenpos(0, 7) COLOR COL_LABEL, "UP  "
    PRINT AT CARD_ROW0 + screenpos(0, 8) COLOR COL_LABEL, "BON "

    PRINT AT CARD_ROW0 + screenpos(10, 1) COLOR COL_LABEL, "SET3"
    PRINT AT CARD_ROW0 + screenpos(10, 2) COLOR COL_LABEL, "SET4"
    PRINT AT CARD_ROW0 + screenpos(10, 3) COLOR COL_LABEL, "HOUS"
    PRINT AT CARD_ROW0 + screenpos(10, 4) COLOR COL_LABEL, "SRUN"
    PRINT AT CARD_ROW0 + screenpos(10, 5) COLOR COL_LABEL, "LRUN"
    PRINT AT CARD_ROW0 + screenpos(10, 6) COLOR COL_LABEL, "CNT "
    PRINT AT CARD_ROW0 + screenpos(10, 7) COLOR COL_LABEL, "FUJI"
    PRINT AT CARD_ROW0 + screenpos(10, 8) COLOR COL_LABEL, "TOT "
END

' ---------------------------------------------------------------------------
' calc_running_total: sum every filled category (UP+BON+SET3..FUJI, unset
' treated as 0) for the player record at #ctr_addr into #ctr_total. The
' server only fills the wire's grand-total slot (score index 15) at game
' end, so the live TOT row and the standings overlay compute it themselves.
' ---------------------------------------------------------------------------
DIM #ctr_addr, #ctr_total, ctr_i, #ctr_v
calc_running_total: PROCEDURE
    #ctr_total = 0
    FOR ctr_i = 6 TO 14
        #ctr_v = score_at(#ctr_addr, ctr_i)
        IF #ctr_v <> SCORE_UNSET AND #ctr_v <> SCORE_VIEWING THEN #ctr_total = #ctr_total + #ctr_v
    NEXT ctr_i
END

' ---------------------------------------------------------------------------
' draw_cat_cell: render one 3-char value field. Inputs:
'   dcc_row     BACKTAB row (1-8)
'   dcc_valcol  BACKTAB column of the value field's first cell
'   dcc_cat     score index 0-5 or 8-14 for a real category; 100=UP,
'               101=BON, 102=TOT for the three computed cells
'   #dcc_addr   viewed player's 42-byte record in FN_RX
'   dcc_own     1 if this is your own card and it's your turn (enables the
'               green "potential score" hint on unscored categories)
'   dcc_cursor  1 if this cell is the SCORE-mode cursor's current selection
' ---------------------------------------------------------------------------
DIM dcc_row, dcc_valcol, dcc_cat, #dcc_addr, dcc_own, dcc_cursor
DIM #dcc_v, #dcc_color, #dcc_pot
draw_cat_cell: PROCEDURE
    #dcc_color = COL_TEXT
    IF dcc_cursor THEN #dcc_color = COL_CURSOR

    IF dcc_cat = 100 OR dcc_cat = 101 THEN
        #dcc_v = score_at(#dcc_addr, 6 + (dcc_cat - 100))
        IF #dcc_v = SCORE_UNSET OR #dcc_v = SCORE_VIEWING THEN
            IF dcc_cursor = 0 THEN #dcc_color = COL_DASH
            PRINT AT screenpos(dcc_valcol, dcc_row) COLOR #dcc_color, "  -"
        ELSE
            PRINT AT screenpos(dcc_valcol, dcc_row) COLOR #dcc_color, <.3>#dcc_v
        END IF
    ELSEIF dcc_cat = 102 THEN
        #ctr_addr = #dcc_addr
        GOSUB calc_running_total
        PRINT AT screenpos(dcc_valcol, dcc_row) COLOR #dcc_color, <.3>#ctr_total
    ELSE
        #dcc_v = score_at(#dcc_addr, dcc_cat)
        IF #dcc_v = SCORE_UNSET OR #dcc_v = SCORE_VIEWING THEN
            #dcc_pot = 255
            IF dcc_own THEN #dcc_pot = valid_at(dcc_cat)
            IF #dcc_pot <> 255 THEN
                ' A potential of exactly 0 (category open but this roll
                ' doesn't fill it) is only shown on the row the cursor is
                ' currently sitting on -- matching the reference clients
                ' (gamelogic.c's drawTextAlt/drawBlank cursor-move
                ' handling), which hides the "0" everywhere else so an
                ' open board isn't a wall of zeros before you've decided.
                IF #dcc_pot > 0 THEN
                    IF dcc_cursor = 0 THEN #dcc_color = COL_POTENTIAL
                    PRINT AT screenpos(dcc_valcol, dcc_row) COLOR #dcc_color, <.3>#dcc_pot
                ELSEIF dcc_cursor THEN
                    PRINT AT screenpos(dcc_valcol, dcc_row) COLOR #dcc_color, "  0"
                ELSE
                    PRINT AT screenpos(dcc_valcol, dcc_row) COLOR COL_TEXT, "   "
                END IF
            ELSE
                IF dcc_cursor = 0 THEN #dcc_color = COL_DASH
                PRINT AT screenpos(dcc_valcol, dcc_row) COLOR #dcc_color, "  -"
            END IF
        ELSE
            PRINT AT screenpos(dcc_valcol, dcc_row) COLOR #dcc_color, <.3>#dcc_v
        END IF
    END IF
END

' ---------------------------------------------------------------------------
' render_card: redraw every value cell of the viewed player's card.
' Globals expected: #rc_addr (player record), rc_own (1 if own card + your
' turn, enables potentials), rc_mode (0=DICE,1=SCORE), rc_selcat (score
' index the SCORE-mode cursor sits on; only consulted when rc_mode=1),
' rc_reveal (score index 0-14 to force-highlight regardless of rc_own/
' rc_mode -- used to flash another player's just-scored category; 255 for
' none, the normal case).
' Split into a left-column half and a right-column half with a WAIT between
' (and another before the header/seat strip) so a full repaint -- 16 value
' cells worth of PRINT -- can't tear a frame the way one unbroken burst
' covering half the visible screen could (see board.bas/5card.bas's own
' per-region WAIT breaks for the same reason: no page-flip on the STIC).
' ---------------------------------------------------------------------------
DIM #rc_addr, rc_own, rc_mode, rc_selcat, rc_reveal, rc_i, rc_cur
render_card: PROCEDURE
    FOR rc_i = 0 TO 7
        rc_cur = 0
        IF rc_mode = 1 AND rc_own AND rc_i < 6 AND rc_selcat = rc_i THEN rc_cur = 1
        IF rc_reveal = rc_i THEN rc_cur = 1
        dcc_row = rc_i + 1 : dcc_valcol = CARD_LCOL_VALUE : #dcc_addr = #rc_addr
        dcc_own = rc_own : dcc_cursor = rc_cur
        IF rc_i < 6 THEN
            dcc_cat = rc_i
        ELSEIF rc_i = 6 THEN
            dcc_cat = 100
        ELSE
            dcc_cat = 101
        END IF
        GOSUB draw_cat_cell
    NEXT rc_i
    WAIT

    FOR rc_i = 0 TO 7
        rc_cur = 0
        IF rc_mode = 1 AND rc_own AND rc_i < 7 AND rc_selcat = rc_i + 8 THEN rc_cur = 1
        IF rc_reveal = rc_i + 8 THEN rc_cur = 1
        dcc_row = rc_i + 1 : dcc_valcol = CARD_RCOL_VALUE : #dcc_addr = #rc_addr
        dcc_own = rc_own : dcc_cursor = rc_cur
        IF rc_i < 7 THEN dcc_cat = rc_i + 8 ELSE dcc_cat = 102
        GOSUB draw_cat_cell
    NEXT rc_i
END

' ---------------------------------------------------------------------------
' render_seatstrip: one letter per seated player (up to 6), spaced 3
' columns apart, color-coded: active player highlighted, the currently
' viewed player (if different) in a second color, everyone else plain
' white, empty seats a dim dot.
'
' This is the player's *first* name character (PL_NAME+0), not the
' server's PL_ALIAS-indexed "unique highlight character" the field
' technically exists for. The alias-indirection version (PEEK an alias
' index byte, then PEEK name[that index]) was extensively verified
' correct -- traced the exact compiled instructions, cross-checked real
' alias/name bytes pulled live from both the dev and production servers
' (every case seen had alias=0, i.e. this simpler version is what it
' would have shown anyway) -- and still rendered '?' for every seat in
' practice. Simplifying to a single direct PEEK removes the double
' indirection entirely rather than continuing to chase a mismatch between
' verified-correct analysis and observed behavior.
' ---------------------------------------------------------------------------
DIM ss_i, ss_addr, #ss_ch, #ss_color
render_seatstrip: PROCEDURE
    FOR ss_i = 0 TO 5
        IF ss_i < state_playercount THEN
            ss_addr = player_addr(ss_i)
            #ss_ch = (PEEK(ss_addr + PL_NAME) AND 255)
            IF #ss_ch >= 97 AND #ss_ch <= 122 THEN #ss_ch = #ss_ch - 32
            IF #ss_ch < 32 OR #ss_ch > 95 THEN #ss_ch = 63 ' '?' fallback
            ' Active/viewed status wins the BG (black-on-yellow/green, as
            ' before -- needs to stay readable and unambiguous regardless
            ' of which player it is); otherwise the letter uses that
            ' player's own color, so it reads consistently with their
            ' name everywhere else even while just sitting in the strip.
            IF ss_i = active_player THEN
                #ss_color = COL_ACTIVE
            ELSEIF ss_i = view_idx THEN
                #ss_color = COL_VIEWED
            ELSE
                pc_idx = ss_i
                GOSUB player_color
                #ss_color = #pc_color
            END IF
        ELSE
            #ss_ch = 46 ' '.'
            #ss_color = COL_SEATEMPTY
        END IF
        #BACKTAB(screenpos(ss_i * 3, SEAT_ROW)) = (#ss_ch - 32) * 8 + #ss_color
    NEXT ss_i
END

' ---------------------------------------------------------------------------
' render_player_list: name + running total for up to 8 seated players,
' starting at BACKTAB row prl_top. Shared by show_standings (the keypad-
' ENTER overlay during play) and render_gameover (the round-99 screen) --
' both just want "who's got how many points," and calc_running_total's sum
' of every filled category equals the server's own final total once every
' category is filled, so the same running-total math is correct in both
' places without needing to trust the wire's game-over-only total field.
' ---------------------------------------------------------------------------
DIM prl_top, prl_i, prl_addr, #prl_pc
render_player_list: PROCEDURE
    #prl_pc = state_playercount
    IF #prl_pc > 8 THEN #prl_pc = 8
    FOR prl_i = 0 TO #prl_pc - 1
        prl_addr = player_addr(prl_i)
        pc_idx = prl_i
        GOSUB player_color
        #df_src = prl_addr + PL_NAME : df_pos = screenpos(0, prl_top + prl_i) : df_len = 9 : #df_color = #pc_color
        GOSUB draw_field
        #ctr_addr = prl_addr
        GOSUB calc_running_total
        PRINT AT screenpos(15, prl_top + prl_i) COLOR COL_TEXT, <.4>#ctr_total
    NEXT prl_i
END

' ---------------------------------------------------------------------------
' show_standings: keypad-ENTER overlay. Blanks rows 1-8 and lists seated
' players' names and running totals instead of the card. Blocks on its own
' input loop (like ingame_menu) rather than folding into the poll loop --
' holding ENTER for a couple of frames of paused polling is harmless, and
' this keeps render_card's cell layout untouched by an overlay that only
' needs to exist while the button is held.
' ---------------------------------------------------------------------------
DIM sd_i
show_standings: PROCEDURE
    FOR sd_i = 1 TO 8
        PRINT AT screenpos(0, sd_i) COLOR COL_TEXT, "                    "
    NEXT sd_i
    prl_top = 1
    GOSUB render_player_list

sd_wait:
    WAIT
    IF CONT1.KEY = 11 THEN GOTO sd_wait
END
