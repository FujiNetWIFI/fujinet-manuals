' battleship.bas -- FujiNet Battleship for Intellivision, entry point +
' state machine. Follows the pattern established by fujinet-5cardstud/intv/
' 5card.bas (name entry -> table select -> game loop -> in-game menu), but
' the board itself is rendered with board.bas's colored-squares kernel
' instead of GRAM card art, since four 10x10 grids need to be on screen at
' once (Battleship's core multiplayer rule is that one shot hits every
' opposing board simultaneously).
'
' GOTO boot_start jumps over every INCLUDE below before any of it runs --
' see fujinet.bas/5card.bas for why: falling into a PROCEDURE or DATA block
' by straight-line execution corrupts the return stack.
    GOTO boot_start

    INCLUDE "constants.bas"
    INCLUDE "fujinet.bas"
    INCLUDE "state.bas"
    INCLUDE "board.bas"
    INCLUDE "sound.bas"

    CONST ROWCELLS = 20
    CONST STATUS_ROW = 220     ' row 11 (screenpos(0,11))
    CONST PANEL_COL = 11       ' right-hand chrome panel starts at column 11

    CONST COL_TEXT   = CS_WHITE
    CONST COL_HILITE = CS_YELLOW

' Scratch RAM, ours, below fujinet.bas's own SC_* buffers (which stop at
' SC_QUERY $9150 + 48 = $9180) and well below the $9C00 mailbox.
    CONST SC_TABLE      = $9180 ' selected table id, 9 bytes (8 + NUL)
    CONST SC_MYSHIPS    = $9190 ' our 5 placed ship values (cell+100*dir), 1 byte each
    CONST SC_OCCUPY     = $91A0 ' 100 bytes, placement-time occupancy map (0/1)
    CONST SC_PREVFIELD  = $9200 ' 4 x 100 bytes, shadow gamefields for diffing

' ---------------------------------------------------------------------------
' URL literals (ASCII DATA). url_path selects the endpoint:
'   0 tables   1 state   2 ready   3 place   4 attack   5 leave
' ---------------------------------------------------------------------------
lit_n_colon: DATA 78,58
lit_https: DATA 104,116,116,112,115,58,47,47,98,97,116,116,108,101,115,104,105,112,46,99,97,114,114,45,100,101,115,105,103,110,115,46,99,111,109,47
lit_tables: DATA 116,97,98,108,101,115
lit_qbin: DATA 63,98,105,110,61,49
lit_state: DATA 115,116,97,116,101
lit_ready: DATA 114,101,97,100,121
lit_place: DATA 112,108,97,99,101,47
lit_attack: DATA 97,116,116,97,99,107,47
lit_leave: DATA 108,101,97,118,101
lit_qtable: DATA 63,116,97,98,108,101,61
lit_aplayer: DATA 38,112,108,97,121,101,114,61
lit_abinv2: DATA 38,98,105,110,61,49,38,118,61,50
lit_comma: DATA 44

    CONST LEN_HTTPS = 36

    ' Lobby appkey: creator 1 / app 1, key = this game's registered slot.
    ' See fujinet-battleship/src/misc.h AK_LOBBY_KEY_SERVER.
    CONST AK_LOBBY_KEY_SERVER = 5

' ---------------------------------------------------------------------------
' Globals
' ---------------------------------------------------------------------------
    DIM gs_i, gs_j, gs_char, #gs_c
    DIM ne_i, ne_j, ne_cur, ne_len
    DIM ne_buf(8)
    DIM ak_try
    DIM tbl_count, tbl_sel
    DIM inp_lock
    DIM want_leave, im_sel
    DIM url_path
    DIM #tmp_addr, #tmp_field

    DIM df_pos, df_len, #df_color, df_i, df_c, df_stop
    DIM #df_src

    ' split_room_url locals (see procedure below)
    DIM sp_i, sp_found, sp_ok, sp_j, sp_k, sp_c, sp_valid, sp_m

    DIM cu_i
    DIM pn_val, pn_h, pn_t, pn_o, pn_started

    DIM cur_status, cur_pc, cur_pstatus, prev_status, ships_drawn, has_action
    DIM atk_pos, has_targeted
    DIM prev_seen_pc, prev_result_status, prev_result_pos, rb_lastattack

    DIM pc_x, pc_y, pc_dir, pc_size, pc_i, pc_ok, pc_moved
    DIM pc_prevx, pc_prevy, pc_prevdir, pc_cx, pc_cy, pc_mx, pc_my
    DIM ship_idx, ph_shipnum

    DIM rb_i, rb_j, rb_c, rb_state, rb_pstatus, rb_ch
    DIM #rb_field
    DIM rb_ship, rb_sx, rb_sy, rb_sdir, rb_ssize
    DIM ds_bq, ds_base, ds_color

    DIM tg_x, tg_y, tg_newx, tg_newy, tg_moved, tg_timeleft, tg_framecount
    DIM tc_q, tc_state, tc_color, tc_field

' ---------------------------------------------------------------------------
' draw_field: render df_len ASCII bytes from #df_src onto the screen at
' BACKTAB offset df_pos, in color #df_color. MODE 0 gives full GROM (cards
' 0-255), so unlike 5cardstud's MODE 1 client, lowercase is available --
' server prompts/names arrive lowercased and are shown as-is. Stops at a
' NUL and pads the rest of the field with spaces; clamps anything outside
' the printable range to a space rather than drawing garbage.
' ---------------------------------------------------------------------------
draw_field: PROCEDURE
    df_stop = 0
    FOR df_i = 0 TO df_len - 1
        df_c = PEEK(#df_src + df_i) AND 255
        IF df_c = 0 THEN df_stop = 1
        IF df_stop THEN df_c = 32
        IF df_c < 32 OR df_c > 127 THEN df_c = 32
        #BACKTAB(df_pos + df_i) = (df_c - 32) * 8 + #df_color
    NEXT df_i
END

' ---------------------------------------------------------------------------
' fn_putnum: append the decimal (no leading zeros) representation of pn_val
' (0-999) into FN_TX at the current #fn_txlen. IntyBASIC has no built-in
' itoa; placement values run 0-199 and attack positions 0-99, so three
' digits is generous headroom.
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
' compose_url: build "N:<endpoint><path...><suffix>" directly into FN_TX.
' For url_path=3 (place), SC_MYSHIPS's 5 bytes are comma-joined. For
' url_path=4 (attack), atk_pos is appended. Always requests &bin=1&v=2 --
' v=1 omits the winner's ships and forces activePlayer=-1 at game over,
' both of which render_gameover needs.
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
            #fn_src = VARPTR lit_place(0) : fn_len = 6 : GOSUB fn_putstr
            FOR cu_i = 0 TO 4
                pn_val = PEEK(SC_MYSHIPS + cu_i) AND 255
                GOSUB fn_putnum
                IF cu_i < 4 THEN
                    #fn_src = VARPTR lit_comma(0) : fn_len = 1 : GOSUB fn_putstr
                END IF
            NEXT cu_i
        ELSEIF url_path = 4 THEN
            #fn_src = VARPTR lit_attack(0) : fn_len = 7 : GOSUB fn_putstr
            pn_val = atk_pos
            GOSUB fn_putnum
        ELSE
            #fn_src = VARPTR lit_leave(0) : fn_len = 5 : GOSUB fn_putstr
        END IF

        #fn_src = VARPTR lit_qtable(0) : fn_len = 7 : GOSUB fn_putstr
        #fn_src = SC_TABLE : ls_max = 9 : GOSUB fn_strlen : GOSUB fn_putstr
        #fn_src = VARPTR lit_aplayer(0) : fn_len = 8 : GOSUB fn_putstr
        #fn_src = SC_NAME : ls_max = 9 : GOSUB fn_strlen : GOSUB fn_putstr
        #fn_src = VARPTR lit_abinv2(0) : fn_len = 10 : GOSUB fn_putstr
    END IF
END

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
' ---------------------------------------------------------------------------
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

' ---------------------------------------------------------------------------
' write_room_appkey: persist SC_ENDPT + "?table=" + SC_TABLE back to the
' lobby server appkey slot, so a reboot without going back through the
' lobby rejoins the same room (mirrors the C clients' "Update server app
' key in case of reboot"). Builds the payload directly in FN_TX and writes
' it from there -- appkey_write's byte-by-byte copy from #fn_src into
' FN_TX is a safe no-op when #fn_src is FN_TX itself.
' ---------------------------------------------------------------------------
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

' ---------------------------------------------------------------------------
' clear_room_appkey: blank the lobby server appkey slot on a deliberate
' leave, so a later reboot lands on table select instead of silently
' rejoining a table the player just quit.
' ---------------------------------------------------------------------------
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
' Boot
' ===========================================================================
boot_start:
    MODE 0, CS_BLACK, CS_BLACK, CS_BLACK, CS_BLACK : WAIT
    CLS
    PRINT AT 0 COLOR COL_TEXT, "BATTLESHIP"
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
                gs_char = PEEK(SC_NAME + gs_j) AND 255
                IF gs_char >= 97 AND gs_char <= 122 THEN gs_char = gs_char - 32
                IF (gs_char < 65 OR gs_char > 90) AND (gs_char < 48 OR gs_char > 57) THEN gs_i = 0
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
    CLS
    PRINT AT 0 COLOR COL_TEXT, "CHOOSE A TABLE"
    PRINT AT 40, "REFRESHING..."

    url_path = 0 : GOSUB compose_url
    #net_readlen = TABLES_MAXLEN
    GOSUB api_call

    IF fn_ok = 1 THEN
        #tmp_field = 1 + (PEEK(FN_RX) AND 255) * TABLE_STRIDE
        IF #net_gotlen < #tmp_field THEN fn_ok = 0
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

    tbl_count = PEEK(FN_RX) AND 255
    IF tbl_count > 8 THEN tbl_count = 8
    IF tbl_count = 0 THEN
        PRINT AT 40, "NO TABLES AVAILABLE "
        inp_lock = 90
        WHILE inp_lock > 0
            inp_lock = inp_lock - 1
            WAIT
        WEND
        GOTO table_select
    END IF

    CLS
    PRINT AT 0 COLOR COL_TEXT, "CHOOSE A TABLE"
    FOR gs_i = 0 TO tbl_count - 1
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
    FOR gs_i = 0 TO tbl_count - 1
        #gs_c = COL_TEXT
        IF gs_i = tbl_sel THEN #gs_c = COL_HILITE
        #BACKTAB(20 + gs_i * 20) = (62 - 32) * 8 + #gs_c ' '>' cursor glyph
    NEXT gs_i

    IF inp_lock > 0 THEN inp_lock = inp_lock - 1 : GOTO ts_input

    IF CONT1.DOWN THEN
        tbl_sel = tbl_sel + 1
        IF tbl_sel >= tbl_count THEN tbl_sel = 0
        inp_lock = 8
        GOSUB sound_cursor
        GOTO ts_input
    END IF
    IF CONT1.UP THEN
        IF tbl_sel = 0 THEN tbl_sel = tbl_count
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
' In a table: poll /state (or submit a pending ready/place/attack action in
' its place) and dispatch on status. A full CLS + board_init happens only
' on the transition out of the lobby (or on first entry) -- every other
' poll updates in place, matching the differential-render approach 5 Card
' Stud settled on for the same reason (IntyBASIC/the STIC have no true
' page-flip; a per-poll CLS would visibly blank the screen every ~1s).
' ===========================================================================
    prev_status = 255 ' sentinel: forces the initial CLS/board_init
    prev_seen_pc = 255 ' sentinel: skip the join/leave cue on the first poll
    prev_result_status = 255
    prev_result_pos = 255
    poll_wait = 0
    want_leave = 0
    has_action = 0
    GOSUB sound_join

tl_loop:
    WAIT

    IF poll_wait > 0 THEN
        poll_wait = poll_wait - 1
        GOTO tl_input
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
        GOTO tl_input
    END IF

    cur_status = state_status
    cur_pc = state_playercount
    cur_pstatus = state_playerstatus

    IF prev_seen_pc <> 255 THEN
        IF cur_pc > prev_seen_pc THEN GOSUB sound_player_join
        IF cur_pc < prev_seen_pc THEN GOSUB sound_player_left
    END IF
    prev_seen_pc = cur_pc

    IF cur_status = STATUS_LOBBY THEN
        IF prev_status <> STATUS_LOBBY THEN CLS
        GOSUB render_lobby
        poll_wait = 45
    ELSEIF cur_status = STATUS_GAMEOVER THEN
        IF prev_status = STATUS_LOBBY OR prev_status = 255 THEN
            CLS
            GOSUB board_init
        END IF
        IF prev_status <> STATUS_GAMEOVER THEN GOSUB render_gameover
        poll_wait = 60
    ELSE
        ' STATUS_PLACE_SHIPS, GAMESTART, MISS, HIT, SUNK.
        IF prev_status = STATUS_LOBBY OR prev_status = 255 THEN
            CLS
            GOSUB board_init
            ships_drawn = 0
        END IF

        IF cur_status = STATUS_PLACE_SHIPS THEN
            IF cur_pstatus = PSTATUS_PLACE_SHIPS THEN
                GOSUB handle_placement
                has_action = 2
                poll_wait = 0
            ELSE
                #df_src = FN_RX + GAME_PROMPT : df_pos = STATUS_ROW : df_len = ROWCELLS : #df_color = COL_TEXT
                GOSUB draw_field
                poll_wait = 30
            END IF
        ELSE
            GOSUB render_game_board
            GOSUB render_panel
            #df_src = FN_RX + GAME_PROMPT : df_pos = STATUS_ROW : df_len = ROWCELLS : #df_color = COL_TEXT
            GOSUB draw_field

            ' status (MISS/HIT/SUNK) reflects the *last* attack's result and
            ' can legitimately repeat across several polls if no one has
            ' fired since -- pair it with lastAttackPos so the sound plays
            ' exactly once per real event, not once per poll it's visible.
            IF cur_status = STATUS_MISS OR cur_status = STATUS_HIT OR cur_status = STATUS_SUNK THEN
                rb_lastattack = PEEK(FN_RX + GAME_LASTATTACK) AND 255
                IF cur_status <> prev_result_status OR rb_lastattack <> prev_result_pos THEN
                    IF cur_status = STATUS_MISS THEN
                        GOSUB sound_miss
                    ELSEIF cur_status = STATUS_HIT THEN
                        GOSUB sound_hit
                    ELSE
                        GOSUB sound_sink
                    END IF
                    prev_result_status = cur_status
                    prev_result_pos = rb_lastattack
                END IF
            END IF

            IF active_player = 0 AND cur_pstatus = PSTATUS_PLAYING THEN
                GOSUB targeting
                IF has_targeted THEN
                    GOSUB sound_myturn
                    has_action = 3
                    poll_wait = 0
                ELSE
                    poll_wait = 20
                END IF
            ELSE
                poll_wait = 20
            END IF
        END IF
    END IF

    prev_status = cur_status

tl_input:
    IF CONT1.KEY = 10 THEN GOSUB ingame_menu
    IF want_leave THEN
        want_leave = 0
        GOTO table_select
    END IF
    GOTO tl_loop

' ===========================================================================
' render_lobby: server name, ready list, prompt. Trigger toggles /ready.
' ===========================================================================
render_lobby: PROCEDURE
    #df_src = FN_RX + LOBBY_SERVERNAME : df_pos = 20 : df_len = 20 : #df_color = COL_TEXT
    GOSUB draw_field
    FOR gs_i = 0 TO cur_pc - 1
        #tmp_addr = lobby_player_addr(gs_i)
        #df_src = #tmp_addr + LP_NAME : df_pos = 60 + gs_i * 20 : df_len = 9 : #df_color = COL_TEXT
        GOSUB draw_field
        #gs_c = 46 ' '.'
        IF (PEEK(#tmp_addr + LP_READY) AND 255) <> 0 THEN #gs_c = 42 ' '*'
        #BACKTAB(60 + gs_i * 20 + 10) = (#gs_c - 32) * 8 + COL_TEXT
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
' render_gameover: reveal the winner's ships (myShips[5..9]) on their
' quadrant, show the prompt. Held on screen (poll_wait=60) until the server
' resets the table back to the lobby.
' ===========================================================================
render_gameover: PROCEDURE
    GOSUB sound_gamedone
    IF active_player >= 0 AND active_player <= 3 THEN
        ds_bq = active_player : ds_base = GAME_MYSHIPS + 5 : ds_color = BCOL_SUNKSHIP
        GOSUB draw_ship_set
    END IF
    #df_src = FN_RX + GAME_PROMPT : df_pos = STATUS_ROW : df_len = ROWCELLS : #df_color = COL_HILITE
    GOSUB draw_field
END

' ---------------------------------------------------------------------------
' draw_ship_set: paint the 5 ships encoded at FN_RX+ds_base (each byte
' cell+100*dir, state.bas's myShips layout) onto quadrant ds_bq in colour
' ds_color. Shared by render_game_board (own ships, ds_base=GAME_MYSHIPS)
' and render_gameover (winner's ships, ds_base=GAME_MYSHIPS+5).
' ---------------------------------------------------------------------------
draw_ship_set: PROCEDURE
    FOR rb_i = 0 TO 4
        rb_ship = PEEK(FN_RX + ds_base + rb_i) AND 255
        IF rb_ship > 0 THEN
            rb_sx = (rb_ship % 100) % 10
            rb_sy = (rb_ship % 100) / 10
            rb_sdir = rb_ship / 100
            rb_ssize = ship_size(rb_i)
            FOR rb_j = 0 TO rb_ssize - 1
                IF rb_sdir = 0 THEN
                    bc_x = rb_sx + rb_j : bc_y = rb_sy
                ELSE
                    bc_x = rb_sx : bc_y = rb_sy + rb_j
                END IF
                bc_bq = ds_bq : bc_color = ds_color
                GOSUB board_cell
            NEXT rb_j
        END IF
    NEXT rb_i
END

' ===========================================================================
' render_panel: right-hand chrome (columns 11-19). Three rows per player
' (name, ships-left, blank separator) x 4 players fits rows 0-10 exactly.
' Redrawn in full every poll -- cheap (36 characters max) and simpler than
' diffing four short text fields.
' ===========================================================================
render_panel: PROCEDURE
    FOR rb_i = 0 TO 3
        #gs_c = COL_TEXT
        IF rb_i < cur_pc THEN
            IF rb_i = active_player THEN #gs_c = COL_HILITE
            #df_src = player_addr(rb_i) + PL_NAME : df_pos = screenpos(PANEL_COL, rb_i * 3) : df_len = 9 : #df_color = #gs_c
            GOSUB draw_field
            FOR rb_j = 0 TO 4
                rb_state = PEEK(player_addr(rb_i) + PL_SHIPSLEFT + rb_j) AND 255
                rb_ch = 46 ' '.'  -- sunk
                IF rb_state <> 0 THEN rb_ch = 35 ' '#' -- afloat
                #BACKTAB(screenpos(PANEL_COL + rb_j, rb_i * 3 + 1)) = (rb_ch - 32) * 8 + #gs_c
            NEXT rb_j
        ELSE
            FOR rb_j = 0 TO 8
                #BACKTAB(screenpos(PANEL_COL + rb_j, rb_i * 3)) = COL_TEXT
                #BACKTAB(screenpos(PANEL_COL + rb_j, rb_i * 3 + 1)) = COL_TEXT
            NEXT rb_j
        END IF
    NEXT rb_i
END

' ===========================================================================
' render_game_board: diff each seated player's 100-byte gamefield against
' its SC_PREVFIELD shadow and repaint only the cells that changed (board
' cells are always painted water by board_init, and SC_PREVFIELD is seeded
' to a sentinel below whenever a fresh board_init just ran, so the first
' call after entering GAMESTART paints every real cell exactly once). Own
' ship overlay is drawn once from the wire's myShips bytes, authoritative
' over whatever handle_placement guessed client-side (covers reconnects).
' ===========================================================================
render_game_board: PROCEDURE
    IF ships_drawn = 0 THEN
        FOR rb_i = 0 TO 99
            POKE (SC_PREVFIELD + 0 * 100 + rb_i), 255
            POKE (SC_PREVFIELD + 1 * 100 + rb_i), 255
            POKE (SC_PREVFIELD + 2 * 100 + rb_i), 255
            POKE (SC_PREVFIELD + 3 * 100 + rb_i), 255
        NEXT rb_i
    END IF

    FOR rb_i = 0 TO cur_pc - 1
        rb_pstatus = PEEK(player_addr(rb_i) + PL_STATUS) AND 255
        IF rb_pstatus <> PSTATUS_PLACE_SHIPS THEN
            #rb_field = player_addr(rb_i) + PL_GAMEFIELD
            FOR rb_c = 0 TO 99
                rb_state = PEEK(#rb_field + rb_c) AND 255
                IF rb_state <> (PEEK(SC_PREVFIELD + rb_i * 100 + rb_c) AND 255) THEN
                    bc_bq = rb_i
                    bc_x = rb_c % 10
                    bc_y = rb_c / 10
                    IF rb_state = 1 THEN
                        bc_color = BCOL_HIT
                    ELSEIF rb_state = 2 THEN
                        bc_color = BCOL_MISS
                    ELSE
                        bc_color = BCOL_WATER
                    END IF
                    GOSUB board_cell
                    POKE (SC_PREVFIELD + rb_i * 100 + rb_c), rb_state
                END IF
            NEXT rb_c
        END IF
    NEXT rb_i

    IF ships_drawn = 0 THEN
        FOR rb_i = 0 TO 4
            rb_ship = PEEK(FN_RX + GAME_MYSHIPS + rb_i) AND 255
            rb_sx = (rb_ship % 100) % 10
            rb_sy = (rb_ship % 100) / 10
            rb_sdir = rb_ship / 100
            rb_ssize = ship_size(rb_i)
            FOR rb_j = 0 TO rb_ssize - 1
                IF rb_sdir = 0 THEN
                    bc_x = rb_sx + rb_j : bc_y = rb_sy
                ELSE
                    bc_x = rb_sx : bc_y = rb_sy + rb_j
                END IF
                bc_bq = 0 : bc_color = BCOL_SHIP
                GOSUB board_cell
            NEXT rb_j
        NEXT rb_i
        ships_drawn = 1
    END IF
END

' ===========================================================================
' targeting: your turn. Cursor moves in lockstep over every live enemy
' quadrant at once -- the server's core multiplayer rule is that a single
' shot fires at that coordinate on every other playing board simultaneously,
' so there's only ever one cursor position to choose, not one per opponent.
' Sets has_targeted + atk_pos on a confirmed attack.
' ===========================================================================
targeting: PROCEDURE
    tg_x = 0 : tg_y = 0
    has_targeted = 0
    inp_lock = 0
    GOSUB targeting_draw_cursor

    ' moveTime (server-computed, already net of a network round-trip grace
    ' period -- see gameLogic.go) is the countdown's starting point; count
    ' it down locally frame-by-frame rather than re-polling every second.
    ' Shown in the prompt row's last 2 columns, same corner 5cardstud uses
    ' for its stopwatch.
    tg_timeleft = PEEK(FN_RX + GAME_MOVETIME) AND 255
    tg_framecount = 0
    ' moveTime can run up to 250 (state.bas), so the field needs 3 digits --
    ' a 2-digit field silently produces garbage glyphs rather than truncating
    ' (PRNUM16.z's digit loop assumes higher place-values were already
    ' stripped by wider field positions it never visits). Space-padded
    ' (<.3>, PRNUM16.b) rather than zero-padded (<3>, PRNUM16.z): .z's entry
    ' point never initializes the register it uses to pick blank-vs-zero
    ' padding, so on a value needing fewer than 3 digits it can print
    ' whatever garbage that register held as the leading "digit" instead of
    ' an actual 0. .b's entry point explicitly clears it first.
    PRINT AT STATUS_ROW + 17 COLOR COL_TEXT, <.3>tg_timeleft

tg_loop:
    WAIT

    tg_framecount = tg_framecount + 1
    IF tg_framecount >= 60 THEN
        tg_framecount = 0
        IF tg_timeleft > 0 THEN tg_timeleft = tg_timeleft - 1
        PRINT AT STATUS_ROW + 17 COLOR COL_TEXT, <.3>tg_timeleft
        GOSUB sound_tick
        ' The server enforces its own 45s move limit and skips a turn that
        ' runs out (gameLogic.go's PLAYER_TIME_LIMIT) -- without this bail,
        ' a player who never acts leaves this loop blocked on WAIT forever,
        ' so the client would never poll again to discover its turn had
        ' already moved on.
        IF tg_timeleft = 0 THEN
            GOSUB targeting_erase_cursor
            RETURN
        END IF
    END IF

    IF inp_lock > 0 THEN inp_lock = inp_lock - 1 : GOTO tg_loop

    ' Compute the candidate new position into tg_newx/tg_newy without
    ' touching tg_x/tg_y yet -- targeting_erase_cursor reads tg_x/tg_y to
    ' know which cell to restore, so it must still see the *old* position
    ' when it runs, not the one we're about to move to.
    tg_moved = 0
    tg_newx = tg_x : tg_newy = tg_y
    IF CONT1.RIGHT AND tg_newx < 9 THEN tg_newx = tg_newx + 1 : tg_moved = 1
    IF CONT1.LEFT AND tg_newx > 0 THEN tg_newx = tg_newx - 1 : tg_moved = 1
    IF CONT1.DOWN AND tg_newy < 9 THEN tg_newy = tg_newy + 1 : tg_moved = 1
    IF CONT1.UP AND tg_newy > 0 THEN tg_newy = tg_newy - 1 : tg_moved = 1

    IF tg_moved THEN
        GOSUB targeting_erase_cursor
        tg_x = tg_newx : tg_y = tg_newy
        GOSUB targeting_draw_cursor
        inp_lock = 6
        GOSUB sound_cursor
        GOTO tg_loop
    END IF

    IF CONT1.KEY = 10 THEN
        GOSUB targeting_erase_cursor
        RETURN
    END IF
    IF CONT1.BUTTON = 0 THEN GOTO tg_loop

    GOSUB sound_attack
    GOSUB targeting_erase_cursor
    atk_pos = tg_y * 10 + tg_x
    has_targeted = 1
END

targeting_draw_cursor: PROCEDURE
    FOR tc_q = 1 TO 3
        IF tc_q < cur_pc THEN
            tc_state = PEEK(player_addr(tc_q) + PL_STATUS) AND 255
            IF tc_state = PSTATUS_PLAYING THEN
                bc_bq = tc_q : bc_x = tg_x : bc_y = tg_y : bc_color = BCOL_CURSOR
                GOSUB board_cell
            END IF
        END IF
    NEXT tc_q
END

targeting_erase_cursor: PROCEDURE
    FOR tc_q = 1 TO 3
        IF tc_q < cur_pc THEN
            tc_state = PEEK(player_addr(tc_q) + PL_STATUS) AND 255
            IF tc_state = PSTATUS_PLAYING THEN
                tc_field = PEEK(SC_PREVFIELD + tc_q * 100 + tg_y * 10 + tg_x) AND 255
                tc_color = BCOL_WATER
                IF tc_field = 1 THEN tc_color = BCOL_HIT
                IF tc_field = 2 THEN tc_color = BCOL_MISS
                bc_bq = tc_q : bc_x = tg_x : bc_y = tg_y : bc_color = tc_color
                GOSUB board_cell
            END IF
        END IF
    NEXT tc_q
END

' The compiled program overflows IntyBASIC's default $5000-$6FFF (8192-word)
' window -- the compiler happily keeps allocating past $6FFF, but $7000 is
' not in the manual's list of ranges "usable without additional programming"
' on modern flash cart/homebrew PCBs (that list jumps from $6FFF to $A000).
' Relocating everything from here to halt: into $C100-$FFFF (also on that
' list) via an explicit ASM ORG keeps the whole ROM inside documented-safe
' territory. This is a code segment, not just data (contrary to the
' manual's "easier... if you put only data in these areas" suggestion),
' but cross-segment GOSUB/GOTO compiles to ordinary absolute CP-1610
' jumps/calls, so that's only a bookkeeping caveat, not a correctness one.
    ASM ORG $D000

' ===========================================================================
' handle_placement: place all 5 ships (sizes 5,4,3,3,2, fixed order). Each
' ship starts at a random legal position, then the disc moves it, B1
' rotates it, and the action button confirms (rejected locally if it
' overlaps an already-confirmed ship -- no need to round-trip to the server
' to find that out). Fills SC_MYSHIPS for compose_url's url_path=3.
' ===========================================================================
handle_placement: PROCEDURE
    ' q0 is already water -- board_init just painted all four boards before
    ' this was reached (see tl_loop's STATUS_LOBBY-or-255 transition). Only
    ' the occupancy map needs clearing here.
    FOR rb_i = 0 TO 99
        POKE (SC_OCCUPY + rb_i), 0
    NEXT rb_i

    FOR ship_idx = 0 TO 4
        pc_size = ship_size(ship_idx)

        DO
            pc_dir = RANDOM(2)
            IF pc_dir = 0 THEN
                pc_x = RANDOM(11 - pc_size)
                pc_y = RANDOM(10)
            ELSE
                pc_x = RANDOM(10)
                pc_y = RANDOM(11 - pc_size)
            END IF
            GOSUB place_fits
        LOOP WHILE pc_ok = 0

        pc_prevx = pc_x : pc_prevy = pc_y : pc_prevdir = pc_dir
        GOSUB place_draw

        ph_shipnum = ship_idx + 1
        ' "/5 MOVE B1=ROT" is exactly 14 chars, filling columns 6-19 of the
        ' 20-column STATUS_ROW with no overflow -- the original "/5  DISC=
        ' MOVE B1=ROT" (20 chars) ran 6 columns past the end of the row and
        ' off the end of #BACKTAB, corrupting the rest of the screen.
        PRINT AT STATUS_ROW COLOR COL_TEXT, "SHIP "
        PRINT AT STATUS_ROW + 5, <>ph_shipnum
        PRINT AT STATUS_ROW + 6, "/5 MOVE B1=ROT"

        inp_lock = 0
