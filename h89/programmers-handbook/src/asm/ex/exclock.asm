;-----------------------------------------------------------------------------
; EXCLOCK -- the exerciser for the clock (45H): the time in every format
; the clock gives it, in the system time zone and in the alternate one,
; the time zone itself, and setting both zones (and a bad one, which
; the clock takes and quietly throws away).
;
; The book's clock cards are cut from this file: see
; tools/EXERCISERS.md.
;
; Copyright (C) 2026 Thomas Cherryhomes
; SPDX-License-Identifier: GPL-3.0-or-later
;-----------------------------------------------------------------------------
INCLUDE "os.inc"
INCLUDE "fujinet.inc"

main:
        call    card_on

; ---- the time, in the system zone (UTC on the rig) -------------------
        call    ex_m
        defm    "clock.gettime", 0
;@ex clock.gettime
        ld      hl,rq_time              ; day, month, year - 2000, hour,
        call    fn_call                 ;   minute, second
        jr      nz,gt_x
        ld      hl,tbuf
        ld      b,6
gt_1:
        call    pspace                  ; each byte in decimal
        ld      a,(hl)
        call    pdec8
        inc     hl
        djnz    gt_1
gt_x:
;@end
        call    ex_show

        call    ex_m
        defm    "clock.settz_alt2", 0
;@ex clock.settz_alt2
        ld      hl,rq_simple            ; 54H gets the time (the name
        call    fn_call                 ;   lies): century, year, month,
        jr      nz,gs_x                 ;   day, hour, minute, second
        ld      hl,tbuf
        ld      b,7
gs_1:
        call    pspace
        ld      a,(hl)
        call    pdec8
        inc     hl
        djnz    gs_1
gs_x:
;@end
        call    ex_show

        call    ex_m
        defm    "clock.get_simple_hundredths", 0
;@ex clock.get_simple_hundredths
        ld      hl,rq_hund              ; as 54H, and hundredths of a
        call    fn_call                 ;   second in byte 7
        jr      nz,gh_x
        call    pspace
        ld      a,(tbuf+7)
        call    pdec8
gh_x:
;@end
        call    ex_show

        call    ex_m
        defm    "clock.get_prodos", 0
;@ex clock.get_prodos
        ld      hl,rq_prodos            ; ProDOS's date word (yyyyyyym
        call    fn_call                 ;   mmmddddd), minute, hour
;@end
        call    ex_show

        call    ex_m
        defm    "clock.get_sos", 0
;@ex clock.get_sos
        ld      hl,rq_sos               ; Apple III SOS: 18 digits, and
        call    fn_call                 ;   a NUL to end them
        jr      nz,sos_x
        call    crlf
        ld      hl,tbuf
        call    print
sos_x:
;@end
        call    ex_show

        call    ex_m
        defm    "clock.get_iso_local", 0
;@ex clock.get_iso_local
        ld      hl,rq_isol              ; ISO 8601, with the zone's
        call    fn_call                 ;   offset; NUL at the end
        jr      nz,iso_x
        call    crlf
        ld      hl,tbuf
        call    print
iso_x:
;@end
        call    ex_show

        call    ex_m
        defm    "clock.get_iso_utc", 0
;@ex clock.get_iso_utc
        ld      hl,rq_isou              ; ISO 8601 in UTC, always
        call    fn_call
        jr      nz,utc_x
        call    crlf
        ld      hl,tbuf
        call    print
utc_x:
;@end
        call    ex_show

; ---- the system time zone --------------------------------------------
        call    ex_m
        defm    "clock.gettz_len", 0
;@ex clock.gettz_len
        ld      hl,rq_tzlen             ; how long the zone's name is,
        call    fn_call                 ;   its NUL counted
        jr      nz,len_x
        call    crlf
        ld      a,(tbuf)
        call    pdec8
len_x:
;@end
        call    ex_show

        call    ex_m
        defm    "clock.get_general", 0
;@ex clock.get_general
        ld      hl,rq_tz                ; the system zone, with a NUL
        call    fn_call
        jr      nz,tz_x
        call    crlf
        ld      hl,tbuf
        call    print
tz_x:
;@end
        call    ex_show

; ---- the alternate time zone -----------------------------------------
        call    ex_m
        defm    "clock.settz", 0
;@ex clock.settz
        ld      hl,rq_settz             ; set the alternate zone (in RAM
        call    fn_call                 ;   only): US Central time
;@end
        call    ex_show

        call    ex_m
        defm    "clock.gettztime", 0
