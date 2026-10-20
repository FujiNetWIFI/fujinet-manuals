; cards.inc -- cards as two cells, [rank][suit], white on black.
;
; Not inverse on a white face: a 3x5 rank's outer strokes then merge into the
; gap beside it and a K loses its stem. The wire's 't' is drawn T. A hole card
; ("??") is a hatched app-glyph pair, the right cell a pixel narrower so two
; backs stay apart.

; glyphs -- teach the cart the app glyphs.
        FIT     32
glyphs: LDR     RB, gtab
gly1:   LDA     RB
        BZ      gly3
        FCALL   d_par                   ; the code
        LDI     12
        PLO     RC
gly2:   LDA     RB
        FCALL   d_par                   ; 12 scanlines, bit 3 the leftmost
        DEC     RC
        GLO     RC
        BNZ     gly2
        LDI     TOP_GLYPH
        FCALL   d_op
        BR      gly1
gly3:   FRET

gtab:   DB      G_BACKL, 0, 0AH, 05H, 0AH, 05H, 0AH, 05H, 0AH, 05H, 0AH, 05H, 0
        DB      G_BACKR, 0, 0AH, 04H, 0AH, 04H, 0AH, 04H, 0AH, 04H, 0AH, 04H, 0
        DB      0

; dhand -- the hand at RB: five cards, ten cells. A NUL rank ends the hand
; (the string is NUL-padded); the rest of the field is blanked.
        FIT     72
dhand:  LDI     5
        PLO     RC
dh1:    LDA     RB
        BZ      dh7
        PLO     R9
        XRI     '?'
        BNZ     dh2
        INC     RB                      ; the suit is '?' too
        LDI     G_BACKL
        FCALL   d_putc
        LDI     G_BACKR
        BR      dh6
dh2:    GLO     R9                      ; a rank: digits stand, letters fold
        SMI     'a'
        BNF     dh3
        GLO     R9
        SMI     20H
        BR      dh4
dh3:    GLO     R9
dh4:    FCALL   d_putc
        LDA     RB                      ; the suit
        PLO     R9
        LDR     R8, suits
dh5:    LDA     R8
        BZ      dh5x                    ; not a suit: '?'
        STR     R2
        GLO     R9
        XOR
        BZ      dh5x
        INC     R8
        BR      dh5
dh5x:   LDN     R8
dh6:    FCALL   d_putc
        DEC     RC
        GLO     RC
        BNZ     dh1
        FRET
dh7:    GLO     RC                      ; two blank cells a card left
        SHL
        FJMP    blanks

suits:  DB      'h', SYM_HEART, 'd', SYM_DIAMOND, 'c', SYM_CLUB, 's', SYM_SPADE
        DB      0, '?'
