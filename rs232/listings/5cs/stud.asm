;=====================================================================
; STUD.ASM -- FujiNet 5 Card Stud for a terminal or Teletype
;
; A client for the FujiNet Game System's 5 Card Stud server.  Every
; exchange is one HTTPS GET through network unit 1; the server answers
; in its fixed-width binary form (&bin=1), so the state is read by
; offset with no parsing.  The table is printed as plain scrolling
; text, and only when something has changed, so it suits an ASR-33 as
; well as a glass terminal.
;
; Hardware lives in ALTAIR.INC (88-2SIO: terminal on port A, FujiNet
; on port B); the packet layer is FUJIBUS.INC.
; Assemble:  z88dk-z80asm -b stud.asm
;      (add -DDEVTABLES to list the server's hidden developer tables)
;=====================================================================

        ORG     0100h

NET     EQU     71h             ; network unit 1 (N1:)
RESPMAX EQU     512             ; largest server reply we keep

; Offsets into the binary game state (the server's util.go)
G_LAST  EQU     0               ; last result text, 80 + NUL
G_ROUND EQU     81              ; 0 waiting, 1-4 betting, 5 game over
G_POT   EQU     82              ; u16
G_ACTV  EQU     84              ; active player, signed; 0 = you
G_TIME  EQU     85              ; seconds left to move
G_VIEW  EQU     86              ; 1 = table full, you are watching
G_NMOVE EQU     87              ; valid moves that follow
G_MOVES EQU     88              ; 5 x 13: code 2+NUL, name 9+NUL
G_NPLAY EQU     153             ; players that follow
G_PLAY  EQU     154             ; players, 33 bytes each:
P_NAME  EQU     0               ;   name 8 + NUL
P_STAT  EQU     9               ;   0 waiting, 1 in, 2 folded, 3 left
P_BET   EQU     10              ;   u16
P_MOVE  EQU     12              ;   last move 7 + NUL
P_PURSE EQU     20              ;   u16
P_HAND  EQU     22              ;   cards, 2 chars each, 10 + NUL
P_SIZE  EQU     33

START:  LD      SP,STACK
        CALL    PINIT
        CALL    PRINT
        DEFB    13,10,"FUJINET 5 CARD STUD",13,10,0
        CALL    PRINT
        DEFB    "YOUR NAME? ",0
        LD      HL,NAME
        LD      B,8
        CALL    GETLN
        LD      A,B
        OR      A
        JR      NZ,ST1
        LD      HL,DEFNAME      ; nothing typed: a default
        LD      DE,NAME
        CALL    STRCPY
ST1:    LD      HL,NAME         ; spaces become '+' in a URL
ST2:    LD      A,(HL)
        OR      A
        JR      Z,TABLES
        CP      ' '
        JR      NZ,ST3
        LD      (HL),'+'
ST3:    INC     HL
        JR      ST2

;=====================================================================
; The table list
;=====================================================================
TABLES: LD      DE,URLBUF       ; base + "tables?bin=1"
        LD      HL,BASE
        CALL    STRCPY
        LD      HL,QTABLES
        CALL    STRCPY
        CALL    HTTPGET
        JP      C,NETFAIL
        CALL    PRINT
        DEFB    13,10,"TABLES",13,10,0
        LD      HL,RESP         ; 1 byte count, then 36-byte records:
        LD      A,(HL)          ;   id 8+NUL, name 20+NUL, "p / m"+NUL
        OR      A
        JP      Z,NETFAIL
        CP      10              ; the server sends at most ten
        JR      C,TB0
        LD      A,10
TB0:    LD      (NTABLE),A
        INC     HL
        LD      C,1
TB1:    PUSH    HL
        LD      L,C
        LD      H,0
        LD      B,3
        CALL    PRDECW
        POP     HL
        CALL    SPACE
        CALL    SPACE
        PUSH    HL
        LD      DE,9            ; the name, padded to 22 columns
        ADD     HL,DE
        LD      B,20
        CALL    PRUPN
        LD      A,22
        SUB     B
        LD      B,A
        CALL    SPACES
        POP     HL
        PUSH    HL
        LD      DE,30           ; the player count
        ADD     HL,DE
        LD      B,6
        CALL    PRUPN
        CALL    CRLF
        POP     HL
        LD      DE,36
        ADD     HL,DE
        LD      A,(NTABLE)
        CP      C
        JR      Z,TB2
        INC     C
        JR      TB1
TB2:    CALL    PRINT
        DEFB    "TABLE NUMBER (RETURN TO QUIT)? ",0
        LD      HL,LINE
        LD      B,3
        CALL    GETLN
        LD      A,B
        OR      A
        JP      Z,PEXIT
        LD      A,(NTABLE)
        LD      C,A
        CALL    PARSE
        JR      C,TB2
        LD      L,A             ; TABLE = the chosen record's id
        LD      H,0
        LD      DE,36
        CALL    MUL16
        LD      DE,RESP+1
        ADD     HL,DE
        LD      DE,TABLE
        CALL    STRCPY
        XOR     A
        LD      (PEND),A        ; no move waiting to be sent
        LD      (LASTLEN),A
        LD      (LASTLEN+1),A

;=====================================================================
; The game loop: fetch the state (or send a move), show it if it has
; changed, and either ask for a move or wait a second.
;=====================================================================
GLOOP:  LD      DE,URLBUF
        LD      HL,BASE
        CALL    STRCPY
        LD      A,(PEND)        ; a move to send?
        OR      A
        JR      Z,GL1
        LD      HL,QMOVE        ; "move/" + code
        CALL    STRCPY
        LD      HL,(PEND+1)
        CALL    STRCPY
        XOR     A
        LD      (PEND),A
        JR      GL2
GL1:    LD      HL,QSTATE       ; "state"
        CALL    STRCPY
GL2:    CALL    QUERY           ; "?table=..&player=..&bin=1"
        CALL    HTTPGET
        JR      NC,GL3
        CALL    PRINT
        DEFB    "NETWORK ERROR, TRYING AGAIN",13,10,0
        JR      GWAIT
GL3:    CALL    REPORT
        LD      A,(RESP+G_ACTV) ; my turn?
        OR      A
        JR      NZ,GWAIT
        LD      A,(RESP+G_VIEW)
        OR      A
        JR      NZ,GWAIT
        LD      A,(RESP+G_NMOVE)
        OR      A
        JR      Z,GWAIT
        CALL    ASKMOVE         ; Q (leave) returns carry set
        JR      C,LEAVE
        JR      GLOOP

GWAIT:  LD      B,100           ; about a second, watching for Q
GW1:    CALL    CONST
        JR      Z,GW2
        CALL    GETKEY
        CP      'Q'
        JR      Z,LEAVE
GW2:    LD      A,1
        CALL    DELAY
        DJNZ    GW1
        JP      GLOOP

LEAVE:  LD      DE,URLBUF       ; base + "leave" + query
        LD      HL,BASE
        CALL    STRCPY
        LD      HL,QLEAVE
        CALL    STRCPY
        CALL    QUERY
        CALL    HTTPGET
        CALL    PRINT
        DEFB    "YOU LEAVE THE TABLE.",13,10,0
        JP      TABLES

NETFAIL:CALL    PRINT
        DEFB    "CANNOT REACH THE SERVER.",13,10,0
        JP      PEXIT

; QUERY -- append "?table=<TABLE>&player=<NAME>&bin=1" at DE
QUERY:  LD      HL,QTABLE
        CALL    STRCPY
        LD      HL,TABLE
        CALL    STRCPY
        LD      HL,QPLAYER
        CALL    STRCPY
        LD      HL,NAME
        CALL    STRCPY
        LD      HL,QBIN
        JP      STRCPY

;=====================================================================
; REPORT -- tell the player what has happened since the last state.
; A new round (or the first look at the table) prints the whole table;
; otherwise each player whose bet or move changed gets one line, so a
; Teletype is not kept busy reprinting the table after every bot move.
;=====================================================================
REPORT: LD      HL,(LASTLEN)    ; first state at this table?
        LD      A,H
        OR      L
        JR      Z,RPFULL
        LD      A,(LAST+G_ROUND) ; a new round?
        LD      HL,RESP+G_ROUND
        CP      (HL)
        JR      NZ,RPFULL
        LD      A,(LAST+G_NPLAY) ; someone came or went?
        LD      HL,RESP+G_NPLAY
        CP      (HL)
        JR      NZ,RPFULL
        OR      A
        JR      Z,RPRES
        LD      B,A
        LD      HL,RESP+G_PLAY
        LD      DE,LAST+G_PLAY
RP1:    PUSH    BC
        PUSH    HL
        PUSH    DE
        LD      BC,P_BET        ; compare bet (2) and move (8)
        ADD     HL,BC
        EX      DE,HL
        ADD     HL,BC
        EX      DE,HL
        LD      B,10
RP2:    LD      A,(DE)
        CP      (HL)
        JR      NZ,RP3
        INC     HL
        INC     DE
        DJNZ    RP2
        JR      RP4
RP3:    POP     DE              ; changed: one line for this player
        POP     HL
        PUSH    HL
        PUSH    DE
        CALL    EVENT
RP4:    POP     DE
        POP     HL
        LD      BC,P_SIZE
        ADD     HL,BC
        EX      DE,HL
        ADD     HL,BC
        EX      DE,HL
        POP     BC
        DJNZ    RP1
RPRES:  LD      HL,RESP+G_LAST  ; a new result line?
        LD      DE,LAST+G_LAST
        LD      B,81
RP5:    LD      A,(DE)
        CP      (HL)
        JR      NZ,RP6
        INC     HL
        INC     DE
        DJNZ    RP5
        JR      RPCOPY
RP6:    LD      A,(RESP+G_LAST)
        OR      A
        JR      Z,RPCOPY
        LD      HL,RESP+G_LAST
        LD      B,80
        CALL    PRUPN
        CALL    CRLF
RPCOPY: LD      HL,RESP         ; this state becomes the last one
        LD      DE,LAST
        LD      BC,(RESPLEN)
        LD      (LASTLEN),BC
        LDIR
        RET
RPFULL: CALL    SHOW
        JR      RPCOPY

; EVENT -- one line for the player record at HL: name, move, bet
EVENT:  PUSH    HL
        LD      DE,P_MOVE
        ADD     HL,DE
        LD      A,(HL)          ; no move (a new round clears them)
        POP     HL
        OR      A
        RET     Z
        CALL    SPACE
        CALL    SPACE
        LD      B,8
        CALL    PRUPN
        LD      A,10
        SUB     B
        LD      B,A
        CALL    SPACES
        PUSH    HL
        LD      DE,P_MOVE
        ADD     HL,DE
        LD      B,7
        CALL    PRUPN
        LD      A,7             ; then the bet, right-aligned
        SUB     B
        LD      B,A
        CALL    SPACES
        LD      DE,P_BET-P_MOVE
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        POP     HL
        EX      DE,HL
        LD      B,5
        CALL    PRDECW
        JP      CRLF

;=====================================================================
; SHOW -- print the table
;=====================================================================
SHOW:   CALL    CRLF
        LD      A,(RESP+G_ROUND)
        OR      A
        JR      NZ,SH1
        CALL    PRINT           ; round 0: waiting for players
        DEFB    "WAITING FOR MORE PLAYERS",13,10,0
        JR      SH2
SH1:    CP      5
        JR      NZ,SH1A
        CALL    PRINT           ; round 5: the cards are turned over
        DEFB    "SHOWDOWN",0
        JR      SH1B
SH1A:   CALL    PRINT
        DEFB    "ROUND ",0
        LD      A,(RESP+G_ROUND)
        LD      L,A
        LD      H,0
        CALL    PRDEC
SH1B:   CALL    PRINT
        DEFB    "   POT ",0
        LD      HL,(RESP+G_POT)
        CALL    PRDEC
        CALL    CRLF
SH2:    LD      A,(RESP+G_NPLAY)
        OR      A
        JP      Z,SH9
        LD      B,A
        LD      C,0             ; C = player index
        LD      HL,RESP+G_PLAY
SH3:    PUSH    BC
        PUSH    HL
        LD      A,(RESP+G_ACTV) ; '>' marks whose turn it is
        CP      C
        LD      A,' '
        JR      NZ,SH4
        LD      A,'>'
SH4:    CALL    CONOUT
        CALL    SPACE
        LD      B,8             ; name, 10 columns
        CALL    PRUPN
        LD      A,10
        SUB     B
        LD      B,A
        CALL    SPACES
        POP     HL
        PUSH    HL
        LD      DE,P_PURSE      ; purse
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        EX      DE,HL
        LD      B,5
        CALL    PRDECW
        POP     HL
        PUSH    HL
        LD      DE,P_BET        ; bet
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        EX      DE,HL
        LD      B,5
        CALL    PRDECW
        CALL    SPACE
        CALL    SPACE
        POP     HL
        PUSH    HL
        LD      DE,P_HAND       ; the cards, "KS 9H ?? "
        ADD     HL,DE
        CALL    PRHAND
        POP     HL
        PUSH    HL
        LD      DE,P_MOVE       ; last move, or the player's status
        ADD     HL,DE
        LD      A,(HL)
        OR      A
        JR      Z,SH5
        LD      B,7
        CALL    PRUPN
        JR      SH7
SH5:    POP     HL
        PUSH    HL
        LD      DE,P_STAT
        ADD     HL,DE
        LD      A,(HL)
        OR      A
        JR      NZ,SH6
        CALL    PRINT
        DEFB    "WAITING",0
        JR      SH7
SH6:    CP      3
        JR      NZ,SH7
        CALL    PRINT
        DEFB    "LEFT",0
SH7:    CALL    CRLF
        POP     HL
        LD      DE,P_SIZE
        ADD     HL,DE
        POP     BC
        INC     C
        DEC     B
        JP      NZ,SH3
SH9:    LD      A,(RESP+G_ROUND) ; the result line belongs to round 5
        OR      A               ;   (and to round 0, where it says who
        JR      Z,SH10          ;   is still awaited)
        CP      5
        RET     NZ
SH10:   LD      A,(RESP+G_LAST)
        OR      A
        RET     Z
        LD      HL,RESP+G_LAST
        LD      B,80
        CALL    PRUPN
        JP      CRLF

; PRHAND -- print the hand at HL as "KS 9H ?? ", padded to 16 columns
PRHAND: LD      B,16
PH1:    LD      A,(HL)
        OR      A
        JR      Z,PH2
        CALL    UCASE
        CALL    CONOUT
        INC     HL
        LD      A,(HL)
        CALL    UCASE
        CALL    CONOUT
        INC     HL
        CALL    SPACE
        DEC     B
        DEC     B
        DEC     B
        JR      PH1
PH2:    JP      SPACES

; PRUPN -- print at most B characters of the string at HL in upper
; case; on return B = the number printed (C, DE, HL preserved)
PRUPN:  PUSH    HL
        PUSH    DE
        LD      D,B             ; D = characters still allowed
        LD      B,0
PU1:    LD      A,D
        OR      A
        JR      Z,PU2
        LD      A,(HL)
        OR      A
        JR      Z,PU2
        CALL    UCASE
        CALL    CONOUT
        INC     HL
        INC     B
        DEC     D
        JR      PU1
PU2:    POP     DE
        POP     HL
        RET

;=====================================================================
; ASKMOVE -- list the valid moves and wait for a choice, no longer
; than the server's move timer.  Carry set if the player typed Q.
;=====================================================================
ASKMOVE:CALL    PRINT
        DEFB    "YOUR CARDS ",0
        LD      HL,RESP+G_PLAY+P_HAND
        CALL    PRHAND
        CALL    PRINT
        DEFB    "POT ",0
        LD      HL,(RESP+G_POT)
        CALL    PRDEC
        CALL    PRINT
        DEFB    13,10,"YOUR MOVE:",0
        LD      A,(RESP+G_NMOVE)
        CP      6
        JR      C,AM1
        LD      A,5
AM1:    LD      B,A
        LD      C,'1'
        LD      HL,RESP+G_MOVES
AM2:    CALL    SPACE
        CALL    SPACE
        LD      A,C
        CALL    CONOUT
        CALL    SPACE
        PUSH    HL
        PUSH    BC
        INC     HL              ; the name follows the 3-byte code
        INC     HL
        INC     HL
        LD      B,9
        CALL    PRUPN
        POP     BC
        POP     HL
        LD      DE,13
        ADD     HL,DE
        INC     C
        DJNZ    AM2
        CALL    PRINT
        DEFB    "  Q LEAVE? ",0
        LD      A,(RESP+G_TIME) ; wait up to the move timer
        OR      A
        JR      NZ,AM3
        LD      A,1
AM3:    LD      D,A             ; D seconds of 100 x 10 ms
AM4:    LD      E,100
AM5:    CALL    CONST
        JR      NZ,AM6
        LD      A,1
        CALL    DELAY
        DEC     E
        JR      NZ,AM5
        DEC     D
        JR      NZ,AM4
        CALL    PRINT           ; out of time: the server moves for us
        DEFB    "TOO SLOW",13,10,0
        OR      A
        RET
AM6:    CALL    GETKEY
        CP      'Q'
        JR      NZ,AM7
        CALL    CONOUT
        CALL    CRLF
        SCF
        RET
AM7:    SUB     '1'             ; a move number?
        JR      C,AM5
        LD      HL,RESP+G_NMOVE
        CP      (HL)
        JR      NC,AM5
        PUSH    AF
        ADD     A,'1'
        CALL    CONOUT
        CALL    CRLF
        POP     AF
        LD      L,A             ; PEND+1 = address of that move's code
        LD      H,0
        LD      DE,13
        CALL    MUL16
        LD      DE,LAST+G_MOVES ; (REPORT copied this state to LAST;
        ADD     HL,DE           ;  RESP is overwritten by the fetch)
        LD      (PEND+1),HL
        LD      A,1
        LD      (PEND),A
        OR      A
        RET

;=====================================================================
; HTTPGET -- GET the devicespec in URLBUF into RESP (RESPLEN bytes).
; OPEN, then STATUS / READ until the server's reply is used up (EOF),
; then CLOSE.  Carry set on failure.
;=====================================================================
HTTPGET:LD      HL,0
        LD      (RESPLEN),HL
; OPEN ('O'): p0 = 12 (HTTP GET), p1 = 0 (no translation)
        LD      A,NET
        LD      C,'O'
        LD      B,02h
        CALL    FBNEW
        LD      A,12
        CALL    FBBYTE
        XOR     A
        CALL    FBBYTE
        LD      HL,URLBUF
        CALL    STRLEN
        INC     BC              ; and the NUL
        CALL    FBMEM
        LD      A,80            ; DNS + TLS: allow 20 s
        LD      (FBWAIT),A
        CALL    FBCALL
        LD      A,40
        LD      (FBWAIT),A
        RET     C
        SCF
        RET     NZ              ; NAK
        LD      A,200           ; at most ~200 empty polls
        LD      (POLLS),A
HG1:    LD      A,NET           ; STATUS ('S') -> avail, conn, err
        LD      C,'S'
        LD      B,00h
        CALL    FBNEW
        CALL    FBCALL
        JR      C,HGX
        JR      NZ,HGX
        LD      E,(HL)          ; DE = bytes waiting
        INC     HL
        LD      D,(HL)
        INC     HL
        INC     HL
        LD      A,D
        OR      E
        JR      NZ,HG3
        LD      A,(HL)          ; nothing waiting: 136 = end of file
        CP      136
        JR      Z,HGOK
        LD      A,(POLLS)
        DEC     A
        LD      (POLLS),A
        JR      Z,HGX
        LD      A,5             ; give the server 50 ms
        CALL    DELAY
        JR      HG1
HG3:    LD      HL,RESPMAX      ; room left = RESPMAX - RESPLEN
        LD      BC,(RESPLEN)
        OR      A
        SBC     HL,BC
        JR      Z,HGX           ; full: the reply is too big
        OR      A               ; ask for min(waiting, room)
        SBC     HL,DE
        ADD     HL,DE
        JR      NC,HG4
        EX      DE,HL           ; room < waiting
HG4:    PUSH    DE
        LD      A,NET           ; READ ('R'): p0 = count (u16)
        LD      C,'R'
        LD      B,05h
        CALL    FBNEW
        POP     HL
        CALL    FBWORD
        CALL    FBCALL
        JR      C,HGX
        JR      NZ,HGX
        PUSH    BC              ; append the bytes to RESP
        LD      DE,(RESPLEN)
        PUSH    HL
        LD      HL,RESP
        ADD     HL,DE
        EX      DE,HL
        POP     HL
        LD      A,B
        OR      C
        JR      Z,HG5
        LDIR
HG5:    POP     BC
        LD      HL,(RESPLEN)
        ADD     HL,BC
        LD      (RESPLEN),HL
        JR      HG1
HGOK:   CALL    HCLOSE
        OR      A
        RET
HGX:    CALL    HCLOSE
        SCF
        RET
HCLOSE: LD      A,NET           ; CLOSE ('C')
        LD      C,'C'
        LD      B,00h
        CALL    FBNEW
        JP      FBCALL

;=====================================================================
; String helpers
;=====================================================================

; STRCPY -- copy the string at HL to DE with its NUL; DE is left on
; the copied NUL, so a second STRCPY appends
STRCPY: LD      A,(HL)
        LD      (DE),A
        OR      A
        RET     Z
        INC     HL
        INC     DE
        JR      STRCPY

; STRLEN -- BC = length of the string at HL
STRLEN: PUSH    HL
        LD      BC,0
SL1:    LD      A,(HL)
        OR      A
        JR      Z,SL2
        INC     HL
        INC     BC
        JR      SL1
SL2:    POP     HL
        RET

; PARSE -- the decimal number in LINE, 1..C -> A = number - 1;
; carry set if blank, not a number, or out of range
PARSE:  LD      HL,LINE
        LD      B,0
PA1:    LD      A,(HL)
        OR      A
        JR      Z,PA2
        SUB     '0'
        RET     C
        CP      10
        CCF
        RET     C
        LD      D,A
        LD      A,B
        ADD     A,A
        LD      E,A
        ADD     A,A
        ADD     A,A
        ADD     A,E
        ADD     A,D
        LD      B,A
        INC     HL
        JR      PA1
PA2:    LD      A,B
        OR      A
        SCF
        RET     Z
        CP      C
        JR      Z,PA3
        CCF
        RET     C
PA3:    DEC     A
        OR      A
        RET

; MUL16 -- HL = HL x DE
MUL16:  PUSH    BC
        LD      B,H
        LD      C,L
        LD      HL,0
        LD      A,16
MU1:    ADD     HL,HL
        EX      DE,HL
        ADD     HL,HL
        EX      DE,HL
        JR      NC,MU2
        ADD     HL,BC
MU2:    DEC     A
        JR      NZ,MU1
        POP     BC
        RET

;=====================================================================
; The server and its requests
;=====================================================================
BASE:   DEFB    "N:HTTPS://5card.carr-designs.com/",0
        IF      DEVTABLES
QTABLES:DEFB    "tables?bin=1&dev=1",0
        ELSE
QTABLES:DEFB    "tables?bin=1",0
        ENDIF
QSTATE: DEFB    "state",0
QMOVE:  DEFB    "move/",0
QLEAVE: DEFB    "leave",0
QTABLE: DEFB    "?table=",0
QPLAYER:DEFB    "&player=",0
QBIN:   DEFB    "&bin=1",0
DEFNAME:DEFB    "ALTAIR",0

        INCLUDE "../common/altair.inc"
        INCLUDE "../common/conio.inc"
        INCLUDE "../common/fujibus.inc"

;=====================================================================
; Variables and buffers
;=====================================================================
NTABLE: DEFB    0
POLLS:  DEFB    0
PEND:   DEFB    0               ; 1 = a move is waiting to be sent,
        DEFW    0               ;   and the address of its code
NAME:   DEFS    9
TABLE:  DEFS    9
LINE:   DEFS    4
RESPLEN:DEFW    0
LASTLEN:DEFW    0
URLBUF: DEFS    128
RESP:   DEFS    RESPMAX
LAST:   DEFS    RESPMAX
        DEFS    256
STACK:
