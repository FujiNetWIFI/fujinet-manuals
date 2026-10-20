; state.inc -- the wire format and the device numbers, as equates.
;
; The server's ?bin=1&v=2 layout (servers/fujinet-game-system/battleship,
; util.go): fixed-length strings padded with NULs and one byte longer than
; their text, everything lower case. Nothing is parsed into RAM but a few
; header bytes: the screens index the reply window (RPLY) in place.

; ---- /state and every request whose reply is the state ----
GPCNT   EQU     0               ; playerCount
GPROMPT EQU     1               ; prompt[33]: the lobby's, empty in play
GSTAT   EQU     34              ; ST_*
GPSTAT  EQU     35              ; our own PS_*
GACT    EQU     36              ; activePlayer, $FF nobody; the winner at 99
GMVTIM  EQU     37              ; seconds left to move
; the lobby (GSTAT = ST_LOBBY)
GSRV    EQU     38              ; serverName[21]
GLPLYRS EQU     59              ; players, LSTRIDE apart
LSTRIDE EQU     10              ; name[9], status
; placement, play and game over
GLAP    EQU     38              ; lastAttackPos
GSHIPS  EQU     39              ; ours [0-4], the winner's [5-9] at 99: pos+100*dir
GPLYRS  EQU     49              ; players: PSTRIDE apart, LSTRIDE in placement
PSTRIDE EQU     115
PNAME   EQU     0               ; name[9]
PSTAT   EQU     9               ; PS_*
PGF     EQU     10              ; gamefield[100]: 0 unknown, 1 hit, 2 miss
PLEFT   EQU     110             ; shipsLeft[5]: 1 afloat, 0 sunk
GMAXPL  EQU     4
GMINLEN EQU     38              ; the shortest a state can be
GMAXLEN EQU     GPLYRS+GMAXPL*PSTRIDE

; GSTAT
ST_LOBBY EQU    0
ST_PLACE EQU    1
ST_START EQU    10
ST_MISS  EQU    11
ST_HIT   EQU    12
ST_SUNK  EQU    13
ST_OVER  EQU    99

; PSTAT and GPSTAT
PS_PLAY  EQU    0
PS_DEAD  EQU    1
PS_VIEW  EQU    2
PS_READY EQU    3
PS_PLACE EQU    10

; ---- /tables: a count byte, then Tables ----
TSTRIDE EQU     36
TID     EQU     0               ; id[9]
TNAME   EQU     9               ; name[21]
TPLAY   EQU     30              ; players[6], literally "cur / max"
TMAXN   EQU     28              ; as many as the 1K window holds
TCAP    EQU     1+TMAXN*TSTRIDE

; ---- the requests url.inc builds; 0 is /tables, so a cleared request is
; never mistaken for a /state (Channel F's seventh rule) ----
REQ_TABLES EQU  0
REQ_STATE  EQU  1
REQ_READY1 EQU  2
REQ_READY0 EQU  3
REQ_PLACE  EQU  4
REQ_ATTACK EQU  5
REQ_LEAVE  EQU  6

; ---- N1: (lib/device/NDevice) ----
NDEV    EQU     71H
NCOPEN  EQU     4FH             ; 'O'
NCCLOSE EQU     43H             ; 'C'
NCREAD  EQU     52H             ; 'R'
NCSTAT  EQU     53H             ; 'S'
NMHTTPG EQU     0CH             ; open mode: HTTP GET
NTRNONE EQU     0               ; no EOL translation
NSDEVST EQU     3               ; STATUS byte 3, nDevStatus_t: 1 is SUCCESS
NETTMO  EQU     100             ; seconds: past the cart's own 90 s for N:

; ---- appkeys on the FUJI device: the username every client in the family
; shares (creator 1, app 1, key 0). OPEN takes a 6-byte struct appkey as
; payload; READ answers a u16 length and then the value (rs232Fuji). ----
FNCAKOP EQU     0DCH
FNCAKRD EQU     0DDH
FNCAKWR EQU     0DEH
AKREAD  EQU     0
AKWRITE EQU     1
NAMEMAX EQU     8               ; the wire's name[9] holds 8

; ---- failure codes the screens show ----
FE_OPEN EQU     0E1H
FE_STAT EQU     0E2H
FE_READ EQU     0E3H
FE_LEN  EQU     0E4H

; ---- the board ----
NSHIPS  EQU     5               ; of 5, 4, 3, 3 and 2 (gameLogic.go SHIP_SIZES)
