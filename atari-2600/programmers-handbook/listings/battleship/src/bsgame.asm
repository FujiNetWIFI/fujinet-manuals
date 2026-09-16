; bsgame.asm -- bank 1: the game.
;
; Every board on screen at once, composed BY THE CARTRIDGE out of the reply
; window into playfield tables (fujinet.inc, the playfield board) and drawn
; by dispgame.inc. The console never touches a cell.
;
; THE COMPOSER IS ANOTHER BANK. This one holds the kernel, the input, the
; cues and the cursor, and with the composer in it too it came in 961 bytes
; over. A poll's recompose -- a dozen blit ops and five text rows -- runs in
; bscomp in the vblank of the first frame back from the network, and bscomp
; hands the frame here to be finished, so no frame is ever anything but 262
; lines. What this bank holds is a cursor, the four bytes of state every
; screen keys on, the previous poll's values for the edges the cues ride on,
; and a local move clock.
;
; Three rules from the sibling clients, each learned somewhere else:
;
;   * A shot lands on EVERY live enemy at once, so the cursor is drawn on
;     every live enemy board and the shot is refused, with a tone, at a cell
;     already resolved on all of them -- the server refuses it silently and
;     the turn never passes.
;   * The result cue rides the STATUS edge paired with lastAttackPos, so an
;     opponent's shot is heard too and a result that repeats across polls is
;     heard once.
;   * The turn cue rides activePlayer's edge, and PRVAC advances on every
;     poll including the lobby's, so the lobby-to-play transition is caught
;     by the same comparison as any other turn change.

        CPU     6502
        INCLUDE "vcs.inc"
        INCLUDE "fujinet.inc"
        INCLUDE "bsdefs.inc"

BSBANK  EQU     BANKGAM
BSHASINP EQU    1
BSHASUI EQU     1
BSHASED EQU     0
BSHASNET EQU    0               ; BANKNET polls for it
BSHASCLS EQU    0
BSHASSTR EQU    0               ; BANKCMP composes for it
BSHASRPL EQU    0
BSHASDEC EQU    0
SNDFULL EQU     1
SNDLAST EQU     5               ; ...and the shot and the clock

        INCLUDE "../build/tail.inc"

        ORG     $1000

; ---------------------------------------------------------------------------
; Four ways in. ENGNEXT is from a poll by way of the composer, between
; frames: the next one is started. ENGRUN is from the composer's text pass,
; mid-frame: that frame is finished. ENGRUND is the same from the menu, by
; way of the composer, and the menu's kernel left the TIA set up for text,
; so DINIT first. ENGCOLD is from the lobby's hook. DINIT costs five lines,
; which is why it is not done on every entry: the overscan has thirty.
GENTRY: lda     BSENT
        cmp     #ENGCOLD
        beq     GCOLD
        cmp     #ENGNEXT
        beq     GRUN            ; between frames, from a poll: the TIA is as
                                ;   this kernel left it
        cmp     #ENGRUN
        beq     GRUN2           ; mid-frame, from the text pass: likewise
        jsr     DINIT           ; ENGRUND: mid-frame, from the menu's kernel
GRUN2:  jsr     DFRAME2
GRUN:   jsr     DFRAME
        jmp     GRUN

; A table was just joined. Nothing is known: set the state up and let the
; composer clear the screen, then poll on the first frame -- retrieving the
; state IS the join.
GCOLD:  lda     #0
        sta     BSPOLL
        sta     BSMODE
        sta     BSLIVE
        sta     BSCLK
        sta     BSERR2
        sta     SNDPTR
        sta     AUDV0
        sta     BSREDRW         ; the composer's previous seat count
        lda     #4
        sta     BSCURX
        sta     BSCURY
        lda     #$FF
        sta     BSPRVAC
        sta     BSPRVST
        sta     BSPRVLP
        sta     BSCLASS
        lda     #RQSTATE
        sta     BSREQ2
        lda     #1
        sta     BSMODE
        jsr     DINIT           ; finish the lobby's frame with blank boards,
        jsr     DFRAME2         ;   then the composer clears, in the overscan
        lda     #BANKCMP        ; ENGCOLD still: back as ENGNEXT
        jmp     BSGOTO

; ---------------------------------------------------------------------------
; The per-frame hook.
APPVBL: jsr     SNDTICK
; The composer's text pass, owed from the last poll: taken here, at the top
; of a vblank, and the composer finishes this frame.
        bit     BSREDRW
        bpl     GA0
        lda     #ENTEXT
        sta     BSENT
        lda     #BANKCMP
        jmp     BSGOTO
GA0:    jsr     INREPT
        sta     BSINP
        and     #IN_RST
        beq     GA1
        lda     #ENMENU
        sta     BSENT
        lda     #BANKMNU
        jmp     BSGOTO
GA1:    lda     BSINP
        and     #IN_SEL
        beq     GA2
        lda     #0              ; poll now
        sta     BSPOLL
GA2:    lda     BSCLASS
        cmp     #CLPLAY
        bne     GA5
        lda     BSMYST
        bne     GA6             ; defeated, or watching: no cursor, no shot
        lda     BSINP
        and     #INDIRS
        beq     GA3
        jsr     GMOVE
