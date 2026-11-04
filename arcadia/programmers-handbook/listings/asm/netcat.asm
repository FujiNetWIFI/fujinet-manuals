; netcat.asm -- a TCP line terminal for the Arcadia 2001.
;
; OPEN the bench's line server as N:TCP://, then, once a frame: read the
; left controller, and every sixth frame ask STATUS; whatever is waiting
; is READ and printed in the terminal, rows 0-9, which scrolls. The line
; being typed is row 10; the legend rows 11-12.
;
; The keyboard is a wheel, as an arcade machine takes a high-score name:
; the disc turns the character under the cursor (held, it repeats), the
; Action button types it, CLEAR takes the last one back, ENTER sends the
; line with CR LF, and 0 CLOSEs the connection and stops. The Action
; button is the keypad's 2 (one wire), so the 2 types, too.
;
; Build: ./build.sh netcat

        CPU     2650

TROWS   EQU     10              ; the terminal: rows 0-9
LROW    EQU     $A0             ; row 10: the line being typed
LMAX    EQU     15              ; characters a line
NPOLL   EQU     6               ; frames between STATUS readings
TROW    EQU     BKVAR           ; the terminal's row, column
TCOL    EQU     BKVAR+1
TCH     EQU     BKVAR+2         ; TPUTC: the glyph
WIDX    EQU     BKVAR+3         ; the wheel: which character
LLEN    EQU     BKVAR+4         ; the line's length
HELD    EQU     BKVAR+5         ; frames the disc has been held
PREVK   EQU     BKVAR+6         ; the keys last frame
POLL    EQU     BKVAR+7         ; frames to the next STATUS
RIDX    EQU     BKVAR+8         ; RECV: the reply byte being printed
LBUF    EQU     BKVAR+16        ; the line, then CR LF: 17 bytes
WLEN    EQU     WHEND-WHEEL     ; 45 characters on the wheel

        ORG     $0000
        BCTA    UN,START        ; cartridge header: jump past the
        DB      $17             ; RETC,UN interrupt guard at $0003

        ORG     $0020
        INCLUDE "fujidisp.inc"
        INCLUDE "fujilib.inc"
        INCLUDE "bookdefs.inc"
        INCLUDE "booklib.inc"
        INCLUDE "netlib.inc"
        INCLUDE "bookcfg.inc"

START:  EORZ    R0
        LPSU
        LODI,R0 $02             ; COM=1: logical compares
        LPSL
        BSTA,UN BKINIT
        EORZ    R0
        STRA,R0 TROW
        STRA,R0 TCOL
        STRA,R0 WIDX
        STRA,R0 LLEN
        STRA,R0 HELD
        STRA,R0 PREVK
        STRA,R0 POLL
        PUTS    $B0, LEG1
        PUTS    $C0, LEG2
        BSTA,UN FNCHECK
        BCTR,EQ OPEN
        LODI,R0 FENOCRT
        BCTA,UN FAIL

OPEN:   SETFSTR URL             ; read and write: a TCP connection
        LODI,R2 NMRDWR
        BSTA,UN NOPEN
        BCFA,EQ FAIL
        BSTA,UN LSHOW

; ---- once a frame --------------------------------------------------------
MAIN:   TPSU    $80             ; the vertical blank: the disc is valid
        BCFR,EQ MAIN
        BSTA,UN INPUT
        LODA,R0 POLL
        SUBI,R0 1
        STRA,R0 POLL
        BCFR,GT MAIN1           ; not yet
        BSTA,UN RECV
        LODI,R0 NPOLL
        STRA,R0 POLL
MAIN1:  TPSU    $80
        BCTR,EQ MAIN1
        BCTA,UN MAIN

; ---- the controller: the wheel, and the keys on their edges -----------------
INPUT:  LODA,R0 $19FF           ; the disc, vertical (the mux is clear)
        COMI,R0 $40
        BCTR,LT INUP
        COMI,R0 $C0
        BCTR,GT INDN
        EORZ    R0              ; centred: the next turn is at once
        STRA,R0 HELD
        BCTA,UN INKEYS
INUP:   LODI,R1 WLEN-1          ; up: the character before
        BCTR,UN INTURN
INDN:   LODI,R1 1               ; down: the one after
INTURN: LODA,R0 HELD            ; at once; held, from the 16th frame
        ADDI,R0 1               ; on, every 8th
        STRA,R0 HELD
        COMI,R0 1
        BCTR,EQ INT1
        COMI,R0 16
        BCTA,LT INKEYS
        ANDI,R0 7
        BCFA,EQ INKEYS
INT1:   LODA,R0 WIDX            ; WIDX = (WIDX + R1) mod WLEN
        ADDZ    R1
        COMI,R0 WLEN
        BCTR,LT INT2
        SUBI,R0 WLEN
INT2:   STRA,R0 WIDX
        BSTA,UN LSHOW
INKEYS: LODA,R0 $1901           ; b3: Action (and 2), b0: 0
        ANDI,R0 $09
        STRZ    R1
        LODA,R0 $1900           ; b0: CLEAR
        ANDI,R0 $01
        RRL,R0                  ; to b1
        IORZ    R1
        STRZ    R1
        LODA,R0 $1902           ; b0: ENTER
        ANDI,R0 $01
        RRL,R0
        RRL,R0                  ; to b2
        IORZ    R1
        STRZ    R1              ; R1: the keys now
        LODA,R0 PREVK
        EORI,R0 $FF
        ANDZ    R1              ; R0: the keys just pressed
        STRA,R1 PREVK
        TMI,R0  $08
        BCTA,EQ TYPE
        TMI,R0  $02
        BCTA,EQ DELETE
        TMI,R0  $04
        BCTA,EQ SEND
        TMI,R0  $01
        BCTA,EQ QUIT
        RETC,UN

