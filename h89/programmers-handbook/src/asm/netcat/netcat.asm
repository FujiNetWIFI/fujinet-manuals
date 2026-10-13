;-----------------------------------------------------------------------------
; NETCAT -- the H89 as a terminal on the network. Opens a connection on
; network unit 1 (a TELNET or TCP devicespec, typed on the command line or
; asked for), then passes keys out and bytes in until the far end hangs up
; or CTRL-] is struck. The H19 is put in ANSI mode for the session, since
; that is what bulletin boards speak, and back in Heath mode after.
;
;   NETCAT N:TELNET://BBS.FOZZTEXX.COM/      or just NETCAT, and answer
;
; One source, two systems:
;   z88dk-z80asm -b -DHDOS -Isrc/asm/inc netcat.asm  ->  NETCAT.ABS (HDOS)
;   z88dk-z80asm -b -DCPM  -Isrc/asm/inc netcat.asm  ->  NETCAT.COM (CP/M)
;
; Copyright (C) 2026 Thomas Cherryhomes
; SPDX-License-Identifier: GPL-3.0-or-later
;-----------------------------------------------------------------------------
INCLUDE "os.inc"
INCLUDE "fujinet.inc"

QUIT_KEY        equ     0x1D            ; CTRL-] ends the session
BUFSZ           equ     512             ; bytes taken from the FujiNet at once
ESC             equ     0x1B

main:
        ld      hl,t_banner
        call    print
        call    card_on                 ; start the card (if nothing has)
        call    card_present
        jp      nz,no_card

;@ex netcat.spec
        call    args                    ; a devicespec on the command line?
        ld      a,(hl)
        or      a
        jr      nz,have_spec
        ld      hl,t_ask                ; no: ask for one
        call    print
        ld      hl,line
        ld      b,120
        call    getline
        ld      a,(hl)
        or      a
        jr      nz,have_spec
        ld      hl,t_default            ; just RETURN: the default
have_spec:
        call    set_spec                ; to spec, with N: in front
;@end
        ld      hl,t_conn
        call    print
        ld      hl,spec
        call    print
        call    crlf

;@ex netcat.open
        ld      hl,spec                 ; open the connection: the payload
        call    strlen                  ;   is the devicespec
        ld      (rq_open+RQ_PLEN),bc
        ld      hl,rq_open
        call    fn_call
        jp      nz,open_failed
;@end
        ld      hl,t_ansi               ; the H19 in ANSI mode
        call    print

;@ex netcat.loop
loop:
        call    conin                   ; a key struck?
        jr      c,poll
        cp      QUIT_KEY
        jr      z,hangup
        ld      (outch),a               ; send it: one byte
        ld      hl,rq_write
        call    fn_call
poll:
        ld      hl,rq_status            ; anything come in?
        call    fn_call
        jr      nz,loop
        ld      hl,(nstat+NS_AVAIL)
        ld      a,h
        or      l
        jr      nz,fetch
        ld      a,(nstat+NS_CONN)       ; nothing: still connected?
        or      a
        jr      nz,loop
        jr      hungup                  ; the far end has gone
fetch:
        ld      de,BUFSZ                ; take what waits, a buffer at most
        or      a
        sbc     hl,de
        add     hl,de
        jr      c,fetch1
        ex      de,hl
fetch1:
        ld      (rq_read+RQ_AUX1),hl    ; the read's length field
        ld      hl,rq_read
        call    fn_call
        jr      nz,loop
        ld      hl,rxbuf                ; BC bytes came: type them
show:
        ld      a,b
        or      c
        jr      z,loop
        ld      a,(hl)
        call    conout
        inc     hl
        dec     bc
        jr      show
;@end

hangup:
hungup:
        ld      hl,t_heath              ; the H19 back in Heath mode
        call    print
;@ex netcat.close
        ld      hl,rq_close             ; and the connection closed
        call    fn_call
;@end
        ld      hl,t_bye
        jp      print

no_card:
        ld      hl,t_nocard
        jp      print
open_failed:
        ld      hl,t_nopen
        jp      print

; HL -> what was typed: copy it to spec, putting "N:" in front unless it
; starts with N: or Nn: already
set_spec:
        ld      de,spec
        ld      a,(hl)
        and     0xDF                    ; upper case
        cp      'N'
        jr      nz,set_n
        inc     hl
        ld      a,(hl)
        dec     hl
        cp      ':'
        jr      z,set_copy
        inc     hl
        inc     hl
        ld      a,(hl)
        dec     hl
        dec     hl
        cp      ':'
        jr      z,set_copy
set_n:
        ld      a,'N'
        ld      (de),a
        inc     de
        ld      a,':'
        ld      (de),a
        inc     de
set_copy:
        ld      a,(hl)
        ld      (de),a
        inc     hl
        inc     de
        or      a
        jr      nz,set_copy
        ret

;@ex netcat.requests
rq_open:                                ; mode 12: read and write; no
        FNREQ   DEV_NETWORK, NET_OPEN, F_A1_A2, 12,0,0,0    ;   translation
        FNBUF   spec, 0, 0, 0
rq_status:
        FNREQ   DEV_NETWORK, NET_STATUS, F_NONE, 0,0,0,0
        FNBUF   0, 0, nstat, 4
rq_read:                                ; length set before each read
        FNREQ   DEV_NETWORK, NET_READ, F_B12, 0,0,0,0
        FNBUF   0, 0, rxbuf, BUFSZ
rq_write:
        FNREQ   DEV_NETWORK, NET_WRITE, F_B12, 1,0,0,0
        FNBUF   outch, 1, 0, 0
rq_close:
        FNREQ   DEV_NETWORK, NET_CLOSE, F_NONE, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end

t_banner:       defm    "NETCAT - the H89 on the network.  CTRL-] hangs up."
                defb    13, 10, 0
t_ask:          defm    "Connect to (RETURN for BBS.FOZZTEXX.COM): "
                defb    0
t_default:      defm    "N:TELNET://BBS.FOZZTEXX.COM/"
                defb    0
t_conn:         defm    "Connecting to "
                defb    0
t_ansi:         defb    ESC, '<', 0                 ; H19: enter ANSI mode
t_heath:        defb    ESC, '[', '?', '2', 'h', 0  ; ANSI: back to Heath mode
t_bye:          defb    13, 10
                defm    "Disconnected."
                defb    13, 10, 0
t_nocard:       defm    "No FujiNet card at 0D0H."
                defb    13, 10, 0
t_nopen:        defm    "The FujiNet could not open that."
                defb    13, 10, 0

outch:          defb    0               ; the key to send
nstat:          defs    4               ; STATUS: waiting (2), connected, error
line:           defs    120             ; what was typed
spec:           defs    124             ; the devicespec
rxbuf:          defs    BUFSZ

INCLUDE "card.inc"
INCLUDE "fujibus.inc"
INCLUDE "con.inc"
INCLUDE "tail.inc"
