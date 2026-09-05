; board.inc -- the four 10x10 boards: geometry, cell patterns, and the
; wire-driven redraw.
;
; A board cell is 4x4 pixels = one byte per row at 2bpp, so a cell
; paints as four byte writes and nothing shifts. Quadrant layout
; (player i = quadrant i; the server rotates you to index 0):
;
;   bytes 0-9 | 10  | 11-20        lines  0-39  q1 (TL)   q2 (TR)
;      board    div    board       lines 40-43  divider
;                                  lines 44-83  q0 (YOU)  q3 (BR)
;
; The reply window is the shadow board: erasing a cursor or a pending
; ship reads the cell's truth back out of the wire (or OCCUPY during
; placement), so no 100-byte RAM copies exist.

; Cell pattern indexes.
PWATER  EQU     0
PHIT    EQU     1
PMISS   EQU     2
PSHIP   EQU     3
PSHPHT  EQU     4
PSUNK   EQU     5
PCURSR  EQU     6

; ----------------------------------------------------------------------
; BRDPOS: DE = screen address of cell (V_CX,V_CY) on quadrant A.
; line = QDROW[q] + 4*y; addr = NORMEM + line*40 + QDCOL[q] + x.
; Clobbers A,BC,HL.
BRDPOS: LD      C,A
        LD      B,0
        LD      HL,QDROW
        ADD     HL,BC
        LD      A,(V_CY)
        ADD     A,A
        ADD     A,A             ; 4*y
        ADD     A,(HL)          ; + the quadrant's top line (max 80)
        LD      L,A
        LD      H,0
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL           ; *8
        LD      E,L
        LD      D,H
        ADD     HL,HL
        ADD     HL,HL           ; *32
        ADD     HL,DE           ; *40
        EX      DE,HL           ; DE = line*40
        LD      HL,QDCOL
        ADD     HL,BC
        LD      A,(HL)
        LD      HL,V_CX
        ADD     A,(HL)
        LD      L,A
        LD      H,0
        ADD     HL,DE
        LD      DE,NORMEM
        ADD     HL,DE
        EX      DE,HL
        RET

; CELLDRW: paint pattern A at cell screen address HL (4 rows of 1
; byte). Preserves HL, DE, BC.
CELLDRW: PUSH   HL
        PUSH    DE
        PUSH    BC
        ADD     A,A
        ADD     A,A             ; *4
        LD      E,A
        LD      D,0
        PUSH    HL
        LD      HL,CELLPAT
        ADD     HL,DE
        EX      DE,HL           ; DE = the pattern rows
        POP     HL
        LD      B,4
CDR1:   LD      A,(DE)
        LD      (HL),A
        INC     DE
        LD      A,L
        ADD     A,BYTEPL
        LD      L,A
        JR      NC,CDR2
        INC     H
CDR2:   DJNZ    CDR1
        POP     BC
        POP     DE
        POP     HL
        RET

; CELLST: wire cell byte -> pattern index. The wire says 0-2, but this
; indexes a table: clamp everything else to sea.
CELLST: CP      1
        JR      Z,CST1
        CP      2
        JR      Z,CST2
        LD      A,PWATER
        RET
CST1:   LD      A,PHIT
        RET
CST2:   LD      A,PMISS
        RET

; PLBASE: HL = wire offset of player record A (GOPLYRS + A*115). Only
; valid once the gamefields exist (status >= 10). Clobbers B,DE.
PLBASE: LD      HL,GOPLYRS
        OR      A
        RET     Z
        LD      B,A
        LD      DE,PLSTRID
PLB1:   ADD     HL,DE
        DJNZ    PLB1
        RET

; MUL10: A -> A*10 (callers keep A <= 25). Clobbers C.
MUL10:  LD      C,A
        ADD     A,A
        ADD     A,A             ; *4
        ADD     A,C             ; *5
        ADD     A,A             ; *10
        RET

; DIV10: A -> B = A/10, A = A mod 10.
DIV10:  LD      B,0
DIV1:   CP      10
        RET     C
        SUB     10
        INC     B
        JR      DIV1

; ----------------------------------------------------------------------
; QUADDRW: quadrant A's 100 cells from player A's wire gamefield,
; walked forward so the slice window flips at most three times.
QUADDRW: LD     (V_QD),A
        CALL    PLBASE
        LD      DE,PLFIELD
        ADD     HL,DE           ; HL = wire offset of cell 0
        XOR     A
        LD      (V_CY),A
QDRY:   XOR     A
        LD      (V_CX),A
        PUSH    HL
        LD      A,(V_QD)
        CALL    BRDPOS          ; DE = screen address of the row start
        POP     HL
        LD      B,10
QDRX:   CALL    RXGETB          ; preserves HL,BC,DE
        CALL    CELLST
        EX      DE,HL
        CALL    CELLDRW
        EX      DE,HL
        INC     HL              ; next wire cell
        INC     DE              ; next cell is the next byte right
        DJNZ    QDRX
        LD      A,(V_CY)
        INC     A
        LD      (V_CY),A
        CP      10
        JR      C,QDRY
        RET

