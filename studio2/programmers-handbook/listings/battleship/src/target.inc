; target.inc -- aiming, on our turn.
;
; One cursor, on every live opponent's board at once, because one shot lands
; on all of them (gameLogic.go attack()). 1-9 move it the way the keypad is
; laid out, diagonals too, wrapping at the edges; 5 fires. A square every
; live opponent has already had shot is refused with a tone: the server would
; refuse it too, and the turn would not pass (the C client's rule).

; akey -- an aiming key, the digit in RC.0.
        FIT     72
akey:   GLO     RC
        XRI     5
        BNZ     ak1
        FJMP    afire
ak1:    GETV    V_CY
        PUTV    V_OLDY
        GLO     RC
        ADI     LO(dxt)
        FCALL   tbyte
        STR     R2
        GETV    V_CX
        ADD
        FCALL   wrap10
        PUTV    V_CX
        GLO     RC
        ADI     LO(dyt)
        FCALL   tbyte
        STR     R2
        GETV    V_CY
        ADD
        FCALL   wrap10
        PUTV    V_CY
        FCALL   mcur
        FCALL   aredraw
        FJMP    gw1

; wrap10 -- D mod 10, for D below 20.
        FIT     8
wrap10: SMI     10
        BDF     wr1
        ADI     10
wr1:    FRET

; aredraw -- the rows the cursor left and entered, on every live opponent.
        FIT     120
aredraw:
        SETV    V_BSEAT, 1
ard1:   GETV    V_PC
        STR     R2
        GETV    V_BSEAT
        SM
        BDF     ard9                    ; past the last seat
        GETV    V_BSEAT
        FCALL   prec
        LDI     PSTAT
        FCALL   radd
        LDN     RB
        BNZ     ard8                    ; sunk: no cursor there
        SETV    V_BMH, HI(MAP)
        FCALL   bsetup
        GETV    V_OLDY
        FCALL   trowof
        PUTV    V_BTR
        FCALL   bdrow
        GETV    V_CY
        FCALL   trowof
        STR     R2
        GETV    V_BTR
        XOR
        BZ      ard8                    ; the same row
        GETV    V_CY
        FCALL   trowof
        PUTV    V_BTR
        FCALL   bdrow
ard8:   GETV    V_BSEAT
        ADI     1
        STR     RA
        BR      ard1
ard9:   FRET

; trowof -- D = the text row (0-3) holding square row D.
trowof: ADI     LO(trow)
        FJMP    tbyte

; afire -- 5: fire at the cursor, if any live opponent is still open there.
        FIT     96
afire:  FCALL   cpos
        PUTV    V_SHOT
        SETV    V_CTR, 1
af1:    GETV    V_PC
        STR     R2
        GETV    V_CTR
        SM
        BDF     afno                    ; nobody left to ask
        GETV    V_CTR
        FCALL   prec
        LDI     PSTAT
        FCALL   radd
        LDN     RB
        BNZ     af2                     ; sunk
        LDI     PGF-PSTAT
        FCALL   radd
        GETV    V_SHOT
        FCALL   radd
        LDN     RB
        BZ      afyes                   ; open water to them
af2:    GETV    V_CTR
        ADI     1
        STR     RA
        BR      af1
afno:   BEEP    16
        FJMP    gw1
afyes:  SETV    V_REQ, REQ_ATTACK
        SETV    V_MODE, M_TEXT          ; until the reply says otherwise
        BEEP    6
        FJMP    gpoll
