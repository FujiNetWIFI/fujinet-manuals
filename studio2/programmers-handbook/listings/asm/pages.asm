; pages.asm -- one program across fourteen
; pages of the cartridge.
;
; A short branch reaches only its own page, so a
; program that outgrows a page leaves it with
; FJMP and reaches other pages with FCALL. Here
; each page calls `mark`, which shows the page
; it was called from, and jumps to the next.
; The cartridge's app pages are $0C-$0F and
; $x4-$xF for x = 1 to D.

        CPU     1802
        INCLUDE "fujinet.inc"
        INCLUDE "s2macro.inc"
        INCLUDE "s2defs.inc"

        ORG     0400H
        INCLUDE "s2call.inc"
        INCLUDE "fujilib.inc"
        INCLUDE "fujidisp.inc"

        ORG     0C00H
        INCLUDE "booklib.inc"

        FIT     40
main:   FCALL   d_cls
        PUTS    00H, t_title
        LDI     20H
        PLO     RC              ; where mark writes
        FCALL   mark            ; page $0C
        FJMP    1400H

; mark -- the caller's page, in hex, at RC.0;
; five to a row. R6 is the caller's return.
        FIT     43
mark:   GHI     R6
        PLO     RA
        GLO     RC
        FCALL   d_at
        GLO     RA
        FCALL   d_hex
        GLO     RC
        ADI     3
        PLO     RC
        ANI     0FH
        SMI     15
        BNF     mk1             ; still room
        GLO     RC
        ANI     0F0H
        ADI     10H
        PLO     RC
mk1:    FRET

done:   PUTS    90H, t_done
hang:   BR      hang

t_title: DB     "PAGES", 0
t_done:  DB     "ALL OK", 0

; PAGE here, next -- a page of its own
PAGE    MACRO   here, next
        ORG     here
        FCALL   mark
        FJMP    next
        ENDM

        PAGE    1400H, 2400H
        PAGE    2400H, 3400H
        PAGE    3400H, 4400H
        PAGE    4400H, 5400H
        PAGE    5400H, 6400H
        PAGE    6400H, 7400H
        PAGE    7400H, 8400H
        PAGE    8400H, 9400H
        PAGE    9400H, 0A400H
        PAGE    0A400H, 0B400H
        PAGE    0B400H, 0C400H
        PAGE    0C400H, 0D400H
        PAGE    0D400H, done

        S2CLAIM
