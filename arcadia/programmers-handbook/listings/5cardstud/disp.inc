; disp.inc -- 2637 UVI display core for 5 Card Stud.
;
; Adapted from the bring-up's fujidisp.inc, with three changes for this
; client:
;   - The game runs the screen NO OTHER CLIENT HAS USED: 26-line mode
;     (16x26 of 8x8 cells, lower page $1A00) plus MULTICOLOR mode. Cell
;     bit6 picks the ink ($19F8 b3-5 = black vs $19F9 b3-5 = red), bit7
;     picks the background ($19F8 b0-2 = green vs $19F9 b0-2 = white):
;       $00 black on green   felt text        $80 black on white  cards/bar
;       $40 red   on green   alerts/chip      $C0 red   on white  red suits
;     The one hazard: a cell of exactly $C0 (space with attrs 11) flips
;     the row into block-graphics for the rest of the row. DPUTC guards
;     it (glyph 0 + attr $C0 -> $80); nothing else writes attributed
;     cells.
;   - Output goes through the *SCRP pointer so one code path serves both
;     screen halves (rows 0-12 at $1800, rows 13-25 at $1A00).
;   - DXLAT NEVER emits UDC codes: the game bank repurposes $38-$3F for
;     suits/ten/chip/lattice/chevron, so a stray '-' or ':' in a name
;     must not render as a club. '/' maps to the built-in full-cell
;     diagonal $02; the rest fold to '.'.
;
; Conventions: R0 data, R1/R2 arguments, R3 counters; PSL = $02 (COM=1,
; logical compares, WC off -- NUMPRT flips WC internally and restores it).

; ---- hardware ---------------------------------------------------------
SCREEN  EQU     $1800           ; upper screen, 16 cols x 13 rows
SCREENL EQU     $1A00           ; lower screen, rows 13-25 (26-line mode)
UDC     EQU     $1980           ; 8 user-defined characters, 8 bytes each
GFXMOD  EQU     $19F8           ; b7 gfx mode, b6 26-line, b3-5 ink A,
                                ;   b0-2 bg A (colours INVERTED: 0=white,
                                ;   3=green, 5=red, 7=black)
BGCOL   EQU     $19F9           ; b7 char size (1 = 8x8), b6 pot mux,
                                ;   b3-5 ink B, b0-2 bg B
SPRC23  EQU     $19FA           ; b6/b7 size obj3/obj2, colours obj3/obj2
SPRC01  EQU     $19FB           ; b6/b7 size obj1/obj0, colours obj1/obj0
SPRPOS  EQU     $18F0           ; 4 x (y,x); y raw = 256-yint, x raw = xint+43
PITCH   EQU     $18FD           ; b7 MULTICOLOR, b0-6 sound frequency
VOLUME  EQU     $18FE           ; b0-2 loudness, b3 snd enable, b5-7 h-shift

CGREEN  EQU     3               ; the palette (inverted encoding)
CRED    EQU     5
CBLACK  EQU     7
CWHITE  EQU     0

AFELT   EQU     $00             ; attribute nibbles (cell bits 7-6)
AALERT  EQU     $40
ACARD   EQU     $80
AREDW   EQU     $C0

GDIAG   EQU     $01             ; built-in full-cell '/' diagonal
GBLOCK  EQU     $03             ; built-in solid block
GHEART  EQU     $38             ; bank T UDCs
GDIAM   EQU     $39
GCLUB   EQU     $3A
GSPADE  EQU     $3B
GTEN    EQU     $3C
GCHIP   EQU     $3D
GBACK   EQU     $3E
GCHEVR  EQU     $3F
GARROW  EQU     $38             ; bank L: cursor sprite/glyph
GSLASH  EQU     $39
GDASH   EQU     $3A

; ---- macros -----------------------------------------------------------
DWBE    MACRO   val             ; big-endian word: what indirection reads
        DB      ((val)>>8)&$FF, (val)&$FF
        ENDM

SETSTR  MACRO   adr             ; point DPRINT at a string (clobbers R0)
        LODI,R0 (adr)>>8
        STRA,R0 DSTRP
        LODI,R0 (adr)&$FF
        STRA,R0 DSTRP+1
        ENDM

DAT     MACRO   row,col         ; fixed screen position (clobbers R0,R2)
    IF (row)<13
        LODI,R0 SCREEN>>8
        STRA,R0 SCRP
        LODI,R2 ((row)*16+(col)-1)&$FF
    ELSEIF
        LODI,R0 SCREENL>>8
        STRA,R0 SCRP
        LODI,R2 (((row)-13)*16+(col)-1)&$FF
    ENDIF
        ENDM

DCOL    MACRO   attr            ; set the attribute for what follows
        LODI,R0 attr
        STRA,R0 DCOLOR
        ENDM

; ---- mode setup -------------------------------------------------------
; DINI13 / DINI26: 13- or 26-line multicolor text mode, sound off. The
; palette is the whole game: ink A black / bg A green ($19F8), ink B red /
; bg B white ($19F9). Leaf. Clobbers R0.
DINI13: LODI,R0 $3B             ; ink A black(7), bg A green(3)
        STRA,R0 GFXMOD
        LODI,R0 $28             ; 8x16 doublescan: 13 big rows fill the frame
        BCTR,UN DINIC
