; crt0bank.s -- fujinet-lib's atari7800 crt0 (bus/atari7800/crt0.s), with
; one byte changed: the claim names the bank scheme, SuperGame with cart RAM
; (kind byte = A78MAP_SG_RAM + 1), so the cartridge banks the image itself.
;
; crt0.s -- startup for a FujiNet Atari 7800 client, in place of cc65's.
;
; cc65's own locks INPTCTRL ($07 to $01); this one never stores to $00-$1F,
; so INPTCTRL stays unlocked and a game can later be handed to the
; console's BIOS. The cart's RAM at $4000 is there because the claim below
; asks for it.

        .export         __STARTUP__ : absolute = 1
        .export         _exit
        .export         _fuji_a7800_nmi
        .import         __STACK_START__, __STACK_SIZE__
        .import         initlib, donelib, zerobss, copydata
        .import         push0, _main

        .include        "zeropage.inc"

CTRL    = $3C
OFFSET  = $38

        .segment "STARTUP"
start:  sei
        cld
        lda     #$7F            ; MARIA's DMA off until the program builds a display
        sta     CTRL
        lda     #0
        sta     OFFSET
        ldx     #$FF
        txs
        lda     #<(__STACK_START__ + __STACK_SIZE__)
        sta     c_sp
        lda     #>(__STACK_START__ + __STACK_SIZE__)
        sta     c_sp+1

        jsr     zerobss
        jsr     copydata
        lda     #$4C            ; JMP rti_only; no NMI comes before a display is on
        sta     _fuji_a7800_nmi
        lda     #<rti_only
        sta     _fuji_a7800_nmi+1
        lda     #>rti_only
        sta     _fuji_a7800_nmi+2
        jsr     initlib
        jsr     push0           ; argc
        jsr     push0           ; argv
        ldy     #4
        jsr     _main
_exit:  jsr     donelib
@hang:  jmp     @hang

rti_only:
        rti

        .segment "BSS"
_fuji_a7800_nmi:
        .res    3               ; JMP to a display-list interrupt handler

        .segment "CLAIM"
        .byte   "FUJI", 1, 5, 1, 0, 0, 0    ; version 1, SuperGame + RAM, cart RAM

        .segment "VECTORS"
        .byte   $FF, $87                    ; $FFF8/$FFF9: a 7800 cart
        .word   _fuji_a7800_nmi, start, rti_only
