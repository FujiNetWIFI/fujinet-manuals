; board.inc -- the four boards, in the cart's mosaic cells.
;
; A board is 5 x 4 text cells, each a mosaic of 2 x 3 squares (TOP_MOSAIC),
; so 10 x 12 squares:
;
;   square row 0      five fleet pips, one a cell (shipsLeft: T_PIP / T_PIPX)
;   square rows 1-10  the field, lit (tiles.inc)
;   square row 11     T_BLANK: the gap above the next name row
;
; A square's tile is its gamefield byte (0 unknown, 1 hit, 2 miss) ORed with
; its MAP byte (0, T_HULL, T_CUR, or placement's T_PLC / T_BAD). A board with
; no gamefield yet (placement) reads ZEROS for it, and a board with no marks
; reads ZEROS for MAP, so one loop draws every case. A text row is fifteen
; tile pairs (5 cells x 3 thirds) sent as one TOP_MOSAIC: four ops a board.
;
; The seats sit where the C ports put them: us bottom-left, then clockwise
; from top-left. Each board has its name row above it.
;
;   col  0-4   5  6-10  11  12-15
;   row 0  [seat 1 name]  [seat 2 name]   panel (game.inc)
;   1-4    [seat 1 board] [seat 2 board]
;   5      [YOU]          [seat 3 name]
;   6-9    [our board]    [seat 3 board]

; ---- the data page: page-aligned, so a table is reached by its low byte ----
ZEROS:  DB      100 DUP (0)             ; no gamefield, or no marks
ONES:   DB      NSHIPS DUP (1)          ; no shipsLeft: all afloat
mul10:  DB      0, 10, 20, 30, 40, 50, 60, 70, 80, 90
trow:   DB      0, 0, 1, 1, 1, 2, 2, 2, 3, 3    ; square row -> text row
sizes:  DB      5, 4, 3, 3, 2           ; the fleet (gameLogic.go SHIP_SIZES)
orgrc:  DB      60H, 10H, 16H, 66H      ; each seat's first board cell, $rc
dxt:    DB      0, 9, 0, 1, 9, 0, 1, 9, 0, 1    ; aiming: each digit's step,
dyt:    DB      0, 9, 9, 9, 0, 0, 0, 1, 1, 1    ; -1 as 9, the keypad's layout
        IF      HI($) <> HI(ZEROS)
        ERROR   "board.inc's tables cross a page"
        ENDIF

; tbyte -- D = the byte at table + D, for the data page's tables. Clobbers R8.
tbyte:  PLO     R8
        LDI     HI(ZEROS)
        PHI     R8
        LDN     R8
        FRET

; ---- the composer ----------------------------------------------------------

; bsetup -- V_BGF and V_BPIP for seat V_BSEAT: its gamefield and shipsLeft in
; the reply, or ZEROS and ONES while there are none (placement, status 1).
; V_BMH is the caller's.
        FIT     80
bsetup: GETV    V_ST
        SMI     ST_START
        BDF     bsu1                    ; 10-13 and 99 carry gamefields
        VAR     V_BGF
        LDI     HI(ZEROS)
        STR     RA
        INC     RA
        LDI     LO(ZEROS)
        STR     RA
        INC     RA                      ; V_BPIP
        LDI     HI(ONES)
        STR     RA
        INC     RA
        LDI     LO(ONES)
        STR     RA
        FRET
bsu1:   GETV    V_BSEAT
        FCALL   prec
        LDI     PGF
        FCALL   radd
        VAR     V_BGF
        GHI     RB
        STR     RA
        INC     RA
        GLO     RB
        STR     RA
        LDI     PLEFT-PGF
        FCALL   radd
        VAR     V_BPIP
        GHI     RB
        STR     RA
        INC     RA
        GLO     RB
        STR     RA
        FRET

; bdrow -- text row V_BTR (0-3) of seat V_BSEAT's board. The parameters go
; into V_BUF cell by cell (a cell's top, middle and bottom thirds), built a
; third at a time: RB walks V_BUF + third in steps of three.
        FIT     200
bdrow:  SETV    V_BK, 0
bdk:    LDI     HI(V_BUF)
        PHI     RB
        GETV    V_BK
        ADI     LO(V_BUF)
        PLO     RB
        GETV    V_BTR                   ; the square row: 3 * row + third
        STR     R2
        SHL
        ADD
        STR     R2
        GETV    V_BK
        ADD
        BZ      bdpip                   ; 0: the pips
        SMI     11
        BZ      bdpad                   ; 11: the gap
        ADI     10                      ; 1-10: field row y = that - 1
        ADI     LO(mul10)
        FCALL   tbyte
        PLO     R9                      ; R9 = MAP (or ZEROS) + y * 10
        GETV    V_BMH
        PHI     R9
        VAR     V_BGF+1                 ; R8 = the gamefield + y * 10
        GLO     R9
        SEX     RA
        ADD
        PLO     R8
        DEC     RA
        LDI     0
        ADC
        PHI     R8
        SEX     R2
        LDI     5
        PHI     RC
bdc:    LDA     R8                      ; left square: high nibble
        ANI     3
        STR     R2
        LDA     R9
        OR
        SHL
        SHL
        SHL
        SHL
        STR     RB
        LDA     R8                      ; right square: low nibble
        ANI     3
        STR     R2
        LDA     R9
        OR
        SEX     RB
        OR
        SEX     R2
        STR     RB
        INC     RB
        INC     RB
        INC     RB
        GHI     RC
        SMI     1
        PHI     RC
        BNZ     bdc
        BR      bdnext
bdpip:  VAR     V_BPIP                  ; a pip in each cell's left square
        LDA     RA
        PHI     R8
        LDN     RA
        PLO     R8
        LDI     NSHIPS
        PHI     RC
bdp1:   LDA     R8
        BZ      bdp2
        LDI     T_PIP*16+T_BLANK
        BR      bdp3
bdp2:   LDI     T_PIPX*16+T_BLANK
bdp3:   STR     RB
        INC     RB
        INC     RB
        INC     RB
        GHI     RC
        SMI     1
        PHI     RC
        BNZ     bdp1
        BR      bdnext
bdpad:  LDI     5
        PHI     RC
bdz1:   LDI     T_BLANK*16+T_BLANK
        STR     RB
        INC     RB
        INC     RB
        INC     RB
        GHI     RC
        SMI     1
        PHI     RC
        BNZ     bdz1
bdnext: GETV    V_BK
        ADI     1
        STR     RA
        XRI     3
        BNZ     bdk
        GETV    V_BSEAT                 ; the cursor: the seat's first cell,
        ADI     LO(orgrc)               ; down by the row
        FCALL   tbyte
        STR     R2
        GETV    V_BTR
        SHL
        SHL
        SHL
        SHL
        ADD
        HOT     TX_CURSOR
        LDR     RB, V_BUF
        LDI     TX_PARAM
        PHI     RF
        LDI     15
        PLO     RC
bde1:   LDA     RB
        PLO     RF
        LDN     RF
        DEC     RC
        GLO     RC
        BNZ     bde1
        LDI     FN_PARK
        PHI     RF
        LDI     TOP_MOSAIC
        HOT     TX_OP
        FRET

; bdraw -- the whole of seat V_BSEAT's board; V_BMH is the caller's. The
; keypads are looked at between rows: a board is ~20 ms of drawing.
        FIT     32
bdraw:  FCALL   bsetup
        SETV    V_BTR, 0
bdr1:   FCALL   bdrow
        FCALL   kpoll
        GETV    V_BTR
        ADI     1
        STR     RA
        XRI     4
        BNZ     bdr1
        FRET

; bblank -- seat V_BSEAT's name row and board as blanks: an empty seat.
        FIT     40
bblank: GETV    V_BSEAT
        ADI     LO(orgrc)
        FCALL   tbyte
        SMI     10H                     ; the name row
        PLO     RC
        LDI     5
        PHI     RC
bbl1:   GLO     RC
        FCALL   d_at
        LDI     5
        FCALL   blanks
        GLO     RC
        ADI     10H
        PLO     RC
        GHI     RC
        SMI     1
        PHI     RC
        BNZ     bbl1
        FRET

; ---- MAP -------------------------------------------------------------------

; mclear -- MAP all zero.
        FIT     16
mclear: LDR     R8, MAP+99
        SEX     R8
mcl1:   LDI     0
        STXD
        GLO     R8
        XRI     0FFH
        BNZ     mcl1
        SEX     R2
        FRET

; mstart -- the ship V_MX, V_MY, V_MD, V_ML: R8 = MAP + its first square,
; R9.0 = its step (1 across, 10 down), RC.0 = its length, and DF = 1; DF = 0
; if any of it is off the board.
        FIT     72
mstart: GETV    V_MX
        SMI     10
        BDF     msbad
        GETV    V_MY
        SMI     10
        BDF     msbad
        GETV    V_MD
        BZ      ms1
        GETV    V_MY
        BR      ms2
ms1:    GETV    V_MX
ms2:    STR     R2
        GETV    V_ML
        PLO     RC
        ADD
        SDI     10                      ; 10 - (start + length): no borrow, fits
        BNF     ms9
        GETV    V_MY
        ADI     LO(mul10)
        FCALL   tbyte
        STR     R2
        GETV    V_MX
        ADD
        PLO     R8
        LDI     HI(MAP)
        PHI     R8
        GETV    V_MD
        BZ      ms3
        LDI     10
        BR      ms4
ms3:    LDI     1
ms4:    PLO     R9
        SMI     0                       ; DF = 1
ms9:    FRET
msbad:  LDI     0
        ADI     0                       ; DF = 0
        FRET

; mfits -- DF = 1 if the ship (mstart's) is on the board over empty squares.
        FIT     40
mfits:  FCALL   mstart
        BNF     mf9
mf1:    LDN     R8
        BNZ     mf8
        GLO     R9
        STR     R2
        GLO     R8
        ADD
        PLO     R8
        DEC     RC
        GLO     RC
        BNZ     mf1
        SMI     0                       ; D = 0: DF = 1
        FRET
mf8:    ADI     0                       ; D != 0 and no carry: DF = 0
mf9:    FRET

; mmark -- the ship's squares (mstart's) = V_MT; where V_MT is T_PLC and a
; square is already marked, T_BAD instead, and V_MBAD = 1. DF as mstart.
        FIT     72
mmark:  FCALL   mstart
        BNF     mm9
mm1:    LDN     R8
        BZ      mm2
        GETV    V_MT
        XRI     T_PLC
        BNZ     mm2
        SETV    V_MBAD, 1
        LDI     T_BAD
        BR      mm3
mm2:    GETV    V_MT
mm3:    STR     R8
        GLO     R9
        STR     R2
        GLO     R8
        ADD
        PLO     R8
        DEC     RC
        GLO     RC
        BNZ     mm1
        SMI     0                       ; DF = 1
mm9:    FRET

; mdec -- V_MX, V_MY, V_MD from D = pos + 100 * dir, the wire's placement.
; DF = 0 if D is past 199.
        FIT     64
mdec:   PLO     R9
        SETV    V_MD, 0
        GLO     R9
        SMI     100
        BNF     md1
        PLO     R9
        SETV    V_MD, 1
        GLO     R9
        SMI     100
        BDF     mdbad
md1:    LDI     0                       ; R9.1 = pos / 10, R9.0 = pos % 10
        PHI     R9
md2:    GLO     R9
        SMI     10
        BNF     md3
        PLO     R9
        GHI     R9
        ADI     1
        PHI     R9
        BR      md2
md3:    GLO     R9
        PUTV    V_MX
        GHI     R9
        PUTV    V_MY
        SMI     0                       ; DF = 1
        FRET
mdbad:  LDI     0
        ADI     0                       ; DF = 0
        FRET

; mships -- MAP gets the five wire placements at RB as T_HULL. RB is left
; past them.
        FIT     56
mships: SETV    V_CTR, 0
msh1:   LDA     RB
        FCALL   mdec
        BNF     msh2
        GETV    V_CTR
        ADI     LO(sizes)
        FCALL   tbyte
        PUTV    V_ML
        SETV    V_MT, T_HULL
        FCALL   mmark
msh2:   GETV    V_CTR
        ADI     1
        STR     RA
        XRI     NSHIPS
        BNZ     msh1
        FRET

; mcur -- MAP all zero but the aiming cursor's square, T_CUR.
        FIT     24
mcur:   FCALL   mclear
        FCALL   cpos
        PLO     R8
        LDI     HI(MAP)
        PHI     R8
        LDI     T_CUR
        STR     R8
        FRET

; cpos -- D = the cursor's square, V_CY * 10 + V_CX.
        FIT     24
cpos:   GETV    V_CY
        ADI     LO(mul10)
        FCALL   tbyte
        STR     R2
        GETV    V_CX
        ADD
        FRET
