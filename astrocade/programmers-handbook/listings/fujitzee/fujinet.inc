; fujinet.inc -- N: device commands and the Fujitzee wire format.
;
; The N: command values are hand-synchronised with the battleship port
; (whose o2/ family carries the documentation of WHY each is what it is).
; The wire offsets are verified against the shared C client's packed
; structs (src/misc.h) and the Intellivision client's byte-exact map
; (intv/state.bas). The mailbox transport itself is fujilib.inc.

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

; ---- Wire format (?bin=1) ---------------------------------------------
; /state, /ready, /roll/.., /score/.., /leave -> the same state blob;
; /tables -> Tables. Offsets are read in place out of the reply slice
; window; nothing is buffered. All strings are lowercased, NUL-padded,
; one byte longer than their content width.

; Header, always present (95 bytes):
GOPC    EQU     0               ; playerCount (spectators appended)
GOSRVNM EQU     1               ; serverName[21]
GOPRMPT EQU     22              ; prompt[41]
GORND   EQU     63              ; round: 0 lobby, 1-13 play, 99 gameover
GORLEFT EQU     64              ; rollsLeft this turn (3 down to 0)
GOACTPL EQU     65              ; signed; FFH = -1 nobody, 0 = your turn
                                ; (the server rotates you to index 0)
GOMVTIM EQU     66              ; seconds left, 0-250
GOVIEW  EQU     67              ; 1 = YOU are a spectator: input disabled
GODICE  EQU     68              ; 5 ascii '1'-'6' + NUL; NULs at turn start
GOKEEP  EQU     74              ; 5 ascii '0'/'1' + NUL; '1' = re-roll
GOVALID EQU     80              ; validScores[15], signed bytes: FFH = -1
                                ; closed row, else the points that row
                                ; would earn. ALL ZERO in the lobby --
                                ; only rounds 1-13 may read it.
GOPLYRS EQU     95              ; playerCount x 42-byte records
PLSTRID EQU     42
PLNAME  EQU     0               ; name[9]
PLALIAS EQU     9               ; index of the highlight char in name
PLSCORS EQU     10              ; scores[16], u16 LE each: FFFFH = -1
                                ; unset, FFFEH = -2 spectator. scores[0]
                                ; doubles as the lobby ready flag.

; Score slots. 0-5 ones..sixes and 8-14 are the 13 selectable
; categories; 6, 7 and 15 are server-computed and never selectable.
SCUPTOT EQU     6               ; upper total
SCBONUS EQU     7               ; upper bonus (35 at 63+)
SCSET3  EQU     8
SCFUJI  EQU     14              ; five of a kind
SCGRAND EQU     15              ; grand total -- filled only at gameover

; Round values.
RNLOBBY EQU     0
RNFINAL EQU     13
RNOVER  EQU     99

; /tables (?bin=1) -- byte-identical to the card games' Tables struct.
TBSTRID EQU     36
TBID    EQU     0               ; table[9]
TBNAME  EQU     9               ; name[21]
TBPLYRS EQU     30              ; players[6], literal "cur / max"

GMAXLEN EQU     599             ; 95 + 12*42; the NREAD clamp, and it fits
                                ; the cart's four 256-byte reply slices
GMINLEN EQU     95              ; the fixed header
TMAXLEN EQU     361
PCMAX   EQU     12              ; the serializer's seat + spectator cap
