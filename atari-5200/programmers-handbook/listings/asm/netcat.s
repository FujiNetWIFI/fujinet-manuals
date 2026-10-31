; netcat.s -- talk to a TCP server a line at a time.
;
; OPEN the devicespec read/write, then every frame: the stick moves round an
; on-screen keyboard and the bottom button types its key; the keypad's
; digits type themselves, * rubs out, # sends the line with CR LF (a
; WRITE), and START closes the connection. Every eighth frame a STATUS
; asks what is waiting, and a READ fetches it (at most 128 bytes) into
; rows 3-14, which scroll.

        .include "fujinet.inc"
        .include "netdefs.inc"
        .include "devdefs.inc"
        .include "book.inc"

        .import disp_init, disp_at, disp_str, disp_putc, disp_hex, disp_on
        .import fn_chk, fn_beg, fn_go, fn_ack, fn_pb, fn_pw, fn_txb
        .export main

ROW0    = 3                     ; the received text: rows 3-14
NROWS   = 12
NCOLS   = 36
LROW    = 16                    ; the line being typed, after "> "
LMAX    = 34
KROW    = 18                    ; the keyboard: rows 18-20, 13 keys a row
KCOLS   = 13
NMAX    = 128                   ; the most one READ asks for
LO      = $40                   ; the stick's dead zone: $40-$A4
HI      = $A4

        .segment "BSS"
aperr:  .res 1
rrow:   .res 1                  ; where received text goes next
rcol:   .res 1
llen:   .res 1                  ; the typed line
line:   .res LMAX + 2           ; ...with room for CR LF
cx:     .res 1                  ; the keyboard's cursor
cy:     .res 1
latch:  .res 1                  ; the stick moved; wait for the centre
fired:  .res 1                  ; the bottom button was down last frame
navail: .res 2
nleft:  .res 2

        .segment "CODE"

.proc main
        jsr     disp_init
        lda     #$04            ; the pots on; controller 1
        sta     CONSOL
        lda     #0
        sta     rcol
        sta     llen
        sta     cx
        sta     cy
        sta     latch
        sta     fired
        sta     KEY
        lda     #ROW0
        sta     rrow
        PUTS    1, 2, title
        PUTS    LROW, 2, tprompt
        PUTS    22, 1, thelp
        jsr     keyboard
        jsr     cursor          ; the cursor on A
        jsr     disp_on
        jsr     fn_chk
        beq     open
        lda     #FNENOC
        sta     aperr
        jmp     fail

        ; OPEN: mode read/write, no translation; the devicespec follows
open:   FNBEGIN NETDEV, NCOPEN, 2
        lda     #NMHTTPG        ; 12: read and write
        jsr     fn_pb
        lda     #NTRNONE
        jsr     fn_pb
        ldx     #0              ; X: fn_txb takes its byte in Y
@url:   lda     url,x
        beq     @go
        jsr     fn_txb
        inx
        bne     @url
@go:    jsr     go_ack

loop:   WAITFRAME
        jsr     stick
        jsr     button
        jsr     keypad
        lda     RTCLOKL         ; every eighth frame, see what has come
        and     #7
        bne     loop
        jsr     receive
        jmp     loop
.endproc

; ---- the keyboard -------------------------------------------------------

; keyboard -- draw the three rows, a key every other column from column 2.
.proc keyboard
        lda     #0
        sta     ZTMP            ; the row
@row:   lda     ZTMP
        clc
        adc     #KROW
        ldx     #2
        jsr     disp_at
        ldx     ZTMP
        lda     krow,x
        tax                     ; X: the row's first key in keys
        ldy     #KCOLS
@key:   lda     keys,x
        jsr     disp_putc
        lda     #' '
        jsr     disp_putc
        inx
        dey
        bne     @key
        inc     ZTMP
        lda     ZTMP
        cmp     #3
        bne     @row
        rts
.endproc

