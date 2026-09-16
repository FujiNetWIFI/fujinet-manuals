; bsplace.asm -- bank 5: put your five ships on the water.
;
; The five placements are staged in console RAM -- five bytes at SHIPS, each
; pos + 100*dir, the server's own encoding -- and sent when all five are
; down, through BANKNET like every request. The board shows them as the
; cartridge composes them: every hull as a bracket, the one being placed
; blinking, all through FB_PFCEL one cell at a time.
;
; A RANDOM LEGAL FLEET IS ROLLED FIRST AND THEN ADJUSTED, which is what every
; sibling does and is the right way round: the player is never made to solve
; the packing problem from an empty board, the whole fleet is on the board
; before a finger moves, and five presses accept the roll as it stands. The
; stick moves the ship whose turn it is FROM WHERE THE ROLL PUT IT.
;
; THE ROLL IS ONE CANDIDATE A FRAME, in the vblank hook, not a loop in
; PENTRY. A candidate costs up to about 1,650 cycles -- the hunt has to walk
; every hull already down -- and a whole fleet is thousands more than the
; two thousand two hundred an entry between frames has. Spread, the worst
; frame is one candidate and the picture never moves; a fleet takes about ten
; frames to land, which is a sixth of a second and looks like a deal. Nothing
; reads the stick until it is down.
;
; Bounds AND overlaps are checked here now. Bounds always were -- a hull
; running off the edge is a thing the player can see going wrong. Overlaps
; used to be left to the server, which cost a refusal, a round trip, and all
; five ships redone; the roll has to know about them anyway, so the same test
; refuses a move that would sit on another hull, with a tone, for free.

        CPU     6502
        INCLUDE "vcs.inc"
        INCLUDE "fujinet.inc"
        INCLUDE "bsdefs.inc"

BSBANK  EQU     BANKPLC
BSHASINP EQU    1
BSHASUI EQU     0               ; your own board only: no PLRECP, no GCURS
BSHASED EQU     0
BSHASNET EQU    0
BSHASCLS EQU    0
BSHASSTR EQU    1
BSHASRPL EQU    0
BSHASDEC EQU    0
SNDFULL EQU     1
SNDLAST EQU     3               ; move, select, place, refused

        INCLUDE "../build/tail.inc"

; The hull walk's cells, live only inside PHULLS and POVL -- one walk at a
; time, which is why three are enough. The game bank's clock cells, which it
; reloads on its next compose -- NOT its edge memory at $AE-$B0, which has to
; survive placement or the first poll after it hears a phantom shot.
BSPOS   EQU     BSCLK
BSSEG   EQU     BSTICK
BSPDIR  EQU     BSPOLL
; The roll's own cells, on the same terms. BSSEL is the lobby's list cursor
; and the keyboard's cell; BSERR2 is APICALL's result, which the network bank
; writes before anything reads it again; BSBLINK is zeroed after the roll.
BSRNDL  EQU     BSSEL
BSRNDH  EQU     BSERR2
BSCND   EQU     BSTMP2          ; the candidate, pos + 100*dir. CELLNO
                                ;   clobbers BSTMP2 and is called before it

        ORG     $1000

; The seed. FNACKS is the cartridge's sequence echo -- transactions have run
; by the time anyone places, so it differs run to run -- and BSFRAME counts
; how long the lobby took, which is human. INTIM would be the obvious third,
; and is not read here: reading it CLEARS the TIMINT latch the kernel waits
; on, and this runs inside an overscan that is already armed.
PENTRY: lda     FNACKS
        eor     BSFRAME
        sta     BSRNDL
        lda     FNRPLY+GOMVTIM
        eor     #$A5
        ora     #1              ; an all-zero LFSR never leaves zero
        sta     BSRNDH
        lda     #1              ; the layout follows the seat count
        ldx     BSPCNT
        cpx     #3
        bcs     PE2
        lda     #0
PE2:    sta     BSMODE          ; no DINIT: the network bank's kernel is this
        ldx     #NSHIPS-1       ;   one, and the TIA is as it left it
        lda     #$FF            ; an empty slate for the roll to fill, a ship
PE1:    sta     SHIPS,x         ;   a frame
        dex
        bpl     PE1
        lda     #0
        sta     BSSHIP
        sta     BSDIR
        sta     BSBLINK
        sta     BSCURX
        sta     BSCURY
        sta     BSLIVE
        jsr     PCLEAR
        jsr     PTEXT
        lda     BSENT
        cmp     #ENPLFAIL
        bne     PE3
        ldx     #(TAGAIN)&$FF   ; the server refused the last set
        ldy     #(TAGAIN)>>8
        jsr     PSTAT
PE3:    jsr     PHULLS          ; all of it inside the overscan the network
PRUN:   jsr     DFRAME          ;   bank's last frame armed
        jmp     PRUN

