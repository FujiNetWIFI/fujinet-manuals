; bscomp.asm -- bank 6: compose the screen, in one vblank, and hand it on.
;
; This bank is here for SIZE: the game bank holds the board kernel, the
; input and the cues, and with the composer in it too it came in 961 bytes
; over. So a fresh state's recompose -- the cue edges, four playfield boards
; through the cartridge's transforms, the status row, the name rows and the
; two-player layout's lower rows -- runs here, in two passes that each fit
; the blanked time they run in (see CENTRY). Nothing here draws, so there is
; no kernel here.
;
; It is also the cold path's clear, and the failed poll's status line.

        CPU     6502
        INCLUDE "vcs.inc"
        INCLUDE "fujinet.inc"
        INCLUDE "bsdefs.inc"

BSBANK  EQU     BANKCMP
BSHASINP EQU    0               ; it draws nothing and reads no input
BSHASUI EQU     1
BSHASED EQU     0
BSHASNET EQU    0
BSHASCLS EQU    0
BSHASSTR EQU    1
BSHASRPL EQU    1
BSHASDEC EQU    0
SNDFULL EQU     0               ; it fires cues; the game bank ticks them
SNDLAST EQU     11              ; every result cue

        INCLUDE "../build/tail.inc"

; The previous poll's playerCount, for the full clear when a seat count
; changes: the server compacts its list when someone leaves. BSREDRW is the
; flag that forces everything to be composed again.
BSPPCNT EQU     BSBLINK

        ORG     $1000

; A poll's recompose is about 3,900 cycles, and the overscan a bank has
; between two frames is about 2,200. So it is PASSES: the cue edges and the
; gamefields between frames, in the overscan the network bank's last frame
; armed; then the AUX plane -- the hulls and the cursor -- and then the text,
; a frame each, inside the vblank the game bank's hook hands over from
; (ENTEXT). The status row is two frames behind the boards, which nobody can
; see.
;
; The AUX plane used to ride the overscan with the gamefields, and at FOUR
; seats the two did not fit: two more records to walk and two more blits, and
; the poll's frame measured 265 lines instead of 262. It had always done
; that; `make frames` was AI1, which is two seats, and nothing ran the
; quadrant layout past a VSYNC tap until `make frames4`.
;
;   ENGAME    between frames, from a poll:      boards, then ENGNEXT
;   ENTEXT    mid-frame, from the game's hook:  the AUX plane, then the
;             text, a frame each, then ENGRUN
;   ENRESUME  mid-frame, from the menu:         everything's boards, ENGRUN
;   ENGCOLD   between frames, a table joined:   clear, then ENGNEXT
CENTRY: lda     BSENT
        cmp     #ENGCOLD
        beq     CCOLD
        cmp     #ENRESUME
        beq     CRESUM
        cmp     #ENTEXT
        beq     CTEXT
; ENGAME: back from a poll. A failed poll leaves the reply window alone, so
; the boards are still the last good ones; only the status row says.
        lda     BSERR2
        beq     CW1
        jsr     GFAIL
        jmp     CNEXT
CW1:    jsr     GCOMPB
CNEXT:  lda     #ENGNEXT
        sta     BSENT
        lda     #BANKGAM
        jmp     BSGOTO

CTEXT:  jsr     GCOMPT
CRUN:   lda     #ENGRUN
        sta     BSENT
        lda     #BANKGAM
        jmp     BSGOTO

CRESUM: lda     #1
        sta     BSREDRW         ; everything: the menu drew over it all
        jsr     GCOMPB
        lda     #ENGRUND        ; the menu's kernel was a text one
        sta     BSENT
        lda     #BANKGAM
        jmp     BSGOTO

CCOLD:  jsr     GCLEAR
        jmp     CNEXT

; APPVBL -- never called: this bank draws no frame.
APPVBL: rts

; ---------------------------------------------------------------------------
; GCOMPB -- the boards pass: the class, the layout, the cue edges and the
; four slots. Leaves BSREDRW saying what the text pass owes: bit 7 always
; (a pass is due), bit 1 the names, bit 0 everything.
GCOMPB: ldx     #CLLOBBY
        lda     BSSTAT
        beq     GCP1
        ldx     #CLPLACE
        cmp     #STPLACE
        beq     GCP1
        ldx     #CLOVER
        cmp     #STOVER
        beq     GCP1
        ldx     #CLPLAY
