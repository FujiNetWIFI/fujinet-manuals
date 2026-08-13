' dice.bas -- die-face GRAM bitmaps and draw routine, MODE 1 (FG/BG). Same
' technique as fujinet-5cardstud/intv/gfx.bas's cards: each face is one 8x8
' GRAM card, loaded once at boot, drawn by poking a BACKTAB cell to
' (index + 256) * 8 + color.
'
' Six faces (pip counts 1-6, GRAM index 0-5), a standard 3x3 pip grid on an
' outlined 8x8 box. A die marked to re-roll isn't a separate GRAM tile --
' it's the same face drawn with the cursor/held background color, exactly
' like card.bas's scorecard cursor and board.bas's cell coloring. That
' keeps the GRAM budget at 6 of 64 cards, leaving the rest free for a
' future sprite-based roll animation (neither 5cardstud nor Battleship use
' any MOBs at all).

' ---------------------------------------------------------------------------
' dice_init: load the 6 die faces into GRAM slots 0-5 (screen codes 256-261).
' Must run once at startup. GRAM loads take effect on the next video frame,
' so DEFINE is followed by WAIT -- a second DEFINE in the same frame would
' silently overwrite the first.
' ---------------------------------------------------------------------------
dice_init: PROCEDURE
    DEFINE 0, 6, diceart : WAIT
END

' ---------------------------------------------------------------------------
' print_die: draw one die face at BACKTAB cell dp_pos. Inputs: dp_pos (cell
' offset), dp_val (1-6; anything outside that range draws a blank cell so an
' empty dice string at turn start doesn't render garbage), #dp_color.
' ---------------------------------------------------------------------------
DIM dp_pos, dp_val, #dp_color
print_die: PROCEDURE
    IF dp_val >= 1 AND dp_val <= 6 THEN
        #BACKTAB(dp_pos) = #dp_color + (dp_val - 1 + 256) * 8
    ELSE
        #BACKTAB(dp_pos) = #dp_color + 32 * 8 ' blank (space glyph)
    END IF
END

