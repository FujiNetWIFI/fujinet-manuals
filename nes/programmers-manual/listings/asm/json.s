; json.s -- fetch a JSON document and pick fields out of it.
;
; OPEN as for any file; SET_PARSER to JSON and PARSE; then, per field, QUERY
; a path and READ the value the query leaves waiting.

        .include "book.inc"
        .export main

        .segment "ZEROPAGE"
row:    .res 1
idx:    .res 1

        .segment "CODE"
.proc main
        PUTS    2, 2, title

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

        CALL    FNDEVN, NCPARSER, 2     ; channel mode: JSON
        lda     #1
        jsr     fn_pb
        lda     #1
        jsr     fn_pb
        jsr     fn_go
        jne     fail
        CALL    FNDEVN, NCPARSE, 0      ; the FujiNet parses the whole body
        jsr     fn_go
        jne     fail
        jsr     fn_ack
        jne     fail

        lda     #4
        sta     row
        lda     #0
        sta     idx
field:  ldx     idx                     ; fn_ptr = paths[idx]
        lda     paths,x
        sta     fn_ptr
        lda     paths+1,x
        sta     fn_ptr+1
        lda     row
        ldx     #2
        jsr     disp_at
        jsr     disp_str                ; the path itself, as a label

        CALL    FNDEVN, NCQUERY, 0      ; QUERY: the path is the payload
        jsr     fn_path                 ; NUL-padded to 256, as the library does
        jsr     fn_go
        jne     fail
        CALL    FNDEVN, NCSTAT, 0       ; the value's length
        jsr     fn_go
        jne     fail
        lda     FN_RPLY
        beq     skip                    ; no such field
        CALL    FNDEVN, NCREAD, 1
        lda     FN_RPLY                 ; still the STATUS reply: fn_beg wrote
        ldx     #0                      ; only registers, not the window
        jsr     fn_pw
        jsr     fn_go
        jne     fail
        lda     row
        ldx     #17
        jsr     disp_at
        ldx     #0
        ldy     FN_RXLO
show1:  lda     FN_RPLY,x
        cmp     #$20                    ; stop at the trailing newline
        bcc     skip
        sta     PPU_DATA
        inx
        dey
        bne     show1
skip:   inc     row
        inc     idx
        inc     idx
        lda     idx
        cmp     #2*5
        jne     field

        CALL    FNDEVN, NCCLOSE, 0
        jsr     fn_go
        jmp     show

fail:   pha
        PUTS    20, 2, tfail
        pla
        jsr     disp_hex
show:   jsr     disp_on
:       jmp     :-
.endproc

        .segment "RODATA"
title:  .byte "JSON", 0
url:    .byte "N:HTTP://127.0.0.1:8765/hello.json", 0
p0:     .byte "/name", 0
p1:     .byte "/console", 0
p2:     .byte "/year", 0
p3:     .byte "/mailbox/base", 0
p4:     .byte "/mailbox/reply", 0
paths:  .addr p0, p1, p2, p3, p4
tfail:  .byte "FAILED: $", 0
