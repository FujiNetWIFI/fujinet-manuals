; netget.asm -- fetch a file over HTTP through the N: device, and show it.
;
; OPEN the URL as an HTTP GET; STATUS until the count of bytes waiting is
; not 0 and two readings agree; READ them (at most 192, a screen's worth)
; into the reply window; show them a line at a time (LF ends a row, CR is
; skipped); CLOSE. The URL is the bench's, from build.sh.
;
; Build: ./build.sh netget

        CPU     2650

ROW0    EQU     $20             ; the first row of the file: row 2
NMAX    EQU     192             ; the most we read
NTRIES  EQU     30              ; STATUS readings before giving up
PREVL   EQU     BKVAR           ; the reading before: low, high
PREVH   EQU     BKVAR+1
TRIES   EQU     BKVAR+2
CELL    EQU     BKVAR+3         ; where the next character goes, minus 1
ROWAT   EQU     BKVAR+4         ; this row's first cell

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
        PUTS    $00, TITLE
        BSTA,UN FNCHECK
        BCTR,EQ OPEN
        LODI,R0 FENOCRT
        BCTA,UN FAIL

; ---- OPEN: the URL, as an HTTP GET --------------------------------------
OPEN:   SETFSTR URL
        LODI,R2 NMREAD
        BSTA,UN NOPEN
        BCFA,EQ FAIL

; ---- STATUS until two readings agree, and are not 0 ---------------------
        LODI,R0 $FF
        STRA,R0 PREVL
        STRA,R0 PREVH
        EORZ    R0
        STRA,R0 TRIES
STAT1:  BSTA,UN NSTAT
        BCFA,EQ FAIL
        LODA,R0 NAVL            ; the same as the reading before?
        COMA,R0 PREVL
        BCFR,EQ AGAIN
        LODA,R0 NAVH
        COMA,R0 PREVH
        BCFR,EQ AGAIN
        IORA,R0 NAVL            ; and not 0?
        BCTA,EQ AGAIN
        BCTA,UN READ
AGAIN:  LODA,R0 NAVL            ; this reading is the one before
        STRA,R0 PREVL
        LODA,R0 NAVH
        STRA,R0 PREVH
        LODA,R0 TRIES
        ADDI,R0 1
        STRA,R0 TRIES
        COMI,R0 NTRIES
        BCFR,EQ WAIT
        LODI,R0 FETMOUT         ; it never settled
        BCTA,UN FAIL
WAIT:   LODI,R3 3               ; three frames
        BSTA,UN WAITF
        BCTA,UN STAT1

; ---- READ what is waiting, at most NMAX ----------------------------------
READ:   LODA,R2 NAVL
        LODA,R0 NAVH
        BCFR,EQ RDMAX           ; 256 or more
        LODZ    R2
        COMI,R0 NMAX
        BCTR,LT RDGO            ; under NMAX
RDMAX:  LODI,R2 NMAX
RDGO:   LODI,R3 0
        BSTA,UN NREAD
        BCFA,EQ FAIL

; ---- show it: R3 walks the reply, LF ends a row, CR is skipped -----------
        LODI,R0 ROW0
        STRA,R0 ROWAT
        SUBI,R0 1
        STRA,R0 CELL
        LODI,R3 $FF             ; the reply's index, minus 1
SHOW1:  ADDI,R3 1
        LODZ    R3
        COMA,R0 *FRXLP          ; the reply's length (under 256 here)
        BCTA,EQ CLOSE
        LODA,R0 *FRDP,R3        ; reply[R3]
        COMI,R0 $0D
        BCTR,EQ SHOW1           ; CR: skip it
        COMI,R0 $0A
        BCTR,EQ SHOW2           ; LF: the next row
        BSTA,UN DXLAT           ; ASCII to a glyph (clobbers R1)
        LODA,R2 CELL
        STRA,R0 SCREEN,R2,+     ; screen[++R2]
        STRA,R2 CELL
        BCTR,UN SHOW1
SHOW2:  LODA,R0 ROWAT           ; the next row's first cell
        ADDI,R0 $10
        STRA,R0 ROWAT
        SUBI,R0 1
        STRA,R0 CELL
        BCTR,UN SHOW1

; ---- CLOSE, and say so -----------------------------------------------------
CLOSE:  BSTA,UN NCLOSE
        BCFA,EQ FAIL
        PUTS    $C0, DONE
HANG:   BCTR,UN HANG

URL:    HTTPURL
TITLE:  DB      "NETGET",0
DONE:   DB      "CLOSED",0
