;-----------------------------------------------------------------------------
; con.inc -- printing numbers and bytes on the console (built on conout).
;
;   phex8   A in hex          phex16  HL in hex
;   pdec8   A in decimal      pdec16  HL in decimal
;   pspace  one space         pip     HL -> 4 bytes as a dotted IP address
;   ptext   HL -> BC bytes as text, unprintable ones as '.'
;   pdump   HL -> BC bytes in hex, 16 to a line
;   phexs   HL -> BC bytes in hex on one line (at most 24, then "...")
;   getline HL -> buffer, B = its size: a line typed at the keyboard, shown
;           as it is typed (BACKSPACE and DELETE rub out), ended by RETURN;
;           stored NUL-terminated without the RETURN. Keeps HL.
;   strlen  HL -> a NUL-terminated string: BC = its length. Keeps HL.
;
; All keep BC, DE and HL unless they say otherwise.
;
; Copyright (C) 2026 Thomas Cherryhomes
; SPDX-License-Identifier: GPL-3.0-or-later
;-----------------------------------------------------------------------------

phex16:
        ld      a,h
        call    phex8
        ld      a,l
phex8:
        push    af
        rrca
        rrca
        rrca
        rrca
        call    phex4
        pop     af
phex4:
        and     0x0F
        add     a,'0'
        cp      '9'+1
        jp      c,conout
        add     a,'A'-'9'-1
        jp      conout

pspace:
        ld      a,' '
        jp      conout

pdec8:
        push    hl
        ld      l,a
        ld      h,0
        call    pdec16
        pop     hl
        ret

pdec16:
        push    bc
        push    de
        push    hl
        ld      b,0                     ; digits printed so far
        ld      de,-10000
        call    pdec1
        ld      de,-1000
        call    pdec1
        ld      de,-100
        call    pdec1
        ld      de,-10
        call    pdec1
        ld      a,l
        add     a,'0'
        call    conout
        pop     hl
        pop     de
        pop     bc
        ret
pdec1:
        ld      a,'0'-1
pdec2:
        inc     a
        add     hl,de
        jr      c,pdec2
        sbc     hl,de                   ; one too many: put it back
        cp      '0'                     ; no leading zeros
        jr      nz,pdec3
        inc     b
        dec     b
        ret     z
pdec3:
        ld      b,1
        jp      conout

pip:
        push    bc
        push    hl
        ld      b,4
pip1:
        ld      a,(hl)
        call    pdec8
        inc     hl
        dec     b
        jr      z,pip2
        ld      a,'.'
        call    conout
        jr      pip1
pip2:
        pop     hl
        pop     bc
        ret

ptext:
        push    bc
        push    hl
ptext1:
        ld      a,b
        or      c
        jr      z,ptext3
        ld      a,(hl)
        cp      ' '
        jr      c,ptext2
        cp      0x7F
        jr      c,ptext4
ptext2:
        ld      a,'.'
ptext4:
        call    conout
        inc     hl
        dec     bc
        jr      ptext1
ptext3:
        pop     hl
        pop     bc
        ret

phexs:
        push    bc
        push    de
        push    hl
        ld      d,24
phexs1:
        ld      a,b
        or      c
        jr      z,phexs3
        ld      a,d
        or      a
        jr      z,phexs2
        ld      a,(hl)
        call    phex8
        call    pspace
        inc     hl
        dec     bc
        dec     d
        jr      phexs1
phexs2:
        ld      a,'.'
        call    conout
        call    conout
        call    conout
phexs3:
        pop     hl
        pop     de
        pop     bc
        ret

pdump:
        push    bc
        push    de
        push    hl
pdump1:
        ld      a,b
        or      c
        jr      z,pdump3
        ld      e,16
pdump2:
        ld      a,(hl)
        call    phex8
        call    pspace
        inc     hl
        dec     bc
        ld      a,b
        or      c
        jr      z,pdump3
        dec     e
        jr      nz,pdump2
        call    crlf
        jr      pdump1
pdump3:
        call    crlf
        pop     hl
        pop     de
        pop     bc
        ret

getline:
        push    hl
        push    de
        dec     b                       ; room for the NUL
        ld      c,0                     ; characters so far
getl1:
        call    getkey
        cp      13
        jr      z,getl4
        cp      8
        jr      z,getl3
        cp      0x7F
        jr      z,getl3
        cp      ' '
        jr      c,getl1                 ; other control characters: ignored
        ld      e,a
        ld      a,c
        cp      b
        jr      nc,getl1                ; full
        ld      a,e
        ld      (hl),a
        inc     hl
        inc     c
        call    conout
        jr      getl1
getl3:
        ld      a,c                     ; rub out the last one, if any
        or      a
        jr      z,getl1
        dec     hl
        dec     c
        ld      a,8
        call    conout
        ld      a,' '
        call    conout
        ld      a,8
        call    conout
        jr      getl1
getl4:
        ld      (hl),0
        call    crlf
        pop     de
        pop     hl
        ret

strlen:
        push    hl
        ld      bc,0
strl1:
        ld      a,(hl)
        or      a
        jr      z,strl2
        inc     hl
        inc     bc
        jr      strl1
strl2:
        pop     hl
        ret
