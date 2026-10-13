;-----------------------------------------------------------------------------
; NPUT -- copy a file from a disk to the network. Opens the devicespec on
; network unit 1 for writing, sends the file in pieces, and closes the
; channel, which is when an HTTP PUT is really sent.
;
;   NPUT SY1:HELLO.TXT N:HTTP://192.168.1.10/hello.txt      (HDOS)
;   NPUT B:NOTES.TXT N:TNFS://myserver/notes.txt            (CP/M)
;
; HDOS and CP/M know a file's length only in whole sectors (256 bytes) and
; records (128), so the copy is that long: a text file arrives with the
; zeros or CTRL-Zs that fill its last sector or record.
;
; One source, two systems:
;   z88dk-z80asm -b -DHDOS -Isrc/asm/inc nput.asm   ->  NPUT.ABS (HDOS)
;   z88dk-z80asm -b -DCPM  -Isrc/asm/inc nput.asm   ->  NPUT.COM (CP/M)
;
; Copyright (C) 2026 Thomas Cherryhomes
; SPDX-License-Identifier: GPL-3.0-or-later
;-----------------------------------------------------------------------------
INCLUDE "os.inc"
INCLUDE "fujinet.inc"

BUFSZ           equ     512             ; bytes sent to the FujiNet at once

main:
        ld      hl,t_banner
        call    print
        call    card_on
        call    card_present
        jp      nz,no_card

;@ex nput.args
        call    args                    ; NPUT file devicespec
        ld      de,fname
        call    word
        jr      nz,two_words
        ld      hl,t_from               ; none: ask, since CP/M turns a
        call    print                   ;   command line into capitals
        ld      hl,fname
        ld      b,30
        call    getline
        ld      hl,t_to
        call    print
        ld      hl,spec
        ld      b,128
        call    getline
        jr      got_words
two_words:
        ld      de,spec
        call    word
        jp      z,usage
got_words:
        ld      de,spec                 ; N: in front if it is missing
        call    netspec
;@end
        ld      hl,fname                ; the file to send
        call    f_open
        jp      c,no_file

;@ex nput.open
        ld      hl,spec                 ; open it for writing (mode 8),
        call    strlen                  ;   no translation
        ld      (rq_open+RQ_PLEN),bc
        ld      hl,rq_open
        call    fn_call
        jp      nz,no_open
;@end

;@ex nput.loop
copy:
        ld      de,txbuf                ; a piece of the file
        ld      bc,BUFSZ
        call    f_read
        ld      a,b
        or      c
        jr      z,done                  ; the end of the file
        ld      (rq_write+RQ_AUX1),bc   ; the length, as a field
        ld      (rq_write+RQ_PLEN),bc   ;   and of the payload
        push    bc
        ld      hl,rq_write
        call    fn_call
        pop     bc
        jr      nz,net_error
        ld      hl,(total)
        add     hl,bc
        ld      (total),hl
        jr      copy
;@end

;@ex nput.close
done:
        ld      hl,rq_close             ; CLOSE: an HTTP PUT goes now
        call    fn_call
        push    af
        call    f_close
        pop     af
        jr      nz,net_error
;@end
        ld      hl,(total)
        call    pdec16
        ld      hl,t_done
        jp      print

usage:
        ld      hl,t_usage
        jp      print
no_card:
        ld      hl,t_nocard
        jp      print
no_file:
        ld      hl,t_nofile
        jp      print
no_open:
        call    f_close
        ld      hl,t_noopen
        jp      print
net_error:
        ld      hl,rq_close
        call    fn_call
        call    f_close
        ld      hl,t_neterr
        jp      print

;@ex nput.requests
rq_open:
        FNREQ   DEV_NETWORK, NET_OPEN, F_A1_A2, 8,0,0,0
        FNBUF   spec, 0, 0, 0
rq_write:                               ; length set before each write
        FNREQ   DEV_NETWORK, NET_WRITE, F_B12, 0,0,0,0
        FNBUF   txbuf, 0, 0, 0
rq_close:
        FNREQ   DEV_NETWORK, NET_CLOSE, F_NONE, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end

t_banner:       defm    "NPUT - copy a file to the network"
                defb    13, 10, 0
t_from:         defm    "From (file): "
                defb    0
t_to:           defm    "To (devicespec): "
                defb    0
t_usage:        defm    "Usage: NPUT file devicespec"
                defb    13, 10, 0
t_nocard:       defm    "No FujiNet card at 0D0H."
                defb    13, 10, 0
t_nofile:       defm    "Cannot open the file."
                defb    13, 10, 0
t_noopen:       defm    "The FujiNet could not open that."
                defb    13, 10, 0
t_neterr:       defm    "Network error; the copy may be incomplete."
                defb    13, 10, 0
t_done:         defm    " bytes sent."
                defb    13, 10, 0

total:          defw    0
spec:           defs    132             ; the devicespec, room for N:
fname:          defs    32              ; the file
txbuf:          defs    BUFSZ

INCLUDE "words.inc"
INCLUDE "card.inc"
INCLUDE "fujibus.inc"
INCLUDE "con.inc"
INCLUDE "tail.inc"