' ---------------------------------------------------------------------------
' draw_dice_row: a ROLL tile at BACKTAB row 10 col 0, then the 5 dice at
' cols 2,4,6,8,10, plus a small rolls-left readout. Reads the live wire
' dice string (FN_RX+GAME_DICE) and the local keep mask (SC_KEEP) directly
' rather than taking them as parameters -- both are always current by the
' time this is called (either just-polled, or unrolled state.bas globals
' set up before a redraw).
'
' SC_KEEP holds the wire's roll-mask convention ('1'=49 will reroll,
' '0'=48 will be kept -- see fujitzee.bas's compose_url, which sends it
' straight through to /roll/<mask>), but the *default* per die, before the
' player touches anything, is '1' (reroll) -- pressing the button marks a
' die to be KEPT, matching how every other Fujitzee client's dice
' selection reads (you pick what you're holding onto, not what you're
' throwing away). So the highlight here is for the KEEP state (mask='0'),
' not the reroll state.
'
' Inputs: dr_mode (0=DICE,1=SCORE), dr_cursor (0-5: 0=the ROLL tile, 1-5=
' dice 0-4, matching the reference clients' own cursorPos convention --
' only drawn highlighted when dr_mode=0).
' ---------------------------------------------------------------------------
    CONST DICE_ROW = 10
    CONST ROLL_COL = 0
    CONST DICE_COL0 = 2
    CONST COL_DICE_NORMAL = FG_BLACK + BG_WHITE
    CONST COL_DICE_KEPT   = FG_BLACK + BG_YELLOW
    CONST COL_DICE_CURSOR = FG_BLACK + BG_GREEN

DIM dr_mode, dr_cursor, dr_i, #dr_ch, dr_kept, #dr_rolls
draw_dice_row: PROCEDURE
    #dp_color = COL_DICE_NORMAL
    IF dr_mode = 0 AND dr_cursor = 0 THEN #dp_color = COL_DICE_CURSOR
    PRINT AT screenpos(ROLL_COL, DICE_ROW) COLOR #dp_color, "R"

    FOR dr_i = 0 TO 4
        #dr_ch = (PEEK(FN_RX + GAME_DICE + dr_i) AND 255)
        IF #dr_ch >= 49 AND #dr_ch <= 54 THEN dp_val = #dr_ch - 48 ELSE dp_val = 0

        dr_kept = (PEEK(SC_KEEP + dr_i) AND 255) = 48
        #dp_color = COL_DICE_NORMAL
        IF dr_kept THEN #dp_color = COL_DICE_KEPT
        IF dr_mode = 0 AND dr_cursor = dr_i + 1 THEN #dp_color = COL_DICE_CURSOR

        dp_pos = screenpos(DICE_COL0 + dr_i * 2, DICE_ROW)
        GOSUB print_die
    NEXT dr_i

    ' Blank cols 11-19 first, not just the 2 cells the count actually
    ' needs -- "x" used to sit at col 17 here as a separator, and being
    ' lowercase it was outside MODE 1's GROM range (ASCII 32-95 only,
    ' uppercase/digits/symbols), rendering as a garbage glyph. Blanking
    ' the whole gap defensively means any future stray write here (or
    ' leftover from a still-undiagnosed one) can't leave visible debris
    ' either, rather than only ever touching the exact 2 cells this
    ' PRINT needs.
    FOR dr_i = 11 TO 19
        #BACKTAB(screenpos(dr_i, DICE_ROW)) = COL_DICE_NORMAL
    NEXT dr_i
    #dr_rolls = state_rollsleft
    PRINT AT screenpos(18, DICE_ROW) COLOR COL_DICE_NORMAL, <.2>#dr_rolls
END

' ---------------------------------------------------------------------------
' animate_roll: dice-rolling flourish shown right after any player's roll
' lands (yours or another seat's -- see game_loop's roll_changed check,
' which fires this for anyone). FN_RX already holds the settled result at
' this point (the server computes the whole roll in one shot), so this
' doesn't determine the outcome -- it flickers whichever dice the *wire's*
' keepRoll field says were rerolled (GAME_KEEPROLL; the server echoes
' back whatever mask was actually submitted, by whoever just rolled, not
' our own local SC_KEEP -- that's what makes this work for other players'
' turns too) through random faces a few times, with a tick each flicker,
' before the normal render draws the real values. Kept dice are drawn at
' their real (unchanging) value throughout, echoing the reference C
' clients' rollFrames/ROLL_SOUND_MOD animation (gamelogic.c). Wire
' convention is unaffected by the local keep/reroll UI relabeling above:
' keepRoll's '1' still means "this die was rerolled."
' ---------------------------------------------------------------------------
    CONST ROLL_ANIM_FRAMES = 24
    CONST ROLL_ANIM_STEP = 3

DIM ra_frame, ra_i, #ra_ch
animate_roll: PROCEDURE
    FOR ra_frame = 1 TO ROLL_ANIM_FRAMES
        IF ra_frame % ROLL_ANIM_STEP = 1 THEN
            FOR ra_i = 0 TO 4
                IF (PEEK(FN_RX + GAME_KEEPROLL + ra_i) AND 255) = 49 THEN
                    dp_val = RAND(6) + 1
                ELSE
                    #ra_ch = (PEEK(FN_RX + GAME_DICE + ra_i) AND 255)
                    IF #ra_ch >= 49 AND #ra_ch <= 54 THEN dp_val = #ra_ch - 48 ELSE dp_val = 0
                END IF
                dp_pos = screenpos(DICE_COL0 + ra_i * 2, DICE_ROW) : #dp_color = COL_DICE_NORMAL
                GOSUB print_die
            NEXT ra_i
            GOSUB sound_tick
        END IF
        WAIT
    NEXT ra_frame
END

' Pip grid: border at rows/cols 0 and 7; pips at rows/cols {2,4,6} of an
' 8x8 cell. Row4 col4 is the single center pip (face 1); rows/cols 2 and 6
' are the four corners (faces 4-6); row4 cols 2/6 are the middle side pips
' (face 6 only).
diceart:
    ' Face 1 (index 0): center pip.
    BITMAP "oooooooo"
    BITMAP "o......o"
    BITMAP "o......o"
    BITMAP "o......o"
    BITMAP "o...o..o"
    BITMAP "o......o"
    BITMAP "o......o"
    BITMAP "oooooooo"

    ' Face 2 (index 1): top-left, bottom-right.
    BITMAP "oooooooo"
    BITMAP "o......o"
    BITMAP "o.o....o"
    BITMAP "o......o"
    BITMAP "o......o"
    BITMAP "o......o"
    BITMAP "o.....oo"
    BITMAP "oooooooo"

    ' Face 3 (index 2): top-left, center, bottom-right.
    BITMAP "oooooooo"
    BITMAP "o......o"
    BITMAP "o.o....o"
    BITMAP "o......o"
    BITMAP "o...o..o"
    BITMAP "o......o"
    BITMAP "o.....oo"
    BITMAP "oooooooo"

    ' Face 4 (index 3): four corners.
    BITMAP "oooooooo"
    BITMAP "o......o"
    BITMAP "o.o...oo"
    BITMAP "o......o"
    BITMAP "o......o"
    BITMAP "o......o"
    BITMAP "o.o...oo"
    BITMAP "oooooooo"

    ' Face 5 (index 4): four corners + center.
    BITMAP "oooooooo"
    BITMAP "o......o"
    BITMAP "o.o...oo"
    BITMAP "o......o"
    BITMAP "o...o..o"
    BITMAP "o......o"
    BITMAP "o.o...oo"
    BITMAP "oooooooo"

    ' Face 6 (index 5): four corners + two middle side pips.
    BITMAP "oooooooo"
    BITMAP "o......o"
    BITMAP "o.o...oo"
    BITMAP "o......o"
    BITMAP "o.o...oo"
    BITMAP "o......o"
    BITMAP "o.o...oo"
    BITMAP "oooooooo"
