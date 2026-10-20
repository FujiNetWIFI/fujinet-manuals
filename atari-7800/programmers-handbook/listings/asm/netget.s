; netget.s -- fetch a URL through the N: device and show the text.
;
; OPEN the devicespec as an HTTP GET, STATUS until the byte count settles,
; READ what is waiting (at most 512 bytes) into the reply window, show it a
; line at a time -- LF ends a row, CR is skipped, a row is at most 36
; characters -- then CLOSE.

        .include "fujinet.inc"
        .include "netdefs.inc"

        .import disp_at, disp_str, disp_hex, disp_on, disp_putc, disp_vbl
        .import fn_chk, fn_beg, fn_go, fn_ack, fn_pb, fn_pw, fn_txb
        .export main, nmi

NMAX    = 512                   ; the most we read
NROW0   = 4                     ; the first text row of the reply
NROWS   = 18                    ; rows 4-21
NCOLS   = 36
NTRIES  = 30                    ; STATUS readings before giving up

        .segment "ZEROPAGE"
aperr:  .res 1                  ; what went wrong, if anything
navail: .res 2                  ; bytes waiting, from STATUS
nprev:  .res 2                  ; the previous STATUS reading
ntry:   .res 1
nsrc:   .res 2                  ; the reply cursor
nleft:  .res 2                  ; reply bytes still to show
nrow:   .res 1
ncol:   .res 1

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
        lda     #0
        sta     aperr
        jsr     fn_chk
        beq     open
        lda     #FNENOC
        sta     aperr
        jmp     fail

        ; OPEN: two one-byte parameters, the mode and the translation, then
        ; the devicespec as the payload
open:   lda     #NETDEV
        sta     FN_DEV
        lda     #NCOPEN
        sta     FN_CMD
        lda     #2
        sta     FN_NPR
        jsr     fn_beg
        lda     #NMHTTPG
        jsr     fn_pb
        lda     #NTRNONE
        jsr     fn_pb
        ldy     #0
@url:   lda     url,y
        beq     @urle
        jsr     fn_txb
        iny
        bne     @url
@urle:  jsr     go_ack

        ; STATUS until two readings agree and are not zero: the adapter
        ; answers as soon as SOME of the response has arrived
        lda     #$FF
        sta     nprev
        sta     nprev+1
        lda     #0
        sta     ntry
stat:   lda     #NETDEV
        sta     FN_DEV
        lda     #NCSTAT
        sta     FN_CMD
        lda     #2
        sta     FN_NPR
        jsr     fn_beg
        lda     #0
        jsr     fn_pb
        lda     #0
        jsr     fn_pb
        jsr     go_ack
        lda     FN_REPLY+NSAVLO
        sta     navail
        lda     FN_REPLY+NSAVHI
        sta     navail+1
        cmp     nprev+1
        bne     again
        lda     navail
        cmp     nprev
        bne     again
        ora     navail+1
        bne     read
again:  lda     navail
        sta     nprev
        lda     navail+1
        sta     nprev+1
        inc     ntry
        lda     ntry
        cmp     #NTRIES
        bcc     @wait
        lda     #FNEWAIT
        sta     aperr
        jmp     fail
@wait:  ldx     #3              ; three frames between readings
@w:     jsr     disp_vbl
        dex
        bne     @w
        jmp     stat

        ; READ: ONE two-byte parameter, the count, capped at NMAX
read:   lda     navail+1
        cmp     #>NMAX
        bcc     @len
        lda     #<NMAX
        sta     navail
        lda     #>NMAX
        sta     navail+1
@len:   lda     #NETDEV
        sta     FN_DEV
        lda     #NCREAD
        sta     FN_CMD
        lda     #1
        sta     FN_NPR
        jsr     fn_beg
        lda     navail
        ldx     navail+1
        jsr     fn_pw
        jsr     go_ack

        ; show it, a row per line
        lda     #<FN_REPLY
        sta     nsrc
        lda     #>FN_REPLY
        sta     nsrc+1
        lda     FN_RXLEN
        sta     nleft
        lda     FN_RXLEN+1
        sta     nleft+1
        lda     #NROW0
        sta     nrow
        jsr     newrow
next:   lda     nleft
        ora     nleft+1
        beq     close
        ldy     #0
        lda     (nsrc),y
        inc     nsrc
        bne     @s
        inc     nsrc+1
@s:     ldx     nleft
        bne     @n
        dec     nleft+1
@n:     dec     nleft
        cmp     #13             ; CR: skip
        beq     next
        cmp     #10             ; LF: next row
        bne     @c
        inc     nrow
        lda     nrow
        cmp     #NROW0+NROWS
        beq     close
        jsr     newrow
        jmp     next
@c:     ldx     ncol
        cpx     #NCOLS
        beq     next            ; past the edge: drop it
        inc     ncol
        jsr     disp_putc
        jmp     next

        ; CLOSE: no parameters
close:  lda     #NETDEV
        sta     FN_DEV
        lda     #NCCLOSE
        sta     FN_CMD
        lda     #0
        sta     FN_NPR
        jsr     fn_beg
        jsr     go_ack
        PUTS    22, 2, tdone
loop:   jmp     loop
.endproc

; newrow -- the cursor to column 2 of row nrow.
.proc newrow
        lda     #0
        sta     ncol
        lda     nrow
        ldx     #2
        jmp     disp_at
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
@bad:   pla                     ; drop our caller's return
        pla
        jmp     fail
.endproc

; fail -- FAILED and the code. Does not return.
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
url:    .byte "N:http://127.0.0.1:8765/hello.txt", 0
title:  .byte "NETGET", 0
tdone:  .byte "CLOSED", 0
tfail:  .byte "FAILED: E", 0
