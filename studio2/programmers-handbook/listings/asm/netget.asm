; netget.asm -- fetch a file over HTTP through
; the N: device, and show it.
;
; OPEN the URL as an HTTP GET; STATUS until the
; byte count settles; READ it into the reply
; window; show it a line at a time (LF ends a
; row, CR is skipped); CLOSE. The URL is the
; bench's, from build.sh.

        CPU     1802
        INCLUDE "fujinet.inc"
        INCLUDE "s2macro.inc"
        INCLUDE "s2defs.inc"
        INCLUDE "bookcfg.inc"

NMAX    EQU     128             ; the most we read
ROW0    EQU     2               ; the first row
NTRIES  EQU     30              ; STATUS readings
V_AV    EQU     V_APP           ; waiting: lo, hi
V_PREV  EQU     V_APP+2         ; the reading before
V_TRY   EQU     V_APP+4         ; readings so far

        ORG     0400H
        INCLUDE "s2call.inc"
        INCLUDE "fujilib.inc"
        INCLUDE "fujidisp.inc"

        ORG     0C00H
        INCLUDE "booklib.inc"

; ---- OPEN: mode and translation, then the URL --
        FIT     77
main:   FCALL   d_cls
        PUTS    00H, t_title
        FCALL   fn_chk
        BDF     open
        LDI     FNENOC
        FJMP    fail
open:   FNBEGIN NETDEV, NCOPEN, 2
        LDI     NMREAD
        FCALL   fn_pb
        LDI     NTRNONE
        FCALL   fn_pb
        LDR     R8, url
        FCALL   fn_str
        SLOW    95              ; past the cart's 90
        GOACK
        FJMP    status

; ---- STATUS until two readings agree, not 0 ----
        FIT     154
status: LDR     R8, V_PREV
        LDI     0FFH
        STR     R8
        INC     R8
        STR     R8
        INC     R8
        LDI     0
        STR     R8              ; V_TRY
stat1:  FNBEGIN NETDEV, NCSTAT, 2
        LDI     0
        FCALL   fn_pb
        LDI     0
        FCALL   fn_pb
        SLOW    95
        GOACK
        LDR     RA, V_AV        ; RA: AV, then PREV
        PEEK    FN_REPLY+NSAVLO
        STR     RA
        INC     RA
        PEEK    FN_REPLY+NSAVHI
        STR     RA
        DEC     RA
        LDR     RB, V_PREV
        SEX     RB
        LDA     RA              ; AV lo = PREV lo?
        XOR
        PHI     RC
        INC     RB
        LDN     RA              ; AV hi = PREV hi?
        XOR
        SEX     R2
        STR     R2
        GHI     RC
        OR
        BNZ     again           ; changed
        DEC     RA              ; RA = V_AV
        LDA     RA
        STR     R2
        LDN     RA
        OR                      ; lo | hi: 0 or not
        BNZ     read
again:  LDR     RA, V_AV        ; PREV = AV
        LDR     RB, V_PREV
        LDA     RA
        STR     RB
        INC     RB
        LDA     RA
        STR     RB
        INC     RB
        LDN     RB              ; V_TRY + 1
        ADI     1
        STR     RB
        XRI     NTRIES
        BNZ     wait
        LDI     FNEWAIT
        FJMP    fail
wait:   LDI     3               ; three frames
        FCALL   pause
        BR      stat1
read:   FJMP    read1

; ---- READ: one two-byte count, at most NMAX ----
        FIT     65
read1:  LDR     RA, V_AV
        LDA     RA
        PLO     R8              ; R8 = the count
        LDN     RA
        PHI     R8
        BNZ     rd1             ; 256 or more
        GLO     R8
        SMI     NMAX+1
        BNF     rd2             ; under NMAX + 1
rd1:    LDR     R8, NMAX
rd2:    GLO     R8              ; fn_beg uses R8
        PLO     RA
        GHI     R8
        PHI     RA
        FNBEGIN NETDEV, NCREAD, 1
        GLO     RA
        PLO     R8
        GHI     RA
        PHI     R8
        FCALL   fn_pw
        SLOW    95
        GOACK
        FJMP    show

; ---- show it: RA walks the reply, RB.0 counts --
        FIT     64
show:   LDR     RA, FN_REPLY
        PEEK    FN_RXLEN        ; under 256
        PLO     RB
        LDI     ROW0*10H
        PLO     RC              ; RC.0: this row
        FCALL   d_at
shw1:   GLO     RB
        BZ      close
        DEC     RB
        LDA     RA
        XRI     0DH
        BZ      shw1            ; CR: skip it
        XRI     0DH ! 0AH
        BZ      shw2            ; LF: the next row
        XRI     0AH
        FCALL   d_putc
        BR      shw1
shw2:   GLO     RC
        ADI     10H
        PLO     RC
        FCALL   d_at
        BR      shw1
close:  FJMP    close1

; ---- CLOSE, and say so ----
        FIT     43
close1: FNBEGIN NETDEV, NCCLOSE, 0
        GOACK
        PUTS    90H, t_done
hang:   BR      hang

url:     HTTP_URL
t_title: DB     "NETGET", 0
t_done:  DB     "CLOSED", 0

        S2CLAIM
