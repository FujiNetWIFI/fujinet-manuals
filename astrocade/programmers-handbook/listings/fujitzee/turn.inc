; turn.inc -- your turn. Two cursor modes over one bounded input slice:
; DICE mode walks the ROLL tile and the five dice (trigger holds a die
; or submits the roll), SCORE mode walks the open scorecard rows
; (trigger takes the row). Stick-up crosses from dice to scores; down
; from the bottom of a column drops back to the dice while rolls
; remain.
;
; Like battleship's TARGET, TURNIN runs one bounded ~5 s slice and
; returns; GAMELP re-polls and re-enters while it is still our turn, so
; a game that ends (or a table that empties) is noticed within a slice.
; UIMODE/DCUR/SCUR/KEEPBF persist across slices; a keypress restarts
; the slice, and KEYSCN's edge detection means holding a key cannot
; spin it.
;
; The countdown reseeds from the wire's moveTime on every entry, so the
; calibrated-delay clock self-corrects each poll; at zero it bails --
; the server has already force-scored, and only the next poll can
; discover where the game went (the Intellivision lesson).
;
; V_FLAG on return: 0 slice out / timeout, 1 roll staged (KEEPBF),
; 2 score staged (SCOREIX), 3 leave, 4 help.

TURNIN: XOR     A
        LD      (V_FLAG),A
        LD      (TGFRM),A
        LD      HL,GOMVTIM
        CALL    RXGETB
        LD      (TGLEFT),A
        LD      B,250           ; ~5 s slice of 20 ms ticks
TILP:   PUSH    BC
        CALL    KEYSCN
        POP     BC
        OR      A
        JP      NZ,TIKEY
        PUSH    BC
        LD      DE,2500         ; ~20 ms
TIDLY:  DEC     DE
        LD      A,D
        OR      E
        JR      NZ,TIDLY
        LD      HL,TGFRM        ; the local second hand
        INC     (HL)
        LD      A,(HL)
        CP      50              ; 50 x 20 ms = 1 s
        JR      C,TINX
        LD      (HL),0
        LD      A,(TGLEFT)
        OR      A
        JR      Z,TIOUT         ; already zero: bail now
        DEC     A
        LD      (TGLEFT),A
        PUSH    AF
        LD      L,A             ; repaint the clock field
        LD      H,0
        CALL    U16STR
        LD      HL,LINBUF
        LD      DE,14*256+37
        LD      C,XRONF
        LD      B,3
        CALL    TXTN
        POP     AF
        OR      A
        JR      Z,TIOUT         ; hit zero: the server has skipped us
        CP      6
        CALL    C,SNDTICK       ; the last five seconds tick
TINX:   POP     BC
        DJNZ    TILP
        RET                     ; slice out: V_FLAG stays 0
TIOUT:  POP     BC              ; discard the slice counter
        RET
TIRST:  LD      B,250           ; a press restarts the slice
        JP      TILP

; ---- Key dispatch ----------------------------------------------------
TIKEY:  LD      C,A
        CP      'E'             ; leave -- handed back to GAMELP so the
        JR      NZ,TIK0         ; stack stays balanced
        LD      A,3
        LD      (V_FLAG),A
        RET
TIK0:   CP      '.'             ; help, same hand-back
        JR      NZ,TIK1
        LD      A,4
        LD      (V_FLAG),A
        RET
TIK1:   LD      A,(UIMODE)
        OR      A
        JP      NZ,TISCR

; ---- DICE mode -------------------------------------------------------
        LD      A,C
        CP      'L'
        JR      NZ,TID1
        LD      A,(DCUR)
        OR      A
        JR      NZ,TIDL1
        LD      A,6
TIDL1:  DEC     A
        LD      (DCUR),A
TIDMV:  CALL    SNDKEY
        CALL    DICEHUD
        JP      TIRST
TID1:   CP      'R'
        JR      NZ,TID2
        LD      A,(DCUR)
        INC     A
        CP      6
        JR      C,TIDR1
        XOR     A
TIDR1:  LD      (DCUR),A
        JR      TIDMV
TID2:   CP      'U'             ; up crosses to the score rows -- once
        JR      NZ,TID3         ; there are dice to score
        LD      HL,GODICE
        CALL    RXGETB
        OR      A
        JP      Z,TIBAD
        LD      A,1
        LD      (UIMODE),A
        CALL    SCURFX
        CALL    SNDSEL
        CALL    CARDRW          ; show the score cursor
        CALL    DICEHUD         ; clear the dice cursor
        JP      TIRST
TID3:   CP      'T'
        JP      NZ,TIRST
        LD      A,(DCUR)
        OR      A
        JR      Z,TIDROL
        DEC     A               ; a die: toggle held <-> re-roll
        LD      HL,KEEPBF
        ADD     A,L
        LD      L,A
        JR      NC,TIDT1
        INC     H
TIDT1:  LD      A,(HL)
        XOR     1               ; '0' <-> '1'
        LD      (HL),A
        CALL    SNDHLD
        CALL    DICEHUD
        JP      TIRST
TIDROL: LD      HL,GORLEFT      ; the ROLL tile: submit the roll
        CALL    RXGETB
        OR      A
        JP      Z,TIBAD         ; no rolls left
        LD      HL,KEEPBF       ; at least one die must move
        LD      B,5
TIDR2:  LD      A,(HL)
        CP      '1'
        JR      Z,TIDGO
        INC     HL
        DJNZ    TIDR2
        JP      TIBAD           ; everything held: nothing to roll
TIDGO:  LD      A,1
        LD      (V_FLAG),A
        JP      SNDROLL

