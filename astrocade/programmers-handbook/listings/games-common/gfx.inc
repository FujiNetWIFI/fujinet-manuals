; gfx.inc -- the 4x6 renderer, fills, and raw blits.
;
; The whole port draws on one alignment trick: at 2bpp, 4 pixels are one
; byte, and the character grid is 4 pixels wide -- so every glyph row is a
; single byte write and nothing here ever shifts. Text goes through the
; magic EXPANDER: OUT the fg/bg pair to XPAND, reset the expander's nibble
; flip-flop by writing the MAGIC register, and each following write through
; magic memory (0000H + screen offset) paints the HIGH nibble of the data
; as 4 pixels in those two colors. One MAGIC write per row keeps the
; flip-flop on the high nibble; MAME's funcgen and the Nutting description
; agree on that reset.
;
; Everything runs with interrupts off and draws opaquely (bg included), so
; redraw over live screen never flickers and never needs a clear first.
;
; Char grid: 40 cols x 15 rows of 4x6 cells over 90 visible lines.
; Colors (palette registers): 0 felt, 1 black, 2 red, 3 white.

MAGEXP  EQU     08H             ; MAGIC value: expand, no shift/rotate/or/xor

; XPAND color pairs (fg*4 + bg).
XWONF   EQU     0CH+0           ; white on felt (table text)
XKONW   EQU     04H+3           ; black on white (card ranks)
XRONW   EQU     08H+3           ; red on white
XKONF   EQU     04H+0           ; black on felt
XRONF   EQU     08H+0           ; red on felt
XFONW   EQU     00H+3           ; felt on white (inverse: highlights)

; ----------------------------------------------------------------------
; TXTAT: string at HL (NUL-terminated) at char col E, row D, colors C
; (an XPAND pair). TXTN: exactly B cells of the string -- stops copying
; at the NUL and pads the rest with spaces, so fixed-width fields redraw
; opaquely. Lowercase folds to uppercase; anything else outside 20H-5FH
; draws as '?'. Clobbers everything.
TXTAT:  LD      B,0             ; 0: no pad, stop at NUL
        JR      TXT0
TXTN:   LD      A,B
        OR      A
        RET     Z
TXT0:   LD      A,C
        OUT     (XPAND),A
        CALL    TXTPOS
TXT1:   LD      A,(HL)
        OR      A
        JR      Z,TXT3          ; NUL: pad or stop
        INC     HL
        CP      61H             ; fold 'a'-'z'
        JR      C,TXT2
        CP      7BH
        JR      NC,TXT2
        SUB     20H
TXT2:   SUB     20H
        CP      40H
        JR      C,TXT4
        LD      A,'?'-20H
TXT4:   CALL    GLYPH
        LD      A,B
        OR      A
        JR      Z,TXT1          ; unbounded (TXTAT)
        DJNZ    TXT1
        RET
TXT3:   LD      A,B
        OR      A
        RET     Z               ; TXTAT: done at NUL
TXT5:   XOR     A               ; TXTN: space-pad the remainder
        CALL    GLYPH
        DJNZ    TXT5
        RET

; TXTPOS: D,E char row/col -> shadow DE = magic address; preserves the
; primary registers (HL string, B count, C colors).
TXTPOS: PUSH    HL
        PUSH    BC
        LD      A,D
        ADD     A,A
        LD      H,0
        LD      L,A
        LD      BC,ROWTAB
        ADD     HL,BC
        LD      A,(HL)
        INC     HL
        LD      H,(HL)
        LD      L,A
        LD      B,0
        LD      C,E
        ADD     HL,BC           ; HL = row*240 + col
        PUSH    HL
        EXX
        POP     DE              ; shadow DE = magic address
        EXX
        POP     BC
        POP     HL
        RET

; GLYPH: draw glyph index A (0-3FH) at the shadow-DE magic address and
; advance it one cell right. Preserves primary HL/BC (shadow DE is the
; running magic address, so the *6 scratch uses shadow BC).
GLYPH:  EXX
        LD      L,A
        LD      H,0
        ADD     HL,HL           ; A*2
        LD      B,H
        LD      C,L
        ADD     HL,HL           ; A*4
        ADD     HL,BC           ; A*6
        LD      BC,FONT46
        ADD     HL,BC           ; HL = glyph rows
        LD      B,6
GLYRW:  LD      A,MAGEXP
        OUT     (MAGIC),A       ; reset the expander nibble flip-flop
        LD      A,(HL)
        LD      (DE),A          ; one row: 4 pixels
        INC     HL
        LD      A,E             ; down one line
        ADD     A,BYTEPL
        LD      E,A
        JR      NC,GLYRW1
        INC     D
GLYRW1: DJNZ    GLYRW
        LD      A,E             ; back up 6 lines, over 1 col
        SUB     6*BYTEPL-1
        LD      E,A
        JR      NC,GLYRW2
        DEC     D
GLYRW2: EXX
        RET

; ----------------------------------------------------------------------
; CLRSCR: the whole visible screen back to felt. Clobbers A,BC,DE,HL.
CLRSCR: LD      HL,NORMEM
        LD      DE,NORMEM+1
        LD      BC,LINES*BYTEPL-1
        LD      (HL),0
        LDIR
        RET

; ----------------------------------------------------------------------
; FILLRC: fill C bytes x B lines with byte D, top-left at screen address
; HL (NORMEM-based). Clobbers A,B,E,HL.
FILLRC: PUSH    BC
        PUSH    HL
FILL1:  LD      (HL),D
        INC     HL
        DEC     C
        JR      NZ,FILL1
        POP     HL
        POP     BC
        LD      A,L
        ADD     A,BYTEPL
        LD      L,A
        JR      NC,FILL2
        INC     H
FILL2:  DJNZ    FILLRC
        RET

; RAWBLT: copy C bytes x B rows from HL to screen address DE
; (NORMEM-based), advancing DE one screen line per row. Clobbers all.
RAWBLT: PUSH    DE
        PUSH    BC
RAWB1:  LD      A,(HL)
        LD      (DE),A
        INC     HL
        INC     DE
        DEC     C
        JR      NZ,RAWB1
        POP     BC
        POP     DE
        LD      A,E
        ADD     A,BYTEPL
        LD      E,A
        JR      NC,RAWB2
        INC     D
RAWB2:  DJNZ    RAWBLT
        RET

; ----------------------------------------------------------------------
; U16STR: HL as decimal into LINBUF, leading zeros suppressed, NUL
; terminated. Clobbers everything.
U16STR: LD      DE,LINBUF
        LD      BC,10000
        CALL    U16DIG
        LD      BC,1000
        CALL    U16DIG
        LD      BC,100
        CALL    U16DIG
        LD      BC,10
        CALL    U16DIG
        LD      A,L
        ADD     A,'0'
        LD      (DE),A
        INC     DE
        XOR     A
        LD      (DE),A
        RET
U16DIG: XOR     A               ; digit for power BC
U16D1:  SBC     HL,BC
        JR      C,U16D2
        INC     A
        JR      U16D1
U16D2:  ADD     HL,BC           ; undo the overshoot
        OR      A
        JR      NZ,U16D3        ; a real digit
        LD      A,E             ; suppress a leading zero: buffer still
        OR      A               ; empty? (LINBUF sits at 4F00H -- page
        RET     Z               ; aligned -- so low byte 0 is the start)
        XOR     A
U16D3:  ADD     A,'0'
        LD      (DE),A
        INC     DE
        RET

ROWTAB: DW      0*240,1*240,2*240,3*240,4*240
        DW      5*240,6*240,7*240,8*240,9*240
        DW      10*240,11*240,12*240,13*240,14*240
