; disptext.inc -- the 48-pixel text display, with colour.
;
; The cartridge composes the glyphs (firmware/src/vcs_render.c) and publishes
; them as six 128-byte planes at $1800-$1AFF; this is the console half.
;
; THE 53-CYCLE INK BODY BELOW IS TRANSCRIBED FROM
; fujinet-firmware/pico/atari-2600/testrom/fujidisp.inc AND MUST NOT BE
; RETIMED. Its four constants are the coordinates of a ONE-PIXEL-WIDE window
; found by byte-comparing the raster against the renderer with
; emu/dispcheck.py -- every wrong setting still looks like text.
;
; WHAT IS ADDED HERE: colour, for nothing.
;
; vcs_render_row() writes ZERO to scanline 5 of every cell -- the sixth line
; of a 4x6 cell is blank leading and the renderer does not store it. So the
; loop is 21 rows of (5 cycle-exact ink lines + 1 SEAM LINE), the seam line is
; a line on which no glyph can possibly be drawn, and it is free for whatever
; the kernel wants to do instead. That costs no scanlines at all: the blank
; line was already there, and the picture is still 21*6 = 126 lines.
;
; "Free" means free of DEADLINES, not free of cycles: the seam line still has
; to finish inside its 76, or it quietly costs a second scanline. The budget is
; spelled out where it is spent, at the seam line itself.
;
; Three facts make the seam line's timing a non-problem, which is the whole
; trick:
;
;   * Its sprite writes are BLANKING writes. The copies draw nothing whatever
;     cycle the stores land on.
;   * COLUBK has until the green playfield border ends at pixel 31, about
;     cycle 32, because the playfield draws OVER the background -- a
;     background change underneath the border cannot be seen. That is a
;     33-cycle window for a compare and a branch, not the 22 of hblank.
;   * COLUP0/COLUP1 have NO deadline on this line. The sprites are blank, so a
;     new ink colour cannot show until the next line anyway.
;
; What that buys: a sea-blue frame, a black panel, a full-width red bar under
; the selected row, and a per-row background -- with the ink body left
; byte-identical on every line that draws. The 5 Card Stud original also
; picked a per-seat ink colour here; every text screen in this client is
; white ink, so that pick is gone and the seam line is shorter for it.

; ---------------- kernel timing constants ----------------
; Not taste. See the file header.
RNOP    EQU     16              ; NOPs before RESP0 (2 cycles each)...
R3      EQU     1               ; ...plus this, so RESP0 lands on cycle 38
HM0     EQU     15              ; HMP0 = $F0: move P0 right one pixel...
HM1     EQU     0               ; ...and leave P1, closing the gap to eight
VDEL    EQU     1               ; vertical delay on both players

; ---------------- text plane bases ----------------
TP0     EQU     FNTEXT+$000
TP1     EQU     FNTEXT+$080
TP2     EQU     FNTEXT+$100
TP3     EQU     FNTEXT+$180
TP4     EQU     FNTEXT+$200
TP5     EQU     FNTEXT+$280

TINK    EQU     FNTCLH-1        ; 5 ink lines, then the seam
TLINES  EQU     FNTROW*FNTCLH   ; 126 scanlines of text

; NTSC: 3 vsync + 37 vblank + 192 visible + 30 overscan = 262.
VBLINES EQU     37
OSLINES EQU     30
PADLINE EQU     (192-TLINES)/2  ; 33 above and below

; THE BLANKED BANDS ARE TIMED, NOT COUNTED, and that is not a refinement --
; counting them is what made the picture jump.
;
; The old loop burned VBLINES scanlines on WSYNC and THEN called APPVBL, so
; whatever the hook did was ADDED to the frame instead of spent inside it. A
; frame measured 265 scanlines rather than 262 just from scanning the input,
; wandered between 262, 264 and 265 depending on what the hook touched, and
; reached 413 on the frame a SELECT press recomposed the seats. Every one of
; those is a different vertical position on the screen.
;
; So the two blanked bands set the RIOT's 64-cycle timer, do their work, and
; then wait out whatever is left of it. The hook now runs INSIDE the vblank
; and costs the frame nothing at all, as long as it fits.
;
; THE BUDGET IT HAS TO FIT IN IS 37 SCANLINES -- 2812 cycles, and no more.
; DPADA and DPADB are not spare: they are the green bands, and they are
; visible. Work that overruns still lengthens the frame, and the frame still
; jumps; it is just that almost nothing overruns now.
;
; The two counts are in 64-cycle units and are one less than the arithmetic
; suggests, because the timer has to expire INSIDE the last line rather than
; on its boundary -- at 43 it lands 36 cycles into scanline 36 of 37, and the
; WSYNC that follows takes the band to exactly 37. They were confirmed by
; histogramming VSYNC-to-VSYNC with emu/blank.lua, not derived.
VBTIM   EQU     43              ; ~37 scanlines of vblank
OSTIM   EQU     35              ; ~30 scanlines of overscan

