; antic.s -- the 8-bit client's screen (atari-fastbasic-version/5card.bas
; InitScreen) on the 5200: ANTIC mode 4, 40 x 26, the font, the display lists,
; the DLI that colours the status rows and the deferred VBI that slides the
; underline.
;
; The screens and player/missile memory sit in the top 4K of RAM, which the
; Makefile reserves. Drawing always goes to the work screen; the front screen
; is a copy shown while a frame is being built (graphics.c).

        .export _scrWork, _scrFront, _pmBase
        .export _dlFrontNorm, _dlFrontTall, _dlWorkNorm, _dlWorkTall
        .export _fcsFont, _fcsDli, _dliBg, _dliFg
        .export _fcsVbi, _barHpos, _barTarget

_scrWork  = $3000               ; 1040 bytes each, inside one 4K block
_scrFront = $3410
_pmBase   = $3800               ; single-line PMG: players from $3C00

WSYNC   = $D40A
VCOUNT  = $D40B
HPOSP2  = $C002
COLPF1  = $C017
COLBK   = $C01A

; 3 + 8 blank lines (a DLI on the second: the table's colours), rows 0-23,
; row 24 and, 3 lines below, the status row: each of the last two after a
; DLI. A tall status bar moves the gap above row 24 so both rows read as one.
.macro  dlist   scr, tall
        .local  top
top:    .byte   $20, $F0
        .byte   $44, <scr, >scr
        .repeat 22
        .byte   $04
        .endrepeat
        .byte   $84
.if tall
        .byte   $20, $84
.else
        .byte   $84, $20
.endif
        .byte   $04
        .byte   $41, <top, >top
.endmacro

        .segment "DLIST"        ; 1K-aligned: all four in one page
_dlFrontNorm:   dlist _scrFront, 0
_dlFrontTall:   dlist _scrFront, 1
_dlWorkNorm:    dlist _scrWork, 0
_dlWorkTall:    dlist _scrWork, 1
        .assert >_dlFrontNorm = >(_dlWorkTall + 33), error, "display lists span a page"

        .segment "FONT"         ; $B800, clear of the cart's mailbox
_fcsFont:
        .incbin "atari-fastbasic-version/5card-fontmaker.fnt"

        .code

; The BIOS's dispatcher pushes nothing. The first DLI is told apart by
; VCOUNT, so a frame never inherits a miscount.
.proc   _fcsDli
        pha
        txa
        pha
        ldx     #0
        lda     VCOUNT
        cmp     #32
        bcc     :+
        ldx     idx
:       lda     _dliBg,x
        sta     WSYNC
        sta     COLBK
        lda     _dliFg,x
        sta     COLPF1
        inx
        stx     idx
        pla
        tax
        pla
        rti
.endproc

; The deferred VBI: the underline (player 2) glides half the remaining way
; to its target each frame, as the BASIC's move cursor does. The crt0's VBI
; has pushed A, X and Y; this ends the way its own deferred vector does.
.proc   _fcsVbi
        lda     _barTarget
        sec
        sbc     _barHpos
        beq     set
        bcc     down
        lsr     a               ; up: half the distance, rounded up
        adc     #0
        clc
        adc     _barHpos
        sta     _barHpos
        jmp     set
down:   eor     #$FF            ; down: the distance, halved, rounded up
        clc
        adc     #1
        lsr     a
        adc     #0
        sta     step
        lda     _barHpos
        sec
        sbc     step
        sta     _barHpos
set:    lda     _barHpos
        sta     HPOSP2
        pla
        tay
        pla
        tax
        pla
        rti
.endproc

        .bss
_dliBg: .res    3               ; the table, row 24, the status row
_dliFg: .res    3
idx:    .res    1
_barHpos:   .res 1
_barTarget: .res 1
step:   .res    1
