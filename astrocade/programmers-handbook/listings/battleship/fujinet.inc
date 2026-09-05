; fujinet.inc -- N: device commands and the Battleship wire format.
;
; The N: command values are hand-synchronised with the texasHoldEm port
; (whose o2/ family carries the documentation of WHY each is what it is).
; The wire offsets are verified against the server's serializeResults()
; (servers/fujinet-game-system/battleship/util.go) and the Intellivision
; client's byte-exact map (intv/state.bas). The mailbox transport itself
; is fujilib.inc.

; ---- Network device (N:) ----------------------------------------------
NETDEV  EQU     71H             ; N1:
NCOPEN  EQU     4FH             ; 'O'
NCCLOSE EQU     43H             ; 'C'
NCREAD  EQU     52H             ; 'R'
NCSTAT  EQU     53H             ; 'S'

NMHTTPG EQU     0CH             ; open mode: HTTP GET
NTRNONE EQU     0               ; translation: none

; NET_STATUS reply: 4 bytes in slice 0.
NSAVLO  EQU     0               ; bytes waiting, low
NSAVHI  EQU     1               ; bytes waiting, high
NSCONN  EQU     2               ; connected flag
NSDEVST EQU     3               ; nDevStatus_t; 1 = SUCCESS. Checking this is
                                ; not optional: the GET is deferred until the
                                ; first STATUS, and an HTTP error page still
                                ; has a readable body.

; ---- Wire format (?bin=1&v=2) -----------------------------------------
; /state, /ready, /place/.., /attack/.., /leave -> the same state blob;
; /tables -> Tables. Offsets are read in place out of the reply slice
; window; nothing is buffered. All strings are lowercased, NUL-padded,
; one byte longer than their content width.
;
; v=2 is mandatory: v1 hides the winner (activePlayer forced to -1 at
; gameover) and sends only 5 myShips bytes instead of 10.

; Header, always present (38 bytes):
GOPC    EQU     0               ; playerCount
GOPRMPT EQU     1               ; prompt[33]
GOSTAT  EQU     34              ; game status, STxxxx below
GOPSTAT EQU     35              ; YOUR status, PSxxxx below
GOACTPL EQU     36              ; signed; FFH = -1 nobody, 0 = your turn
                                ; (the server rotates you to index 0);
                                ; at gameover (v=2) the winner's index
GOMVTIM EQU     37              ; seconds left, 0-250

; status = 0 (lobby): the header is followed by
GOSRVNM EQU     38              ; serverName[21]
GOLPLRS EQU     59              ; playerCount x 10-byte records
LPSTRID EQU     10
LPNAME  EQU     0               ; name[9]
LPSTAT  EQU     9               ; the player's PSxxxx status (3 = ready)

; status <> 0: the header is followed by
GOLATK  EQU     38              ; lastAttackPos, 0-99
GOMYSH  EQU     39              ; myShips[10]: [0-4] yours, [5-9] the
                                ; winner's (gameover only); each byte is
                                ; pos + 100*dir (dir 0 horiz, 1 vert)
GOPLYRS EQU     49              ; playerCount x 115-byte records ONCE THE
                                ; GAMEFIELDS EXIST (status >= 10). During
                                ; PLACE_SHIPS the records are 10 bytes
                                ; (name + status only) -- never index
                                ; player records in the place phase.
PLSTRID EQU     115
PLNAME  EQU     0               ; name[9]
PLSTAT  EQU     9               ; the player's PSxxxx status
PLFIELD EQU     10              ; gamefield[100], y*10+x: 0 unknown,
                                ; 1 hit, 2 miss
PLSHLFT EQU     110             ; shipsLeft[5]: 1 afloat, 0 sunk, per
                                ; SHPSIZ index

; /tables (?bin=1) -- byte-identical to the card games' Tables struct.
TBSTRID EQU     36
TBID    EQU     0               ; table[9]
TBNAME  EQU     9               ; name[21]
TBPLYRS EQU     30              ; players[6], literal "cur / max"

; Game status values.
STLOBBY EQU     0
STPLACE EQU     1
STSTART EQU     10
STMISS  EQU     11
STHIT   EQU     12
STSUNK  EQU     13
STOVER  EQU     99

; Player status values.
PSPLAY  EQU     0
PSDEAD  EQU     1
PSVIEW  EQU     2
PSREADY EQU     3
PSPLACE EQU     10

GMAXLEN EQU     509             ; 49 + 4*115; the NREAD clamp, and it fits
                                ; the cart's four 256-byte reply slices
GMINLEN EQU     38              ; the fixed header
TMAXLEN EQU     361
