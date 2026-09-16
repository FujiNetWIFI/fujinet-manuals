; clock.asm -- the time of day, from the adapter's clock.
;
; The clock is a device of its own ($45). GET_ISO_LOCAL answers with the
; local time as text -- "2026-09-15T20:45:31" and a NUL -- in the adapter's
; configured time zone, and GET_ISO_UTC the same in UTC. Twelve columns is
; not nineteen, so the date goes on one row and the time on the next, both
; straight out of the reply window.

        CPU     6502
        INCLUDE "vcs.inc"

PAD3    EQU     $81
SAVSP   EQU     $82
APERR   EQU     $8F

        INCLUDE "fujinet.inc"
        INCLUDE "devdefs.inc"

        ORG     $1000

START:  sei
        cld
        ldx     #$FF
        txs
        lda     #0
CLRLP:  sta     $00,x
        dex
        bne     CLRLP
        sta     $00
        lda     #2
        sta     VBLANK
        lda     #0
        sta     APERR

        jsr     FNARM
        jsr     FNCHK
        beq     GOTCART
        lda     #FNENOC
        sta     APERR
        jmp     SHOW

; ---------------- GET_ISO_LOCAL: no parameters ----------------
GOTCART:
        lda     #CLKDEV
        sta     FNDEV
        lda     #CKISOL
        sta     FNCMD
        lda     #0
        sta     FNNPR
        jsr     FNBEG
        jsr     FNGO
        sta     APERR
        bne     SHOW
        jsr     FNACK
        sta     APERR
        bne     SHOW

        lda     #(TLOCAL)&$FF
        sta     FNPTRL
        lda     #(TLOCAL)>>8
        sta     FNPTRH
        lda     #2
        jsr     FNRSTR
        lda     #3              ; the date: ten characters from offset 0
        ldx     #0
        ldy     #10
        jsr     FNRRPL
        lda     #4              ; the time: eight from offset 11, past the T
        ldx     #11
        ldy     #8
        jsr     FNRRPL

; ---------------- GET_ISO_UTC ----------------
        lda     #CLKDEV
        sta     FNDEV
        lda     #CKISOU
        sta     FNCMD
        lda     #0
        sta     FNNPR
        jsr     FNBEG
        jsr     FNGO
        sta     APERR
        bne     SHOW
        jsr     FNACK
        sta     APERR
        bne     SHOW
        lda     #(TUTC)&$FF
        sta     FNPTRL
        lda     #(TUTC)>>8
        sta     FNPTRH
        lda     #6
        jsr     FNRSTR
        lda     #7
        ldx     #0
        ldy     #10
        jsr     FNRRPL
        lda     #8
        ldx     #11
        ldy     #8
        jsr     FNRRPL

SHOW:   lda     #(TTITLE)&$FF
        sta     FNPTRL
        lda     #(TTITLE)>>8
        sta     FNPTRH
        lda     #0
        jsr     FNRSTR
        lda     APERR
        beq     RUN
        lda     #10
        jsr     FNROWA
        lda     #'E'
        sta     FNRSEL+FH_TCHR
        lda     APERR
        jsr     FNHEX
        jsr     FNENDR
RUN:    lda     #0
        sta     VBLANK
        jsr     DINIT
        jmp     DLOOP

TTITLE: DB      "CLOCK",0
TLOCAL: DB      "LOCAL",0
TUTC:   DB      "UTC",0

        INCLUDE "fujilib.inc"
APPVBL: rts
        INCLUDE "fujidisp.inc"

        ORG     $1FFC
        DW      START
        DW      START
        END
