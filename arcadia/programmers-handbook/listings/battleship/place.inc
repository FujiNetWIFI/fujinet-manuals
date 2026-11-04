; place.inc -- laying out your five ships.
;
; A random legal layout is seeded first and then adjusted, which is the
; astrocade port's model: the player is never made to build a board from
; nothing, and the seed is guaranteed legal.
;
; OVERLAP TESTING USES THE SCREEN AS THE OCCUPANCY MAP. A 10x10 byte
; array is 100 bytes and this machine has 84 in total, so instead the
; board is repainted carrying every ship EXCEPT the one being moved, and
; a candidate is legal when every cell it would cover reads as open sea.
; Storing NOPLC into the moving ship's slot for the duration of the
; repaint is what excludes it -- YSHIPR already skips NOPLC -- so the
; whole trick costs nothing but the two bytes that shelter the slot.
;
; V_CURS, not V_SHP, holds the ship being adjusted: V_SHP is YSHIPR's
; loop variable and does not survive a board repaint.

PLACSCR: BSTA,UN SEEDRD         ; reseed -- by now ACKSEQ has moved, so
        BSTA,UN PLSEED          ;   the layout differs run to run
        LODI,R0 0
        STRA,R0 V_CURS
        BSTA,UN PLSHOW
PLKEY:  BSTA,UN GETKEY
        STRZ    R1
        COMI,R0 KUP
        BCTR,EQ PLMV
        COMI,R0 KDOWN
        BCTR,EQ PLMV
        COMI,R0 KLEFT
        BCTR,EQ PLMV
        COMI,R0 KRIGHT
        BCTR,EQ PLMV
        COMI,R0 5               ; keypad 5 rotates
        BCTA,EQ PLROT
        COMI,R0 KENT            ; Enter or FIRE commits this ship
        BCTR,EQ PLCOMM
        COMI,R0 2
        BCTR,EQ PLCOMM
        COMI,R0 KCLR            ; Clear leaves the table
        BCTA,EQ PLQUIT
        BCTA,UN PLKEY
PLMV:   BSTA,UN PLMOVE
        BCTA,UN PLKEY
PLCOMM: BSTA,UN SNDPLC
        LODA,R0 V_CURS
        ADDI,R0 1
        STRA,R0 V_CURS
        COMI,R0 NSHIPS
        BCTR,EQ PLDONE
        BSTA,UN PLSHOW
        BCTA,UN PLKEY
PLDONE: BSTA,UN PLFINL          ; every hull settled, none highlighted
        LODI,R0 RQPLACE         ; the layout rides the next poll
        STRA,R0 PENDACT
        RETC,UN
PLQUIT: LODI,R0 RQLEAVE
        STRA,R0 PENDACT
        RETC,UN

; PLSHOW: repaint the board with the settled hulls, then the ship under
; the cursor in red on top, and the prompt.
; Calls four down. Clobbers R0-R3.
PLSHOW: BSTA,UN PLDRWO
        BSTA,UN PLCUR
        BCTA,UN PLHINT          ; tail call

; PLFINL: the finished layout, nothing highlighted.
; Calls four down. Clobbers R0-R3.
PLFINL: BSTA,UN YBCLR
        BCTA,UN YSHIPR          ; tail call

; PLDRWO: repaint your board carrying every hull EXCEPT the one being
; adjusted, which is what turns the screen into the occupancy map.
; Calls four down (YSHIPR -> SHIPDR -> PLCDEC/DPOS). Clobbers R0-R3.
PLDRWO: LODA,R0 V_CURS
        STRZ    R2
        LODA,R0 SHIPS,R2
        STRA,R0 V_SAVP          ; shelter it across the repaint
        LODI,R0 NOPLC
        STRA,R0 SHIPS,R2
        BSTA,UN YBCLR
        BSTA,UN YSHIPR
        LODA,R0 V_CURS
        STRZ    R2
        LODA,R0 V_SAVP
        STRA,R0 SHIPS,R2
        RETC,UN

