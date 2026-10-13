;-----------------------------------------------------------------------------
; os.inc -- one program, two operating systems.
;
; Include this FIRST. Assemble with -DHDOS for an HDOS 2.0 .ABS file or
; -DCPM for a Heath CP/M 2.2.04 .COM file. Your program supplies `main`
; (it may return, or call exit) and ends by including tail.inc.
;
; Both systems get the same routines:
;   conout   A = character out. Keeps BC, DE, HL.
;   conin    A = a key, NC; carry if no key is waiting. Keeps BC, DE, HL.
;   getkey   waits for a key; A = it.
;   print    HL -> NUL-terminated text out.
;   crlf     carriage return, line feed.
;   exit     restore the console and return to the system.
;   args     HL -> the command line's arguments, NUL-terminated.
;   f_create HL -> "SY1:NAME.EXT" / "B:NAME.EXT". Carry = failed.
;   f_open   the same, for reading.
;   f_write  DE -> data, BC = length (any). Carry = failed.
;   f_read   DE -> buffer, BC = size; BC = bytes read, 0 at the end.
;   f_close  write what is buffered, close. Carry = failed.
;   TICKS    the word the system's 2 ms clock counts up.
;
; Copyright (C) 2026 Thomas Cherryhomes
; SPDX-License-Identifier: GPL-3.0-or-later
;-----------------------------------------------------------------------------

IFDEF HDOS
;------------------------------------------------------------- HDOS 2.0 ----
TICKS           equ     0x201B          ; HDOS's tick counter (S.TIME area)
S_CSLMD         equ     0x20D6          ; the five console mode bytes
HDOS_EOS        equ     0x227F          ; the command line ends here (a NUL)

; system calls: RST 38H followed by the function number
macro SCALL fn
        rst     0x38
        defb    fn
endm
_EXIT           equ     0x00
_SCIN           equ     0x01
_SCOUT          equ     0x02
_READ           equ     0x04
_WRITE          equ     0x05
_CONSL          equ     0x06
_OPENR          equ     0x22
_OPENW          equ     0x23
_CLOSE          equ     0x26

        org     0x2278                  ; HDOS loads programs at 2280H:
        defb    0xFF, 0x00              ; the .ABS header, 8 bytes, comes first
        defw    start                   ; load address
        defw    prog_end - start        ; length
        defw    start                   ; entry point
start:
        ld      (os_argp),sp            ; HDOS leaves SP on the command line
        call    os_init
        call    main
        jp      exit

; raw character mode, no echo, no case mapping, no width: escape sequences
; and graphics characters pass untouched
os_init:
        ld      hl,S_CSLMD              ; keep the console as we found it
        ld      de,os_consave
        ld      bc,5
        ldir
        ld      a,0                     ; S.CSLMD: echo off, raw, character mode
        ld      b,0x85
        ld      c,0x87
        SCALL   _CONSL
        ld      a,1                     ; S.CONTY: no case mapping
        ld      b,0
        ld      c,0x32
        SCALL   _CONSL
        ld      a,3                     ; S.CONWI: width 255
        ld      b,255
        ld      c,0xFF
        SCALL   _CONSL
        ret

exit:
        ld      a,(os_consave)          ; put the console back as it was
        ld      b,a
        xor     a
        ld      c,0xFF
        SCALL   _CONSL
        ld      a,(os_consave+1)
        ld      b,a
        ld      a,1
        ld      c,0xFF
        SCALL   _CONSL
        ld      a,(os_consave+3)
        ld      b,a
        ld      a,3
        ld      c,0xFF
        SCALL   _CONSL
        xor     a
        SCALL   _EXIT

conout:
        push    bc
        push    de
        push    hl
        SCALL   _SCOUT
        pop     hl
        pop     de
        pop     bc
        ret

conin:
        push    bc
        push    de
        push    hl
        SCALL   _SCIN                   ; carry: nothing waiting
        pop     hl
        pop     de
        pop     bc
        ret

; HL -> the arguments: from where SP pointed at entry to 227FH
args:
        ld      hl,(os_argp)
args_skip:
        ld      a,h                     ; SP was 2280H: no arguments
        cp      0x22
        jr      nz,args_sp
        ld      a,l
        cp      0x80
        jr      nz,args_sp
        ld      hl,os_nul               ; none: an empty string (227FH
        ret                             ;   holds a NUL only if there were)
args_sp:
        ld      a,(hl)
        cp      ' '
        ret     nz
        inc     hl
        jr      args_sp

; files: channel 0, read or written through a 256-byte sector buffer
f_create:
        ld      a,_OPENW
        jr      f_openx
f_open:
        ld      a,_OPENR
