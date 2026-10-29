; lobby.inc -- st_lobby: pick a table.
;
; One /tables request: a count byte, then TSTRIDE-byte records. Up to eight
; rows, drawn straight out of the window:
;     [n]NAME_______ c/m
; the key, the name in 11 cells, the server's "cur / max" without its
; spaces. A digit joins that table; 0 is the menu.

        FIT     120
st_lobby:
        RESET
        SETV    V_SEAT, 0
        FCALL   d_cls
        PUTS    00H, s_choose
        PUTS    40H, s_finding
        SETV    V_REQ, REQ_TABLES
        LDR     R8, 1
        LDR     R9, TCAP
        FCALL   setlim
        FCALL   nfetch
        BNZ     lbfail
        LDI     0                       ; believe the count only if the
        FCALL   rpeek                   ; length agrees with it
        SMI     TMAXN+1
        BDF     lbbad
        LDR     R8, 1
        LDI     TSTRIDE
        PLO     R9
        LDI     0
        FCALL   rpeek
        FCALL   vlen
        BNZ     lbbad
        LDI     0
        FCALL   rpeek
        SMI     9
        BNF     lb1
        LDI     8
        BR      lb2
lb1:    LDN     RB
lb2:    PUTV    V_NTBL
        FCALL   d_cls
        PUTS    00H, s_choose
        PUTS    90H, s_lbleg
        GETV    V_NTBL
        BNZ     lb3
        PUTS    40H, s_notables
lb3:    FCALL   lbrows
lbk:    FCALL   kwait
        BZ      lbmenu
        PLO     RC
        SMI     1
        STR     R2
        GETV    V_NTBL
        SM                              ; count - index
        BZ      lbk
        BNF     lbk                     ; no such row
        GLO     RC
        SMI     1
        FJMP    lbjoin
lbmenu: FJMP    st_menu
lbbad:  LDI     FE_LEN
lbfail: PUTV    V_ERRC
        FJMP    lberr

; lberr -- the fetch failed: say so, then retry or open the menu.
        FIT     40
lberr:  PUTS    40H, s_neterr
        GETV    V_ERRC
        FCALL   d_hex
        OP      TOP_CLREOL
        PUTS    90H, s_retry
        BEEP    20
        FCALL   kwait
        BZ      lbe1
        FJMP    st_lobby
lbe1:   FJMP    st_menu

; lbjoin -- copy record D's id into V_TABLE and sit down.
        FIT     40
lbjoin: FCALL   trec
        VAR     V_TABLE
        LDI     NAMEMAX
        PLO     RC
lj1:    LDA     RB
        STR     RA
        BZ      lj2
        INC     RA
        DEC     RC
        GLO     RC
        BNZ     lj1
        LDI     0
        STR     RA
lj2:    FJMP    st_game

; lbrows -- the table rows.
        FIT     96
lbrows: SETV    V_ROW, 0
lr1:    GETV    V_ROW
        STR     R2
        GETV    V_NTBL
        XOR
        BZ      lr9
        GETV    V_ROW
        ADI     1
        SHL
        SHL
        SHL
        SHL
        FCALL   d_at
        OP      TOP_INV_ON
        GETV    V_ROW
        ADI     '1'
        FCALL   d_putc
        OP      TOP_INV_OFF
        GETV    V_ROW
        FCALL   trec
        LDI     TNAME
        FCALL   radd
        LDI     0
        PHI     R8
        LDI     11
        FCALL   rpu
        LDI     ' '
        FCALL   d_putc
        GETV    V_ROW
        FCALL   trec
        LDI     TPLAY
        FCALL   radd
        LDI     2
        PHI     R8
        LDI     3
        FCALL   rpu
        GETV    V_ROW
        ADI     1
        STR     RA
        BR      lr1
lr9:    FRET

; trec -- RB = table record D: FN_REPLY + 1 + D * TSTRIDE.
        FIT     24
trec:   PLO     RC
        LDR     RB, FN_REPLY+1
tr1:    GLO     RC
        BZ      tr9
        LDI     TSTRIDE
        FCALL   radd
        DEC     RC
        BR      tr1
tr9:    FRET
