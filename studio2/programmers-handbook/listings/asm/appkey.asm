; appkey.asm -- read the shared FujiNet user
; name, then write a key of our own and read it
; back.
;
; An app key is a small file on the adapter's
; SD card, named by a creator id, an app id and
; a key number. Creator 1, app 1, key 0 is the
; one every FujiNet game reads the player's
; name from. Ours is creator $1802, app $FF (this
; handbook's scratch key), key 0.
;
; OPEN_APPKEY's payload is one six-byte struct:
; creator (low first), app, key, mode and a
; reserved 0. READ_APPKEY's reply is a two-byte
; length, then the value. WRITE_APPKEY takes one
; parameter, the length, then the bytes.

        CPU     1802
        INCLUDE "fujinet.inc"
        INCLUDE "s2macro.inc"
        INCLUDE "s2defs.inc"

OURCRE  EQU     1802H
OURAPP  EQU     0FFH
OURKEY  EQU     0

        ORG     0400H
        INCLUDE "s2call.inc"
        INCLUDE "fujilib.inc"
        INCLUDE "fujidisp.inc"

        ORG     0C00H
        INCLUDE "booklib.inc"

        FIT     104
main:   FCALL   d_cls
        PUTS    00H, t_title
        FCALL   fn_chk
        BDF     go
        LDI     FNENOC
        FJMP    fail
go:     PUTS    20H, t_name     ; the user name
        LDR     RA, k_name
        FCALL   akopen
        FCALL   akread
        LDI     30H
        FCALL   akshow
        PUTS    50H, t_ours     ; ours: write it...
        LDR     RA, k_ourw
        FCALL   akopen
        FCALL   akwrite
        LDR     RA, k_ourr      ; ...read it back
        FCALL   akopen
        FCALL   akread
        LDI     60H
        FCALL   akshow
hang:   BR      hang

; akopen -- OPEN_APPKEY: no parameters, the
; six-byte struct at RA as the payload.
        FIT     40
akopen: FNBEGIN FNDEVF, FNCAKOP, 0
        LDI     6
        PLO     RB
ako1:   LDA     RA
        FCALL   fn_txb
        DEC     RB
        GLO     RB
        BNZ     ako1
        GOACK
        FRET

; akread -- READ_APPKEY: the value is left in
; the reply window after its two-byte length.
        FIT     20
akread: FNBEGIN FNDEVF, FNCAKRD, 0
        GOACK
        FRET

; akwrite -- WRITE_APPKEY: the length, then it.
        FIT     42
akwrite:
        FNBEGIN FNDEVF, FNCAKWR, 1
        LDI     VALLEN
        FCALL   fn_pb
        LDR     RA, val
        LDI     VALLEN
        PLO     RB
akw1:   LDA     RA
        FCALL   fn_txb
        DEC     RB
        GLO     RB
        BNZ     akw1
        GOACK
        FRET

; akshow -- the value just read, at D = row and
; column; "(EMPTY)" when there is none.
        FIT     49
akshow: FCALL   d_at
        PEEK    FN_REPLY        ; the length, < 64
        BZ      aks1
        LDR     R8, 2           ; after the length
        PEEK    FN_REPLY
        FCALL   d_rpl
        FRET
aks1:   LDR     R8, t_empty
        FCALL   d_puts
        FRET

k_name: DB      LO(AKCREAT), HI(AKCREAT), AKAPP
        DB      AKKEY, AKMRD, 0
k_ourw: DB      LO(OURCRE), HI(OURCRE), OURAPP
        DB      OURKEY, AKMWR, 0
k_ourr: DB      LO(OURCRE), HI(OURCRE), OURAPP
        DB      OURKEY, AKMRD, 0
val:    DB      "HELLO STUDIO II"
VALLEN  EQU     $-val
t_title: DB     "APP KEYS", 0
t_name:  DB     "PLAYER NAME", 0
t_ours:  DB     "OURS, READ BACK", 0
t_empty: DB     "(EMPTY)", 0

        S2CLAIM