; ---------------------------------------------------------------------------
APPVBL: jsr     SNDTICK
        lda     SHIPS+NSHIPS-1  ; the last slot filled is the roll's flag
        cmp     #$FF
        bne     PA0
        jmp     PROLLF
PA0:    jsr     INREPT
        sta     BSINP
        and     #IN_RST
        beq     PA1
        lda     #ENMENU
        sta     BSENT
        lda     #BANKMNU
        jmp     BSGOTO
PA1:    lda     BSINP
        and     #INDIRS
        beq     PA2
        jsr     PMOVE
        jmp     PHULLS
PA2:    lda     BSINP
        and     #IN_SEL
        beq     PA3
        lda     BSDIR           ; rotate
        eor     #1
        sta     BSDIR
        lda     #SNDMOVE
        jsr     SNDSOFT
        jmp     PHULLS
PA3:    lda     BSINP
        and     #IN_FIRE
        beq     PA4
        jmp     PPLACE
PA4:    inc     BSBLINK         ; the pending ship blinks
        lda     BSBLINK
        and     #BLINKFR-1
        bne     PAX
        jmp     PHULLS
PAX:    rts

PMOVE:  lda     BSINP
        lsr     a
        bcc     PM1             ; up
        lda     BSCURY
        beq     PM4
        dec     BSCURY
        jmp     PM4
PM1:    lsr     a
        bcc     PM2             ; down
        lda     BSCURY
        cmp     #BRDDIM-1
        bcs     PM4
        inc     BSCURY
        jmp     PM4
PM2:    lsr     a
        bcc     PM3             ; left
        lda     BSCURX
        beq     PM4
        dec     BSCURX
        jmp     PM4
PM3:    lda     BSCURX          ; right
        cmp     #BRDDIM-1
        bcs     PM4
        inc     BSCURX
PM4:    lda     #SNDMOVE
        jmp     SNDSOFT

; ---------------------------------------------------------------------------
; PPLACE -- stage the current ship, and send them all once the last is down.
PPLACE: jsr     FITS
        bne     PBAD            ; off the edge: leave it where it was
        jsr     PCAND
        sta     BSCND
        jsr     POVL
        bne     PBADO           ; on another hull: likewise
        lda     BSCND
        ldx     BSSHIP
        sta     SHIPS,x
        inx
        cpx     #NSHIPS
        bcs     PSEND
        stx     BSSHIP
        jsr     PLOAD           ; the next ship, where the roll put it
        lda     #SNDPLC
        jsr     SNDFIRE
        jsr     PTEXT
        jmp     PHULLS

PSEND:  lda     #SNDSEL
        jsr     SNDFIRE
        lda     #RQPLACE
        sta     BSREQ2
        lda     #ENFETCH
        sta     BSENT
        lda     #BANKNET
        jmp     BSGOTO

PBADO:  lda     #(TLAP)&$FF
        ldy     #(TLAP)>>8
        bne     PBADS           ; always: neither string is at $xx00
PBAD:   lda     #(TOFF)&$FF
        ldy     #(TOFF)>>8
PBADS:  sta     BSTMP           ; SNDFIRE keeps Y and BSTMP, not X
        lda     #SNDERR
        jsr     SNDFIRE
        ldx     BSTMP
        jmp     PSTAT

; FITS -- Z set if the current ship fits on the board from the cursor.
FITS:   ldx     BSSHIP
        lda     SHPSIZ,x
        clc
        adc     #$FF            ; length - 1, the last segment's offset
        ldx     BSDIR
        bne     FIT1
        clc
        adc     BSCURX
        jmp     FIT2
FIT1:   clc
        adc     BSCURY
FIT2:   cmp     #BRDDIM
        bcs     FITNO
        lda     #0
        rts
FITNO:  lda     #1
        rts

; ---------------------------------------------------------------------------
; PHULLS -- your board's AUX plane: every staged ship EXCEPT the one being
; placed, and that one on the blink's lit phase at wherever the cursor has
; it. Every slot is filled from the first frame now, so this paints the whole
; fleet -- and painting "all but the one being moved" is exactly the picture
; POVL reasons about.
PHULLS: jsr     PSLOT0
        tax
        stx     BSLIVE          ; your slot, for the cells below
        lda     #PFM_AUX
        ldy     #0
        jsr     FNBARG
        lda     #FB_PFCLR
        jsr     FNBLIT
        ldx     #0
PH1:    cpx     #NSHIPS
        bcs     PH2
        cpx     BSSHIP
        beq     PH1A            ; the pending one: the blink below draws it
        stx     BSIDX
        lda     SHIPS,x
        jsr     HULL
        ldx     BSIDX
PH1A:   inx
        bne     PH1             ; always
PH2:    lda     BSBLINK
        and     #BLINKFR
        bne     PH9
        jsr     FITS
        bne     PH9             ; off the edge: show nothing rather than a
        jsr     PCAND           ;   hull wrapping into the next row
        ldx     BSSHIP
        stx     BSIDX
        jmp     HULL
PH9:    rts

; PCAND -- A = the cursor as pos + 100*dir, the server's own encoding.
PCAND:  jsr     CELLNO          ; A = y*10 + x; clobbers BSTMP2
        ldx     BSDIR
        beq     PCA1
        clc
        adc     #BRDCELL
PCA1:   rts

; PDEC -- start a hull walk: BSPOS = pos and BSPDIR = dir from A, which is
; pos + 100*dir, and BSSEG = the length of ship X. The head HULL used to
; carry inline, so POVL can walk a hull too.
PDEC:   ldy     #0
        cmp     #BRDCELL
        bcc     PDC1
        sbc     #BRDCELL        ; the compare left C set
        ldy     #1
PDC1:   sty     BSPDIR
        sta     BSPOS
        lda     SHPSIZ,x
        sta     BSSEG
        rts

; PSTEP -- the walk along one cell and one segment down. Z set when it is
; finished. BSPOS cannot wrap: the hull was bounds-checked before the walk.
PSTEP:  lda     BSPOS
        clc
        ldy     BSPDIR
        beq     PST1
        adc     #BRDDIM         ; down a row
        bne     PST2            ; always: pos + 10 is at least 10
PST1:   adc     #1              ; along
PST2:   sta     BSPOS
        dec     BSSEG
        rts

; HULL -- the cells of ship BSIDX placed at A (pos + 100*dir), into AUX.
HULL:   ldx     BSIDX
        jsr     PDEC
HU2:    lda     #PFM_AUX
        ldx     BSLIVE
        ldy     BSPOS
        jsr     FNBARG
        lda     #FB_PFCEL
        jsr     FNBLIT
        jsr     PSTEP
        bne     HU2
        rts

; ---------------------------------------------------------------------------
; POVL -- Z set if the candidate hull -- ship BSSHIP at cell BSCND in
; direction BSDIR -- is clear of every OTHER staged ship.
;
; No occupancy map: a hundred bytes is most of this console's RAM. Instead
; each staged hull is WALKED and each of its cells asked whether the
; candidate covers it, which is arithmetic. One walk is live at a time, so
; PHULLS's three cells are all it costs.
POVL:   ldx     #NSHIPS-1
PVL1:   cpx     BSSHIP
        beq     PVL7
        lda     SHIPS,x
        cmp     #$FF
        beq     PVL7            ; not placed yet: nothing to hit
        stx     BSIDX
        jsr     PDEC
PVL2:   lda     BSPOS
        jsr     PINC
        bne     PVL9            ; they share a cell
        jsr     PSTEP
        bne     PVL2
        ldx     BSIDX
PVL7:   dex
        bpl     PVL1
        lda     #0              ; Z set: clear
        rts
PVL9:   lda     #1
        rts

; PINC -- Z CLEAR if cell A is one of the candidate's. Across, the candidate
; owns BSCND .. BSCND+len-1 and cannot wrap, because FITS said so; down, it
; owns BSCND plus ten times each segment.
PINC:   sec
        sbc     BSCND
        bcc     PIN8            ; before its first cell
        ldx     BSSHIP
        ldy     SHPSIZ,x        ; the candidate's length, in a cell because
        sty     BSTMP           ;   there is no CPY absolute,X
        ldy     BSDIR
        beq     PIN5
        ldy     #0
PIN1:   cmp     #BRDDIM
        bcc     PIN4
        sbc     #BRDDIM
        iny
        cpy     BSTMP
        bcc     PIN1
        bcs     PIN8            ; past the last segment
PIN4:   cmp     #0              ; under ten: only an exact multiple counts,
        beq     PIN9            ;   and Y < length is already known
        bne     PIN8
PIN5:   cmp     BSTMP
        bcs     PIN8
PIN9:   lda     #1              ; Z clear: covered
        rts
PIN8:   lda     #0
        rts

; ---------------------------------------------------------------------------
; PRND -- sixteen bits of Galois LFSR, poly $B400, the Channel F port's.
PRND:   lsr     BSRNDH
        ror     BSRNDL
        bcc     PRN1
        lda     BSRNDH
        eor     #$B4
        sta     BSRNDH
PRN1:   lda     BSRNDL
        rts

; PRND10 -- 0..9, by rejection on four bits: cheaper than a divide, and the
; six rejected values cost a shift each.
PRND10: jsr     PRND
        and     #$0F
        cmp     #BRDDIM
        bcs     PRND10
        rts

; PROLL -- the cursor and the direction, rolled.
PROLL:  jsr     PRND10
        sta     BSCURX
        jsr     PRND10
        sta     BSCURY
        jsr     PRND
        and     #1
        sta     BSDIR
        rts

; PROLLF -- ONE candidate for ship BSSHIP, this frame. A miss costs nothing
; but the frame; there is no bound and none is needed, because a ten by ten
; board always has room for the five and the expected wait is two candidates
; a ship. When the last lands the fleet is handed over: the cursor onto the
; first ship, the row redrawn, and the hulls painted -- once, not five times,
; because a paint and a candidate together would not fit the same vblank.
PROLLF: jsr     PROLL
        jsr     FITS
        bne     PRFX
        jsr     PCAND
        sta     BSCND
        jsr     POVL
        bne     PRFX
        lda     BSCND
        ldx     BSSHIP
        sta     SHIPS,x
        inx
        cpx     #NSHIPS
        bcs     PRF4
        stx     BSSHIP
PRFX:   rts
PRF4:   lda     #0
        sta     BSSHIP
        jsr     PLOAD
        jsr     PTEXT
        jmp     PHULLS

; PLOAD -- the cursor onto the seeded placement of ship BSSHIP, so the stick
; starts where the roll put it rather than at the origin.
PLOAD:  ldx     BSSHIP
        lda     SHIPS,x
        jsr     PDEC
        lda     BSPDIR
        sta     BSDIR
        lda     BSPOS
        ldx     #$FF
PLD1:   inx
        sec
        sbc     #BRDDIM
        bcs     PLD1
        adc     #BRDDIM         ; C is clear: this adds ten back
        sta     BSCURX
        stx     BSCURY
        rts

; PSLOT0 -- A = your slot: top-right with two players, bottom-left with more.
PSLOT0: lda     #SLTR
        ldx     BSMODE
        beq     PSL1
        lda     #SLBL
PSL1:   rts

; ---------------------------------------------------------------------------
; PTEXT -- the status row and the name over your board.
PTEXT:  lda     #RSTAT
        jsr     FNROWA
        ldx     #(TPLACE)&$FF
        ldy     #(TPLACE)>>8
        jsr     FNSETP
        jsr     FNSTRA
        lda     BSSHIP
        clc
        adc     #'1'
        jsr     FNCHR
        jsr     FNENDW
        lda     #RLABA
        ldx     BSMODE
        beq     PT1
        lda     #RLABB
PT1:    jsr     FNROWA
        lda     BSMODE
        bne     PT2
        lda     #7              ; two players: you are on the right
        jsr     FNSPC
PT2:    ldx     #(TYOU)&$FF
        ldy     #(TYOU)>>8
        jsr     FNSETP
        jsr     FNSTRA
        jmp     FNENDW

; PSTAT -- the status row from the string at X/Y.
PSTAT:  jsr     FNSETP
        lda     #RSTAT
        jsr     FNROWA
        jsr     FNSTRA
        jmp     FNENDW

; PCLEAR -- the rows this screen owns blank, every slot cleared.
PCLEAR: ldx     #0
PCL1:   stx     BSIDX
        lda     PCLROWS,x
        jsr     FNROWA
        jsr     FNENDW
        ldx     BSIDX
        inx
        cpx     #11
        bne     PCL1
        ldx     #PFSLOTS-1
PCL2:   stx     BSIDX
        lda     #PFM_ALL
        ldy     #0
        jsr     FNBARG
        lda     #FB_PFCLR
        jsr     FNBLIT
        ldx     BSIDX
        dex
        bpl     PCL2
        lda     BSMODE
        bne     PCLX
        lda     #RLOW0          ; the two-player layout's hint rows
        jsr     FNROWA
        ldx     #(THINT1)&$FF
        ldy     #(THINT1)>>8
        jsr     FNSETP
        jsr     FNSTRA
        jsr     FNENDW
        lda     #RLOW0+1
        jsr     FNROWA
        ldx     #(THINT2)&$FF
        ldy     #(THINT2)>>8
        jsr     FNSETP
        jsr     FNSTRA
        jsr     FNENDW
PCLX:   rts

PCLROWS: DB     0, 1, 2, 3, 4, 15, 16, 17, 18, 19, 20

; The classic five, longest first, matching the server's myShips[] order.
SHPSIZ: DB      5, 4, 3, 3, 2

TPLACE: DB      "PLACE SHIP ",0
TYOU:   DB      "YOU",0
TOFF:   DB      "WON'T FIT",0
TLAP:   DB      "SHIPS TOUCH",0
TAGAIN: DB      "REFUSED-AGAIN",0
THINT1: DB      "SEL TURNS",0
THINT2: DB      "FIRE PLACES",0

        INCLUDE "bslib.inc"
        INCLUDE "state.inc"
        INCLUDE "sound.inc"
        INCLUDE "dispgame.inc"

        END
