; appkey.s -- count how many times this program has been run.
;
; An app key is opened with a 6-byte record -- creator (2 bytes, LE), app,
; key, mode (0 read, 1 write), reserved -- and then read or written. On the
; RS-232 FujiBus the READ reply starts with the key's length, 2 bytes LE.

        .include "book.inc"
        .export main

CREATOR = $5E5E                 ; a scratch creator id
APP     = $01
KEY     = $00

        .segment "ZEROPAGE"
runs:   .res 2

        .segment "CODE"
.proc main
        PUTS    2, 2, title
        lda     #0
        sta     runs
        sta     runs+1

        lda     #0                      ; mode 0: read
        jsr     open_key
        jne     fail
        CALL    FNDEVF, FNCRKEY, 0
        jsr     fn_go
        jne     fail
        jsr     fn_ack
        bne     count                   ; never written: start from zero
        lda     FN_RPLY+1               ; length, high byte
        bne     have
        lda     FN_RPLY                 ; length, low byte
        cmp     #2
        bcc     count
have:   lda     FN_RPLY+2               ; the two bytes after the length
        sta     runs
        lda     FN_RPLY+3
        sta     runs+1

count:  inc     runs                    ; RMW on console RAM: fine
        bne     :+
        inc     runs+1
:
        lda     #1                      ; mode 1: write
        jsr     open_key
        jne     fail
        CALL    FNDEVF, FNCWKEY, 0      ; the payload is the key's new value
        lda     runs
        jsr     fn_txb
        lda     runs+1
        jsr     fn_txb
        jsr     fn_go
        jne     fail
        jsr     fn_ack
        jne     fail

        PUTS    5, 2, tran
        PUTS    6, 2, tdollar
        lda     runs+1
        jsr     disp_hex
        lda     runs
        jsr     disp_hex
        PUTS    6, 8, ttimes
        PUTS    9, 2, treset
        jmp     show

fail:   pha
        PUTS    12, 2, tfail
        pla
        jsr     disp_hex
show:   jsr     disp_on
:       jmp     :-
.endproc

; open_key -- OPEN_APPKEY with mode A. Returns as fn_go / fn_ack do.
.proc open_key
        pha
        CALL    FNDEVF, FNCOKEY, 0
        lda     #<CREATOR
        jsr     fn_txb
        lda     #>CREATOR
        jsr     fn_txb
        lda     #APP
        jsr     fn_txb
        lda     #KEY
        jsr     fn_txb
        pla
        jsr     fn_txb                  ; mode
        lda     #0
        jsr     fn_txb                  ; reserved
        jsr     fn_go
        bne     done
        jsr     fn_ack
done:   rts
.endproc

        .segment "RODATA"
title:  .byte "APPKEY", 0
tran:   .byte "THIS PROGRAM HAS RUN", 0
tdollar: .byte "$", 0
ttimes: .byte "TIMES.", 0
treset: .byte "PRESS RESET TO COUNT AGAIN.", 0
tfail:  .byte "FAILED: $", 0
