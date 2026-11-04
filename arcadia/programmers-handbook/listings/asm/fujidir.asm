; fujidir.asm -- list a directory on a FujiNet host.
;
; MOUNT_HOST, then OPEN_DIRECTORY with the path (NUL-padded to 256 bytes),
; then READ_DIR_ENTRY until the $7F,$7F end marker or a full screen, each
; name printed straight from the reply window (16 characters at most: the
; row), then CLOSE_DIRECTORY.
;
; Build: ./build.sh fujidir

        CPU     2650

HOSTSL  EQU     0               ; host slot 0: the SD card
MAXLEN  EQU     36              ; never below 36: a folder's '/' needs it
ROW0    EQU     $20             ; the first name: row 2
NROWS   EQU     10              ; rows 2-11
ROWAT   EQU     BKVAR           ; this name's first cell
LEFT    EQU     BKVAR+1         ; rows left

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
        PUTS    $10, PATH
        BSTA,UN FNCHECK
        BCTR,EQ MOUNT
        LODI,R0 FENOCRT
        BCTA,UN FAIL

; ---- mount the host, open the directory -----------------------------------
MOUNT:  FNBEGIN FNDFUJI, FCMHOST, 1
        LODI,R2 HOSTSL
        BSTA,UN FNPARB
        BSTA,UN FNGO
        BCFA,EQ FAIL
        FNBEGIN FNDFUJI, FCODIR, 1
        LODI,R2 HOSTSL
        BSTA,UN FNPARB
        SETFSTR PATH
        BSTA,UN FNPATH          ; the path, NUL-padded to 256
        BSTA,UN FNGO
        BCFA,EQ FAIL

; ---- READ_DIR_ENTRY until $7F,$7F or the screen is full --------------------
        LODI,R0 ROW0
        STRA,R0 ROWAT
        LODI,R0 NROWS
        STRA,R0 LEFT
NEXT:   FNBEGIN FNDFUJI, FCRDIR, 2
        LODI,R2 MAXLEN
        BSTA,UN FNPARB          ; the longest name we take
        LODI,R2 0
        BSTA,UN FNPARB          ; no extra fields (no icons)
        BSTA,UN FNGO
        BCFA,EQ FAIL
        LODA,R0 *FRDP           ; $7F,$7F: the end
        COMI,R0 $7F
        BCFR,EQ SHOW
        LODI,R1 1
        LODA,R0 *FRDP,R1
        COMI,R0 $7F
        BCTA,EQ DONE
SHOW:   LODA,R2 ROWAT           ; the name, 16 characters at most
        SUBI,R2 1
        LODI,R3 $FF
SHOW1:  LODA,R0 *FRDP,R3,+      ; name[++R3]; a load sets CC
        BCTR,EQ SHOW2           ; its NUL
        BSTA,UN DXLAT
        STRA,R0 SCREEN,R2,+
        COMI,R3 15
        BCFR,EQ SHOW1
SHOW2:  LODA,R0 ROWAT
        ADDI,R0 $10
        STRA,R0 ROWAT
        LODA,R0 LEFT
        SUBI,R0 1
        STRA,R0 LEFT
        BCFA,EQ NEXT

; ---- close the directory -------------------------------------------------
DONE:   FNBEGIN FNDFUJI, FCCDIR, 0
        BSTA,UN FNGO
        BCFA,EQ FAIL
        PUTS    $C0, CLOSED
HANG:   BCTR,UN HANG

TITLE:  DB      "FUJIDIR",0
PATH:   DB      "/arcbook/",0
CLOSED: DB      "CLOSED",0