TYPE:   LODA,R1 LLEN            ; the wheel's character onto the line
        COMI,R1 LMAX
        BCFR,LT TYPE9           ; full
        LODA,R3 WIDX
        LODA,R0 WHEEL,R3
        STRA,R0 LBUF,R1
        ADDI,R1 1
        STRA,R1 LLEN
        BSTA,UN LSHOW
TYPE9:  RETC,UN

DELETE: LODA,R0 LLEN
        BCTR,EQ DEL9
        SUBI,R0 1
        STRA,R0 LLEN
        BSTA,UN LSHOW
DEL9:   RETC,UN

SEND:   LODA,R1 LLEN            ; the line, CR, LF
        LODI,R0 $0D
        STRA,R0 LBUF,R1
        ADDI,R1 1
        LODI,R0 $0A
        STRA,R0 LBUF,R1
        ADDI,R1 1
        LODZ    R1              ; R2: the count
        STRZ    R2
        SETFSTR LBUF
        BSTA,UN NWRITE
        BCFA,EQ FAIL
        EORZ    R0
        STRA,R0 LLEN
        BSTA,UN LSHOW
        RETC,UN

QUIT:   BSTA,UN NCLOSE
        PUTS    $B0, TCLOSED
        PUTS    $C0, TBLANK
QUIT9:  BCTR,UN QUIT9

; LSHOW -- row 10: the line, then the wheel's character in magenta, then
; spaces. Calls one down (DXLAT). Clobbers R0-R3.
LSHOW:  LODI,R3 0
LSH1:   COMA,R3 LLEN
        BCTR,EQ LSH2
        LODA,R0 LBUF,R3
        BSTA,UN DXLAT
        STRA,R0 SCREEN+LROW,R3
        ADDI,R3 1
        BCTR,UN LSH1
LSH2:   LODA,R1 WIDX            ; the candidate
        LODA,R0 WHEEL,R1
        BSTA,UN DXLAT
        IORI,R0 $80             ; colour bits 10: magenta
        STRA,R0 SCREEN+LROW,R3
LSH3:   ADDI,R3 1               ; the rest of the row
        COMI,R3 16
        BCTR,EQ LSH9
        EORZ    R0
        STRA,R0 SCREEN+LROW,R3
        BCTR,UN LSH3
LSH9:   RETC,UN

; ---- receiving: STATUS, then READ what is waiting, then print it -----------
RECV:   BSTA,UN NSTAT
        BCFA,EQ FAIL
        LODA,R0 NAVH
        BCFR,EQ RECV1           ; 256 or more: take 255
        LODA,R2 NAVL
        BCTR,EQ RECV9           ; nothing
        BCTR,UN RECV2
RECV1:  LODI,R2 255
RECV2:  LODI,R3 0
        BSTA,UN NREAD
        BCFA,EQ FAIL
        EORZ    R0
        STRA,R0 RIDX
RECV3:  LODA,R0 RIDX
        COMA,R0 *FRXLP          ; the reply's length (under 256)
        BCTR,EQ RECV9
        STRZ    R3
        LODA,R0 *FRDP,R3        ; reply[RIDX]
        BSTA,UN TPUTC
        LODA,R0 RIDX
        ADDI,R0 1
        STRA,R0 RIDX
        BCTR,UN RECV3
RECV9:  RETC,UN

; TPUTC -- the ASCII character in R0 onto the terminal: CR ignored, LF a
; new line, the rest at the cursor, wrapping at 16. Calls two down
; (TNL -> TSCRL). Clobbers R0-R3.
TPUTC:  COMI,R0 $0D
        BCTR,EQ TPC9
        COMI,R0 $0A
        BCTR,EQ TNL
        BSTA,UN DXLAT           ; to a glyph (clobbers R1)
        STRA,R0 TCH
        LODA,R0 TROW            ; the cell: row * 16 + column
        RRL,R0
        RRL,R0
        RRL,R0
        RRL,R0
        ADDA,R0 TCOL
        STRZ    R1
        LODA,R0 TCH
        STRA,R0 SCREEN,R1
        LODA,R0 TCOL
        ADDI,R0 1
        STRA,R0 TCOL
        COMI,R0 16
        BCTR,EQ TNL             ; wrap
TPC9:   RETC,UN
TNL:    EORZ    R0              ; a new line: column 0, the next row
        STRA,R0 TCOL
        LODA,R0 TROW
        ADDI,R0 1
        COMI,R0 TROWS
        BCTR,LT TNL1
        BSTA,UN TSCRL           ; off the bottom: scroll, stay on row 9
        LODI,R0 TROWS-1
TNL1:   STRA,R0 TROW
        RETC,UN

; TSCRL -- rows 1-9 up one, row 9 cleared. Leaf. Clobbers R0,R3.
TSCRL:  LODI,R3 0
TSC1:   LODA,R0 SCREEN+16,R3
        STRA,R0 SCREEN,R3
        ADDI,R3 1
        COMI,R3 16*(TROWS-1)
        BCFR,EQ TSC1
TSC2:   EORZ    R0
        STRA,R0 SCREEN,R3
        ADDI,R3 1
        COMI,R3 16*TROWS
        BCFR,EQ TSC2
        RETC,UN

URL:    NCURL
WHEEL:  DB      "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,+$/-_:"
WHEND:
LEG1:   DB      "DISC PICK 2 TYPE",0
LEG2:   DB      "CLR DEL ENT SEND",0
TCLOSED: DB     "CLOSED",0
TBLANK: DB      "                ",0