; PLCUR: draw the ship under the cursor, red, over the repainted board.
; Calls three down. Clobbers R0-R3.
PLCUR:  LODA,R0 V_CURS
        STRA,R0 V_SHP
        STRZ    R2
        LODA,R0 SHIPS,R2
        COMI,R0 NOPLC
        BCTR,EQ PLC9
        STRA,R0 V_PLC
        LODI,R0 AHIT
        STRA,R0 DCOLOR
        BCTA,UN SHIPDR          ; tail call
PLC9:   RETC,UN

; PLMOVE: shift the ship under the cursor one cell in direction R1.
; Works in (x, y, dir) rather than on the packed position so a sideways
; step can never wrap across a row. Illegal moves are refused, not
; clamped. Calls four down. Clobbers R0-R3.
PLMOVE: STRA,R1 V_BTMP
        LODA,R0 V_CURS
        STRA,R0 V_SHP
        STRZ    R2
        LODA,R0 SHIPS,R2
        STRA,R0 V_PLC
        BSTA,UN PLCDEC          ; -> V_SX, V_SY, V_DIR, V_LEN
        LODA,R0 V_BTMP
        COMI,R0 KUP
        BCFR,EQ PLMD
        LODA,R0 V_SY
        BCTA,EQ PLMBAD
        SUBI,R0 1
        STRA,R0 V_SY
        BCTR,UN PLMTRY
PLMD:   COMI,R0 KDOWN
        BCFR,EQ PLML
        LODA,R0 V_SY
        ADDI,R0 1
        COMI,R0 BRDDIM
        BCTA,EQ PLMBAD
        STRA,R0 V_SY
        BCTR,UN PLMTRY
PLML:   COMI,R0 KLEFT
        BCFR,EQ PLMR
        LODA,R0 V_SX
        BCTA,EQ PLMBAD
        SUBI,R0 1
        STRA,R0 V_SX
        BCTR,UN PLMTRY
PLMR:   LODA,R0 V_SX
        ADDI,R0 1
        COMI,R0 BRDDIM
        BCTA,EQ PLMBAD
        STRA,R0 V_SX
PLMTRY: BSTA,UN PLENC
        BCTA,UN PLTRY           ; tail call
PLMBAD: BCTA,UN SNDERR          ; tail call

; PLROT: flip the ship under the cursor between horizontal and vertical.
; Calls four down. Clobbers R0-R3.
PLROT:  LODA,R0 V_CURS
        STRA,R0 V_SHP
        STRZ    R2
        LODA,R0 SHIPS,R2
        STRA,R0 V_PLC
        BSTA,UN PLCDEC
        LODA,R0 V_DIR
        EORI,R0 1
        STRA,R0 V_DIR
        BSTA,UN PLENC
        BCTA,UN PLTRY           ; tail call

; PLENC: V_PLC = V_SY*10 + V_SX + 100*V_DIR.
; Calls one down (MUL10). Clobbers R0,R1,R3.
PLENC:  LODA,R0 V_SY
        BSTA,UN MUL10
        ADDA,R0 V_SX
        STRZ    R3
        LODA,R0 V_DIR
        BCTR,EQ PLE1
        LODZ    R3
        ADDI,R0 100
        STRZ    R3
PLE1:   LODZ    R3
        STRA,R0 V_PLC
        RETC,UN

; PLTRY: commit V_PLC for the ship under the cursor if it is legal,
; otherwise leave the old placement alone and complain.
; Calls four down. Clobbers R0-R3.
PLTRY:  BSTA,UN PLDRWO          ; the screen becomes the occupancy map
        BSTA,UN TESTSHP
        BCFR,EQ PLTBAD
        LODA,R0 V_CURS
        STRZ    R2
        LODA,R0 V_PLC
        STRA,R0 SHIPS,R2
        BSTA,UN PLCUR
        BCTA,UN SNDMOVE         ; tail call
PLTBAD: LODA,R0 V_CURS          ; put the settled one back on screen
        STRZ    R2
        LODA,R0 SHIPS,R2
        STRA,R0 V_PLC
        BSTA,UN PLCUR
        BCTA,UN SNDERR          ; tail call

