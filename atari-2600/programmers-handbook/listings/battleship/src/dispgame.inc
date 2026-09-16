; dispgame.inc -- the four-quadrant board display.
;
; Up to four 10x10 boards as COLOURED CELLS, drawn with the TIA playfield
; rewritten twice a scanline out of tables the cartridge composes (see
; fujinet.inc, the playfield board). A cell is two playfield bits -- eight
; pixels -- by eight scanlines (twelve in the two-player layout, which makes
; it square), and the colour a cell shows is decided BY LINE: the playfield
; has one colour per scanline, so each line of the cell draws a different
; table in a different colour, and a hit, a miss and a hull come out red,
; white and yellow on one board with no flicker at all.
;
;   line 0    AUX  yellow   your hulls; the cursor on the enemy boards
;   line 1-2  HIT  red      a hit: the top of the red block
;   line 3-4  MID  white    hit OR miss: a hit's white core, a miss's dash
;   line 5-6  HIT  red      the bottom of the block
;   line 7    AUX  yellow
;
; Two boards side by side are the whole 160 pixels, abutting at 79|80, with a
; two-clock black missile down the seam. Text rows -- the status line and a
; name row over each pair -- use the 48-pixel player kernel from
; disptext.inc, whose 53-cycle body is TRANSCRIBED FROM THE FIRMWARE'S
; fujidisp.inc AND MUST NOT BE RETIMED: its constants are the coordinates of a
; one-pixel-wide window. The players are positioned once, in DINIT, and never
; move; there is no HMOVE anywhere in the frame.
;
; THE FRAME IS ALWAYS 262 LINES. The blanked bands are timed with the RIOT
; timer, as in disptext.inc, and so is the VISIBLE band: the kernel's own
; lines add up to less than 192 and a timed pad at the bottom absorbs the
; difference -- and any overrun -- rather than moving the whole picture down
; the screen, which is what this family has paid for twice already.
;
; Visible, three or four players (192). Counted as WSYNCs, which is what the
; raster sees; tools/pfcheck.py holds the same arithmetic and must move with
; it.
;    1  the unblank line
;    6  status row                (text row 0: 5 ink + a seam)
;    6  names over pair A         (text row 1)
;    3  fleet strip               (text row 3: '#' afloat, '=' sunk)
;    1  the strip's seam, WHICH IS ALSO the lead-in: sprites blanked,
;       water on, the divider on
;   80  board pair A, rows 0-9
;    1  lead-out: playfield off, the divider off
;    2  gap
;    6  names over pair B         (text row 2)
;    3  fleet strip               (text row 4)
;    1  seam and lead-in
;   80  board pair B, rows 10-19
;    1  lead-out
;    1  timed pad
; That is 191 lines of kernel in a band of 192, and the pad is the last one.
; The count is fixed -- nothing in the visible band branches on data -- so
; exact is safe where variable would not be, and `make frames` is what says
; so. The gap was seven lines and the pad four before the strips; six of
; those nine are what the two strips are made of.
;
; Two players: one pair of 12-line cells (120), then text rows 15-20, and no
; strips -- the lower rows have carried the fleets as pips all along.

; ---------------- kernel timing constants ----------------
; Not taste. See disptext.inc.
RNOP    EQU     16              ; NOPs before RESP0 (2 cycles each)...
R3      EQU     1               ; ...plus this, so RESP0 lands on cycle 38
HM0     EQU     15              ; HMP0 = $F0: move P0 right one pixel...
HM1     EQU     0               ; ...and leave P1, closing the gap to eight
VDEL    EQU     1               ; vertical delay on both players

; The divider: RESM1 completing at cycle 48 puts a missile at clock 80 (a
; player lands at three times the completion cycle less 63, a missile one
; clock earlier -- both measured), and one clock of HMM1 pulls it to 79-80
; with the two-clock width NUSIZ1 gives it. Confirmed against the raster by
; tools/pfcheck.py.
MNOP    EQU     21              ; NOPs before RESM1...
M3      EQU     1               ; ...plus a 3-cycle store: 45, so it lands at 48
MHM1    EQU     $10             ; then one clock left

