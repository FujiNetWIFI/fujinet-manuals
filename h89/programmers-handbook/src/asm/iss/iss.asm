;-----------------------------------------------------------------------------
; ISS -- where is the International Space Station? Asks a web service for
; the station's position and the people in space, both as JSON, has the
; FujiNet's JSON parser pick out the values, and plots the station on a map
; of the world drawn on the H19, every 30 seconds until ESC is struck.
;
;   ISS                                  api.open-notify.org
;   ISS N:HTTP://192.168.1.10/           a server of your own, which has
;                                        iss-now.json and astros.json
;
; One source, two systems:
;   z88dk-z80asm -b -DHDOS -Isrc/asm/inc iss.asm   ->  ISS.ABS (HDOS)
;   z88dk-z80asm -b -DCPM  -Isrc/asm/inc iss.asm   ->  ISS.COM (CP/M)
;
; After Justin Skists's ISS tracker for the RC2014, itself after Bill
; Kendrick's for the Atari. The map is theirs (map.inc).
;
; Copyright (C) 2026 Thomas Cherryhomes
; SPDX-License-Identifier: GPL-3.0-or-later
;-----------------------------------------------------------------------------
INCLUDE "os.inc"
INCLUDE "fujinet.inc"

ESC             equ     0x1B
MAP_X           equ     4               ; the map's top left on the screen
MAP_Y           equ     2
VALSZ           equ     64              ; the longest value we keep
REFRESH         equ     60              ; half-seconds between updates

main:
        call    card_on
        call    card_present
        jp      nz,no_card
        call    args                    ; a server of our own?
        ld      de,base
        call    word
        jr      nz,main1
        ld      hl,t_base               ; no: open-notify
        ld      de,base
        call    strcpyd
main1:
        ld      de,base
        call    netspec
        ld      hl,t_start              ; clear the screen, cursor off
        call    print

        call    astros                  ; who is up there
        jr      c,quit
map_loop:
        call    fetch_iss               ; where is the station?
        call    draw
        call    wait_blink              ; 30 seconds, or a key
        jr      nc,map_loop
quit:
        ld      hl,t_stop               ; clear the screen, cursor on
        jp      print

no_card:
        ld      hl,t_nocard
        jp      print

;-------------------------------------------------------------- the JSON part
; open_json: HL -> a devicespec. Opens it on unit 1 (HTTP GET), sets the
; channel's parser to JSON and parses what comes. NZ if any step failed.
;@ex iss.open_json
open_json:
        push    hl
        call    strlen
        pop     hl
        ld      (rq_open+RQ_PAY),hl
        ld      (rq_open+RQ_PLEN),bc
        ld      hl,rq_open              ; open: GET the document
        call    fn_call
        ret     nz
        ld      hl,rq_parser            ; the channel's parser: JSON
        call    fn_call
        ret     nz
        ld      hl,rq_parse             ; read and parse the whole reply
        jp      fn_call
;@end

; jget: HL -> a JSON Pointer, such as "/iss_position/latitude". Asks the
; parser for it and reads the value into val, NUL-terminated, without the
; line feed the FujiNet puts after it. NZ if it is not there.
;@ex iss.jget
jget:
        push    hl
        call    strlen                  ; the query is the whole payload
        pop     hl
        ld      (rq_query+RQ_PAY),hl
        ld      (rq_query+RQ_PLEN),bc
        ld      hl,rq_query
        call    fn_call
        ret     nz
        ld      hl,rq_status            ; the value is waiting to be read
        call    fn_call
        ret     nz
        ld      hl,(nstat+NS_AVAIL)
        ld      a,h
        or      l
        jr      z,jget_none             ; not found: nothing waits
        ld      de,VALSZ-1
        or      a
        sbc     hl,de
        add     hl,de
        jr      c,jget1
        ex      de,hl
jget1:
        ld      (rq_read+RQ_AUX1),hl
        ld      hl,rq_read
        call    fn_call
        ret     nz
        ld      hl,val                  ; end it at BC, then drop the
        add     hl,bc                   ;   line feed (and any CR)
        ld      (hl),0
