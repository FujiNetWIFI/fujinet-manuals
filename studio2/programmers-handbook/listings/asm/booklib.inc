; booklib.inc -- what this handbook's programs
; share: a transaction that must succeed, the
; failure screen, strings into the TX stream and
; short waits. Include after ORG 0C00H. FCALLed;
; may clobber R8 and R9, like the runtime.

; go_ack -- fn_go, then fn_ack: D = 0, or the
; error (FNE* or the cart's FN_ERR).
        FIT     12
go_ack: FCALL   fn_go
        BNZ     gak1
        FCALL   fn_ack
gak1:   FRET

; fn_str -- append the NUL-terminated string at
; R8 to the TX stream: a payload, not padded.
        FIT     16
fn_str: LDA     R8
        BZ      fst1
        HOT     HI(FN_TXDATA)
        BR      fn_str
fst1:   FRET

; pause -- wait D frames; RE counts them.
        FIT     16
pause:  PLO     R9
pse1:   GLO     RE
        STR     R2
pse2:   GLO     RE
        XOR
        BZ      pse2
        DEC     R9
        GLO     R9
        BNZ     pse1
        FRET

; fail -- FJMP here with D = the error: FAILED
; and the code on the last row, and stop.
        FIT     40
fail:   PLO     RA
        PUTS    90H, t_fail
        GLO     RA
        FCALL   d_hex
fl1:    BR      fl1
t_fail: DB      "FAILED E", 0
