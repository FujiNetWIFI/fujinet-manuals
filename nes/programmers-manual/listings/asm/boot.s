; boot.s -- fetch a cartridge image from the SD card and run it, with a
; progress count drawn while MOUNT_IMAGE is still outstanding.
;
; MOUNT_HOST -> SET_DEVICE_FULLPATH -> MOUNT_IMAGE. The last one does not
; answer until the whole image has crossed into the cartridge's store, so it
; is launched with fn_launch and watched, one vblank at a time, through
; BOOT_PCT. Then BOOTLOCK and a jump into the loader ROM at $5800.

        .include "book.inc"
        .export main

HOST    = 0                     ; host slot 1: the SD card
SLOT    = 0                     ; device slot 1
MREAD   = 1                     ; disk access mode: read
LIMIT   = 65                    ; seconds: outlasts the cart's own 60

        .segment "ZEROPAGE"
secs:   .res 1
tick:   .res 1

        .segment "CODE"
.proc main
        PUTS    2, 2, title
        lda     #<path
        sta     fn_ptr
        lda     #>path
        sta     fn_ptr+1
        jsr     disp_str
        PUTS    4, 2, tload
        jsr     disp_on

        CALL    FNDEVF, FNCMHST, 1      ; MOUNT_HOST(host)
        lda     #HOST
        jsr     fn_pb
        jsr     fn_go
        jne     fail
        jsr     fn_ack
        jne     fail

        CALL    FNDEVF, FNCSDFP, 3      ; SET_DEVICE_FULLPATH(slot, host, mode)
        lda     #SLOT
        jsr     fn_pb
        lda     #HOST
        jsr     fn_pb
        lda     #MREAD
        jsr     fn_pb
        lda     #<path
        sta     fn_ptr
        lda     #>path
        sta     fn_ptr+1
        jsr     fn_path                 ; exactly 256 bytes
        jsr     fn_go
        jne     fail
        jsr     fn_ack
        jne     fail

        CALL    FNDEVF, FNCMIMG, 2      ; MOUNT_IMAGE(slot, mode)
        lda     #SLOT
        jsr     fn_pb
        lda     #MREAD
        jsr     fn_pb
        jsr     fn_launch               ; sent; do not wait here

        lda     #LIMIT
        sta     secs
        lda     #60
        sta     tick
watch:  jsr     wait_vbl                ; vblank: safe to touch the PPU
        lda     #4
        ldx     #10
        jsr     disp_at
        lda     FN_BPC                  ; 0-100, painted by the cart
        jsr     disp_d3
        jsr     scroll0
        jsr     fn_done                 ; MOUNT_IMAGE answered?
        bcs     answered
        dec     tick
        bne     watch
        lda     #60
        sta     tick
        dec     secs
        bne     watch
        lda     #FNEWAIT
        jmp     fail

answered:
        lda     FN_ERR
        jne     fail
        jsr     fn_ack
        jne     fail
        lda     FN_BST
        cmp     #FN_BRDY
        jne     bootfail
        jsr     fn_blk                  ; BOOTLOCK = $B5
        jmp     fn_boot                 ; SEI, PPU off, JMP $5800

bootfail:
        lda     FN_BER                  ; why: 1 TOOBIG 2 TRUNCATED 3 NOMAP 4 BUSY
fail:   pha
        jsr     wait_vbl
        PUTS    6, 2, tfail
        pla
        jsr     disp_hex
        jsr     scroll0
:       jmp     :-
.endproc

        .segment "RODATA"
title:  .byte "BOOTING ", 0
tload:  .byte "LOADING    %", 0
tfail:  .byte "FAILED: $", 0
path:   .byte "/nesbook/hello.bin", 0
