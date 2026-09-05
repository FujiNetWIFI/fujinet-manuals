; term.inc -- the scrolling terminal pane.
;
; No other Astrocade FujiNet client has one: they all redraw opaquely from
; the reply window every poll, so nothing ever had to move. This does.
;
; SCROLLING. There is no display-base or scroll register on this hardware
; (videoram is a flat mapping at 4000H, and the BIOS SCROLL call is itself a
; software copy), so a line feed at the bottom of the pane is an LDIR of
; (TROWS-1)*240 bytes. At 21 T-states a byte on a 1.789 MHz Z80 that is
; ~34 ms, about two frames, and it happens once per line -- cheap enough
; that the TV-typewriter fallback (re-home and clear forward) is not needed.
;
; THE SHADOW. The grid keyboard opens over the bottom of the pane, so the
; TSHROWS rows it covers have to come back afterwards. A character shadow of
; just those rows is 160 bytes; one of the whole pane would be 520 and RAM
; here is 736 bytes total. TPUTC records into it, TSCROL shifts it by a row
; in step with the screen, and TRSHAD repaints from it.
;
; THE CURSOR is the cell's bottom scanline, set to 0FFH and cleared to 0 by
; direct (non-magic) writes. It sits where the next character will land,
; which in normal flow is blank, so clearing to zero is right; the one cost
; is that a character the cursor previously rested on loses its bottom pixel
; row. That is worth not spending 520 bytes on a full-pane shadow.

; TINIT: clear the pane, home the cursor, drop any escape state.
; Clobbers everything.
TINIT:  XOR     A
        LD      (TCOL),A
        LD      (TROW),A
        LD      (TESC),A
        LD      HL,TSHAD        ; glyph index 0 is the space
        LD      DE,TSHAD+1
        LD      BC,TSHROWS*TCOLS-1
        LD      (HL),0
        LDIR
        XOR     A
        LD      B,TROWS
        JP      CLRRWS

; ----------------------------------------------------------------------
; TPUTC: put the byte in A through the terminal. Clobbers everything.
TPUTC:  LD      C,A             ; C holds the byte throughout
        LD      A,(TESC)
        OR      A
        JP      NZ,TPESCS
        LD      A,C
        CP      20H
        JR      C,TPCTL
        CP      7FH
        RET     NC              ; DEL, and 8-bit CP437 art: drop it rather
        SUB     20H             ; than print a wrong glyph
        ; falls into TPGLY

; TPGLY: draw glyph index A at the cursor and advance.
TPGLY:  CALL    TPDRAW
        LD      A,(TCOL)
        INC     A
        CP      TCOLS
        JR      C,TPG1
        XOR     A               ; wrap
        LD      (TCOL),A
        JR      TNEWLN
TPG1:   LD      (TCOL),A
        RET

; TPDRAW: draw glyph index A at the cursor without moving it, recording it
; in the shadow if the cursor is inside the shadowed band.
TPDRAW: PUSH    AF
        CALL    TSHPUT
        POP     AF
        LD      DE,(TCOL)       ; E = TCOL, D = TROW -- they are adjacent
        LD      C,XWONK
        JP      GLYPH1

; TNEWLN: down one row, scrolling if already at the bottom.
TNEWLN: LD      A,(TROW)
        INC     A
        CP      TROWS
        JR      NC,TSCROL
        LD      (TROW),A
        RET

; TSCROL: the whole pane up one row, screen and shadow together.
TSCROL: LD      A,TROWS
        CALL    SCRLUP
        LD      A,TROWS-1
        CALL    CLRROW
        LD      HL,TSHAD+TCOLS
        LD      DE,TSHAD
        LD      BC,(TSHROWS-1)*TCOLS
        LDIR
        LD      HL,TSHAD+(TSHROWS-1)*TCOLS
        LD      DE,TSHAD+(TSHROWS-1)*TCOLS+1
        LD      BC,TCOLS-1
        LD      (HL),0
        LDIR
        RET

; ----------------------------------------------------------------------
; TPCTL: the control characters worth honouring. CR and LF are handled
; independently, which gets CR LF right for free.
TPCTL:  LD      A,C
        CP      13
        JR      Z,TPCR
        CP      10
        JR      Z,TNEWLN
        CP      8
        JR      Z,TPBS
        CP      9
        JR      Z,TPTAB
        CP      27
        JR      Z,TPESCB
        RET                     ; BEL and everything else: ignore

TPCR:   XOR     A
        LD      (TCOL),A
        RET

