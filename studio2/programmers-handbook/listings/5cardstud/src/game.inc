; game.inc -- st_game: the table.
;
; Poll /state, draw it, offer the moves the server says are legal, send one.
; Every poll redraws the whole screen out of the reply window; rewriting a
; cell with what it already holds changes no pixel, so nothing flickers and
; nothing is tracked.
;
;   rows 0-7  a seat each, in the server's order (seat 0, YOU, is us):
;             NAME_ then five cards, [rank][suit] -- or FOLDED / LEFT /
;             WAITING; with 9 (chips) the purse and the last move instead.
;             The player to act has the name in inverse.
;   row 8     POT nnnnn  Rn :ss   (the street; the clock of the player to act)
;   row 9     the last hand's result, scrolling; or the key legend
;   rows 8-9  on our turn: the moves, 2 x 2, [n]NAME; slot 4 shows the pot
;             when it is free.

POLLF   EQU     90              ; frames between polls
FAILF   EQU     180             ; and after a failed one
MQRATE  EQU     15              ; frames per marquee step
HOLDP   EQU     3               ; polls a new result stays on row 9

; st_game -- sit down at V_TABLE (or come back from the menu).
        FIT     64
st_game:
        RESET
        SETV    V_SEAT, 1
        SETV    V_REQ, REQ_STATE
        SETV    V_OK, 0
        SETV    V_PNMV, 0
        SETV    V_MQON, 0
        SETV    V_HOLD, 0
        FCALL   d_cls
        PUTS    40H, s_joining
        FJMP    gpoll

; gpoll -- one request (V_REQ: a /state, or the /move whose reply is the
; next state), validated, then drawn.
        FIT     120
gpoll:  LDR     R8, GMINLEN
        LDR     R9, GMAXLEN
        FCALL   setlim
        FCALL   nfetch
        PLO     RC
        SETV    V_REQ, REQ_STATE
        GLO     RC
        BNZ     gfail
        LDI     GPLCNT                  ; at most GMAXPL seats, and exactly
        FCALL   rpeek                   ; the length they imply
        SMI     GMAXPL+1
        BDF     gbad
        LDR     R8, GMINLEN
        LDI     PSTRIDE
        PLO     R9
        LDI     GPLCNT
        FCALL   rpeek
        FCALL   vlen
        BNZ     gbad
        SETV    V_OK, 1
        FCALL   gcues
        FCALL   grender
        FCALL   gturn
        SETV    V_IVL, POLLF
        FJMP    gwait
gbad:   LDI     FE_LEN
gfail:  PUTV    V_ERRC
        SETV    V_OK, 0                 ; the window is not a state now
        SETV    V_MQON, 0
        AT      90H
        OP      TOP_INV_ON
        LDR     R8, s_neterr
        FCALL   d_puts
        GETV    V_ERRC
        FCALL   d_hex
        OP      TOP_INV_OFF
        OP      TOP_CLREOL
        BEEP    20
        SETV    V_IVL, FAILF
        FJMP    gwait

; gwait -- V_IVL frames of keys and marquee, then the next poll.
        FIT     120
gwait:  GLO     RE
        PUTV    V_T0
gw1:    FCALL   kget
        BNZ     gkey
        FCALL   mqstep
        GETV    V_T0
        STR     R2
        GLO     RE
        SM                              ; frames gone
        STR     R2
        GETV    V_IVL
        SD                              ; gone - interval
        BNF     gw1
        FJMP    gpoll
gkey:   ANI     0FH
        PLO     RC
        BZ      gkmenu
        XRI     9
        BZ      gkview
        GETV    V_OK
        BZ      gw1
        GETV    V_NMV                   ; a move: only one the server offers
        STR     R2
        GLO     RC
        SD                              ; count - key
        BNF     gw1
        GLO     RC
        SMI     1
        FCALL   mvrec
        VAR     V_MOVE
        LDA     RB
        STR     RA
        INC     RA
        LDN     RB
        STR     RA
        SETV    V_REQ, REQ_MOVE         ; its reply is the next state
        SETV    V_OK, 0
        PUTS    80H, s_sending
        OP      TOP_CLREOL
        AT      90H
        OP      TOP_CLREOL
        BEEP    6
        FJMP    gpoll
gkmenu: FJMP    st_menu
gkview: GETV    V_VIEW
        XRI     1
        STR     RA
        GETV    V_OK
        BZ      gw1
        FCALL   grender
        BR      gw1

