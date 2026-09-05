; dice.inc -- the dice strip: five 12x12 dice, the ROLL tile, the hold
; markers, and the roll animation.
;
; A die is 3 bytes x 12 lines at 2bpp, sitting exactly on char rows
; 10-11 (pixel lines 60-71), so the ROLL tile and the hold markers are
; ordinary text on the same grid and everything stays byte-aligned. The
; faces are not stored as bitmaps: each face is three 3-bit pip masks
; (top / middle / bottom row of pips) and the twelve lines are built
; from a skeleton, so all six faces cost 18 bytes of data.
;
; The hold markers live in the text row UNDER the dice ('HLD' when a
; die will be kept), and the dice-mode cursor is that field -- or the
; ROLL tile -- drawn inverse. No blinking: the family redraws on every
; keypress and that is signal enough.

DIETOP  EQU     60              ; the strip's first pixel line
PIPB    EQU     0D7H            ; one row byte: white,black,black,white
WHTB    EQU     0FFH            ; one row byte: solid white

; DIEADDR: DE = screen address of die A (0-4). Clobbers A,HL.
DIEADDR: ADD    A,A
        LD      HL,DIEPOS
        ADD     A,L
        LD      L,A
        JR      NC,DIEA1
        INC     H
DIEA1:  LD      E,(HL)
        INC     HL
        LD      D,(HL)
        RET

; DIEDRW: face A (0 = empty tray, 1-6 = pips) at screen address DE.
; Clobbers everything.
DIEDRW: OR      A
        JR      NZ,DIED1
        EX      DE,HL           ; empty: back to felt
        LD      B,12
        LD      C,3
        LD      D,0
        JP      FILLRC
DIED1:  DEC     A               ; the face's three pip masks
        LD      C,A
        ADD     A,A
        ADD     A,C
        LD      C,A             ; C = (face-1)*3
        LD      HL,ROWSKEL
        LD      B,12
DIEDL:  LD      A,(HL)
        INC     HL
        PUSH    HL
        CP      0FFH
        JR      NZ,DIEDP
        XOR     A               ; a white line: no pips
        JR      DIEDM
DIEDP:  PUSH    BC
        ADD     A,C
        LD      L,A
        LD      H,0
        LD      BC,FACETAB
        ADD     HL,BC
        LD      A,(HL)
        POP     BC
DIEDM:  PUSH    BC              ; A = mask, bit 2 left .. bit 0 right
        PUSH    DE
        LD      C,A
        LD      B,3
DIEDB:  LD      A,C
        AND     4
        LD      A,WHTB
        JR      Z,DIEDB2
        LD      A,PIPB
DIEDB2: LD      (DE),A
        INC     DE
        SLA     C
        DJNZ    DIEDB
        POP     DE
        POP     BC
        LD      A,E             ; down one screen line
        ADD     A,BYTEPL
        LD      E,A
        JR      NC,DIEDN
        INC     D
DIEDN:  POP     HL
        DJNZ    DIEDL
        RET

; ----------------------------------------------------------------------
; DICEROW: the five dice from the wire. An out-of-range byte (or the
; NULs of a turn not yet rolled) draws the empty tray.
DICEROW: XOR    A
        LD      (V_TM2),A
DICR1:  LD      A,(V_TM2)
        CP      5
        RET     NC
        LD      HL,GODICE
        LD      E,A
        LD      D,0
        ADD     HL,DE
        CALL    RXGETB
        SUB     '0'             ; '1'-'6' -> 1-6; anything else -> 0
        JR      C,DICR2
        CP      7
        JR      C,DICR3
DICR2:  XOR     A
DICR3:  LD      (V_FACE),A
        LD      A,(V_TM2)
        CALL    DIEADDR
        LD      A,(V_FACE)
        CALL    DIEDRW
        LD      A,(V_TM2)
        INC     A
        LD      (V_TM2),A
        JR      DICR1

; ----------------------------------------------------------------------
; DICEHUD: the ROLL tile (rows 10-11, cols 1-4) and the five hold
; markers (row 12, under the dice). The mask shown is the local staging
; buffer on your turn, the wire's echo otherwise; '0' means kept. The
; dice-mode cursor inverts its field.
DICEHUD: LD     HL,GORLEFT
        CALL    RXGETB
        LD      (V_FACE),A      ; rollsLeft, reused below
        LD      HL,TROLL        ; the tile: dead black at 0 rolls,
        LD      C,XKONF         ; inverse under the cursor, else white
        OR      A
        JR      Z,DIH1
        LD      C,XWONF
        CALL    DCURQ0
        JR      NZ,DIH1
        LD      C,XFONW
DIH1:   LD      DE,10*256+1
        LD      B,4
        PUSH    BC
        CALL    TXTN
        POP     BC
        LD      A,(V_FACE)      ; " xN" under it, same color
        ADD     A,'0'
        LD      (LINBUF+2),A
        LD      A,' '
        LD      (LINBUF),A
        LD      A,'X'
        LD      (LINBUF+1),A
        XOR     A
        LD      (LINBUF+3),A
        LD      HL,LINBUF
        LD      DE,11*256+1
        LD      B,4
        CALL    TXTN
        XOR     A               ; the five markers
        LD      (V_TM2),A
