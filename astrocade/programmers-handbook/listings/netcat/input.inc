; input.inc -- keypad and hand-controller scanning.
;
; The 24-key keypad reads as four column ports (KEY0 14H rightmost .. KEY3
; 17H leftmost), active-high bits 0-5; the player 1 handle is port 10H,
; active-high U/D/L/R/T in bits 0-4. Everything folds into one event space.
;
; The card ports mapped only the three columns their games needed. netcat is
; a terminal, so it wants every key it can get -- the whole matrix is here,
; decoded from MAME's astrohome.cpp the way fujinet-config does it.
;
; Pacing is a calibrated delay loop, not a frame counter: the program runs DI
; for its whole life (fujilib's contract) and the vertical-address feedback
; register is lightpen-latched and useless as a time base.
;
; Two entry points because the two callers want different things. The session
; loop takes INPOLL, edge only -- a key held down must not machine-gun the
; BBS. The grid keyboard takes INPOLR, which auto-repeats so a thumb on a
; direction walks the grid.

EVNONE  EQU     0
EVUP    EQU     1
EVDOWN  EQU     2
EVLEFT  EQU     3
EVRIGHT EQU     4
EVTRIG  EQU     5
EVCE    EQU     6               ; CE  -- backspace / delete
EVEQ    EQU     7               ; =   -- accept / send
EVDOT   EQU     8               ; .
EVCLR   EQU     9               ; C   -- hang up / cancel
EVMR    EQU     0AH             ; MR
EVMS    EQU     0BH             ; MS
EVCH    EQU     0CH             ; CH
EVPCT   EQU     0DH             ; %
EVDIV   EQU     0EH             ; /
EVMUL   EQU     0FH             ; x
EVMIN   EQU     10H             ; -
EVPLU   EQU     11H             ; +
EVD0    EQU     20H             ; digits: EVD0+n

INDLY   EQU     30              ; ~300 ms before a held key repeats
INRATE  EQU     8               ; ~80 ms between repeats

; INPOLL: A = a freshly pressed event, or EVNONE. No auto-repeat.
INPOLL: CALL    KEYRAW
        LD      HL,V_KEY
        CP      (HL)
        JR      NZ,IPNEW
        XOR     A               ; held: already reported
        RET

; INPOLR: as INPOLL, but a held key repeats after INDLY at INRATE. Assumes
; the caller paces itself with DELAY10.
INPOLR: CALL    KEYRAW
        LD      HL,V_KEY
        CP      (HL)
        JR      NZ,IPNEW
        OR      A
        RET     Z
        LD      HL,V_RPT
        DEC     (HL)
        JR      Z,IPRPT
        XOR     A               ; still counting down -- and A must be zeroed
        RET                     ; here, or the held key reads as a fresh press
IPRPT:  LD      (HL),INRATE
        LD      A,(V_KEY)
        CP      EVRIGHT+1       ; only the directions repeat: a held trigger
        RET     C               ; must not spray characters into the buffer
        XOR     A
        RET

IPNEW:  LD      (HL),A          ; HL = V_KEY
        LD      HL,V_RPT
        LD      (HL),INDLY
        LD      A,(V_KEY)
        OR      A
        RET

; INWAIT: block until an event arrives, with repeat. Returns it in A.
INWAIT: CALL    DELAY10
        CALL    INPOLR
        OR      A
        JR      Z,INWAIT
        RET

; DELAY10: about 10 ms. 745 iterations of a 26 T-state loop at 1.789 MHz,
; the figure fujinet-config calibrated. Clobbers A,D,E.
DELAY10: LD     DE,745
DLY1:   DEC     DE
        LD      A,D
        OR      E
        JR      NZ,DLY1
        RET

; KEYRAW: A = the event for whatever is pressed right now, or EVNONE.
; First match wins; a diagonal on the stick reduces to its lowest set bit so
; it cannot look like two keys. Clobbers A,B,C,D,E,H,L.
KEYRAW: LD      HL,KPTAB
        LD      B,4
KRCOL:  LD      C,(HL)
        INC     HL
        IN      A,(C)
        LD      D,A
        LD      E,6
KRBIT:  LD      A,(HL)
        INC     HL
        SRL     D
        JR      NC,KRB2
        OR      A
        RET     NZ              ; pressed, and mapped
KRB2:   DEC     E
        JR      NZ,KRBIT
        DJNZ    KRCOL
        IN      A,(SW0)         ; the stick
        AND     1FH
        RET     Z
        LD      D,A
        NEG
        AND     D
        LD      HL,STKMAP
KRSTK:  SRL     A
        JR      C,KRSTK1
        INC     HL
        JR      KRSTK
KRSTK1: LD      A,(HL)
        RET

; EVTOCH: A = event -> A = the character that key types, or 0 if it types
; nothing. Shared by the terminal (which sends it) and the grid keyboard
; (which inserts it), so the keypad means the same thing in both places.
; Clobbers D,E,H,L.
EVTOCH: CP      EVD0
        JR      C,ETC1
        SUB     EVD0
        CP      10
        JR      NC,ETCZ
        ADD     A,'0'
        RET
ETC1:   CP      EVPLU+1
        JR      NC,ETCZ
        LD      HL,EVCHR
        LD      E,A
        LD      D,0
        ADD     HL,DE
        LD      A,(HL)
        RET
ETCZ:   XOR     A
        RET

; Indexed by event code, EVNONE..EVPLU.
EVCHR:  DB      0,0,0,0,0,0     ; none, up, down, left, right, trigger
        DB      0               ; CE  -- backspace, not a character
        DB      0               ; =   -- accept, not a character
        DB      '.'
        DB      0               ; C   -- cancel, not a character
        DB      0               ; MR  -- ESC in the terminal, nothing here
        DB      0               ; MS  -- Ctrl-C in the terminal
        DB      ' '             ; CH
        DB      '%','/','*','-','+'

; Column port, then its six bit codes, bit 0 (bottom key) first.
KPTAB:  DB      KEY0
        DB      EVPCT,EVDIV,EVMUL,EVMIN,EVPLU,EVEQ      ; % / x - + =
        DB      KEY1
        DB      EVDOWN,EVCH,EVD0+9,EVD0+6,EVD0+3,EVDOT  ; v CH 9 6 3 .
        DB      KEY2
        DB      EVUP,EVMS,EVD0+8,EVD0+5,EVD0+2,EVD0     ; ^ MS 8 5 2 0
        DB      KEY3
        DB      EVCLR,EVMR,EVD0+7,EVD0+4,EVD0+1,EVCE    ; C MR 7 4 1 CE
STKMAP: DB      EVUP,EVDOWN,EVLEFT,EVRIGHT,EVTRIG
