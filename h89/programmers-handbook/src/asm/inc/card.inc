;-----------------------------------------------------------------------------
; card.inc -- set the H89 FujiNet card up. After fujinet-h89's
; common/card.inc, less the start-up the reworked card no longer needs.
; Uses TICKS.
;
; The FujiNet runs from power-on; nothing here starts it. A mode word sets
; up only the 82C55A, so it is safe to send every time. Port A runs straight
; to the ESP32, which drives it through /ACK, so there is no direction to set.
;
; Copyright (C) 2026 Thomas Cherryhomes
; SPDX-License-Identifier: GPL-3.0-or-later
;-----------------------------------------------------------------------------

card_on:
;@ex model.card_on
        ld      a,MODE2                 ; mode 2; PC0-PC2 out, all 0
        out     (PCTRL),a
        in      a,(PORTA)               ; drop a byte latched before
        ret
;@end

; Is the card there? Z if so: PC0 and PC1, wired to nothing, read back the
; zeros the mode word left in them. Without a card the ports read FF, and
; every wait for a byte would see one at once, forever.
;@ex model.card_present
card_present:
        in      a,(PORTC)
        and     PC_OE|PC_DIR            ; PC1 and PC0 both 0
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
