; booklib.inc -- what this handbook's programs share: beginning a
; transaction on any device, a two-byte parameter, a transaction that
; waits as long as the cartridge may and checks its reply, printing,
; waiting frames, and the failure screen. Include after fujidisp.inc and
; fujilib.inc (macros before their callers).
;
; RAM: zone A ($18D0-$18EF) belongs to the runtime (FSTRP, DSTRP, the
; boot stub). The book's programs keep their own bytes in zone B, the
; lower screen at $1A00-$1AFF, which nothing shows in 13-line mode.

BKTRY   EQU     $1A00           ; FNGO: sweeps left
BKERR   EQU     $1A01           ; FAIL: the code
DRPOS   EQU     $1A06           ; DREPLY: the first reply byte
DRCNT   EQU     $1A07           ; DREPLY: how many
BKVAR   EQU     $1A08           ; the first byte a program may take

; FNBEGIN dev, cmd, np -- rewind the TX stream and set the device, the
; command and the number of parameters. Clobbers R0,R1,R2.
FNBEGIN MACRO   dev, cmd, np
        LODI,R1 FRDATRS
        LODI,R2 0
        BSTA,UN FNREGWR
        LODI,R1 FRDEVIC
        LODI,R2 (dev)
        BSTA,UN FNREGWR
        LODI,R1 FRCMD
        LODI,R2 (cmd)
        BSTA,UN FNREGWR
        LODI,R1 FRNPARM
        LODI,R2 (np)
        BSTA,UN FNREGWR
        ENDM

; PUTS cell, str -- print a string from a screen cell (row * 16 + column).
; Clobbers R0-R3.
PUTS    MACRO   cell, str
        SETSTR  str
        LODI,R2 ((cell)-1)&$FF
        BSTA,UN DPRINT
        ENDM

; BKINIT -- the display as CONFIG has it: DINIT's 13-line text mode, but
; with 8x16 characters (BGCOL bit 7 clear), so the 13 rows fill the
; picture instead of its top half; then a clear screen. Calls two down
; (DINIT -> DUDCLD). Clobbers R0,R1,R3.
BKBG    EQU     $07             ; BGCOL: 8x16, character colour 0, screen 7
BKINIT: BSTA,UN DINIT
        LODI,R0 BKBG
        STRA,R0 BGCOL
        BSTA,UN DCLS
        RETC,UN

; FNPARW -- append a 2-byte parameter: R2 the low byte, R3 the high.
; Leaf. Clobbers R0,R1.
FNPARW: LODI,R1 2
        LODA,R0 *FTXP,R1        ; size byte
        LODA,R0 *FTXP,R2        ; low
        LODA,R0 *FTXP,R3        ; high
        RETC,UN

; FNTXN -- append the R2 bytes at (FSTRP) to the TX stream, NULs and all
; (R2 = 0: 256). Leaf. Clobbers R0,R1,R2,R3.
FNTXN:  LODI,R3 $FF
FNTXN1: LODA,R0 *FSTRP,R3,+     ; buf[++R3]
        STRZ    R1
        LODA,R0 *FTXP,R1        ; append it
        BDRR,R2 FNTXN1
        RETC,UN

; FNGO -- commit, wait, and check the reply. FNCOMMIT gives up after about
; 6 s, but the cartridge allows a mount 60 s and a network OPEN, STATUS,
; READ or CLOSE 90 s, so on its timeout keep polling the SAME sequence
; number (never write a new one: that would start a second transaction)
; for 15 more sweeps, about 90 s in all. R0 = 0 on an ACK, the cart's
; FNERR, FETIMO, or FCNAK on a NAK; CC is EQ exactly when R0 is 0.
; Calls two down (FNCOMMIT -> FNREGWR). Clobbers R1,R2,R3.
FNGO:   BSTA,UN FNCOMMIT        ; R2 = the SEQ it wrote
        COMI,R0 FETIMO
        BCFR,EQ FNGO4           ; answered, or failed, in time
        LODI,R0 15
        STRA,R0 BKTRY
FNGO1:  LODI,R3 0               ; one sweep: 64K polls of ~90 us
FNGO2:  LODI,R1 0
FNGO3:  NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        LODA,R0 *FACKP
        COMZ    R2
        BCTR,EQ FNGO5           ; the reply is in
        BDRR,R1 FNGO3
        BDRR,R3 FNGO2
        LODA,R0 BKTRY
        SUBI,R0 1
        STRA,R0 BKTRY
        BCFR,EQ FNGO1
        LODI,R0 FETIMO
        RETC,UN
FNGO5:  LODA,R0 *FERRP
FNGO4:  COMI,R0 0
        BCFR,EQ FNGO7           ; the cart's error: return it
        LODA,R0 *FREPP
        COMI,R0 FCACK
        BCTR,EQ FNGO6
        LODI,R0 FCNAK
        RETC,UN
FNGO6:  EORZ    R0
FNGO7:  RETC,UN

; WAITF -- wait R3 frames (R3 = 0: 256). Leaf. Clobbers R3.
WAITF:  TPSU    $80             ; until the vertical blank starts
        BCFR,EQ WAITF
WAITF2: TPSU    $80             ; and until it ends
        BCTR,EQ WAITF2
        BDRR,R3 WAITF
        RETC,UN

; DREPLY -- print DRCNT bytes of the reply window, from index DRPOS, at
; screen cell R2 + 1 (none when DRCNT is 0). Calls one down (DXLAT).
; Clobbers R0-R3.
DREPLY: LODA,R0 DRCNT
        BCTR,EQ DRP2
        LODA,R3 DRPOS
DRP1:   LODA,R0 *FRDP,R3        ; reply[R3]
        BSTA,UN DXLAT
        STRA,R0 SCREEN,R2,+     ; screen[++R2]
        ADDI,R3 1
        LODA,R0 DRCNT
        SUBI,R0 1
        STRA,R0 DRCNT
        BCFR,EQ DRP1
DRP2:   RETC,UN

; FAIL -- branch here (BCTA) with R0 = the code: FAILED and the code on
; the last row, and stop. $FE means no FujiNet cartridge.
FAIL:   STRA,R0 BKERR
        PUTS    $C0, FLSTR
        LODA,R0 BKERR
        BSTA,UN DHEX            ; after the text: DPRINT left R2 there
FAILH:  BCTR,UN FAILH
FLSTR:  DB      "FAILED ",0
FENOCRT EQU     $FE             ; FAIL's code: no FujiNet cartridge