; ---------------- text plane bases ----------------
TP0     EQU     FNTEXT+$000
TP1     EQU     FNTEXT+$080
TP2     EQU     FNTEXT+$100
TP3     EQU     FNTEXT+$180
TP4     EQU     FNTEXT+$200
TP5     EQU     FNTEXT+$280

TINK    EQU     FNTCLH-1        ; 5 ink lines per text row

; ---------------- the playfield tables ----------------
; Plane r holds register r's tables: HIT at PFROW0, MID and AUX after it.
; Every one of these fits in one page for y in 0..19 (the highest is $1AD9),
; so `lda table,y` is always four cycles. host_test asserts it.
THIT0   EQU     FNTEXT+$000+PFROW0
THIT1   EQU     FNTEXT+$080+PFROW0
THIT2   EQU     FNTEXT+$100+PFROW0
THIT3   EQU     FNTEXT+$180+PFROW0
THIT4   EQU     FNTEXT+$200+PFROW0
THIT5   EQU     FNTEXT+$280+PFROW0
TMID0   EQU     THIT0+PFKLEN
TMID1   EQU     THIT1+PFKLEN
TMID2   EQU     THIT2+PFKLEN
TMID3   EQU     THIT3+PFKLEN
TMID4   EQU     THIT4+PFKLEN
TMID5   EQU     THIT5+PFKLEN
TAUX0   EQU     THIT0+2*PFKLEN
TAUX1   EQU     THIT1+2*PFKLEN
TAUX2   EQU     THIT2+2*PFKLEN
TAUX3   EQU     THIT3+2*PFKLEN
TAUX4   EQU     THIT4+2*PFKLEN
TAUX5   EQU     THIT5+2*PFKLEN

; NTSC: 3 vsync + 37 vblank + 192 visible + 30 overscan = 262. The counts
; are in 64-cycle units and one less than the arithmetic suggests, because
; the timer has to expire INSIDE the last line rather than on its boundary;
; VBTIM and OSTIM are disptext.inc's, confirmed by histogram.
VBTIM   EQU     43              ; ~37 scanlines of vblank
OSTIM   EQU     35              ; ~30 scanlines of overscan
VITIM   EQU     227             ; ~192 scanlines of picture

; ---------------- DINIT: TIA setup and positioning ----------------
DINIT:
; Every TIA register the kernel relies on, written -- RESMP1 above all, whose
; power-on state on real silicon is undefined and which, set, locks the
; missile to its player and never draws it. The cold start clears $00-$2C
; too; this is for a bank entered warm.
        lda     #0
        sta     CTRLPF          ; no reflect, no priority, no score mode
        sta     PF0
        sta     PF1
        sta     PF2
        sta     ENAM0
        sta     ENAM1
        sta     ENABL
        sta     RESMP0
        sta     RESMP1
        sta     REFP0
        sta     REFP1
        sta     HMM0
        sta     HMM1
        sta     HMBL
        sta     HMP0
        sta     HMP1
        sta     VDELBL
        sta     COLUBK
        sta     GRP0
        sta     GRP1
        sta     GRP0
        sta     BSFRAME
        lda     #$03            ; P0: three copies, close
        sta     NUSIZ0
        lda     #$13            ; P1: three copies, close, and a 2-clock
        sta     NUSIZ1          ;   missile -- the two fields are independent
        lda     #VDEL
        sta     VDELP0
        sta     VDELP1
        lda     #CWHITE
        sta     COLUP0
        sta     COLUP1

; The divider first, while HMP0/HMP1 are still zero so its HMOVE moves
; nothing else. The nudge is cleared straight after, so the players' HMOVE
; below leaves it where it is, and there are no HMOVEs after that.
        sta     WSYNC
        REPT    MNOP
        nop
        ENDM
        IF      M3
        sta     PAD3
        ENDIF
        sta     RESM1
        lda     #MHM1
        sta     HMM1
        sta     WSYNC
        sta     HMOVE
        sta     WSYNC           ; the motion takes most of a line to apply;
        lda     #0              ;   clearing the nudge inside it cuts it short
        sta     HMM1

