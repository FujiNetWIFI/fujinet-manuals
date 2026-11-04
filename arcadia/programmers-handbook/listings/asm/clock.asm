; clock.asm -- the time of day, from the adapter's clock.
;
; The clock is a device of its own ($45). GET_ISO_LOCAL answers with the
; local time as text -- "2026-11-03T10:45:31" and more -- in the adapter's
; time zone, GET_ISO_UTC the same in UTC. The date and the time go on the
; screen straight out of the reply window. First the adapter's own zone
; is set with SETTZ_ALT ($74; SETTZ, $99, sets the alternate zone).
;
; Build: ./build.sh clock

        CPU     2650

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
        BSTA,UN FNCHECK
        BCTR,EQ GO
        LODI,R0 FENOCRT
        BCTA,UN FAIL

GO:     FNBEGIN DVCLOCK, CKSETTA, 0
        SETFSTR TZONE           ; the zone: the payload
        BSTA,UN FNTXSTR
        BSTA,UN FNGO
        BCFA,EQ FAIL
        PUTS    $20, TLOCAL
        LODI,R1 CKISOL
        LODI,R2 $30-1
        BSTA,UN ASK
        PUTS    $70, TUTC
        LODI,R1 CKISOU
        LODI,R2 $80-1
        BSTA,UN ASK
HANG:   BCTR,UN HANG

; ASK -- clock command R1, no parameters; the date at cell R2 + 1 and the
; time on the row under it. Calls three down (FNGO).
ASK:    STRA,R1 BKVAR           ; hold them across the transaction
        STRA,R2 BKVAR+1
        LODI,R1 FRDATRS
        LODI,R2 0
        BSTA,UN FNREGWR
        LODI,R1 FRDEVIC
        LODI,R2 DVCLOCK
        BSTA,UN FNREGWR
        LODI,R1 FRCMD
        LODA,R2 BKVAR
        BSTA,UN FNREGWR
        LODI,R1 FRNPARM
        LODI,R2 0
        BSTA,UN FNREGWR
        BSTA,UN FNGO
        BCFA,EQ FAIL
        EORZ    R0              ; YYYY-MM-DD: reply[0..9]
        STRA,R0 DRPOS
        LODI,R0 10
        STRA,R0 DRCNT
        LODA,R2 BKVAR+1
        BSTA,UN DREPLY
        LODI,R0 11              ; HH:MM:SS: reply[11..18]
        STRA,R0 DRPOS
        LODI,R0 8
        STRA,R0 DRCNT
        LODA,R2 BKVAR+1
        ADDI,R2 $10
        BSTA,UN DREPLY
        RETC,UN

TZONE:  DB      "EST5EDT",0
TITLE:  DB      "CLOCK",0
TLOCAL: DB      "LOCAL",0
TUTC:   DB      "UTC",0
