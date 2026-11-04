; input.inc -- keypad + two-axis disc, folded into one code space.
;
; Three hardware facts shape this:
;   - FIRE is wired to the SAME line as keypad '2' ($1901 b3): they are
;     electrically indistinguishable. Outside the game screen that wire
;     is SELECT; inside it fires at the cursor.
;   - The P1 disc is an analog pot valid ONLY during vertical blank; read
;     elsewhere it looks like "down". Every scan syncs to a fresh vblank
;     EDGE, which also gives the game loop its frame clock for free: one
;     KEYSCN = one frame.
;   - BOTH disc axes arrive on $19FF; $19F9 bit 6 (the pot mux) selects
;     which -- CLEAR = vertical, SET = horizontal (MAME arcadia_v.cpp
;     case 0x1ff). Battleship needs both, for a cursor on a 10x10 grid.
;
; Reading two axes off one register without breaking edge detection is
; the whole design here. The mux is flipped ONCE PER FRAME and only the
; selected axis is sampled, but BOTH raw values are CACHED (AXV/AXH) and
; the direction is decoded from the cache. Sampling one axis per frame
; and reporting from both means a held direction reads the same every
; frame -- which is what edge detection needs. Setting the mux and then
; waiting a whole frame before the read also gives real 2637 silicon
; time to digitise with the new mux, which a flip-and-read-immediately
; scheme would not.
;
; Codes: 0-9 = the digits, KUP/KDOWN/KLEFT/KRIGHT = disc, KENT = Enter,
; KCLR = Clear, KNONE = nothing. '2' doubles as FIRE. Column bits
; priority-encode through 16-byte tables so a mashed pair cannot alias
; to a third key.

KNONE   EQU     $FF
; The four disc directions are CONTIGUOUS ($80-$83) so the auto-repeat
; gate below is two compares; Enter/Clear sit above them and never repeat.
KUP     EQU     $80
KDOWN   EQU     $81
KLEFT   EQU     $82
KRIGHT  EQU     $83
KENT    EQU     $84
KCLR    EQU     $85

JOYP1   EQU     $19FF           ; P1 pot; the axis depends on BGCOL b6
JOYLO   EQU     $40             ; < this = up / left
JOYHI   EQU     $C0             ; > this = down / right
JOYCTR  EQU     $6F             ; the resting value

RPTDLY  EQU     18              ; frames before a held disc repeats
RPTINT  EQU     4               ; frames between repeats

; WAITVB: wait for the next vertical-blank EDGE (SENSE low then high).
; Leaf. Preserves everything but the PSW condition code.
WAITVB: TPSU    $80
        BCTR,EQ WAITVB          ; still in the previous vblank
WVB1:   TPSU    $80
        BCFR,EQ WVB1            ; wait for the next one to start
        RETC,UN

; KEYRAW: R0 = code of the first control found this frame (KNONE if
; none). Costs exactly one frame. Calls one down (WAITVB).
; Clobbers R0,R1. Updates AXV/AXH, AXSEL.
KEYRAW: LODA,R0 AXSEL           ; arm the mux for the axis we will sample
        BCTR,EQ KRVERT
        LODA,R0 BGCBAS
        IORI,R0 $40             ; mux SET: horizontal
        BCTR,UN KRARM
KRVERT: LODA,R0 BGCBAS          ; mux CLEAR: vertical
KRARM:  STRA,R0 BGCOL
        BSTR,UN WAITVB          ; a whole frame with the mux settled
        LODA,R0 JOYP1
        STRZ    R1
        LODA,R0 AXSEL
        BCTR,EQ KRSTV
        LODZ    R1
        STRA,R0 AXH
        LODI,R0 0               ; alternate for next frame
        BCTR,UN KRSTD
KRSTV:  LODZ    R1
        STRA,R0 AXV
        LODI,R0 1
KRSTD:  STRA,R0 AXSEL
; Decode from the CACHE, not from this frame's sample: vertical wins
; over horizontal so a diagonal push resolves to one axis.
        LODA,R0 AXV
        COMI,R0 JOYLO
        BCTR,LT KRUP
        COMI,R0 JOYHI
        BCTR,GT KRDN
        LODA,R0 AXH
        COMI,R0 JOYLO
        BCTR,LT KRLF
        COMI,R0 JOYHI
        BCTR,GT KRRT
        LODA,R0 $1900           ; b3='1' b2='4' b1='7' b0=Clear
        ANDI,R0 $0F
        BCFR,EQ KRC0
        LODA,R0 $1901           ; b3='2'/FIRE b2='5' b1='8' b0='0'
        ANDI,R0 $0F
        BCFR,EQ KRC1
        LODA,R0 $1902           ; b3='3' b2='6' b1='9' b0=Enter
        ANDI,R0 $0F
        BCFR,EQ KRC2
        LODI,R0 KNONE
        RETC,UN
KRUP:   LODI,R0 KUP
        RETC,UN
KRDN:   LODI,R0 KDOWN
        RETC,UN
KRLF:   LODI,R0 KLEFT
        RETC,UN
KRRT:   LODI,R0 KRIGHT
        RETC,UN
KRC0:   STRZ    R1
        LODA,R0 *PKT0,R1
        RETC,UN
KRC1:   STRZ    R1
        LODA,R0 *PKT1,R1
        RETC,UN
KRC2:   STRZ    R1
        LODA,R0 *PKT2,R1
        RETC,UN


PKT0:   DWBE    KT0             ; the tables live in block 2 (ROM budget)
PKT1:   DWBE    KT1
PKT2:   DWBE    KT2

; KEYSCN: edge-detected KEYRAW -- a control reports once per press, and
; a rocked disc or second key reports without a full release. A HELD
; DISC DIRECTION auto-repeats (RPTDLY then every RPTINT frames): nine
; presses to cross the board would be miserable, and the repeat lives
; here rather than in the targeting loop so every screen gets it.
; Calls two down. Clobbers R0,R1.
KEYSCN: BSTA,UN KEYRAW
        COMA,R0 V_KEY
        BCTR,EQ KSHELD          ; unchanged: held or still idle
        STRA,R0 V_KEY           ; a fresh control: latch and arm the repeat
        STRZ    R1
        LODI,R0 RPTDLY
        STRA,R0 V_RPT
        LODZ    R1
        COMI,R0 KNONE
        BCTR,EQ KSNONE          ; the release edge reports nothing
        RETC,UN
KSHELD: COMI,R0 KUP             ; digits are < $80: never repeat
        BCTR,LT KSNONE
        COMI,R0 KRIGHT          ; KENT/KCLR/KNONE are > $83: never repeat
        BCTR,GT KSNONE
        LODA,R0 V_RPT
        SUBI,R0 1
        STRA,R0 V_RPT
        BCFR,EQ KSNONE
        LODI,R0 RPTINT
        STRA,R0 V_RPT
        LODA,R0 V_KEY           ; the held direction fires again
        RETC,UN
KSNONE: LODI,R0 KNONE
        RETC,UN

; GETKEY: block for a fresh control; R0 = code. Calls three down.
GETKEY: BSTR,UN KEYSCN
        COMI,R0 KNONE
        BCTR,EQ GETKEY
        RETC,UN