jget2:
        ld      a,b
        or      c
        jr      z,jget3
        dec     hl
        ld      a,(hl)
        cp      ' '
        jr      nc,jget3
        ld      (hl),0
        dec     bc
        jr      jget2
jget3:
        xor     a                       ; Z: found
        ret
jget_none:
        inc     a                       ; NZ
        ret
;@end

close_ch:
        ld      hl,rq_close
        jp      fn_call

;-------------------------------------------------------------- the people
; astros: list the people in space, then wait for a key. Carry if ESC.
;@ex iss.astros
astros:
        ld      hl,t_astros
        call    make_url
        ld      hl,url
        call    open_json
        jr      nz,astros_fail
        ld      hl,q_number             ; how many?
        call    jget
        jr      nz,astros_fail
        ld      hl,val
        call    atou8
        ld      (people),a
        ld      hl,t_ptitle
        call    print
        ld      a,(people)
        call    pdec8
        call    crlf
        call    crlf
        xor     a                       ; then each by number
astros1:
        ld      (person),a
        ld      hl,people
        cp      (hl)
        jr      nc,astros2
        ld      hl,q_name               ; /people/n/name
        call    person_q
        call    jget
        ld      hl,t_indent
        call    print
        ld      hl,val
        call    print
        ld      hl,q_craft              ; /people/n/craft
        call    person_q
        call    jget
        ld      hl,t_open
        call    print
        ld      hl,val
        call    print
        ld      a,')'
        call    conout
        call    crlf
        ld      a,(person)
        inc     a
        jr      astros1
;@end
astros2:
        call    close_ch
        ld      hl,t_anykey
        call    print
        ld      bc,REFRESH              ; wait up to 30 s for a key
astros3:
        push    bc
        call    half_sec
        pop     bc
        ret     c                       ; ESC
        ret     z                       ; another key
        dec     bc
        ld      a,b
        or      c
        jr      nz,astros3
        ret
astros_fail:
        call    close_ch
        ld      hl,t_nopeople
        call    print
        jr      astros2

; person_q: HL -> "/name" or "/craft". Builds "/people/<person><that>" in q
; and leaves HL -> q.
person_q:
        push    hl
        ld      hl,q_people
        ld      de,q
        call    strcpyd
        ld      a,(person)
        call    utoa8
        pop     hl
        call    strcpyd
        ld      hl,q
        ret

;-------------------------------------------------------------- the station
; fetch_iss: the latitude, longitude and time of the station's last fix
; into lat, lng and stamp. Clears ok if anything failed.
;@ex iss.fetch
fetch_iss:
        xor     a
        ld      (ok),a
        ld      hl,t_issnow
        call    make_url
        ld      hl,url
        call    open_json
        jr      nz,fetch_end
        ld      hl,q_lat
        call    jget
        jr      nz,fetch_end
        ld      hl,val
        ld      de,lat
        call    strcpyd
        ld      hl,q_lng
        call    jget
        jr      nz,fetch_end
        ld      hl,val
        ld      de,lng
        call    strcpyd
        ld      hl,q_time
        call    jget
        jr      nz,fetch_end
        ld      hl,val
        ld      de,stamp
        call    strcpyd
        ld      a,1
        ld      (ok),a
fetch_end:
        jp      close_ch
;@end

; make_url: HL -> a file name. url = base + it.
make_url:
        push    hl
        ld      hl,base
        ld      de,url
        call    strcpyd
        pop     hl
        jp      strcpyd

;-------------------------------------------------------------- the screen
; draw: the frame and the map, the station's place on it, and the figures
; under it
draw:
        ld      hl,t_frame              ; clear; the title; graphics on
        call    print
        ld      bc,(MAP_Y-1)*256+MAP_X-1
        call    gotoxy
        ld      a,'f'                   ; the top: corner, line, corner
        call    conout
        call    hline
        ld      a,'c'
        call    conout
        ld      hl,map_rows             ; each row, between two sides
        ld      b,MAP_Y