DIH2:   LD      A,(V_TM2)
        CP      5
        RET     NC
        CALL    KEEPGET         ; A = this die's mask char
        CP      '0'
        LD      HL,THLD
        JR      Z,DIH3
        LD      HL,TNUL
DIH3:   LD      C,XRONF
        LD      A,(V_TM2)
        INC     A               ; cursor 1-5 = dice 0-4
        CALL    DCURQ
        JR      NZ,DIH4
        LD      C,XFONW
DIH4:   LD      A,(V_TM2)       ; field col = 8 + i*5
        ADD     A,A
        ADD     A,A
        LD      E,A
        LD      A,(V_TM2)
        ADD     A,E
        ADD     A,8
        LD      E,A
        LD      D,12
        LD      B,3
        CALL    TXTN
        LD      A,(V_TM2)
        INC     A
        LD      (V_TM2),A
        JR      DIH2

; KEEPGET: A = mask char for die (V_TM2): the staging buffer on your
; turn, the wire otherwise. Preserves BC,DE... clobbers A,HL.
KEEPGET: LD     A,(V_MYTRN)
        OR      A
        JR      Z,KPGW
        LD      A,(V_TM2)
        LD      HL,KEEPBF
        ADD     A,L
        LD      L,A
        JR      NC,KPG1
        INC     H
KPG1:   LD      A,(HL)
        RET
KPGW:   PUSH    DE
        LD      A,(V_TM2)
        LD      HL,GOKEEP
        LD      E,A
        LD      D,0
        ADD     HL,DE
        CALL    RXGETB
        POP     DE
        RET

; DCURQ0 / DCURQ: Z set when the dice-mode cursor is visible and equals
; 0 (the ROLL tile) / A. Preserves BC,DE,HL.
DCURQ0: XOR     A
DCURQ:  PUSH    HL
        LD      HL,V_MYTRN
        BIT     0,(HL)
        JR      Z,DCQN
        LD      HL,UIMODE
        BIT     0,(HL)
        JR      NZ,DCQN
        LD      HL,DCUR
        CP      (HL)
        POP     HL
        RET
DCQN:   POP     HL
        OR      1               ; force NZ
        RET

; ----------------------------------------------------------------------
; ROLLANM: a roll landed -- rattle the re-rolled dice. Which dice is the
; wire's own answer: the server echoes the mask the roll was made with,
; so GOKEEP names the moving dice for your rolls and everyone else's
; alike. Eight flickers of LFSR faces with a tick each, then the caller
; repaints the truth on the ordinary render path.
ROLLANM: LD     B,8
RANM1:  PUSH    BC
        XOR     A
        LD      (V_TM2),A
RANM2:  LD      A,(V_TM2)
        CP      5
        JR      NC,RANM3
        LD      HL,GOKEEP
        LD      E,A
        LD      D,0
        ADD     HL,DE
        CALL    RXGETB
        CP      '1'
        JR      NZ,RANM4        ; kept: it never moves
        LD      A,6
        CALL    RNDMOD
        INC     A
        LD      (V_FACE),A
        LD      A,(V_TM2)
        CALL    DIEADDR
        LD      A,(V_FACE)
        CALL    DIEDRW
RANM4:  LD      A,(V_TM2)
        INC     A
        LD      (V_TM2),A
        JR      RANM2
RANM3:  CALL    SNDTICK
        LD      DE,6000         ; ~50 ms between flickers
RANMD:  DEC     DE
        LD      A,D
        OR      E
        JR      NZ,RANMD
        POP     BC
        DJNZ    RANM1
        RET

; ----------------------------------------------------------------------
ROWSKEL: DB     0FFH,0FFH       ; the twelve lines of a face: white
        DB      0,0             ; margin, pip row, gap, pip row, gap,
        DB      0FFH            ; pip row, margin
        DB      1,1
        DB      0FFH
        DB      2,2
        DB      0FFH,0FFH

; Three pip masks per face (top, middle, bottom); bit 2 = left,
; bit 1 = centre, bit 0 = right.
FACETAB: DB     0,2,0           ; 1
        DB      4,0,1           ; 2
        DB      4,2,1           ; 3
        DB      5,0,5           ; 4
        DB      5,2,5           ; 5
        DB      5,5,5           ; 6

; The five dice: byte columns 8,13,18,23,28 on pixel line 60.
DIEPOS: DW      NORMEM+DIETOP*BYTEPL+8
        DW      NORMEM+DIETOP*BYTEPL+13
        DW      NORMEM+DIETOP*BYTEPL+18
        DW      NORMEM+DIETOP*BYTEPL+23
        DW      NORMEM+DIETOP*BYTEPL+28

TROLL:  DB      "ROLL",0
THLD:   DB      "HLD",0
TNUL:   DB      0