f_openx:
        ld      (f_scall+1),a           ; the SCALL number, patched in
        xor     a
        ld      (os_fcnt),a
        ld      (os_fcnt+1),a
        ld      (os_feof),a
        ld      de,os_hdefault
f_scall:
        SCALL   0                       ; OPENW or OPENR, A = channel 0
        ret

f_write:
        ld      a,b
        or      c
        ret     z
        ld      a,(de)
        inc     de
        push    de
        push    bc
        ld      hl,(os_fcnt)
        push    hl
        ld      de,os_fbuf
        add     hl,de
        ld      (hl),a
        pop     hl
        inc     hl
        ld      (os_fcnt),hl
        ld      a,h                     ; a whole sector: write it
        cp      1
        jr      nz,f_write1
        call    f_wsector
        jr      c,f_wfail
f_write1:
        pop     bc
        pop     de
        dec     bc
        jr      f_write
f_wfail:
        pop     bc
        pop     de
        scf
        ret
f_wsector:
        xor     a                       ; channel 0
        ld      de,os_fbuf
        ld      bc,256
        SCALL   _WRITE
        ld      hl,0
        ld      (os_fcnt),hl
        ret

f_close:
        ld      hl,(os_fcnt)            ; pad the last sector with zeros
        ld      a,h
        or      l
        jr      z,f_close1
f_pad:
        ld      de,os_fbuf
        push    hl
        add     hl,de
        ld      (hl),0
        pop     hl
        inc     hl
        ld      a,h
        cp      1
        jr      nz,f_pad
        call    f_wsector
        ret     c
f_close1:
        xor     a
        SCALL   _CLOSE
        ret

f_read:
        push    bc                      ; BC = size wanted
        ld      hl,0
        ld      (os_rcount),hl
f_read1:
        pop     bc
        ld      a,b
        or      c
        jr      z,f_readx
        dec     bc
        push    bc
        ld      hl,(os_fcnt)            ; buffer empty? read a sector
        ld      a,h
        or      l
        jr      nz,f_read2
        ld      a,(os_feof)
        or      a
        jr      nz,f_reof
        push    de
        xor     a
        ld      de,os_fbuf
        ld      bc,256
        SCALL   _READ                   ; carry: the end of the file
        pop     de
        jr      c,f_rend
        ld      hl,256
        ld      (os_fcnt),hl
        ld      hl,os_fbuf
        ld      (os_fptr),hl
f_read2:
        ld      hl,(os_fptr)
        ld      a,(hl)
        inc     hl
        ld      (os_fptr),hl
        ld      (de),a
        inc     de
        ld      hl,(os_fcnt)
        dec     hl
        ld      (os_fcnt),hl
        ld      hl,(os_rcount)
        inc     hl
        ld      (os_rcount),hl
        jr      f_read1
f_rend:
        ld      a,1
        ld      (os_feof),a
f_reof:
        pop     bc
f_readx:
        ld      bc,(os_rcount)
        ret

ELSE
;--------------------------------------------------- Heath CP/M 2.2.04 ----
TICKS           equ     0x000B          ; the Heath BIOS's tick counter
BDOS            equ     0x0005
CPM_TAIL        equ     0x0080          ; the command tail: length, text

        org     0x0100