; TESTSHP: is V_PLC legal for the ship under the cursor? R0 = 0 if so.
; Assumes the board currently carries every OTHER hull (PLDRWO). Reads
; the screen back through the same auto-increment cursor the writer uses.
; Calls one down (PLCDEC, DPOS). Clobbers R0-R3.
TESTSHP: LODA,R0 V_CURS
        STRA,R0 V_SHP
        BSTA,UN PLCDEC
        LODA,R0 V_DIR           ; does it run off the edge?
        BCTR,EQ TSH
        LODA,R0 V_SY
        BCTR,UN TSB
TSH:    LODA,R0 V_SX
TSB:    ADDA,R0 V_LEN
        COMI,R0 BRDDIM
        BCTA,GT TSBAD
        LODI,R0 0
        STRA,R0 V_SEG
TS1:    LODA,R0 V_SY
        ADDI,R0 YBROW
        STRZ    R1
        LODA,R0 V_SX
        ADDI,R0 BCOL
        STRZ    R2
        BSTA,UN DPOS
        LODA,R0 *SCRP,R2,+
        ANDI,R0 $3F
        BCFR,EQ TSBAD           ; not open sea: another hull is there
        LODA,R0 V_DIR
        BCTR,EQ TSSX
        LODA,R0 V_SY
        ADDI,R0 1
        STRA,R0 V_SY
        BCTR,UN TSNX
TSSX:   LODA,R0 V_SX
        ADDI,R0 1
        STRA,R0 V_SX
TSNX:   LODA,R0 V_SEG
        ADDI,R0 1
        STRA,R0 V_SEG
        COMA,R0 V_LEN
        BCFA,EQ TS1
        EORZ    R0
        RETC,UN
TSBAD:  LODI,R0 $FF
        RETC,UN

; PLSEED: a random legal layout. Each ship is tried against a board
; carrying only the ships already seeded -- the later ones are still
; NOPLC, so YSHIPR skips them and one repaint serves every attempt.
; Calls five down. Clobbers R0-R3.
PLSEED: LODI,R3 NSHIPS-1        ; clear the slate first
        LODI,R0 NOPLC
PLS1:   STRA,R0 SHIPS,R3
        BDRR,R3 PLS1
        LODI,R0 NOPLC
        STRA,R0 SHIPS
        LODI,R0 0
        STRA,R0 V_CURS
PLS2:   BSTA,UN YBCLR           ; the ships seeded so far
        BSTA,UN YSHIPR
        LODI,R0 200             ; a bounded hunt; the board is roomy
        STRA,R0 V_COL
PLS3:   LODI,R1 2
        BSTA,UN RNDMOD
        COMI,R0 0               ; RNDMOD exits on COMZ R1, so the CC
        BCTR,EQ PLS4            ;   reflects the COMPARE, not the value --
                                ;   branching on it directly seeded every
                                ;   ship vertical
        LODI,R0 100             ; vertical
        BCTR,UN PLS5
PLS4:   LODI,R0 0
PLS5:   STRA,R0 V_BTMP
        LODI,R1 BRDCELL
        BSTA,UN RNDMOD
        ADDA,R0 V_BTMP
        STRA,R0 V_PLC
        BSTA,UN TESTSHP
        BCTR,EQ PLS6
        LODA,R0 V_COL           ; rejected: try again
        SUBI,R0 1
        STRA,R0 V_COL
        BCFA,EQ PLS3
        LODI,R0 0               ; gave up: park it at the origin so the
        STRA,R0 V_PLC           ;   slot is never left NOPLC
PLS6:   LODA,R0 V_CURS
        STRZ    R2
        LODA,R0 V_PLC
        STRA,R0 SHIPS,R2
        LODA,R0 V_CURS
        ADDI,R0 1
        STRA,R0 V_CURS
        COMI,R0 NSHIPS
        BCFA,EQ PLS2
        RETC,UN

; PLHINT: the placement prompt.
; Calls three down. Clobbers R0-R3.
PLHINT: DAT     STATROW,0
        DCOL    ATEXT
        LODI,R1 16
        SETSTR  TPLACE
        BSTA,UN DPRTN
        DAT     FOOTROW,0
        LODI,R1 16
        SETSTR  TPLKEY
        BCTA,UN DPRTN           ; tail call