TPBS:   LD      A,(TCOL)
        OR      A
        RET     Z
        DEC     A
        LD      (TCOL),A
        XOR     A               ; erase the cell we backed into
        JR      TPDRAW

TPTAB:  LD      A,(TCOL)
        AND     0F8H
        ADD     A,8
        CP      TCOLS
        JR      C,TPT1
        XOR     A
        LD      (TCOL),A
        JR      TNEWLN
TPT1:   LD      (TCOL),A
        RET

TPESCB: LD      A,1
        LD      (TESC),A
        XOR     A
        LD      (TESCN),A
        RET

; ----------------------------------------------------------------------
; TPESCS: inside an escape sequence. A = state, C = the byte.
;
; A BBS told cols/rows still gets to decide it wants ANSI, so swallowing
; these is what keeps [0;37;44m off a 40-column screen. Three states are
; enough: 1 = just saw ESC, 2 = inside a CSI, 3 = swallow one more byte
; (the character-set selectors, ESC ( B and friends).
TPESCS: CP      1
        JR      Z,TPES1
        CP      2
        JR      Z,TPES2
        JR      TESCOF          ; state 3: this byte was the last of it

TPES1:  LD      A,C
        CP      '['
        JR      Z,TPCSIB
        CP      '('
        JR      Z,TPINT
        CP      ')'
        JR      Z,TPINT
        CP      '#'
        JR      Z,TPINT
        JR      TESCOF          ; a one-byte sequence, already consumed
TPCSIB: LD      A,2
        LD      (TESC),A
        RET
TPINT:  LD      A,3
        LD      (TESC),A
        RET

TPES2:  LD      A,(TESCN)       ; a CSI runs until a final byte in 40H-7EH
        INC     A
        LD      (TESCN),A
        CP      32
        JR      NC,TESCOF       ; runaway: stop swallowing the screen
        LD      A,C
        CP      40H
        RET     C               ; parameter or intermediate byte
        CP      7FH
        RET     NC
TESCOF: XOR     A
        LD      (TESC),A
        RET

; ----------------------------------------------------------------------
; The shadow.

; TSHRO0: HL = TSHAD + A*TCOLS. Clobbers A,D,E.
TSHRO0: LD      L,A
        LD      H,0
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL           ; *8
        LD      D,H
        LD      E,L
        ADD     HL,HL
        ADD     HL,HL           ; *32
        ADD     HL,DE           ; *40
        LD      DE,TSHAD
        ADD     HL,DE
        RET

; TSHPUT: record glyph index A at the cursor, if the cursor row is covered.
; Preserves A.
TSHPUT: PUSH    AF
        LD      A,(TROW)
        SUB     TSHTOP
        JR      C,TSHP9         ; above the band: nothing to remember
        CALL    TSHRO0
        LD      A,(TCOL)
        LD      E,A
        LD      D,0
        ADD     HL,DE
        POP     AF
        LD      (HL),A
        RET
TSHP9:  POP     AF
        RET

; TRSHAD: repaint the shadowed rows -- what closing the overlay calls.
; Clobbers everything.
TRSHAD: LD      A,TSHTOP
        LD      B,TSHROWS
TRS1:   PUSH    BC
        PUSH    AF
        CALL    TRSROW
        POP     AF
        INC     A
        POP     BC
        DJNZ    TRS1
        RET

; TRSROW: repaint terminal row A from its shadow line.
TRSROW: PUSH    AF
        SUB     TSHTOP
        CALL    TSHRO0
        POP     AF
        LD      D,A             ; D = terminal row
        LD      E,0             ; E = column
        LD      B,TCOLS
TRSR1:  LD      C,XWONK
        LD      A,(HL)
        PUSH    HL
        CALL    GLYPH1          ; preserves BC, DE; HL for safety
        POP     HL
        INC     HL
        INC     E
        DJNZ    TRSR1
        RET

; ----------------------------------------------------------------------
; The cursor: the bottom scanline of the cell it sits on.

; TCURA: HL = screen address of that scanline. Clobbers A,D,E.
TCURA:  LD      A,(TROW)
        CALL    ROWADR
        LD      DE,5*BYTEPL
        ADD     HL,DE
        LD      A,(TCOL)
        LD      E,A
        LD      D,0
        ADD     HL,DE
        RET

TCURON: CALL    TCURA
        LD      (HL),0FFH       ; a direct write: no expander, 4 white pixels
        RET

TCUROF: CALL    TCURA
        LD      (HL),0
        RET