start:
        ld      sp,os_stack             ; our own stack (the CCP's is tiny)
        call    os_init
        call    main
        jp      exit

os_init:
        ret

exit:
        jp      0                       ; warm boot back to the CCP

; console through BDOS function 6, direct: no echo, no ^S or ^P
conout:
        push    af
        push    bc
        push    de
        push    hl
        ld      e,a
        ld      c,6
        call    BDOS
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

conin:
        push    bc
        push    de
        push    hl
        ld      e,0xFF
        ld      c,6
        call    BDOS                    ; A = 0: nothing waiting
        pop     hl
        pop     de
        pop     bc
        or      a
        scf
        ret     z
        ccf
        ret

; HL -> the arguments: the CCP's command tail at 80H, made NUL-terminated
args:
        ld      hl,CPM_TAIL
        ld      e,(hl)
        ld      d,0
        inc     hl
        push    hl
        add     hl,de
        ld      (hl),0
        pop     hl
        jr      args_sp
args_sp:
        ld      a,(hl)
        cp      ' '
        ret     nz
        inc     hl
        jr      args_sp

; files: one FCB, read or written through a 128-byte record buffer
f_create:
        call    f_fcb
        ld      de,os_fcb
        ld      c,19                    ; delete any old one
        call    BDOS
        ld      de,os_fcb
        ld      c,22                    ; make
        jr      f_openx
f_open:
        call    f_fcb
        ld      de,os_fcb
        ld      c,15                    ; open
f_openx:
        call    BDOS
        inc     a                       ; FFH: failed
        scf
        ret     z
        xor     a
        ld      (os_fcnt),a
        ld      (os_fcnt+1),a
        ld      (os_feof),a
        ret

; HL -> "D:NAME.EXT" into os_fcb
f_fcb:
        push    hl
        ld      hl,os_fcb               ; clear it: drive 0, blank name
        ld      (hl),0
        inc     hl
        ld      b,11
f_fcbsp:
        ld      (hl),' '
        inc     hl
        djnz    f_fcbsp
        ld      b,24
f_fcbz:
        ld      (hl),0
        inc     hl
        djnz    f_fcbz
        pop     hl
        inc     hl                      ; "D:" names a drive
        ld      a,(hl)
        dec     hl
        cp      ':'
        jr      nz,f_fcbn
        ld      a,(hl)
        and     0x5F
        sub     'A' - 1
        ld      (os_fcb),a
        inc     hl
        inc     hl
f_fcbn:
        ld      de,os_fcb + 1
        ld      b,8
        call    f_fcbpart
        ld      a,(hl)
        cp      '.'
        jr      nz,f_fcbx
        inc     hl
        ld      de,os_fcb + 9
        ld      b,3
        call    f_fcbpart
f_fcbx:
        ret
f_fcbpart:
        ld      a,(hl)
        or      a
        ret     z
        cp      '.'
        ret     z
        cp      ' '
        ret     z
        cp      'a'
        jr      c,f_fcbup
        and     0x5F
f_fcbup:
        ld      (de),a
        inc     de
        inc     hl
        djnz    f_fcbpart
        ret

f_write:
        ld      a,b
        or      c
        ret     z
        ld      a,(de)
        inc     de
        push    de
        push    bc
        ld      hl,(os_fcnt)
        push    hl
        ld      de,os_fbuf
        add     hl,de
        ld      (hl),a
        pop     hl
        inc     hl
        ld      (os_fcnt),hl
        ld      a,l                     ; a whole record: write it
        cp      128
        jr      nz,f_write1
        call    f_wrecord
        jr      c,f_wfail
f_write1:
        pop     bc
        pop     de
        dec     bc
        jr      f_write
f_wfail:
        pop     bc
        pop     de
        scf
        ret
f_wrecord:
        ld      de,os_fbuf
        ld      c,26                    ; set DMA
        call    BDOS
        ld      de,os_fcb
        ld      c,21                    ; write sequential
        call    BDOS
        ld      hl,0
        ld      (os_fcnt),hl
        or      a
        ret     z
        scf
        ret

f_close:
        ld      hl,(os_fcnt)            ; pad the last record with ^Z
        ld      a,l
        or      a
        jr      z,f_close1
f_pad:
        ld      de,os_fbuf
        push    hl
        add     hl,de
        ld      (hl),0x1A
        pop     hl
        inc     hl
        ld      a,l
        cp      128
        jr      nz,f_pad
        call    f_wrecord
        ret     c
f_close1:
        ld      de,os_fcb
        ld      c,16                    ; close
        call    BDOS
        inc     a
        scf
        ret     z
        or      a
        ret

f_read:
        push    bc
        ld      hl,0
        ld      (os_rcount),hl
f_read1:
        pop     bc
        ld      a,b
        or      c
        jr      z,f_readx
        dec     bc
        push    bc
        ld      hl,(os_fcnt)            ; buffer empty? read a record
        ld      a,h
        or      l
        jr      nz,f_read2
        ld      a,(os_feof)
        or      a
        jr      nz,f_reof
        push    de
        ld      de,os_fbuf
        ld      c,26
        call    BDOS
        ld      de,os_fcb
        ld      c,20                    ; read sequential: not 0 = the end
        call    BDOS
        pop     de
        or      a
        jr      nz,f_rend
        ld      hl,128
        ld      (os_fcnt),hl
        ld      hl,os_fbuf
        ld      (os_fptr),hl
f_read2:
        ld      hl,(os_fptr)
        ld      a,(hl)
        inc     hl
        ld      (os_fptr),hl
        ld      (de),a
        inc     de
        ld      hl,(os_fcnt)
        dec     hl
        ld      (os_fcnt),hl
        ld      hl,(os_rcount)
        inc     hl
        ld      (os_rcount),hl
        jr      f_read1
f_rend:
        ld      a,1
        ld      (os_feof),a
f_reof:
        pop     bc
f_readx:
        ld      bc,(os_rcount)
        ret
ENDIF

;---------------------------------------------------------- both systems ----
getkey:
        call    conin
        jr      c,getkey
        ret

print:
        ld      a,(hl)
        or      a
        ret     z
        call    conout
        inc     hl
        jr      print

crlf:
        ld      a,13
        call    conout
        ld      a,10
        jp      conout
