;-----------------------------------------------------------------------------
; NGET -- copy a file from the network to a disk. Opens the devicespec on
; network unit 1 for reading, and writes whatever comes to the file, until
; the FujiNet says the end has been reached.
;
;   NGET N:HTTP://192.168.1.10/hello.txt SY1:HELLO.TXT      (HDOS)
;   NGET N:TNFS://tnfs.fujinet.online/README.TXT B:README.TXT  (CP/M)
;
; Any scheme a channel can read will do (Chapter 11). HDOS and CP/M keep
; files in whole sectors (256 bytes) and records (128), so the copy ends
; with up to a sector of zeros, or a record of CTRL-Z, after the data.
;
; One source, two systems:
;   z88dk-z80asm -b -DHDOS -Isrc/asm/inc nget.asm   ->  NGET.ABS (HDOS)
;   z88dk-z80asm -b -DCPM  -Isrc/asm/inc nget.asm   ->  NGET.COM (CP/M)
;
; Copyright (C) 2026 Thomas Cherryhomes
; SPDX-License-Identifier: GPL-3.0-or-later
;-----------------------------------------------------------------------------
INCLUDE "os.inc"
INCLUDE "fujinet.inc"

BUFSZ           equ     512             ; bytes taken from the FujiNet at once
EOF_ERR         equ     136             ; STATUS error: the end of the data
WAIT_SECS       equ     30              ; give up after this long with nothing

main:
        ld      hl,t_banner
        call    print
        call    card_on
        call    card_present
        jp      nz,no_card

;@ex nget.args
        call    args                    ; NGET devicespec file
        ld      de,spec
        call    word
        jr      nz,two_words
        ld      hl,t_from               ; none: ask, since CP/M turns a
        call    print                   ;   command line into capitals
        ld      hl,spec
        ld      b,128
        call    getline
        ld      hl,t_to
        call    print
        ld      hl,fname
        ld      b,30
        call    getline
        jr      got_words
two_words:
        ld      de,fname
        call    word
        jp      z,usage
got_words:
        ld      de,spec                 ; N: in front if it is missing
        call    netspec
;@end

;@ex nget.open
        ld      hl,spec                 ; open it for reading (mode 4),
        call    strlen                  ;   no translation
        ld      (rq_open+RQ_PLEN),bc
        ld      hl,rq_open
        call    fn_call
        jp      nz,no_open
;@end
        ld      hl,fname                ; and the file to write
        call    f_create
        jp      c,no_file

;@ex nget.loop
        ld      hl,(TICKS)              ; when data last came
        ld      (t_last),hl
copy:
        ld      hl,rq_status            ; how much is waiting?
        call    fn_call
        jp      nz,net_error
        ld      hl,(nstat+NS_AVAIL)
        ld      a,h
        or      l
        jr      nz,fetch
        ld      a,(nstat+NS_ERR)        ; nothing: the end?
        cp      EOF_ERR
        jr      z,done
        cp      2                       ; an error (1 is all well)
        jp      nc,net_error
        ld      a,(nstat+NS_CONN)       ; the far end gone, nothing left
        or      a
        jr      z,done
        ld      hl,(TICKS)              ; still waiting: for too long?
        ld      de,(t_last)
        or      a
        sbc     hl,de
        ld      de,WAIT_SECS*500
        or      a
        sbc     hl,de
        jr      c,copy
        jp      timed_out
fetch:
        ld      de,BUFSZ                ; never ask for more than waits
        or      a
        sbc     hl,de
        add     hl,de
        jr      c,fetch1
        ex      de,hl
fetch1:
        ld      (rq_read+RQ_AUX1),hl
        ld      hl,rq_read
        call    fn_call
        jp      nz,net_error
        push    bc                      ; BC bytes came: to the file
        ld      de,rxbuf
        call    f_write
        pop     bc
        jp      c,write_error
        ld      hl,(total)              ; count them
        add     hl,bc
        ld      (total),hl
        ld      hl,(TICKS)
        ld      (t_last),hl
        jr      copy
;@end

done:
        call    finish
        ld      hl,(total)
        call    pdec16
        ld      hl,t_done
        jp      print

; close the channel and the file, whatever happened
;@ex nget.close
finish:
        ld      hl,rq_close
        call    fn_call
        jp      f_close
;@end

usage:
        ld      hl,t_usage
        jp      print
no_card:
        ld      hl,t_nocard
        jp      print
no_open:
        ld      hl,t_noopen
        jp      print
no_file:
        ld      hl,rq_close
        call    fn_call
        ld      hl,t_nofile
        jp      print
net_error:
        call    finish
        ld      hl,t_neterr
        call    print
        ld      a,(nstat+NS_ERR)
        call    pdec8
        jp      crlf
write_error:
        call    finish
        ld      hl,t_wrerr
        jp      print
timed_out:
        call    finish
        ld      hl,t_tmo
        jp      print

;@ex nget.requests
rq_open:
        FNREQ   DEV_NETWORK, NET_OPEN, F_A1_A2, 4,0,0,0
        FNBUF   spec, 0, 0, 0
rq_status:
        FNREQ   DEV_NETWORK, NET_STATUS, F_NONE, 0,0,0,0
        FNBUF   0, 0, nstat, 4
rq_read:
        FNREQ   DEV_NETWORK, NET_READ, F_B12, 0,0,0,0
        FNBUF   0, 0, rxbuf, BUFSZ
rq_close:
        FNREQ   DEV_NETWORK, NET_CLOSE, F_NONE, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end

t_banner:       defm    "NGET - copy a file from the network"
                defb    13, 10, 0
t_from:         defm    "From (devicespec): "
                defb    0
t_to:           defm    "To (file): "
                defb    0
t_usage:        defm    "Usage: NGET devicespec file"
                defb    13, 10, 0
t_nocard:       defm    "No FujiNet card at 0D0H."
                defb    13, 10, 0
t_noopen:       defm    "The FujiNet could not open that."
                defb    13, 10, 0
t_nofile:       defm    "Cannot create the file."
                defb    13, 10, 0
t_neterr:       defm    "Network error "
                defb    0
t_wrerr:        defm    "Cannot write the file (disk full?)."
                defb    13, 10, 0
t_tmo:          defm    "Nothing came for 30 seconds; stopped."
                defb    13, 10, 0
t_done:         defm    " bytes copied."
                defb    13, 10, 0

total:          defw    0
t_last:         defw    0
nstat:          defs    4               ; STATUS: waiting (2), connected, error
spec:           defs    132             ; the devicespec, room for N:
fname:          defs    32              ; the file
rxbuf:          defs    BUFSZ

INCLUDE "words.inc"
INCLUDE "card.inc"
INCLUDE "fujibus.inc"
INCLUDE "con.inc"
INCLUDE "tail.inc"