draw1:
        push    bc
        ld      c,MAP_X-1
        call    gotoxy
        ld      a,'`'                   ; side (graphics on)
        call    conout
        ld      a,ESC                   ; graphics off for the map
        call    conout
        ld      a,'G'
        call    conout
        ld      b,MAP_W
draw2:
        ld      a,(hl)
        call    conout
        inc     hl
        djnz    draw2
        ld      a,ESC
        call    conout
        ld      a,'F'
        call    conout
        ld      a,'`'
        call    conout
        pop     bc
        inc     b
        ld      a,b
        cp      MAP_Y+MAP_H
        jr      nz,draw1
        ld      c,MAP_X-1               ; the bottom
        call    gotoxy
        ld      a,'e'
        call    conout
        call    hline
        ld      a,'d'
        call    conout
        ld      a,ESC
        call    conout
        ld      a,'G'                   ; graphics off
        call    conout
        ld      a,(ok)
        or      a
        jr      z,draw_fail
        call    place                   ; where on the map
        ld      bc,(MAP_Y+MAP_H+2)*256+MAP_X-1
        call    gotoxy
        ld      hl,t_time               ; the figures
        call    print
        call    print_stamp
        ld      hl,t_lat
        call    print
        ld      hl,lat
        call    print
        ld      hl,t_lng
        call    print
        ld      hl,lng
        call    print
        ld      bc,(MAP_Y+MAP_H+3)*256+MAP_X-1
        call    gotoxy
        ld      hl,t_esc
        jp      print
draw_fail:
        ld      bc,(MAP_Y+MAP_H+2)*256+MAP_X-1
        call    gotoxy
        ld      hl,t_noiss
        jp      print

hline:
        ld      b,MAP_W
hline1:
        ld      a,'a'
        call    conout
        djnz    hline1
        ret

; gotoxy: B = row, C = column, from 0. The H19's ESC Y, row + 32, col + 32.
gotoxy:
        ld      a,ESC
        call    conout
        ld      a,'Y'
        call    conout
        ld      a,b
        add     a,32
        call    conout
        ld      a,c
        add     a,32
        jp      conout

; place: the station's column and row on the map, from lat and lng.
; 72 columns for 360 degrees, 18 rows for 180: x = (lng + 180) / 5,
; y = (90 - lat) / 10, worked in tenths of a degree.
;@ex iss.place
place:
        ld      hl,lng
        call    tenths
        ld      de,1800
        add     hl,de                   ; 0 to 3600
        ld      c,50
        call    div16_8                 ; 0 to 72
        ld      a,l
        cp      MAP_W
        jr      c,place1
        ld      a,MAP_W-1
place1:
        ld      (iss_x),a
        ld      hl,lat
        call    tenths
        ex      de,hl
        ld      hl,900
        or      a
        sbc     hl,de                   ; 0 to 1800
        ld      c,100
        call    div16_8                 ; 0 to 18
        ld      a,l
        cp      MAP_H
        jr      c,place2
        ld      a,MAP_H-1
place2:
        ld      (iss_y),a
        ret
;@end

; mark: A = 1 to show the station, 0 to put the map back
mark:
        push    af
        ld      a,(iss_y)
        add     a,MAP_Y
        ld      b,a
        ld      a,(iss_x)
        add     a,MAP_X
        ld      c,a
        call    gotoxy
        pop     af
        or      a
        jr      z,mark_off
        ld      hl,t_iss                ; reverse video *
        jp      print
mark_off:
        ld      a,(iss_y)               ; the map's own character
        ld      l,a
        ld      h,0
        add     hl,hl                   ; y * 72 = y * 8 + y * 64
        add     hl,hl
        add     hl,hl
        ld      d,h
        ld      e,l
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,de
        ld      a,(iss_x)
        ld      e,a
        ld      d,0
        add     hl,de
        ld      de,map_rows
        add     hl,de
        ld      a,(hl)
        jp      conout