DINI26: LODI,R0 $7B             ; + bit6: 26-line
        STRA,R0 GFXMOD
        LODI,R0 $A8             ; 8x8 cells
DINIC:  STRA,R0 BGCOL           ; (both: mux clear, ink B red, bg B white)
        LODI,R0 $80             ; multicolor on, frequency 0
        STRA,R0 PITCH
        EORZ    R0
        STRA,R0 VOLUME
        STRA,R0 SCRP+1          ; both halves are page-aligned
        STRA,R0 DCOLOR
        RETC,UN

; DCLSU / DCLSL: clear one half to felt (208 cells of $00). Leaf.
; Clobbers R0,R3.
DCLSU:  LODI,R3 207
DCU1:   EORZ    R0
        STRA,R0 SCREEN,R3
        BDRR,R3 DCU1
        EORZ    R0
        STRA,R0 SCREEN
        RETC,UN

DCLSL:  LODI,R3 207
DCL1:   EORZ    R0
        STRA,R0 SCREENL,R3
        BDRR,R3 DCL1
        EORZ    R0
        STRA,R0 SCREENL
        RETC,UN

; ---- positioning ------------------------------------------------------
; DPOS: runtime position. R1 = row 0-25, R2 = col. Sets SCRP and leaves
; R2 = cell-minus-one for the auto-increment stores. Leaf. Clobbers
; R0,R1,R2.
DPOS:   LODI,R0 SCREEN>>8
        COMI,R1 13
        BCTR,LT DPOS1
        SUBI,R1 13
        LODI,R0 SCREENL>>8
DPOS1:  STRA,R0 SCRP
        LODZ    R1
        RRL,R0
        RRL,R0
        RRL,R0
        RRL,R0                  ; row*16 (row < 13: no wrap)
        ADDZ    R2
        SUBI,R0 1
        STRZ    R2
        RETC,UN

; ---- writing ----------------------------------------------------------
; DPUTC: write glyph R0 at the next cell with the DCOLOR attribute. The
; $C0 hazard guard lives here and only here. Leaf. Clobbers R0,R2(+1).
DPUTC:  IORA,R0 DCOLOR
        COMI,R0 $C0             ; space with attrs 11 = block-gfx trap
        BCFR,EQ DPUT1
        LODI,R0 $80             ; same look (blank white cell), no trap
DPUT1:  STRA,R0 *SCRP,R2,+
        RETC,UN

; DFILL: write R3 cells of glyph R1 with the DCOLOR attribute.
; Calls one down (DPUTC). Clobbers R0,R2,R3.
DFILL:  LODZ    R1
        BSTR,UN DPUTC
        BDRR,R3 DFILL
        RETC,UN

; DXLAT: ASCII in R0 -> glyph $00-$3F, never a UDC. Lowercase folds.
; Leaf. Clobbers R0,R1.
DXLAT:  ANDI,R0 $7F
        SUBI,R0 $20
        BCTR,LT DXLBAD          ; control character
        STRZ    R1
        LODA,R0 XLAT,R1
        RETC,UN
DXLBAD: LODI,R0 $34             ; '.'
        RETC,UN

; DPRINT: print the 0-terminated ASCII string at (DSTRP) from the next
; cell, translated and attributed. Calls one down (DXLAT/DPUTC).
; Clobbers R0,R1,R2,R3.
DPRINT: LODI,R3 $FF
DPRT1:  LODA,R0 *DSTRP,R3,+    ; str[++R3]; a load sets CC
        BCTR,EQ DPRT9
        BSTR,UN DXLAT
        BSTR,UN DPUTC
        BCTR,UN DPRT1
DPRT9:  RETC,UN

; DPRTN: like DPRINT but exactly R1 cells: the string is truncated or
; space-padded to the field, so fields overdraw opaquely.
; Calls one down (DXLAT/DPUTC). Clobbers R0,R1,R2,R3, V_TMP2.
DPRTN:  LODZ    R1
        STRA,R0 V_TMP2          ; cells remaining
        LODI,R3 $FF
DPTN1:  LODA,R0 V_TMP2
        BCTR,EQ DPTN9
        SUBI,R0 1
        STRA,R0 V_TMP2
        LODA,R0 *DSTRP,R3,+
        BCTR,EQ DPTNP           ; NUL: pad the rest with spaces
        BSTR,UN DXLAT
        BSTA,UN DPUTC
        BCTR,UN DPTN1
DPTNP:  EORZ    R0
        BSTA,UN DPUTC
        LODA,R0 V_TMP2
        BCTR,EQ DPTN9
        SUBI,R0 1
        STRA,R0 V_TMP2
        BCTR,UN DPTNP
DPTN9:  RETC,UN

; DHEX: R0 as two hex digits at the next cells, felt attribute ignored
; (debug aid). Leaf-ish. Clobbers R0,R1,R2.
DHEX:   STRZ    R1
        RRR,R0
        RRR,R0
        RRR,R0
        RRR,R0
        ANDI,R0 $0F
        IORI,R0 $10
        STRA,R0 *SCRP,R2,+
        LODZ    R1
        ANDI,R0 $0F
        IORI,R0 $10
        STRA,R0 *SCRP,R2,+
        RETC,UN

; NUMPRT: print the u16 at V_NUM right-aligned in a 5-cell field from the
; next cell, leading zeros blanked, DCOLOR applied. Flips WC on for the
; 16-bit repeated subtraction and restores WC=0 before returning.
; Calls one down (DPUTC). Clobbers R0,R1,R3, V_NUM, V_TMP.
NUMPRT: EORZ    R0
        STRA,R0 V_TMP           ; nonzero-seen flag
        LODI,R1 0               ; power-of-ten byte index: 0,2,4,6
NUMP1:  LODI,R3 0               ; digit
NUMP2:  PPSL    $09             ; WC on, C=1 (no borrow in)
        LODA,R0 V_NUM+1
        SUBA,R0 PW10+1,R1
        STRA,R0 V_NUM+1
        LODA,R0 V_NUM
        SUBA,R0 PW10,R1
        STRA,R0 V_NUM
        CPSL    $08             ; WC off (C preserved)
        TPSL    $01
        BCFR,EQ NUMP3           ; C=0: borrowed, undo
        ADDI,R3 1
        BCTR,UN NUMP2
NUMP3:  PPSL    $08             ; WC on, C=0: plain 16-bit add-back
        LODA,R0 V_NUM+1
        ADDA,R0 PW10+1,R1
        STRA,R0 V_NUM+1
        LODA,R0 V_NUM
        ADDA,R0 PW10,R1
        STRA,R0 V_NUM
        CPSL    $09             ; WC off, C clear
        LODZ    R3
        BCFR,EQ NUMPD           ; a digit: print it
        LODA,R0 V_TMP
        BCFR,EQ NUMPZD          ; zero after a digit: print '0'
        EORZ    R0              ; leading zero: blank cell
        BSTA,UN DPUTC
        BCTR,UN NUMPN
NUMPD:  LODI,R0 1
        STRA,R0 V_TMP
NUMPZD: LODZ    R3
        IORI,R0 $10
        BSTA,UN DPUTC
NUMPN:  ADDI,R1 2
        COMI,R1 8
        BCFA,EQ NUMP1
        LODA,R0 V_NUM+1         ; ones digit: always printed
        IORI,R0 $10
        BSTA,UN DPUTC
        RETC,UN

PW10:   DWBE    10000
        DWBE    1000
        DWBE    100
        DWBE    10

; RXPRNT: print exactly R1 cells from the state cursor (RXNEXT bytes),
; truncating at the field or padding past a NUL -- the zero-copy string
; renderer for names, moves and banners. The cursor is left wherever the
; NUL (or the field edge) put it; callers position it per field.
; Calls two down (RXNEXT -> MSLICE). Clobbers R0,R1,R3, V_TMP2.
RXPRNT: LODZ    R1
        STRA,R0 V_TMP2
RXP1:   LODA,R0 V_TMP2
        BCTR,EQ RXP9
        SUBI,R0 1
        STRA,R0 V_TMP2
        BSTA,UN RXNEXT
        BCTR,EQ RXPPAD          ; NUL: pad the rest
        BSTA,UN DXLAT
        BSTA,UN DPUTC
        BCTR,UN RXP1
RXPPAD: EORZ    R0
        BSTA,UN DPUTC
        LODA,R0 V_TMP2
        BCTR,EQ RXP9
        SUBI,R0 1
        STRA,R0 V_TMP2
        BCTR,UN RXPPAD
RXP9:   RETC,UN

; ---- ASCII $20-$7F -> glyph, 96 entries; no UDC codes ------------------
XLAT:   DB      $00,$34,$34,$34,$37,$34,$34,$34 ; spc ! " # $ % & '
        DB      $34,$34,$34,$36,$35,$34,$34,GDIAG ; ( ) * + , - . /
        DB      $10,$11,$12,$13,$14,$15,$16,$17 ; 0-7
        DB      $18,$19,$34,$34,$34,$34,$34,$34 ; 8 9 : ; < = > ?
        DB      $34,$1A,$1B,$1C,$1D,$1E,$1F,$20 ; @ A-G
        DB      $21,$22,$23,$24,$25,$26,$27,$28 ; H-O
        DB      $29,$2A,$2B,$2C,$2D,$2E,$2F,$30 ; P-W
        DB      $31,$32,$33,$34,$34,$34,$34,$34 ; X Y Z [ \ ] ^ _
        DB      $34,$1A,$1B,$1C,$1D,$1E,$1F,$20 ; ` a-g
        DB      $21,$22,$23,$24,$25,$26,$27,$28 ; h-o
        DB      $29,$2A,$2B,$2C,$2D,$2E,$2F,$30 ; p-w
        DB      $31,$32,$33,$34,$34,$34,$34,$34 ; x y z { | } ~ del
