; state.inc -- reading the reply where it lies.
;
; The reply stays painted in the cart's 256-byte slice window until the
; next transaction, so nothing is buffered: page-0 code sets the flat
; cursor (RXPTR = slice, RXPTR+1 = offset -- both page-0 RAM it can
; store directly) and then calls RXNEXT per byte. RXNEXT switches slices
; only when the cursor's slice differs from the cached CURSLC; every
; transaction ends with the cart republishing slice 0 and net.inc
; re-homing the cache.

; RXNEXT: R0 = the reply byte at the cursor; the cursor advances.
; PRESERVES R2 (render loops keep their screen cell there). Calls one
; down (MSLICE, on a slice cross only). Clobbers R0,R1,R3.
RXNEXT: LODA,R0 *PRXSLC
        COMA,R0 *PCURSL
        BCTR,EQ RXN1
        STRA,R2 *PSAV2          ; shelter the caller's R2
        STRZ    R2              ; wanted slice
        STRA,R0 *PCURSL
        BSTA,UN MSLICE
        LODA,R2 *PSAV2
RXN1:   LODA,R1 *PRXOFF
        LODA,R0 FNRDATA,R1      ; the byte
        STRZ    R3
        ADDI,R1 1
        STRA,R1 *PRXOFF
        BCFR,EQ RXN2            ; wrapped to 0: next slice
        LODA,R0 *PRXSLC
        ADDI,R0 1
        STRA,R0 *PRXSLC
RXN2:   LODZ    R3
        RETC,UN
