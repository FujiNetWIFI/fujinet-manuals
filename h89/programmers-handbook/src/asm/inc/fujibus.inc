;-----------------------------------------------------------------------------
; fujibus.inc -- FujiBus transactions over the H89 card's 82C55A.
;
; fn_call   HL -> a request block (FNREQ in fujinet.inc):
;             +0 device   +1 command   +2 field descriptor   +3..+6 aux1-aux4
;             +7 payload address   +9 payload length
;             +11 reply buffer     +13 reply buffer size
;           Sends the request in a SLIP frame, then takes the whole reply,
;           to its closing END, so the next request starts clean.
;   Exit:   A  = FN_OK (ACK), FN_NAK, FN_TIMEOUT or FN_BAD; Z set on FN_OK
;           BC = the reply's payload length (all of it, even past the buffer)
;           carry set if the payload was longer than the buffer (the rest
;           was dropped); fn_rep = the reply's 6-byte header;
;           fn_res and fn_len keep A and BC for later
;           All other registers are changed.
;
; fn_raw    DE -> buffer, BC = its size. Takes whatever bytes come until
;           200 ms pass with none (the modem's replies are not framed).
;   Exit:   BC = bytes taken.
;
; fn_send   HL -> a request block: sends it as fn_call does, but does not
;           wait for a reply. For the modem (50H), which answers in bare
;           bytes or not at all: take what comes with fn_raw.
;   Exit:   A = FN_OK, Z set; FN_TIMEOUT if the ESP32 did not take it.
;
; Forked from fujinet-h89's common/fujibus.inc: a request block instead of
; variables, replies of any length, NAK told apart from a bad frame.
;
; Copyright (C) 2026 Thomas Cherryhomes
; SPDX-License-Identifier: GPL-3.0-or-later
;-----------------------------------------------------------------------------

TX_TIMEOUT      equ     500             ; 1 s for the ESP32 to take a byte
RX_FIRST        equ     7500            ; 15 s for the reply to begin
RX_TIMEOUT      equ     500             ; 1 s between reply bytes
RAW_FIRST       equ     1000            ; fn_raw: 2 s for the first byte
RAW_QUIET       equ     100             ; fn_raw: 200 ms of quiet ends it

fn_send:
        ld      a,1                     ; send only: no reply to wait for
        jr      fn_call0
fn_call:
        xor     a
fn_call0:
        ld      (fn_only),a
        ld      (fn_sp),sp              ; a timeout returns from here
        ld      (fn_rq),hl
        ld      a,(fn_dirty)            ; a call given up before: drain it
        or      a
        call    nz,fn_drain

        ; the header: device, command, length, checksum 0, descriptor, aux
        ld      a,(hl)
        ld      (fn_out),a              ; device
        inc     hl
        ld      a,(hl)
        ld      (fn_out+1),a            ; command
        inc     hl
        ld      a,(hl)
        and     7
        ld      (fn_out+5),a            ; descriptor
        ld      e,a                     ; how many aux bytes it carries
        ld      d,0
        push    hl
        ld      hl,fn_auxn
        add     hl,de
        ld      a,(hl)
        pop     hl
        ld      (fn_nout),a
        inc     hl
        ld      de,fn_out+6             ; aux1-aux4 (only n of them go)
        ld      bc,4
        ldir
        ld      e,(hl)                  ; payload address and length
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      (fn_pay),de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      (fn_plen),de
        ld      e,(hl)                  ; reply buffer and its size
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      (fn_rbuf),de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      (fn_rmax),de

        ld      a,(fn_nout)             ; length = 6 + aux + payload
        add     a,6
        ld      (fn_nout),a
        ld      l,a
        ld      h,0
        ld      de,(fn_plen)
        add     hl,de
        ld      (fn_out+2),hl
        xor     a                       ; checksum over header, aux, payload
        ld      (fn_out+4),a
        ld      d,a
        ld      hl,fn_out
        ld      a,(fn_nout)
        ld      c,a
        ld      b,0
        call    fn_cksum
        ld      hl,(fn_pay)
        ld      bc,(fn_plen)
        call    fn_cksum
        ld      a,d
        ld      (fn_out+4),a

        ; send: one END, the packet, one END
        ld      hl,TX_TIMEOUT
        ld      (fn_tlim),hl
        ld      a,SLIP_END
        call    fn_putc
        ld      hl,fn_out
        ld      a,(fn_nout)
        ld      c,a
        ld      b,0
        call    fn_slip
        ld      hl,(fn_pay)
        ld      bc,(fn_plen)
        call    fn_slip
        ld      a,SLIP_END
        call    fn_putc
        call    fn_txwait
        ld      a,(fn_only)             ; fn_send: that is all
        or      a
        jr      z,fn_recv
        ld      bc,0
        xor     a                       ; A = FN_OK, Z set, carry clear
        jp      fn_done

        ; receive: wait for an END, skip any more, decode up to the next
fn_recv:
        ld      hl,RX_FIRST
        ld      (fn_tlim),hl
fn_sync:
        call    fn_getc
        cp      SLIP_END
        jr      nz,fn_sync
        ld      hl,RX_TIMEOUT
        ld      (fn_tlim),hl
fn_skip:
        call    fn_getc
        cp      SLIP_END
        jr      z,fn_skip
        ld      hl,0                    ; the reply's first byte is in A
        ld      (fn_idx),hl
        ld      l,a
        xor     a
        ld      (fn_cks),a
        ld      a,l
fn_rx:
        cp      SLIP_END
        jr      z,fn_rxend
        cp      SLIP_ESC
        jr      nz,fn_rxput
        call    fn_getc
        cp      SLIP_ESC_END
        jr      nz,fn_rxesc
        ld      a,SLIP_END
        jr      fn_rxput
fn_rxesc:
        cp      SLIP_ESC_ESC
        jr      nz,fn_rxput
        ld      a,SLIP_ESC
fn_rxput:
        call    fn_store
        call    fn_getc
        jr      fn_rx

fn_rxend:
        ld      hl,(fn_idx)             ; at least a header,
        ld      de,6
        or      a
        sbc     hl,de
        jr      c,fn_bad
        ld      hl,(fn_idx)             ; as long as its header says,
        ld      de,(fn_rep+2)
        or      a
        sbc     hl,de
        jr      nz,fn_bad
        ld      a,(fn_cks)              ; with its checksum right
        ld      hl,fn_rep+4
        cp      (hl)
        jr      nz,fn_bad
        ld      a,(fn_rep+1)
        cp      NAK
        jr      z,fn_nak
        cp      ACK                     ; an ACK, from the device asked
        jr      nz,fn_bad
        ld      a,(fn_rep)
        ld      hl,fn_out
        cp      (hl)
        jr      nz,fn_bad
        call    fn_rlen
        xor     a                       ; A = FN_OK, Z set, carry clear
        ld      a,(fn_trunc)
        rra                             ; carry = truncated (Z kept)
        ld      a,FN_OK
        jr      fn_done
fn_nak:
        call    fn_rlen
        ld      a,FN_NAK
        or      a                       ; NZ, carry clear
        ld      a,(fn_trunc)
        rra
        ld      a,FN_NAK
        jr      fn_done
fn_bad:
        ld      bc,0
        ld      a,FN_BAD
        or      a
; every way out: keep the result for later (fn_res, fn_len); flags kept
fn_done:
        ld      (fn_res),a
        ld      (fn_len),bc
        ret

; BC = payload bytes received; fn_trunc = 1 if more than the buffer held
fn_rlen:
        ld      hl,(fn_idx)
        ld      de,6
        or      a
        sbc     hl,de
        ld      b,h
        ld      c,l
        ld      de,(fn_rmax)
        ex      de,hl                   ; HL = size, DE = received
        or      a
        sbc     hl,de                   ; size - received: borrow if short
        ld      a,0
        rla
        ld      (fn_trunc),a
        ret

; A reply byte: the first 6 to fn_rep, then into the reply buffer while it
; has room; every byte but the checksum's own goes into fn_cks
fn_store:
        ld      c,a
        ld      hl,(fn_idx)
        ld      a,h                     ; byte 4 is the checksum itself
        or      a
        jr      nz,fn_sum
        ld      a,l
        cp      4
        jr      z,fn_nosum
fn_sum:
        ld      a,(fn_cks)
        add     a,c
        adc     a,0
        ld      (fn_cks),a
fn_nosum:
        ld      hl,(fn_idx)
        inc     hl
        ld      (fn_idx),hl
        dec     hl
        ld      de,6
        or      a
        sbc     hl,de
        jr      nc,fn_spay
        add     hl,de                   ; header byte
        ld      de,fn_rep
        add     hl,de
        ld      (hl),c
        ret
fn_spay:
        ld      de,(fn_rmax)            ; payload byte, if there is room
        ld      a,l
        sub     e
        ld      a,h
        sbc     a,d
        ret     nc
        ld      de,(fn_rbuf)
        add     hl,de
        ld      (hl),c
        ret

; a timeout anywhere: give the call up (its reply may still be coming)
fn_abort:
        ld      a,1
        ld      (fn_dirty),a
        ld      sp,(fn_sp)
        ld      bc,0
        ld      a,FN_TIMEOUT
        or      a
        jr      fn_done

;@ex bus.cksum
; D += BC bytes from HL: an 8-bit sum with end-around carry
fn_cksum:
        ld      a,b
        or      c
        ret     z
        ld      a,d
        add     a,(hl)
        adc     a,0
        ld      d,a
        inc     hl
        dec     bc
        jr      fn_cksum
;@end

;@ex bus.slip
; BC bytes from HL, SLIP-escaped
fn_slip:
        ld      a,b
        or      c
        ret     z
        ld      a,(hl)
        cp      SLIP_END
        jr      z,fn_slipe
        cp      SLIP_ESC
        jr      z,fn_slipx
        call    fn_putc
        jr      fn_slipn
fn_slipe:
        ld      a,SLIP_ESC
        call    fn_putc
        ld      a,SLIP_ESC_END
        call    fn_putc
        jr      fn_slipn
fn_slipx:
        ld      a,SLIP_ESC
        call    fn_putc
        ld      a,SLIP_ESC_ESC
        call    fn_putc
fn_slipn:
        inc     hl
        dec     bc
        jr      fn_slip
;@end

;@ex model.expired
; carry once (TICKS - fn_t0) has reached fn_tlim. Uses HL, DE.
fn_expired:
        ld      hl,(TICKS)
        ld      de,(fn_t0)
        or      a
        sbc     hl,de
        ld      de,(fn_tlim)
        or      a
        sbc     hl,de
        ccf
        ret
;@end

;@ex model.putc
; wait until the ESP32 has taken the last byte (/OBF high). Keeps BC DE HL.
fn_txwait:
        in      a,(PORTC)
        and     PC_OBF
        ret     nz
        push    hl
        push    de
        ld      hl,(TICKS)
        ld      (fn_t0),hl
fn_txw1:
        in      a,(PORTC)
        and     PC_OBF
        jr      nz,fn_txw2
        call    fn_expired
        jr      nc,fn_txw1
        jp      fn_abort
fn_txw2:
        pop     de
        pop     hl
        ret

; send A. Keeps BC, DE, HL.
fn_putc:
        push    af
        call    fn_txwait
        pop     af
        out     (PORTA),a
        ret
;@end

;@ex model.getc
; the next byte from the ESP32 into A. Keeps BC, DE, HL.
fn_getc:
        in      a,(PORTC)
        and     PC_IBF
        jr      nz,fn_take
        push    hl
        push    de
        ld      hl,(TICKS)
        ld      (fn_t0),hl
fn_getc1:
        in      a,(PORTC)
        and     PC_IBF
        jr      nz,fn_getc2
        call    fn_expired
        jr      nc,fn_getc1
        jp      fn_abort
fn_getc2:
        pop     de
        pop     hl
fn_take:
        in      a,(PORTA)
        ret
;@end

; after a call given up part way: take bytes until 100 ms pass with none
; (and at most 2048, in case a missing card reads as an endless stream)
fn_drain:
        xor     a
        ld      (fn_dirty),a
        ld      hl,50
        ld      (fn_tlim),hl
        ld      bc,2048
fn_drain1:
        ld      hl,(TICKS)
        ld      (fn_t0),hl
fn_drain2:
        in      a,(PORTC)
        and     PC_IBF
        jr      z,fn_drain3
        in      a,(PORTA)
        dec     bc
        ld      a,b
        or      c
        ret     z
        jr      fn_drain1
fn_drain3:
        call    fn_expired
        jr      nc,fn_drain2
        ret

; take unframed bytes into DE (BC = room) until RAW_QUIET ticks of quiet
fn_raw:
        ld      (fn_rbuf),de
        ld      (fn_rmax),bc
        ld      hl,0
        ld      (fn_idx),hl
        ld      hl,RAW_FIRST
        ld      (fn_tlim),hl
fn_raw1:
        ld      hl,(TICKS)
        ld      (fn_t0),hl
fn_raw2:
        in      a,(PORTC)
        and     PC_IBF
        jr      nz,fn_raw3
        call    fn_expired
        jr      nc,fn_raw2
        ld      bc,(fn_idx)             ; quiet: done
        ret
fn_raw3:
        in      a,(PORTA)
        ld      c,a
        ld      hl,(fn_idx)
        ld      de,(fn_rmax)
        ld      a,l
        sub     e
        ld      a,h
        sbc     a,d
        jr      nc,fn_raw4              ; no room: count, drop
        ld      de,(fn_rbuf)
        add     hl,de
        ld      (hl),c
fn_raw4:
        ld      hl,(fn_idx)
        inc     hl
        ld      (fn_idx),hl
        ld      hl,RAW_QUIET
        ld      (fn_tlim),hl
        jr      fn_raw1

; aux bytes carried by each field descriptor, 0-7
fn_auxn:        defb    0, 1, 2, 3, 4, 2, 4, 4

; state
fn_rq:          defw    0
fn_sp:          defw    0
fn_out:         defs    10              ; header (6) and aux (up to 4)
fn_nout:        defb    0               ; header + aux bytes
fn_pay:         defw    0
fn_plen:        defw    0
fn_rbuf:        defw    0
fn_rmax:        defw    0
fn_rep:         defs    6               ; the reply's header
fn_idx:         defw    0
fn_cks:         defb    0
fn_t0:          defw    0
fn_tlim:        defw    0
fn_dirty:       defb    0
fn_only:        defb    0               ; 1: fn_send, no reply
fn_trunc:       defb    0
fn_res:         defb    0               ; the last call's result (A)
fn_len:         defw    0               ;   and reply length (BC)
