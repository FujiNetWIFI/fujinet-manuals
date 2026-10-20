; url.inc -- the devicespec, streamed into the TX stream a byte at a time and
; never assembled in RAM. A /place request is about 110 bytes of the 320 a
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

; txdec -- append D (0-255) in decimal, no leading zeros.
        FIT     64
txdec:  PLO     R9
        LDI     0
        PHI     R9                      ; a digit has been sent
        LDI     100
        FCALL   txd1
        LDI     10
        FCALL   txd1
        GLO     R9
        ADI     '0'
        FJMP    fn_txb
txd1:   PLO     RC                      ; one digit: R9.0 / D
        LDI     0
        PHI     RC
txd2:   GLO     RC
        STR     R2
        GLO     R9
        SM
        BNF     txd3
        PLO     R9
        GHI     RC
        ADI     1
        PHI     RC
        BR      txd2
txd3:   GHI     RC
        BNZ     txd4
        GHI     R9
        BZ      txd5                    ; a leading zero
txd4:   LDI     1
        PHI     R9
        GHI     RC
        ADI     '0'
        FCALL   fn_txb
txd5:   FRET

; bldurl -- the devicespec for V_REQ: N:<endpoint> then
;   tables?bin=1
;   state | ready/1 | ready/0 | place/a,b,c,d,e | attack/p | leave,
;   then ?table=<id>&player=<name>&bin=1&v=2
; v=2 makes activePlayer the winner at game over and adds the winner's
; ships (util.go).
        FIT     112
bldurl: LDR     R8, UENDPT
        FCALL   txs
        GETV    V_REQ
        BNZ     bu1
        LDR     R8, utabls              ; no table, no player
        FJMP    txs
bu1:    SMI     REQ_ATTACK+1            ; past attack: leave
        BDF     bu7
        LDR     RB, upaths-2            ; a request with a fixed path
        GETV    V_REQ
        SHL
        FCALL   radd
        LDA     RB
        PHI     R8
        LDN     RB
        PLO     R8
        FCALL   txs
        GETV    V_REQ
        XRI     REQ_PLACE
        BNZ     bu2
        FCALL   txplace
        BR      bu8
bu2:    GETV    V_REQ
        XRI     REQ_ATTACK
        BNZ     bu8
        GETV    V_SHOT
        FCALL   txdec
        BR      bu8
bu7:    LDR     R8, uleave
        FCALL   txs
bu8:    LDR     R8, uqtab
        FCALL   txs
        LDR     R8, V_TABLE
        FCALL   txenc
        LDR     R8, uqplr
        FCALL   txs
        LDR     R8, V_NAME
        FCALL   txenc
        LDR     R8, uqbin
        FJMP    txs

; txplace -- the five placements, pos + 100 * dir, comma separated.
        FIT     64
txplace:
        SETV    V_CTR, 0
txp1:   GETV    V_CTR                   ; y * 10 + x
        ADI     LO(V_SY)
        PLO     RA
        LDN     RA
        ADI     LO(mul10)
        PLO     R8
        LDI     HI(mul10)
        PHI     R8
        LDN     R8
        STR     R2
        GETV    V_CTR
        ADI     LO(V_SX)
        PLO     RA
        LDN     RA
        ADD
        STR     R2
        GETV    V_CTR                   ; + 100 if down
        ADI     LO(V_SD)
        PLO     RA
        LDN     RA
        BZ      txp2
        LDI     100
txp2:   ADD
        FCALL   txdec
        GETV    V_CTR
        ADI     1
        STR     RA
        XRI     NSHIPS
        BZ      txp9
        LDI     ','
        FCALL   fn_txb
        BR      txp1
txp9:   FRET

upaths: DW      ustate, urdy1, urdy0, uplace, uattk
utabls: DB      "tables?bin=1", 0
ustate: DB      "state", 0
urdy1:  DB      "ready/1", 0
urdy0:  DB      "ready/0", 0
uplace: DB      "place/", 0
uattk:  DB      "attack/", 0
uleave: DB      "leave", 0
uqtab:  DB      "?table=", 0
uqplr:  DB      "&player=", 0
uqbin:  DB      "&bin=1&v=2", 0
