; wait.inc -- the screens before the shooting: the waiting room (status 0),
; and placement (status 1) while we place or wait for the others.
;
; The waiting room:
;   row 0     the server's name
;   rows 2-5  the seats: NAME     READY
;   row 7     the server's prompt ("starting in 5"), scrolled by the cart
;   row 9     5 READY  0 MENU
;
; Placement (place.inc keys the board):
;   row 0     PLACE YOUR FLEET           FLEET PLACED / WATCHING
;   row 1     1/5 CARRIER                WAITING FOR THE
;   rows 2-4  the keys                   OTHERS TO PLACE
;   rows 5-9  YOU over our board; the others' names and OK / ... beside it

; globby -- status 0.
        FIT     160
globby: SETV    V_PLOK, 0
        SETV    V_MODE, M_LOBBY
        SETV    V_IVL, LOBF
        GETV    V_SCR
        XRI     SC_LOBBY
        BZ      gl1
        SETV    V_SCR, SC_LOBBY
        SETV    V_PSUM, 0               ; no sum is 0: the prompt is drawn
        FCALL   d_cls
gl1:    AT      00H
        LDR     RB, RPLY+GSRV
        LDI     0
        PHI     R8
        LDI     16
        FCALL   rpu
        SETV    V_ROW, 0
gl2:    GETV    V_ROW
        ADI     2
        SHL
        SHL
        SHL
        SHL
        FCALL   d_at
        GETV    V_PC
        STR     R2
        GETV    V_ROW
        SM                              ; row - count: a borrow is a seat
        BDF     gl4
        GETV    V_ROW
        FCALL   lrec
        LDI     0
        PHI     R8
        LDI     9
        FCALL   rpu
        GETV    V_ROW
        FCALL   lrec
        LDI     PSTAT
        FCALL   radd
        LDN     RB
        XRI     PS_READY
        BNZ     gl4
        LDR     R8, s_ready
        FCALL   d_puts
gl4:    OP      TOP_CLREOL
        GETV    V_ROW
        ADI     1
        STR     RA
        XRI     GMAXPL
        BNZ     gl2
        FCALL   gprompt
        LDR     R8, s_lobrdy
        GETV    V_PST
        XRI     PS_READY
        BNZ     gl5
        LDR     R8, s_lobunr
gl5:    AT      90H
        FCALL   d_puts
        OP      TOP_CLREOL
        FJMP    gwait

; gprompt -- row 7: the server's prompt, when it has changed. The cart
; prints it from its own window and scrolls it when it runs past the row.
        FIT     80
gprompt:
        LDR     RB, RPLY+GPROMPT        ; a checksum, bit 7 set: never 0
        LDI     33
        PLO     RC
        LDI     0
        PLO     R9
gpr1:   LDA     RB
        BZ      gpr2
        STR     R2
        GLO     R9
        ADD
        PLO     R9
        DEC     RC
        GLO     RC
        BNZ     gpr1
gpr2:   GLO     R9
        ORI     80H
        PLO     R9
        GETV    V_PSUM
        STR     R2
        GLO     R9
        XOR
        BZ      gpr9
        GLO     R9
        PUTV    V_PSUM
        AT      70H
        OP      TOP_CLREOL
        AT      70H
        OP      TOP_MARQUEE
        LDR     R8, GPROMPT
        LDI     0
        FJMP    d_rpl
gpr9:   FRET

; gplace -- status 1: place our ships, or wait for the others to.
        FIT     120
gplace: GETV    V_PST
        XRI     PS_PLACE
        BZ      gpl1
        FJMP    gwaitp
gpl1:   GETV    V_PLOK
        BNZ     gpl2
        SETV    V_PLOK, 1               ; a new placement: roll a fleet
        SETV    V_PSHIP, 0
        FCALL   proll
        BR      gpl3
gpl2:   GETV    V_PSHIP
        XRI     NSHIPS
        BNZ     gpl3
        SETV    V_PSHIP, 0              ; sent, yet still placing: refused
        BEEP    30
gpl3:   SETV    V_MODE, M_PLACE
        SETV    V_IVL, PLACEF
        GETV    V_SCR
        XRI     SC_PLACE
        BZ      gpl4
        SETV    V_SCR, SC_PLACE
        FCALL   d_cls
        PUTS    00H, s_place
        PUTS    20H, s_plc1
        PUTS    30H, s_plc2
        PUTS    40H, s_plc3
        PUTS    50H, s_you5
gpl4:   FCALL   pship
        FCALL   pdraw
        FCALL   gothers
        FJMP    gwait

; gwaitp -- status 1 with our ships placed (or only watching).
        FIT     112
gwaitp: SETV    V_MODE, M_TEXT
        SETV    V_IVL, POLLF
        GETV    V_SCR
        XRI     SC_WAITP
        BZ      gwp1
        SETV    V_SCR, SC_WAITP
        FCALL   d_cls
        LDR     R8, s_placed
        GETV    V_PST
        XRI     PS_VIEW
        BNZ     gwp0
        LDR     R8, s_watching
gwp0:   AT      00H
        FCALL   d_puts
        PUTS    20H, s_waitp1
        PUTS    30H, s_waitp2
gwp1:   SETV    V_BSEAT, 0
        GETV    V_PST
        XRI     PS_VIEW
        BNZ     gwp2
        FCALL   bblank                  ; watching: no fleet of ours
        BR      gwp3
gwp2:   PUTS    50H, s_you5
        FCALL   mclear                  ; the server's copy of our fleet
        LDR     RB, RPLY+GSHIPS
        FCALL   mships
        SETV    V_BMH, HI(MAP)
        FCALL   bdraw
gwp3:   FCALL   gothers
        FJMP    gwait

; gothers -- rows 6-8, columns 6-15: the other seats, OK once placed.
        FIT     100
gothers:
        SETV    V_ROW, 1
go1:    GETV    V_ROW
        ADI     5
        SHL
        SHL
        SHL
        SHL
        ORI     06H
        FCALL   d_at
        GETV    V_PC
        STR     R2
        GETV    V_ROW
        SM                              ; row - count: a borrow is a seat
        BNF     go2
        LDI     10
        FCALL   blanks
        BR      go4
go2:    GETV    V_ROW
        FCALL   lrec
        LDI     1
        PHI     R8
        LDI     6
        FCALL   rpu
        GETV    V_ROW
        FCALL   lrec
        LDI     PSTAT
        FCALL   radd
        LDR     R8, s_dots4
        LDN     RB
        XRI     PS_PLACE
        BZ      go3
        LDR     R8, s_ok4
go3:    FCALL   d_puts
go4:    GETV    V_ROW
        ADI     1
        STR     RA
        XRI     GMAXPL
        BNZ     go1
        FRET
