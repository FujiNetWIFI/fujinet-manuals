' state.bas -- binary Game/Tables wire format, read in place out of FN_RX.
'
' Per the plan: never copy the reply into IntyBASIC variables. These are
' just fixed offsets (matching server/util.go's appendFixedLengthString
' binary layout, requested with ?bin=1 -- uint16 fields are little-endian,
' the server's default; &be=1 was dropped after pot/bet started showing
' up as an exact multiple of 256, the signature of a byte-order mismatch
' on the server's binary.BigEndian path, which is exercised by only one
' other client in the whole family (CoCo/6809) versus everything else
' being little-endian x86/6502/Z80)
' plus small DEF FN accessors that PEEK straight out of FN_RX.
'
' /state, /move/XX, /leave -> Game struct, up to 418 bytes:
'   0   lastResult[81]
'  81   round (1)              0=waiting 1-4=streets 5=showdown
'  82   pot (u16 LE)
'  84   activePlayer (signed, $FF = -1)
'  85   moveTime (1, seconds)
'  86   viewing (1, 0/1)
'  87   validMoveCount (1)
'  88   validMoves[5] -- always 5 slots, 13 bytes each: move[3] + name[10]
' 153   playerCount (1)
' 154   players[N] -- N = playerCount, 33 bytes each:
'         name[9] status(1) bet(u16 LE) move[8] purse(u16 LE) hand[11]
'
' /tables -> Tables struct:
'   0   count (1)
'   then N x 36 bytes: table[9] name[21] players[6] (literal "cur / max")

    CONST GAME_LASTRESULT     = 0
    CONST GAME_ROUND          = 81
    CONST GAME_POT            = 82
    CONST GAME_ACTIVEPLAYER   = 84
    CONST GAME_MOVETIME       = 85
    CONST GAME_VIEWING        = 86
    CONST GAME_VALIDMOVECOUNT = 87
    CONST GAME_VALIDMOVES     = 88
    CONST GAME_PLAYERCOUNT    = 153
    CONST GAME_PLAYERS        = 154

    CONST MOVE_STRIDE  = 13
    CONST MOVE_CODE    = 0   ' 3 bytes
    CONST MOVE_NAME    = 3   ' 10 bytes

    CONST PLAYER_STRIDE = 33
    CONST PL_NAME   = 0      ' 9 bytes
    CONST PL_STATUS = 9      ' 1 byte: 0 waiting, 1 playing, 2 folded, 3 left
    CONST PL_BET    = 10     ' u16 LE
    CONST PL_MOVE   = 12     ' 8 bytes
    CONST PL_PURSE  = 20     ' u16 LE
    CONST PL_HAND   = 22     ' 11 bytes (5 cards x 2 chars + NUL)

    CONST TABLE_STRIDE = 36
    CONST TBL_ID      = 0    ' 9 bytes
    CONST TBL_NAME    = 9    ' 21 bytes
    CONST TBL_PLAYERS = 30   ' 6 bytes, literal "cur / max"

    CONST GAME_MAXLEN   = 418
    CONST GAME_MINLEN   = 154  ' fixed prefix through playerCount, 0 players
    CONST TABLES_MAXLEN = 361

' u16be: read a little-endian uint16 at RAM address `addr` (see header note
' on why this is LE despite the name -- kept as u16be to avoid renaming
' every call site for what's ultimately a one-line fix).
    DEF FN u16be(addr) = (PEEK(addr + 1) AND 255) * 256 + (PEEK(addr) AND 255)

' player_addr(i): address of player i's 33-byte record in FN_RX.
    DEF FN player_addr(i) = FN_RX + GAME_PLAYERS + i * PLAYER_STRIDE

' move_addr(i): address of valid-move slot i's 13-byte record in FN_RX.
    DEF FN move_addr(i) = FN_RX + GAME_VALIDMOVES + i * MOVE_STRIDE

' table_addr(i): address of table i's 36-byte record in FN_RX (i is 0-based,
' the record right after the leading count byte).
    DEF FN table_addr(i) = FN_RX + 1 + i * TABLE_STRIDE

' active_player: activePlayer as a signed value (-1..7), converting the
' wire's $FF sentinel. Called as plain `active_player` (no parens -- DEF FN
' with no arguments is defined and invoked without them).
    DEF FN active_player = ((PEEK(FN_RX + GAME_ACTIVEPLAYER) AND 255) = 255) * -256 + (PEEK(FN_RX + GAME_ACTIVEPLAYER) AND 255)

' draw_field is in 5card.bas -- it renders a field straight from FN_RX (or
' any RAM address) onto the screen in one pass (uppercase, NUL/pad-stop,
' ASCII->card-code), so there's no need to stage a separate ASCII copy here.
