; state.inc -- the wire format and the device numbers, as equates.
;
; The server's ?bin=1 layout (util.go): fixed-length strings padded with NULs
; and one byte longer than their text, u16 little-endian, everything lower
; case. Nothing is parsed into RAM: the screens index the reply window.

; ---- /state, /move/<code>: a Game ----
GLAST   EQU     0               ; lastResult[81]
GROUND  EQU     81              ; 0 waiting, 1-4 the streets, 5 the showdown
GPOT    EQU     82              ; u16
GACTPL  EQU     84              ; the player to act, $FF nobody
GMVTIM  EQU     85              ; seconds that player has left
GVIEW   EQU     86              ; 1: the table was full, we are watching
GMVCNT  EQU     87              ; moves offered (to us, on our turn)
GMOVES  EQU     88              ; 5 x { code[3], name[10] }
MVSTRID EQU     13
MVCODE  EQU     0               ; two letters, the /move/<code> path
MVNAME  EQU     3               ; "fold", "raise 10"
GPLCNT  EQU     153
GPLYRS  EQU     154             ; players, PSTRIDE apart; we are index 0
PSTRIDE EQU     33
PNAME   EQU     0               ; name[9]
PSTAT   EQU     9               ; 0 waiting, 1 playing, 2 folded, 3 left
PBET    EQU     10              ; u16
PMOVE   EQU     12              ; move[8], the seat's last action
PPURSE  EQU     20              ; u16
PHAND   EQU     22              ; 5 cards x rank,suit then a NUL; "??" hidden
GMINLEN EQU     154             ; through playerCount, nobody seated
GMAXLEN EQU     GMINLEN+8*PSTRIDE
GMAXPL  EQU     8

; ---- /tables: a count byte, then Tables ----
TSTRIDE EQU     36
TID     EQU     0               ; id[9]
TNAME   EQU     9               ; name[21]
TPLAY   EQU     30              ; players[6], literally "cur / max"
TMAXN   EQU     28              ; as many as the 1K window holds
TCAP    EQU     1+TMAXN*TSTRIDE

; ---- the requests url.inc builds ----
REQ_TABLES EQU  0
REQ_STATE  EQU  1
REQ_MOVE   EQU  2
REQ_LEAVE  EQU  3

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

; ---- app glyphs ($80-$9F, cards.inc) ----
G_BACKL EQU     80H             ; a hidden card, left and right cells
G_BACKR EQU     81H