; cursor -- turn the key under the cursor to reverse video, or back.
.proc cursor
        lda     cy
        clc
        adc     #KROW
        pha
        lda     cx
        asl     a               ; a key every other column
        adc     #2
        tax
        pla
        jsr     disp_at
        ldy     #0
        lda     (DISP_PTR),y
        eor     #$80
        sta     (DISP_PTR),y
        rts
.endproc

; stick -- one step per push: move, then wait for the stick to come back
; to the centre.
.proc stick
        lda     PADDL0
        ldx     PADDL0+1
        ldy     latch
        beq     free
        cmp     #LO             ; latched: free again once both are centred
        bcc     done
        cmp     #HI+1
        bcs     done
        cpx     #LO
        bcc     done
        cpx     #HI+1
        bcs     done
        lda     #0
        sta     latch
done:   rts
free:   cmp     #LO
        bcc     left
        cmp     #HI+1
        bcs     right
        cpx     #LO
        bcc     up
        cpx     #HI+1
        bcs     down
        rts
left:   jsr     cursor
        dec     cx
        bpl     moved
        lda     #KCOLS-1
        sta     cx
        bne     moved
right:  jsr     cursor
        inc     cx
        lda     cx
        cmp     #KCOLS
        bne     moved
        lda     #0
        sta     cx
        beq     moved
up:     jsr     cursor
        dec     cy
        bpl     moved
        lda     #2
        sta     cy
        bne     moved
down:   jsr     cursor
        inc     cy
        lda     cy
        cmp     #3
        bne     moved
        lda     #0
        sta     cy
moved:  lda     #1
        sta     latch
        jmp     cursor
.endproc

; button -- the bottom button types the key under the cursor, once a press.
.proc button
        lda     TRIG0           ; 0 while held
        bne     up
        lda     fired
        bne     done
        inc     fired
        ldx     cy
        lda     krow,x
        clc
        adc     cx
        tax
        lda     keys,x
        cmp     #'_'            ; the key that types a space
        bne     :+
        lda     #' '
:       jmp     type
up:     lda     #0
        sta     fired
done:   rts
.endproc

; keypad -- digits type, * rubs out, # sends, START hangs up.
.proc keypad
        lda     KEY             ; the last key + 1, 0 = none
        beq     done
        ldx     #0
        stx     KEY             ; taken
        sec
        sbc     #1
        cmp     #10
        bcs     :+
        ora     #'0'            ; 0-9
        jmp     type
:       cmp     #$0A            ; *
        beq     rub
        cmp     #$0B            ; #
        bne     :+
        jmp     send
:       cmp     #$0C            ; START
        bne     done
        jmp     hangup
done:   rts
.endproc

; type -- ASCII A onto the end of the line.
.proc type
        ldx     llen
        cpx     #LMAX
        beq     full
        sta     line,x
        inc     llen
        pha
        txa
        clc
        adc     #4              ; after "> "
        tax
        lda     #LROW
        jsr     disp_at
        pla
        jmp     disp_putc
full:   rts
.endproc

.proc rub
        ldx     llen
        beq     done
        dex
        stx     llen
        txa
        clc
        adc     #4
        tax
        lda     #LROW
        jsr     disp_at
        lda     #' '
        jmp     disp_putc
done:   rts
.endproc

; ---- the network --------------------------------------------------------

; send -- WRITE the line and CR LF: one two-byte parameter, the length,
; then the bytes. Then clear the line.
.proc send
        ldx     llen
        lda     #13
        sta     line,x
        lda     #10
        sta     line+1,x
        inx
        inx
        stx     ZTMP
        FNBEGIN NETDEV, NCWRITE, 1
        lda     ZTMP
        ldx     #0
        jsr     fn_pw
        ldx     #0
@b:     lda     line,x
        jsr     fn_txb
        inx
        cpx     ZTMP
        bne     @b
        jsr     go_ack
        lda     #0
        sta     llen
        lda     #LROW
        ldx     #4
        jsr     disp_at
        ldx     #LMAX
@clr:   lda     #' '
        jsr     disp_putc
        dex
        bne     @clr
        rts