; The players, transcribed from batari Basic's std_kernel.asm by way of the
; firmware's fujidisp.inc: RESP0 at 38, RESP1 three cycles later, HMP0 pulls
; P0 right one pixel, and an EARLY HMOVE on the next line applies it.
        sta     WSYNC
        REPT    RNOP
        nop
        ENDM
        IF      R3
        sta     PAD3
        ENDIF
        sta     RESP0
        sta     RESP1
        lda     #HM0*16
        sta     HMP0
        lda     #(HM1*16)&$FF
        sta     HMP1
        sta     WSYNC
        sta     HMOVE
        rts

; ---------------- DLOOP: draw frames, forever ----------------
; DFRESH is the entry for a FRESH start -- a bank that is not finishing or
; following a frame -- and arms the overscan timer DFRAME waits on, because
; a stale count could be seconds. A bank entered between frames must NOT
; arm it: the previous frame's DFRAME2 already did, and arming it again in
; DINIT cost thirty lines on every re-entry after a poll.
DFRESH: lda     #OSTIM
        sta     TIM64T
DLOOP:  jsr     DFRAME
        jmp     DLOOP

; ---------------- DFRAME: draw ONE frame, then return ----------------
; Split out of DLOOP so a bank that is not running the display loop can still
; keep the picture alive: net.inc waits for the cartridge a frame at a time
; through here, which is what stops a poll from blanking the screen.
; THE OVERSCAN IS WAITED OUT HERE, at the start of the next frame, and not
; at the end of the one before. DFRAME2 arms the timer and returns at once,
; so whatever a bank does between two frames -- build a URL into the TX
; page, recompose the boards, switch banks -- is spent INSIDE the overscan
; and moves nothing, as long as it fits in thirty lines. Waiting at the end
; instead put every one of those between the overscan and the next VSYNC,
; and a played game measured 96 frames in 2,400 that were 273 to 310 lines.
DFRAME: bit     TIMINT
        bpl     DFRAME
        sta     WSYNC
        lda     #2
        sta     VSYNC
        sta     WSYNC
        sta     WSYNC
        sta     WSYNC
        lda     #0
        sta     VSYNC

        lda     #2
        sta     VBLANK
        lda     #VBTIM
        sta     TIM64T
; The per-frame hook, INSIDE the timed band: input, sound, and the whole of a
; recompose. It has 2812 cycles less what surrounds it, and what it does costs
; the frame nothing as long as it fits.
        inc     BSFRAME
        jsr     APPVBL

; ---------------- DFRAME2: finish the frame the hook was called in ----------
; A bank switch is taken from INSIDE the hook, and the bank entered carries on
; from here: the vblank timer is the RIOT's and does not care which bank is
; mapped, so the frame the switch interrupted is completed at exactly 262
; lines by whoever holds the kernel now. The alternative -- switching between
; frames -- puts the next VSYNC tens of cycles late, once a poll, and a
; switch that starts a fresh frame from the hook throws a 40-line frame at
; the set.
DFRAME2:
; The status row's colours, set here where the raster is nowhere near
; anything, in case the hook -- or the bank before it -- left them elsewhere.
        lda     #0
        sta     COLUBK
        sta     PF0
        sta     PF1
        sta     PF2
        sta     ENAM1
        lda     #CSTATUS
        sta     COLUP0
        sta     COLUP1

; Wait out the band -- TIMINT, not INTIM: the latch stays set, so an overrun
; costs exactly the overrun -- and land the unblank on a line boundary.
DVBLP:  bit     TIMINT
        bpl     DVBLP
        sta     WSYNC
        lda     #0
        sta     VBLANK
        lda     #VITIM          ; the picture's own clock
        sta     TIM64T

; ---- the status row ----
; Every text row is six lines: five of ink and a seam line that blanks the
; sprites, which otherwise go on showing their last two bytes down the
; screen. TINK5 returns early in its seam line, so a colour change here lands
; on a line nothing is drawn on.
        ldy     #RSTAT*FNTCLH
        jsr     TINK5
        lda     #CLABEL
        sta     COLUP0
        sta     COLUP1

