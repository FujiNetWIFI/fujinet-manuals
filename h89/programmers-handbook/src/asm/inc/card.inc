;-----------------------------------------------------------------------------
; card.inc -- start the H89 FujiNet card if nothing has yet (as FNON does),
; and face it toward us. From fujinet-h89's common/card.inc. Uses TICKS.
;
; Copyright (C) 2026 Thomas Cherryhomes
; SPDX-License-Identifier: GPL-3.0-or-later
;-----------------------------------------------------------------------------

card_on:
;@ex model.card_on
        in      a,(PORTC)
        and     PC_EN
        jr      nz,card_ready
        ld      a,MODE2                 ; mode 2; PC0-PC2 out, all 0
        out     (PCTRL),a
        ld      a,0x06                  ; EN=1, IO0=1
        out     (PORTC),a
        ld      a,0x02                  ; EN=0 with IO0 high
        out     (PORTC),a
        call    tick
        call    tick
        ld      a,0x06                  ; EN=1: boots from flash
        out     (PORTC),a
        ld      b,100                   ; about 200 ms
card_wait:
        call    tick
        djnz    card_wait
card_ready:
        in      a,(PORTA)               ; drop a byte latched at start
        ld      a,OE_ON
        out     (PCTRL),a
        ld      a,DIR_TO_H89
        out     (PCTRL),a
        ret
;@end

; Is the card there, running and facing us? Z if so. Without a card the
; ports read FF, and every wait for a byte would see one at once, forever.
;@ex model.card_present
card_present:
        in      a,(PORTC)
        and     0x07                    ; EN, /OE, DIR
        cp      PC_EN
        ret
;@end

; Wait for the next 2 ms tick
;@ex model.tick
tick:
        ld      a,(TICKS)
        ld      c,a
tick_wait:
        ld      a,(TICKS)
        cp      c
        jr      z,tick_wait
        ret
;@end
