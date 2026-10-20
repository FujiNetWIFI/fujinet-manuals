; clock.s -- the time of day, from the adapter's clock.
;
; The clock is a device of its own ($45). GET_ISO_LOCAL answers with the
; local time as text -- "2026-10-20T10:45:31" and a NUL -- in the adapter's
; configured time zone, and GET_ISO_UTC the same in UTC. Each goes on the
; screen straight out of the reply window.

        .include "fujinet.inc"
        .include "devdefs.inc"

        .import disp_at, disp_str, disp_hex, disp_on, disp_rpl
        .import fn_chk, fn_beg, fn_go, fn_ack
        .export main, nmi

        .segment "ZEROPAGE"
aperr:  .res 1

        .segment "CODE"

.macro  PUTS    row, col, str
        lda     #row
        ldx     #col
        jsr     disp_at
        lda     #<str
        sta     FN_PTR
        lda     #>str
        sta     FN_PTR+1
        jsr     disp_str
.endmacro

; ASK cmd, row -- a clock command with no parameters, its text on the row.
.macro  ASK     cmd, row
        lda     #CLKDEV
        sta     FN_DEV
        lda     #cmd
        sta     FN_CMD
        lda     #0
        sta     FN_NPR
        jsr     fn_beg
        jsr     go_ack
        lda     #row
        ldx     #10
        jsr     disp_at
        ldx     #0
        ldy     #25
        jsr     disp_rpl
.endmacro

.proc main
        PUTS    2, 2, title
        jsr     disp_on
        jsr     fn_chk
        beq     @go
        lda     #FNENOC
        sta     aperr
        jmp     fail
@go:    PUTS    5, 2, tlocal
        ASK     CKISOL, 5
        PUTS    7, 2, tutc
        ASK     CKISOU, 7
loop:   jmp     loop
.endproc

; go_ack -- fn_go, then fn_ack; on any failure, the failure screen.
.proc go_ack
        jsr     fn_go
        sta     aperr
        bne     @bad
        jsr     fn_ack
        sta     aperr
        bne     @bad
        rts
@bad:   pla
        pla
        jmp     fail
.endproc

.proc fail
        PUTS    22, 2, tfail
        lda     aperr
        jsr     disp_hex
@h:     jmp     @h
.endproc

.proc nmi
        rti
.endproc

        .segment "RODATA"
title:  .byte "CLOCK", 0
tlocal: .byte "LOCAL", 0
tutc:   .byte "UTC", 0
tfail:  .byte "FAILED: E", 0
