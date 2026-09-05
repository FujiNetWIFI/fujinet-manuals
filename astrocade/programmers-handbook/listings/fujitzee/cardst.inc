; cardst.inc -- the scorecard's static geometry: the 16 row labels
; (drawn once per class entry, and by the DEMO screen), and the
; slot -> screen position map the value cells share.
;
; The card is two columns of eight rows: slots 0-7 (ones..sixes, the
; upper total, the bonus) down the left, slots 8-15 (the seven lower
; rows and the running total) down the right. Labels sit at cols 0 and
; 8; values at cols 4 and 12.

; CATPOS: slot A (0-15) -> D = screen row, E = value column. Preserves
; BC. Clobbers A,HL.
CATPOS: PUSH    BC
        LD      C,A
        LD      B,0
        LD      HL,CATROW
        ADD     HL,BC
        LD      D,(HL)
        LD      E,4
        LD      A,C
        CP      8
        JR      C,CATP9
        LD      E,12
CATP9:  POP     BC
        RET

; CARDST: the 16 labels, in slot order.
CARDST: LD      HL,CATLBL
        XOR     A
        LD      (V_CAT),A
CST1:   LD      A,(V_CAT)
        CP      16
        RET     NC
        PUSH    HL
        CALL    CATPOS
        LD      A,E
        SUB     4               ; the label column: 4 -> 0, 12 -> 8
        LD      E,A
        POP     HL
        LD      C,XWONF
        CALL    TXTAT           ; leaves HL at the NUL
        INC     HL
        LD      A,(V_CAT)
        INC     A
        LD      (V_CAT),A
        JR      CST1

CATROW: DB      1,2,3,4,5,6,7,8
        DB      1,2,3,4,5,6,7,8

CATLBL: DB      "ONE",0,"TWO",0,"THR",0,"FOU",0
        DB      "FIV",0,"SIX",0,"UP",0,"BON",0
        DB      "SET3",0,"SET4",0,"HOUS",0,"SRUN",0
        DB      "LRUN",0,"CNT",0,"FUJI",0,"TOT",0
