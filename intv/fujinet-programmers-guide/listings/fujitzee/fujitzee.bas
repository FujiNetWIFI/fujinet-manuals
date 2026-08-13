' fujitzee.bas -- FujiNet Fujitzee (Yahtzee-style) for Intellivision, entry
' point + state machine. Follows the pattern established by
' fujinet-5cardstud/intv/5card.bas and fujinet-battleship/intv/battleship.bas
' (name entry -> table select -> game loop -> in-game menu), adapted for a
' scorecard game: the 20x12 screen can't show all 6 players' 15-category
' cards at once, so one player's card is shown at a time (card.bas), paged
' with the disc when it isn't your turn, alongside a permanent 6-seat strip.
'
' GOTO boot_start jumps over every INCLUDE below before any of it runs --
' see fujinet.bas for why: falling into a PROCEDURE or DATA block by
' straight-line execution corrupts the return stack.
    GOTO boot_start

    INCLUDE "constants.bas"
    INCLUDE "fujinet.bas"
    INCLUDE "state.bas"
    INCLUDE "dice.bas"
    INCLUDE "card.bas"
    INCLUDE "sound.bas"

    CONST ROWCELLS = 20
    CONST STATUS_ROW = screenpos(0, 11)

' ---------------------------------------------------------------------------
' URL literals (ASCII DATA). url_path selects the endpoint:
'   0 tables   1 state   2 ready   3 roll/<mask>   4 score/<idx>   5 leave
' ---------------------------------------------------------------------------
lit_n_colon: DATA 78,58
lit_https: DATA 104,116,116,112,115,58,47,47,102,117,106,105,116,122,101,101,46,99,97,114,114,45,100,101,115,105,103,110,115,46,99,111,109,47
lit_tables: DATA 116,97,98,108,101,115
lit_qbin: DATA 63,98,105,110,61,49
lit_state: DATA 115,116,97,116,101
lit_ready: DATA 114,101,97,100,121
lit_roll: DATA 114,111,108,108,47
lit_score: DATA 115,99,111,114,101,47
lit_leave: DATA 108,101,97,118,101
lit_qtable: DATA 63,116,97,98,108,101,61
lit_aplayer: DATA 38,112,108,97,121,101,114,61
lit_abin: DATA 38,98,105,110,61,49

    CONST LEN_HTTPS = 34

    ' Lobby appkey: creator 1 / app 1, key = this game's registered slot.
    ' See fujinet-fujitzee/src/misc.h AK_LOBBY_KEY_SERVER.
    CONST AK_LOBBY_KEY_SERVER = 3

' ---------------------------------------------------------------------------
' Globals
' ---------------------------------------------------------------------------
    DIM gs_i, gs_j, #gs_char, #gs_c
    DIM ne_i, ne_j, ne_cur, ne_len
    DIM ne_buf(8)
    DIM ak_try
    DIM #tbl_count, tbl_sel
    DIM inp_lock
    DIM want_leave, im_sel
    DIM url_path
    DIM #tmp_addr

    ' split_room_url locals (see procedure below)
    DIM sp_i, sp_found, sp_ok, sp_j, sp_k, sp_c, sp_valid, sp_m

    DIM #cur_round, #cur_pc, prev_round, prev_active, prev_seen_pc, my_turn
    DIM poll_wait, has_action
    DIM turn_changed, roll_changed, #prev_dice_rollsleft, shadow_seeded
    DIM view_lock, ui_mode, dice_cur, crs_idx, score_idx

    DIM pn_val, pn_h, pn_t, pn_o, pn_started
    DIM #ti_timeleft, ti_framecount, ti_allkept, pt_i, score_is_fujitzee, at_bottom_row