; ----------------------------------------------------------------------
; SHIPSET: overlay the 5-ship set at wire offset DE on quadrant A.
; C = the pattern to draw, or 0FFH for "your own gamefield decides": a
; hit cell shows PSHPHT inside the hull. Each ship byte is
; pos + 100*dir; a byte of 0 is a real carrier at the top-left, not an
; empty slot, so callers only come here when the set is known valid --
; and a byte that decodes off the board is dropped, because it indexes
; the screen. Reuses the placement cursor cells (never live at once).
SHIPSET: LD     (V_QD),A
        LD      (V_BASE),DE     ; wire offset of ship[0]
        LD      A,C
        LD      (V_ST),A        ; the pattern mode
        XOR     A
        LD      (PCNUM),A
SHS1:   LD      A,(PCNUM)
        CP      5
        RET     NC
        LD      HL,(V_BASE)     ; the ship byte
        LD      E,A
        LD      D,0
        ADD     HL,DE
        CALL    RXGETB
        LD      D,0             ; decode the direction
        CP      100
        JR      C,SHS2
        SUB     100
        INC     D
SHS2:   CP      100
        JR      NC,SHSN         ; junk byte: drop the whole ship
        LD      E,A
        LD      A,D
        LD      (PCDIR),A
        LD      A,E
        CALL    DIV10           ; B = y, A = x
        LD      (PCX),A
        LD      A,B
        LD      (PCY),A
        LD      A,(PCNUM)       ; the size
        LD      HL,SHPSIZ
        LD      E,A
        LD      D,0
        ADD     HL,DE
        LD      A,(HL)
        LD      (PCSIZ),A
SHSC:   LD      A,(PCSIZ)       ; per cell, walking the ship
        OR      A
        JR      Z,SHSN
        DEC     A
        LD      (PCSIZ),A
        LD      A,(PCX)
        CP      10
        JR      NC,SHSN         ; ran off the board: junk, stop here
        LD      (V_CX),A
        LD      A,(PCY)
        CP      10
        JR      NC,SHSN
        LD      (V_CY),A
        LD      A,(V_ST)        ; the pattern
        CP      0FFH
        JR      NZ,SHSP
        LD      A,(PCY)         ; your own field: damaged or whole?
        CALL    MUL10
        LD      HL,PCX
        ADD     A,(HL)
        LD      L,A
        LD      H,0
        LD      DE,GOPLYRS+PLFIELD
        ADD     HL,DE
        CALL    RXGETB
        CP      1
        LD      A,PSHPHT
        JR      Z,SHSP
        LD      A,PSHIP
SHSP:   PUSH    AF
        LD      A,(V_QD)
        CALL    BRDPOS          ; DE = screen address
        POP     AF
        EX      DE,HL
        CALL    CELLDRW
        LD      A,(PCDIR)       ; advance along the ship
        OR      A
        LD      HL,PCX
        JR      Z,SHSA
        LD      HL,PCY
SHSA:   INC     (HL)
        JR      SHSC
SHSN:   LD      A,(PCNUM)
        INC     A
        LD      (PCNUM),A
        JP      SHS1

; ----------------------------------------------------------------------
; BRDSTAT: the board dividers -- the only game-screen statics.
BRDSTAT: LD     HL,NORMEM+10    ; vertical, byte column 10, lines 0-83
        LD      B,84
        LD      C,1
        LD      D,0FFH
        CALL    FILLRC
        LD      HL,NORMEM+40*BYTEPL ; horizontal, lines 40-43, bytes 0-20
        LD      B,4
        LD      C,21
        LD      D,0FFH
        JP      FILLRC

; ----------------------------------------------------------------------
QDROW:  DB      44,0,0,44       ; quadrant top line
QDCOL:  DB      0,0,11,11       ; quadrant left byte column
QTAG:   DB      "BLTLTRBR"      ; panel tags, 2 chars per quadrant
SHPSIZ: DB      5,4,3,3,2       ; fixed order; the index is also the
                                ; shipsLeft / myShips slot

; Cell patterns: 4 rows x 1 byte each, 2bpp pixels left to right in
; bits 7-6 .. 1-0 (00 sea, 01 black, 10 red, 11 white).
CELLPAT: DB     000H,000H,000H,000H     ; WATER    ....  flat sea
        DB      0AAH,0AAH,0AAH,0AAH     ; HIT      rrrr  solid red
        DB      000H,03CH,03CH,000H     ; MISS     .ww.  splash dot
        DB      0FFH,0FFH,0FFH,0FFH     ; SHIP     wwww  solid hull
        DB      0FFH,0EBH,0EBH,0FFH     ; SHIPHIT  wrrw  red core in hull
        DB      0AAH,0BEH,0BEH,0AAH     ; SUNK     rwwr  white core in red
        DB      0FFH,0C3H,0C3H,0FFH     ; CURSOR   w..w  ring: targeting
                                        ; and the pending placement
