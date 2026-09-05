; edit.inc -- the on-screen grid keyboard.
;
; Descended from fujinet-config/astrocade/edit.inc, but the 4x6 renderer
; changes the shape of the problem: 40 columns fit all 96 printable
; characters at once as 32x3, so config's CASE toggle and its whole action
; row disappear. The keypad supplies the actions instead.
;
; Five rows, drawn at a caller-supplied top row, so the dial screen and the
; in-session composer are the same code at different heights:
;
;   +0        the value line, tail-anchored, with an inverse cursor cell
;   +1..+3    the grid: cell (gx,gy) is character 20H + gy*32 + gx
;   +4        the hint line
;
; Contract, kept from config: the caller preloads EDBUF (NUL-terminated),
; EDMAX, EDTOPR and EDHNT, and the editor runs NO transactions -- so a reply
; window the caller is holding stays valid across an edit. Carry set on
; cancel; EDBUF is mutated either way.

EGW     EQU     32              ; grid cells per row
EGROWS  EQU     3
EGX     EQU     (TCOLS-EGW)/2   ; centred: 4
EVWID   EQU     TCOLS-1         ; value characters shown; the last cell is
                                ; the cursor block

; EDIT: run the editor. Carry set on cancel. Clobbers everything.
EDIT:   CALL    EDRAWA
ELOOP:  CALL    INWAIT
        CP      EVTRIG
        JR      Z,EPICK
        CP      EVLEFT
        JR      Z,EMVL
        CP      EVRIGHT
        JR      Z,EMVR
        CP      EVUP
        JR      Z,EMVU
        CP      EVDOWN
        JR      Z,EMVD
        CP      EVEQ
        JR      Z,EACC
        CP      EVCE
        JR      Z,EDEL
        CP      EVCLR
        JR      Z,ECAN
        CALL    EVTOCH          ; a keypad key that types a character
        OR      A
        JR      Z,ELOOP
        JR      EINS

EACC:   OR      A               ; accept: carry clear
        RET
ECAN:   SCF                     ; cancel
        RET

; ---- movement. A move repaints the whole grid rather than tracking the
; cell it left: 96 glyphs is about 8 ms, well inside the repeat rate, and it
; costs no state.
EMVL:   LD      A,(V_GX)
        DEC     A
        JP      P,EMVX
        LD      A,EGW-1
        JR      EMVX
EMVR:   LD      A,(V_GX)
        INC     A
        CP      EGW
        JR      C,EMVX
        XOR     A
EMVX:   LD      (V_GX),A
        JR      EDMOV
EMVU:   LD      A,(V_GY)
        DEC     A
        JP      P,EMVY
        LD      A,EGROWS-1
        JR      EMVY
EMVD:   LD      A,(V_GY)
        INC     A
        CP      EGROWS
        JR      C,EMVY
        XOR     A
EMVY:   LD      (V_GY),A
EDMOV:  CALL    EDGRID
        JR      ELOOP

; ---- the buffer
EPICK:  LD      A,(V_GY)        ; the cell under the cursor IS the character
        ADD     A,A
        ADD     A,A
        ADD     A,A
        ADD     A,A
        ADD     A,A             ; gy*32
        LD      HL,V_GX
        ADD     A,(HL)
        ADD     A,20H
        ; falls into EINS

; EINS: append the character in A, if there is room.
EINS:   LD      C,A
        CALL    EDLEN
        LD      HL,EDMAX
        CP      (HL)
        JR      NC,EDRW1        ; full
        LD      E,A
        LD      D,0
        LD      HL,EDBUF
        ADD     HL,DE
        LD      (HL),C
        INC     HL
        LD      (HL),0
        JR      EDRW1

EDEL:   CALL    EDLEN
        OR      A
        JR      Z,EDRW1
        DEC     A
        LD      E,A
        LD      D,0
        LD      HL,EDBUF
        ADD     HL,DE
        LD      (HL),0
EDRW1:  CALL    EDRAWV
        JP      ELOOP

; EDLEN: A = the length of EDBUF. Clobbers B,H,L.
EDLEN:  LD      HL,EDBUF
        LD      B,0
EDL1:   LD      A,(HL)
        OR      A
        JR      Z,EDL2
        INC     HL
        INC     B
        JR      EDL1
EDL2:   LD      A,B
        RET

; ---- drawing
; EDRAWA: the whole editor. Clobbers everything.
EDRAWA: LD      A,(EDTOPR)
        LD      B,5
        CALL    CLRRWS
        CALL    EDGRID
        CALL    EDHINT
        ; falls into EDRAWV

; EDRAWV: the value line. Shows the tail when the buffer is longer than the
; row, so the end being typed is always visible.
EDRAWV: CALL    EDLEN
        LD      HL,EDBUF
        CP      EVWID
        JR      C,EDV1
        SUB     EVWID           ; scroll the window to the tail
        LD      E,A
        LD      D,0
        ADD     HL,DE
        LD      A,EVWID
EDV1:   LD      (EDVN),A
        LD      A,(EDTOPR)
        LD      D,A
        LD      E,0
        LD      C,XWONK
        LD      B,TCOLS
        CALL    TXTN            ; pads the rest of the row with spaces
        LD      A,(EDTOPR)
        LD      D,A
        LD      A,(EDVN)
        LD      E,A
        LD      C,XKONW
        XOR     A               ; a space in inverse: the cursor block
        JP      GLYPH1

; EDHINT: the hint line.
EDHINT: LD      A,(EDTOPR)
        ADD     A,4
        LD      D,A
        LD      E,0
        LD      C,XAONK
        LD      HL,(EDHNT)
        LD      B,TCOLS
        JP      TXTN

; EDGRID: all 96 cells, the selected one inverse.
EDGRID: LD      B,0
EDG1:   PUSH    BC
        LD      A,B
        CALL    EDCELL
        POP     BC
        INC     B
        LD      A,B
        CP      EGW*EGROWS
        JR      C,EDG1
        RET

; EDCELL: draw grid cell index A (0-95). The cell index IS the glyph index,
; because both spaces start at 20H.
EDCELL: LD      (EDCIX),A
        LD      B,0
EDC1:   CP      EGW
        JR      C,EDC2
        SUB     EGW
        INC     B
        JR      EDC1
EDC2:   LD      C,A             ; B = gy, C = gx
        LD      A,(V_GY)
        CP      B
        JR      NZ,EDC3
        LD      A,(V_GX)
        CP      C
        JR      NZ,EDC3
        LD      A,XKONW
        JR      EDC4
EDC3:   LD      A,XWONK
EDC4:   PUSH    AF
        LD      A,(EDTOPR)
        INC     A
        ADD     A,B
        LD      D,A
        LD      A,C
        ADD     A,EGX
        LD      E,A
        POP     AF
        LD      C,A
        LD      A,(EDCIX)
        JP      GLYPH1
