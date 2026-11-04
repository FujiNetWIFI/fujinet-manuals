; appkey.asm -- read the shared FujiNet player name, then write a key of
; our own and read it back.
;
; An app key is a small file on the adapter's memory card, named by a
; creator, an app and a key number. Creator 1, app 1, key 0 holds the
; player's name, which every FujiNet game reads. Ours is creator $2650,
; app $FF (this handbook's scratch key), key 0.
;
; OPEN_APPKEY's payload is one six-byte struct: the creator (low first),
; the app, the key, the mode and a reserved 0. READ_APPKEY's reply is a
; two-byte length, then the value. WRITE_APPKEY takes one parameter, the
; length, then the bytes.
;
; Build: ./build.sh appkey

        CPU     2650

OURCRE  EQU     $2650
OURAPP  EQU     $FF
OURKEY  EQU     0

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

GO:     PUTS    $20, TNAME      ; the player's name
        SETFSTR KNAME
        BSTA,UN AKOPEN
        BSTA,UN AKREAD
        LODI,R2 $30-1
        BSTA,UN AKSHOW
        PUTS    $60, TOURS      ; ours: write it...
        SETFSTR KOURW
        BSTA,UN AKOPEN
        BSTA,UN AKWRIT
        SETFSTR KOURR           ; ...and read it back
        BSTA,UN AKOPEN
        BSTA,UN AKREAD
        LODI,R2 $70-1
        BSTA,UN AKSHOW
HANG:   BCTR,UN HANG

; AKOPEN -- OPEN_APPKEY: no parameters, the six-byte struct at (FSTRP)
; as the payload. Calls three down (FNGO).
AKOPEN: FNBEGIN FNDFUJI, FCAKOP, 0
        LODI,R2 6
        BSTA,UN FNTXN
        BSTA,UN FNGO
        BCFA,EQ FAIL
        RETC,UN

; AKREAD -- READ_APPKEY: the value is left in the reply window after its
; two-byte length. Calls three down (FNGO).
AKREAD: FNBEGIN FNDFUJI, FCAKRD, 0
        BSTA,UN FNGO
        BCFA,EQ FAIL
        RETC,UN

; AKWRIT -- WRITE_APPKEY: the length as the parameter, then the value.
; Calls three down (FNGO).
AKWRIT: FNBEGIN FNDFUJI, FCAKWR, 1
        LODI,R2 VALLEN
        BSTA,UN FNPARB
        SETFSTR VALUE
        LODI,R2 VALLEN
        BSTA,UN FNTXN
        BSTA,UN FNGO
        BCFA,EQ FAIL
        RETC,UN

; AKSHOW -- the value just read, at cell R2 + 1; EMPTY when there is none.
; Calls two down (DREPLY -> DXLAT).
AKSHOW: LODA,R0 *FRDP           ; the length, under 16 here
        STRA,R0 DRCNT
        BCTR,EQ AKSHW1
        LODI,R0 2               ; after the length
        STRA,R0 DRPOS
        BSTA,UN DREPLY
        RETC,UN
AKSHW1: SETSTR  TEMPTY
        BSTA,UN DPRINT
        RETC,UN

KNAME:  DB      AKCREAT&$FF, AKCREAT>>8, AKAPP, AKKEY, AKMREAD, 0
KOURW:  DB      OURCRE&$FF, OURCRE>>8, OURAPP, OURKEY, AKMWRIT, 0
KOURR:  DB      OURCRE&$FF, OURCRE>>8, OURAPP, OURKEY, AKMREAD, 0
VALUE:  DB      "HELLO ARCADIA"
VALLEN  EQU     $-VALUE
TITLE:  DB      "APP KEYS",0
TNAME:  DB      "PLAYER NAME",0
TOURS:  DB      "OURS, READ BACK",0
TEMPTY: DB      "EMPTY",0
