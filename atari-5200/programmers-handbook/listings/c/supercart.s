; supercart.s -- the Super Cart's bank switch, for C. A bank is chosen by
; READING a hotspot, which C cannot be trusted to do: cc65 drops a load
; whose value is unused. BIT reads without touching A or X, so a far call
; keeps its return value.

        .export _far_bank0
        .import _bank0_main

; uint8_t far_bank0 (void) -- run bank 0's bank0_main() and come back to the
; last bank (bank 1, the power-on bank). Common code: the same bytes are at
; this address in both banks.
.proc _far_bank0
        bit     $BFD0           ; bank 0 from the next fetch on
        jsr     _bank0_main
        bit     $BFE0           ; the last bank again
        rts
.endproc
