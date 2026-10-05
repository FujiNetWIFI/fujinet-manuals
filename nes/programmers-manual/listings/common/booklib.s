; booklib.s -- the few routines this book adds to the bring-up's fujilib.s.
;
;   nmi        a vblank handler that only counts frames
;   wait_vbl   wait for the next vblank (rendering may be on)
;   scroll0    after drawing in vblank: scroll home, NMI on
;   fn_str     append the NUL-terminated string at fn_ptr, unpadded
;   fn_launch  commit the transaction and return at once
;   fn_done    has the launched transaction been answered? (C set if so)
;   disp_d3    A as three decimal digits, right-aligned with spaces

        .include "fujinet.inc"

        .export nmi, wait_vbl, scroll0, fn_str, fn_launch, fn_done, disp_d3
        .exportzp frames

        .segment "ZEROPAGE"
frames: .res 1                  ; bumped once per vblank by the NMI
want:   .res 1                  ; the sequence fn_launch is waiting for

        .segment "CODE"

; The whole vblank handler. It never writes to $5500-$57FF, so it can land in
; the middle of a transaction without disturbing it.
.proc nmi
        inc     frames          ; RMW on console RAM: harmless
        rti
.endproc

.proc wait_vbl
        lda     frames
:       cmp     frames
        beq     :-
        rts
.endproc

.proc scroll0
        lda     #0
        sta     PPU_SCROLL
        sta     PPU_SCROLL
        lda     #%10000000      ; NMI on, nametable 0
        sta     PPU_CTRL
        rts
.endproc

; fn_str -- append the string at FN_PTR without its NUL. A URL needs no
; padding: the payload is as long as the bytes you store.
.proc fn_str
        ldy     #0
loop:   lda     (FN_PTR),y
        beq     done
        sta     FN_TX
        iny
        bne     loop
done:   rts
.endproc

; fn_launch -- like fn_go, but does not wait. The sequence still comes from
; the cart's ACKSEQ + 1, skipping 0.
.proc fn_launch
        lda     FN_ACKS
        clc
        adc     #1
        bne     :+
        lda     #1
:       sta     want
        sta     FN_RSEL+FR_SEQ  ; the one store that sends it
        rts
.endproc

; fn_done -- C set once ACKSEQ echoes the launched sequence.
.proc fn_done
        lda     FN_ACKS
        cmp     want
        beq     yes
        clc
        rts
yes:    sec
        rts
.endproc

; disp_d3 -- A (0-255) as three characters, leading zeros as spaces.
.proc disp_d3
        ldx     #'0'-1
h:      inx
        sec
        sbc     #100
        bcs     h
        adc     #100
        cpx     #'0'
        bne     :+
        ldx     #' '
:       stx     PPU_DATA
        ldy     #'0'-1
t:      iny
        sec
        sbc     #10
        bcs     t
        adc     #10
        cpy     #'0'
        bne     :+
        cpx     #' '            ; a zero tens digit is blank only after a
        bne     :+              ; blank hundreds digit
        ldy     #' '
:       sty     PPU_DATA
        ora     #'0'
        sta     PPU_DATA
        rts
.endproc
