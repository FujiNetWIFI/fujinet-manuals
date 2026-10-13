;-----------------------------------------------------------------------------
; EXMODEM -- the exerciser for the modem (50H). The modem is the one
; device that does not answer in frames: its replies, and everything
; it hears from the far end, are bare bytes, and an ACK or a NAK is no
; byte at all. So every request here goes out with fn_send, and what
; comes back is taken with fn_raw.
;
; It sends all ten commands the modem knows, dials the test board on
; 127.0.0.1:7801 with ATDT (in a WRITE, then as bare bytes), shows that
; AT's OK never comes and +++ no longer escapes, and answers a call on
; port 7803. Not sent, because each one stops FujiNet: ATCPM, LISTEN on
; port 0, and the commands whose field is required (SET_DUMP, LISTEN,
; BAUDRATELOCK, AUTOANSWER, STATUS) without it.
;
; The book's modem cards are cut from this file: see
; tools/EXERCISERS.md.
;
; Copyright (C) 2026 Thomas Cherryhomes
; SPDX-License-Identifier: GPL-3.0-or-later
;-----------------------------------------------------------------------------
INCLUDE "os.inc"
INCLUDE "fujinet.inc"

MBUFSZ          equ     512             ; bare bytes taken at once

main:
        call    card_on

; ---- the commands ----------------------------------------------------
        call    ex_m
        defm    "modem.status", 0
;@ex modem.status
        ld      hl,rq_mstat             ; STATUS: two bare bytes come
        call    fn_send                 ;   back, not a frame
        ld      de,mstat
        ld      bc,2
        call    fn_raw                  ; BC = how many came
        call    crlf
        ld      hl,mstat                ; error bits (0), and C0H+0CH
        call    phexs                   ;   when online, +01H with data
;@end
        call    rshow

        call    ex_m
        defm    "modem.stream", 0
;@ex modem.stream
        ld      hl,rq_mstrm             ; STREAM: nine bare bytes, the
        call    fn_send                 ;   Atari POKEY's divisors for
        ld      de,mbuf                 ;   the modem's baud rate
        ld      bc,9
        call    fn_raw
;@end
        call    rshow

        call    ex_m
        defm    "modem.configure", 0
;@ex modem.configure
        ld      hl,rq_mconf             ; CONFIGURE: 9600 baud, whatever
        call    fn_send                 ;   is asked; no reply at all
;@end
        call    quiet

        call    ex_m
        defm    "modem.stream.9600", 0
;@ex modem.stream.9600
        ld      hl,rq_mstrm             ; STREAM again: 9600 baud's
        call    fn_send                 ;   divisors now
        ld      de,mbuf
        ld      bc,9
        call    fn_raw
;@end
        call    rshow

        call    ex_m
        defm    "modem.baudratelock", 0
;@ex modem.baudratelock
        ld      hl,rq_mlock             ; lock the rate at 2400: CONNECT
        call    fn_send                 ;   says 2400 from now on
;@end
        call    quiet

        call    ex_m
        defm    "modem.control", 0
;@ex modem.control
        ld      hl,rq_mctl              ; CONTROL: does nothing on the
        call    fn_send                 ;   H89, and says nothing
;@end
        call    quiet

        call    ex_m
        defm    "modem.set_dump", 0
;@ex modem.set_dump
        ld      hl,rq_mdump             ; the traffic log off (field 0)
        call    fn_send
;@end
        call    quiet

        call    ex_m
        defm    "modem.autoanswer", 0
;@ex modem.autoanswer
        ld      hl,rq_mauto             ; field 0: we answer with ATA
        call    fn_send
;@end
        call    quiet

; ---- AT commands, in WRITE frames ------------------------------------
        call    ex_m
        defm    "modem.write.at", 0
;@ex modem.write.at
        ld      hl,rq_mat               ; AT: the modem takes it, but
        call    fn_send                 ;   its OK is never sent
;@end
        call    quiet

        call    ex_m
        defm    "modem.write", 0
;@ex modem.write
        ld      hl,rq_dial              ; dial the test board, and type
        call    fn_send                 ;   what comes: its greeting,
        call    mtype                   ;   and CONNECT a second later
;@end
        call    tshow

        call    ex_m
        defm    "modem.status.online", 0
;@ex modem.status.online
        ld      hl,rq_mstat             ; online: CCH
        call    fn_send
        ld      de,mstat
        ld      bc,2
        call    fn_raw
;@end
        call    rshow

        call    ex_m
        defm    "modem.write.online", 0
;@ex modem.write.online
        ld      hl,rq_mline             ; online, a WRITE goes to the
        call    fn_send                 ;   far end: the board echoes
        call    mtype                   ;   it, then shouts it back
;@end
        call    tshow

        call    ex_m
        defm    "modem.write.plus", 0
;@ex modem.write.plus
        ld      hl,rq_mplus             ; +++ and a second of quiet: no
        call    fn_send                 ;   OK, it went to the board
        call    mtype
