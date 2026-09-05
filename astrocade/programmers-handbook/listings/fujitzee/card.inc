; card.inc -- the scorecard and the standings panel.
;
; The card is the intv port's compact two-column form: the viewed
; player's 16 slots in the left 15 columns (labels from cardst.inc,
; values here), with the reclaimed right half of the screen as an
; always-visible standings panel -- every seat's name, live running
; total, and a TURN tag. One card is shown at a time; GLWAIT pages it
; with left/right while it is someone else's turn.
;
; Everything renders straight out of the reply window. The only
; arithmetic in the whole client lives here: RUNTOT sums score slots
; 6-14, because the wire's grand total (slot 15) is empty until game
; over.

; PLBASE: HL = wire offset of player record A (GOPLYRS + A*42).
; Clobbers B,DE.
PLBASE: LD      HL,GOPLYRS
        OR      A
        RET     Z
        LD      B,A
        LD      DE,PLSTRID
PLB1:   ADD     HL,DE
        DJNZ    PLB1
        RET

; RDSCOR: DE = score word C (0-15) of the player record at wire offset
; HL. Preserves HL, C.
RDSCOR: PUSH    HL
        LD      A,C
        ADD     A,A
        ADD     A,PLSCORS
        LD      E,A
        LD      D,0
        ADD     HL,DE
        CALL    RXGETW
        POP     HL
        RET

; RUNTOT: HL = player A's running total: the sum of score slots 6-14
; (upper total, bonus, and the seven lower rows -- all kept current by
; the server, so the sum tracks the true score and equals the wire's
; grand total once the game ends). Any FFxxH word is an unset or
; spectator marker, never a score: skipped. Clobbers everything.
RUNTOT: CALL    PLBASE
        LD      (V_BASE),HL
        LD      HL,0
        LD      (V_TOT),HL
        LD      C,SCUPTOT
RTT1:   LD      A,C
        CP      15
        JR      NC,RTT9
        LD      HL,(V_BASE)
        CALL    RDSCOR
        LD      A,D
        CP      0FFH
        JR      Z,RTT3
        LD      HL,(V_TOT)
        ADD     HL,DE
        LD      (V_TOT),HL
RTT3:   INC     C
        JR      RTT1
RTT9:   LD      HL,(V_TOT)
        RET

; DECFLD: HL as decimal, right-justified space-padded into a B-cell
; field at LINBUF (NUL-terminated). A value wider than the field is
; left as-is (TXTN's cell count truncates it). Clobbers everything.
DECFLD: PUSH    BC
        CALL    U16STR
        POP     BC
        LD      HL,LINBUF
        LD      C,0
DFL1:   LD      A,(HL)
        OR      A
        JR      Z,DFL2
        INC     HL
        INC     C
        JR      DFL1
DFL2:   LD      A,B             ; the shift = width - length
        SUB     C
        RET     Z
        RET     C
        LD      (V_ST),A
        LD      E,A             ; slide the digits (and the NUL) right
        LD      D,0
        PUSH    HL
        ADD     HL,DE
        EX      DE,HL           ; DE = destination end
        POP     HL              ; HL = source end (the NUL)
        LD      B,0
        INC     C               ; the length plus the NUL
        LDDR
        LD      A,(V_ST)        ; space-fill the vacated front
        LD      B,A
        LD      HL,LINBUF
DFL3:   LD      (HL),' '
        INC     HL
        DJNZ    DFL3
        RET

; ----------------------------------------------------------------------
; CARDRW: the viewed player's 16 value cells. Potentials (what an open
; row would earn, in red, from validScores) appear only on your own
; card, on your turn, once the dice exist -- GOVALID is all zeros in
; the lobby and meaningless on anyone else's card.
CARDRW: LD      A,(VIEWIDX)
        CALL    PLBASE
        LD      (V_BASE),HL
        XOR     A               ; V_TM2 = potentials mode
        LD      (V_TM2),A
        LD      A,(VIEWIDX)
        OR      A
        JR      NZ,CDW0
        LD      A,(V_MYTRN)
        OR      A
        JR      Z,CDW0
        LD      HL,GODICE
        CALL    RXGETB
        OR      A
        JR      Z,CDW0
        LD      A,1
        LD      (V_TM2),A
CDW0:   XOR     A
        LD      (V_CAT),A
CDW1:   LD      A,(V_CAT)
        CP      16
        RET     NC
        CALL    SCELL
        LD      A,(V_CAT)
        INC     A
        LD      (V_CAT),A
        JR      CDW1

; SCELL: one value cell for slot (V_CAT). Filled scores in white; an
; open row's potential in red (a zero only under the cursor); closed or
; unavailable rows as a black dash; the score cursor's cell inverse.
; Slot 15 shows the running total instead of the wire's empty word.
SCELL:  LD      A,(V_CAT)
        CP      15
        JR      Z,SCTOT
        LD      HL,(V_BASE)
        LD      C,A
        CALL    RDSCOR
        LD      A,D
        CP      0FFH
        JR      Z,SCUNS
        EX      DE,HL           ; filled: the value, white
        LD      B,3
        CALL    DECFLD
        LD      C,XWONF
        JR      SCDRW