; ---- pair A: names, the fleet strip, then the boards ----
        ldy     #RLABA*FNTCLH
        jsr     TINK5
        lda     #CAUX           ; the strip is gold, like the hull brackets.
        sta     COLUP0          ;   The name row's seam line has the cycles
        sta     COLUP1          ;   for this and nothing is drawn on it.
        lda     BSMODE
        beq     DFA2
        ldy     #RFLTA*FNTCLH
        jsr     PIPROW          ; three ink lines AND the lead-in
        jmp     DFA3
DFA2:   jsr     LEADIN          ; two seats: the lower rows carry the fleets
DFA3:   ldy     #0
        lda     #10
        sta     ROWEND
        lda     BSMODE
        beq     DF2P
        jsr     BOARD8
        jsr     LEADOUT

; ---- pair B ----
        sta     WSYNC           ; the first gap line takes the background back
        lda     #0
        sta     COLUBK
        lda     #CLABEL
        sta     COLUP0
        sta     COLUP1
        ldx     #1             ; the gap, shortened to pay for the strips
DFGAP:  sta     WSYNC
        dex
        bne     DFGAP
        ldy     #RLABB*FNTCLH
        jsr     TINK5
        lda     #CAUX
        sta     COLUP0
        sta     COLUP1
        ldy     #RFLTB*FNTCLH
        jsr     PIPROW
        ldy     #10
        lda     #20
        sta     ROWEND
        jsr     BOARD8
        jsr     LEADOUT
        jmp     DFPAD

; ---- two players: one pair of square cells, then the lower text ----
DF2P:   jsr     BOARD12
        jsr     LEADOUT
        sta     WSYNC
        lda     #0
        sta     COLUBK
        lda     #CWHITE
        sta     COLUP0
        sta     COLUP1
        ldx     #3
DF2GAP: sta     WSYNC
        dex
        bne     DF2GAP
        ldy     #RLOW0*FNTCLH
        ldx     #NLOWROW
DF2ROW: stx     BSTMP2
        jsr     TINK5
        ldx     BSTMP2
        dex
        bne     DF2ROW

; ---- the pad: whatever is left of 192, timed ----
DFPAD:  sta     WSYNC           ; the lead-out's water stays whole
        lda     #0
        sta     COLUBK
DFPAD1: bit     TIMINT
        bpl     DFPAD1
        sta     WSYNC

        lda     #2
        sta     VBLANK
        lda     #OSTIM          ; the next DFRAME waits this out; see above
        sta     TIM64T
; Returns with VBLANK SET and the overscan timer running: a bank may do up to
; about 2,200 cycles of work before the next DFRAME for free.
        rts

; ---------------------------------------------------------------------------
; TINK5 -- the text row whose first plane byte is Y: five ink lines and a
; SEAM LINE. Leaves Y at the next row's first byte and returns early in the
; seam line, so the caller has that line for colour changes.
;
; The body is disptext.inc's, with the stack pointer parked as a register
; and restored before the return, and the `iny / cpy / bne` loop is what
; keeps an ink line inside 76 cycles. The seam line is not optional: the
; copies go on displaying the last two bytes written until something blanks
; them, and the exit path is too long to do it on the last ink line -- a
; `jsr` after this routine's `rts` lands at cycle 79, which is a line lost
; without anything looking wrong.
;
; TINKN is the same row with A ink lines instead of five, and it hands the
; seam line to its caller WITHOUT blanking: PIPROW needs the water up before
; pixel 0, which is earlier than the blanking has to be, and only the caller
; knows that. TINK5 is TINKN plus the blanking, which is what every other row
; wants. The extra jsr/rts costs twelve cycles of a line that has fifty-seven
; spare.
TINK5:  lda     #TINK
        jsr     TINKN
        lda     #0
        sta     GRP0
        sta     GRP1
        sta     GRP0
        iny                     ; past the blank sixth byte
        rts

TINKN:  tsx
        stx     SAVSP
        sta     BSLINE          ; the ink count, until Y is added to it
        tya
        clc
        adc     BSLINE
        sta     BSLINE          ; the first byte past the ink