; The side border, PFEDGE in bsdefs.inc: PF0 is pixels 0-3 in its HIGH nibble
; and PF1 pixels 4-11 drawn MSB first, so $F0 in each lights pixels 0-7 --
; clocks 0-31. With CTRLPF's reflect bit the right half mirrors, putting the
; same 32 clocks at 128-159. The 48-pixel text block sits at pixels 46-94 and
; never comes near either.

; ---------------- DINIT: TIA setup and player positioning ----------------
DINIT:
; Two players, three copies each, eight pixels apart: P0 draws groups 0,2,4
; and P1 groups 1,3,5, interleaving to 48 contiguous pixels. VDELP is what
; makes the six-write sequence land in the right copies.
        lda     #$03            ; NUSIZ: three copies, close
        sta     NUSIZ0
        sta     NUSIZ1
        lda     #VDEL
        sta     VDELP0
        sta     VDELP1
        lda     #CWHITE
        sta     COLUP0
        sta     COLUP1
        lda     #CWATER
        sta     COLUBK
        sta     COLUPF
        lda     #$01            ; CTRLPF: reflect, so one nibble draws both
        sta     CTRLPF          ;   edges
        lda     #PFEDGE
        sta     PF0
        sta     PF1
        lda     #0
        sta     PF2
        sta     ENAM1           ; the board banks' divider
        sta     BSBAR           ; no red bar until a menu asks for one
        sta     BSFRAME
        sta     GRP0
        sta     GRP1
        sta     GRP0

; Player positioning, transcribed from batari Basic's std_kernel.asm rather
; than re-derived. RESP0 strobed at cycle 43, RESP1 three cycles later (nine
; pixels, since two stores cannot be closer), then HMP0/HMP1 pull them to
; eight apart. RDLY is built from NOPs plus an optional 3-cycle zero-page
; store, because the copies are 2.67 cycles apart and NOPs alone only reach
; even delays.
        sta     WSYNC
        REPT    RNOP
        nop
        ENDM
        IF      R3
        sta     PAD3            ; 3 cycles, so odd delays are reachable
        ENDIF
        sta     RESP0
        sta     RESP1
        lda     #HM0*16
        sta     HMP0
        lda     #(HM1*16)&$FF
        sta     HMP1
; An EARLY HMOVE -- WSYNC, then strobe -- rather than batari's late one at
; cycle 73. A late HMOVE does not apply the motion nibbles cleanly: nudging
; HMP0 by one there widened the player gap from 8 pixels to 9 instead of
; sliding the block, and the window this kernel needs is one pixel wide.
        sta     WSYNC
        sta     HMOVE
        rts

; ---------------- DLOOP: draw frames, forever ----------------
; DFRESH is the entry for a FRESH start -- a screen change, not a frame
; being finished or followed -- and arms the overscan timer DFRAME waits
; on, because a stale count could be seconds. See dispgame.inc.
DFRESH: lda     #OSTIM
        sta     TIM64T
DLOOP:  jsr     DFRAME
        jmp     DLOOP

; ---------------- DFRAME: draw ONE frame, then return ----------------
; Split out of DLOOP so a bank that is not running the display loop can still
; keep the picture alive: net.inc waits for the cartridge a frame at a time
; through here, which is what stops a poll from blanking the screen.
;
; A JSR into this is safe despite the kernel parking a graphics byte in S. The
; return address is pushed BEFORE that happens and nothing pushes again until
; SAVSP has been restored -- the same rule the kernel already lives by, one
; level further out.
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
; The client's per-frame hook, called while the screen is still blanked and
; the raster is nowhere near the text. Input scanning belongs here; so does
; STARTING a transaction, which is a bank switch out of this loop -- the bank
; that talks keeps the picture alive by calling DFRAME below, one frame per
; wait, rather than by returning here.
;
; It runs ON the clock the store above started, so the frame does not grow by
; what it does. See VBTIM for the 2812 cycles it has to fit in.
        inc     BSFRAME
        jsr     APPVBL

; ---------------- DFRAME2: finish the frame the hook was called in ----------
; A bank entered from another bank's hook carries on from here, so the frame
; the switch interrupted is still 262 lines. See dispgame.inc.
DFRAME2:
; Wait out the rest of the band, then land the unblank on a LINE BOUNDARY.
; Both halves matter. The timer is what makes the band a fixed length whatever
; APPVBL did; the WSYNC is what keeps VBLANK from being cleared mid-scanline,
; which used to bring the first visible line up black for its first forty
; pixels and green for the rest -- a visible notch in the top left corner.
;
; TIMINT, not INTIM. Past zero the timer does not stop: it free-runs at a tick
; a cycle, and a seven-cycle `lda INTIM / bne` walks over the single cycle it
; reads zero on again and again. Polling INTIM cost an overrunning frame 290
; scanlines where the work itself was 151. TIMINT's bit 7 LATCHES on the
; underflow and stays latched, so an overrun costs exactly the overrun.
DVBLP:  bit     TIMINT
        bpl     DVBLP
        sta     WSYNC
        lda     #0
        sta     VBLANK

; The top band is felt, and its LAST line hands over to row 0: the store lands
; a couple of cycles into hblank, so that line is already the panel's colour
; and no scanline is spent on the transition.
        ldx     #PADLINE-1
