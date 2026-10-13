;-----------------------------------------------------------------------------
; card.inc -- start the H89 FujiNet card if nothing has yet (as FNON does),
; and face it toward us. From fujinet-h89's common/card.inc. Uses TICKS.
;
; The mark in port B and EN high mean something set the card up and nothing
; has reset the 82C55A since. EN alone can't tell: after a reset the 82C55A's
; bus hold can pull PC2 high while port A isn't in mode 2.
;
; Copyright (C) 2026 Thomas Cherryhomes
; SPDX-License-Identifier: GPL-3.0-or-later
;-----------------------------------------------------------------------------

card_on:
;@ex model.card_on
        in      a,(PORTB)               ; set up since the last reset?
        cp      SETUP_MARK
        jr      nz,card_start
        in      a,(PORTC)
        and     PC_EN
        jr      nz,card_ready           ; yes, and running: leave it
card_start:
        ld      a,MODE2                 ; mode 2; PC0-PC2 out, all 0
        out     (PCTRL),a
        ld      a,0x06                  ; EN=1, IO0=1 at once
        out     (PORTC),a
        ld      b,100                   ; about 200 ms with IO0 high
card_wait:
        call    tick
        djnz    card_wait
        ld      a,SETUP_MARK            ; the card is set up
        out     (PORTB),a
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
