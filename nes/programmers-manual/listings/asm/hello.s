; hello.s -- the first transaction, in assembly.
;
; Asks the FujiNet for GET_ADAPTERCONFIG_EXTENDED and puts the network name,
; the IP address and the firmware version on the screen, straight out of the
; reply window.

        .include "book.inc"
        .export main

AC_SSID = 0                     ; char[33]
AC_VER  = 125                   ; char[15]
AC_SIP  = 140                   ; char[16], the IP already as text

        .segment "CODE"
.proc main
        PUTS    2, 2, title
        jsr     fn_chk          ; 'F','N' in the status page?
        beq     have
        PUTS    5, 2, nocart
        jmp     show

have:   CALL    FNDEVF, FNCADPX, 0
        jsr     fn_go           ; commit, wait for ACKSEQ
        jne     fail            ; A = FN_ERR, or FNEWAIT
        jsr     fn_ack          ; did the FujiNet say ACK?
        jne     fail

        PUTS    5, 2, tssid
        ldx     #AC_SSID        ; window offset
        ldy     #24             ; at most 24 characters
        jsr     disp_rpl
        PUTS    7, 2, tip
        ldx     #AC_SIP
        ldy     #16
        jsr     disp_rpl
        PUTS    9, 2, tver
        ldx     #AC_VER
        ldy     #15
        jsr     disp_rpl
        jmp     show

fail:   pha
        PUTS    5, 2, tfail
        pla
        jsr     disp_hex

show:   PUTS    12, 2, tseq     ; persists across a console Reset
        lda     FN_ACKS
        jsr     disp_hex
        jsr     disp_on
:       jmp     :-
.endproc

        .segment "RODATA"
title:  .byte "FUJINET NES", 0
nocart: .byte "NO FUJINET CARTRIDGE", 0
tssid:  .byte "SSID ", 0
tip:    .byte "IP   ", 0
tver:   .byte "FW   ", 0
tfail:  .byte "FAILED: $", 0
tseq:   .byte "ACKSEQ $", 0