; gcues -- age the result banner, and restart it when lastResult changes.
; The round cannot say a hand ended: at a small table where everyone folds,
; the next hand is dealt without the round leaving 1. lastResult always
; changes, so a checksum of it is watched (Channel F's finding).
        FIT     96
gcues:  GETV    V_HOLD
        BZ      gc1
        SMI     1
        STR     RA
gc1:    LDR     RB, FN_REPLY+GLAST
        LDI     0
        PLO     R9                      ; sum
        PHI     R9                      ; length
gc2:    LDA     RB
        BZ      gc3
        STR     R2
        GLO     R9
        ADD
        PLO     R9
        GHI     R9
        ADI     1
        PHI     R9
        XRI     80                      ; 81 bytes, not always terminated
        BNZ     gc2
gc3:    GHI     R9
        PUTV    V_MQLEN
        SMI     17
        BNF     gc4                     ; it fits the row: no scrolling
        GHI     R9
        ADI     3
        BR      gc5
gc4:    LDI     0
gc5:    PUTV    V_MQW
        GETV    V_LRSUM
        STR     R2
        GLO     R9
        XOR
        BZ      gc9
        GLO     R9
        PUTV    V_LRSUM
        SETV    V_HOLD, HOLDP
        SETV    V_MQPOS, 0
        GLO     RE
        PUTV    V_MQT
gc9:    FRET

; gturn -- beep on the edge where moves start being offered: it stays our
; turn for many polls, and on the level it would beep at every one.
        FIT     24
gturn:  GETV    V_PNMV
        PLO     RC
        GETV    V_NMV
        PUTV    V_PNMV
        GETV    V_NMV
        BZ      gt9
        GLO     RC
        BNZ     gt9
        BEEP    40
gt9:    FRET

; grender -- the whole screen from the window.
        FIT     96
grender:
        LDI     GPLCNT
        FCALL   rpeek
        PUTV    V_PC
        LDI     GACTPL
        FCALL   rpeek
        PUTV    V_ACT
        LDI     GMVCNT
        FCALL   rpeek
        PUTV    V_NMV
        LDI     GROUND
        FCALL   rpeek
        PUTV    V_RND
        SETV    V_ROW, 0
grn1:   FCALL   grow
        GETV    V_ROW
        ADI     1
        STR     RA
        XRI     8
        BNZ     grn1
        SETV    V_MQON, 0
        GETV    V_NMV
        BZ      grn2
        FJMP    gmoves
grn2:   GETV    V_MQLEN                 ; the result scrolls while it is news
        BZ      grn4
        GETV    V_HOLD
        BNZ     grn3
        GETV    V_RND
        BZ      grn3                    ; between hands
        XRI     5
        BNZ     grn4                    ; not the showdown
grn3:   SETV    V_MQON, 1
grn4:   FCALL   gstat
        FJMP    gmsg

; grow -- seat V_ROW on row V_ROW.
        FIT     120
grow:   GETV    V_ROW
        SHL
        SHL
        SHL
        SHL
        FCALL   d_at
        GETV    V_PC
        STR     R2
        GETV    V_ROW
        SM                              ; row - players
        BNF     grw1
        OP      TOP_CLREOL              ; an empty seat
        FRET
grw1:   GETV    V_ACT
        STR     R2
        GETV    V_ROW
        XOR
        BNZ     grw2
        OP      TOP_INV_ON              ; the player to act
grw2:   GETV    V_ROW                   ; seat 0 is us, unless watching
        BNZ     grw2n
        LDI     GVIEW
        FCALL   rpeek
        BNZ     grw2n
        LDR     R8, s_you
        FCALL   d_puts
        BR      grw2s
grw2n:  GETV    V_ROW
        FCALL   prec
        LDI     1                       ; the name up to its first space:
        PHI     R8                      ; "hulk bot" is HULK
        LDI     5
        FCALL   rpu
        LDI     ' '
        FCALL   d_putc
grw2s:  OP      TOP_INV_OFF
        GETV    V_VIEW
        BNZ     grchip
        GETV    V_ROW
        FCALL   prec
        LDI     PSTAT
        FCALL   radd
        LDN     RB
        XRI     1
        BZ      grhand
        LDN     RB                      ; out of this hand: say why
        BZ      grw3
        XRI     2
        BZ      grw4
        LDR     R8, s_left
        BR      grw5
grw3:   LDR     R8, s_waiting
        BR      grw5
grw4:   LDR     R8, s_folded
grw5:   FCALL   d_puts
        OP      TOP_CLREOL
        FRET
grhand: LDI     PHAND-PSTAT
        FCALL   radd
        FJMP    dhand
grchip: GETV    V_ROW                   ; purse, then the last move
        FCALL   prec
        LDI     PPURSE
        FCALL   radd
        FCALL   rword
        LDI     5
        FCALL   dnum
        LDI     ' '
        FCALL   d_putc
        GETV    V_ROW
        FCALL   prec
        LDI     PMOVE
        FCALL   radd
        LDI     0
        PHI     R8
        LDI     4
        FJMP    rpu

; prec -- RB = player record D.
        FIT     24
prec:   PLO     RC
        LDR     RB, FN_REPLY+GPLYRS
prc1:   GLO     RC
        BZ      prc9
        LDI     PSTRIDE
        FCALL   radd
        DEC     RC
        BR      prc1
prc9:   FRET

; mvrec -- RB = the code of offered move D; D = its first letter.
        FIT     24
mvrec:  PLO     RC
        LDI     GMOVES
        PLO     R9
mv1:    GLO     RC
        BZ      mv2
        GLO     R9
        ADI     MVSTRID
        PLO     R9
        DEC     RC
        BR      mv1
mv2:    GLO     R9
        FJMP    rpeek

; gstat -- row 8: POT nnnnn  Rn :ss
        FIT     100
gstat:  PUTS    80H, s_pot
        LDI     GPOT
        FCALL   rpeek
        FCALL   rword
        FCALL   num5
        LDI     5
        FCALL   pnuml
        LDI     ' '
        FCALL   d_putc
        GETV    V_RND
        BZ      gs1                     ; between hands
        SMI     5
        BDF     gs2                     ; the showdown
        LDI     'R'
        FCALL   d_putc
        GETV    V_RND
        ADI     '0'
        FCALL   d_putc
        LDI     ' '
        FCALL   d_putc
        BR      gs3
gs1:    LDI     3
        FCALL   blanks
        BR      gs3
gs2:    LDR     R8, s_end
        FCALL   d_puts
gs3:    GETV    V_ACT
        XRI     0FFH
        BZ      gs4                     ; nobody to act
        LDI     GMVTIM
        FCALL   rpeek
        BZ      gs4                     ; no clock running
        PLO     R8
        LDI     0
        PHI     R8
        LDI     ':'
        FCALL   d_putc
        LDI     2
        FJMP    dnum
gs4:    LDI     3
        FJMP    blanks

; gmsg -- row 9: the result while it is news, else WATCHING or the legend.
        FIT     48
gmsg:   GETV    V_MQON
        BZ      gms1
        FJMP    mqdraw
gms1:   AT      90H
        LDI     GVIEW
        FCALL   rpeek
        BZ      gms2
        LDR     R8, s_watching
        BR      gms3
gms2:   LDR     R8, s_legcard
        GETV    V_VIEW
        BZ      gms3
        LDR     R8, s_legchip
gms3:   FCALL   d_puts
        OP      TOP_CLREOL
        FRET

; gmoves -- rows 8-9 on our turn: [n]NAME in four 8-cell slots.
        FIT     120
gmoves: SETV    V_CTR, 0
gmv1:   GETV    V_CTR                   ; row 8 + k/2, column 8 * (k & 1)
        ANI     2
        SHL
        SHL
        SHL
        STR     R2
        GETV    V_CTR
        ANI     1
        SHL
        SHL
        SHL
        OR
        ORI     80H
        FCALL   d_at
        GETV    V_CTR
        STR     R2
        GETV    V_NMV
        SM                              ; count - k
        BZ      gmv3
        BNF     gmv3
        OP      TOP_INV_ON
        GETV    V_CTR
        ADI     '1'
        FCALL   d_putc
        OP      TOP_INV_OFF
        GETV    V_CTR
        FCALL   mvrec
        LDI     MVNAME
        FCALL   radd
        LDI     2                       ; "raise 10" is RAISE10
        PHI     R8
        LDI     7
        FCALL   rpu
        BR      gmv5
gmv3:   GETV    V_CTR
        XRI     3
        BNZ     gmv4
        LDR     R8, s_pot3
        FCALL   d_puts
        LDI     GPOT
        FCALL   rpeek
        FCALL   rword
        LDI     5
        FCALL   dnum
        BR      gmv5
gmv4:   LDI     8
        FCALL   blanks
gmv5:   GETV    V_CTR
        ADI     1
        STR     RA
        XRI     4
        BNZ     gmv1
        FRET

; mqdraw -- row 9: lastResult from V_MQPOS, folded to upper case, wrapping
; after a three-cell gap when it scrolls.
        FIT     72
mqdraw: AT      90H
        LDI     16
        PLO     RC
        GETV    V_MQPOS
        PLO     R9
md1:    GETV    V_MQLEN
        STR     R2
        GLO     R9
        SM
        BDF     md3                     ; past the end: the gap
        GLO     R9
        FCALL   rpeek                   ; GLAST is offset 0
        PLO     R8
        SMI     'a'
        BNF     md2
        GLO     R8
        SMI     20H
        BR      md4
md2:    GLO     R8
        BR      md4
md3:    LDI     ' '
md4:    FCALL   d_putc
        INC     R9
        GETV    V_MQW
        STR     R2
        GLO     R9
        XOR
        BNZ     md5
        PLO     R9
md5:    DEC     RC
        GLO     RC
        BNZ     md1
        FRET

; mqstep -- one marquee step every MQRATE frames, while it runs.
        FIT     56
mqstep: GETV    V_MQON
        BZ      ms9
        GETV    V_MQW
        BZ      ms9
        GETV    V_MQT
        STR     R2
        GLO     RE
        SM
        SMI     MQRATE
        BNF     ms9
        GLO     RE
        PUTV    V_MQT
        GETV    V_MQPOS
        ADI     1
        PLO     R9
        GETV    V_MQW
        STR     R2
        GLO     R9
        XOR
        BNZ     ms1
        PLO     R9
ms1:    GLO     R9
        PUTV    V_MQPOS
        FJMP    mqdraw
ms9:    FRET