;@ex clock.gettztime
        ld      hl,rq_tztime            ; the time in the other zone,
        call    fn_call                 ;   laid out as GETTIME's
        jr      nz,tzt_x
        call    crlf
        ld      a,(tbuf+3)              ; the hour, there
        call    pdec8
tzt_x:
;@end
        call    ex_show

        call    ex_m
        defm    "clock.gettime.alt", 0
;@ex clock.gettime.alt
        ld      hl,rq_timea             ; field 1 = the alternate zone
        call    fn_call
        jr      nz,alt_x
        call    crlf
        ld      a,(tbuf+3)              ; the hour, there
        call    pdec8
alt_x:
;@end
        call    ex_show

        call    ex_m
        defm    "clock.settz_alt2.alt", 0
;@ex clock.settz_alt2.alt
        ld      hl,rq_simplea
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "clock.get_simple_hundredths.alt", 0
;@ex clock.get_simple_hundredths.alt
        ld      hl,rq_hunda
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "clock.get_prodos.alt", 0
;@ex clock.get_prodos.alt
        ld      hl,rq_prodosa
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "clock.get_sos.alt", 0
;@ex clock.get_sos.alt
        ld      hl,rq_sosa
        call    fn_call
        jr      nz,sosa_x
        call    crlf
        ld      hl,tbuf
        call    print
sosa_x:
;@end
        call    ex_show

        call    ex_m
        defm    "clock.get_iso_local.alt", 0
;@ex clock.get_iso_local.alt
        ld      hl,rq_isola             ; the offset is -0500 now
        call    fn_call
        jr      nz,isoa_x
        call    crlf
        ld      hl,tbuf
        call    print
isoa_x:
;@end
        call    ex_show

        call    ex_m
        defm    "clock.get_iso_utc.alt", 0
;@ex clock.get_iso_utc.alt
        ld      hl,rq_isoua             ; UTC takes the field and pays
        call    fn_call                 ;   it no mind
        jr      nz,utca_x
        call    crlf
        ld      hl,tbuf
        call    print
utca_x:
;@end
        call    ex_show

; ---- a new system time zone ------------------------------------------
        call    ex_m
        defm    "clock.settz_alt", 0
;@ex clock.settz_alt
        ld      hl,rq_setsys            ; set the system zone: US
        call    fn_call                 ;   Eastern; it is saved
;@end
        call    ex_show

        call    ex_m
        defm    "clock.gettz_len.new", 0
;@ex clock.gettz_len.new
        ld      hl,rq_tzlen
        call    fn_call
        jr      nz,lenn_x
        call    crlf
        ld      a,(tbuf)
        call    pdec8
lenn_x:
;@end
        call    ex_show

        call    ex_m
        defm    "clock.get_general.new", 0
;@ex clock.get_general.new
        ld      hl,rq_tz                ; read it back
        call    fn_call
        jr      nz,tzn_x
        call    crlf
        ld      hl,tbuf
        call    print
tzn_x:
;@end
        call    ex_show

        call    ex_m
        defm    "clock.get_iso_local.new", 0
;@ex clock.get_iso_local.new
        ld      hl,rq_isol              ; field 0: the system zone,
        call    fn_call                 ;   -0400 now
        jr      nz,ison_x
        call    crlf
        ld      hl,tbuf
        call    print
ison_x:
;@end
        call    ex_show

        call    ex_m
        defm    "clock.settz_alt.bad", 0
;@ex clock.settz_alt.bad
        ld      hl,rq_setbad            ; a zone with a RETURN on the
        call    fn_call                 ;   end: ACK, and thrown away
;@end
        call    ex_show

        call    ex_m
        defm    "clock.get_general.kept", 0
;@ex clock.get_general.kept
        ld      hl,rq_tz                ; still US Eastern
        call    fn_call
        jr      nz,tzk_x
        call    crlf
        ld      hl,tbuf
        call    print
tzk_x:
;@end
        call    ex_show

        jp      ex_done

; ---- requests: field 1 = 1 asks for the alternate zone
;@ex clock.gettime
rq_time:
        FNREQ   DEV_CLOCK, APETIME_GETTIME, F_A1, 0,0,0,0
        FNBUF   0, 0, tbuf, 6
;@end
;@ex clock.settz_alt2
rq_simple:
        FNREQ   DEV_CLOCK, APETIME_SETTZ_ALT2, F_A1, 0,0,0,0
        FNBUF   0, 0, tbuf, 7
;@end
;@ex clock.get_simple_hundredths
rq_hund:
        FNREQ   DEV_CLOCK, APETIME_GET_SIMPLE_HUNDREDTHS, F_A1, 0,0,0,0
        FNBUF   0, 0, tbuf, 8
