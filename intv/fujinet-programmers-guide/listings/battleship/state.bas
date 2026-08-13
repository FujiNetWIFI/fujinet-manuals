' state.bas -- binary GameState/Tables wire format, read in place out of FN_RX.
'
' Per the pattern established by fujinet-5cardstud/intv/state.bas: never copy
' the reply into IntyBASIC variables -- these are just fixed offsets (matching
' server/util.go's serializeResults binary layout, requested with
' &bin=1&v=2) plus small DEF FN accessors that PEEK straight out of FN_RX.
' v=2 is not optional here: v=1 omits the winner's ships and forces
' activePlayer=-1 at game over, both of which the gameover screen needs.
'
' Header (always present), 38 bytes:
'   0   playerCount (1)
'   1   prompt[33]           lowercased, NUL-padded
'  34   status (1)           0 lobby, 1 place-ships, 10 gamestart,
'                             11 miss, 12 hit, 13 sunk, 99 gameover
'  35   playerStatus (1)     your status: 0 playing, 1 defeated, 2 viewing,
'                             3 ready, 10 place-ships
'  36   activePlayer (signed, $FF = -1; 0 = your turn)
'  37   moveTime (1, seconds, 0-250)
'
' If status = 0 (STATUS_LOBBY), the header is followed by:
'  38   serverName[21]
'  59   players[N] -- N = playerCount, 10 bytes each: name[9] ready(1)
'
' Otherwise (in a table, placing/playing/over):
'  38   lastAttackPos (1)     0-99
'  39   myShips[10]           [0..4] your ships, [5..9] winner's ships
'                             (v=2; only nonzero at game over), each byte is
'                             cell + 100*dir (dir 0=horizontal, 1=vertical)
'  49   players[N] -- N = playerCount, 115 bytes each:
'         name[9] status(1) gamefield[100] shipsLeft[5]
'         (gamefield/shipsLeft are present only once ships are placed and
'          the game has started -- see GAME_MINLEN/expected-length notes
'          below; entries for players who haven't placed are shorter, but
'          in practice the server only starts sending player records once
'          GAMESTART, by which point every playing player has placed.)
'
' /tables -> Tables struct:
'   0   count (1)
'   then N x 36 bytes: table[9] name[21] players[6] (literal "cur / max")

    CONST GAME_PLAYERCOUNT  = 0
    CONST GAME_PROMPT       = 1     ' 33 bytes
    CONST GAME_STATUS       = 34
    CONST GAME_PLAYERSTATUS = 35
    CONST GAME_ACTIVEPLAYER = 36
    CONST GAME_MOVETIME     = 37

    CONST LOBBY_SERVERNAME  = 38    ' 21 bytes
    CONST LOBBY_PLAYERS     = 59
    CONST LOBBY_PLAYER_STRIDE = 10
    CONST LP_NAME  = 0               ' 9 bytes
    CONST LP_READY = 9               ' 1 byte

    CONST GAME_LASTATTACK   = 38
    CONST GAME_MYSHIPS      = 39    ' 10 bytes
    CONST GAME_PLAYERS      = 49

    CONST PLAYER_STRIDE = 115
    CONST PL_NAME      = 0          ' 9 bytes
    CONST PL_STATUS    = 9          ' 1 byte
    CONST PL_GAMEFIELD = 10         ' 100 bytes
    CONST PL_SHIPSLEFT = 110        ' 5 bytes

    CONST TABLE_STRIDE = 36
    CONST TBL_ID      = 0           ' 9 bytes
    CONST TBL_NAME    = 9           ' 21 bytes
    CONST TBL_PLAYERS = 30          ' 6 bytes, literal "cur / max"

    CONST GAME_MAXLEN    = 509
    CONST GAME_MINLEN    = 38       ' fixed header, before branching on status
    CONST TABLES_MAXLEN  = 361

    ' Status values.
    CONST STATUS_LOBBY       = 0
    CONST STATUS_PLACE_SHIPS = 1
    CONST STATUS_GAMESTART   = 10
    CONST STATUS_MISS        = 11
    CONST STATUS_HIT         = 12
    CONST STATUS_SUNK        = 13
    CONST STATUS_GAMEOVER    = 99

    ' Player status values.
    CONST PSTATUS_PLAYING     = 0
    CONST PSTATUS_DEFEATED    = 1
    CONST PSTATUS_VIEWING     = 2
    CONST PSTATUS_READY       = 3
    CONST PSTATUS_PLACE_SHIPS = 10

    ' Ship sizes, fixed order (index also selects the shipsLeft/myShips slot).
    ship_size: DATA 5, 4, 3, 3, 2