GA3:    lda     BSINP
        and     #IN_FIRE
        beq     GA6
        jsr     GFIRE
        jmp     GA6
GA5:    lda     BSCLASS         ; the lobby: FIRE readies (a toggle)
        bne     GA6
        lda     BSINP
        and     #IN_FIRE
        beq     GA6
        lda     #RQREADY
        sta     BSREQ2
        lda     #0
        sta     BSPOLL
        lda     #SNDSEL
        jsr     SNDFIRE
GA6:    jsr     GCLOCK
; The poll clock stops AT zero and the switch is taken here, inside the
; vblank: the network bank finishes this frame. The test comes before the
; decrement, or a due poll would wrap the clock to 255.
        lda     BSPOLL
        beq     GA7
        dec     BSPOLL
        rts
GA7:    lda     #ENFETCH
        sta     BSENT
        lda     #BANKNET
        jmp     BSGOTO

; ---------------------------------------------------------------------------
; GMOVE -- the stick moved the cursor: off every live board, step, back on.
GMOVE:  lda     #PFM_AUX|PFM_CLR
        jsr     GCURS
        lda     BSINP
        lsr     a
        bcc     GM1             ; up
        lda     BSCURY
        beq     GM4
        dec     BSCURY
        jmp     GM4
GM1:    lsr     a
        bcc     GM2             ; down
        lda     BSCURY
        cmp     #BRDDIM-1
        bcs     GM4
        inc     BSCURY
        jmp     GM4
GM2:    lsr     a
        bcc     GM3             ; left
        lda     BSCURX
        beq     GM4
        dec     BSCURX
        jmp     GM4
GM3:    lda     BSCURX          ; right
        cmp     #BRDDIM-1
        bcs     GM4
        inc     BSCURX
GM4:    lda     #SNDMOVE
        jsr     SNDSOFT         ; never over a hit
        lda     #PFM_AUX
        jmp     GCURS
; ---------------------------------------------------------------------------
; GFIRE -- FIRE in play: stage /attack at the cursor, if it is your turn and
; the cell is still unresolved on at least one live enemy.
GFIRE:  lda     BSACT
        bne     GFERR
        jsr     CELLNO
        sta     BSTMP2
        ldx     #1
GF1:    cpx     BSPCNT
        bcs     GFERR           ; nowhere it would land: refuse it
        stx     BSIDX
        jsr     PLRECP
        ldy     #PLSTAT
        lda     (FNPTRL),y
        bne     GF2             ; defeated or watching: not a target
        lda     FNPTRL
        clc
        adc     #PLFIELD
        sta     FNPTRL
        bcc     GF1A
        inc     FNPTRH
GF1A:   ldy     BSTMP2
        lda     (FNPTRL),y
        beq     GFOK            ; open sea here: it lands
GF2:    ldx     BSIDX
        inx
        jmp     GF1
GFOK:   lda     #RQATTCK
        sta     BSREQ2
        lda     #0
        sta     BSPOLL
        lda     #SNDSHOT
        jmp     SNDFIRE
GFERR:  lda     #SNDERR
        jmp     SNDFIRE

; ---------------------------------------------------------------------------
; GCLOCK -- the move clock, counted down locally a second at a time from the
; server's moveTime (already net of a round trip), ticking in its last
; seconds, and polling when it runs out: the server has moved on by then and
; a client that waited for a button would never learn.
GCLOCK: lda     BSCLASS
        cmp     #CLPLAY
        bne     GCKX
        lda     BSCLK
        beq     GCKX
        dec     BSTICK
        bne     GCKX
        lda     #60
        sta     BSTICK
        dec     BSCLK
        lda     BSACT
        bne     GCKX            ; only your own clock shows
        jsr     GCLKDR
        lda     BSCLK
        beq     GCK0
        cmp     #6
        bcs     GCKX
        lda     #SNDCLK
        jmp     SNDFIRE
GCK0:   sta     BSPOLL
GCKX:   rts

; GCLKDR -- the three clock digits at the end of the status row, a cell
; each through FB_TCELL: the only part of the row a second changes, and the
; composer that draws the rest lives in another bank.
GCLKDR: lda     BSCLK
        ldx     #0
GCD1:   cmp     #100
        bcc     GCD2
        sbc     #100
        inx
        bne     GCD1
GCD2:   pha
        txa
        beq     GCD2A
        clc
        adc     #'0'
        jmp     GCD2B
GCD2A:  lda     #' '            ; no leading zero
GCD2B:  ldx     #RSTAT*FNTCOL+9
        jsr     GCDCEL
        pla
        ldx     #0
GCD3:   cmp     #10
        bcc     GCD4
        sbc     #10
        inx
        bne     GCD3
GCD4:   pha
        txa
        clc
        adc     #'0'
        ldx     #RSTAT*FNTCOL+10
        jsr     GCDCEL
        pla
        clc
        adc     #'0'
        ldx     #RSTAT*FNTCOL+11
GCDCEL: ldy     #0
        jsr     FNBARG
        lda     #FB_TCELL
        jmp     FNBLIT

        INCLUDE "bslib.inc"
        INCLUDE "state.inc"
        INCLUDE "sound.inc"
        INCLUDE "dispgame.inc"

        END
