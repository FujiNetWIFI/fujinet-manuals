; netget.s -- read a text file over HTTP and print it.
;
; OPEN, then STATUS / READ until the server has nothing more, then CLOSE.
; Each READ asks for at most 255 bytes so one index register walks the reply.

        .include "book.inc"
        .export main

        .segment "ZEROPAGE"
row:    .res 1
col:    .res 1
count:  .res 1
xsave:  .res 1

        .segment "CODE"
.proc main
        PUTS    2, 2, title
        lda     #4
        sta     row
        jsr     newline

        ; OPEN N1: mode 4 (read), translation 0, the URL as the payload
        CALL    FNDEVN, NCOPEN, 2
        lda     #NMREAD
        jsr     fn_pb
        lda     #0
        jsr     fn_pb
        lda     #<url
        sta     fn_ptr
        lda     #>url
        sta     fn_ptr+1
        jsr     fn_str
        jsr     fn_go
        jne     fail
        jsr     fn_ack
        jne     fail

next:   CALL    FNDEVN, NCSTAT, 0       ; how much is waiting?
        jsr     fn_go
        jne     fail
        lda     FN_RPLY+1               ; avail, high byte
        bne     big
        lda     FN_RPLY                 ; avail, low byte
        bne     some
        lda     FN_RPLY+3               ; nothing waiting: an error (136 = EOF)
        cmp     #2                      ; means the file is over
        bcs     eof
        jmp     next
big:    lda     #255
some:   sta     count

        CALL    FNDEVN, NCREAD, 1       ; READ count bytes
        lda     count
        ldx     #0
        jsr     fn_pw                   ; one 2-byte parameter
        jsr     fn_go
        jne     fail

        ldx     #0                      ; print them out of the window
print:  lda     FN_RPLY,x
        cmp     #$0A
        bne     :+
        stx     xsave                   ; disp_at uses X
        inc     row
        jsr     newline
        ldx     xsave
        jmp     adv
:       sta     PPU_DATA
adv:    inx
        cpx     FN_RXLO
        bne     print
        jmp     next

eof:    CALL    FNDEVN, NCCLOSE, 0
        jsr     fn_go
        inc     row
        jsr     newline
        lda     #<tend
        sta     fn_ptr
        lda     #>tend
        sta     fn_ptr+1
        jsr     disp_str
        jmp     show

fail:   pha
        PUTS    20, 2, tfail
        pla
        jsr     disp_hex
show:   jsr     disp_on
:       jmp     :-
.endproc

; newline -- PPU cursor to column 2 of `row`.
.proc newline
        lda     row
        ldx     #2
        jmp     disp_at
.endproc

        .segment "RODATA"
title:  .byte "NETGET", 0
url:    .byte "N:HTTP://127.0.0.1:8765/hello.txt", 0
tend:   .byte "-- END --", 0
tfail:  .byte "FAILED: $", 0