; ---- SCORE mode ------------------------------------------------------
TISCR:  LD      A,C
        CP      'U'
        JR      NZ,TIS1
        LD      A,(SCUR)
        CALL    SKPUP
        JP      C,TIRST         ; already at the top
TISMV:  LD      (SCUR),A
        CALL    SNDKEY
        CALL    CARDRW
        JP      TIRST
TIS1:   CP      'D'
        JR      NZ,TIS2
        LD      A,(SCUR)
        CALL    SKPDN
        JR      NC,TISMV
        LD      HL,GORLEFT      ; off the bottom: back to the dice --
        CALL    RXGETB          ; unless the rolls are spent
        OR      A
        JP      Z,TIBAD
        XOR     A
        LD      (UIMODE),A
        CALL    SNDSEL
        CALL    CARDRW          ; clear the score cursor
        CALL    DICEHUD         ; show the dice cursor
        JP      TIRST
TIS2:   CP      'L'
        JR      Z,TISCOL
        CP      'R'
        JR      NZ,TIS3
TISCOL: LD      A,(SCUR)        ; the matching row of the other column
        CP      8
        JR      NC,TISC1
        ADD     A,8
        JR      TISC2
TISC1:  SUB     8
        CP      6               ; slot 14 maps beside the always-closed
        JR      C,TISC2         ; upper total: settle on the sixes row
        LD      A,5
TISC2:  LD      E,A
        CALL    VALIDC
        CP      0FFH
        LD      A,E
        JR      NZ,TISMV        ; open: land there
        CALL    SKPDN           ; closed: nearest open below, then above
        JR      NC,TISMV
        LD      A,E
        CALL    SKPUP
        JR      NC,TISMV
        JP      TIBAD           ; the whole column is closed
TIS3:   CP      'T'
        JP      NZ,TIRST
        LD      A,(SCUR)
        CALL    VALIDC
        CP      0FFH
        JP      Z,TIBAD         ; a closed row (should be unreachable)
        LD      E,A
        LD      A,(SCUR)
        LD      (SCOREIX),A
        LD      A,2
        LD      (V_FLAG),A
        LD      A,(SCUR)        ; the fanfare for a real fujitzee
        CP      SCFUJI
        JR      NZ,TISSC
        LD      A,E
        OR      A
        JR      Z,TISSC
        JP      SNDFUJI
TISSC:  JP      SNDSCOR

; A rejected press earns only a short slice: an accepted key restarting
; the full one is an aiming player, but a trigger bounced off a dead
; ROLL tile must not be able to starve the poll loop.
TIBAD:  CALL    SNDBAD
        LD      B,50            ; ~1 s
        JP      TILP

; ----------------------------------------------------------------------
; VALIDC: A = validScores[slot A]. FFH means the row is closed (or the
; server's own). Preserves BC,DE. Clobbers HL.
VALIDC: ADD     A,GOVALID
        LD      L,A
        LD      H,0
        JP      RXGETB

; SKPDN: from slot A, the next open row down the same column; carry set
; when there is none. SKPUP: the same, upward. The always-closed slots
; (the upper total and the bonus) skip like any other closed row.
; Clobber B,C,HL.
SKPDN:  CP      8
        LD      B,8             ; the left column ends before slot 8
        JR      C,SKD0
        LD      B,15
SKD0:   LD      C,A
SKD1:   INC     C
        LD      A,C
        CP      B
        JR      NC,SKDF
        CALL    VALIDC
        CP      0FFH
        JR      Z,SKD1
        LD      A,C
        OR      A               ; clear carry
        RET
SKDF:   SCF
        RET

SKPUP:  CP      8
        LD      B,0             ; the left column starts at slot 0
        JR      C,SKU0
        LD      B,8
SKU0:   LD      C,A
SKU1:   LD      A,C
        CP      B
        JR      Z,SKUF
        DEC     C
        LD      A,C
        CALL    VALIDC
        CP      0FFH
        JR      Z,SKU1
        LD      A,C
        OR      A
        RET
SKUF:   SCF
        RET

; PICKBEST: the score cursor onto the highest-paying open row (first
; wins a tie) -- the resting place once the rolls run out. Clobbers all.
PICKBEST: LD    B,0
        LD      C,0
        LD      E,0FFH          ; no candidate yet
PKB1:   LD      A,B
        CP      15
        JR      NC,PKB9
        CALL    VALIDC
        CP      0FFH
        JR      Z,PKB2
        LD      D,A
        LD      A,E
        CP      0FFH
        JR      Z,PKBT          ; the first open row is the baseline
        LD      A,D
        CP      E
        JR      C,PKB2
        JR      Z,PKB2
PKBT:   LD      E,D
        LD      C,B
PKB2:   INC     B
        JR      PKB1
PKB9:   LD      A,C
        LD      (SCUR),A
        RET

; SCURFX: keep the score cursor on an open row when entering the mode.
SCURFX: LD      A,(SCUR)
        CALL    VALIDC
        CP      0FFH
        RET     NZ
        JP      PICKBEST

; ----------------------------------------------------------------------
; KEEPRST: the mask back to roll-everything. KEEPSYN: restage it from
; the wire's echo after a roll lands (so the next submit re-rolls the
; same dice unless the player retunes it); an empty echo falls back to
; roll-everything.
KEEPRST: LD     HL,KEEPBF
        LD      B,5
KRS1:   LD      (HL),'1'
        INC     HL
        DJNZ    KRS1
        LD      (HL),0
        RET

KEEPSYN: LD     HL,GOKEEP
        LD      DE,KEEPBF
        LD      B,5
        CALL    RXSTRN
        LD      A,(KEEPBF)
        OR      A
        RET     NZ
        JR      KEEPRST
