; clock.asm -- the time of day, from the
; adapter's clock.
;
; The clock is a device of its own ($45).
; GET_ISO_LOCAL answers with the local time as
; text -- "2026-10-20T10:45:31" and more -- in
; the adapter's time zone, GET_ISO_UTC the same
; in UTC. The date and the time go on the screen
; straight out of the reply window. First the
; adapter's own zone is set with $74 (SETTZ's
; twin: $99 sets the alternate zone instead).

        CPU     1802
        INCLUDE "fujinet.inc"
        INCLUDE "s2macro.inc"
        INCLUDE "s2defs.inc"

CKSETZA EQU     74H             ; the adapter's zone

        ORG     0400H
        INCLUDE "s2call.inc"
        INCLUDE "fujilib.inc"
        INCLUDE "fujidisp.inc"

        ORG     0C00H
        INCLUDE "booklib.inc"

; ASK cmd, rc -- a clock command with no
; parameters; its date and time at rc.
ASK     MACRO   cmd, rc
        FNBEGIN CLKDEV, cmd, 0
        GOACK
        LDI     rc
        FCALL   d_at
        LDR     R8, 0           ; YYYY-MM-DD
        LDI     10
        FCALL   d_rpl
        LDI     rc+10H
        FCALL   d_at
        LDR     R8, 11          ; HH:MM:SS
        LDI     8
        FCALL   d_rpl
        ENDM

        FIT     187
main:   FCALL   d_cls
        PUTS    00H, t_title
        FCALL   fn_chk
        BDF     go
        LDI     FNENOC
        FJMP    fail
go:     FNBEGIN CLKDEV, CKSETZA, 0
        LDR     R8, tz          ; the payload
        FCALL   fn_str
        GOACK
        PUTS    20H, t_local
        ASK     CKISOL, 30H
        PUTS    60H, t_utc
        ASK     CKISOU, 70H
hang:   BR      hang

tz:      DB     "EST5EDT", 0
t_title: DB     "CLOCK", 0
t_local: DB     "LOCAL", 0
t_utc:   DB     "UTC", 0

        S2CLAIM
