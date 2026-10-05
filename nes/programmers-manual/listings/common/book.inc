; book.inc -- the macros every assembly program in this book uses.

        .macpack longbranch           ; jne, jeq ... reach past 127 bytes
        .include "fujinet.inc"
        .include "fujidefs.inc"

        .import disp_at, disp_str, disp_hex, disp_rpl, disp_on, disp_off
        .import disp_putc, disp_dec
        .import wait_vbl, scroll0, fn_str, fn_launch, fn_done, disp_d3
        .importzp frames
        .import fn_chk, fn_beg, fn_go, fn_ack, fn_pb, fn_pw, fn_path
        .import fn_txb, fn_blk, fn_boot
        .importzp fn_ptr, fn_dev, fn_cmd, fn_npr, fn_tmo

; PUTS row, col, string -- a string from ROM, at a screen position.
.macro  PUTS    row, col, str
        lda     #row
        ldx     #col
        jsr     disp_at
        lda     #<str
        sta     fn_ptr
        lda     #>str
        sta     fn_ptr+1
        jsr     disp_str
.endmacro

; AT row, col -- move the PPU cursor.
.macro  AT      row, col
        lda     #row
        ldx     #col
        jsr     disp_at
.endmacro

; CALL dev, cmd, nparam -- begin a transaction.
.macro  CALL    dev, cmd, npar
        lda     #dev
        sta     fn_dev
        lda     #cmd
        sta     fn_cmd
        lda     #npar
        sta     fn_npr
        jsr     fn_beg
.endmacro