; wait_blink: blink the station for 30 seconds. Carry if ESC was struck;
; returns early if another key was.
wait_blink:
        ld      b,REFRESH
wb1:
        push    bc
        ld      a,(ok)
        or      a
        jr      z,wb2
        ld      a,b                     ; on, off, on ... from the start
        and     1
        xor     1
        call    mark
        ld      bc,0                    ; the cursor out of the way
        call    gotoxy
wb2:
        call    half_sec
        pop     bc
        ret     c                       ; ESC
        ret     z                       ; another key: update now
        djnz    wb1
        or      a
        ret

; half_sec: wait 0.5 s for a key. Carry if ESC, Z if another key, else NZ.
half_sec:
        ld      hl,(TICKS)
        ld      (t0),hl
hs1:
        call    conin
        jr      nc,hs2
        ld      hl,(TICKS)
        ld      de,(t0)
        or      a
        sbc     hl,de
        ld      de,250
        or      a
        sbc     hl,de
        jr      c,hs1
        or      1                       ; NZ, no carry: time is up
        ret
hs2:
        cp      ESC
        scf
        ret     z
        xor     a                       ; Z, no carry
        ret

;-------------------------------------------------------------- the time
; print_stamp: stamp (seconds since 1 January 1970) as YYYY-MM-DD hh:mm:ss
;@ex iss.time
print_stamp:
        ld      hl,stamp                ; seconds, as a 32-bit number
        call    atou32
        ld      c,60
        call    div32_8
        ld      (sec),a
        call    div32_8                 ; minutes
        ld      (min),a
        ld      c,24
        call    div32_8                 ; hours; days are left
        ld      (hour),a
        ld      hl,(num32)
        ld      de,1970                 ; take away whole years
ps1:
        ld      bc,365
        ld      a,e
        and     3
        jr      nz,ps2
        inc     bc                      ; leap year (1901-2099)
ps2:
        or      a
        sbc     hl,bc
        jr      c,ps3
        inc     de
        jr      ps1
ps3:
        add     hl,bc                   ; HL = day of the year, from 0
        ld      (year),de
        ld      ix,mdays                ; then whole months
        ld      b,1
ps4:
        ld      e,(ix+0)
        ld      d,0
        ld      a,b
        cp      2
        jr      nz,ps5
        ld      a,(year)
        and     3
        jr      nz,ps5
        inc     de                      ; 29 days in a leap February
ps5:
        or      a
        sbc     hl,de
        jr      c,ps6
        inc     ix
        inc     b
        jr      ps4
ps6:
        add     hl,de
        inc     l                       ; days from 1
        push    hl
        push    bc
        ld      hl,(year)
        call    pdec16
        ld      a,'-'
        call    conout
        pop     bc
        ld      a,b
        call    p2dig
        ld      a,'-'
        call    conout
        pop     hl
        ld      a,l
        call    p2dig
        call    pspace
        ld      a,(hour)
        call    p2dig
        ld      a,':'
        call    conout
        ld      a,(min)
        call    p2dig
        ld      a,':'
        call    conout
        ld      a,(sec)
        call    p2dig
        ld      hl,t_utc
        jp      print
;@end
mdays:          defb    31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31

;-------------------------------------------------------------- arithmetic
; div16_8: HL / C -> HL quotient, A remainder (C from 1 to 127)
div16_8:
        xor     a
        ld      b,16
d168a:
        add     hl,hl
        rla
        cp      c
        jr      c,d168b
        sub     c
        inc     l
d168b:
        djnz    d168a
        ret

; div32_8: num32 / C -> num32 quotient, A remainder. A byte at a time,
; from the top, the remainder carried down as in long division.
div32_8:
        ld      hl,num32+3
        ld      b,4
        xor     a                       ; nothing carried in yet
