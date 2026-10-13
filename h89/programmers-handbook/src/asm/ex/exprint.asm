;-----------------------------------------------------------------------------
; EXPRINT -- the exerciser for the printer (40H): a line of text with
; WRITE, another with PUT, the printer's STATUS, and the ways the
; printer goes wrong: STATUS without its field, WRITE with nothing to
; print, and WRITEs of 256 and 300 bytes, which the firmware counts in
; a byte (more than 320 would overrun its buffer, so none are sent).
;
; What was printed lands in the file PAPER on FujiNet's SD card.
;
; The book's printer cards are cut from this file: see
; tools/EXERCISERS.md.
;
; Copyright (C) 2026 Thomas Cherryhomes
; SPDX-License-Identifier: GPL-3.0-or-later
;-----------------------------------------------------------------------------
INCLUDE "os.inc"
INCLUDE "fujinet.inc"

main:
        call    card_on

        call    ex_m
        defm    "printer.write", 0
;@ex printer.write
        ld      hl,rq_pline             ; one line, RETURN and LINE FEED
        call    fn_call                 ;   and all
;@end
        call    ex_show

        call    ex_m
        defm    "printer.put", 0
;@ex printer.put
        ld      hl,rq_pput              ; PUT is WRITE by another name
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "printer.status", 0
;@ex printer.status
        ld      hl,rq_pstat             ; 4 bytes: 0, a byte nobody set,
        call    fn_call                 ;   the timeout (5), 0
        jr      nz,ps_x
        call    crlf
        ld      hl,pstat
        ld      bc,4
        call    phexs
ps_x:
;@end
        call    ex_show

        call    ex_m
        defm    "printer.status.nofield", 0
;@ex printer.status.nofield
        ld      hl,rq_pstat0            ; STATUS with no field: NAK
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "printer.write.empty", 0
;@ex printer.write.empty
        ld      hl,rq_pnone             ; nothing to print: NAK
        call    fn_call
;@end
        call    ex_show

        ld      hl,t_256                ; 256 bytes: a line, dashes,
        ld      bc,254                  ;   RETURN, LINE FEED
        call    fill
        call    ex_m
        defm    "printer.write.256", 0
;@ex printer.write.256
        ld      hl,rq_p256              ; 256 bytes: ACK, and nothing
        call    fn_call                 ;   printed (256 is 0 in a byte)
;@end
        call    ex_show

        ld      hl,t_44                 ; 300 bytes: a line of 44, then
        ld      bc,298                  ;   dashes, RETURN, LINE FEED
        call    fill
        call    ex_m
        defm    "printer.write.300", 0
;@ex printer.write.300
        ld      hl,rq_p300              ; 300 bytes: ACK, and the first
        call    fn_call                 ;   44 printed (300 - 256)
;@end
        call    ex_show

        jp      ex_done

; big = the text at HL, then dashes up to BC, then RETURN, LINE FEED
fill:
        push    hl
        push    bc
        ld      hl,big
        ld      de,big+1
        ld      bc,299
        ld      (hl),'-'
        ldir
        pop     bc
        ld      hl,big
        add     hl,bc
        ld      (hl),13
        inc     hl
        ld      (hl),10
        pop     hl
        ld      de,big
fill1:
        ld      a,(hl)
        or      a
        ret     z
        ld      (de),a
        inc     hl
        inc     de
        jr      fill1

; ---- requests --------------------------------------------------------
;@ex printer.write
rq_pline:
        FNREQ   DEV_PRINTER, PRINTER_WRITE, F_NONE, 0,0,0,0
        FNBUF   p_line, p_linee-p_line, 0, 0
p_line: defm    "Printed on the H89 through FujiNet."
        defb    13, 10
p_linee:
;@end
;@ex printer.put
rq_pput:
        FNREQ   DEV_PRINTER, PRINTER_PUT, F_NONE, 0,0,0,0
        FNBUF   p_put, p_pute-p_put, 0, 0
p_put:  defm    "And this line went by PUT."
        defb    13, 10
p_pute:
;@end
;@ex printer.status
rq_pstat:                               ; one field: any value, but
        FNREQ   DEV_PRINTER, PRINTER_STATUS, F_A1, 0,0,0,0
        FNBUF   0, 0, pstat, 4          ;   it must be there
;@end
;@ex printer.status.nofield
rq_pstat0:
        FNREQ   DEV_PRINTER, PRINTER_STATUS, F_NONE, 0,0,0,0
        FNBUF   0, 0, pstat, 4
;@end
;@ex printer.write.empty
rq_pnone:
        FNREQ   DEV_PRINTER, PRINTER_WRITE, F_NONE, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex printer.write.256
rq_p256:
        FNREQ   DEV_PRINTER, PRINTER_WRITE, F_NONE, 0,0,0,0
        FNBUF   big, 256, 0, 0
;@end
;@ex printer.write.300
rq_p300:
        FNREQ   DEV_PRINTER, PRINTER_WRITE, F_NONE, 0,0,0,0
        FNBUF   big, 300, 0, 0
;@end

t_256:          defm    "This 256-byte line never reaches the paper."
                defb    0
t_44:           defm    "Of 300 bytes sent, just these 44 print out"
                defb    13, 10, 0
pstat:          defs    4               ; STATUS's reply
big:            defs    300             ; the long lines

INCLUDE "mark.inc"
INCLUDE "card.inc"
INCLUDE "fujibus.inc"
INCLUDE "con.inc"
INCLUDE "tail.inc"
