; sprites.asm -- the 2637 up close: character colours, a block-graphics
; row, the built-in box glyphs, and two sprites with both collision
; registers. No FujiNet.
;
; Sprite 0 runs to and fro along row 7, through a box drawn with glyphs
; $04-$0B, and into sprite 1, parked at column 13. Each frame, in the
; vertical blank, the program reads $19FD (sprite against sprite) and
; $19FC (sprite against character); a bit reads 0 where a collision
; happened in the frame just drawn. The sprites' images are the
; user-defined characters $38 and $39, so this program cannot print
; fujidisp.inc's / and - : those are its slash and dash.
;
; Build: ./build.sh sprites

        CPU     2650

S0Y     EQU     $18F0           ; sprite 0: vertical, horizontal
S0X     EQU     $18F1
S1Y     EQU     $18F2           ; sprite 1
S1X     EQU     $18F3
SPCOL   EQU     $19FB           ; sprites 0 and 1: size, colour
SPHIT   EQU     $19FC           ; sprite against character, low = hit
SSHIT   EQU     $19FD           ; sprite against sprite, low = hit
XLEFT   EQU     43+8*1          ; column 1
XRIGHT  EQU     43+8*14         ; column 14
YROW7   EQU     256-16*7        ; row 7: 16 lines a row
XPOS    EQU     BKVAR           ; sprite 0's horizontal register
STEP    EQU     BKVAR+1         ; +1 or -1

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
        LODI,R3 15              ; rows 2 and 4: colours, blocks
ROWS1:  LODA,R0 COLROW,R3
        STRA,R0 SCREEN+$20,R3
        LODA,R0 BLKROW,R3
        STRA,R0 SCREEN+$40,R3
        BDRR,R3 ROWS1
        LODA,R0 COLROW
        STRA,R0 SCREEN+$20
        LODA,R0 BLKROW
        STRA,R0 SCREEN+$40
        LODI,R3 4               ; rows 6-8: the box, columns 0-4
BOX1:   LODA,R0 BOXTOP,R3
        STRA,R0 SCREEN+$60,R3
        LODA,R0 BOXMID,R3
        STRA,R0 SCREEN+$70,R3
        LODA,R0 BOXBOT,R3
        STRA,R0 SCREEN+$80,R3
        BDRR,R3 BOX1
        LODA,R0 BOXTOP
        STRA,R0 SCREEN+$60
        LODA,R0 BOXMID
        STRA,R0 SCREEN+$70
        LODA,R0 BOXBOT
        STRA,R0 SCREEN+$80
        LODI,R3 15              ; the two images: UDCs $38 and $39
IMG1:   LODA,R0 SPIMG,R3
        STRA,R0 UDC,R3
        BDRR,R3 IMG1
        LODA,R0 SPIMG
        STRA,R0 UDC
        LODI,R0 $0D             ; 8x16 both; sprite 0 yellow, 1 red
        STRA,R0 SPCOL
        LODI,R0 YROW7
        STRA,R0 S0Y
        STRA,R0 S1Y
        LODI,R0 43+8*13         ; sprite 1: column 13
        STRA,R0 S1X
        LODI,R0 XLEFT
        STRA,R0 XPOS
        LODI,R0 1
        STRA,R0 STEP
        PUTS    $A0, TX

; ---- once a frame: move, then read what the frame just drawn hit ----------
MAIN:   TPSU    $80             ; the vertical blank
        BCFR,EQ MAIN
        LODA,R0 XPOS
        STRA,R0 S0X
        LODI,R2 $A2-1           ; row 10: the horizontal register
        BSTA,UN DHEX
        LODA,R0 SSHIT           ; bit 0 low: sprites 0 and 1 met
        ANDI,R0 $01
        BCFR,EQ MAIN1
        PUTS    $B0, TSPR
        BCTR,UN MAIN2
MAIN1:  PUTS    $B0, TBLANK
MAIN2:  LODA,R0 SPHIT           ; bit 0 low: sprite 0 met a character
        ANDI,R0 $01
        BCFR,EQ MAIN3
        PUTS    $C0, TCHR
        BCTR,UN MAIN4
MAIN3:  PUTS    $C0, TBLANK
MAIN4:  LODA,R0 XPOS            ; the next position, turning at the ends
        ADDA,R0 STEP
        STRA,R0 XPOS
        COMI,R0 XRIGHT
        BCTR,EQ MAIN5
        COMI,R0 XLEFT
        BCFR,EQ MAIN6
MAIN5:  LODA,R0 STEP            ; turn: 1 <-> $FF
        EORI,R0 $FE
        STRA,R0 STEP
MAIN6:  TPSU    $80             ; to the end of the blank
        BCTR,EQ MAIN6
        BCTA,UN MAIN

; row 2: the colour bits (6-7) of the same digit, four ways
COLROW: DB      $1C,$28,$25,$28,$2E,$2B,$2C,$00 ; COLOURS
        DB      $11,$51,$91,$D1                  ; 1 in 00 01 10 11
        DB      $00,$00,$00,$00
; row 4: block graphics -- $C0 first turns the row over; each cell's low
; 6 bits are 3 x 2 blocks, top row in bits 0-2
BLKROW: DB      $C0,$3F,$07,$38,$15,$2A,$01,$02
        DB      $04,$08,$10,$20,$3F,$00,$3F,$00
BOXTOP: DB      $09,$04,$04,$04,$08     ; the built-in corners and edges
BOXMID: DB      $07,$00,$00,$00,$05
BOXBOT: DB      $0A,$06,$06,$06,$0B
; sprite 0: a ship; sprite 1: a block with a hole
SPIMG:  DB      %00011000,%00111100,%01111110,%11011011
        DB      %11111111,%00100100,%01011010,%10100101
        DB      %11111111,%10000001,%10111101,%10100101
        DB      %10100101,%10111101,%10000001,%11111111

TITLE:  DB      "SPRITES",0
TX:     DB      "X",0
TSPR:   DB      "SPRITE HIT",0
TCHR:   DB      "BOX HIT",0
TBLANK: DB      "          ",0