ph_loop:
        WAIT
        IF inp_lock > 0 THEN inp_lock = inp_lock - 1 : GOTO ph_loop

        pc_mx = 9 : pc_my = 9
        IF pc_dir = 0 THEN pc_mx = 10 - pc_size ELSE pc_my = 10 - pc_size

        pc_moved = 0
        IF CONT1.RIGHT AND pc_x < pc_mx THEN pc_x = pc_x + 1 : pc_moved = 1
        IF CONT1.LEFT AND pc_x > 0 THEN pc_x = pc_x - 1 : pc_moved = 1
        IF CONT1.DOWN AND pc_y < pc_my THEN pc_y = pc_y + 1 : pc_moved = 1
        IF CONT1.UP AND pc_y > 0 THEN pc_y = pc_y - 1 : pc_moved = 1

        IF CONT1.B1 THEN
            pc_dir = 1 - pc_dir
            IF pc_dir = 0 AND pc_x > 10 - pc_size THEN pc_x = 10 - pc_size
            IF pc_dir = 1 AND pc_y > 10 - pc_size THEN pc_y = 10 - pc_size
            pc_moved = 1
        END IF

        IF pc_moved THEN
            GOSUB place_erase
            pc_prevx = pc_x : pc_prevy = pc_y : pc_prevdir = pc_dir
            GOSUB place_draw
            inp_lock = 6
            GOSUB sound_cursor
            GOTO ph_loop
        END IF

        IF CONT1.BUTTON = 0 THEN GOTO ph_loop

        GOSUB place_fits
        IF pc_ok = 0 THEN
            GOSUB sound_invalid
            GOTO ph_loop
        END IF

        GOSUB place_mark
        GOSUB sound_place_ship
        FOR pc_i = 0 TO pc_size - 1
            IF pc_dir = 0 THEN
                bc_x = pc_x + pc_i : bc_y = pc_y
            ELSE
                bc_x = pc_x : bc_y = pc_y + pc_i
            END IF
            bc_bq = 0 : bc_color = BCOL_SHIP
            GOSUB board_cell
        NEXT pc_i

        POKE (SC_MYSHIPS + ship_idx), pc_x + pc_y * 10 + 100 * pc_dir
    NEXT ship_idx
