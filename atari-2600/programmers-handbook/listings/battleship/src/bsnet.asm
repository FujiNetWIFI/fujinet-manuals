; bsnet.asm -- bank 2: one request, with the picture up, and back.
;
; This bank exists for a size reason. net.inc and url.inc are about 550 bytes
; together, every bank carries its own copy of everything it calls, and the
; game bank needs the board kernel, the composer and the input. A poll
; happens every ninety frames, so paying a bank switch for one costs nothing.
;
; IT CARRIES THE BOARD KERNEL, though it composes nothing. A transaction is
; several socket round trips and the transport's wait for ACKSEQ is a spin
; loop; spun blind, the picture stops for the duration and the set sees a
; flash once a poll. net.inc spends every wait in DFRAME instead, redrawing
; the boards out of the tables the cartridge is still holding -- the reply
; window is not repainted until the READ, so what is on screen stays true.
;
; THE SWITCH IN IS TAKEN INSIDE THE VBLANK HOOK: the game bank switches here
; from its hook and this bank finishes that frame (DFRAME2) before it starts
; talking. THE SWITCH OUT IS TAKEN BETWEEN FRAMES, in the overscan the last
; frame's DFRAME2 armed: the composer's work and the game bank's re-entry
; both fit in it. Every frame across a poll is 262 lines, which is what "no
; shudder" means.
;
; The lobby's /tables and the menu's /leave come in blanked, on a screen
; change, and are spun blind: there is nothing to keep up.

        CPU     6502
        INCLUDE "vcs.inc"
        INCLUDE "fujinet.inc"
        INCLUDE "bsdefs.inc"

BSBANK  EQU     BANKNET
BSHASINP EQU    0               ; it draws nothing and reads no input
BSHASUI EQU     0               ; ...and touches no player record
BSHASED EQU     0
BSHASNET EQU    1               ; it is the only bank that issues requests
BSHASCLS EQU    0
BSHASSTR EQU    0
BSHASRPL EQU    0
BSHASDEC EQU    0

        INCLUDE "../build/tail.inc"

        ORG     $1000

; ---------------------------------------------------------------------------
NENTRY: lda     BSENT
        cmp     #ENTABLE
        bne     NE1
        jmp     NTABLE
NE1:    cmp     #ENLEAVE
        bne     NE2
        jmp     NLEAVE
NE2:

; ---------------------------------------------------------------------------
; A game request. The screen is mid-frame: finish it first.
        jsr     DFRAME2

; A STAGED REQUEST RIDES THE POLL: /attack, /ready and /place all return the
; next state, so there is no separate submit anywhere in this client.
        lda     BSREQ2
        jsr     APICALL
        sta     BSERR2
        lda     #RQSTATE
        sta     BSREQ2          ; sent, or abandoned; either way not re-sent

        lda     BSERR2
        beq     NGOOD
; A failure leaves the reply window alone, so the boards on screen are still
; the last good ones. Back off and let the game bank say so.
        lda     #FAILFRM
        sta     BSPOLL
        lda     BSREQ
        cmp     #RQPLACE
        bne     NBACKG
        lda     #ENPLFAIL       ; the placement was refused: place again
        sta     BSENT
        lda     #BANKPLC
        jmp     BSGOTO

; The poll cadence follows the phase: the lobby is slow, play is brisk, the
; game-over screen lingers until the server resets the table.
NGOOD:  lda     #0
        sta     BSERR
        lda     #POLLFRM
        ldx     BSSTAT
        beq     NG1             ; the lobby
        cpx     #STOVER
        bne     NG2
        lda     #OVERFRM
        jmp     NG2
NG1:    lda     #LOBFRM
NG2:    sta     BSPOLL
; Placement is not a choice, so it does not wait for a button. The test is
; BOTH the game's phase and YOUR status: the phase stays STPLACE until
; everyone has placed, so the phase alone would send you back to the
; placement screen the moment you had finished.
        lda     BSSTAT
        cmp     #STPLACE
        bne     NBACKG
        lda     BSMYST
        cmp     #PSPLACE
        bne     NBACKG
        lda     #ENPLACE
        sta     BSENT
        lda     #BANKPLC
        jmp     BSGOTO
; The reply came in during the last frame's overscan -- NPGO checks once a
; frame, after DFRAME has returned -- so the switch is taken HERE, between
; frames, and the composer's work lands inside that overscan.
NBACKG: lda     #ENGAME
        sta     BSENT
        lda     #BANKCMP
        jmp     BSGOTO

; ---------------------------------------------------------------------------
; The lobby's table list, blanked.
NTABLE: lda     #2
        sta     VBLANK
        lda     #RQTABLE
        jsr     APICALL
        beq     NTOK
        lda     #0
        sta     BSCNT           ; no tables to show
        jmp     NBACKL
NTOK:   lda     #0
        sta     BSERR
NBACKL: lda     #ENLOBBY
        sta     BSENT
        lda     #BANKLOB
        jmp     BSGOTO

; ---------------------------------------------------------------------------
; Leaving. The reply is a Game and is thrown away; what matters is that the
; server frees the seat. Then STRAIGHT ON TO A FRESH /tables, because the
; list the lobby is still holding has us sitting at one of them -- and
; falling into NTABLE is also what puts the lobby up WARM rather than cold.
NLEAVE: lda     #2
        sta     VBLANK
        lda     #RQLEAVE
        jsr     APICALL
        jmp     NTABLE

; ---------------------------------------------------------------------------
; APPVBL -- nothing. Every frame this bank draws is drawn from INSIDE a
; transaction, and polling for another here would re-enter APICALL through
; its own settle loop.
APPVBL: rts

        INCLUDE "bslib.inc"
        INCLUDE "net.inc"
        INCLUDE "url.inc"
        INCLUDE "state.inc"
        INCLUDE "dispgame.inc"

        END