d328:
        push    bc
        push    hl
        ld      l,(hl)                  ; remainder * 256 + this byte
        ld      h,a
        call    div16_8                 ; the quotient fits in L
        ld      e,l
        pop     hl
        ld      (hl),e
        dec     hl
        pop     bc
        djnz    d328
        ret

; atou32: HL -> decimal digits. num32 = their value.
atou32:
        xor     a
        ld      (num32),a
        ld      (num32+1),a
        ld      (num32+2),a
        ld      (num32+3),a
atou32a:
        ld      a,(hl)
        sub     '0'
        ret     c
        cp      10
        ret     nc
        push    hl
        ld      b,4                     ; num32 = num32 * 10 + digit
        ld      hl,num32
        ld      c,a
atou32b:
        ld      e,(hl)                  ; this byte * 10 + carry in C
        ld      d,0
        push    hl
        ld      h,d
        ld      l,e
        add     hl,hl
        add     hl,hl
        add     hl,de
        add     hl,hl
        ld      e,c
        add     hl,de
        ld      c,h                     ; carry out
        ld      a,l
        pop     hl
        ld      (hl),a
        inc     hl
        djnz    atou32b
        pop     hl
        inc     hl
        jr      atou32a

; atou8: HL -> decimal digits. A = their value (to 255).
atou8:
        ld      b,0
atou8a:
        ld      a,(hl)
        sub     '0'
        jr      c,atou8b
        cp      10
        jr      nc,atou8b
        ld      c,a
        ld      a,b
        add     a,a
        add     a,a
        add     a,b
        add     a,a
        add     a,c
        ld      b,a
        inc     hl
        jr      atou8a
atou8b:
        ld      a,b
        ret

; tenths: HL -> a number like "-95.3698". HL = it in tenths (-953).
tenths:
        ld      a,(hl)
        cp      '-'
        push    af                      ; Z: negative
        jr      nz,ten1
        inc     hl
ten1:
        ld      de,0
ten2:
        ld      a,(hl)
        cp      '.'
        jr      z,ten3
        sub     '0'
        jr      c,ten4
        cp      10
        jr      nc,ten4
        call    de10a
        inc     hl
        jr      ten2
ten3:
        inc     hl                      ; the first decimal
        ld      a,(hl)
        sub     '0'
        jr      c,ten4
        cp      10
        jr      c,ten5
ten4:
        xor     a                       ; no decimals: times 10
ten5:
        call    de10a
        ex      de,hl
        pop     af
        ret     nz
        xor     a                       ; negative: HL = -HL
        sub     l
        ld      l,a
        sbc     a,a
        sub     h
        ld      h,a
        ret

; de10a: DE = DE * 10 + A
de10a:
        push    hl
        ld      h,d
        ld      l,e
        add     hl,hl
        add     hl,hl
        add     hl,de
        add     hl,hl
        ld      e,a
        ld      d,0
        add     hl,de
        ex      de,hl
        pop     hl
        ret

; utoa8: A (0-99) as decimal at DE, NUL-terminated; DE left at the NUL
utoa8:
        ld      b,'0'-1
utoa8a:
        inc     b
        sub     10
        jr      nc,utoa8a
        add     a,10+'0'
        ld      c,a
        ld      a,b
        cp      '0'
        jr      z,utoa8b
        ld      (de),a
        inc     de
utoa8b:
        ld      a,c
        ld      (de),a
        inc     de
        xor     a
        ld      (de),a
        ret

; strcpyd: copy the string at HL to DE, with its NUL; DE left at the NUL
strcpyd:
        ld      a,(hl)
        ld      (de),a
        or      a
        ret     z
        inc     hl
        inc     de
        jr      strcpyd

; p2dig: A (0-99) as two digits
p2dig:
        cp      10
        jr      nc,p2dig1
        push    af
        ld      a,'0'
        call    conout
        pop     af
p2dig1:
        jp      pdec8

;-------------------------------------------------------------- data
;@ex iss.requests
rq_open:                                ; mode 4: HTTP GET
        FNREQ   DEV_NETWORK, NET_OPEN, F_A1_A2, 4,0,0,0
        FNBUF   0, 0, 0, 0
