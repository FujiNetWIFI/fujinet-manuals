; fujitext.asm -- a batari Basic minikernel that shows the cartridge's text.
;
; The FujiNet cartridge composes 12-column text into six 128-byte planes at
; $1800-$1AFF (fuji_mailbox.h); this draws FT_ROWS of those rows, starting at
; text row FT_ROW0, between batari Basic's playfield and its score, in the
; slot the standard kernel offers a `minikernel`. The ink body is the
; bring-up's fujidisp.inc kernel, transcribed and NOT retimed: its four
; positioning constants are the coordinates of a one-pixel-wide window.
;
; In the program:
;       include fujitext.asm
;       const FT_ROW0 = 18      ; first text row shown (0-20)
;       const FT_ROWS = 3       ; how many (1-21)
;       const pfres = 8         ; and shrink the playfield to pay for the
;       const pfrowheight = 8   ;   3 + 6*FT_ROWS scanlines this costs
;
; batari Basic's frame is timer-locked, so the lines this draws come out of
; the time the BASIC program has between frames unless the playfield gives
; them back; emu/frames.lua is what says whether the frame is still 262.
        ifnconst FT_ROW0
FT_ROW0 = 18
        endif
        ifnconst FT_ROWS
FT_ROWS = 3
        endif
        ifnconst FT_COLOR
FT_COLOR = $0E                  ; white
        endif
FT_Y0   = FT_ROW0*6
FT_Y1   = FT_Y0+FT_ROWS*6
FT_PAD  = temp1                 ; a 3-cycle store target
FT_SP   = temp2                 ; the stack pointer, parked across the rows

; The plane bases, FN_T_PLANE(0..5).
FT_P0   = $1800
FT_P1   = $1880
FT_P2   = $1900
FT_P3   = $1980
FT_P4   = $1A00
FT_P5   = $1A80

minikernel
        sta     WSYNC
; Two players, three copies each, eight pixels apart: P0 draws groups 0,2,4
; and P1 groups 1,3,5, interleaving to 48 contiguous pixels. VDELP is what
; makes the six-write sequence land in the right copies.
        lda     #$03
        sta     NUSIZ0
        sta     NUSIZ1
        lda     #1
        sta     VDELP0
        sta     VDELP1
        lda     #FT_COLOR
        sta     COLUP0
        sta     COLUP1
        lda     #0
        sta     GRP0
        sta     GRP1
        sta     GRP0
; Positioning: 16 NOPs plus one 3-cycle store, RESP0 at cycle 38, RESP1 three
; cycles later, HMP0 = $F0 to pull P0 right one pixel, and an EARLY HMOVE.
        sta     WSYNC
        REPEAT  16
        nop
        REPEND
        sta     FT_PAD
        sta     RESP0
        sta     RESP1
        lda     #$F0
        sta     HMP0
        lda     #0
        sta     HMP1
        sta     WSYNC
        sta     HMOVE
; The rows. 53 cycles of the 76; Y is the absolute scanline into the planes,
; so `lda plane,y` is always four cycles and no per-row setup exists. The
; stack pointer parks group 4, because a zero-page store is 3 cycles and the
; six copies are 2.67 apart. Nothing here may touch the stack.
        tsx
        stx     FT_SP
        ldy     #FT_Y0
ftkern  sta     WSYNC
        lda     FT_P0,y         ; 4
        sta     GRP0            ; 3   ->  7   new GRP0 = group 0
        lda     FT_P1,y         ; 4   -> 11
        sta     GRP1            ; 3   -> 14   displays group 0
        lda     FT_P2,y         ; 4   -> 18
        sta     GRP0            ; 3   -> 21   displays group 1
        lda     FT_P4,y         ; 4   -> 25
        tax                     ; 2   -> 27
        txs                     ; 2   -> 29   park group 4 in S
        lda     FT_P3,y         ; 4   -> 33
        tax                     ; 2   -> 35
        lda     FT_P5,y         ; 4   -> 39
        stx     GRP1            ; 3   -> 42   displays group 2
        tsx                     ; 2   -> 44   recover group 4
        stx     GRP0            ; 3   -> 47   displays group 3
        sta     GRP1            ; 3   -> 50   displays group 4
        sty     GRP0            ; 3   -> 53   displays group 5; value unused
        iny
        cpy     #FT_Y1
        bne     ftkern
        ldx     FT_SP
        txs
; Blank both players: three writes, not two -- with VDELP set a write to
; GRP0 only reloads the DELAYED GRP1 and vice versa.
        lda     #0
        sta     GRP0
        sta     GRP1
        sta     GRP0
        rts
