; pads.asm -- both hand controllers, the console's buttons and the tone.
;
; Every frame, in the vertical blank: both keypads drawn live (a pressed
; key shows as a solid block), both discs read through the pot
; multiplexer -- vertical on one frame, horizontal on the next, each kept
; -- and the console's START, OPTION and SELECT. Each key plays its own
; tone while it is held. The last key, direction and button stay on the
; bottom rows. No FujiNet: this is the console alone.
;
; Build: ./build.sh pads

        CPU     2650

FRAME   EQU     BKVAR           ; counts frames: bit 0 picks the pot axis
DV1     EQU     BKVAR+1         ; the pots: left disc vertical, horizontal
DH1     EQU     BKVAR+2
DV2     EQU     BKVAR+3         ; right disc
DH2     EQU     BKVAR+4
LASTK   EQU     BKVAR+5         ; the last key's glyph (0: none yet)
ANYK    EQU     BKVAR+6         ; a key is down this frame
LDIR    EQU     BKVAR+8         ; the left disc's direction this frame
BGBASE  EQU     BKBG            ; BGCOL as BKINIT sets it

        ORG     $0000
        BCTA    UN,START        ; cartridge header: jump past the
        DB      $17             ; RETC,UN interrupt guard at $0003

        ORG     $0020
        INCLUDE "fujidisp.inc"
        INCLUDE "fujilib.inc"
        INCLUDE "bookdefs.inc"
        INCLUDE "booklib.inc"

START:  EORZ    R0
        LPSU
        LODI,R0 $02             ; COM=1: logical compares
        LPSL
        BSTA,UN BKINIT
        PUTS    $00, TITLE
        PUTS    $20, THEAD
        PUTS    $80, TDISC
        PUTS    $90, TTONE
        PUTS    $A0, TKEY
        PUTS    $B0, TLDISC
        PUTS    $C0, TLAST
        EORZ    R0
        STRA,R0 FRAME
        STRA,R0 LASTK

; ---- once a frame, in the vertical blank -----------------------------------
MAIN:   TPSU    $80             ; wait for the vertical blank
        BCFR,EQ MAIN
        LODA,R0 FRAME           ; the pots: valid only now
        ANDI,R0 1
        BCFR,EQ MHORZ
        LODA,R0 $19FF           ; mux clear: the vertical axes
        STRA,R0 DV1
        LODA,R0 $19FE
        STRA,R0 DV2
        LODI,R0 BGBASE|$40      ; the next frame reads horizontal
        STRA,R0 BGCOL
        BCTR,UN MKEYS
MHORZ:  LODA,R0 $19FF           ; mux set: the horizontal axes
        STRA,R0 DH1
        LODA,R0 $19FE
        STRA,R0 DH2
        LODI,R0 BGBASE          ; the next frame reads vertical
        STRA,R0 BGCOL
MKEYS:  LODA,R0 FRAME
        ADDI,R0 1
        STRA,R0 FRAME
        BSTA,UN KEYS
        BSTA,UN TONE
        BSTA,UN DISCS
        BSTA,UN PANEL
MWAIT:  TPSU    $80             ; and for it to end
        BCTR,EQ MWAIT
        BCTA,UN MAIN

; ---- the keypads: 24 keys from a table ------------------------------------
; KTAB, 4 bytes a key: the column's offset from $1900, the key's bit, its
; screen cell, its label's glyph.
KEYS:   EORZ    R0
        STRA,R0 ANYK
        LODI,R3 0
KEY1:   LODA,R0 KTAB,R3         ; the column
        STRZ    R1
        LODA,R0 $1900,R1
        ANDA,R0 KTAB+1,R3       ; this key's bit
        STRZ    R2              ; R2: down or not
        LODA,R0 KTAB+2,R3       ; its cell
        STRZ    R1
        LODA,R0 KTAB+3,R3       ; its label
        COMI,R2 0
        BCTR,EQ KEY2            ; up: the label
        STRA,R0 LASTK           ; down: remember it, show a block
        STRA,R0 ANYK
        LODI,R0 GBLOCK
KEY2:   STRA,R0 SCREEN,R1
        ADDI,R3 4
        COMI,R3 24*4
        BCFR,EQ KEY1
        LODA,R0 LASTK           ; the last key, on row 10
        STRA,R0 SCREEN+$AB
        RETC,UN