END

place_fits: PROCEDURE
    pc_ok = 1
    IF pc_dir = 0 THEN
        IF pc_x + pc_size > 10 THEN pc_ok = 0
    ELSE
        IF pc_y + pc_size > 10 THEN pc_ok = 0
    END IF
    IF pc_ok THEN
        FOR pc_i = 0 TO pc_size - 1
            IF pc_dir = 0 THEN
                pc_cx = pc_x + pc_i : pc_cy = pc_y
            ELSE
                pc_cx = pc_x : pc_cy = pc_y + pc_i
            END IF
            IF (PEEK(SC_OCCUPY + pc_cy * 10 + pc_cx) AND 255) <> 0 THEN pc_ok = 0
        NEXT pc_i
    END IF
END

place_mark: PROCEDURE
    FOR pc_i = 0 TO pc_size - 1
        IF pc_dir = 0 THEN
            pc_cx = pc_x + pc_i : pc_cy = pc_y
        ELSE
            pc_cx = pc_x : pc_cy = pc_y + pc_i
        END IF
        POKE (SC_OCCUPY + pc_cy * 10 + pc_cx), 1
    NEXT pc_i
END

place_erase: PROCEDURE
    FOR pc_i = 0 TO pc_size - 1
        IF pc_prevdir = 0 THEN
            pc_cx = pc_prevx + pc_i : pc_cy = pc_prevy
        ELSE
            pc_cx = pc_prevx : pc_cy = pc_prevy + pc_i
        END IF
        bc_bq = 0 : bc_x = pc_cx : bc_y = pc_cy : bc_color = BCOL_WATER
        GOSUB board_cell
    NEXT pc_i
