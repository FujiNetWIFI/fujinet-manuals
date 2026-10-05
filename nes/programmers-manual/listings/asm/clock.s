; clock.s -- the FujiNet's network time, once a second.
;
; The clock device answers 'I' with a 25-byte ISO 8601 string in the
; FujiNet's time zone: 2026-10-04T18:20:00-0500. The date and the time are
; copied straight from the reply window to the screen during vblank.

        .include "book.inc"
        .export main


        .segment "ZEROPAGE"
tick:   .res 1

        .segment "CODE"
.proc main
        PUTS    2, 2, title
        jsr     disp_on

loop:   CALL    FNDEVC, CLKISO, 0
        jsr     fn_go                   ; runs with the screen on: the NMI
        bne     wait                    ; may land anywhere in it
        jsr     fn_ack
        bne     wait

        jsr     wait_vbl
        lda     #5
        ldx     #2
        jsr     disp_at
        ldx     #0                      ; "2026-10-04"
        ldy     #10
        jsr     disp_rpl
        lda     #6
        ldx     #2
        jsr     disp_at
        ldx     #11                     ; "18:20:00"
        ldy     #8
        jsr     disp_rpl
        jsr     scroll0

wait:   lda     #60
        sta     tick
:       jsr     wait_vbl
        dec     tick
        bne     :-
        jmp     loop
.endproc

        .segment "RODATA"
title:  .byte "CLOCK", 0
