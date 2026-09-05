; state.inc -- reading the reply where it lies.
;
; The reply stays painted in the cart's 256-byte slice window (FNRDATA)
; until the next transaction, so nothing is ever buffered: these helpers
; give the rest of the program a flat 0-1023 offset space over it, and
; switch slices only when a read crosses a 256-byte boundary. CURSLC
; caches the slice the cart is currently publishing; every transaction
; ends with the cart republishing slice 0 and net.inc re-homing the cache.

; RXGETB: A = reply byte at offset HL. Preserves HL, BC, DE.
RXGETB: PUSH    BC
        PUSH    DE
        PUSH    HL
        LD      A,H             ; slice = offset high byte (0-3)
        LD      HL,CURSLC
        CP      (HL)
        JR      Z,RXG1
        LD      (HL),A
        CALL    FNSLICE         ; repaints in microseconds; a timeout here
RXG1:   POP     HL              ; means the cart is gone anyway
        PUSH    HL
        LD      D,3BH           ; FNRDATA page
        LD      E,L
        LD      A,(DE)
        POP     HL
        POP     DE
        POP     BC
        RET

; RXGETW: DE = little-endian word at offset HL. Preserves HL, BC.
RXGETW: CALL    RXGETB
        LD      E,A
        INC     HL
        CALL    RXGETB
        LD      D,A
        DEC     HL
        RET

; RXSTRN: copy at most B bytes from offset HL into (DE), stopping at a
; NUL; the destination is always NUL-terminated. Preserves HL, DE.
RXSTRN: PUSH    HL
        PUSH    DE
RXS1:   CALL    RXGETB
        OR      A
        JR      Z,RXS9
        LD      (DE),A
        INC     HL
        INC     DE
        DJNZ    RXS1
RXS9:   XOR     A
        LD      (DE),A
        POP     DE
        POP     HL
        RET
