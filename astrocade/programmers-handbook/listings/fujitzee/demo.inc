; demo.inc -- static mock play screen, assembled when DEMO=1.
;
; M1 scaffolding: exercises every drawing path with zero network -- the
; play-screen sketch from the plan, populated with a four-seat game in
; progress. This is where the palette, the dice, and the column
; geometry get tuned by screenshot; the live screens (screens.inc)
; replace it from M2 on.

DEMOSCR:
        CALL    CLRSCR
        CALL    CARDST          ; the real label geometry

; Row 0: the viewed player and the round.
        LD      HL,DMYOU
        LD      DE,0*256+0
        LD      C,XWONF
        CALL    TXTAT
        LD      HL,DMRD
        LD      DE,0*256+10
        LD      C,XWONF
        CALL    TXTAT

; The left column's values (col 4): white filled, black dashes, one
; red potential with its cell inverse two rows further down.
        LD      HL,DMVALS       ; (row, col, color, 3 chars + NUL) x N,
DMV1:   LD      A,(HL)          ; FF ends
        CP      0FFH
        JR      Z,DMV9
        LD      D,A
        INC     HL
        LD      E,(HL)
        INC     HL
        LD      C,(HL)
        INC     HL
        LD      B,3
        CALL    TXTN            ; leaves HL at the NUL
        INC     HL
        JR      DMV1
DMV9:

; The standings panel: four seats, the third on turn.
        LD      HL,DMNAM1
        LD      DE,1*256+17
        LD      C,XFONW         ; the viewed card's owner
        CALL    TXTAT
        LD      HL,DMNAM2
        LD      DE,2*256+17
        LD      C,XWONF
        CALL    TXTAT
        LD      HL,DMNAM3
        LD      DE,3*256+17
        LD      C,XWONF
        CALL    TXTAT
        LD      HL,DMNAM4
        LD      DE,4*256+17
        LD      C,XWONF
        CALL    TXTAT
        LD      HL,DMTOT1
        LD      DE,1*256+27
        LD      C,XWONF
        CALL    TXTAT
        LD      HL,DMTOT2
        LD      DE,2*256+27
        LD      C,XWONF
        CALL    TXTAT
        LD      HL,DMTOT3
        LD      DE,3*256+27
        LD      C,XWONF
        CALL    TXTAT
        LD      HL,DMTOT4
        LD      DE,4*256+27
        LD      C,XWONF
        CALL    TXTAT
        LD      HL,DMTURN
        LD      DE,3*256+32
        LD      C,XRONF
        CALL    TXTAT

; Row 9: the your-turn banner.
        LD      HL,DMBANR
        LD      DE,9*256+6
        LD      C,XRONF
        CALL    TXTAT

; The dice strip: ROLL tile, five faces, hold markers.
        LD      HL,DMROLL
        LD      DE,10*256+1
        LD      C,XFONW         ; the dice cursor parked on ROLL
        CALL    TXTAT
        LD      HL,DMX2
        LD      DE,11*256+1
        LD      C,XWONF
        CALL    TXTAT
        XOR     A
        LD      (V_TM2),A
DMD1:   LD      A,(V_TM2)
        CP      5
        JR      NC,DMD9
        LD      HL,DMFACE
        LD      E,A
        LD      D,0
        ADD     HL,DE
        LD      A,(HL)
        LD      (V_FACE),A
        LD      A,(V_TM2)
        CALL    DIEADDR
        LD      A,(V_FACE)
        CALL    DIEDRW
        LD      A,(V_TM2)
        INC     A
        LD      (V_TM2),A
        JR      DMD1
DMD9:   LD      HL,DMHLD
        LD      DE,12*256+13
        LD      C,XRONF
        CALL    TXTAT
        LD      HL,DMHLD
        LD      DE,12*256+23
        LD      C,XRONF
        CALL    TXTAT
        LD      HL,DMHLD
        LD      DE,12*256+28
        LD      C,XRONF
        CALL    TXTAT

; Row 14: the prompt and the clock.
        LD      HL,DMPRM
        LD      DE,14*256+0
        LD      C,XWONF
        CALL    TXTAT
        LD      HL,DMCLK
        LD      DE,14*256+37
        LD      C,XRONF
        CALL    TXTAT
        RET

DMYOU:  DB      "ASTRO",0
DMRD:   DB      "RD  5/13",0
DMBANR: DB      "YOUR TURN - ROLL OR SCORE",0
DMROLL: DB      "ROLL",0
DMX2:   DB      " X2",0
DMHLD:  DB      "HLD",0
DMPRM:  DB      "ROLL 2. KEEP OR SCORE",0
DMCLK:  DB      "45",0
DMNAM1: DB      "ASTRO",0
DMNAM2: DB      "MOZZWALD",0
DMNAM3: DB      "ERICJ",0
DMNAM4: DB      "THOM",0
DMTOT1: DB      "86",0
DMTOT2: DB      "92",0
DMTOT3: DB      "71",0
DMTOT4: DB      "64",0
DMTURN: DB      "TURN",0
DMFACE: DB      3,5,2,6,1

; (row, col, color, three cells) per value cell; FF ends.
DMVALS: DB      1,4,XWONF,"  3",0
        DB      2,4,XWONF,"  6",0
        DB      3,4,XRONF," 15",0      ; an open row's potential
        DB      4,4,XWONF," 12",0
        DB      5,4,XKONF,"  -",0
        DB      6,4,XWONF," 18",0
        DB      7,4,XWONF," 39",0
        DB      8,4,XKONF,"  -",0
        DB      1,12,XWONF," 24",0
        DB      2,12,XFONW," 17",0     ; the score cursor's cell
        DB      3,12,XWONF," 25",0
        DB      4,12,XKONF,"  -",0
        DB      5,12,XWONF," 40",0
        DB      6,12,XKONF,"  -",0
        DB      7,12,XKONF,"  -",0
        DB      8,12,XWONF,"128",0
        DB      0FFH