;@end
        call    tshow

        call    ex_m
        defm    "modem.write.ath", 0
;@ex modem.write.ath
        ld      hl,rq_math              ; so ATH is data too: the board
        call    fn_send                 ;   gets it; the call stays up
        call    mtype
;@end
        call    tshow

        call    ex_m
        defm    "modem.write.bye", 0
;@ex modem.write.bye
        ld      hl,rq_mbye              ; the far end must hang up: BYE
        call    fn_send                 ;   to the board; NO CARRIER
        call    mtype
;@end
        call    tshow

; ---- AT commands as bare bytes ---------------------------------------
        call    ex_m
        defm    "modem.write.raw_dial", 0
;@ex modem.write.raw_dial
        ld      hl,p_dial               ; the same ATDT as bare bytes:
        ld      bc,p_diale-p_dial       ;   whatever is not in a frame
        call    rawput                  ;   goes to the modem as typed
        call    mtype
;@end
        call    tshow

        call    ex_m
        defm    "modem.write.raw_bye", 0
;@ex modem.write.raw_bye
        ld      hl,p_bye                ; online, bare bytes go to the
        ld      bc,4                    ;   far end, as WRITE's do
        call    rawput
        call    mtype
;@end
        call    tshow

; ---- a call coming in ------------------------------------------------
        call    ex_m
        defm    "modem.listen", 0
;@ex modem.listen
        ld      hl,rq_mlstn             ; take calls on port 7803: the
        call    fn_send                 ;   rig's helper calls, and the
        ld      de,mbuf                 ;   modem says RING every 3 s
        ld      bc,MBUFSZ
        call    fn_raw
        ld      hl,mbuf
        call    ptext
;@end
        call    rshow

        call    ex_m
        defm    "modem.status.ring", 0
;@ex modem.status.ring
        ld      hl,rq_mstat             ; a caller waits: CDH
        call    fn_send
        ld      de,mstat
        ld      bc,2
        call    fn_raw
;@end
        call    rshow

        call    ex_m
        defm    "modem.write.ata", 0
;@ex modem.write.ata
        ld      hl,rq_mata              ; ATA answers; what the caller
        call    fn_send                 ;   sent (PING) comes through,
        call    mtype                   ;   CONNECT a second later
;@end
        call    tshow

        call    ex_m
        defm    "modem.write.pong", 0
;@ex modem.write.pong
        ld      hl,rq_mpong             ; answer; the caller hangs up:
        call    fn_send                 ;   NO CARRIER
        call    mtype
;@end
        call    tshow

        call    ex_m
        defm    "modem.unlisten", 0
;@ex modem.unlisten
        ld      hl,rq_munl              ; no more calls on 7803
        call    fn_send
;@end
        call    quiet

        jp      ex_done

; ---- never run: each of these stops FujiNet --------------------------
;@ex modem.write.atcpm
        ld      hl,rq_mcpm              ; ATCPM: this build has no CP/M
        call    fn_send                 ;   device, and FujiNet crashes
;@end
;@ex modem.listen.port0
        ld      hl,rq_ml0               ; LISTEN on port 0: a NAK, then
        call    fn_send                 ;   an ACK, and an assert fails
;@end

; ---- the exerciser's reports -----------------------------------------
; quiet: wait 2 s for anything (nothing should come), then report it
quiet:
        ld      de,mbuf
        ld      bc,MBUFSZ
        call    fn_raw
; rshow: "RAW n" and the first bytes, from fn_raw's BC and buffer
rshow:
        call    crlf
        push    bc
        ld      hl,t_raw
        call    print
        pop     bc
        ld      h,b
        ld      l,c
        call    pdec16
        call    pspace
        ld      hl,(fn_rbuf)
        jp      phexs
; tshow: "RAW n", from mtype's count
tshow:
        call    crlf
        push    bc
        ld      hl,t_raw
        call    print
        pop     hl
        jp      pdec16
t_raw:          defm    "RAW "
                defb    0

; ---- typing what comes, sending bare bytes ---------------------------
;@ex modem.write
; mtype: type the modem's bytes as they come, until 2 s pass with
; none. BC = how many came in all.
mtype:
        ld      hl,0
        ld      (mcount),hl
mtype1:
        ld      de,mbuf
        ld      bc,MBUFSZ
        call    fn_raw                  ; until 200 ms pass with none
        ld      a,b
        or      c
        jr      z,mtype2                ; 2 s and nothing: that is all
        ld      hl,(mcount)
        add     hl,bc
        ld      (mcount),hl
        ld      hl,mbuf                 ; type them, the unprintable
        call    ptext                   ;   ones as dots
        jr      mtype1
mtype2:
        ld      bc,(mcount)
        ret
mcount: defw    0
;@end

;@ex modem.write.raw_dial
; rawput: BC bytes from HL to the FujiNet, outside any frame
rawput:
        ld      a,OE_ON
        out     (PCTRL),a
        ld      a,DIR_TO_ESP            ; the 245 toward the ESP32
        out     (PCTRL),a