' ---------------------------------------------------------------------------
' fn_putnum: append the decimal (no leading zeros) representation of pn_val
' (0-999) into FN_TX at the current #fn_txlen. IntyBASIC has no built-in
' itoa; score indices only run 0-14, but a 3-digit routine costs nothing
' extra and matches fujinet-battleship/intv/battleship.bas's version.
' ---------------------------------------------------------------------------
fn_putnum: PROCEDURE
    pn_h = pn_val / 100
    pn_t = (pn_val / 10) % 10
    pn_o = pn_val % 10
    pn_started = 0
    IF pn_h > 0 THEN
        POKE (FN_TX + #fn_txlen), pn_h + 48 : #fn_txlen = #fn_txlen + 1
        pn_started = 1
    END IF
    IF pn_t > 0 OR pn_started THEN
        POKE (FN_TX + #fn_txlen), pn_t + 48 : #fn_txlen = #fn_txlen + 1
    END IF
    POKE (FN_TX + #fn_txlen), pn_o + 48 : #fn_txlen = #fn_txlen + 1
END

' ---------------------------------------------------------------------------
' draw_field: render df_len ASCII bytes from #df_src onto the screen at
' BACKTAB offset df_pos, in color #df_color. MODE 1 only exposes GROM cards
' 0-63 (ASCII 32-95, no lowercase), so unlike Battleship's MODE 0 client
' this uppercases -- server strings (names, prompts) arrive lowercased.
' Stops at a NUL and pads the rest of the field with spaces; clamps
' anything outside the printable range to a space rather than drawing
' garbage. Ported from fujinet-5cardstud/intv/5card.bas's version.
' ---------------------------------------------------------------------------
DIM df_i, #df_c, df_stop
draw_field: PROCEDURE
    df_stop = 0
    FOR df_i = 0 TO df_len - 1
        #df_c = (PEEK(#df_src + df_i) AND 255)
        IF #df_c = 0 THEN df_stop = 1
        IF df_stop THEN
            #df_c = 32
        ELSEIF #df_c >= 97 AND #df_c <= 122 THEN
            #df_c = #df_c - 32
        END IF
        IF #df_c < 32 OR #df_c > 95 THEN #df_c = 32
        #BACKTAB(df_pos + df_i) = (#df_c - 32) * 8 + #df_color
    NEXT df_i
END

' ---------------------------------------------------------------------------
' cls_blue: CLS, then fill the whole 240-cell BACKTAB with a blank blue
' card. CLS alone leaves every cell at card 0 / color 0 (black), so
' without this every screen would still show a black field behind
' whatever text gets drawn on top of it. Every CLS in this file goes
' through here instead, matching fujinet-5cardstud/intv/5card.bas's
' fill_bg pattern.
' ---------------------------------------------------------------------------
DIM cb_i
cls_blue: PROCEDURE
    CLS
    FOR cb_i = 0 TO 239
        #BACKTAB(cb_i) = COL_TEXT
    NEXT cb_i
END

' ---------------------------------------------------------------------------
' compose_url: build "N:<endpoint><path...><suffix>" directly into FN_TX.
' url_path=3 (roll) appends SC_KEEP's 5 raw ascii mask bytes directly (it's
' already in wire format, no NUL). url_path=4 (score) appends score_idx via
' fn_putnum.
' ---------------------------------------------------------------------------
compose_url: PROCEDURE
    #fn_txlen = 0
    #fn_src = VARPTR lit_n_colon(0) : fn_len = 2 : GOSUB fn_putstr
    #fn_src = SC_ENDPT : ls_max = 65 : GOSUB fn_strlen : GOSUB fn_putstr

    IF url_path = 0 THEN
        #fn_src = VARPTR lit_tables(0) : fn_len = 6 : GOSUB fn_putstr
        #fn_src = VARPTR lit_qbin(0) : fn_len = 6 : GOSUB fn_putstr
    ELSE
        IF url_path = 1 THEN
            #fn_src = VARPTR lit_state(0) : fn_len = 5 : GOSUB fn_putstr
        ELSEIF url_path = 2 THEN
            #fn_src = VARPTR lit_ready(0) : fn_len = 5 : GOSUB fn_putstr
        ELSEIF url_path = 3 THEN
            #fn_src = VARPTR lit_roll(0) : fn_len = 5 : GOSUB fn_putstr
            #fn_src = SC_KEEP : fn_len = 5 : GOSUB fn_putstr
        ELSEIF url_path = 4 THEN
            #fn_src = VARPTR lit_score(0) : fn_len = 6 : GOSUB fn_putstr
            pn_val = score_idx
            GOSUB fn_putnum
        ELSE
            #fn_src = VARPTR lit_leave(0) : fn_len = 5 : GOSUB fn_putstr
        END IF

        #fn_src = VARPTR lit_qtable(0) : fn_len = 7 : GOSUB fn_putstr
        #fn_src = SC_TABLE : ls_max = 9 : GOSUB fn_strlen : GOSUB fn_putstr
        #fn_src = VARPTR lit_aplayer(0) : fn_len = 8 : GOSUB fn_putstr
        #fn_src = SC_NAME : ls_max = 9 : GOSUB fn_strlen : GOSUB fn_putstr
        #fn_src = VARPTR lit_abin(0) : fn_len = 6 : GOSUB fn_putstr
    END IF
END

' ===========================================================================
' Boot
' ===========================================================================
boot_start:
    MODE 1
    GOSUB cls_blue
    GOSUB dice_init
    PRINT AT 0 COLOR COL_TEXT, "FUJITZEE"
    PRINT AT 40, "CONNECTING TO FUJINET"
    GOSUB fn_wait_mailbox
    IF fn_ok = 0 THEN
        PRINT AT 40, "NO CARTRIDGE MAILBOX"
        GOTO halt
    END IF

' ---------------------------------------------------------------------------
' Name: try the shared lobby appkey (creator 1 / app 1 / key 0) first, with
' one retry (a cold RP2040/ESP32 link right after the mailbox comes up can
' time out the very first transaction); fall back to the disc letter picker
' if the read fails, comes back empty, or holds anything outside A-Z0-9 --
' this slot is shared by every FujiNet client, and a stray character here
' goes straight into the query string unescaped.
' ---------------------------------------------------------------------------
    gs_i = 0
    FOR ak_try = 0 TO 1
        ak_creator_lo = 1 : ak_creator_hi = 0 : ak_app = 1 : ak_key = 0 : ak_mode = 0
        GOSUB appkey_open
        IF fn_ok THEN EXIT FOR
    NEXT ak_try
    IF fn_ok THEN
        #fn_src = SC_NAME : ls_max = 9 : GOSUB appkey_read
        GOSUB appkey_close
        IF fn_len > 0 THEN
            gs_i = 1
            FOR gs_j = 0 TO fn_len - 1
                #gs_char = (PEEK(SC_NAME + gs_j) AND 255)
                IF #gs_char >= 97 AND #gs_char <= 122 THEN #gs_char = #gs_char - 32
                IF (#gs_char < 65 OR #gs_char > 90) AND (#gs_char < 48 OR #gs_char > 57) THEN gs_i = 0
            NEXT gs_j
        END IF
    END IF
    IF gs_i = 0 THEN GOSUB name_entry_screen

' ---------------------------------------------------------------------------
' Room: check the lobby server appkey (creator 1 / app 1 / key
' AK_LOBBY_KEY_SERVER). If the lobby wrote a room there, split it into
' SC_ENDPT/SC_TABLE and skip straight past table select. Seed the
' compiled-in default endpoint first so SC_ENDPT is always valid even if
' the appkey is empty or the read fails -- compose_url relies on it from
' here on for every request, not just /tables.
' ---------------------------------------------------------------------------
    FOR gs_i = 0 TO LEN_HTTPS - 1
        POKE (SC_ENDPT + gs_i), PEEK(VARPTR lit_https(0) + gs_i) AND 255
    NEXT gs_i
    POKE (SC_ENDPT + LEN_HTTPS), 0
    POKE SC_TABLE, 0

    FOR ak_try = 0 TO 1
        ak_creator_lo = 1 : ak_creator_hi = 0 : ak_app = 1
        ak_key = AK_LOBBY_KEY_SERVER : ak_mode = 0
        GOSUB appkey_open
        IF fn_ok THEN EXIT FOR
    NEXT ak_try
    IF fn_ok THEN
        #fn_src = SC_ENDPT : ls_max = 65 : GOSUB appkey_read
        GOSUB appkey_close
        IF fn_len > 0 THEN
            GOSUB split_room_url
        ELSE
            ' appkey_read always NUL-terminates at fn_len, even when
            ' empty, which would otherwise wipe out the default just
            ' seeded above -- restore it.
            FOR gs_i = 0 TO LEN_HTTPS - 1
                POKE (SC_ENDPT + gs_i), PEEK(VARPTR lit_https(0) + gs_i) AND 255
            NEXT gs_i
            POKE (SC_ENDPT + LEN_HTTPS), 0
        END IF
    END IF

    IF (PEEK(SC_TABLE) AND 255) <> 0 THEN GOTO table_joined

' ===========================================================================
' Table select (re-entered after leaving a table)
' ===========================================================================
table_select:
    GOSUB cls_blue
    PRINT AT 0 COLOR COL_TEXT, "CHOOSE A TABLE"
    PRINT AT 40, "REFRESHING..."

    url_path = 0 : GOSUB compose_url
    #net_readlen = TABLES_MAXLEN
    GOSUB api_call

    IF fn_ok = 1 THEN
        #tmp_addr = 1 + (PEEK(FN_RX) AND 255) * TABLE_STRIDE
        IF #net_gotlen < #tmp_addr THEN fn_ok = 0
    END IF

    IF fn_ok = 0 THEN
        PRINT AT 40, "SERVER UNREACHABLE  "
        inp_lock = 90
        WHILE inp_lock > 0
            inp_lock = inp_lock - 1
            WAIT
        WEND
        GOTO table_select
    END IF

    #tbl_count = (PEEK(FN_RX) AND 255)
    IF #tbl_count > 8 THEN #tbl_count = 8
    IF #tbl_count = 0 THEN
        PRINT AT 40, "NO TABLES AVAILABLE "
        inp_lock = 90
        WHILE inp_lock > 0
            inp_lock = inp_lock - 1
            WAIT
        WEND
        GOTO table_select
    END IF

    GOSUB cls_blue
    PRINT AT 0 COLOR COL_TEXT, "CHOOSE A TABLE"
    FOR gs_i = 0 TO #tbl_count - 1
        #tmp_addr = table_addr(gs_i)
        #df_src = #tmp_addr + TBL_NAME : df_pos = 20 + gs_i * 20 + 1 : df_len = 14 : #df_color = COL_TEXT
        GOSUB draw_field
        #df_src = #tmp_addr + TBL_PLAYERS : df_pos = 20 + gs_i * 20 + 15 : df_len = 5 : #df_color = COL_TEXT
        GOSUB draw_field
    NEXT gs_i

    tbl_sel = 0
    inp_lock = 0
ts_input:
    WAIT
    FOR gs_i = 0 TO #tbl_count - 1
        #gs_c = COL_TEXT
        IF gs_i = tbl_sel THEN #gs_c = COL_HILITE
        #BACKTAB(20 + gs_i * 20) = (62 - 32) * 8 + #gs_c ' '>' cursor glyph
    NEXT gs_i

    IF inp_lock > 0 THEN inp_lock = inp_lock - 1 : GOTO ts_input

    IF CONT1.DOWN THEN
        tbl_sel = tbl_sel + 1
        IF tbl_sel >= #tbl_count THEN tbl_sel = 0
        inp_lock = 8
        GOSUB sound_cursor
        GOTO ts_input
    END IF
    IF CONT1.UP THEN
        IF tbl_sel = 0 THEN tbl_sel = #tbl_count
        tbl_sel = tbl_sel - 1
        inp_lock = 8
        GOSUB sound_cursor
        GOTO ts_input
    END IF
    IF CONT1.BUTTON = 0 THEN GOTO ts_input
    GOSUB sound_select

    #tmp_addr = table_addr(tbl_sel)
    FOR gs_i = 0 TO 8
        POKE (SC_TABLE + gs_i), PEEK(#tmp_addr + TBL_ID + gs_i) AND 255
    NEXT gs_i

    ' Update the lobby server appkey so a reboot without going back
    ' through the lobby rejoins this table.
    GOSUB write_room_appkey

table_joined:
' ===========================================================================
' In a table: poll /state (or submit a pending ready/roll/score action in
' its place) and dispatch on round. A full CLS happens only on the
' transition into/out of play (lobby<->play<->gameover); every other poll
' updates cells in place -- the STIC has no page-flip, so a per-poll CLS
' would visibly blank the screen every cycle.
' ===========================================================================
    prev_round = 255  ' sentinel: forces the initial CLS/card_init
    prev_active = 255 ' sentinel: forces the initial turn-start reset+sound
    prev_seen_pc = 255 ' sentinel: skip the join/leave cue on the first poll
    poll_wait = 0
    want_leave = 0
    has_action = 0
    view_idx = 0 : view_lock = 0
    ui_mode = 0 : crs_idx = 0 : dice_cur = 0
    GOSUB sound_join

game_loop:
    WAIT

    IF poll_wait > 0 THEN
        poll_wait = poll_wait - 1
        GOTO gl_input
    END IF

    IF has_action = 1 THEN
        url_path = 2
    ELSEIF has_action = 2 THEN
        url_path = 3
    ELSEIF has_action = 3 THEN
        url_path = 4
    ELSE
        url_path = 1
    END IF
    has_action = 0
    GOSUB compose_url
    #net_readlen = GAME_MAXLEN
    GOSUB api_call
    GOSUB validate_state

    IF fn_ok = 0 THEN
        poll_wait = 30
        GOTO gl_input
    END IF

    #cur_round = state_round
    #cur_pc = state_playercount
    IF view_idx >= #cur_pc THEN view_idx = 0

    IF prev_seen_pc <> 255 THEN
        IF #cur_pc > prev_seen_pc THEN GOSUB sound_player_join
        IF #cur_pc < prev_seen_pc THEN GOSUB sound_player_left
    END IF
    prev_seen_pc = #cur_pc

    IF #cur_round = ROUND_LOBBY THEN
        IF prev_round <> ROUND_LOBBY THEN GOSUB cls_blue
        GOSUB render_lobby
        poll_wait = 45
    ELSEIF #cur_round = ROUND_GAMEOVER THEN
        IF prev_round <> ROUND_GAMEOVER THEN
            GOSUB cls_blue
            GOSUB render_gameover
        END IF
        poll_wait = 60
    ELSE
        IF prev_round = ROUND_LOBBY OR prev_round = 255 OR prev_round = ROUND_GAMEOVER THEN
            GOSUB cls_blue
            GOSUB card_init
            view_idx = 0 : ui_mode = 0 : crs_idx = 0 : dice_cur = 0
            #prev_dice_rollsleft = 255 ' sentinel: don't animate the first paint
            shadow_seeded = 0 ' sentinel: don't reveal-check against garbage
            FOR pt_i = 0 TO 4
                POKE (SC_KEEP + pt_i), 49
            NEXT pt_i
        END IF

        ' Whenever the active player changes (a new turn begins, yours or
        ' someone else's), snap the viewed card to follow them, like the
        ' other clients -- no need to manually page to see who's rolling.
        ' Manual disc-paging in gl_input still works to peek elsewhere
        ' while waiting; it's just overridden at the next turn change.
        turn_changed = 0
        IF active_player <> prev_active THEN turn_changed = 1

        ' Someone other than you just finished their turn (scored, or
        ' timed out and got auto-scored) -- flash whatever they picked
        ' before the view below flips over to whoever's active now. Skips
        ' your own turn ending: you already saw that happen live, driven
        ' by turn_input.
        IF shadow_seeded THEN
            IF turn_changed THEN
                IF prev_active <> 0 THEN
                    IF prev_active >= 0 THEN
                        IF prev_active < #cur_pc THEN GOSUB check_score_reveal
                    END IF
                END IF
            END IF
        END IF

        ' Deliberately nested single-condition IFs, not
        ' "IF active_player = 0 AND state_viewing = 0 THEN": IntyBASIC
        ' v1.4.2 miscompiles a chain of two "X = const" comparisons joined
        ' by AND when one side's value comes from an expression that
        ' itself contains "AND 255" (state_viewing's DEF FN body, or
        ' active_player's sign-extension formula) -- the fused codegen
        ' ANDs in a stray always-zero register instead of the second
        ' comparison, so the whole condition is always false. Confirmed
        ' by reading the generated .lst: it never called turn_input.
        my_turn = 0
        IF active_player = 0 THEN
            IF state_viewing = 0 THEN my_turn = 1
        END IF

        IF turn_changed THEN
            IF active_player >= 0 THEN
                IF active_player < #cur_pc THEN view_idx = active_player
            END IF
            IF my_turn THEN
                GOSUB sound_myturn
                ui_mode = 0 : crs_idx = 0 : dice_cur = 0
                FOR pt_i = 0 TO 4
                    POKE (SC_KEEP + pt_i), 49
                NEXT pt_i
            END IF
        END IF

        ' Snapshot whoever's active now, so whenever *their* turn ends we
        ' have a valid "before" state for check_score_reveal to diff
        ' against -- done every poll (cheap: 15 words), not just on
        ' turn_changed, since it must reflect their latest scoring right
        ' up until the moment they stop being active.
        IF active_player >= 0 THEN
            IF active_player < #cur_pc THEN
                GOSUB seed_score_shadow
                shadow_seeded = 1
            END IF
        END IF

        ' A roll landed for whoever's turn it is -- rollsLeft changed
        ' since the last poll, or the turn itself just changed (covers
        ' the server's automatic opening roll). Flicker the dice the
        ' wire's keepRoll says were rerolled before drawing the settled
        ' result; see dice.bas's animate_roll for why this same check
        ' animates both your own rolls and every other player's.
        roll_changed = 0
        IF #prev_dice_rollsleft <> 255 THEN
            IF state_rollsleft <> #prev_dice_rollsleft THEN roll_changed = 1
            IF turn_changed THEN roll_changed = 1
            IF roll_changed THEN GOSUB animate_roll
        END IF
        #prev_dice_rollsleft = state_rollsleft

        ' Out of rolls -- jump to SCORE mode automatically, like the
        ' other clients (gamelogic.c defaults cursorPos onto the
        ' highest-scoring open category the moment rollsLeft hits 0).
        ' Gated on roll_changed so this fires once, not every poll while
        ' sitting at 0 (which would otherwise fight any manual navigation
        ' the player had already done).
        IF roll_changed THEN
            IF my_turn THEN
                IF state_rollsleft = 0 THEN
                    ui_mode = 1
                    GOSUB pick_best_score
                END IF
            END IF
        END IF

        GOSUB render_playscreen

        IF my_turn THEN
            GOSUB turn_input
            IF has_action THEN poll_wait = 0 ELSE poll_wait = 20
        ELSE
            poll_wait = 20
        END IF
    END IF
    prev_active = active_player
    prev_round = #cur_round

gl_input:
    ' Page the viewed player's card with the disc when it isn't your turn
    ' (during your own turn, turn_input owns the disc for die/category
    ' selection instead). No network round-trip needed -- every seated
    ' player's record already arrived in the same poll. Reuses my_turn
    ' (computed once per successful poll, above) rather than re-testing
    ' active_player/state_viewing here -- see the comment at that
    ' computation for why chaining those DEF FNs into a multi-condition
    ' AND on one line miscompiles on this compiler.
    IF #cur_round >= 1 THEN
        IF #cur_round <= ROUND_FINAL THEN
            IF my_turn = 0 THEN
                IF view_lock > 0 THEN view_lock = view_lock - 1
                IF CONT1.RIGHT AND view_lock = 0 THEN
                    view_idx = view_idx + 1
                    IF view_idx >= #cur_pc THEN view_idx = 0
                    view_lock = 8
                    GOSUB sound_cursor
                    GOSUB render_header
                    GOSUB render_card_for_view
                ELSEIF CONT1.LEFT AND view_lock = 0 THEN
                    IF view_idx = 0 THEN view_idx = #cur_pc
                    view_idx = view_idx - 1
                    view_lock = 8
                    GOSUB sound_cursor
                    GOSUB render_header
                    GOSUB render_card_for_view
                END IF
            END IF
        END IF
    END IF

    IF CONT1.KEY = 10 THEN GOSUB ingame_menu
    IF want_leave THEN
        want_leave = 0
        GOTO table_select
    END IF
    GOTO game_loop

' ===========================================================================
' render_lobby: server name, ready list, prompt. Trigger toggles /ready.
' Uses the same 42-byte player records as play -- scores[0] doubles as the
' ready flag while round=0 (SCORE_READY/SCORE_UNREADY/SCORE_VIEWING).
' ===========================================================================
DIM #lb_pc, lb_ready
render_lobby: PROCEDURE
    #df_src = FN_RX + GAME_SERVERNAME : df_pos = screenpos(0, 0) : df_len = 20 : #df_color = COL_TEXT
    GOSUB draw_field

    #lb_pc = state_playercount
    IF #lb_pc > 8 THEN #lb_pc = 8
    FOR gs_i = 0 TO #lb_pc - 1
        #tmp_addr = player_addr(gs_i)
        pc_idx = gs_i
        GOSUB player_color
        #df_src = #tmp_addr + PL_NAME : df_pos = screenpos(0, gs_i + 2) : df_len = 9 : #df_color = #pc_color
        GOSUB draw_field
        #gs_c = 46 ' '.'
        lb_ready = score_at(#tmp_addr, 0)
        IF lb_ready = SCORE_READY THEN #gs_c = 42 ' '*'
        #BACKTAB(screenpos(10, gs_i + 2)) = (#gs_c - 32) * 8 + COL_TEXT
    NEXT gs_i

    #df_src = FN_RX + GAME_PROMPT : df_pos = STATUS_ROW : df_len = ROWCELLS : #df_color = COL_TEXT
    GOSUB draw_field

    IF CONT1.BUTTON THEN
        GOSUB sound_select
        url_path = 2 : GOSUB compose_url
        #net_readlen = GAME_MAXLEN
        GOSUB api_call
        poll_wait = 15
    END IF
END

' ===========================================================================
' render_gameover: standings (name + final total, same running-total math
' that's live during play, so it doesn't depend on the server's own
' scores[15] convention) plus the prompt naming the winner. Held on screen
' (poll_wait=60) until the server resets the table back to the lobby.
' ===========================================================================
render_gameover: PROCEDURE
    GOSUB sound_gamedone
    prl_top = 1
    GOSUB render_player_list
    #df_src = FN_RX + GAME_PROMPT : df_pos = STATUS_ROW : df_len = ROWCELLS : #df_color = COL_HILITE
    GOSUB draw_field
END

' ===========================================================================
' render_header: viewed player's name and the round counter.
' ===========================================================================
render_header: PROCEDURE
    #tmp_addr = player_addr(view_idx)
    pc_idx = view_idx
    GOSUB player_color
    #df_src = #tmp_addr + PL_NAME : df_pos = screenpos(0, 0) : df_len = 9 : #df_color = #pc_color
    GOSUB draw_field
    PRINT AT screenpos(10, 0) COLOR COL_ROUND, "R"
    PRINT AT screenpos(12, 0) COLOR COL_ROUND, <.2>#cur_round
    PRINT AT screenpos(14, 0) COLOR COL_ROUND, "/13"
    PRINT AT screenpos(18, 0) COLOR COL_TEXT, "<>"
END

' ===========================================================================
' render_card_for_view: point card.bas's render_card at the currently
' viewed player, enabling the green "potential score" hint only on your own
' card during your own turn.
' ===========================================================================
render_card_for_view: PROCEDURE
    #rc_addr = player_addr(view_idx)
    rc_own = 0
    ' Nested single-condition IFs, not a chained "A = 0 AND B = 0 AND
    ' C = 0" -- see the comment at game_loop's turn check for why that
    ' shape miscompiles to always-false on this compiler.
    IF view_idx = 0 THEN
        IF active_player = 0 THEN
            IF state_viewing = 0 THEN rc_own = 1
        END IF
    END IF
    rc_mode = ui_mode
    IF crs_idx < 6 THEN rc_selcat = crs_idx ELSE rc_selcat = crs_idx + 2
    rc_reveal = 255
    GOSUB render_card
END

' ===========================================================================
' seed_score_shadow: snapshot the current active player's scores[0..14]
' into SC_PREVSCORES. Called every poll for whoever's active right now, so
' that whenever *their* turn eventually ends, check_score_reveal has a
' valid "before" state to diff against.
' ===========================================================================
DIM #rv_addr, rv_i, #rv_new, #rv_old, rv_found, rv_cat, rv_frame
seed_score_shadow: PROCEDURE
    #rv_addr = player_addr(active_player)
    FOR rv_i = 0 TO 14
        #rv_new = score_at(#rv_addr, rv_i)
        POKE (SC_PREVSCORES + rv_i * 2), #rv_new AND 255
        POKE (SC_PREVSCORES + rv_i * 2 + 1), (#rv_new / 256) AND 255
    NEXT rv_i
END

' ===========================================================================
' check_score_reveal: called right when turn_changed detects someone other
' than you just finished their turn. Diffs their scores[] against the
' shadow captured the last time seed_score_shadow saw them become active,
' to find which single category they just filled in (skipping indices 6/7,
' the computed upper-total/bonus rows -- a player never directly picks
' those, they only change as a side effect of an upper-section pick, which
' the 0-5 scan already catches first). Shows their card with that cell
' highlighted for about 3/4 of a second before the normal turn-changed
' flow (which reassigns view_idx to whoever's active now) takes over. A
' no-op if nothing actually changed -- e.g. the departing "player" is a
' sentinel (-1, nobody), or the shadow was never seeded for them.
' ===========================================================================
check_score_reveal: PROCEDURE
    #rv_addr = player_addr(prev_active)
    rv_found = 0
    FOR rv_i = 0 TO 14
        IF rv_i <> 6 THEN
            IF rv_i <> 7 THEN
                #rv_new = score_at(#rv_addr, rv_i)
                #rv_old = (PEEK(SC_PREVSCORES + rv_i * 2 + 1) AND 255) * 256 + (PEEK(SC_PREVSCORES + rv_i * 2) AND 255)
                IF rv_found = 0 THEN
                    IF #rv_new <> #rv_old THEN
                        IF #rv_new <> SCORE_UNSET THEN
                            IF #rv_new <> SCORE_VIEWING THEN
                                rv_found = 1 : rv_cat = rv_i
                            END IF
                        END IF
                    END IF
                END IF
            END IF
        END IF
    NEXT rv_i

    IF rv_found THEN
        pc_idx = prev_active
        GOSUB player_color
        #df_src = #rv_addr + PL_NAME : df_pos = screenpos(0, 0) : df_len = 9 : #df_color = #pc_color
        GOSUB draw_field
        #rc_addr = #rv_addr
        rc_own = 0 : rc_mode = 0 : rc_selcat = 0 : rc_reveal = rv_cat
        GOSUB render_card
        GOSUB sound_score
        FOR rv_frame = 1 TO 45
            WAIT
        NEXT rv_frame
    END IF
END

' ===========================================================================
' render_playscreen: full redraw of the round 1-13 screen from whatever is
' currently sitting in FN_RX -- header, card, seat strip, dice, prompt.
' Split with WAITs between regions (render_card already breaks its own two
' columns) so one poll's redraw can't tear a frame; matches board.bas's
' per-quadrant WAIT and 5card.bas's per-seat WAIT, for the same reason
' (STIC has no page-flip; a big unbroken BACKTAB write can spill past
' vblank into active display).
' ===========================================================================
render_playscreen: PROCEDURE
    GOSUB render_header
    GOSUB render_card_for_view
    WAIT
    GOSUB render_seatstrip
    dr_mode = ui_mode : dr_cursor = dice_cur
    GOSUB draw_dice_row
    #df_src = FN_RX + GAME_PROMPT : df_pos = STATUS_ROW : df_len = ROWCELLS : #df_color = COL_TEXT
    GOSUB draw_field
END

' ===========================================================================
' pick_best_score: point crs_idx at whichever open, selectable category
' scores the most with the current (final) roll. Used when rollsLeft hits
' 0 and SCORE mode is entered automatically -- matches the reference C
' clients defaulting cursorPos onto the highest score once no rolls
' remain (gamelogic.c). Categories 0-5 map to crs_idx 0-5 directly;
' 8-14 map to crs_idx 6-12 (see render_card's/turn_input's own comments
' for that mapping). Falls back to crs_idx=0 if nothing is open at all
' (shouldn't happen mid-round, but leaves a sane cursor position either
' way).
' ===========================================================================
DIM pbs_found, #pbs_best, pbs_i, #pbs_v
pick_best_score: PROCEDURE
    pbs_found = 0
    #pbs_best = 0
    crs_idx = 0
    FOR pbs_i = 0 TO 5
        #pbs_v = valid_at(pbs_i)
        IF #pbs_v <> 255 THEN
            IF pbs_found = 0 THEN
                pbs_found = 1 : #pbs_best = #pbs_v : crs_idx = pbs_i
            ELSEIF #pbs_v > #pbs_best THEN
                #pbs_best = #pbs_v : crs_idx = pbs_i
            END IF
        END IF
    NEXT pbs_i
    FOR pbs_i = 8 TO 14
        #pbs_v = valid_at(pbs_i)
        IF #pbs_v <> 255 THEN
            IF pbs_found = 0 THEN
                pbs_found = 1 : #pbs_best = #pbs_v : crs_idx = pbs_i - 2
            ELSEIF #pbs_v > #pbs_best THEN
                #pbs_best = #pbs_v : crs_idx = pbs_i - 2
            END IF
        END IF
    NEXT pbs_i
END

' ===========================================================================
' turn_input: your turn. Blocks in its own WAIT loop (like Battleship's
' targeting) handling DICE mode (pick a die, toggle its reroll flag, submit
' a roll) and SCORE mode (pick a category, score it), switched with the
' bottom-left button. Sets has_action + score_idx/SC_KEEP and returns to
' let the outer poll loop perform the actual network call, exactly like
' Battleship's has_targeted/atk_pos handoff.
' ===========================================================================
turn_input: PROCEDURE
    inp_lock = 0
    has_action = 0
    #ti_timeleft = (PEEK(FN_RX + GAME_MOVETIME) AND 255)
    ti_framecount = 0
    ' moveTime can run up to 250 (state.bas comment), so the field needs 3
    ' digits -- see battleship.bas's targeting for why <.3> (space-padded,
    ' PRNUM16.b) is used instead of <3> (zero-padded, PRNUM16.z): .z never
    ' initializes the register that picks blank-vs-zero padding, so a
    ' shorter value can print garbage in the unused leading digit(s).
    PRINT AT STATUS_ROW + 17 COLOR COL_TEXT, <.3>#ti_timeleft

ti_loop:
    WAIT

    ti_framecount = ti_framecount + 1
    IF ti_framecount >= 60 THEN
        ti_framecount = 0
        IF #ti_timeleft > 0 THEN #ti_timeleft = #ti_timeleft - 1
        PRINT AT STATUS_ROW + 17 COLOR COL_TEXT, <.3>#ti_timeleft
        GOSUB sound_tick
        ' The server enforces its own move time limit and force-scores a
        ' player who runs out (gameLogic.go's forceHumanMove) -- without
        ' this bail, a player who never acts would stay stuck in this loop
        ' forever and never poll again to discover the turn moved on.
        IF #ti_timeleft = 0 THEN RETURN
    END IF

    IF inp_lock > 0 THEN inp_lock = inp_lock - 1 : GOTO ti_loop

    IF CONT1.KEY = 10 THEN
        GOSUB ingame_menu
        IF want_leave THEN RETURN
        GOTO ti_loop
    END IF
    IF CONT1.KEY = 11 THEN
        GOSUB show_standings
        GOSUB render_card_for_view
        GOTO ti_loop
    END IF

    IF ui_mode = 0 THEN
        ' DICE mode. B1/B2/UP are checked *before* BUTTON deliberately:
        ' the Intellivision controller's three action-button signals share
        ' overlapping bits (constants.bas's BUTTON_MASK = BUTTON_1 OR
        ' BUTTON_2 OR BUTTON_3), so CONT1.BUTTON reads non-zero for *any*
        ' of the three side buttons, not just the top one. Checking it
        ' first meant every button press -- including B1 and B2 -- fell
        ' into the "toggle hold" branch and B1/B2 were never reached.
        ' Battleship's handle_placement uses this same before-BUTTON
        ' ordering for CONT1.B1 for the identical reason.
        ' dice_cur ranges 0-5: 0 is the on-screen ROLL tile (drawn at
        ' col 0 by draw_dice_row), 1-5 are dice 0-4 -- matching the
        ' reference clients' own cursorPos convention (0=roll, 1-5=dice),
        ' rather than a dedicated controller button for rolling.
        IF CONT1.RIGHT THEN
            dice_cur = (dice_cur + 1) % 6
            inp_lock = 8 : GOSUB sound_cursor
            dr_mode = ui_mode : dr_cursor = dice_cur : GOSUB draw_dice_row
            GOTO ti_loop
        END IF
        IF CONT1.LEFT THEN
            dice_cur = (dice_cur + 5) % 6
            inp_lock = 8 : GOSUB sound_cursor
            dr_mode = ui_mode : dr_cursor = dice_cur : GOSUB draw_dice_row
            GOTO ti_loop
        END IF
        IF CONT1.UP OR CONT1.B1 THEN
            ' Move from the dice row up into the scorecard -- your current
            ' roll's potential scores are already shown in green there
            ' (render_card_for_view/draw_cat_cell), so this is how you
            ' "bank" a roll instead of rolling again.
            ui_mode = 1
            inp_lock = 10 : GOSUB sound_select
            dr_mode = ui_mode : dr_cursor = dice_cur : GOSUB draw_dice_row
            GOSUB render_card_for_view
            GOTO ti_loop
        END IF
        IF CONT1.BUTTON THEN
            IF dice_cur = 0 THEN
                ' On the ROLL tile -- submit. Rejected (sound_invalid,
                ' stay put) if there are no rolls left, or if every die is
                ' marked KEEP (mask='0') so nothing would actually
                ' reroll. The untouched default (every die still
                ' '1'=reroll) is itself a valid "reroll all 5" submission.
                IF state_rollsleft = 0 THEN
                    GOSUB sound_invalid
                    GOTO ti_loop
                END IF
                ti_allkept = 1
                FOR pt_i = 0 TO 4
                    IF (PEEK(SC_KEEP + pt_i) AND 255) = 49 THEN ti_allkept = 0
                NEXT pt_i
                IF ti_allkept THEN
                    GOSUB sound_invalid
                    GOTO ti_loop
                END IF
                GOSUB sound_roll
                has_action = 2
                RETURN
            ELSE
                ' On a die -- toggle it between its default (reroll, '1')
                ' and kept ('0').
                pt_i = dice_cur - 1
                IF (PEEK(SC_KEEP + pt_i) AND 255) = 49 THEN
                    POKE (SC_KEEP + pt_i), 48
                ELSE
                    POKE (SC_KEEP + pt_i), 49
                END IF
                GOSUB sound_hold
                dr_mode = ui_mode : dr_cursor = dice_cur : GOSUB draw_dice_row
                inp_lock = 8
                GOTO ti_loop
            END IF
        END IF
    ELSE
        ' SCORE mode.
        IF CONT1.DOWN THEN
            ' Pressing down from the bottom row of either column drops
            ' back to DICE mode instead of wrapping to the top -- unless
            ' there are no rolls left, in which case DICE mode has
            ' nothing to do (matches the B1 guard just above/below).
            at_bottom_row = 0
            IF crs_idx = 5 THEN at_bottom_row = 1
            IF crs_idx = 12 THEN at_bottom_row = 1
            IF at_bottom_row THEN
                IF state_rollsleft <> 0 THEN
                    ui_mode = 0
                    inp_lock = 10 : GOSUB sound_select
                    dr_mode = ui_mode : dr_cursor = dice_cur : GOSUB draw_dice_row
                    GOSUB render_card_for_view
                    GOTO ti_loop
                END IF
            END IF
            IF crs_idx < 6 THEN crs_idx = (crs_idx + 1) % 6 ELSE crs_idx = 6 + ((crs_idx - 6 + 1) % 7)
            inp_lock = 8 : GOSUB sound_cursor : GOSUB render_card_for_view
            GOTO ti_loop
        END IF
        IF CONT1.UP THEN
            IF crs_idx < 6 THEN crs_idx = (crs_idx + 5) % 6 ELSE crs_idx = 6 + ((crs_idx - 6 + 6) % 7)
            inp_lock = 8 : GOSUB sound_cursor : GOSUB render_card_for_view
            GOTO ti_loop
        END IF
        IF CONT1.RIGHT AND crs_idx < 6 THEN
            pt_i = crs_idx : IF pt_i > 6 THEN pt_i = 6
            crs_idx = 6 + pt_i
            inp_lock = 8 : GOSUB sound_cursor : GOSUB render_card_for_view
            GOTO ti_loop
        END IF
        IF CONT1.LEFT AND crs_idx >= 6 THEN
            pt_i = crs_idx - 6 : IF pt_i > 5 THEN pt_i = 5
            crs_idx = pt_i
            inp_lock = 8 : GOSUB sound_cursor : GOSUB render_card_for_view
            GOTO ti_loop
        END IF
        IF CONT1.B1 THEN
            ' No rolls left means DICE mode has nothing to do (B2 there
            ' would just reject every attempt) -- stay in SCORE mode
            ' instead of bouncing back to a dead end.
            IF state_rollsleft = 0 THEN
                GOSUB sound_invalid
                GOTO ti_loop
            END IF
            ui_mode = 0
            inp_lock = 10 : GOSUB sound_select
            dr_mode = ui_mode : dr_cursor = dice_cur : GOSUB draw_dice_row
            GOSUB render_card_for_view
            GOTO ti_loop
        END IF
        IF CONT1.BUTTON THEN
            IF crs_idx < 6 THEN score_idx = crs_idx ELSE score_idx = crs_idx + 2
            IF valid_at(score_idx) = 255 THEN
                GOSUB sound_invalid
                GOTO ti_loop
            END IF
            score_is_fujitzee = 0
            IF score_idx = SCORE_FUJITZEE THEN
                IF valid_at(score_idx) > 0 THEN score_is_fujitzee = 1
            END IF
            IF score_is_fujitzee THEN
                GOSUB sound_fujitzee
            ELSE
                GOSUB sound_score
            END IF
            has_action = 3
            RETURN
        END IF
    END IF
    GOTO ti_loop
END

' The compiled program overflows IntyBASIC's default $5000-$6FFF
' (8192-word) window -- the compiler happily keeps allocating past $6FFF,
' but $7000 is not in the manual's list of ranges "usable without
' additional programming" on modern flash cart/homebrew PCBs (that list
' jumps from $6FFF to $A000). This ORG was originally placed just before
' halt:, at the very end of the file -- which put it *after*
' name_entry_screen, so name_entry_screen's own tail end (its "NAME NOT
' SAVED" error path) still spilled about 20 words into that unsafe $7000
' gap (confirmed in the .lst: code was landing at $7000-$7013). Moving the
' ORG here, ahead of both ingame_menu and name_entry_screen, pushes that
' whole "cold" tail (menu, name entry) into $D000+ instead, closing the
' gap entirely. This matters beyond spec-purity: FujiNet GO's boot loader
' hung on mount with the previous placement, consistent with $7000 not
' being safely mapped as ROM on at least one real target this ships to,
' even though jzIntv's emulation is permissive enough not to visibly
' choke on it. Relocating everything from here to halt: into $D000-$FFFF
' keeps the whole ROM inside the address ranges the manual documents as
' safe. Cross-segment GOSUB/GOTO compiles to ordinary absolute CP-1610
' jumps/calls, so this is a bookkeeping split, not a correctness one.
    ASM ORG $D000

' ---------------------------------------------------------------------------
' split_room_url / write_room_appkey / clear_room_appkey: lobby room-
' appkey handling for the intv<->lobby handoff. Placed here (past the
' ORG $D000 split above) rather than back up near compose_url where they
' were first written -- they're only ever called from boot, table-select,
' and ingame_menu, none of which are the hot per-frame game_loop path, so
' like ingame_menu/name_entry_screen below they belong in the "cold" tail.
' Adding them before the split pushed the $5000-$6FFF segment over its
' 8192-word budget and spilled ~200 words into the unsafe $7000-$7FFF
' gap, which is exactly the "hung on mount" failure mode described above
' -- moving them here is the fix. Cross-segment GOSUB/GOTO from boot_start
' and table_select back up before the split compiles to ordinary absolute
' jumps, so this is bookkeeping only, not a correctness change.
' ---------------------------------------------------------------------------
' split_room_url: given a lobby-supplied "https://host/?table=xyz" value
' already sitting in SC_ENDPT with its length in fn_len (as left by
' appkey_read), split it into the bare endpoint (SC_ENDPT, truncated at
' the '?') and the table id (SC_TABLE). Mirrors the C clients'
' welcomeActionVerifyServerDetails() '?' scan. Leaves SC_TABLE empty (a
' leading NUL) if there's no '?', the query isn't "table=...", or the id
' contains anything other than A-Z/a-z/0-9 -- it goes straight into a
' rebuilt query string unescaped, same reasoning as the username check
' above.
split_room_url: PROCEDURE
    POKE SC_TABLE, 0

    sp_found = 255 ' sentinel: not found
    sp_i = 0
    WHILE sp_i < fn_len
        IF (PEEK(SC_ENDPT + sp_i) AND 255) = 63 THEN ' '?'
            sp_found = sp_i
            EXIT WHILE
        END IF
        sp_i = sp_i + 1
    WEND
    IF sp_found = 255 THEN RETURN

    ' Truncate the endpoint at the '?' regardless of what follows.
    POKE (SC_ENDPT + sp_found), 0

    ' Require "table=" (6 bytes) right after the '?'.
    sp_ok = 0
    IF sp_found + 7 <= fn_len THEN
        sp_ok = 1
        IF (PEEK(SC_ENDPT + sp_found + 1) AND 255) <> 116 THEN sp_ok = 0 ' t
        IF (PEEK(SC_ENDPT + sp_found + 2) AND 255) <> 97  THEN sp_ok = 0 ' a
        IF (PEEK(SC_ENDPT + sp_found + 3) AND 255) <> 98  THEN sp_ok = 0 ' b
        IF (PEEK(SC_ENDPT + sp_found + 4) AND 255) <> 108 THEN sp_ok = 0 ' l
        IF (PEEK(SC_ENDPT + sp_found + 5) AND 255) <> 101 THEN sp_ok = 0 ' e
        IF (PEEK(SC_ENDPT + sp_found + 6) AND 255) <> 61  THEN sp_ok = 0 ' =
    END IF
    IF sp_ok = 0 THEN RETURN

    ' Copy the id: up to 8 bytes, stopping at NUL or '&'.
    sp_j = sp_found + 7
    sp_k = 0
    WHILE sp_k < 8 AND sp_j < fn_len
        sp_c = PEEK(SC_ENDPT + sp_j) AND 255
        IF sp_c = 0 OR sp_c = 38 THEN EXIT WHILE ' NUL or '&'
        POKE (SC_TABLE + sp_k), sp_c
        sp_k = sp_k + 1
        sp_j = sp_j + 1
    WEND
    POKE (SC_TABLE + sp_k), 0

    ' Validate: A-Z/a-z/0-9 only.
    sp_valid = 1
    FOR sp_m = 0 TO sp_k - 1
        sp_c = PEEK(SC_TABLE + sp_m) AND 255
        IF (sp_c < 65 OR sp_c > 90) AND (sp_c < 97 OR sp_c > 122) AND (sp_c < 48 OR sp_c > 57) THEN sp_valid = 0
    NEXT sp_m
    IF sp_valid = 0 THEN POKE SC_TABLE, 0
END

' write_room_appkey: persist SC_ENDPT + "?table=" + SC_TABLE back to the
' lobby server appkey slot, so a reboot without going back through the
' lobby rejoins the same room (mirrors the C clients' "Update server app
' key in case of reboot"). Builds the payload directly in FN_TX and writes
' it from there -- appkey_write's byte-by-byte copy from #fn_src into
' FN_TX is a safe no-op when #fn_src is FN_TX itself.
write_room_appkey: PROCEDURE
    #fn_txlen = 0
    #fn_src = SC_ENDPT : ls_max = 65 : GOSUB fn_strlen : GOSUB fn_putstr
    #fn_src = VARPTR lit_qtable(0) : fn_len = 7 : GOSUB fn_putstr
    #fn_src = SC_TABLE : ls_max = 9 : GOSUB fn_strlen : GOSUB fn_putstr

    ak_creator_lo = 1 : ak_creator_hi = 0 : ak_app = 1
    ak_key = AK_LOBBY_KEY_SERVER : ak_mode = 1
    GOSUB appkey_open
    IF fn_ok THEN
        fn_len = #fn_txlen : #fn_src = FN_TX
        GOSUB appkey_write
        GOSUB appkey_close
    END IF
END

' clear_room_appkey: blank the lobby server appkey slot on a deliberate
' leave, so a later reboot lands on table select instead of silently
' rejoining a table the player just quit.
clear_room_appkey: PROCEDURE
    ak_creator_lo = 1 : ak_creator_hi = 0 : ak_app = 1
    ak_key = AK_LOBBY_KEY_SERVER : ak_mode = 1
    GOSUB appkey_open
    IF fn_ok THEN
        fn_len = 0 : #fn_src = FN_TX
        GOSUB appkey_write
        GOSUB appkey_close
    END IF
    POKE SC_TABLE, 0
END

' ===========================================================================
' ingame_menu: keypad CLEAR overlay, drawn over the prompt row and the two
' rows above it. Disc up/down to choose, action button to confirm, Clear
' again cancels straight back to RESUME.
' ===========================================================================
ingame_menu: PROCEDURE
    im_sel = 0
    inp_lock = 0
    ' Wait for the CLEAR press that opened the menu to release before
    ' accepting any input. Without this, the same still-held key
    ' immediately satisfies "IF CONT1.KEY = 10 THEN GOTO im_done" below on
    ' the very first frame, closing the menu the instant it opens -- the
    ' manual's own advice ("it's suggested to wait for CONT1.KEY to
    ' contain 12 before waiting for a key") for exactly this reason.
im_wait_release:
    WAIT
    IF CONT1.KEY <> 12 THEN GOTO im_wait_release

im_loop:
    PRINT AT STATUS_ROW - 40 COLOR COL_TEXT, "                    "
    PRINT AT STATUS_ROW - 20 COLOR COL_TEXT, "                    "
    PRINT AT STATUS_ROW COLOR COL_TEXT, "                    "
    PRINT AT STATUS_ROW - 40 COLOR COL_TEXT, "TABLE MENU"
    #gs_c = COL_TEXT
    IF im_sel = 0 THEN #gs_c = COL_HILITE
    PRINT AT STATUS_ROW - 20 COLOR #gs_c, "RESUME"
    #gs_c = COL_TEXT
    IF im_sel = 1 THEN #gs_c = COL_HILITE
    PRINT AT STATUS_ROW COLOR #gs_c, "QUIT TABLE"

    WAIT
    IF inp_lock > 0 THEN inp_lock = inp_lock - 1 : GOTO im_loop

    IF CONT1.UP OR CONT1.DOWN THEN
        im_sel = 1 - im_sel
        inp_lock = 10
        GOSUB sound_cursor
        GOTO im_loop
    END IF
    IF CONT1.KEY = 10 THEN GOTO im_done
    IF CONT1.BUTTON = 0 THEN GOTO im_loop
    GOSUB sound_select

    IF im_sel = 1 THEN
        url_path = 5 : GOSUB compose_url
        #net_readlen = 8
        GOSUB api_call
        GOSUB clear_room_appkey
        want_leave = 1
    END IF
im_done:
    prev_round = 255 ' safety net, in case some other path still relies on it
    ' Redraw the whole screen immediately from whatever's already cached
    ' in FN_RX -- not just next poll. ingame_menu is called both from
    ' gl_input (outer loop) and from turn_input's own blocking ti_loop;
    ' in the latter case, control doesn't return to game_loop's own
    ' CLS/redraw dispatch until the current turn ends, which could be a
    ' long time away, so the menu's overlay (rows 9-11) would otherwise
    ' just sit there behind whatever turn_input draws around it next.
    IF want_leave = 0 THEN
        GOSUB cls_blue
        IF #cur_round = ROUND_LOBBY THEN
            GOSUB render_lobby
        ELSEIF #cur_round = ROUND_GAMEOVER THEN
            GOSUB render_gameover
        ELSE
            GOSUB card_init
            GOSUB render_playscreen
        END IF
    END IF
END

' ===========================================================================
' name_entry_screen: disc letter picker, max 8 chars. Disc up/down cycles
' the character under the cursor through A-Z, 0-9, space; left/right moves
' the cursor; the action button accepts (at least 1 non-space char).
' Adapted from fujinet-battleship/intv/battleship.bas, verbatim apart from
' colors.
' ===========================================================================
name_entry_screen: PROCEDURE
    GOSUB cls_blue
    PRINT AT 0 COLOR COL_TEXT, "ENTER YOUR NAME"
    FOR ne_i = 0 TO 7
        ne_buf(ne_i) = 36 ' space
    NEXT ne_i
    ne_cur = 0
    inp_lock = 0

ne_loop:
    FOR ne_i = 0 TO 7
        #gs_c = COL_TEXT
        IF ne_i = ne_cur THEN #gs_c = COL_HILITE
        ne_j = ne_buf(ne_i)
        IF ne_j < 26 THEN
            gs_j = 65 + ne_j
        ELSEIF ne_j < 36 THEN
            gs_j = 48 + ne_j - 26
        ELSE
            gs_j = 95 ' underscore stands in for a visible blank
        END IF
        #BACKTAB(60 + 6 + ne_i) = (gs_j - 32) * 8 + #gs_c
    NEXT ne_i

    WAIT
    IF inp_lock > 0 THEN inp_lock = inp_lock - 1 : GOTO ne_loop

    IF CONT1.RIGHT THEN
        ne_cur = ne_cur + 1
        IF ne_cur > 7 THEN ne_cur = 0
        inp_lock = 8
        GOSUB sound_cursor
        GOTO ne_loop
    END IF
    IF CONT1.LEFT THEN
        IF ne_cur = 0 THEN ne_cur = 8
        ne_cur = ne_cur - 1
        inp_lock = 8
        GOSUB sound_cursor
        GOTO ne_loop
    END IF
    IF CONT1.UP THEN
        ne_buf(ne_cur) = ne_buf(ne_cur) + 1
        IF ne_buf(ne_cur) > 36 THEN ne_buf(ne_cur) = 0
        inp_lock = 6
        GOSUB sound_cursor
        GOTO ne_loop
    END IF
    IF CONT1.DOWN THEN
        IF ne_buf(ne_cur) = 0 THEN ne_buf(ne_cur) = 37
        ne_buf(ne_cur) = ne_buf(ne_cur) - 1
        inp_lock = 6
        GOSUB sound_cursor
        GOTO ne_loop
    END IF
    IF CONT1.BUTTON = 0 THEN GOTO ne_loop
    GOSUB sound_select

    ne_len = 8
    WHILE ne_len > 0 AND ne_buf(ne_len - 1) = 36
        ne_len = ne_len - 1
    WEND
    IF ne_len = 0 THEN GOTO ne_loop

    FOR ne_i = 0 TO ne_len - 1
        ne_j = ne_buf(ne_i)
        IF ne_j < 26 THEN
            gs_j = 65 + ne_j
        ELSE
            gs_j = 48 + ne_j - 26
        END IF
        POKE (SC_NAME + ne_i), gs_j
    NEXT ne_i
    POKE (SC_NAME + ne_len), 0

    ak_creator_lo = 1 : ak_creator_hi = 0 : ak_app = 1 : ak_key = 0 : ak_mode = 1
    GOSUB appkey_open
    IF fn_ok THEN
        #fn_src = SC_NAME : fn_len = ne_len
        GOSUB appkey_write
        IF fn_ok = 0 THEN
            PRINT AT 100 COLOR COL_TEXT, "NAME NOT SAVED FOR "
            PRINT AT 120 COLOR COL_TEXT, "NEXT TIME           "
            inp_lock = 90
            WHILE inp_lock > 0
                inp_lock = inp_lock - 1
                WAIT
            WEND
        END IF
        GOSUB appkey_close
    END IF
END

halt:
    WAIT
    GOTO halt