TI1:    sta     WSYNC
        lda     TP0,y           ; 4
        sta     GRP0            ; 3   ->  7   new GRP0 = group 0
        lda     TP1,y           ; 4   -> 11
        sta     GRP1            ; 3   -> 14   displays group 0
        lda     TP2,y           ; 4   -> 18
        sta     GRP0            ; 3   -> 21   displays group 1
        lda     TP4,y           ; 4   -> 25
        tax                     ; 2   -> 27
        txs                     ; 2   -> 29   park group 4 in S
        lda     TP3,y           ; 4   -> 33
        tax                     ; 2   -> 35
        lda     TP5,y           ; 4   -> 39
        stx     GRP1            ; 3   -> 42   displays group 2
        tsx                     ; 2   -> 44   recover group 4
        stx     GRP0            ; 3   -> 47   displays group 3
        sta     GRP1            ; 3   -> 50   displays group 4
        sty     GRP0            ; 3   -> 53   displays group 5; value unused
        iny                     ; 2   -> 55
        cpy     BSLINE          ; 3   -> 58
        bne     TI1             ; 3   -> 61
        ldx     SAVSP           ; 3   -> 64
        txs                     ; 2   -> 66
        sta     WSYNC           ; 3   -> 69
        rts                     ; the caller owns the seam line, from cycle 6

; ---------------------------------------------------------------------------
; PIPROW -- the fleet strip whose first plane byte is Y: three ink lines, and
; a seam line that is ALSO the board's lead-in. Replaces LEADIN in the
; quadrant layout, so the strip costs three scanlines and not four.
;
; Three ink lines, because that is what the gap and the pad between them can
; pay for. The font is a 3x5 glyph, so this is its top three rows: '#' is
; {5,7,5} and '=' is {0,7,0} -- a hash and a bar, which is the whole
; vocabulary the strip needs. Digits would NOT survive the clip; '8' and '9'
; are both {7,5,7}.
;
; The order of this line is not taste. COLUBK must be written before pixel 0
; at cycle 22.67; the sprites only have to be blanked before the text block
; at clock 52, which is cycle 39. Doing the blanking first -- as LEADIN does,
; where it is free -- puts the water in four clocks late and leaves a black
; sliver down the left of the line.
PIPROW: lda     #3
        jsr     TINKN
        lda     #CWATER         ; 2
        sta     COLUBK          ; 5    before pixel 0 at 22
        lda     #0              ; 7
        sta     GRP0            ; 10   before the text block at 39
        sta     GRP1            ; 13
        sta     GRP0            ; 16
        sta     COLUP1          ; 19   the divider's colour
        lda     #$10            ; 21   one copy, two clocks wide
        sta     NUSIZ1          ; 24
        lda     #2              ; 26
        sta     ENAM1           ; 29   before the divider at 49
        rts

; ---------------------------------------------------------------------------
; LEADIN -- the line before a board: the water on, the divider black, ONE
; copy and on. NUSIZ1's copy count is P1's AND its missile's, so the three
; close copies the text needs would put three dividers across the boards;
; it is switched here and back in LEADOUT, both while nothing of P1's is
; visible. The sprites are blanked again for the bank that entered warm.
LEADIN: sta     WSYNC
        lda     #0              ; 2
        sta     GRP0            ; 5
        sta     GRP1            ; 8
        sta     GRP0            ; 11
        sta     COLUP1          ; 14   the divider's colour
        lda     #CWATER         ; 16
        sta     COLUBK          ; 19   before pixel 0 at 22
        lda     #$10            ; 21   one copy, two clocks wide
        sta     NUSIZ1          ; 24
        lda     #2              ; 26
        sta     ENAM1           ; 29   before the divider at 49
        rts

; LEADOUT -- the line after a board: the playfield and the divider off before
; pixel 0, the copies back for the text, the water left on for one more
; line. The line after this one takes the background back to black in ITS
; hblank; a mid-line COLUBK change is a visible seam.
LEADOUT: sta    WSYNC
        lda     #0
        sta     PF0
        sta     PF1
        sta     PF2
        sta     ENAM1
        lda     #$13
        sta     NUSIZ1
        rts

