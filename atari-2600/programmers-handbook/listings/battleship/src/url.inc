; url.inc -- the devicespec, streamed straight into the TX page a character at
; a time.
;
; Nothing is assembled in RAM. The cartridge counts the payload itself, so
; nothing here tracks a length -- which is the only reason a console with 128
; bytes can build
;
;   N:https://battleship.carr-designs.com/attack/47?table=ai1&player=VCS&bin=1&v=2
;
; at all. The table id and the player name are not in console RAM either: they
; live in the cartridge's path buffers and FP_TXRAW streams them from there
; into the request without their ever crossing the bus. The five placements
; and the shot ARE in RAM -- seven bytes -- and go out as decimal through UDEC,
; which is what saves a twenty-character move buffer this console has not got.
;
; A fixed-width wire field is pushed up to its NUL and NEVER through it. The
; server sends name[9] space-padded, and padding in the middle of a URL
; corrupts the request -- the Arcadia port calls this out by name.
;
; All six requests are built here, in the one bank that issues any of them.

; UTXS -- append the NUL-terminated string at FNPTRL/FNPTRH to the TX stream.
UTXS:   ldy     #0
UTXS1:  lda     (FNPTRL),y
        beq     UTXS2
        sta     FNTX
        iny
        bne     UTXS1
UTXS2:  rts

; UPUT -- point at the string in X (lo) / Y (hi) and append it.
UPUT:   jsr     FNSETP
        jmp     UTXS

; UDEC -- append A (0-255) as decimal with no leading zeros. Clobbers X.
UDEC:   ldx     #0              ; hundreds
UDC1:   cmp     #100
        bcc     UDC2
        sbc     #100
        inx
        bne     UDC1
UDC2:   pha
        txa
        beq     UDC3            ; no hundreds: no digit, and tens may be bare
        clc
        adc     #'0'
        sta     FNTX
        pla
        ldx     #0
UDC4:   cmp     #10             ; tens, always printed after a hundreds digit
        bcc     UDC5
        sbc     #10
        inx
        bne     UDC4
UDC5:   pha
        txa
        clc
        adc     #'0'
        sta     FNTX
        pla
        jmp     UDC8
UDC3:   pla
        ldx     #0
UDC6:   cmp     #10
        bcc     UDC7
        sbc     #10
        inx
        bne     UDC6
UDC7:   pha
        txa
        beq     UDC9            ; a zero tens digit prints only after hundreds
        clc
        adc     #'0'
        sta     FNTX
UDC9:   pla
UDC8:   clc                     ; the units digit always prints
        adc     #'0'
        sta     FNTX
        rts

; ---------------------------------------------------------------------------
; BLDURL -- stream the devicespec for the request in BSREQ.
BLDURL: lda     #'N'
        sta     FNTX
        lda     #':'
        sta     FNTX
        ldx     #(UENDPT)&$FF
        ldy     #(UENDPT)>>8
        jsr     UPUT

        lda     BSREQ
        cmp     #RQTABLE
        bne     BU1
; /tables carries its own query and takes neither a table nor a player.
        ldx     #(UTABLS)&$FF
        ldy     #(UTABLS)>>8
        jmp     UPUT
BU1:    cmp     #RQLEAVE
        bne     BU2
        ldx     #(ULEAVE)&$FF
        ldy     #(ULEAVE)>>8
        jsr     UPUT
        jmp     BUQ
BU2:    cmp     #RQREADY
        bne     BU3
        ldx     #(UREADY)&$FF   ; a bare /ready TOGGLES, as on the
        ldy     #(UREADY)>>8    ;   Intellivision and the Astrocade
        jsr     UPUT
        jmp     BUQ
BU3:    cmp     #RQPLACE
        bne     BU4
; /place/P,P,P,P,P -- decimal, no leading zeros, no trailing comma.
        ldx     #(UPLACE)&$FF
        ldy     #(UPLACE)>>8
        jsr     UPUT
        ldx     #0
BU3A:   stx     BSIDX
        lda     SHIPS,x
        jsr     UDEC
        ldx     BSIDX
        inx
        cpx     #NSHIPS
        beq     BUQ
        lda     #','
        sta     FNTX
        jmp     BU3A
BU4:    cmp     #RQATTCK
        bne     BU5
; /attack/P, P = y*10 + x. Its reply IS the next state.
        ldx     #(UATTCK)&$FF
        ldy     #(UATTCK)>>8
        jsr     UPUT
        jsr     CELLNO
        jsr     UDEC
        jmp     BUQ
BU5:    ldx     #(USTATE)&$FF
        ldy     #(USTATE)>>8
        jsr     UPUT

; The query. Both halves come out of the cartridge.
BUQ:    ldx     #(UQTAB)&$FF
        ldy     #(UQTAB)>>8
        jsr     UPUT
        lda     #PBTABLE
        jsr     FNWSEL
        jsr     FNWRAW
        ldx     #(UQPLR)&$FF
        ldy     #(UQPLR)>>8
        jsr     UPUT
        lda     #PBNAME
        jsr     FNWSEL
        jsr     FNWRAW
        ldx     #(UQBIN)&$FF
        ldy     #(UQBIN)>>8
        jmp     UPUT

        INCLUDE "../build/endpoint.inc"

UTABLS: DB      "tables?bin=1",0
USTATE: DB      "state",0
UREADY: DB      "ready",0
UPLACE: DB      "place/",0
UATTCK: DB      "attack/",0
ULEAVE: DB      "leave",0
UQTAB:  DB      "?table=",0
UQPLR:  DB      "&player=",0
; v=2: the winner and the ship reveal at game over. No &be=1: the Go server's
; big-endian path is the road much less travelled.
UQBIN:  DB      "&bin=1&v=2",0