rawput1:
        in      a,(PORTC)               ; wait till the last byte is
        and     PC_OBF                  ;   taken (/OBF high)
        jr      z,rawput1
        ld      a,b
        or      c
        jr      z,rawput2
        ld      a,(hl)
        out     (PORTA),a
        inc     hl
        dec     bc
        jr      rawput1
rawput2:
        ld      a,DIR_TO_H89            ; and back toward us
        out     (PCTRL),a
        ret
;@end

; ---- requests --------------------------------------------------------
;@ex modem.status
rq_mstat:                               ; the field must be there
        FNREQ   DEV_SERIAL, MODEM_STATUS, F_A1, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex modem.stream
rq_mstrm:
        FNREQ   DEV_SERIAL, MODEM_STREAM, F_NONE, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex modem.configure
rq_mconf:
        FNREQ   DEV_SERIAL, MODEM_CONFIGURE, F_NONE, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex modem.baudratelock
rq_mlock:                               ; lock on, 2400 baud (0960H)
        FNREQ   DEV_SERIAL,MODEM_BAUDRATELOCK,F_B12_B34, 1,0,0x60,0x09
        FNBUF   0, 0, 0, 0
;@end
;@ex modem.control
rq_mctl:
        FNREQ   DEV_SERIAL, MODEM_CONTROL, F_NONE, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex modem.set_dump
rq_mdump:                               ; the field must be there
        FNREQ   DEV_SERIAL, MODEM_SET_DUMP, F_A1, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex modem.autoanswer
rq_mauto:                               ; the field must be there
        FNREQ   DEV_SERIAL, MODEM_AUTOANSWER, F_A1, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex modem.write.at
rq_mat:
        FNREQ   DEV_SERIAL, MODEM_WRITE, F_NONE, 0,0,0,0
        FNBUF   p_at, 3, 0, 0
p_at:   defm    "AT"
        defb    13
;@end
;@ex modem.write
rq_dial:                                ; one AT command a WRITE
        FNREQ   DEV_SERIAL, MODEM_WRITE, F_NONE, 0,0,0,0
        FNBUF   p_dial, p_diale-p_dial, 0, 0
p_dial: defm    "ATDT127.0.0.1:7801"
        defb    13
p_diale:
;@end
;@ex modem.write.online
rq_mline:
        FNREQ   DEV_SERIAL, MODEM_WRITE, F_NONE, 0,0,0,0
        FNBUF   p_line, 6, 0, 0
p_line: defm    "hello"
        defb    13
;@end
;@ex modem.write.plus
rq_mplus:
        FNREQ   DEV_SERIAL, MODEM_WRITE, F_NONE, 0,0,0,0
        FNBUF   p_plus, 3, 0, 0
p_plus: defm    "+++"
;@end
;@ex modem.write.ath
rq_math:
        FNREQ   DEV_SERIAL, MODEM_WRITE, F_NONE, 0,0,0,0
        FNBUF   p_ath, 4, 0, 0
p_ath:  defm    "ATH"
        defb    13
;@end
;@ex modem.write.bye
rq_mbye:
        FNREQ   DEV_SERIAL, MODEM_WRITE, F_NONE, 0,0,0,0
        FNBUF   p_bye, 4, 0, 0
p_bye:  defm    "BYE"
        defb    13
;@end
;@ex modem.listen
rq_mlstn:                               ; port 7803 (1E7BH), a word
        FNREQ   DEV_SERIAL, MODEM_LISTEN, F_B12, 0x7B,0x1E,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex modem.write.ata
rq_mata:                                ; just these 4 bytes: ATA, CR
        FNREQ   DEV_SERIAL, MODEM_WRITE, F_NONE, 0,0,0,0
        FNBUF   p_ata, 4, 0, 0
p_ata:  defm    "ATA"
        defb    13
;@end
;@ex modem.write.pong
rq_mpong:
        FNREQ   DEV_SERIAL, MODEM_WRITE, F_NONE, 0,0,0,0
        FNBUF   p_pong, 6, 0, 0
p_pong: defm    "PONG"
        defb    13, 10
;@end
;@ex modem.unlisten
rq_munl:
        FNREQ   DEV_SERIAL, MODEM_UNLISTEN, F_NONE, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end

;@ex modem.write.atcpm
rq_mcpm:
        FNREQ   DEV_SERIAL, MODEM_WRITE, F_NONE, 0,0,0,0
        FNBUF   p_cpm, 6, 0, 0
p_cpm:  defm    "ATCPM"
        defb    13
;@end
;@ex modem.listen.port0
rq_ml0:
        FNREQ   DEV_SERIAL, MODEM_LISTEN, F_B12, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end

mstat:          defs    2               ; STATUS's two bytes
mbuf:           defs    MBUFSZ          ; bare bytes from the modem

INCLUDE "mark.inc"
INCLUDE "card.inc"
INCLUDE "fujibus.inc"
INCLUDE "con.inc"
INCLUDE "tail.inc"
