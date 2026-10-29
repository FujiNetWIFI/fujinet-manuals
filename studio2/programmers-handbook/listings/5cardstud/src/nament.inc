; nament.inc -- the player name: read it, or type it.
;
; st_start reads the username every client in the family shares (the appkey
; at creator 1, app 1, key 0) and only opens the editor when that is empty or
; unreadable, so typing it once on any console is enough for all of them.
;
; The editor is a 16x3 character grid driven from pad A like a game: 2 4 6 8
; move, 5 types the character under the cursor, 1 deletes, 3 is done, 0
; leaves it unchanged (when there was a name to keep). The grid holds only
; characters a URL carries as they are.

; st_start -- fetch the name, or type one.
        FIT     96
st_start:
        RESET
        FCALL   d_cls
        PUTS    00H, s_title
        PUTS    40H, s_chkname
        LDI     AKREAD
        FCALL   akopen
        BNZ     sts9
        FCALL   akread
        BNZ     sts9
        LDI     1
        FCALL   rpeek                   ; the length, hi
        BNZ     sts1                    ; 256 or more: take NAMEMAX
        LDI     0
        FCALL   rpeek
        BZ      sts9                    ; an empty key
        SMI     NAMEMAX+1
        BNF     sts2
sts1:   LDI     NAMEMAX
        BR      sts3
sts2:   LDN     RB                      ; RB is still on the length
sts3:   PLO     RC
        LDR     RB, FN_REPLY+2
        VAR     V_NAME
sts4:   GLO     RC
        BZ      sts5
        LDA     RB
        BZ      sts5
        STR     RA
        INC     RA
        DEC     RC
        BR      sts4
sts5:   LDI     0
        STR     RA
        GETV    V_NAME
        BZ      sts9
        FJMP    st_lobby
sts9:   FJMP    st_edit

; st_edit -- type a name, starting from V_NAME.
        FIT     80
st_edit:
        RESET
        LDR     R8, V_NAME              ; seed the buffer
        VAR     V_EDBUF
        LDI     0
        PLO     RC
ste1:   LDA     R8
        STR     RA
        BZ      ste2
        INC     RA
        INC     RC
        GLO     RC
        XRI     NAMEMAX
        BNZ     ste1
        LDI     0
        STR     RA
ste2:   GLO     RC
        PUTV    V_EDLEN
        SETV    V_EDX, 0
        SETV    V_EDY, 0
        FCALL   d_cls
        PUTS    00H, s_title
        PUTS    20H, s_yourname
        PUTS    80H, s_edleg1
        PUTS    90H, s_edleg2
        FJMP    edloop

        FIT     120
edloop: FCALL   eddraw
edk:    FCALL   in_get                  ; repeats while held: the grid is big
        BZ      edk
        ANI     0FH
        PLO     RC
        BEEP    2                       ; BEEP is an LDI: D is gone
        GLO     RC
        XRI     2
        BZ      edup
        GLO     RC
        XRI     8
        BZ      eddn
        GLO     RC
        XRI     4
        BZ      edlt
        GLO     RC
        XRI     6
        BZ      edrt
        GLO     RC
        XRI     5
        BZ      edtype
        GLO     RC
        XRI     1
        BZ      eddel
        GLO     RC
        XRI     3
        BZ      eddone
        GLO     RC
        BNZ     edk
        GETV    V_NAME                  ; 0: keep the old name, if any
        BZ      edk
        FJMP    st_lobby
edup:   GETV    V_EDY
        BNZ     edup1
        LDI     3
edup1:  SMI     1
        BR      edy
eddn:   GETV    V_EDY
        ADI     1
        XRI     3
        BZ      edy                     ; row 2 wraps to 0
        XRI     3
edy:    PUTV    V_EDY
        BR      edloop
edlt:   GETV    V_EDX
        SMI     1
        BR      edx
edrt:   GETV    V_EDX
        ADI     1
edx:    ANI     0FH
        PUTV    V_EDX
        BR      edloop
eddone: GETV    V_EDLEN
        BZ      edk
        FJMP    edsave
edtype: FJMP    edins
eddel:  FJMP    edrub

; edins -- type the character under the cursor.
        FIT     64
edins:  FCALL   edchar
        XRI     ' '
        BZ      edin9                   ; a blank cell
        GETV    V_EDLEN
        XRI     NAMEMAX
        BZ      edin9                   ; full
        GETV    V_EDLEN
        ADI     LO(V_EDBUF)
        PLO     RA
        LDN     RB                      ; edchar left RB on the character
        STR     RA
        INC     RA
        LDI     0
        STR     RA
        GETV    V_EDLEN
        ADI     1
        PUTV    V_EDLEN
edin9:  FJMP    edloop

; edrub -- delete the last character.
        FIT     24
edrub:  GETV    V_EDLEN
        BZ      edrb9
        SMI     1
        PUTV    V_EDLEN
        ADI     LO(V_EDBUF)
        PLO     RA
        LDI     0
        STR     RA
edrb9:  FJMP    edloop

; edchar -- RB on the grid character under the cursor; D = it.
        FIT     32
edchar: LDR     RB, grid
        GETV    V_EDY
        PLO     RC
edc1:   GLO     RC
        BZ      edc2
        LDI     17
        FCALL   radd
        DEC     RC
        BR      edc1
edc2:   GETV    V_EDX
        FCALL   radd
        LDN     RB
        FRET

; eddraw -- the name line and the grid, the cursor cell inverse.
        FIT     72
eddraw: AT      34H
        LDR     R8, V_EDBUF
        FCALL   d_puts
        GETV    V_EDLEN
        XRI     NAMEMAX
        BZ      edd1
        LDI     '_'
        FCALL   d_putc
edd1:   OP      TOP_CLREOL
        PUTS    50H, grid
        PUTS    60H, grid+17
        PUTS    70H, grid+34
        GETV    V_EDY                   ; the cursor: row 5 + y, column x
        ADI     5
        SHL
        SHL
        SHL
        SHL
        STR     R2
        GETV    V_EDX
        OR
        FCALL   d_at
        OP      TOP_INV_ON
        FCALL   edchar
        FCALL   d_putc
        OP      TOP_INV_OFF
        FRET

; edsave -- keep the name, remember it for every console, and play.
        FIT     40
edsave: LDR     R8, V_EDBUF
        VAR     V_NAME
eds1:   LDA     R8
        STR     RA
        INC     RA
        BNZ     eds1
        AT      40H
        LDR     R8, s_saving
        FCALL   d_puts
        LDI     AKWRITE
        FCALL   akopen
        BNZ     eds9                    ; no appkey storage: play on regardless
        FCALL   akwrite
eds9:   FJMP    st_lobby

grid:   DB      "ABCDEFGHIJKLMNOP", 0
        DB      "QRSTUVWXYZ012345", 0
        DB      "6789-_.         ", 0
