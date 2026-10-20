; keys.asm -- both keypads, drawn on the screen;
; the last key pressed on each is lit, the key
; code is shown, and every press beeps.
;
; in_get (input.inc) returns a key just pressed
; or repeating: KEY_A + k for pad A, KEY_B + k
; for pad B. The ISR sounds the beeper while
; RD.0 counts down.

        CPU     1802
        INCLUDE "fujinet.inc"
        INCLUDE "s2macro.inc"
        INCLUDE "s2defs.inc"

PADA    EQU     01H             ; pad A: column 1
PADB    EQU     0AH             ; pad B: column 10
V_LA    EQU     V_APP           ; pad A's lit key
V_LB    EQU     V_APP+1         ; pad B's, or $FF

        ORG     0400H
        INCLUDE "s2call.inc"
        INCLUDE "fujilib.inc"
        INCLUDE "fujidisp.inc"
        INCLUDE "input.inc"

        ORG     0C00H
        INCLUDE "booklib.inc"

        FIT     141
main:   FCALL   d_cls
        PUTS    00H, t_title
        PUTS    71H, t_pada
        PUTS    7AH, t_padb
        PUTS    90H, t_last
        LDI     PADA
        PLO     RB
        FCALL   pad
        LDI     PADB
        PLO     RB
        FCALL   pad
        LDR     R8, V_LA        ; nothing lit yet
        LDI     0FFH
        STR     R8
        INC     R8
        STR     R8
loop:   FCALL   in_get
        BZ      loop
        PLO     RA
        LDI     96H             ; the code: A5, B9
        FCALL   d_at
        GLO     RA
        FCALL   d_hex
        GLO     RA
        ANI     0FH
        BNZ     lp1
        LDI     40              ; 0: a long beep
        BR      lp2
lp1:    LDI     8
lp2:    PLO     RD              ; the ISR beeps
        GLO     RA
        ANI     0F0H
        XRI     KEY_A
        BNZ     lp3
        LDI     PADA
        PLO     RB
        LDR     RC, V_LA
        BR      lp4
lp3:    LDI     PADB
        PLO     RB
        LDR     RC, V_LB
lp4:    FCALL   light
        BR      loop

; light -- unlight the key at M(RC), light key
; RA.0 & $0F of the pad at column RB.0.
        FIT     40
light:  LDN     RC
        XRI     0FFH
        BZ      lgt1            ; none lit
        LDN     RC
        PLO     RA              ; RA.1 = 0: plain
        LDI     0
        PHI     RA
        FCALL   cell
lgt1:   GLO     RA
        ANI     0FH
        PLO     RA
        STR     RC
        LDI     1
        PHI     RA              ; RA.1 = 1: lit
        FCALL   cell
        FRET

; pad -- the ten keys of the pad at RB.0.
        FIT     24
pad:    LDI     0
        PHI     RA
        PLO     RA
pad1:   FCALL   cell
        INC     RA
        GLO     RA
        XRI     10
        BNZ     pad1
        FRET

; cell -- key RA.0 of the pad at column RB.0,
; in inverse when RA.1 is not 0.
        FIT     40
cell:   LDI     LO(t_pos)
        STR     R2
        GLO     RA
        ADD
        PLO     R8
        LDI     HI(t_pos)
        PHI     R8
        LDN     R8              ; row, column
        STR     R2
        GLO     RB
        ADD                     ; + the pad's column
        FCALL   d_at
        GHI     RA
        BZ      cel1
        LDI     TOP_INV_ON
        FCALL   d_op
cel1:   GLO     RA
        ADI     '0'
        FCALL   d_putc
        LDI     TOP_INV_OFF
        FCALL   d_op
        FRET

; where each key sits: 1-9 in a square, 0 below
        FIT     10
t_pos:  DB      52H, 20H, 22H, 24H, 30H
        DB      32H, 34H, 40H, 42H, 44H
t_title: DB     "KEYPADS", 0
t_pada: DB      "PAD A", 0
t_padb: DB      "PAD B", 0
t_last: DB      "LAST", 0

        S2CLAIM