GCP1:   stx     BSTMP           ; the class
        lda     #1
        ldy     BSPCNT
        cpy     #3
        bcs     GCP2
        lda     #0
GCP2:   sta     BSTMP2          ; the mode
; A change of class, layout or seat count clears everything: opaque
; overdraw cannot repair content that shrank.
        cmp     BSMODE
        bne     GCPCLR
        ldx     BSTMP
        cpx     BSCLASS
        bne     GCPCLR
        lda     BSPCNT
        cmp     BSPPCNT
        beq     GCP3
GCPCLR: lda     BSTMP2
        sta     BSMODE
        lda     BSTMP
        sta     BSCLASS
        lda     BSPCNT
        sta     BSPPCNT
        lda     #1
        sta     BSREDRW
        jsr     GCLRPF
GCP3:   lda     FNRPLY+GOMVTIM  ; the clock first: the status row shows it
        sta     BSCLK
        lda     #60
        sta     BSTICK
; The names are owed when something on that row can have changed -- the
; seats, the player to move, or the lobby's ready marks. Decided here,
; before GEDGES advances BSPRVAC, for the text pass.
        lda     BSREDRW
        and     #1
        bne     GCP3A
        lda     BSCLASS
        beq     GCP3A
        lda     BSACT
        cmp     BSPRVAC
        beq     GCP3B
GCP3A:  lda     BSREDRW
        ora     #2
        sta     BSREDRW
GCP3B:  jsr     GEDGES
        jsr     GBOARDS
        lda     BSREDRW
        ora     #$A0            ; bit 7 a pass is due, bit 5 the AUX plane
        sta     BSREDRW
        rts

; GCOMPT -- the text pass, a frame later: the rows the boards pass said.
; "Everything" -- a screen change -- is three passes of its own: the rows
; blanked in one frame, the status and the names in the next, the lower
; rows in a third, with bits 2 and 3 carrying the rest. Eleven blank rows
; and ten composed ones in one vblank was an eighteen-line jump once a
; phase.
;
; The AUX plane is tested BEFORE anything else, and its bit cleared without
; disturbing the others: the blank-everything stage below rewrites BSREDRW
; wholesale, so an AUX pass staged behind it would be dropped on exactly the
; screen change that needs it most.
GCOMPT: lda     BSREDRW
        and     #$20
        beq     GCT0
        jsr     GBAUX
        lda     BSREDRW
        and     #$DF
        sta     BSREDRW         ; bit 7 still set: come back next frame
        rts
GCT0:   lda     BSREDRW
        and     #1
        beq     GCT1
        jsr     GCLRTX          ; everything: blank the rows first...
        lda     #$84            ; ...and come back for the rest
        sta     BSREDRW
        rts
GCT1:   lda     BSREDRW
        and     #$10
        bne     GCTFLT          ; the fleet strips, a pass of their own
        lda     BSREDRW
        and     #8
        bne     GCTLOW          ; the third pass: the lower rows
        jsr     GSTAT
        lda     BSREDRW
        and     #4
        bne     GCT1A           ; everything: the whole name rows...
        lda     BSREDRW
        and     #2
        beq     GCT2
        jsr     GLMARKS         ; only the markers moved: two cells a row
        jmp     GCT2
GCT1A:  jsr     GLABELS
        lda     #$8C            ; ...and, next frame, whichever of the two
        ldx     BSMODE          ;   lower halves this layout has
        beq     GCT1B
        lda     #$90
GCT1B:  sta     BSREDRW
        rts
; The last pass of each layout. Two seats compose the lower rows every poll,
; because the fleets live in them; the quadrant layout stages the strips
; instead, a frame later again -- two twelve-character rows on the back of
; the status row and the markers is the eighteen-line jump this file already
; paid for once.
GCT2:   lda     BSMODE
        beq     GCTLOW
        lda     #$90
        sta     BSREDRW
        rts
GCTLOW: jsr     GLOWER
        jmp     GCT3
GCTFLT: jsr     GLFLEET
GCT3:   lda     #0
        sta     BSREDRW
        rts

