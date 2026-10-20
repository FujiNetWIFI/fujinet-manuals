; tiles.inc -- the 16 mosaic tiles (the cart's TOP_TILE): four scanlines of
; two pixels, bit 1 the left. One tile is one square of a board, 2 pixels by 4
; scanlines, and a text cell holds 2 x 3 of them (board.inc). On a TV a pixel
; is about three scanlines wide, so a square is a little wider than tall.
;
; A board is a lit field and the marks are dark: black is a ship -- a hit on
; an opponent, or our own hull -- a hatched square is a hit on our hull, and a
; dark dot is a miss. Lit, the four boards stand out as four panels; dark,
; with only their marks lit, they could not be told from the black around them.
;
; A square's tile is its gamefield value ORed with MAP's mark, so the numbers
; are not free: 0-2 are the wire's 0 unknown / 1 hit / 2 miss, T_HULL (4) and
; T_CUR (8) add on top of them, and the rest fill the holes.

T_SEA   EQU     0               ; open water, or not yet shot at
T_HIT   EQU     1
T_MISS  EQU     2
T_PIP   EQU     3               ; a fleet pip: the ship is afloat
T_HULL  EQU     4               ; a hull (ours, or the winner's revealed)
T_HHIT  EQU     5               ; a hull that has been hit
T_PIPX  EQU     7               ; a fleet pip: sunk
T_CUR   EQU     8               ; the aiming cursor over 0-2 (8-10): blinks
T_PLC   EQU     11              ; the ship being placed: blinks
T_BLANK EQU     12              ; nothing: the pip row's gaps, the row below
T_BAD   EQU     15              ; the ship being placed, on another: blinks

; Scanline rows, top to bottom: "##" is 3, "#." 2, ".#" 1, ".." 0.
tiles:  DB      3, 3, 3, 3              ; 0  T_SEA    ##  ##  ##  ##
        DB      0, 0, 0, 0              ; 1  T_HIT    ..  ..  ..  ..
        DB      3, 1, 1, 3              ; 2  T_MISS   ##  .#  .#  ##
        DB      0, 3, 3, 0              ; 3  T_PIP    ..  ##  ##  ..
        DB      0, 0, 0, 0              ; 4  T_HULL   ..  ..  ..  ..
        DB      2, 1, 2, 1              ; 5  T_HHIT   #.  .#  #.  .#
        DB      0, 0, 0, 0              ; 6  (a miss on a hull cannot be)
        DB      0, 0, 2, 0              ; 7  T_PIPX   ..  ..  #.  ..
        DB      3, 3, 3, 3              ; 8-10, 11: tblink's
        DB      0, 0, 0, 0
        DB      3, 1, 1, 3
        DB      0, 0, 0, 0
        DB      0, 0, 0, 0              ; 12 T_BLANK
        DB      0, 0, 0, 0              ; 13, 14 unused
        DB      0, 0, 0, 0
        DB      2, 1, 2, 1              ; 15: tblink's

; The blinking tiles, each "on" then "off": the cursor inverts what it is
; over; a ship being placed flickers dark / hatched, and where it overlaps
; another it buzzes between two stripes.
blinks: DB      T_CUR+T_SEA
        DB      0, 0, 0, 0,  3, 3, 3, 3
        DB      T_CUR+T_HIT
        DB      3, 3, 3, 3,  0, 0, 0, 0
        DB      T_CUR+T_MISS
        DB      0, 2, 2, 0,  3, 1, 1, 3
        DB      T_PLC
        DB      0, 0, 0, 0,  2, 1, 2, 1
        DB      T_BAD
        DB      3, 0, 3, 0,  0, 3, 0, 3
NBLINK  EQU     5
BLINKF  EQU     12              ; frames a phase

; tinit -- define all sixteen tiles.
        FIT     40
tinit:  LDR     RB, tiles
        LDI     0
        PLO     RC
ti1:    GLO     RC
        HOT     TX_PARAM
        LDI     4
        PHI     RC
ti2:    LDA     RB
        HOT     TX_PARAM
        GHI     RC
        SMI     1
        PHI     RC
        BNZ     ti2
        LDI     TOP_TILE
        HOT     TX_OP
        INC     RC
        GLO     RC
        XRI     16
        BNZ     ti1
        FRET

; tblink -- every BLINKF frames, flip V_BLNK and redefine the blinking
; tiles; the cart redraws just the cells that hold them.
        FIT     80
tblink: GETV    V_BLT
        STR     R2
        GLO     RE
        SM
        SMI     BLINKF
        BNF     tbl9                    ; not yet
        GLO     RE
        PUTV    V_BLT
        GETV    V_BLNK
        XRI     1
        STR     RA
        LDR     RB, blinks
        LDI     NBLINK
        PLO     RC
tbl1:   LDA     RB                      ; the tile
        HOT     TX_PARAM
        GETV    V_BLNK
        BNZ     tbl2
        INC     RB                      ; phase 0 is "off": skip "on"
        INC     RB
        INC     RB
        INC     RB
tbl2:   LDI     4
        PHI     RC
tbl3:   LDA     RB
        HOT     TX_PARAM
        GHI     RC
        SMI     1
        PHI     RC
        BNZ     tbl3
        GETV    V_BLNK
        BZ      tbl4
        INC     RB                      ; phase 1 is "on": skip "off"
        INC     RB
        INC     RB
        INC     RB
tbl4:   LDI     TOP_TILE
        HOT     TX_OP
        DEC     RC
        GLO     RC
        BNZ     tbl1
tbl9:   FRET
