; nament.inc -- the name-entry screen.
;
; Eight slots, edited with the stick (or the keypad's arrow keys): up and
; down turn the character wheel A-Z 0-9 then '-', left and right move the
; cursor, trigger accepts. '-' is the blank -- the wheel has no space, so
; a name can never need the '+' URL escape -- and everything from the
; first '-' on is dropped at accept. An all-blank name keeps the default.

NAMESCR: CALL   KEYRAW          ; no leaking presses from the OS menu
        LD      (V_KEY),A
        CALL    CLRSCR
        SYSSUK  STRDIS
        DB      16              ; "FUJITZEE": 8 chars x 16px, centred
        DB      0
        DB      4CH
        DW      TTITLE
        LD      HL,TNAME
        LD      DE,6*256+15
        LD      C,XWONF
        CALL    TXTAT
        LD      HL,TACCPT
        LD      DE,12*256+5
        LD      C,XWONF
        CALL    TXTAT
        LD      HL,PLNBUF       ; edit buffer = name padded with blanks
        LD      DE,NAMEED
        LD      B,8
NEINI:  LD      A,(HL)
        OR      A
        JR      Z,NEINI2
        LD      (DE),A
        INC     HL
        INC     DE
        DJNZ    NEINI
        JR      NEINI9
NEINI2: LD      A,'-'
NEINI3: LD      (DE),A
        INC     DE
        DJNZ    NEINI3
NEINI9: XOR     A
        LD      (V_NCUR),A
        CALL    NEDRAW
NEKEY:  CALL    KEYSCN
        OR      A
        JR      Z,NEKEY
        CP      'U'
        JR      NZ,NEK1
        LD      E,1             ; wheel forward
        JR      NEWHL
NEK1:   CP      'D'
        JR      NZ,NEK2
        LD      E,36            ; wheel back (mod 37)
        JR      NEWHL
NEK2:   CP      'L'
        JR      NZ,NEK3
        LD      A,(V_NCUR)
        OR      A
        JR      Z,NEKEY
        DEC     A
        LD      (V_NCUR),A
        JR      NEDRW
NEK3:   CP      'R'
        JR      NZ,NEK4
        LD      A,(V_NCUR)
        CP      7
        JR      NC,NEKEY
        INC     A
        LD      (V_NCUR),A
        JR      NEDRW
NEK4:   CP      'T'
        JR      NZ,NEKEY
        LD      HL,NAMEED       ; accept: copy up to the first '-'
        LD      DE,PLNBUF
        LD      B,8
NEACC:  LD      A,(HL)
        CP      '-'
        JR      Z,NEACC9
        LD      (DE),A
        INC     HL
        INC     DE
        DJNZ    NEACC
NEACC9: LD      A,E             ; empty name: keep what PLNBUF had
        CP      PLNBUF-4E00H    ; (its low byte; the buffer is in 4Exx)
        JR      Z,NEKEY
        XOR     A
        LD      (DE),A
        JP      SNDSEL          ; confirm cue, then back to the caller

NEWHL:  LD      A,(V_NCUR)      ; step the wheel at the cursor by E
        LD      HL,NAMEED
        PUSH    DE
        LD      E,A
        LD      D,0
        ADD     HL,DE
        POP     DE
        LD      A,(HL)
        PUSH    HL
        LD      HL,WHEEL        ; find its wheel index
        LD      B,0
NEWH1:  CP      (HL)
        JR      Z,NEWH2
        INC     HL
        INC     B
        JR      NEWH1
NEWH2:  LD      A,B
        ADD     A,E             ; +1 or +36
NEWH3:  CP      37
        JR      C,NEWH4
        SUB     37
        JR      NEWH3
NEWH4:  LD      HL,WHEEL
        LD      E,A
        LD      D,0
        ADD     HL,DE
        LD      A,(HL)
        POP     HL
        LD      (HL),A
NEDRW:  CALL    SNDKEY
        CALL    NEDRAW
        JP      NEKEY

; NEDRAW: the eight slots at row 8, cols 16-23, cursor cell inverse.
NEDRAW: XOR     A
        LD      (V_TMP),A
NED1:   LD      A,(V_TMP)
        CP      8
        RET     NC
        LD      HL,NAMEED
        LD      E,A
        LD      D,0
        ADD     HL,DE
        LD      A,(HL)
        LD      (LINBUF),A
        XOR     A
        LD      (LINBUF+1),A
        LD      A,(V_TMP)
        LD      HL,V_NCUR
        CP      (HL)
        LD      C,XFONW
        JR      Z,NED2
        LD      C,XWONF
NED2:   LD      A,(V_TMP)
        ADD     A,16
        LD      E,A
        LD      D,8
        LD      HL,LINBUF
        LD      B,1
        CALL    TXTN
        LD      A,(V_TMP)
        INC     A
        LD      (V_TMP),A
        JR      NED1

WHEEL:  DB      "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-"
TNAME:  DB      "YOUR NAME",0
TACCPT: DB      "STICK EDITS - TRIGGER ACCEPTS",0