; ---------------------------------------------------------------------------
; GEDGES -- the cues, on edges only, decided BEFORE the draw.
GEDGES: lda     BSCLASS
        cmp     #CLPLAY
        bne     GE5
; the result: (status, lastAttackPos) as a pair, because the status repeats
; across polls when nobody has fired since
        lda     BSSTAT
        cmp     #STMISS
        bcc     GE4             ; GAMESTART: no result yet
        cmp     BSPRVST
        bne     GE2
        lda     FNRPLY+GILASTP
        cmp     BSPRVLP
        beq     GE4             ; the same event as last poll
GE2:    lda     BSSTAT
        cmp     #STMISS
        bne     GE3
        lda     #SNDMISS
        jmp     GE3A
GE3:    cmp     #STHIT
        bne     GE3B
        lda     #SNDHIT
        jmp     GE3A
GE3B:   lda     #SNDSUNK
GE3A:   jsr     SNDFIRE
GE4:    lda     FNRPLY+GILASTP
        sta     BSPRVLP
; the turn, last, so it is what is heard when both happen at once
        lda     BSACT
        cmp     BSPRVAC
        beq     GE9
        lda     BSACT
        bne     GE9
        lda     #SNDTURN
        jsr     SNDFIRE
        jmp     GE9
GE5:    cmp     #CLOVER
        bne     GE6
        lda     BSPRVST
        cmp     #STOVER
        beq     GE9
        lda     #SNDOVER
        jsr     SNDFIRE
        jmp     GE9
GE6:    cmp     #CLLOBBY
        bne     GE9
; the countdown: the server's prompt starts with "starting in"
        lda     FNRPLY+GOPRMPT
        cmp     #'s'
        bne     GE7
        cmp     BSPRVLP
        beq     GE8             ; already counting: a tick a poll
        lda     #SNDJOIN
        jsr     SNDFIRE
        jmp     GE7
GE8:    lda     #SNDCLK
        jsr     SNDFIRE
GE7:    lda     FNRPLY+GOPRMPT
        sta     BSPRVLP
GE9:    lda     BSACT
        sta     BSPRVAC
        lda     BSSTAT
        sta     BSPRVST
        rts

; ---------------------------------------------------------------------------
; GBOARDS -- the HIT and MID planes of the four slots, from the records.
;
; The AUX plane is GBAUX and a pass of its own. The two together are about
; 2,100 cycles at four seats and the overscan a bank has between frames is
; about 2,240 -- of which the network bank has already spent four lines by
; the time it hands over, so the poll's frame came out three lines long, once
; a poll, for as long as the quadrant layout has existed. Two seats fitted
; and `make frames` was only ever run at two seats.
GBOARDS: lda    BSCLASS
        cmp     #CLPLAY
        bcs     GB0
        rts                     ; lobby and placement: no gamefields exist
GB0:    ldx     #0
GB1:    cpx     BSPCNT
        bcs     GB1X
        stx     BSIDX
        jsr     PLRECP          ; FNPTRL/H = the record, in the window
        lda     FNPTRL          ; src = its offset + PLFIELD, sixteen bits
        clc
        adc     #PLFIELD
        sta     FNRSEL+FH_BSL
        lda     FNPTRH
        adc     #0
        sec
        sbc     #(FNRPLY)>>8
        sta     FNRSEL+FH_BSH
        ldx     BSIDX
        jsr     PSLOT
        sta     FNRSEL+FH_BDL
        lda     #0
        sta     FNRSEL+FH_BDH
        lda     #FB_PFLD
        jsr     FNBLIT
        ldx     BSIDX
        inx
        jmp     GB1
GB1X:   rts

; GBAUX -- the AUX plane, in the vblank of the frame after: cleared
; everywhere, then your hulls, the winner's at game over, and the cursor on
; every live enemy. One frame behind the boards, which nobody can see, in
; exchange for a frame that is 262 lines.
GBAUX:  lda     BSCLASS
        cmp     #CLPLAY
        bcs     GB2
        rts