SCUNS:  LD      A,(V_TM2)       ; unset: a potential, or a dash
        OR      A
        JR      Z,SCDASH
        LD      A,(V_CAT)
        CP      SCUPTOT         ; 6 and 7 are the server's rows: never
        JR      Z,SCDASH        ; selectable, no potential to show
        CP      SCBONUS
        JR      Z,SCDASH
        CALL    VALIDC
        CP      0FFH
        JR      Z,SCDASH
        LD      E,A
        OR      A
        JR      NZ,SCPOT
        CALL    SCCURQ          ; a zero: visible only under the cursor
        JR      NZ,SCBLNK
SCPOT:  LD      L,E
        LD      H,0
        LD      B,3
        CALL    DECFLD
        LD      C,XRONF
        JR      SCDRW
SCBLNK: LD      HL,TNUL
        LD      C,XWONF
        JR      SCDRW2
SCDASH: LD      HL,TDASH
        LD      C,XKONF
        JR      SCDRW2
SCTOT:  LD      A,(VIEWIDX)
        CALL    RUNTOT
        LD      B,3
        CALL    DECFLD
        LD      C,XWONF
SCDRW:  LD      HL,LINBUF
SCDRW2: CALL    SCCURQ          ; the cursor's cell draws inverse
        JR      NZ,SCDRW3
        LD      C,XFONW
SCDRW3: LD      A,(V_CAT)
        PUSH    HL              ; CATPOS clobbers HL, the string
        CALL    CATPOS
        POP     HL
        LD      B,3
        JP      TXTN

; SCCURQ: Z set when the score cursor is visible and sits on (V_CAT).
; Preserves HL, DE, BC.
SCCURQ: LD      A,(V_TM2)       ; potentials mode implies my card, my turn
        OR      A
        JR      Z,SCCQN
        LD      A,(UIMODE)
        OR      A
        JR      Z,SCCQN
        LD      A,(SCUR)
        PUSH    HL
        LD      HL,V_CAT
        CP      (HL)
        POP     HL
        RET
SCCQN:  OR      1               ; force NZ
        RET

; ----------------------------------------------------------------------
; PANEL: the standings, rows 1-6, char cols 17-39: name (inverse when
; that card is on screen, black for a spectator), running total, and a
; red TURN tag on the active seat. Absent seats blank themselves via
; the fixed-width fields; row 7 counts any seats past the six shown.
PANEL:  XOR     A
        LD      (V_TMP),A
PANL:   LD      A,(V_TMP)
        CP      6
        JP      NC,PANVW
        LD      HL,V_PC
        CP      (HL)
        JP      NC,PANBLK
        CALL    PLBASE
        PUSH    HL
        LD      DE,LINBUF
        LD      B,9
        CALL    RXSTRN
        POP     HL
        LD      C,0             ; scores[0] = FFFEH marks a spectator
        CALL    RDSCOR
        LD      A,D
        CP      0FFH
        JR      NZ,PANP1
        LD      A,E
        CP      0FEH
        JR      NZ,PANP1
        LD      A,(V_TMP)       ; spectator: black name, nothing else
        INC     A
        LD      D,A
        LD      E,17
        LD      HL,LINBUF
        LD      C,XKONF
        LD      B,23
        CALL    TXTN
        JP      PANNXT
PANP1:  LD      A,(V_TMP)       ; the name; the viewed card's owner inverse
        LD      HL,VIEWIDX
        CP      (HL)
        LD      C,XFONW
        JR      Z,PANP2
        LD      C,XWONF
PANP2:  LD      A,(V_TMP)
        INC     A               ; panel rows 1-6
        LD      D,A
        LD      E,17
        LD      HL,LINBUF
        LD      B,9
        CALL    TXTN
        LD      A,(V_TMP)       ; the running total
        CALL    RUNTOT
        LD      B,4
        CALL    DECFLD
        LD      A,(V_TMP)
        INC     A
        LD      D,A
        LD      E,27
        LD      HL,LINBUF
        LD      C,XWONF
        LD      B,4
        CALL    TXTN
        LD      A,(V_TMP)       ; the TURN tag
        LD      HL,V_ACT
        CP      (HL)
        LD      HL,TTURN
        JR      Z,PANT1
        LD      HL,TNUL
PANT1:  LD      A,(V_TMP)
        INC     A
        LD      D,A
        LD      E,32
        LD      C,XRONF
        LD      B,4
        CALL    TXTN
        JR      PANNXT
PANBLK: LD      A,(V_TMP)       ; absent seat: blank the row
        INC     A
        LD      D,A
        LD      E,17
        LD      HL,TNUL
        LD      C,XWONF
        LD      B,23
        CALL    TXTN
PANNXT: LD      A,(V_TMP)
        INC     A
        LD      (V_TMP),A
        JP      PANL
PANVW:  LD      A,(V_PC)        ; row 7: "+N VIEW" when seats overflow
        SUB     6
        JR      C,PANVB
        JR      Z,PANVB
        ADD     A,'0'
        LD      (LINBUF+1),A
        LD      A,'+'
        LD      (LINBUF),A
        LD      HL,TVIEW2
        LD      DE,LINBUF+2
PANVC:  LD      A,(HL)
        LD      (DE),A
        INC     HL
        INC     DE
        OR      A
        JR      NZ,PANVC
        LD      HL,LINBUF
        JR      PANVD
PANVB:  LD      HL,TNUL
PANVD:  LD      DE,7*256+17
        LD      C,XWONF
        LD      B,8
        JP      TXTN

TVIEW2: DB      " VIEW",0
TDASH:  DB      "  -",0
