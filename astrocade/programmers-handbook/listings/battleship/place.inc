; place.inc -- ship placement, transcribed from the Intellivision
; handle_placement. Each ship (sizes 5,4,3,3,2, fixed order) seeds at a
; random legal spot, the stick nudges it, keypad 0 rotates, and the
; trigger confirms -- rejected locally when it overlaps an
; already-confirmed ship, so no server round trip is spent finding that
; out. The pending ship blinks ring <-> solid; confirmed hull is solid.
;
; Blocking, like the Intellivision's: bots place instantly and humans
; are the wait, and the wire's own myShips makes the next poll
; authoritative if the server somehow moved on without us.
;
; Fills MYSHP[0..4] (pos + 100*dir); the caller stages /place.

PLACESCR: CALL  KEYRAW          ; no leaking presses
        LD      (V_KEY),A
        LD      HL,OCCUPY       ; only the occupancy map needs clearing:
        LD      B,100           ; CHKNEW just painted the boards sea
PLCZ:   LD      (HL),0
        INC     HL
        DJNZ    PLCZ
        XOR     A
        LD      (PCNUM),A
PLSHIP: LD      A,(PCNUM)
        CP      5
        RET     NC              ; all placed
        LD      HL,SHPSIZ
        LD      E,A
        LD      D,0
        ADD     HL,DE
        LD      A,(HL)
        LD      (PCSIZ),A
; Seed a random legal spot. The long axis draws 0..10-size, the other
; 0..9, so bounds are legal by construction; only overlap can reject.
PLSEED: CALL    RNDNXT
        AND     1
        LD      (PCDIR),A
        LD      A,(PCSIZ)
        LD      B,A
        LD      A,11
        SUB     B
        CALL    RNDMOD          ; A = rand mod (11-size): the long axis
        PUSH    AF              ; RNDMOD clobbers C -- the first result
        LD      A,10            ; must not ride there (it did once: every
        CALL    RNDMOD          ; long axis came back 10, the modulus)
        LD      B,A             ; B = the free axis
        POP     AF
        LD      C,A             ; C = the long axis
        LD      A,(PCDIR)
        OR      A
        JR      NZ,PLSV
        LD      A,C             ; horizontal: x rides the long axis
        LD      (PCX),A
        LD      A,B
        LD      (PCY),A
        JR      PLSF
PLSV:   LD      A,B             ; vertical: y does
        LD      (PCX),A
        LD      A,C
        LD      (PCY),A
PLSF:   CALL    PLCFIT
        JR      C,PLSEED
        LD      A,(PCNUM)       ; the prompt: SHIP n/5 ...
        ADD     A,'1'
        LD      (HEXBUF),A
        XOR     A
        LD      (HEXBUF+1),A
        LD      HL,TSHIP
        LD      DE,14*256+0
        LD      C,XWONF
        CALL    TXTAT
        LD      HL,HEXBUF
        LD      DE,14*256+5
        LD      C,XWONF
        CALL    TXTAT
        LD      HL,TSHIP2
        LD      DE,14*256+6
        LD      C,XWONF
        LD      B,28
        CALL    TXTN
        XOR     A
        LD      (V_BLNK),A
        CALL    PLCDRW          ; the pending ship, ring pattern
PLLOOP: CALL    KEYSCN
        OR      A
        JP      NZ,PLKEY
        LD      DE,2500         ; ~20 ms
PLDLY:  DEC     DE
        LD      A,D
        OR      E
        JR      NZ,PLDLY
        LD      HL,V_BLNK       ; ring <-> solid every ~320 ms
        INC     (HL)
        LD      A,(HL)
        AND     0FH
        JR      NZ,PLLOOP
        LD      A,(HL)
        AND     10H
        JR      Z,PLBL1
        CALL    PLCDRW
        JR      PLLOOP
PLBL1:  CALL    PLCDRS
        JR      PLLOOP
PLKEY:  CP      'U'
        JR      NZ,PLK1
        LD      A,(PCY)
        OR      A
        JR      Z,PLLOOP
        CALL    PLCERS
        LD      HL,PCY
        DEC     (HL)
PLMV:   CALL    SNDKEY
        CALL    PLCDRW
        JP      PLLOOP
PLK1:   CP      'D'
        JR      NZ,PLK2
        CALL    PLYMAX
        LD      HL,PCY
        CP      (HL)
        JR      Z,PLLOO2        ; already at the edge
        JR      C,PLLOO2
        CALL    PLCERS
        LD      HL,PCY
        INC     (HL)
        JR      PLMV
PLK2:   CP      'L'
        JR      NZ,PLK3
        LD      A,(PCX)
        OR      A
        JR      Z,PLLOO2
        CALL    PLCERS
        LD      HL,PCX
        DEC     (HL)
        JR      PLMV
PLK3:   CP      'R'
        JR      NZ,PLK4
        CALL    PLXMAX
        LD      HL,PCX
        CP      (HL)
        JR      Z,PLLOO2
        JR      C,PLLOO2
        CALL    PLCERS
        LD      HL,PCX
        INC     (HL)
        JR      PLMV
PLK4:   CP      '0'             ; rotate, clamping the origin so the
        JR      NZ,PLK5         ; ship stays on the board
        CALL    PLCERS
        LD      A,(PCDIR)
        XOR     1
        LD      (PCDIR),A
        CALL    PLXMAX
        LD      HL,PCX
        CP      (HL)
        JR      NC,PLR1
        LD      (HL),A
PLR1:   CALL    PLYMAX
        LD      HL,PCY
        CP      (HL)
        JR      NC,PLMV
        LD      (HL),A
        JR      PLMV
PLK5:   CP      'T'
        JR      NZ,PLLOO2
        CALL    PLCFIT
        JR      NC,PLOK
        CALL    SNDBAD          ; overlaps a placed ship
PLLOO2: JP      PLLOOP
PLOK:   CALL    PLCMRK          ; occupy + repaint solid
        CALL    SNDPLC
        LD      A,(PCY)         ; MYSHP[i] = x + y*10 + 100*dir
        CALL    MUL10
        LD      HL,PCX
        ADD     A,(HL)
        LD      HL,PCDIR
        BIT     0,(HL)
        JR      Z,PLOK1
        ADD     A,100
PLOK1:  LD      C,A
        LD      A,(PCNUM)
        LD      HL,MYSHP
        LD      E,A
        LD      D,0
        ADD     HL,DE
        LD      (HL),C
        LD      A,(PCNUM)
        INC     A
        LD      (PCNUM),A
        JP      PLSHIP

; PLXMAX/PLYMAX: A = the cursor's max origin on that axis (the long
; axis stops at 10-size). Clobbers B.
PLXMAX: LD      A,(PCDIR)
        OR      A
        JR      NZ,PLXM1        ; vertical: x is free to 9
        LD      A,(PCSIZ)
        LD      B,A
        LD      A,10
        SUB     B
        RET
PLXM1:  LD      A,9
        RET
PLYMAX: LD      A,(PCDIR)
        OR      A
        JR      Z,PLXM1         ; horizontal: y is free to 9
        LD      A,(PCSIZ)
        LD      B,A
        LD      A,10
        SUB     B
        RET

; PLCELL: A = occupancy index (y*10+x) of pending cell B (0-based along
; the ship). Preserves B,DE; clobbers C.
PLCELL: PUSH    HL
        LD      A,(PCDIR)
        OR      A
        JR      NZ,PLCV
        LD      A,(PCY)         ; horizontal: (x+i, y)
        CALL    MUL10
        LD      HL,PCX
        ADD     A,(HL)
        ADD     A,B
        POP     HL
        RET
PLCV:   LD      A,(PCY)         ; vertical: (x, y+i)
        ADD     A,B
        CALL    MUL10
        LD      HL,PCX
        ADD     A,(HL)
        POP     HL
        RET

; PLCFIT: carry set when the pending ship overlaps a confirmed one.
; Bounds need no check -- the seed and the clamps keep them legal.
PLCFIT: LD      A,(PCSIZ)
        LD      B,A
PLCF1:  LD      A,B
        DEC     A
        PUSH    BC
        LD      B,A
        CALL    PLCELL
        POP     BC
        LD      HL,OCCUPY
        LD      E,A
        LD      D,0
        ADD     HL,DE
        LD      A,(HL)
        OR      A
        JR      NZ,PLCFX
        DJNZ    PLCF1
        OR      A               ; carry clear: it fits
        RET
PLCFX:  SCF
        RET

; PLCMRK: mark the pending cells occupied, then fall through to the
; solid repaint.
PLCMRK: LD      A,(PCSIZ)
        LD      B,A
PLCM1:  LD      A,B
        DEC     A
        PUSH    BC
        LD      B,A
        CALL    PLCELL
        POP     BC
        LD      HL,OCCUPY
        LD      E,A
        LD      D,0
        ADD     HL,DE
        LD      (HL),1
        DJNZ    PLCM1
; falls through: repaint the (now confirmed) ship solid
PLCDRS: LD      A,PSHIP         ; the pending ship, solid phase
        JR      PLCPAT
PLCDRW: LD      A,PCURSR        ; the pending ship, ring phase
PLCPAT: LD      (V_ST),A
        LD      A,(PCSIZ)
        LD      B,A
PLCP1:  LD      A,B
        DEC     A
        PUSH    BC
        LD      B,A
        CALL    PLCELL
        POP     BC
        PUSH    BC
        CALL    DIV10           ; B = y, A = x
        LD      (V_CX),A
        LD      A,B
        LD      (V_CY),A
        XOR     A               ; quadrant 0
        CALL    BRDPOS
        LD      A,(V_ST)
        EX      DE,HL
        CALL    CELLDRW
        POP     BC
        DJNZ    PLCP1
        RET

; PLCERS: repaint the pending cells to their truth -- sea, or a
; confirmed ship's hull where the cursor is passing over one.
PLCERS: LD      A,(PCSIZ)
        LD      B,A
PLCE1:  LD      A,B
        DEC     A
        PUSH    BC
        LD      B,A
        CALL    PLCELL
        POP     BC
        PUSH    BC
        PUSH    AF
        LD      HL,OCCUPY
        LD      E,A
        LD      D,0
        ADD     HL,DE
        LD      A,(HL)
        OR      A
        LD      A,PWATER
        JR      Z,PLCE2
        LD      A,PSHIP
PLCE2:  LD      (V_ST),A
        POP     AF
        CALL    DIV10
        LD      (V_CX),A
        LD      A,B
        LD      (V_CY),A
        XOR     A
        CALL    BRDPOS
        LD      A,(V_ST)
        EX      DE,HL
        CALL    CELLDRW
        POP     BC
        DJNZ    PLCE1
        RET

TSHIP:  DB      "SHIP",0
TSHIP2: DB      "/5 STICK MOVES 0=ROT T=OK",0
