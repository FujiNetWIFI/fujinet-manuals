' state.bas -- binary GameState/Tables wire format, read in place out of FN_RX.
'
' Per the pattern established by fujinet-5cardstud/intv/state.bas and
' fujinet-battleship/intv/state.bas: never copy the reply into IntyBASIC
' variables -- these are just fixed offsets (matching server/util.go's
' serializeResults binary layout, requested with &bin=1) plus small DEF FN
' accessors that PEEK straight out of FN_RX.
'
' GameState layout, always this shape regardless of round (util.go:76-108):
'   0   playerCount (1)
'   1   serverName[21]        lowercased, NUL-padded
'  22   prompt[41]             lowercased, NUL-padded
'  63   round (1)              0=lobby, 1..13=play, 99=gameover
'  64   rollsLeft (1)
'  65   activePlayer (signed, $FF = -1; 0 = your turn)
'  66   moveTime (1, seconds, <=255 by design)
'  67   viewing (1)            1 = you are a spectator
'  68   dice[6]                5 ascii digits '1'-'6' + NUL; empty at turn start
'  74   keepRoll[6]            5 ascii '0'/'1' + NUL (1 = will re-roll)
'  80   validScores[15]        signed bytes; $FF = -1 = not selectable.
'                               Only meaningful when round is 1..13; the
'                               server sends all zero bytes here in the
'                               lobby (nil slice, not -1 -- see util.go's
'                               ValidScores loop), so never read this
'                               outside GAME_MINLEN's play branch.
'  95   players[N] -- N = playerCount (can exceed 6; spectators are
'       appended beyond the 6 seated players), 42 bytes each:
'         name[9] alias(1) scores[16] (u16 LE each; $FFFF = -1 = unset)
'       scores[] is meaningful only at index 0 (1=ready,0=not,-2=spectator)
'       while round=0; all 16 are real once round>=1.
'
' /tables -> Tables struct:
'   0   count (1)
'   then N x 36 bytes: table[9] name[21] players[6] (literal "cur / max")

    CONST GAME_PLAYERCOUNT  = 0
    CONST GAME_SERVERNAME   = 1     ' 21 bytes
    CONST GAME_PROMPT       = 22    ' 41 bytes
    CONST GAME_ROUND        = 63
    CONST GAME_ROLLSLEFT    = 64
    CONST GAME_ACTIVEPLAYER = 65
    CONST GAME_MOVETIME     = 66
    CONST GAME_VIEWING      = 67
    CONST GAME_DICE         = 68    ' 6 bytes
    CONST GAME_KEEPROLL     = 74    ' 6 bytes
    CONST GAME_VALIDSCORES  = 80    ' 15 bytes
    CONST GAME_PLAYERS      = 95