rq_parser:                              ; the second field: 1 = JSON
        FNREQ   DEV_NETWORK, NET_SET_PARSER, F_A1_A2, 0,1,0,0
        FNBUF   0, 0, 0, 0
rq_parse:
        FNREQ   DEV_NETWORK, NET_PARSE, F_NONE, 0,0,0,0
        FNBUF   0, 0, 0, 0
rq_query:                               ; payload: the JSON Pointer
        FNREQ   DEV_NETWORK, NET_QUERY, F_NONE, 0,0,0,0
        FNBUF   0, 0, 0, 0
rq_status:
        FNREQ   DEV_NETWORK, NET_STATUS, F_NONE, 0,0,0,0
        FNBUF   0, 0, nstat, 4
rq_read:
        FNREQ   DEV_NETWORK, NET_READ, F_B12, 0,0,0,0
        FNBUF   0, 0, val, VALSZ-1
rq_close:
        FNREQ   DEV_NETWORK, NET_CLOSE, F_NONE, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end

t_base:         defm    "N:HTTP://api.open-notify.org/"
                defb    0
t_issnow:       defm    "iss-now.json"
                defb    0
t_astros:       defm    "astros.json"
                defb    0
q_number:       defm    "/number"
                defb    0
q_people:       defm    "/people/"
                defb    0
q_name:         defm    "/name"
                defb    0
q_craft:        defm    "/craft"
                defb    0
q_lat:          defm    "/iss_position/latitude"
                defb    0
q_lng:          defm    "/iss_position/longitude"
                defb    0
q_time:         defm    "/timestamp"
                defb    0

t_start:        defb    ESC, 'E', ESC, 'x', '5', 0
t_stop:         defb    ESC, 'G', ESC, 'q', ESC, 'E', ESC, 'y', '5', 0
t_frame:        defb    ESC, 'E', ESC, 'Y', 32, 32+MAP_X+22, ESC, 'p'
                defm    " INTERNATIONAL SPACE STATION "
                defb    ESC, 'q', ESC, 'F', 0
t_iss:          defb    ESC, 'p', '*', ESC, 'q', 0
t_ptitle:       defb    ESC, 'E', ESC, 'p'
                defm    " PEOPLE IN SPACE "
                defb    ESC, 'q', 13, 10, 13, 10
                defm    "There are "
                defb    0
t_indent:       defm    "    "
                defb    0
t_open:         defm    "  ("
                defb    0
t_anykey:       defb    13, 10
                defm    "RETURN shows the map; ESC quits."
                defb    0
t_nopeople:     defb    ESC, 'E'
                defm    "Could not read the list of people in space."
                defb    13, 10, 0
t_time:         defm    "Time "
                defb    0
t_utc:          defm    " UTC"
                defb    0
t_lat:          defm    "   Lat "
                defb    0
t_lng:          defm    "   Long "
                defb    0
t_esc:          defm    "Updates every 30 seconds.  RETURN updates now; ESC quits."
                defb    0
t_noiss:        defm    "Could not read the station's position; trying again."
                defb    0
t_nocard:       defm    "No FujiNet card at 0D0H."
                defb    13, 10, 0

INCLUDE "map.inc"

ok:             defb    0               ; 1 = lat, lng and stamp are good
people:         defb    0
person:         defb    0
iss_x:          defb    0
iss_y:          defb    0
sec:            defb    0
min:            defb    0
hour:           defb    0
year:           defw    0
t0:             defw    0
num32:          defs    4
nstat:          defs    4
val:            defs    VALSZ
lat:            defs    VALSZ
lng:            defs    VALSZ
stamp:          defs    VALSZ
q:              defs    32
base:           defs    132
url:            defs    148

INCLUDE "words.inc"
INCLUDE "card.inc"
INCLUDE "fujibus.inc"
INCLUDE "con.inc"
INCLUDE "tail.inc"
