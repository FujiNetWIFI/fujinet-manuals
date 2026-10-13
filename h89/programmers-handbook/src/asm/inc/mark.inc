;-----------------------------------------------------------------------------
; mark.inc -- the exerciser programs' markers and reports.
;
;   ex_mark  HL -> an example's name, NUL-terminated. Prints "@ex name" and
;            sends it to device 0FH, which the firmware does not have: it
;            answers NAK and does nothing, but the frame stands in the bus
;            log, so every exchange after it belongs to that example.
;   ex_m     the same, with the name in line after the call:
;                    call ex_m
;                    defm "fuji.get_ssid", 0
;   ex_show  after fn_call: prints the result, the reply's length and its
;            first bytes (from fn_res, fn_len). Keeps every register.
;   ex_done  prints "@done".
;
; Copyright (C) 2026 Thomas Cherryhomes
; SPDX-License-Identifier: GPL-3.0-or-later
;-----------------------------------------------------------------------------

MARK_DEV        equ     0x0F

ex_mark:
        push    hl
        call    crlf
        ld      a,'@'
        call    conout
        ld      a,'e'
        call    conout
        ld      a,'x'
        call    conout
        call    pspace
        call    print
        pop     hl
        ld      (ex_rq+7),hl            ; the name is the marker's payload
        ld      bc,0
ex_mark1:
        ld      a,(hl)
        or      a
        jr      z,ex_mark2
        inc     hl
        inc     bc
        jr      ex_mark1
ex_mark2:
        ld      (ex_rq+9),bc
        ld      hl,ex_rq
        jp      fn_call
ex_rq:
        FNREQ   MARK_DEV, 0x00, F_NONE, 0,0,0,0
        FNBUF   0, 0, ex_junk, 8
ex_junk:        defs    8

ex_m:
        pop     hl                      ; HL -> the name, after the call
        push    hl
        call    ex_mark
        pop     hl
ex_m1:
        ld      a,(hl)                  ; return past the name's NUL
        inc     hl
        or      a
        jr      nz,ex_m1
        jp      (hl)

ex_show:
        push    af
        push    bc
        push    de
        push    hl
        call    crlf
        ld      a,(fn_res)              ; ACK, NAK, TMO or BAD
        add     a,a
        add     a,a
        ld      e,a
        ld      d,0
        ld      hl,ex_rnames
        add     hl,de
        ld      b,4
ex_show1:
        ld      a,(hl)
        call    conout
        inc     hl
        djnz    ex_show1
        ld      hl,(fn_len)             ; the reply's length
        call    pdec16
        call    pspace
        ld      bc,(fn_len)             ; and its first bytes
        ld      hl,(fn_rbuf)
        call    phexs
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret
ex_rnames:      defm    "ACK NAK TMO BAD "

ex_done:
        call    crlf
        ld      hl,ex_dtext
        call    print
        jp      crlf
ex_dtext:       defm    "@done"
                defb    0