END

place_draw: PROCEDURE
    FOR pc_i = 0 TO pc_size - 1
        IF pc_dir = 0 THEN
            pc_cx = pc_x + pc_i : pc_cy = pc_y
        ELSE
            pc_cx = pc_x : pc_cy = pc_y + pc_i
        END IF
        bc_bq = 0 : bc_x = pc_cx : bc_y = pc_cy : bc_color = BCOL_CURSOR
        GOSUB board_cell
    NEXT pc_i
END

' ===========================================================================
' ingame_menu: keypad CLEAR overlay, drawn over the prompt row and the two
' rows above it. Disc up/down to choose, action button to confirm, Clear
' again cancels straight back to RESUME.
' ===========================================================================
ingame_menu: PROCEDURE
    im_sel = 0
    inp_lock = 0
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
    prev_status = 255 ' force a full CLS/board_init redraw on return
END

' ===========================================================================
' name_entry_screen: disc letter picker, max 8 chars. Disc up/down cycles
' the character under the cursor through A-Z, 0-9, space; left/right moves
' the cursor; the action button accepts (at least 1 non-space char).
' Adapted from fujinet-5cardstud/intv/5card.bas, verbatim apart from colors.
' ===========================================================================
name_entry_screen: PROCEDURE
    CLS
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