; ---------------------------------------------------------------------------
; The three line bodies. Each is one scanline of one kind, cycle-exact:
;
;   PF0/PF1/PF2 for the LEFT half must be written by cycles 22/28/38, before
;   the beam reaches pixels 0/16/48. For the RIGHT half PF0 must land in
;   28..49 (after pixel 15 has been fetched, before 80), PF1 in 39..54, PF2 in
;   50..65. The NOPs are not padding: without them the right-half PF2 lands at
;   49 and its first colour clock is inside pixel 79, the left board's last.
;   Every window here has at least ten colour clocks of margin.
;
; Y is the cell row; A is free; X is untouched. Each ends at cycle 59 with the
; RTS, and a `jsr` to the next body puts its WSYNC at 68.
LAUX:   sta     WSYNC
        lda     #CAUX           ; 2
        sta     COLUPF          ; 5
        lda     TAUX0,y         ; 9
        sta     PF0             ; 12
        lda     TAUX1,y         ; 16
        sta     PF1             ; 19
        lda     TAUX2,y         ; 23
        sta     PF2             ; 26
        lda     TAUX3,y         ; 30
        sta     PF0             ; 33
        lda     TAUX4,y         ; 37
        nop                     ; 39
        sta     PF1             ; 42
        lda     TAUX5,y         ; 46
        nop                     ; 48
        nop                     ; 50
        sta     PF2             ; 53
        rts

LHIT:   sta     WSYNC
        lda     #CHIT
        sta     COLUPF
        lda     THIT0,y
        sta     PF0
        lda     THIT1,y
        sta     PF1
        lda     THIT2,y
        sta     PF2
        lda     THIT3,y
        sta     PF0
        lda     THIT4,y
        nop
        sta     PF1
        lda     THIT5,y
        nop
        nop
        sta     PF2
        rts

LMID:   sta     WSYNC
        lda     #CMISS
        sta     COLUPF
        lda     TMID0,y
        sta     PF0
        lda     TMID1,y
        sta     PF1
        lda     TMID2,y
        sta     PF2
        lda     TMID3,y
        sta     PF0
        lda     TMID4,y
        nop
        sta     PF1
        lda     TMID5,y
        nop
        nop
        sta     PF2
        rts

; ---------------------------------------------------------------------------
; BOARD8 -- cell rows Y .. ROWEND-1, eight lines each. The last line of the
; row is the AUX body inline with the loop test: `iny / cpy / bne` reaches
; the next row's first WSYNC at 70.
BOARD8: jsr     LAUX            ; 0
        jsr     LHIT            ; 1
        jsr     LHIT            ; 2
        jsr     LMID            ; 3
        jsr     LMID            ; 4
        jsr     LHIT            ; 5
        jsr     LHIT            ; 6
        sta     WSYNC           ; 7
        lda     #CAUX
        sta     COLUPF
        lda     TAUX0,y
        sta     PF0
        lda     TAUX1,y
        sta     PF1
        lda     TAUX2,y
        sta     PF2
        lda     TAUX3,y
        sta     PF0
        lda     TAUX4,y
        nop
        sta     PF1
        lda     TAUX5,y
        nop
        nop
        sta     PF2             ; 53
        iny                     ; 55
        cpy     ROWEND          ; 58
        bne     BOARD8          ; 61
        rts

; BOARD12 -- the two-player layout's square cells: three lines of red, four
; of white, three of red, between the yellow lines.
BOARD12: jsr    LAUX            ; 0
        jsr     LHIT            ; 1
        jsr     LHIT            ; 2
        jsr     LHIT            ; 3
        jsr     LMID            ; 4
        jsr     LMID            ; 5
        jsr     LMID            ; 6
        jsr     LMID            ; 7
        jsr     LHIT            ; 8
        jsr     LHIT            ; 9
        jsr     LHIT            ; 10
        sta     WSYNC           ; 11
        lda     #CAUX
        sta     COLUPF
        lda     TAUX0,y
        sta     PF0
        lda     TAUX1,y
        sta     PF1
        lda     TAUX2,y
        sta     PF2
        lda     TAUX3,y
        sta     PF0
        lda     TAUX4,y
        nop
        sta     PF1
        lda     TAUX5,y
        nop
        nop
        sta     PF2
        iny
        cpy     ROWEND
        bne     BOARD12
        rts
