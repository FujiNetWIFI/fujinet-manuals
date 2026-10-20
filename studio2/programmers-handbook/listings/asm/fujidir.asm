; fujidir.asm -- list a directory on a FujiNet
; host.
;
; MOUNT_HOST, then OPEN_DIRECTORY with the path,
; then READ_DIR_ENTRY until the $7F,$7F marker
; (or the screen is full), each name printed
; straight from the reply window, then
; CLOSE_DIRECTORY.

        CPU     1802
        INCLUDE "fujinet.inc"
        INCLUDE "s2macro.inc"
        INCLUDE "s2defs.inc"

HOSTSL  EQU     0               ; slot 0: the SD
NAMELN  EQU     15              ; never 31: icons

        ORG     0400H
        INCLUDE "s2call.inc"
        INCLUDE "fujilib.inc"
        INCLUDE "fujidisp.inc"

        ORG     0C00H
        INCLUDE "booklib.inc"

; ---- mount the host, open the directory ----
        FIT     88
main:   FCALL   d_cls
        PUTS    00H, t_title
        FCALL   fn_chk
        BDF     mount
        LDI     FNENOC
        FJMP    fail
mount:  FNBEGIN FNDEVF, FNCMHST, 1
        LDI     HOSTSL
        FCALL   fn_pb
        GOACK
        FNBEGIN FNDEVF, FNCODIR, 1
        LDI     HOSTSL
        FCALL   fn_pb
        LDR     R8, path        ; exactly 256 bytes
        FCALL   fn_path
        GOACK
        FJMP    list

; ---- one name a call, a row each ----
        FIT     90
list:   LDI     10H
        PLO     RC              ; RC.0: row, column
entry:  FNBEGIN FNDEVF, FNCRDIR, 2
        LDI     NAMELN          ; the longest name
        FCALL   fn_pb
        LDI     0               ; flags
        FCALL   fn_pb
        GOACK
        PEEK    FN_REPLY
        XRI     7FH
        BNZ     show
        PEEK    FN_REPLY+1
        XRI     7FH
        BZ      close           ; $7F,$7F: the end
show:   GLO     RC
        FCALL   d_at
        LDR     R8, 0           ; reply offset 0
        LDI     NAMELN
        FCALL   d_rpl
        GLO     RC
        ADI     10H
        PLO     RC
        XRI     0A0H
        BNZ     entry           ; rows 1-9
close:  FJMP    close1

        FIT     32
close1: FNBEGIN FNDEVF, FNCCDIR, 0
        GOACK
hang:   BR      hang

path:    DB     "/s2book/", 0
t_title: DB     "SD:/S2BOOK/", 0

        S2CLAIM