' player_addr(i): address of player i's 115-byte in-game record in FN_RX.
    DEF FN player_addr(i) = FN_RX + GAME_PLAYERS + i * PLAYER_STRIDE

' lobby_player_addr(i): address of player i's 10-byte lobby record in FN_RX.
    DEF FN lobby_player_addr(i) = FN_RX + LOBBY_PLAYERS + i * LOBBY_PLAYER_STRIDE

' table_addr(i): address of table i's 36-byte record in FN_RX (i is 0-based,
' the record right after the leading count byte).
    DEF FN table_addr(i) = FN_RX + 1 + i * TABLE_STRIDE

' active_player: activePlayer as a signed value (-1..3), converting the
' wire's $FF sentinel. Called as plain `active_player` (no parens -- DEF FN
' with no arguments is defined and invoked without them).
    DEF FN active_player = ((PEEK(FN_RX + GAME_ACTIVEPLAYER) AND 255) = 255) * -256 + (PEEK(FN_RX + GAME_ACTIVEPLAYER) AND 255)

' state_status / state_playercount / state_playerstatus: unsigned byte reads,
' broken out as DEF FNs purely so call sites read as intent, not offsets.
    DEF FN state_status = PEEK(FN_RX + GAME_STATUS) AND 255
    DEF FN state_playercount = PEEK(FN_RX + GAME_PLAYERCOUNT) AND 255
    DEF FN state_playerstatus = PEEK(FN_RX + GAME_PLAYERSTATUS) AND 255

' ---------------------------------------------------------------------------
' validate_state: layered sanity check on a /state, /ready, /place, /attack,
' or /view reply already sitting in FN_RX (#net_gotlen bytes). FN_RX is never
' cleared between calls, so a short read leaves stale bytes from a previous,
' larger response -- fixed-offset reads would happily render that as
' garbage. Sets fn_ok = 0 (in addition to whatever net/transact left it) if
' any gate fails; callers must check fn_ok after calling this, not just after
' api_call.
' ---------------------------------------------------------------------------
DIM vs_status, vs_pc, #vs_expect
validate_state: PROCEDURE
    IF fn_ok = 0 OR #net_gotlen < GAME_MINLEN THEN
        fn_ok = 0
        RETURN
    END IF

    vs_status = state_status
    vs_pc = state_playercount

    IF vs_pc > 4 THEN
        fn_ok = 0
        RETURN
    END IF

    IF vs_status <> STATUS_LOBBY AND vs_status <> STATUS_PLACE_SHIPS AND vs_status <> STATUS_GAMESTART AND vs_status <> STATUS_MISS AND vs_status <> STATUS_HIT AND vs_status <> STATUS_SUNK AND vs_status <> STATUS_GAMEOVER THEN
        fn_ok = 0
        RETURN
    END IF

    IF vs_status = STATUS_LOBBY THEN
        #vs_expect = LOBBY_PLAYERS + vs_pc * LOBBY_PLAYER_STRIDE
    ELSEIF vs_status = STATUS_PLACE_SHIPS THEN
        ' No players[] array yet -- see the GAME_MINLEN/expected-length note
        ' above header comment: the server only starts sending player
        ' records once GAMESTART. Header + lastAttackPos + myShips only.
        #vs_expect = GAME_PLAYERS
    ELSE
        #vs_expect = GAME_PLAYERS + vs_pc * PLAYER_STRIDE
    END IF

    IF #net_gotlen < #vs_expect THEN fn_ok = 0
END
