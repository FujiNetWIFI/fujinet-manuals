;-----------------------------------------------------------------------------
; words.inc -- picking a command line apart.
;
;   word     HL -> text: skip spaces, copy the next word (up to a space or
;            the end) to DE as a NUL-terminated string. HL is left after
;            it. Z if there was no word.
;   netspec  DE -> a word: if it does not start "N:" or "Nn:", put "N:" in
;            front of it, in place (the buffer needs 2 bytes of room).
;            Changes HL.
;
; Copyright (C) 2026 Thomas Cherryhomes
; SPDX-License-Identifier: GPL-3.0-or-later
;-----------------------------------------------------------------------------

word:
        ld      a,(hl)                  ; skip spaces
        cp      ' '
        jr      nz,word1
        inc     hl
        jr      word
word1:
        or      a                       ; nothing left?
        jr      z,word3
        push    de
word2:
        ld      a,(hl)
        or      a
        jr      z,word4
        cp      ' '
        jr      z,word4
        ld      (de),a
        inc     hl
        inc     de
        jr      word2
word4:
        xor     a
        ld      (de),a
        pop     de
        inc     a                       ; NZ: a word
        ret
word3:
        ld      (de),a                  ; an empty word; Z
        ret

netspec:
        ld      a,(de)
        and     0xDF                    ; upper case
        cp      'N'
        jr      nz,nets1
        inc     de
        ld      a,(de)
        dec     de
        cp      ':'
        ret     z                       ; N:...
        inc     de
        inc     de
        ld      a,(de)
        dec     de
        dec     de
        cp      ':'
        ret     z                       ; Nn:...
nets1:
        push    de                      ; shift right 2, then N: in front
        ex      de,hl
        call    strlen
        add     hl,bc                   ; HL -> the NUL
        ld      d,h
        ld      e,l
        inc     de
        inc     de
        inc     bc                      ; move the NUL too
        lddr
        pop     de
        ld      a,'N'
        ld      (de),a
        inc     de
        ld      a,':'
        ld      (de),a
        dec     de
        ret
