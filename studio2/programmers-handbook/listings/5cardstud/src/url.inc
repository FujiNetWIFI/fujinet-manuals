; url.inc -- the devicespec, streamed into the TX stream a byte at a time and
; never assembled in RAM. A /move request is about 90 bytes of the 320 a
; transaction carries. The table id and the name are percent-encoded: the
; name may come from another console's appkey, and a space or an '&' in it
; would otherwise end the query early.

; txs -- append the NUL-terminated string at R8.
        FIT     16
txs:    LDI     HI(FN_TXDATA)
        PHI     RF
txs1:   LDA     R8
        BZ      txs9
        PLO     RF
        LDN     RF
        BR      txs1
txs9:   LDI     FN_PARK
        PHI     RF
        FRET

; txenc -- append the string at R8, every byte but A-Z a-z 0-9 - _ . ~ as %XX.
        FIT     80
txenc:  LDA     R8
        BZ      txe9
        PLO     R9
        XRI     '-'
        BZ      txok
        GLO     R9
        XRI     '_'
        BZ      txok
        GLO     R9
        XRI     '.'
        BZ      txok
        GLO     R9
        XRI     '~'
        BZ      txok
        GLO     R9
        SMI     '0'
        BNF     txpct
        SMI     10
        BNF     txok                    ; a digit
        GLO     R9
        ORI     20H
        SMI     'a'
        BNF     txpct
        SMI     26
        BNF     txok                    ; a letter
txpct:  LDI     '%'
        FCALL   fn_txb
        GLO     R9
        SHR
        SHR
        SHR
        SHR
        FCALL   hexc
        FCALL   fn_txb
        GLO     R9
        ANI     0FH
        FCALL   hexc
txok1:  FCALL   fn_txb
        BR      txenc
txok:   GLO     R9
        BR      txok1
txe9:   FRET

; hexc -- D = the hex digit for the nibble in D.
        FIT     12
hexc:   SMI     10
        BDF     hexc1
        ADI     '0'+10
        FRET
hexc1:  ADI     'A'
        FRET

; bldurl -- the devicespec for V_REQ: N:<endpoint> then
;   tables?bin=1
;   state | move/<code> | leave, then ?table=<id>&player=<name>&bin=1
        FIT     96
bldurl: LDR     R8, UENDPT
        FCALL   txs
        GETV    V_REQ
        BNZ     bu1
        LDR     R8, utabls              ; no table, no player
        FJMP    txs
bu1:    XRI     REQ_STATE
        BNZ     bu2
        LDR     R8, ustate
        BR      bu4
bu2:    GETV    V_REQ
        XRI     REQ_MOVE
        BNZ     bu3
        LDR     R8, umove
        FCALL   txs
        GETV    V_MOVE
        FCALL   fn_txb
        GETV    V_MOVE+1
        FCALL   fn_txb
        BR      bu5
bu3:    LDR     R8, uleave
bu4:    FCALL   txs
bu5:    LDR     R8, uqtab
        FCALL   txs
        LDR     R8, V_TABLE
        FCALL   txenc
        LDR     R8, uqplr
        FCALL   txs
        LDR     R8, V_NAME
        FCALL   txenc
        LDR     R8, uqbin
        FJMP    txs

utabls: DB      "tables?bin=1", 0
ustate: DB      "state", 0
umove:  DB      "move/", 0
uleave: DB      "leave", 0
uqtab:  DB      "?table=", 0
uqplr:  DB      "&player=", 0
uqbin:  DB      "&bin=1", 0
