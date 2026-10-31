; pads.s -- controller 1: the stick, both buttons and the keypad, and a
; tone from POKEY while the bottom button is held.
;
; The stick is two pots, which the VBI copies to PADDL0 (X) and PADDL1 (Y)
; every frame; they read nothing until CONSOL bit 2 turns them on. The
; bottom button is GTIA's TRIG0 (0 while held). The top button is POKEY's
; SKSTAT bit 3, clear while the top button of the controller CONSOL's bits
; 0-1 pick is held. The keypad is a52init.s's: KEY holds the last key + 1.

        .include "fujinet.inc"
        .include "book.inc"

        .import disp_init, disp_at, disp_str, disp_putc, disp_on
        .export main

TONE    = $50                   ; AUDF1: the pitch
VOICE   = $A8                   ; AUDC1: a pure tone at volume 8

        .segment "CODE"

.proc main
        jsr     disp_init
        lda     #$04            ; the pots on; controller 1's keypad and top button
        sta     CONSOL
        PUTS    2, 2, title
        PUTS    4, 2, tstx
        PUTS    5, 2, tsty
        PUTS    7, 2, tbot
        PUTS    8, 2, ttop
        PUTS    10, 2, tkey
        PUTS    12, 2, tsnd
        jsr     disp_on

loop:   WAITFRAME
        lda     #4              ; the stick, as the VBI last read it
        ldx     #16
        jsr     disp_at
        lda     PADDL0
        jsr     dec3
        lda     #5
        ldx     #16
        jsr     disp_at
        lda     PADDL0+1
        jsr     dec3

        lda     #7              ; the bottom button: TRIG0 is 0 while held
        ldx     #16
        jsr     disp_at
        lda     TRIG0
        jsr     updown
        lda     #8              ; the top button: SKSTAT bit 3 clear while held
        ldx     #16
        jsr     disp_at
        lda     SKSTAT
        and     #$08
        jsr     updown

        lda     #10             ; the last key
        ldx     #16
        jsr     disp_at
        ldx     KEY
        lda     knlo,x
        sta     FN_PTR
        lda     knhi,x
        sta     FN_PTR+1
        jsr     disp_str

        lda     #12             ; a tone while the bottom button is held
        ldx     #16
        jsr     disp_at
        lda     TRIG0
        bne     quiet
        lda     #TONE
        sta     AUDF1
        lda     #VOICE
        sta     AUDC1
        lda     #<ton
        ldx     #>ton
        jmp     said
quiet:  lda     #0
        sta     AUDC1
        lda     #<toff
        ldx     #>toff
said:   sta     FN_PTR
        stx     FN_PTR+1
        jsr     disp_str
        jmp     loop
.endproc

; updown -- "DOWN" if A is 0 (held), else "UP  ".
.proc updown
        cmp     #0
        bne     up
        lda     #<tdown
        ldx     #>tdown
        jmp     show
up:     lda     #<tup
        ldx     #>tup
show:   sta     FN_PTR
        stx     FN_PTR+1
        jmp     disp_str
.endproc

; dec3 -- A as three decimal digits, leading zeros as spaces, so a shorter
; number overwrites a longer one.
.proc dec3
        ldx     #0              ; hundreds
:       cmp     #100
        bcc     :+
        sbc     #100
        inx
        bne     :-
:       sta     ZTMP
        txa
        sta     ZTMP+1          ; nonzero once a digit has been shown
        jsr     digit
        lda     ZTMP
        ldx     #0              ; tens
:       cmp     #10
        bcc     :+
        sbc     #10
        inx
        bne     :-
:       sta     ZTMP
        txa
        ora     ZTMP+1
        sta     ZTMP+1
        txa
        jsr     digit
        lda     ZTMP            ; ones: always shown
        ora     #'0'
        jmp     disp_putc
digit:  ldy     ZTMP+1
        bne     :+
        lda     #' '
        jmp     disp_putc
:       ora     #'0'
        jmp     disp_putc
.endproc

        .segment "RODATA"
title:  .byte "CONTROLLER 1", 0
tstx:   .byte "STICK X", 0
tsty:   .byte "STICK Y", 0
tbot:   .byte "BOTTOM BUTTON", 0
ttop:   .byte "TOP BUTTON", 0
tkey:   .byte "KEYPAD", 0
tsnd:   .byte "SOUND", 0
tup:    .byte "UP  ", 0
tdown:  .byte "DOWN", 0
ton:    .byte "ON ", 0
toff:   .byte "OFF", 0

; KEY is the key's code + 1: 0 none, then 0-9, *, #, START, PAUSE, RESET.
.define KNAMES kn0, kd0, kd1, kd2, kd3, kd4, kd5, kd6, kd7, kd8, kd9, kstar, khash, kstart, kpause, kreset
knlo:   .lobytes KNAMES
knhi:   .hibytes KNAMES
kn0:    .byte "-    ", 0
kd0:    .byte "0    ", 0
kd1:    .byte "1    ", 0
kd2:    .byte "2    ", 0
kd3:    .byte "3    ", 0
kd4:    .byte "4    ", 0
kd5:    .byte "5    ", 0
kd6:    .byte "6    ", 0
kd7:    .byte "7    ", 0
kd8:    .byte "8    ", 0
kd9:    .byte "9    ", 0
kstar:  .byte "*    ", 0
khash:  .byte "#    ", 0
kstart: .byte "START", 0
kpause: .byte "PAUSE", 0
kreset: .byte "RESET", 0

        .include "header.inc"
