; fujidir.s -- list a directory on a FujiNet host.
;
; MOUNT_HOST, then OPEN_DIRECTORY with the path, then READ_DIR_ENTRY until
; the $7F,$7F marker says there are no more (or the screen is full), each
; name shown straight from the reply window, then CLOSE_DIRECTORY.

        .include "fujinet.inc"
        .include "devdefs.inc"

        .import disp_at, disp_str, disp_hex, disp_on, disp_rpl
        .import fn_chk, fn_beg, fn_go, fn_ack, fn_pb, fn_path
        .export main, nmi

HOSTSL  = 0                     ; host slot 0: the SD card
NAMELN  = 36                    ; READ_DIR_ENTRY's maxlen (never 31: at 31 the
                                ;   firmware puts icon bytes in front)
ROW0    = 4
NROWS   = 18

        .segment "ZEROPAGE"
aperr:  .res 1
row:    .res 1

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

.proc main
        PUTS    2, 2, title
        jsr     disp_on
        jsr     fn_chk
        beq     mount
        lda     #FNENOC
        sta     aperr
        jmp     fail

        ; MOUNT_HOST: one parameter, the host slot
mount:  lda     #FNDEVF
        sta     FN_DEV
        lda     #FNCMHST
        sta     FN_CMD
        lda     #1
        sta     FN_NPR
        jsr     fn_beg
        lda     #HOSTSL
        jsr     fn_pb
        jsr     go_ack

        ; OPEN_DIRECTORY: the host slot, then exactly 256 bytes of path
        lda     #FNDEVF
        sta     FN_DEV
        lda     #FNCODIR
        sta     FN_CMD
        lda     #1
        sta     FN_NPR
        jsr     fn_beg
        lda     #HOSTSL
        jsr     fn_pb
        lda     #<path
        sta     FN_PTR
        lda     #>path
        sta     FN_PTR+1
        jsr     fn_path
        jsr     go_ack

        ; READ_DIR_ENTRY: two one-byte parameters, the longest name wanted
        ; and the flags; one name a call
        lda     #ROW0
        sta     row
entry:  lda     #FNDEVF
        sta     FN_DEV
        lda     #FNCRDIR
        sta     FN_CMD
        lda     #2
        sta     FN_NPR
        jsr     fn_beg
        lda     #NAMELN
        jsr     fn_pb
        lda     #0
        jsr     fn_pb
        jsr     go_ack
        lda     FN_REPLY        ; $7F,$7F: the end of the directory
        cmp     #$7F
        bne     @show
        lda     FN_REPLY+1
        cmp     #$7F
        beq     close
@show:  lda     row
        ldx     #2
        jsr     disp_at
        ldx     #0
        ldy     #NAMELN
        jsr     disp_rpl
        inc     row
        lda     row
        cmp     #ROW0+NROWS
        bne     entry

        ; CLOSE_DIRECTORY: no parameters
close:  lda     #FNDEVF
        sta     FN_DEV
        lda     #FNCCDIR
        sta     FN_CMD
        lda     #0
        sta     FN_NPR
        jsr     fn_beg
        jsr     go_ack
loop:   jmp     loop
.endproc

; go_ack -- fn_go, then fn_ack; on any failure the code goes in aperr and
; the failure screen follows, so callers need no branch.
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
path:   .byte "/a7800book/", 0
title:  .byte "DIRECTORY OF SD:/A7800BOOK/", 0
tfail:  .byte "FAILED: E", 0