' Scratch RAM, ours, below fujinet.bas's own SC_* buffers (which stop at
' SC_QUERY $9150 + 48 = $9180) and well below the $9C00 mailbox. Declared
' here (rather than in fujitzee.bas) so dice.bas/card.bas -- included right
' after this file, before fujitzee.bas's own CONST section runs -- can
' reference SC_KEEP without a forward reference.
    CONST SC_TABLE      = $9180 ' selected table id, 9 bytes (8 + NUL)
    CONST SC_KEEP       = $9190 ' 5-char reroll mask, ascii '0'/'1', no NUL needed
    CONST SC_PREVSCORES = $91A0 ' shadow of the active player's scores[16] (u16 LE), 32 bytes

' Cross-file client display globals. IntyBASIC auto-registers a bare
' identifier the first time it's mentioned at all (read or write), not
' just on an explicit DIM -- card.bas (included right after this file)
' reads/writes view_idx and draw_field's df_* parameters before
' fujitzee.bas's own DIM section would otherwise declare them, which
' turns that later DIM into a "variable already defined" error. Declaring
' them here, ahead of every include that touches them, avoids that.
    DIM view_idx
    DIM df_pos, df_len, #df_color, #df_src

    CONST PLAYER_STRIDE = 42
    CONST PL_NAME   = 0             ' 9 bytes
    CONST PL_ALIAS  = 9             ' 1 byte
    CONST PL_SCORES = 10            ' 16 x uint16 LE

    CONST TABLE_STRIDE = 36
    CONST TBL_ID      = 0           ' 9 bytes
    CONST TBL_NAME    = 9           ' 21 bytes
    CONST TBL_PLAYERS = 30          ' 6 bytes, literal "cur / max"

    ' PLAYER_MAX matches the reference C client's misc.h (spectators can
    ' push playerCount past the 6 seated-player cap); GAME_MAXLEN sizes the
    ' one poll buffer big enough for the worst case, 95 + 12*42 = 599 bytes,
    ' well inside FN_RX's 704-byte window ($9D40-$9FFF).
    CONST PLAYER_MAX     = 12
    CONST GAME_MAXLEN    = GAME_PLAYERS + PLAYER_MAX * PLAYER_STRIDE
    CONST GAME_MINLEN    = GAME_PLAYERS
    CONST TABLES_MAXLEN  = 361

    ' Round values.
    CONST ROUND_LOBBY    = 0
    CONST ROUND_FINAL    = 13
    CONST ROUND_GAMEOVER = 99

    ' Scorecard indices (gameLogic.go SCORE_* constants).
    CONST SCORE_ONES        = 0
    CONST SCORE_UPPER_TOTAL = 6
    CONST SCORE_UPPER_BONUS = 7
    CONST SCORE_SET3        = 8
    CONST SCORE_SET4        = 9
    CONST SCORE_FULLHOUSE   = 10
    CONST SCORE_SRUN        = 11
    CONST SCORE_LRUN        = 12
    CONST SCORE_CHANCE      = 13
    CONST SCORE_FUJITZEE    = 14
    CONST SCORE_TOTAL       = 15

    ' Lobby-only meaning of scores[0].
    CONST SCORE_VIEWING = 65534     ' wire $FFFE -> u16 65534 (== -2 signed)
    CONST SCORE_UNSET   = 65535     ' wire $FFFF -> -1 signed
    CONST SCORE_READY   = 1
    CONST SCORE_UNREADY = 0

' player_addr(i): address of player i's 42-byte record in FN_RX.
    DEF FN player_addr(i) = FN_RX + GAME_PLAYERS + i * PLAYER_STRIDE

' table_addr(i): address of table i's 36-byte record in FN_RX (i is 0-based,
' the record right after the leading count byte).
    DEF FN table_addr(i) = FN_RX + 1 + i * TABLE_STRIDE

' score_at(addr, i): player record at `addr`'s scores[i] as an unsigned
' 16-bit word (65535 = unset/-1, 65534 = viewing/-2 in the lobby slot).
    DEF FN score_at(addr, i) = (PEEK(addr + PL_SCORES + i * 2 + 1) AND 255) * 256 + (PEEK(addr + PL_SCORES + i * 2) AND 255)

' valid_at(i): validScores[i] as an unsigned byte (255 = -1 = not selectable).
' Parenthesized "(... AND 255)" deliberately -- see state_round's comment
' below for why an unparenthesized trailing "AND 255" is dangerous.
    DEF FN valid_at(i) = (PEEK(FN_RX + GAME_VALIDSCORES + i) AND 255)

' active_player: activePlayer as a signed value (-1..11), converting the
' wire's $FF sentinel. Called as plain `active_player` (no parens -- DEF FN
' with no arguments is defined and invoked without them).
    DEF FN active_player = ((PEEK(FN_RX + GAME_ACTIVEPLAYER) AND 255) = 255) * -256 + (PEEK(FN_RX + GAME_ACTIVEPLAYER) AND 255)

' state_round / state_playercount / state_rollsleft / state_viewing:
' unsigned byte reads, broken out as DEF FNs purely so call sites read as
' intent, not offsets.
'
' Parenthesized "(... AND 255)" deliberately, not left bare. IntyBASIC's
' "=" binds *tighter* than "AND" (same trap as C's "a & b == c"), so an
' unparenthesized "PEEK(x) AND 255" substituted into "state_viewing = 0"
' compiles as "PEEK(x) AND (255 = 0)" -- the 255 gets grouped with the
' comparison instead of the AND, folding to "PEEK(x) AND 0", which is
' always zero regardless of what was actually peeked. Confirmed by reading
' the generated .lst for "IF active_player = 0 AND state_viewing = 0
' THEN": active_player's own formula (already parenthesized below) came
' out correct, but state_viewing's unparenthesized body made the whole
' condition permanently false, so turn_input was never reached at all.
    DEF FN state_round       = (PEEK(FN_RX + GAME_ROUND) AND 255)
    DEF FN state_playercount = (PEEK(FN_RX + GAME_PLAYERCOUNT) AND 255)
    DEF FN state_rollsleft   = (PEEK(FN_RX + GAME_ROLLSLEFT) AND 255)
    DEF FN state_viewing     = (PEEK(FN_RX + GAME_VIEWING) AND 255)

' ---------------------------------------------------------------------------
' validate_state: layered sanity check on a /state, /ready, /roll, or /score
' reply already sitting in FN_RX (#net_gotlen bytes). FN_RX is never cleared
' between calls, so a short read leaves stale bytes from a previous, larger
' response -- fixed-offset reads would happily render that as garbage. Sets
' fn_ok = 0 (in addition to whatever net/transact left it) if any gate
' fails; callers must check fn_ok after calling this, not just after
' api_call.
' ---------------------------------------------------------------------------
DIM vs_round, vs_pc, #vs_expect
validate_state: PROCEDURE
    IF fn_ok = 0 OR #net_gotlen < GAME_MINLEN THEN
        fn_ok = 0
        RETURN
    END IF

    vs_pc = state_playercount
    IF vs_pc > PLAYER_MAX THEN
        fn_ok = 0
        RETURN
    END IF

    vs_round = state_round
    IF vs_round <> ROUND_GAMEOVER AND vs_round > ROUND_FINAL THEN
        fn_ok = 0
        RETURN
    END IF

    #vs_expect = GAME_PLAYERS + vs_pc * PLAYER_STRIDE
    IF #net_gotlen < #vs_expect THEN fn_ok = 0
END