GB2:    ldx     #PFSLOTS-1
GB3:    stx     BSIDX
        lda     #PFM_AUX
        ldy     #0
        jsr     FNBARG
        lda     #FB_PFCLR
        jsr     FNBLIT
        ldx     BSIDX
        dex
        bpl     GB3
        ldx     #0
        jsr     PSLOT
        tax
        lda     #GIMYSHP
        ldy     #NSHIPS
        jsr     FNBARG
        lda     #FB_PFHUL
        jsr     FNBLIT
        lda     BSCLASS
        cmp     #CLOVER
        bne     GB4
        ldx     BSACT           ; the winner, whose layout came with v=2
        beq     GB4             ; you: yours are up already
        cpx     BSPCNT
        bcs     GB4
        jsr     PSLOT
        tax
        lda     #GIMYSHP+NSHIPS
        ldy     #NSHIPS
        jsr     FNBARG
        lda     #FB_PFHUL
        jsr     FNBLIT
GB4:    lda     #0
        sta     BSLIVE
        lda     BSCLASS
        cmp     #CLPLAY
        bne     GB9
        lda     BSMYST
        bne     GB9             ; defeated or watching: no cursor
        ldx     #1
GB5:    cpx     BSPCNT
        bcs     GB6
        stx     BSIDX
        jsr     PLRECP
        ldy     #PLSTAT
        lda     (FNPTRL),y
        bne     GB5A            ; not playing: a shot does not reach them
        ldx     BSIDX
        jsr     PSLOT
        tax
        lda     SLOTBIT,x
        ora     BSLIVE
        sta     BSLIVE
GB5A:   ldx     BSIDX
        inx
        jmp     GB5
GB6:    lda     #PFM_AUX
        jmp     GCURS
GB9:    rts

; PSLOT -- A = the slot of player X, in the current layout. X survives.
; Two players: you top-right, the enemy top-left. More: the family's
; quadrants, you bottom-left and the others clockwise from top-left.
PSLOT:  txa
        pha
        ldy     BSMODE
        beq     PSL1
        clc
        adc     #4
PSL1:   tax
        lda     SLOTMAP,x
        tay
        pla
        tax
        tya
        rts

