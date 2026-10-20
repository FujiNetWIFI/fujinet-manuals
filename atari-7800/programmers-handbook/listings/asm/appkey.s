; appkey.s -- read the shared FujiNet username, then write a key of our own
; and read it back.
;
; An appkey is a small file on the adapter's SD card, named by a creator id,
; an application id and a key number. Creator 1, app 1, key 0 is the slot
; every FujiNet game reads the player's name from. This program shows it,
; then writes "HELLO 7800" into creator $7800, app $FF, key 0 and reads that
; back. ($7800 is the cartridge's own creator; its app 1 is the High Score
; Cart. App $FF is this handbook's scratch key.)
;
; OPEN_APPKEY's payload is ONE six-byte packed struct -- creator (u16, little-
; endian), app, key, mode, and a reserved byte that is not optional -- not
; four parameters. READ_APPKEY's reply is a two-byte length and then the
; value. WRITE_APPKEY takes one parameter, the length, then the bytes.

        .include "fujinet.inc"
        .include "devdefs.inc"

        .import disp_at, disp_str, disp_hex, disp_on, disp_rpl
        .import fn_chk, fn_beg, fn_go, fn_ack, fn_pb, fn_txb
        .export main, nmi

OURCRE  = $7800
OURAPP  = $FF
OURKEY  = 0

        .segment "ZEROPAGE"
aperr:  .res 1
akcre:  .res 2                  ; the key being opened: creator...
akapp:  .res 1                  ; ...app...
akkey:  .res 1                  ; ...key number...
akmode: .res 1                  ; ...and mode (AKMRD / AKMWR)

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

.macro  KEY     cre, app, key, mode
        lda     #<cre
        sta     akcre
        lda     #>cre
        sta     akcre+1
        lda     #app
        sta     akapp
        lda     #key
        sta     akkey
        lda     #mode
        sta     akmode
.endmacro

.proc main
        PUTS    2, 2, title
        jsr     disp_on
        jsr     fn_chk
        beq     @go
        lda     #FNENOC
        sta     aperr
        jmp     fail

@go:    PUTS    5, 2, tname     ; the shared username
        KEY     AKCREAT, AKAPP, AKKEY, AKMRD
        jsr     akopen
        jsr     akread
        lda     #6
        jsr     akshow

        PUTS    9, 2, tours     ; ours: write it, then read it back
        KEY     OURCRE, OURAPP, OURKEY, AKMWR
        jsr     akopen
        jsr     akwrite
        lda     #AKMRD
        sta     akmode
        jsr     akopen
        jsr     akread
        lda     #10
        jsr     akshow
loop:   jmp     loop
.endproc

; akopen -- OPEN_APPKEY for the key in akcre/akapp/akkey, mode akmode: no
; parameters, the six-byte struct as the payload.
.proc akopen
        lda     #FNDEVF
        sta     FN_DEV
        lda     #FNCAKOP
        sta     FN_CMD
        lda     #0
        sta     FN_NPR
        jsr     fn_beg
        lda     akcre
        jsr     fn_txb
        lda     akcre+1
        jsr     fn_txb
        lda     akapp
        jsr     fn_txb
        lda     akkey
        jsr     fn_txb
        lda     akmode
        jsr     fn_txb
        lda     #0              ; reserved, and not optional
        jsr     fn_txb
        jmp     go_ack
.endproc

; akread -- READ_APPKEY: the value is left in the reply window, two bytes of
; length, then the bytes.
.proc akread
        lda     #FNDEVF
        sta     FN_DEV
        lda     #FNCAKRD
        sta     FN_CMD
        lda     #0
        sta     FN_NPR
        jsr     fn_beg
        jmp     go_ack
.endproc

; akwrite -- WRITE_APPKEY: one parameter, the length, then the value.
.proc akwrite
        lda     #FNDEVF
        sta     FN_DEV
        lda     #FNCAKWR
        sta     FN_CMD
        lda     #1
        sta     FN_NPR
        jsr     fn_beg
        lda     #valend-val
        jsr     fn_pb
        ldy     #0
@w:     lda     val,y
        jsr     fn_txb
        iny
        cpy     #valend-val
        bne     @w
        jmp     go_ack
.endproc

; akshow -- the value just read, on row A; "(EMPTY)" if there is none.
.proc akshow
        ldx     #4
        jsr     disp_at
        lda     FN_REPLY
        ora     FN_REPLY+1
        bne     @val
        lda     #<tempty
        sta     FN_PTR
        lda     #>tempty
        sta     FN_PTR+1
        jmp     disp_str
@val:   ldx     #2              ; the value starts after the length word
        ldy     FN_REPLY        ; at most its length (all are under 64)
        jmp     disp_rpl
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
title:  .byte "APPKEYS", 0
tname:  .byte "USERNAME (CREATOR 1, APP 1, KEY 0)", 0
tours:  .byte "OURS (CREATOR $7800, APP $FF, KEY 0)", 0
tempty: .byte "(EMPTY)", 0
tfail:  .byte "FAILED: E", 0
val:    .byte "HELLO 7800"
valend:
