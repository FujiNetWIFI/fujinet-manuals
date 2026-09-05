; target.inc -- your turn. One cursor, in lockstep over every live enemy
; quadrant: the server's core multiplayer rule is that a single shot
; fires at that coordinate on every other playing board at once, so
; there is only ever one position to choose, not one per opponent.
;
; Unlike the Intellivision's fully-blocking loop, TARGET runs one
; bounded ~5 s slice and returns no-fire; GAMELP re-polls and re-enters
; while it is still our turn. The client keeps polling even inside the
; 250-second single-player clock, so a game that ends (or a table that
; empties) is noticed within a slice. TGX/TGY persist -- the cursor
; resumes where it left off, across slices and turns alike. A keypress
; restarts the slice: an actively-aiming player is not interrupted, and
; KEYSCN's edge detection means holding a key cannot spin it.
;
; The countdown reseeds from the wire's moveTime on every entry, so the
; calibrated-delay clock self-corrects each poll; at zero it bails --
; the server has already skipped the turn, and only the next poll can
; discover where the game went (the Intellivision lesson).
;
; V_FLAG on return: 0 slice out / timeout, 1 fired (ATKPOS staged),
; 2 leave, 3 help.

TARGET: XOR     A
        LD      (V_FLAG),A
        LD      (TGFRM),A
        LD      (V_BLNK),A
        LD      HL,GOMVTIM
        CALL    RXGETB
        LD      (TGLEFT),A
        CALL    TGDRW
        LD      B,250           ; ~5 s slice of 20 ms ticks
TGLP:   PUSH    BC
        CALL    KEYSCN
        POP     BC
        OR      A
        JP      NZ,TGKEY
        PUSH    BC
        LD      DE,2500         ; ~20 ms
TGDLY:  DEC     DE
        LD      A,D
        OR      E
        JR      NZ,TGDLY
        LD      HL,V_BLNK       ; ring <-> truth every ~320 ms
        INC     (HL)
        LD      A,(HL)
        AND     0FH
        JR      NZ,TGSEC
        LD      A,(HL)
        AND     10H
        JR      Z,TGBL1
        CALL    TGDRW
        JR      TGSEC
TGBL1:  CALL    TGERS
TGSEC:  LD      HL,TGFRM        ; the local second hand
        INC     (HL)
        LD      A,(HL)
        CP      50              ; 50 x 20 ms = 1 s
        JR      C,TGNX
        LD      (HL),0
        LD      A,(TGLEFT)
        OR      A
        JR      Z,TGOUT         ; already zero: bail now
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
        JR      Z,TGOUT         ; hit zero: the server has skipped us
        CP      6
        CALL    C,SNDTICK       ; the last five seconds tick
TGNX:   POP     BC
        DJNZ    TGLP
        JP      TGERS           ; slice out: erase, V_FLAG stays 0
TGOUT:  POP     BC              ; discard the slice counter
        JP      TGERS
TGKEY:  CP      'U'
        JR      NZ,TGK1
        LD      A,(TGY)
        OR      A
        JR      Z,TGLP2
        CALL    TGERS
        LD      HL,TGY
        DEC     (HL)
TGMV:   CALL    SNDKEY
        CALL    TGDRW
TGLP2:  LD      B,250           ; a press restarts the slice
        JP      TGLP
TGK1:   CP      'D'
        JR      NZ,TGK2
        LD      A,(TGY)
        CP      9
        JR      NC,TGLP2
        CALL    TGERS
        LD      HL,TGY
        INC     (HL)
        JR      TGMV
TGK2:   CP      'L'
        JR      NZ,TGK3
        LD      A,(TGX)
        OR      A
        JR      Z,TGLP2
        CALL    TGERS
        LD      HL,TGX
        DEC     (HL)
        JR      TGMV
TGK3:   CP      'R'
        JR      NZ,TGK4
        LD      A,(TGX)
        CP      9
        JR      NC,TGLP2
        CALL    TGERS
        LD      HL,TGX
        INC     (HL)
        JR      TGMV
TGK4:   CP      'T'             ; fire
        JR      NZ,TGK5
        CALL    TGERS
        LD      A,(TGY)
        CALL    MUL10
        LD      HL,TGX
        ADD     A,(HL)
        LD      (ATKPOS),A
        LD      A,1
        LD      (V_FLAG),A
        JP      SNDSEL
TGK5:   CP      'E'             ; leave -- handed back to GAMELP so the
        JR      NZ,TGK6         ; stack stays balanced
        LD      A,2
        LD      (V_FLAG),A
        JP      TGERS
TGK6:   CP      '.'             ; help, same hand-back
        JR      NZ,TGLP2
        LD      A,3
        LD      (V_FLAG),A
        JP      TGERS

; TGDRW: the cursor ring on every live enemy quadrant at (TGX,TGY).
; TGERS: those cells back to their wire truth -- the reply window IS
; the shadow board. Both clobber everything.
TGDRW:  LD      A,PCURSR
        JR      TGPAT
TGERS:  LD      A,0FFH
TGPAT:  LD      (V_ST),A
        LD      A,1
        LD      (V_TMP),A
TGQ1:   LD      A,(V_TMP)
        CP      4
        RET     NC
        LD      HL,V_PC
        CP      (HL)
        RET     NC              ; beyond the seat count
        CALL    PLBASE          ; only PLAYING boards carry the cursor
        LD      DE,PLSTAT
        ADD     HL,DE
        CALL    RXGETB
        CP      PSPLAY
        JR      NZ,TGQN
        LD      A,(V_ST)        ; the pattern: ring, or the wire truth
        CP      0FFH
        JR      NZ,TGQ2
        LD      A,(V_TMP)
        CALL    PLBASE
        LD      DE,PLFIELD
        ADD     HL,DE
        LD      A,(TGY)
        CALL    MUL10
        LD      E,A
        LD      A,(TGX)
        ADD     A,E
        LD      E,A
        LD      D,0
        ADD     HL,DE
        CALL    RXGETB
        CALL    CELLST
TGQ2:   PUSH    AF
        LD      A,(TGX)
        LD      (V_CX),A
        LD      A,(TGY)
        LD      (V_CY),A
        LD      A,(V_TMP)
        CALL    BRDPOS
        POP     AF
        EX      DE,HL
        CALL    CELLDRW
TGQN:   LD      A,(V_TMP)
        INC     A
        LD      (V_TMP),A
        JR      TGQ1