; ---------------------------------------------------------------------------
; GSTAT -- the status row, synthesised: the server's prompt is empty for the
; whole of play, deliberately ("updating the prompt based on the attack
; result was getting too busy"), so the client says what it knows. Where the
; server has something to say -- the lobby, game over -- its words win.
GSTAT:  lda     #RSTAT
        jsr     FNROWA
        lda     BSCLASS
        beq     GSLOB
        cmp     #CLPLACE
        beq     GSPLC
        cmp     #CLOVER
        beq     GSOVR
; play: the last result, whose turn, and your clock
        ldx     #(TNONE)&$FF
        ldy     #(TNONE)>>8
        lda     BSSTAT
        cmp     #STMISS
        bne     GS1
        ldx     #(TMISS)&$FF
        ldy     #(TMISS)>>8
GS1:    cmp     #STHIT
        bne     GS2
        ldx     #(THIT)&$FF
        ldy     #(THIT)>>8
GS2:    cmp     #STSUNK
        bne     GS3
        ldx     #(TSUNK)&$FF
        ldy     #(TSUNK)>>8
GS3:    jsr     FNSETP
        jsr     FNSTRA
        lda     BSACT
        bne     GSFOE
        ldx     #(TYOU)&$FF
        ldy     #(TYOU)>>8
        jsr     FNSETP
        jsr     FNSTRA
        lda     BSCLK
        jsr     DEC3
        jmp     FNENDW
GSFOE:  ldx     #(TFOE)&$FF
        ldy     #(TFOE)>>8
GSSTR:  jsr     FNSETP
        jsr     FNSTRA
        jmp     FNENDW
GSPLC:  ldx     #(TWAITS)&$FF   ; the others are placing; yours are down
        ldy     #(TWAITS)>>8
        jmp     GSSTR
GSLOB:  lda     FNRPLY+GOPRMPT
        beq     GSLOB1
        ldx     #GOPRMPT        ; "starting in N"
        ldy     #FNTCOL
        jsr     FNRPLA
        jmp     FNENDW
GSLOB1: ldx     #(TREADY)&$FF
        ldy     #(TREADY)>>8
        lda     BSMYST
        cmp     #PSREADY
        bne     GSSTR
        ldx     #(TWAITP)&$FF
        ldy     #(TWAITP)>>8
        jmp     GSSTR
GSOVR:  ldx     BSACT
        bne     GSOVR1
        ldx     #(TWIN)&$FF
        ldy     #(TWIN)>>8
        jmp     GSSTR
GSOVR1: cpx     BSPCNT
        bcs     GSOVR2
        jsr     PLRECP
        ldx     #5
        jsr     FNRPLP
        ldx     #(TWINS)&$FF
        ldy     #(TWINS)>>8
        jmp     GSSTR
GSOVR2: ldx     #(TOVER)&$FF
        ldy     #(TOVER)>>8
        jmp     GSSTR

; ---------------------------------------------------------------------------
; GLABELS -- the name row over each pair: the left board's owner in the
; first five columns, a marker each, the right board's owner in the last
; five. The 48-pixel text block sits at clocks 52-99, so column 7 starts
; exactly at the seam.
GLABELS: lda    #RLABA
        jsr     FNROWA
        ldx     #SLTL
        jsr     GLNAME
        ldx     #SLTL
        jsr     GLMARK
        ldx     #SLTR
        jsr     GLMARK
        ldx     #SLTR
        jsr     GLNAME
        jsr     FNENDW
        lda     BSMODE
        beq     GLX
        lda     #RLABB
        jsr     FNROWA
        ldx     #SLBL
        jsr     GLNAME
        ldx     #SLBL
        jsr     GLMARK
        ldx     #SLBR
        jsr     GLMARK
        ldx     #SLBR
        jsr     GLNAME
        jmp     FNENDW
GLX:    rts

; GLNAME -- five columns: the name of the player in slot X, YOU for you,
; blank for an empty slot.
GLNAME: jsr     SLPLYR
        bmi     GLN2
        beq     GLN1
        tax
        jsr     PLRECP
        ldx     #5
        jmp     FNRPLP
GLN1:   ldx     #(TYOU5)&$FF
        ldy     #(TYOU5)>>8
        jsr     FNSETP
        jmp     FNSTRA
GLN2:   lda     #5
        jmp     FNSPC

; GLMARK -- one column, appended: '*' ready in the lobby, '>' the player
; to move, 'X' sunk, else a space. GLMARKC is the choice alone, in A.
GLMARK: jsr     GLMARKC
        jmp     FNCHR
GLMARKC: jsr    SLPLYR
        bmi     GLMSP
        sta     BSTMP
        tax
        jsr     PLRECP
        ldy     #PLSTAT         ; LBSTAT and PLSTAT are both offset 9
        lda     (FNPTRL),y
        ldx     BSCLASS
        bne     GLM1
        cmp     #PSREADY        ; the lobby: ready or not
        bne     GLMSP
        lda     #'*'
        rts
GLM1:   cmp     #PSDEFT
        bne     GLM2
        lda     #'X'
        rts
GLM2:   lda     BSTMP
        cmp     BSACT
        bne     GLMSP
        lda     #'>'
        rts
GLMSP:  lda     #' '
        rts

; GLMARKS -- the four marker cells, in place through FB_TCELL: what a poll
; that only moved the turn changes on the name rows, at a tenth of the cost
; of composing them again.
GLMARKS: ldx    #SLTL
        jsr     GLMARKC
        ldx     #RLABA*FNTCOL+5
        jsr     GLMCEL
        ldx     #SLTR
        jsr     GLMARKC
        ldx     #RLABA*FNTCOL+6
        jsr     GLMCEL
        lda     BSMODE
        beq     GLMX
        ldx     #SLBL
        jsr     GLMARKC
        ldx     #RLABB*FNTCOL+5
        jsr     GLMCEL
        ldx     #SLBR
        jsr     GLMARKC
        ldx     #RLABB*FNTCOL+6
        jsr     GLMCEL
GLMX:   rts
GLMCEL: ldy     #0
        jsr     FNBARG
        lda     #FB_TCELL
        jmp     FNBLIT

; ---------------------------------------------------------------------------
; GLFLEET -- text rows 3 and 4: the fleet of each of the four seats as five
; pips, under the name row of its pair. The kernel draws these three ink
; lines high (dispgame.inc, PIPROW), which is why the sunk mark is '=' and
; not '.'.
;
; GPIPS already emits a leading space and five pips -- six columns -- so two
; of them fill the row exactly and the right-hand seat's pips land in columns
; 7-11. Column 7 starts at clock 80, the board seam, so each seat's pips sit
; over its own half.
GLFLEET: lda    #RFLTA
        jsr     FNROWA
        ldx     #SLTL
        jsr     GFSLOT
        ldx     #SLTR
        jsr     GFSLOT
        jsr     FNENDW
        lda     #RFLTB
        jsr     FNROWA
        ldx     #SLBL
        jsr     GFSLOT
        ldx     #SLBR
        jsr     GFSLOT
        jmp     FNENDW

; GFSLOT -- six columns for the seat in slot X: a space and five pips, or six
; spaces for an empty seat. GPIPS emits nothing at all before the gamefields
; exist, which is what the lobby and the placement phase want.
GFSLOT: jsr     SLPLYR
        bmi     GFSP
        tax
        jmp     GPIPS
GFSP:   lda     #NSHIPS+1
        jmp     FNSPC

; SLPLYR -- A = the player in slot X, or $FF (N set) for nobody.
SLPLYR: txa
        ldy     BSMODE
        beq     SLP1
        clc
        adc     #4
SLP1:   tax
        lda     PLOFSL,x
        bmi     SLP2
        cmp     BSPCNT
        bcc     SLP2
        lda     #$FF
SLP2:   cmp     #0              ; N and Z from the VALUE, not from the
        rts                     ;   bounds compare -- 1 - 2 is negative too

; ---------------------------------------------------------------------------
; GLOWER -- the two-player layout's lower rows: the server's prompt in full,
; each player's ships as pips, and a hint.
GLOWER: lda     BSREDRW
        and     #4
        bne     GLW0
        lda     BSCLASS
        cmp     #CLPLAY         ; in play the prompt is empty and the hint
        beq     GLPIPS          ;   is fixed: only the fleets can change
GLW0:   ldx     #0
GLW1:   stx     BSIDX
        txa
        clc
        adc     #RLOW0
        jsr     FNROWA
        lda     BSIDX
        asl     a
        asl     a
        adc     BSIDX
        asl     a               ; twelve bytes a row
        adc     BSIDX
        adc     BSIDX
        clc
        adc     #GOPRMPT
        tax
        ldy     #FNTCOL
        cpx     #GOPRMPT+2*FNTCOL
        bne     GLW2
        ldy     #33-2*FNTCOL    ; the third row holds the last nine
GLW2:   jsr     FNRPLA
        cpy     #0
        beq     GLW3
        tya
        jsr     FNSPC
GLW3:   jsr     FNENDW
        ldx     BSIDX
        inx
        cpx     #3
        bne     GLW1
        jsr     GLPIPS
; the hint
        lda     #RLOW0+5
        jsr     FNROWA
        ldx     #(THINTP)&$FF
        ldy     #(THINTP)>>8
        lda     BSCLASS
        cmp     #CLPLAY
        beq     GLW5
        ldx     #(THINTL)&$FF
        ldy     #(THINTL)>>8
        cmp     #CLLOBBY
        beq     GLW5
        ldx     #(THINTO)&$FF
        ldy     #(THINTO)>>8
GLW5:   jsr     FNSETP
        jsr     FNSTRA
        jmp     FNENDW

; GLPIPS -- the two fleet rows: YOU and the enemy, each with five pips.
GLPIPS: lda     #RLOW0+3
        jsr     FNROWA
        ldx     #(TYOU5)&$FF
        ldy     #(TYOU5)>>8
        jsr     FNSETP
        jsr     FNSTRA
        ldx     #0
        jsr     GPIPS
        jsr     FNENDW
        lda     #RLOW0+4
        jsr     FNROWA
        ldx     #1
        cpx     BSPCNT
        bcs     GLW4
        jsr     PLRECP
        ldx     #5
        jsr     FNRPLP
        ldx     #1
        jsr     GPIPS
GLW4:   jmp     FNENDW

; GPIPS -- " #####" for player X's five ships, '.' where one is sunk. Only
; once the records carry a fleet.
GPIPS:  lda     BSCLASS
        cmp     #CLPLAY
        bcc     GPX
        jsr     PLRECP
        lda     #' '
        jsr     FNCHR
        ldy     #PLSHIPS
GP1:    lda     (FNPTRL),y
        beq     GP2
        lda     #'#'
        jmp     GP3
GP2:    lda     #'='             ; a bar; '.' is the bottom font row alone
                                ;   and the strips only render the top three
GP3:    jsr     FNCHR
        iny
        cpy     #PLSHIPS+NSHIPS
        bne     GP1
GPX:    rts

; ---------------------------------------------------------------------------
; GCLEAR -- every row this bank owns blank, every slot cleared. Rows 5-14
; are the playfield tables and are never touched. GCLRTX is the rows,
; GCLRPF the slots: the two passes split them.
GCLEAR: jsr     GCLRTX
GCLRPF: ldx     #PFSLOTS-1
GCL2:   stx     BSIDX
        lda     #PFM_ALL
        ldy     #0
        jsr     FNBARG
        lda     #FB_PFCLR
        jsr     FNBLIT
        ldx     BSIDX
        dex
        bpl     GCL2
        rts
GCLRTX: ldx     #0
GCL1:   stx     BSIDX
        lda     GCLROWS,x
        jsr     FNROWA
        jsr     FNENDW
        ldx     BSIDX
        inx
        cpx     #11
        bne     GCL1
        rts

; GFAIL -- the status row says the poll failed and where.
GFAIL:  lda     #RSTAT
        jsr     FNROWA
        ldx     #(TNETER)&$FF
        ldy     #(TNETER)>>8
        jsr     FNSETP
        jsr     FNSTRA
        lda     BSSTEP
        clc
        adc     #'0'
        jsr     FNCHR
        lda     #' '
        jsr     FNCHR
        lda     BSERR
        jsr     DEC3
        jmp     FNENDW

; DEC3 -- A as three characters, leading zeros as spaces, the units digit
; always. BSTMP2 is the "something has printed" latch.
DEC3:   ldy     #0
        sty     BSTMP2
        ldx     #0
DC1:    cmp     #100
        bcc     DC2
        sbc     #100
        inx
        bne     DC1
DC2:    jsr     DCDIG
        ldx     #0
DC3:    cmp     #10
        bcc     DC4
        sbc     #10
        inx
        bne     DC3
DC4:    jsr     DCDIG
        clc
        adc     #'0'
        jmp     FNCHR
DCDIG:  pha
        txa
        bne     DCD1
        lda     BSTMP2
        beq     DCD2            ; a leading zero: a space
        lda     #'0'
        bne     DCD3
DCD1:   clc
        adc     #'0'
        inc     BSTMP2
        bne     DCD3
DCD2:   lda     #' '
DCD3:   jsr     FNCHR
        pla
        rts

; ---------------------------------------------------------------------------
GCLROWS: DB     0, 1, 2, 3, 4, 15, 16, 17, 18, 19, 20
; player -> slot, by layout: two players, then quadrants
SLOTMAP: DB     SLTR, SLTL, SLBL, SLBR
        DB      SLBL, SLTL, SLTR, SLBR
; slot -> player, by layout
PLOFSL: DB      1, 0, $FF, $FF
        DB      1, 2, 0, 3

TNONE:  DB      "     ",0
TMISS:  DB      "MISS ",0
THIT:   DB      "HIT  ",0
TSUNK:  DB      "SUNK ",0
TYOU:   DB      "YOU ",0
TFOE:   DB      "ENEMY  ",0
TWAITS: DB      "WAIT: SHIPS",0
TREADY: DB      "FIRE=READY",0
TWAITP: DB      "READY. WAIT",0
TWIN:   DB      "YOU WIN!",0
TWINS:  DB      " WINS",0
TOVER:  DB      "GAME OVER",0
TYOU5:  DB      "YOU  ",0
TNETER: DB      "NET ERR ",0
THINTP: DB      "FIRE=ATTACK",0
THINTL: DB      "FIRE=READY",0
THINTO: DB      "RESET=MENU",0

        INCLUDE "bslib.inc"
        INCLUDE "state.inc"
        INCLUDE "sound.inc"

        END