; ---- the tone: on while a key is down -------------------------------------
; 1/f = 2 (pitch + 1) line periods: pitch 15 is about 490 Hz.
TONE:   LODA,R0 ANYK
        BCTR,EQ TONE1
        ANDI,R0 $1F             ; 0-9, C, E: higher keys, higher notes
        RRL,R0
        STRZ    R1
        LODI,R0 $40
        SUBZ    R1
        STRA,R0 PITCH
        LODI,R0 $0F             ; on, loudest
        BCTR,UN TONE2
TONE1:  EORZ    R0              ; off
TONE2:  STRA,R0 VOLUME
        LODA,R0 PITCH
        LODI,R2 $95-1           ; row 9: the pitch
        BSTA,UN DHEX
        RETC,UN

; ---- the discs: both, live; the left one's last direction ------------------
DISCS:  LODA,R1 DV1
        LODA,R2 DH1
        BSTA,UN DIROF
        STRA,R3 LDIR            ; hold it
        LODI,R2 $85-1           ; row 8, column 5
        BSTA,UN PWORD
        LODA,R1 DV2
        LODA,R2 DH2
        BSTA,UN DIROF
        LODI,R2 $8B-1           ; row 8, column 11
        BSTA,UN PWORD
        LODA,R3 LDIR
        COMI,R3 24              ; centred: keep the last one
        BCTR,EQ DISCS1
        LODI,R2 $BB-1           ; row 11, column 11
        BSTA,UN PWORD
DISCS1: RETC,UN

; DIROF -- R1 = a vertical pot, R2 = a horizontal one: R3 = the word.
; Leaf.
DIROF:  LODI,R3 0               ; up: under $40
        COMI,R1 $40
        BCTR,LT DIROF9
        LODI,R3 6               ; down: over $C0
        COMI,R1 $C0
        BCTR,GT DIROF9
        LODI,R3 12              ; left
        COMI,R2 $40
        BCTR,LT DIROF9
        LODI,R3 18              ; right
        COMI,R2 $C0
        BCTR,GT DIROF9
        LODI,R3 24              ; centred
DIROF9: RETC,UN

; ---- the console's buttons: the last one, on row 12 -------------------------
PANEL:  LODA,R0 $1908
        ANDI,R0 $07
        BCTR,EQ PANEL9
        LODI,R3 30              ; bit 0: START
        TMI,R0  $01
        BCTR,EQ PANEL1
        LODI,R3 37              ; bit 1: OPTION
        TMI,R0  $02
        BCTR,EQ PANEL1
        LODI,R3 44              ; bit 2: SELECT
PANEL1: LODI,R2 $C5-1           ; row 12, column 5
        BSTA,UN PWORD
PANEL9: RETC,UN

; PWORD -- the word at WORDS + R3, up to its NUL, from cell R2 + 1.
; Calls one down (DXLAT). Clobbers R0-R3.
PWORD:  LODA,R0 WORDS,R3        ; a load sets CC
        BCTR,EQ PWORD9
        BSTA,UN DXLAT
        STRA,R0 SCREEN,R2,+
        ADDI,R3 1
        BCTR,UN PWORD
PWORD9: RETC,UN

; five characters a direction (6 bytes with the NUL), six a button
WORDS:  DB      "UP   ",0,"DOWN ",0,"LEFT ",0,"RIGHT",0,"     ",0
        DB      "START ",0,"OPTION",0,"SELECT",0

; column, bit, cell, label: left controller at column 1, right at 9
KTAB:   DB      0,8,$31,$11,  1,8,$33,$12,  2,8,$35,$13   ; 1 2 3
        DB      0,4,$41,$14,  1,4,$43,$15,  2,4,$45,$16   ; 4 5 6
        DB      0,2,$51,$17,  1,2,$53,$18,  2,2,$55,$19   ; 7 8 9
        DB      0,1,$61,$1C,  1,1,$63,$10,  2,1,$65,$1E   ; C 0 E
        DB      4,8,$39,$11,  5,8,$3B,$12,  6,8,$3D,$13
        DB      4,4,$49,$14,  5,4,$4B,$15,  6,4,$4D,$16
        DB      4,2,$59,$17,  5,2,$5B,$18,  6,2,$5D,$19
        DB      4,1,$69,$1C,  5,1,$6B,$10,  6,1,$6D,$1E

TITLE:  DB      "PADS",0
THEAD:  DB      " LEFT    RIGHT",0
TDISC:  DB      "DISC",0
TTONE:  DB      "TONE",0
TKEY:   DB      "LAST KEY",0
TLDISC: DB      "LAST DISC",0
TLAST:  DB      "LAST",0
