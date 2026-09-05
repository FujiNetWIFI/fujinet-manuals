; demo.inc -- static mock table, assembled when DEMO=1.
;
; Exercises every drawing path with zero network: the layout, populated
; with a full 8-player Hold'em table. This is where the palette, the card
; art and the cell geometry get checked by screenshot, so the coordinates
; here are the same ones screens.inc's tables carry -- if you move a seat
; there, move it here.
;
; Rows: 0 table name | 1 top names | 2 top hands + their bets | 5 mid
; names/bets + the street | 6 mid hands + the community board | 9 bottom
; hands | 12 bottom names/bets | 13 purse, bet, pot, clock | 14 the bar.

DEMOSCR:
        CALL    CLRSCR
; Row 0: the table name.
        LD      HL,DTABLE
        LD      DE,0*256+0
        LD      C,XWONF
        CALL    TXTAT

; Top seats (3, 4, 5): names row 1, hands and bets row 2. Seat 4 is the
; active player: inverse name.
        LD      HL,DNAME3
        LD      DE,1*256+0
        LD      C,XWONF
        CALL    TXTAT
        LD      HL,DNAME4
        LD      DE,1*256+15
        LD      C,XFONW         ; inverse: the active player
        CALL    TXTAT
        LD      HL,DNAME5
        LD      DE,1*256+29
        LD      C,XWONF
        CALL    TXTAT

        LD      HL,DHAND3
        LD      DE,2*256+0
        LD      B,2
        CALL    DRWHND
        LD      HL,DHAND4
        LD      DE,2*256+17
        LD      B,2
        CALL    DRWHND
        LD      HL,DHAND5
        LD      DE,2*256+33
        LD      B,2
        CALL    DRWHND

        LD      DE,2*256+6      ; seat 3's bet
        LD      HL,25
        CALL    DBET
        LD      DE,2*256+12     ; seat 4's bet
        LD      HL,150
        CALL    DBET
        LD      DE,2*256+28     ; seat 5's bet
        LD      HL,50
        CALL    DBET

; Middle seats (2 left, 6 right): names row 5, hands row 6. The street
; label and the community board own the middle of both rows.
        LD      HL,DNAME2
        LD      DE,5*256+0
        LD      C,XWONF
        CALL    TXTAT
        LD      HL,DNAME6
        LD      DE,5*256+31
        LD      C,XWONF
        CALL    TXTAT
        LD      DE,5*256+11     ; seat 2's bet
        LD      HL,25
        CALL    DBET
        LD      DE,5*256+24     ; seat 6's bet
        LD      HL,1250
        CALL    DBET

        LD      HL,DSTREET      ; the street, over the board
        LD      DE,5*256+16
        LD      C,XWONF
        LD      B,8
        CALL    TXTN

        LD      HL,DHAND2
        LD      DE,6*256+0
        LD      B,2
        CALL    DRWHND
        LD      HL,DHAND6
        LD      DE,6*256+35
        LD      B,2
        CALL    DRWHND

        LD      HL,DBOARD       ; five community cards, cols 14-24
        LD      DE,6*256+14
        LD      B,5
        CALL    DRWHND

; Bottom seats (1 left, 0 you center, 7 right): hands row 9, names row 12.
; Your own hand is the only one face up; seat 1 has folded, so it shows a
; single card back where the others show two.
        LD      HL,DHAND1
        LD      DE,9*256+0
        LD      B,2
        CALL    DRWHND
        LD      HL,DHAND0
        LD      DE,9*256+17
        LD      B,2
        CALL    DRWHND
        LD      HL,DHAND7
        LD      DE,9*256+33
        LD      B,2
        CALL    DRWHND
        LD      HL,DNAME1
        LD      DE,12*256+0
        LD      C,XWONF
        CALL    TXTAT
        LD      HL,DNAME0
        LD      DE,12*256+14
        LD      C,XWONF
        CALL    TXTAT
        LD      HL,DNAME7
        LD      DE,12*256+29
        LD      C,XWONF
        CALL    TXTAT
        LD      DE,12*256+9     ; seat 1's bet
        LD      HL,25
        CALL    DBET
        LD      DE,12*256+24    ; seat 7's bet
        LD      HL,50
        CALL    DBET

; Row 13: your purse and bet, the pot, and the move clock.
        LD      HL,DPURSE       ; drawn the way PURSE itself lays row 13
        LD      DE,13*256+0     ; out, so a screenshot checks the real cells
        LD      C,XWONF
        CALL    TXTAT
        LD      HL,340
        CALL    U16STR
        LD      HL,LINBUF
        LD      DE,13*256+6
        LD      C,XWONF
        LD      B,5
        CALL    TXTN
        LD      HL,DBETL
        LD      DE,13*256+12
        LD      C,XWONF
        CALL    TXTAT
        LD      HL,25
        CALL    U16STR
        LD      HL,LINBUF
        LD      DE,13*256+16
        LD      C,XWONF
        LD      B,5
        CALL    TXTN
        LD      HL,DPOT
        LD      DE,13*256+22
        LD      C,XWONF
        CALL    TXTAT
        LD      HL,1250
        CALL    U16STR
        LD      HL,LINBUF
        LD      DE,13*256+26
        LD      C,XWONF
        LD      B,5
        CALL    TXTN
        LD      HL,DCLOCK
        LD      DE,13*256+37
        LD      C,XRONF
        CALL    TXTAT

; Row 14: the status bar -- a white strip with the move menu in black.
; DMENU is the worst case the real BAR can produce: five moves at the
; 8-column stride, names already squeezed by MVCOMP, filling cols 0-39
; exactly. If this fits, every shorter menu does.
        LD      HL,NORMEM+14*240
        LD      B,6
        LD      C,BYTEPL
        LD      D,0FFH
        CALL    FILLRC
        LD      HL,DMENU
        LD      DE,14*256+0
        LD      C,XKONW
        CALL    TXTAT
        RET

; DBET: a chip at D,E with the amount in HL drawn just right of it.
DBET:   PUSH    HL
        PUSH    DE
        CALL    DRWCHP
        POP     DE
        POP     HL
        INC     E
        PUSH    DE
        CALL    U16STR
        POP     DE
        LD      HL,LINBUF
        LD      C,XWONF
        LD      B,4
        JP      TXTN

DTABLE: DB      "AI ROOM - 7 BOTS",0
DPOT:   DB      "POT",0
DSTREET: DB     "RIVER   ",0
DPURSE: DB      "PURSE",0
DBETL:  DB      "BET",0
DCLOCK: DB      "12",0
DMENU:  DB      "1 FOLD  2 CHECK 3 B10   4 B20   5 A500  ",0
DNAME0: DB      "YOU",0
DNAME1: DB      "MOZZWALD",0
DNAME2: DB      "ERICJ",0
DNAME3: DB      "THOM",0
DNAME4: DB      "JEFFP",0
DNAME5: DB      "ROGER",0
DNAME6: DB      "NORM",0
DNAME7: DB      "TSCHAK",0

DBOARD: DB      "7dkcac9s2h",0  ; the full five-card board
DHAND0: DB      "askh",0        ; yours, face up
DHAND1: DB      "??",0          ; folded: one card back
DHAND2: DB      "????",0
DHAND3: DB      "????",0
DHAND4: DB      "????",0
DHAND5: DB      "????",0
DHAND6: DB      "????",0
DHAND7: DB      "tdjc",0        ; a showdown reveal
