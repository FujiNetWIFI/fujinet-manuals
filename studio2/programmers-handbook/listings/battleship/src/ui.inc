; ui.inc -- keys, waits, numbers and text out of the reply window.
;
; Every routine is FCALLed and may clobber R8, R9, RB, RC and RA.0.

; ---- keys ----
; A transaction can take most of a second, so the keypads are also scanned
; while one runs (net.inc's ngo) and an edge seen there is kept for kget.

; kpoll -- scan once; a new press is latched in V_KLAT unless one waits.
        FIT     40
kpoll:  FCALL   in_scan
        PLO     R9
        VAR     V_KLAST
        GLO     R9
        SEX     RA
        XOR
        SEX     R2
        BZ      kpl9                    ; held, or still nothing
        GLO     R9
        STR     RA
        BZ      kpl9                    ; a release
        VAR     V_KLAT
        LDN     RA
        BNZ     kpl9                    ; the first press wins
        GLO     R9
        STR     RA
kpl9:   FRET

; kget -- D = a key pressed since the last kget (KEY_A/KEY_B + k), or 0.
        FIT     24
kget:   FCALL   kpoll
        VAR     V_KLAT
        LDN     RA
        PLO     R9
        LDI     0
        STR     RA
        GLO     R9
        BZ      kgt9
        BEEP    2
        GLO     R9
kgt9:   FRET

; krep -- D = a key just pressed (kget), or the one still held again
; KEY_DELAY frames on and every KEY_RATE frames after; else 0. A press also
; stirs the frame count into the placement dice.
        FIT     72
krep:   FCALL   kget
        BZ      kr1
        PLO     R9
        GLO     RE
        ADI     KEY_DELAY
        PUTV    V_KTM
        VAR     V_RND+1
        GLO     RE
        SEX     RA
        XOR
        SEX     R2
        STR     RA
        GLO     R9
        FRET
kr1:    GETV    V_KLAST                 ; held since kpoll's last look?
        BZ      kr9
        PLO     R9
        GETV    V_KTM
        STR     R2
        GLO     RE
        SM                              ; RE.0 - V_KTM, signed
        ANI     80H
        BNZ     kr8                     ; not yet
        GLO     RE
        ADI     KEY_RATE
        PUTV    V_KTM
        GLO     R9
        FRET
kr8:    LDI     0
kr9:    FRET

; kwait -- D = the next key's digit, 0-9.
        FIT     12
kwait:  FCALL   kget
        BZ      kwait
        ANI     0FH
        FRET

; wframes -- wait D frames, scanning the keys.
        FIT     40
wframes:
        PLO     RC
wf1:    GLO     RC
        BZ      wf9
        GLO     RE
        PUTV    V_T0
wf2:    FCALL   kpoll
        GETV    V_T0
        STR     R2
        GLO     RE
        XOR
        BZ      wf2
        DEC     RC
        BR      wf1
wf9:    FRET

; ---- text ----

; rpu -- draw the text at RB in a field of D cells, folded to upper case:
; up to a NUL or the field's end, then blanks. R8.1 is the mode: 0 every
; character, 1 the field ends at a space, 2 spaces are skipped. RB is left
; past what was read.
        FIT     72
rpu:    PLO     R8
        LDI     TX_PUTC
        PHI     RF
rpu1:   GLO     R8
        BZ      rpu9
        LDN     RB
        BZ      rpu6                    ; NUL: blanks from here
        INC     RB
        PLO     R9
        XRI     ' '
        BNZ     rpu3
        GHI     R8
        BZ      rpu3                    ; mode 0: a space is drawn
        XRI     2
        BZ      rpu1                    ; mode 2: skipped
        BR      rpu6                    ; mode 1: the field ends
rpu3:   GLO     R9
        ANI     80H
        BNZ     rpu4                    ; not ASCII: never an app glyph
        GLO     R9
        SMI     'a'
        BNF     rpu5
        SMI     26
        BDF     rpu5
        GLO     R9
        SMI     20H
        BR      rpu7
rpu4:   LDI     '?'
        BR      rpu7
rpu5:   GLO     R9
rpu7:   PLO     RF
        LDN     RF
        DEC     R8
        BR      rpu1
rpu6:   GLO     R8
        BZ      rpu9
        LDI     ' '
        PLO     RF
        LDN     RF
        DEC     R8
        BR      rpu6
rpu9:   LDI     FN_PARK
        PHI     RF
        FRET

; blanks -- D spaces at the cursor.
blanks: PLO     R9
        LDI     ' '
        FCALL   d_par
        GLO     R9
        FCALL   d_par
        LDI     TOP_REPEAT
        FJMP    d_op

; ---- numbers ----

; num5 -- V_DIGS = R8 in decimal, five cells, leading blanks.
        FIT     72
num5:   VAR     V_DIGS
        LDI     0
        PLO     RC                      ; no digit drawn yet
        LDR     RB, pow10
nm1:    LDI     0
        PHI     R9                      ; this digit
nm2:    SEX     RB
        GLO     R8
        SM                              ; table is lo, hi
        PLO     R9
        INC     RB
        GHI     R8
        SMB
        DEC     RB
        SEX     R2
        BNF     nm3                     ; would go below zero
        PHI     R8
        GLO     R9
        PLO     R8
        GHI     R9
        ADI     1
        PHI     R9
        BR      nm2
nm3:    GHI     R9
        BNZ     nm4
        GLO     RC
        BNZ     nm4
        LDI     ' '
        BR      nm5
nm4:    LDI     1
        PLO     RC
        GHI     R9
        ADI     '0'
nm5:    STR     RA
        INC     RA
        INC     RB
        INC     RB
        GLO     RB
        XRI     LO(pow10+8)
        BNZ     nm1
        GLO     R8
        ADI     '0'
        STR     RA
        FRET

pow10:  DB      10H, 27H                ; 10000
        DB      0E8H, 03H               ; 1000
        DB      64H, 00H                ; 100
        DB      0AH, 00H                ; 10

; pnum -- the last D (1-5) cells of V_DIGS: the number right-aligned.
        FIT     24
pnum:   PLO     R9
        SDI     5
        ADI     LO(V_DIGS)
        PLO     RA
pn1:    LDA     RA
        FCALL   d_putc
        DEC     R9
        GLO     R9
        BNZ     pn1
        FRET

; pnuml -- V_DIGS left-aligned in a field of D cells (D >= its digits).
        FIT     48
pnuml:  PLO     R9
        VAR     V_DIGS
pl1:    LDN     RA
        XRI     ' '
        BNZ     pl2
        INC     RA                      ; the last cell is never blank
        BR      pl1
pl2:    GLO     R9
        BZ      pl4
        LDA     RA
        FCALL   d_putc
        DEC     R9
        GLO     RA
        XRI     LO(V_DIGS+5)
        BNZ     pl2
        GLO     R9
        FJMP    blanks
pl4:    FRET

; dnum -- R8 right-aligned in D cells.
dnum:   STXD
        FCALL   num5
        IRX
        LDX
        FJMP    pnum

; ---- the reply window ----

; radd -- RB += D.
radd:   STR     R2
        GLO     RB
        ADD
        PLO     RB
        GHI     RB
        ADCI    0
        PHI     RB
        FRET

; rpeek -- RB = RPLY + D; D = the byte there. For offsets below 256.
rpeek:  PLO     RB
        LDI     HI(RPLY)
        PHI     RB
        LDN     RB
        FRET

; precd -- RB = RPLY + R8.0 + D * R9.0: seat D's record, the records
; starting at R8.0 and R9.0 apart. Clobbers RC.
        FIT     24
precd:  PLO     RC
        LDI     HI(RPLY)
        PHI     RB
        LDI     LO(RPLY)
        PLO     RB
        GLO     R8
        FCALL   radd
pcd1:   GLO     RC
        BZ      pcd9
        GLO     R9
        FCALL   radd
        DEC     RC
        BR      pcd1
pcd9:   FRET

; prec -- RB = in-play player record D (115 bytes a seat).
prec:   PLO     RC
        LDI     GPLYRS
        PLO     R8
        LDI     PSTRIDE
        PLO     R9
        GLO     RC
        FJMP    precd

; lrec -- RB = lobby or placement player record D (10 bytes a seat): the
; lobby's start after the server name, placement's where play's do.
        FIT     24
lrec:   PLO     RC
        GETV    V_ST
        BZ      lrc1
        LDI     GPLYRS
        BR      lrc2
lrc1:   LDI     GLPLYRS
lrc2:   PLO     R8
        LDI     LSTRIDE
        PLO     R9
        GLO     RC
        FJMP    precd

; rword -- R8 = the u16 at RB (LE).
rword:  LDA     RB
        PLO     R8
        LDN     RB
        PHI     R8
        FRET
