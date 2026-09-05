; fujinet.inc -- N: device, appkey commands, and the Texas Hold'em wire format.
;
; The command and offset values are hand-synchronised with o2/o2fuji.inc,
; which carries the family's documentation of WHY each one is what it is;
; this file only restates the numbers in zmac Z80 syntax. The mailbox
; transport itself is fujilib.inc.

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
                                ; has a readable body (o2/net.inc).

; ---- Fuji device appkeys ----------------------------------------------
FCOKEY  EQU     0DCH            ; OPEN_APPKEY
FCCKEY  EQU     0DBH            ; CLOSE_APPKEY
FCRKEY  EQU     0DDH            ; READ_APPKEY
FCWKEY  EQU     0DEH            ; WRITE_APPKEY

; Lobby appkey: creator 1 / app 1 / key 0 is the username shared by every
; FujiNet client on this server (src/misc.h).
AKCRLO  EQU     1
AKCRHI  EQU     0
AKAPP   EQU     1
AKKNAME EQU     0
AKMRD   EQU     0
AKMWR   EQU     1

; ---- Wire format (?bin=1, uint16 little-endian) -----------------------
; /state, /move/XX, /leave -> Game; /tables -> Tables. Offsets are read in
; place out of the reply slice window; nothing is buffered.
;
; Texas Hold'em delta from 5 Card Stud: community[11] is inserted right
; after viewing (offset 87), shifting everything from validMoveCount on by
; +11. The offsets are locked on the other side by the _Static_asserts in
; support/host-test/holdem_host_test.c against src/misc.h.
GOLASTR EQU     0               ; lastResult, 81 bytes
GOROUND EQU     81              ; 0 waiting, 1 PRE-FLOP, 2 FLOP, 3 TURN,
                                ; 4 RIVER, 5 SHOWDOWN
GOPOT   EQU     82              ; u16
GOACTPL EQU     84              ; signed, 0FFH = -1
GOMVTIM EQU     85              ; seconds
GOVIEW  EQU     86
GOCOMM  EQU     87              ; community board, 11 bytes: up to 5 cards
                                ; x 2 chars + NUL. Empty pre-flop, then 6 /
                                ; 8 / 10 chars at flop / turn / river.
GOMVCNT EQU     98
GOMOVES EQU     99              ; 5 slots, always
GOPLCNT EQU     164
GOPLYRS EQU     165

MVSTRID EQU     13
MVCODE  EQU     0               ; 3 bytes; the first 2 go in the /move/XX path
MVNAME  EQU     3               ; 10 bytes

PLSTRID EQU     33
PLNAME  EQU     0               ; 9 bytes
PLSTAT  EQU     9               ; 0 waiting, 1 playing, 2 folded, 3 left.
                                ; The bin=1 serializer folds all-in back
                                ; into 1, so 4 never reaches us.
PLBET   EQU     10              ; u16
PLMOVE  EQU     12              ; 8 bytes, the seat's last action
PLPURSE EQU     20              ; u16
PLHAND  EQU     22              ; 11 bytes, but Hold'em uses 4: the 2 hole
                                ; cards. "????" masked, "??" folded, the
                                ; real chars at the showdown. The field
                                ; keeps 5 Card Stud's width on the wire.

TBSTRID EQU     36
TBID    EQU     0               ; 9 bytes
TBNAME  EQU     9               ; 21 bytes
TBPLYRS EQU     30              ; 6 bytes, literal "cur / max"

GMAXLEN EQU     429
GMINLEN EQU     165             ; fixed prefix through playerCount, 0 players
TMAXLEN EQU     361
