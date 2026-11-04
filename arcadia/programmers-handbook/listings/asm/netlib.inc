; netlib.inc -- the N: device (N1:, $71), for netget and netcat.
;
; The round trip is OPEN, then STATUS until bytes are waiting, then READ
; them, and CLOSE at the end. Every routine returns R0 = 0 on success
; (CC EQ) and the failure otherwise, as FNGO does. Include after
; booklib.inc and bookdefs.inc.

NAVL    EQU     $1A02           ; STATUS: bytes waiting, low
NAVH    EQU     $1A03           ;   and high
NCON    EQU     $1A04           ;   connected
NDST    EQU     $1A05           ;   device status

; NOPEN -- OPEN the devicespec at (FSTRP), mode R2 (NMREAD for an HTTP
; GET, NMRDWR for TCP), no translation. Calls three down (FNGO; a
; BSTA and RETC, not a tail BCTA, so tools/checkdepth.py counts it).
; Clobbers R0-R3.
NOPEN:  STRA,R2 NDST            ; the mode, until the parameters go
        FNBEGIN DVNET, NCOPEN, 2
        LODA,R2 NDST
        BSTA,UN FNPARB          ; mode
        LODI,R2 NTRNONE
        BSTA,UN FNPARB          ; translation
        BSTA,UN FNTXSTR         ; the devicespec: the payload
        BSTA,UN FNGO
        RETC,UN

; NSTAT -- one STATUS: the four reply bytes into NAVL..NDST.
; Calls three down (FNGO). Clobbers R0-R3.
NSTAT:  FNBEGIN DVNET, NCSTAT, 2
        LODI,R2 0
        BSTA,UN FNPARB
        LODI,R2 0
        BSTA,UN FNPARB
        BSTA,UN FNGO
        BCFR,EQ NSTRET
        LODI,R3 3               ; copy the reply: R0 is the only data
NSTCP:  LODA,R0 *FRDP,R3        ; register an indexed load may use
        STRA,R0 NAVL,R3
        BDRR,R3 NSTCP
        LODA,R0 *FRDP           ; [0]: BDRR stops before it
        STRA,R0 NAVL
        EORZ    R0
NSTRET: RETC,UN

; NREAD -- READ R2 (low) R3 (high) bytes into the reply window; at most
; 1024 fit. Calls three down (FNGO). Clobbers R0-R3.
NREAD:  STRA,R2 NDST            ; the count, until the parameter goes
        STRA,R3 NCON
        FNBEGIN DVNET, NCREAD, 1
        LODA,R2 NDST
        LODA,R3 NCON
        BSTA,UN FNPARW
        BSTA,UN FNGO
        RETC,UN

; NWRITE -- WRITE the R2 bytes at (FSTRP): one 2-byte parameter, the
; count, then the bytes as the payload. Calls three down (FNGO).
; Clobbers R0-R3.
NWRITE: STRA,R2 NDST
        FNBEGIN DVNET, NCWRITE, 1
        LODA,R2 NDST
        LODI,R3 0
        BSTA,UN FNPARW
        LODA,R2 NDST            ; the bytes: the payload
        BSTA,UN FNTXN
        BSTA,UN FNGO
        RETC,UN

; NCLOSE -- CLOSE. Calls three down (FNGO). Clobbers R0-R3.
NCLOSE: FNBEGIN DVNET, NCCLOSE, 0
        BSTA,UN FNGO
        RETC,UN
