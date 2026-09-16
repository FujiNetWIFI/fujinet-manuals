; fujitail.asm -- the fixed half of a batari Basic FujiNet client.
;
; A batari Basic program built with `set romsize 2k` is exactly the 2K the
; cartridge serves at $1000-$17FF, with its `start` at $1000. The cartridge
; needs one more 2K behind it: the claim that says "this image is a FujiNet
; client, keep the mailbox alive", and the RESET/BRK vectors, which the 6507
; fetches from $1FFC-$1FFF -- the fixed half -- whatever bank happens to be
; mapped low. Everything between $1800 and $1F0F is served by the cartridge
; itself (text planes, reply window, control and TX pages, status cells), so
; those bytes of this image are never seen by the console.
;
; Assemble once with dasm: dasm fujitail.asm -f3 -obuild/fujitail.bin
; (2048 bytes, $1800-$1FFF). tools/bbfix.py appends it to the program.
        processor 6502

FNRSEL  = $1D00                 ; + n: arm register n / one-shot ops
FH_BANK = $80                   ; + b: select bank b
FH_ARM1 = $FC                   ; the arming pair...
FH_ARM2 = $FD
FNAM1   = $B5
FNAM2   = $4A

        ORG     $1800           ; nothing here is ours to drive; one byte so
        .byte   0               ;   the raw image starts at $1800
        ORG     $1F10
        .byte   "FUJI"          ; the claim -- FN_R_CLAIM
        ORG     $1F14
        .byte   1, 6, 1         ; FN_R_HDR: bank count, cell height, layout rev

; The cold stub. The RESET switch restarts the 6507 with whatever bank was
; last selected still mapped, and this console's cartridge port has no reset
; line -- so the entry point lives in the fixed half and reselects bank 0
; before jumping to the program's own `start`. Banking is a control-page
; operation and the control page decodes nothing until the arming pair has
; arrived, so that comes first.
        ORG     $1F20
COLD    sei
        cld
        ldx     #$FF
        txs
        lda     #FNAM1
        sta     FNRSEL+FH_ARM1
        lda     #FNAM2
        sta     FNRSEL+FH_ARM2
        lda     #0
        sta     FNRSEL+FH_BANK  ; bank 0: the batari Basic program
        jmp     $1000           ; batari Basic's `start`

        ORG     $1FFC
        .word   COLD            ; RESET
        .word   COLD            ; BRK -- a runaway reboots rather than hangs