DPADA:  sta     WSYNC
        dex
        bne     DPADA
        sta     WSYNC
        lda     BSBGT           ; row 0's background
        sta     COLUBK
        lda     #CWHITE
        sta     COLUP0
        sta     COLUP1

; ---------------- the kernel ----------------
; The stack pointer is a spare register in the ink body, and that is not a
; flourish: the six player copies are 2.67 cycles apart while a zero-page
; store is 3, so the four late writes drift a full cycle across the block.
; Recovering a byte from zero page costs 3 cycles; `tsx` costs 2, and that one
; cycle is the difference between a schedule that closes and one that does
; not. It is also why the seventh write is `sty GRP0`: its value is a
; don't-care, so Y serves and no register need be spared.
;
; NOTHING between the txs here and the restore below may touch the stack --
; no JSR -- which is why the row loop and the seam line are inline. The 6507
; has no interrupts, so there is nothing else to worry about.
        tsx
        stx     SAVSP
        ldy     #0              ; the absolute scanline, 0-125; never clobbered
        lda     #0
        sta     BSROW

DROWL:  lda     #TINK
        sta     BSLINE

DINK:   sta     WSYNC
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
        dec     BSLINE          ; 5   -> 60
        bne     DINK            ; 3   -> 63

; ---- the seam line ----
; Line 5 of the cell. The cartridge stores zero here, so no glyph can be
; drawn and the kernel does something useful instead. See the file header for
; why none of this needs to be cycle-exact WITHIN the line.
;
; IT DOES, HOWEVER, HAVE TO FIT IN ONE. This is a WSYNC-bounded loop, so a
; seam line that runs past cycle 76 does not glitch -- it silently costs a
; SECOND scanline, because the next `sta WSYNC` is then already on the
; following line and waits for the end of THAT one. The first cut of this
; reached DROWL's `lda #TINK` at cycle 77 on the seat path and every seat row
; was seven scanlines instead of six: 142 lines of text, a 278-line frame, a
; picture that rolls on anything that cares. Nothing about it looked wrong on
; screen, which is the whole problem with the failure mode.
;
; The budget is therefore from this WSYNC to the last cycle of the next one,
; and it is 76. The path below reaches it at 58, with `lda BSBGT,x` costing a
; fifth cycle in any bank whose twenty-two byte table straddles a page and
; `bne DSEAM1` a third if its target ever lands on another page.
        sta     WSYNC
        lda     #0              ; 2
        sta     GRP0            ; 3   ->  5   three writes, not two: with
        sta     GRP1            ; 3   ->  8     VDELP set a write to GRP0
        sta     GRP0            ; 3   -> 11     reloads the DELAYED GRP1
        ldx     BSROW           ; 3   -> 14
        inx                     ; 2   -> 16   the row these colours are FOR
        lda     BSBGT,x         ; 4   -> 20
        cpx     BSBAR           ; 3   -> 23
        bne     DSEAM1          ; 3   -> 26
        lda     #CRED           ; 2         the selected move's bar
DSEAM1: sta     COLUBK          ; 3   -> 29   by cycle 30, pixel 22 at the
                                ;   latest, under the green border
        stx     BSROW           ; 3   -> 32   the row counter, advanced here
                                ;   rather than with a read-modify-write at
                                ;   the bottom: X still holds it, and `inc`
                                ;   costs five cycles this line has not got
        iny                     ; 2   -> 34   step past the blank plane byte.
                                ;   AFTER the COLUBK store, not before: it has
                                ;   to land before the green border ends at
                                ;   pixel 31 and two cycles is two-thirds of
                                ;   the margin that had.
; The ink colour: white, every row. (The original chose a per-seat colour
; here; this client's text screens have no seats.)
        lda     #CWHITE         ; 2   -> 36
        sta     COLUP0          ; 3   -> 39
        sta     COLUP1          ; 3   -> 42
        lda     BSROW           ; 3   -> 45
        cmp     #FNTROW         ; 2   -> 47
        bne     DROWL           ; 3   -> 50   + DROWL's 5 and the WSYNC's 3

        ldx     SAVSP
        txs

; The last seam line already blanked the sprites and set the background back
; to felt -- BSBGT's twenty-second entry exists for exactly that -- so the
; bottom band needs nothing but scanlines.
        ldx     #PADLINE
DPADB:  sta     WSYNC
        dex
        bne     DPADB

        lda     #2
        sta     VBLANK
        lda     #OSTIM          ; the next DFRAME waits this out; see above
        sta     TIM64T
; Returns with VBLANK SET and the overscan timer running: a bank may do up to
; about 2,200 cycles of work before the next DFRAME for free.
        rts

; ---------------------------------------------------------------------------
; BSBGT is NOT here. Each bank supplies its own twenty-two byte table, because
; each bank is a different screen.
;
; Twenty-TWO entries, not twenty-one: the seam line at the bottom of row 20
; programmes row 21, which does not exist, and making that entry felt is what
; turns the handover to the bottom band into a colour the kernel was going to
; write anyway.
