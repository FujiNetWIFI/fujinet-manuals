; bscore.inc -- the contents of the fixed half.
;
; Included by bstail.asm, which is the copy that becomes the real client's
; last 2K, AND by layout.asm, whose flat 4K image contains its own fixed half.
; Sharing the source is what makes the addresses in build/tail.inc true for
; both: the layout ROM used to include only the generated equates, so every
; jsr into the shared transport landed on p2bin's filler.

; BSGOTO is not a label: bsdefs.inc gives it a fixed address and this ORG is
; what makes that true, so the two cannot drift apart. It must be FIRST in the
; tail, because it is the one address a bank has to know before build/tail.inc
; exists.
        ORG     BSGOTO

; ---------------------------------------------------------------------------
; BSGOTO -- select bank A and enter it at $1000.
;
; `sta FNRSEL,x` is the documented-safe indexed form: the base low byte is $00
; so the index cannot carry, which means the dummy read STA abs,X always
; performs lands on the same address as the write.
        clc
        adc     #FH_BANK
        tax
        sta     FNRSEL,x
; RESET THE STACK. A bank switch is a JUMP and nothing ever returns through
; one, so every switch abandons whatever return addresses were on the stack --
; and the switches here are taken from inside APPVBL, which DLOOP reaches with
; a JSR. Two bytes leaked per poll, a poll every ninety frames, and after
; thirty-five of them the stack had grown down out of $C0-$FF and was
; overwriting BSMOVE, BSENT and BSFRAME: a bank entry dispatching on an entry
; code that was really the low byte of a return address.
;
; This is the one place it can be got right once. The store above has already
; switched the bank, but these instructions are fetched from the FIXED tail,
; which is not banked, so they still execute.
        ldx     #$FF
        txs
        jmp     $1000

; ---------------------------------------------------------------------------
; The shared transport. tools/mktail.py turns the addresses these assemble to
; into build/tail.inc, which is what the banks include.
        INCLUDE "bstrans.inc"

; ---------------------------------------------------------------------------
; BSCOLD -- power-on and RESET.
;
; Deliberately TINY. Everything a cold start has to do -- clear the 128 bytes,
; blank the screen, empty the cartridge's four path buffers -- is done by bank
; 0 at BSCOLD2, because the tail is 220 bytes and the shared transport and
; text primitives want 160 of them. All that has to be here is what cannot be
; anywhere else: the arming pair, because banking is a control-page operation
; and that page decodes nothing until an ordered pair of stores carrying two
; specific values arrives, and the bank switch itself.
;
; A cold stub in bank 0 would not do. This console has NO RESET LINE to the
; cartridge: the RESET switch restarts the 6507 with whatever bank was last
; selected still mapped, so the stub has to be somewhere every bank can see.
BSCOLD: sei
        cld
        ldx     #$FF
        txs
; FORCE A COLD ENTRY. This console does not clear its RAM on a reset, so
; BSENT -- the byte that says what the bank being entered should do -- still
; holds whatever the last screen set it to. A reset taken at the keyboard came
; back into the LOBBY'S WARM PATH, which redraws a table list out of a reply
; window that is holding a Game, and reads table names out of the middle of
; lastResult.
        lda     #ENCOLD
        sta     BSENT
        lda     #FNAM1
        sta     FNRSEL+FH_ARM1
        lda     #FNAM2
        sta     FNRSEL+FH_ARM2
        lda     #BANKLOB
        jmp     BSGOTO

        ORG     $1FFC
        DW      BSCOLD
        DW      BSCOLD