.endproc

; receive -- STATUS; if anything is waiting, READ it (at most NMAX) and
; show it.
.proc receive
        FNBEGIN NETDEV, NCSTAT, 2
        lda     #0
        jsr     fn_pb
        lda     #0
        jsr     fn_pb
        jsr     go_ack
        lda     FN_REPLY+NSAVLO
        sta     navail
        lda     FN_REPLY+NSAVHI
        sta     navail+1
        ora     navail
        beq     done
        lda     navail+1        ; at most NMAX
        bne     cap
        lda     navail
        cmp     #NMAX+1
        bcc     read
cap:    lda     #NMAX
        sta     navail
        lda     #0
        sta     navail+1
read:   FNBEGIN NETDEV, NCREAD, 1
        lda     navail
        ldx     navail+1
        jsr     fn_pw
        jsr     go_ack
        lda     FN_RXLEN        ; the reply is at most NMAX: one byte
        sta     nleft
        lda     #<FN_REPLY
        sta     PTR1
        lda     #>FN_REPLY
        sta     PTR1+1
next:   lda     nleft
        beq     done
        dec     nleft
        ldy     #0
        lda     (PTR1),y
        inc     PTR1
        bne     :+
        inc     PTR1+1
:       jsr     show
        jmp     next
done:   rts
.endproc

; show -- one received byte: CR skipped, LF a new row, the rest printed.
.proc show
        cmp     #13
        beq     done
        cmp     #10
        beq     newrow
        pha
        lda     rcol
        clc
        adc     #2
        tax
        lda     rrow
        jsr     disp_at
        pla
        jsr     disp_putc
        inc     rcol
        lda     rcol
        cmp     #NCOLS
        beq     newrow
done:   rts
.endproc

; newrow -- the next row; past the last, scroll rows 4-14 up one.
.proc newrow
        lda     #0
        sta     rcol
        inc     rrow
        lda     rrow
        cmp     #ROW0+NROWS
        bne     done
        dec     rrow
        lda     #<(SCREEN+(ROW0+1)*40)
        sta     PTR1
        lda     #>(SCREEN+(ROW0+1)*40)
        sta     PTR1+1
        lda     #<(SCREEN+ROW0*40)
        sta     PTR2
        lda     #>(SCREEN+ROW0*40)
        sta     PTR2+1
        ldx     #NROWS-1
@row:   ldy     #39
@b:     lda     (PTR1),y
        sta     (PTR2),y
        dey
        bpl     @b
        lda     PTR1
        sta     PTR2
        lda     PTR1+1
        sta     PTR2+1
        lda     PTR1
        clc
        adc     #40
        sta     PTR1
        bcc     :+
        inc     PTR1+1
:       dex
        bne     @row
        ldy     #39             ; PTR2 is the last row now: blank it
        lda     #0              ; ANTIC's code for a space
@clr:   sta     (PTR2),y
        dey
        bpl     @clr
done:   rts
.endproc

; hangup -- CLOSE, say so, and stop.
.proc hangup
        FNBEGIN NETDEV, NCCLOSE, 0
        jsr     go_ack
        PUTS    LROW, 2, tclosed
@h:     jmp     @h
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
        PUTS    LROW, 2, tfail
        lda     aperr
        jsr     disp_hex
@h:     jmp     @h
.endproc

        .segment "RODATA"
url:    .byte "N:TCP://127.0.0.1:8769/", 0
title:  .byte "NETCAT  127.0.0.1:8769", 0
tprompt: .byte "> ", 0
thelp:  .byte "FIRE TYPES  # SENDS  * RUBS  START ENDS", 0
tclosed: .byte "CLOSED                              ", 0
tfail:  .byte "FAILED: E", 0
keys:   .byte "ABCDEFGHIJKLM"
        .byte "NOPQRSTUVWXYZ"
        .byte "_.,:/?!-'@()="       ; _ types a space
krow:   .byte 0, KCOLS, 2*KCOLS

        .include "header.inc"
