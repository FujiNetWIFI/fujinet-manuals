; dir.s -- list a directory on a TNFS host.
;
; READ_HOST_SLOTS for the host's name, then MOUNT_HOST, OPEN_DIRECTORY and one
; READ_DIR_ENTRY per line until the $7F end marker.

        .include "book.inc"
        .export main

HOST    = 7                     ; host slot 8: ec.tnfs.io
ROWS    = 20

        .segment "ZEROPAGE"
row:    .res 1

        .segment "CODE"
.proc main
        CALL    FNDEVF, FNCRHST, 0      ; 8 x 32-byte host names
        jsr     fn_go
        jne     fail
        PUTS    2, 2, title
        ldx     #HOST*32
        ldy     #32
        jsr     disp_rpl                ; this slot's name, from the window

        CALL    FNDEVF, FNCMHST, 1      ; MOUNT_HOST(host)
        lda     #HOST
        jsr     fn_pb
        jsr     fn_go
        jne     fail
        jsr     fn_ack
        jne     fail

        CALL    FNDEVF, FNCODIR, 1      ; OPEN_DIRECTORY(host), path "/"
        lda     #HOST
        jsr     fn_pb
        lda     #<root
        sta     fn_ptr
        lda     #>root
        sta     fn_ptr+1
        jsr     fn_path                 ; exactly 256 bytes, NUL-padded
        jsr     fn_go
        jne     fail
        jsr     fn_ack
        jne     fail

        lda     #4
        sta     row
entry:  CALL    FNDEVF, FNCRDIR, 2      ; READ_DIR_ENTRY(maxlen, flags)
        lda     #28
        jsr     fn_pb
        lda     #0
        jsr     fn_pb
        jsr     fn_go
        jne     fail
        jsr     fn_ack
        jne     close
        lda     FN_RPLY
        cmp     #$7F                    ; end of directory
        beq     close
        lda     row
        ldx     #3
        jsr     disp_at
        ldx     #0
        ldy     #28
        jsr     disp_rpl
        inc     row
        lda     row
        cmp     #4+ROWS
        bne     entry

close:  CALL    FNDEVF, FNCCDIR, 0
        jsr     fn_go
        jmp     show

fail:   pha
        PUTS    26, 2, tfail
        pla
        jsr     disp_hex
show:   jsr     disp_on
:       jmp     :-
.endproc

        .segment "RODATA"
title:  .byte "DIR OF ", 0
root:   .byte "/", 0
tfail:  .byte "FAILED: $", 0