;@end
;@ex clock.get_prodos
rq_prodos:
        FNREQ   DEV_CLOCK, APETIME_GET_PRODOS, F_A1, 0,0,0,0
        FNBUF   0, 0, tbuf, 4
;@end
;@ex clock.get_sos
rq_sos:
        FNREQ   DEV_CLOCK, APETIME_GET_SOS, F_A1, 0,0,0,0
        FNBUF   0, 0, tbuf, 19
;@end
;@ex clock.get_iso_local
rq_isol:
        FNREQ   DEV_CLOCK, APETIME_GET_ISO_LOCAL, F_A1, 0,0,0,0
        FNBUF   0, 0, tbuf, 25
;@end
;@ex clock.get_iso_utc
rq_isou:
        FNREQ   DEV_CLOCK, APETIME_GET_ISO_UTC, F_A1, 0,0,0,0
        FNBUF   0, 0, tbuf, 25
;@end
;@ex clock.gettz_len
rq_tzlen:
        FNREQ   DEV_CLOCK, APETIME_GETTZ_LEN, F_NONE, 0,0,0,0
        FNBUF   0, 0, tbuf, 1
;@end
;@ex clock.get_general
rq_tz:
        FNREQ   DEV_CLOCK, APETIME_GET_GENERAL, F_NONE, 0,0,0,0
        FNBUF   0, 0, tbuf, 64
;@end
;@ex clock.settz
rq_settz:                               ; the zone, a POSIX TZ string
        FNREQ   DEV_CLOCK, APETIME_SETTZ, F_NONE, 0,0,0,0
        FNBUF   p_cst, p_cste-p_cst, 0, 0
p_cst:  defm    "CST6CDT,M3.2.0,M11.1.0"
p_cste:
;@end
;@ex clock.gettztime
rq_tztime:
        FNREQ   DEV_CLOCK, APETIME_GETTZTIME, F_NONE, 0,0,0,0
        FNBUF   0, 0, tbuf, 6
;@end
;@ex clock.gettime.alt
rq_timea:
        FNREQ   DEV_CLOCK, APETIME_GETTIME, F_A1, 1,0,0,0
        FNBUF   0, 0, tbuf, 6
;@end
;@ex clock.settz_alt2.alt
rq_simplea:
        FNREQ   DEV_CLOCK, APETIME_SETTZ_ALT2, F_A1, 1,0,0,0
        FNBUF   0, 0, tbuf, 7
;@end
;@ex clock.get_simple_hundredths.alt
rq_hunda:
        FNREQ   DEV_CLOCK, APETIME_GET_SIMPLE_HUNDREDTHS, F_A1, 1,0,0,0
        FNBUF   0, 0, tbuf, 8
;@end
;@ex clock.get_prodos.alt
rq_prodosa:
        FNREQ   DEV_CLOCK, APETIME_GET_PRODOS, F_A1, 1,0,0,0
        FNBUF   0, 0, tbuf, 4
;@end
;@ex clock.get_sos.alt
rq_sosa:
        FNREQ   DEV_CLOCK, APETIME_GET_SOS, F_A1, 1,0,0,0
        FNBUF   0, 0, tbuf, 19
;@end
;@ex clock.get_iso_local.alt
rq_isola:
        FNREQ   DEV_CLOCK, APETIME_GET_ISO_LOCAL, F_A1, 1,0,0,0
        FNBUF   0, 0, tbuf, 25
;@end
;@ex clock.get_iso_utc.alt
rq_isoua:
        FNREQ   DEV_CLOCK, APETIME_GET_ISO_UTC, F_A1, 1,0,0,0
        FNBUF   0, 0, tbuf, 25
;@end
;@ex clock.settz_alt
rq_setsys:
        FNREQ   DEV_CLOCK, APETIME_SETTZ_ALT, F_NONE, 0,0,0,0
        FNBUF   p_est, p_este-p_est, 0, 0
p_est:  defm    "EST5EDT,M3.2.0,M11.1.0"
p_este:
;@end
;@ex clock.settz_alt.bad
rq_setbad:                              ; only 20H-7EH will do
        FNREQ   DEV_CLOCK, APETIME_SETTZ_ALT, F_NONE, 0,0,0,0
        FNBUF   p_bad, 8, 0, 0
p_bad:  defm    "PST8PDT"
        defb    13
;@end

tbuf:           defs    64              ; the clock's replies

INCLUDE "mark.inc"
INCLUDE "card.inc"
INCLUDE "fujibus.inc"
INCLUDE "con.inc"
INCLUDE "tail.inc"
