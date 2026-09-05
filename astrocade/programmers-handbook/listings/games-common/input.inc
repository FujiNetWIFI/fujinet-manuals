; input.inc -- keypad and hand-controller scanning.
;
; The 24-key keypad reads as four column ports (KEY0 14H rightmost ..
; KEY3 17H leftmost), active-high bits 0-5; the player 1 handle is port
; 10H, active-high U/D/L/R/T in bits 0-4. Both are folded into one code
; space: '0'-'9', 'E' (the CE key), '.', and U/D/L/R/T -- the keypad's own
; up/down keys return the same 'U'/'D' as the stick, so list navigation
; needs no special cases. Codes are edge-detected against V_KEY: a key
; reports once per press.

; KEYSCN: A = freshly pressed code, or 0. Clobbers A,B,C,D,E,HL.
KEYSCN: CALL    KEYRAW
        LD      HL,V_KEY
        CP      (HL)
        JR      NZ,KSNEW
        XOR     A               ; held: already reported
        RET
KSNEW:  LD      (HL),A
        OR      A
        RET

; KEYRAW: A = currently pressed code, or 0. First match wins.
KEYRAW: LD      HL,KEYMAP
        LD      B,3             ; three keypad columns carry mapped keys
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
        RET     NZ              ; pressed and mapped
KRB2:   DEC     E
        JR      NZ,KRBIT
        DJNZ    KRCOL
        IN      A,(SW0)         ; the stick
        AND     1FH
        RET     Z
        LD      D,A             ; keep only the lowest set bit, so a
        NEG                     ; diagonal cannot look like two keys
        AND     D
        LD      HL,STKMAP
KRSTK:  SRL     A
        JR      C,KRSTK1
        INC     HL
        JR      KRSTK
KRSTK1: LD      A,(HL)
        RET

; Column port, then the six bit codes (bit 0 first; 0 = unmapped).
KEYMAP: DB      KEY3
        DB      0,0,'7','4','1','E'     ; C MR 7 4 1 CE
        DB      KEY2
        DB      'U',0,'8','5','2','0'   ; up MS 8 5 2 0
        DB      KEY1
        DB      'D',0,'9','6','3','.'   ; down CH 9 6 3 .
STKMAP: DB      'U','D','L','R','T'
