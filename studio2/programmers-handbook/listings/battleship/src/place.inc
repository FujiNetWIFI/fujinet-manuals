; place.inc -- placing the fleet.
;
; A random legal fleet is rolled first (the 2600's and Channel F's way); then
; each ship in turn, 5 4 3 3 2, blinks where it lies and the keypad moves it:
;
;   2 4 6 8   move it          1   turn it          5   keep it
;   3         roll the ships not yet kept again     0   the menu
;
; A move that would put any of it off the board is refused with a tone,
; never clamped. It may pass over another ship (those squares buzz, T_BAD),
; but it cannot be kept there: the server ignores an illegal placement
; without a word, so nothing illegal is ever sent. After the fifth, /place
; goes with all five as pos + 100 * dir, and its reply is the next state.

; pship -- row 1: which ship, "1/5 CARRIER".
        FIT     64
pship:  AT      10H
        GETV    V_PSHIP
        SMI     NSHIPS
        BDF     psh9
        GETV    V_PSHIP
        ADI     '1'
        FCALL   d_putc
        LDR     R8, s_of5
        FCALL   d_puts
        LDR     RB, s_ships             ; the name: V_PSHIP NULs on
        GETV    V_PSHIP
        PLO     RC
psh1:   GLO     RC
        BZ      psh3
psh2:   LDA     RB
        BNZ     psh2
        DEC     RC
        BR      psh1
psh3:   GHI     RB
        PHI     R8
        GLO     RB
        PLO     R8
        FCALL   d_puts
psh9:   OP      TOP_CLREOL
        FRET

; pget -- V_MX, V_MY, V_MD, V_ML = ship D's.
        FIT     48
pget:   PLO     R9
        ADI     LO(V_SX)
        PLO     RA
        LDN     RA
        PUTV    V_MX
        GLO     R9
        ADI     LO(V_SY)
        PLO     RA
        LDN     RA
        PUTV    V_MY
        GLO     R9
        ADI     LO(V_SD)
        PLO     RA
        LDN     RA
        PUTV    V_MD
        GLO     R9
        ADI     LO(sizes)
        FCALL   tbyte
        PUTV    V_ML
        FRET

; pput -- ship D = V_MX, V_MY, V_MD.
        FIT     48
pput:   PLO     R9
        GETV    V_MX
        PHI     RC
        GLO     R9
        ADI     LO(V_SX)
        PLO     RA
        GHI     RC
        STR     RA
        GETV    V_MY
        PHI     RC
        GLO     R9
        ADI     LO(V_SY)
        PLO     RA
        GHI     RC
        STR     RA
        GETV    V_MD
        PHI     RC
        GLO     R9
        ADI     LO(V_SD)
        PLO     RA
        GHI     RC
        STR     RA
        FRET

; pdraw -- MAP for placement, then our board: every ship but the current one
; T_HULL, the current one T_PLC over them (T_BAD where it overlaps, and
; V_MBAD = 1).
        FIT     80
pdraw:  FCALL   mclear
        SETV    V_MBAD, 0
        SETV    V_CTR, 0
pd1:    GETV    V_CTR
        STR     R2
        GETV    V_PSHIP
        XOR
        BZ      pd2                     ; the current one goes on last
        GETV    V_CTR
        FCALL   pget
        SETV    V_MT, T_HULL
        FCALL   mmark
pd2:    GETV    V_CTR
        ADI     1
        STR     RA
        XRI     NSHIPS
        BNZ     pd1
        GETV    V_PSHIP
        XRI     NSHIPS
        BZ      pd3
        GETV    V_PSHIP
        FCALL   pget
        SETV    V_MT, T_PLC
        FCALL   mmark
pd3:    SETV    V_BSEAT, 0
        SETV    V_BMH, HI(MAP)
        FJMP    bdraw

; proll -- a random legal fleet for ships V_PSHIP-4, around the kept ones.
; Each ship gets 256 throws; should one run out (kept ships boxing it in),
; the whole fleet is thrown again.
        FIT     144
proll:  FCALL   mclear
        SETV    V_CTR, 0
pr1:    GETV    V_CTR                   ; the kept ships, as they are
        STR     R2
        GETV    V_PSHIP
        XOR
        BZ      pr2
        GETV    V_CTR
        FCALL   pget
        SETV    V_MT, T_HULL
        FCALL   mmark
        GETV    V_CTR
        ADI     1
        STR     RA
        BR      pr1
pr2:    SETV    V_TRIES, 0
        GETV    V_CTR
        FCALL   pget                    ; its length
pr3:    FCALL   rnd
        ANI     0FH
        PUTV    V_MX
        FCALL   rnd
        ANI     0FH
        PUTV    V_MY
        FCALL   rnd
        ANI     1
        PUTV    V_MD
        FCALL   mfits
        BDF     pr5
        GETV    V_TRIES
        ADI     1
        STR     RA
        BNZ     pr3
        SETV    V_PSHIP, 0              ; boxed in: throw them all
        BR      proll
pr5:    SETV    V_MT, T_HULL
        FCALL   mmark
        GETV    V_CTR
        FCALL   pput
        GETV    V_CTR
        ADI     1
        STR     RA
        XRI     NSHIPS
        BNZ     pr2
        FRET

; rnd -- D = the next byte of a 16-bit Galois LFSR (taps $B400), V_RND.
        FIT     48
rnd:    VAR     V_RND
        LDA     RA
        PHI     R9
        LDN     RA
        PLO     R9
        LDI     8
        PLO     R8
rn1:    GHI     R9
        SHR
        PHI     R9
        GLO     R9
        RSHR
        PLO     R9
        BNF     rn2
        GHI     R9
        XRI     0B4H
        PHI     R9
rn2:    DEC     R8
        GLO     R8
        BNZ     rn1
        GLO     R9                      ; never stuck at zero
        BNZ     rn3
        GHI     R9
        BNZ     rn3
        INC     R9
rn3:    VAR     V_RND
        GHI     R9
        STR     RA
        INC     RA
        GLO     R9
        STR     RA
        FRET

; pkey -- a placement key, the digit in RC.0.
        FIT     144
pkey:   GLO     RC
        XRI     5
        BZ      pkeep
        GLO     RC
        XRI     3
        BZ      pkroll
        GETV    V_PSHIP                 ; the rest move the current ship
        SMI     NSHIPS
        BDF     pk9
        GETV    V_PSHIP
        FCALL   pget
        GLO     RC
        XRI     1
        BZ      pkrot
        GLO     RC
        XRI     2
        BZ      pkup
        GLO     RC
        XRI     8
        BZ      pkdn
        GLO     RC
        XRI     4
        BZ      pklt
        GLO     RC
        XRI     6
        BNZ     pk9
        GETV    V_MX                    ; 6: right
        ADI     1
        BR      pkx
pklt:   GETV    V_MX                    ; off the left is 255: refused
        SMI     1
pkx:    PUTV    V_MX
        BR      pkmove
pkup:   GETV    V_MY
        SMI     1
        BR      pky
pkdn:   GETV    V_MY
        ADI     1
pky:    PUTV    V_MY
        BR      pkmove
pkrot:  GETV    V_MD
        XRI     1
        PUTV    V_MD
pkmove: FCALL   mstart                  ; still on the board?
        BNF     pkno
        GETV    V_PSHIP
        FCALL   pput
        FCALL   pdraw
pk9:    FJMP    gw1
pkno:   BEEP    10
        FJMP    gw1
pkroll: FCALL   proll
        FCALL   pdraw
        FJMP    gw1
pkeep:  GETV    V_PSHIP
        SMI     NSHIPS
        BDF     pk9
        GETV    V_MBAD
        BNZ     pkno                    ; it lies on another ship
        GETV    V_PSHIP
        ADI     1
        PUTV    V_PSHIP
        XRI     NSHIPS
        BZ      pksend
        FCALL   pship
        FCALL   pdraw
        FJMP    gw1
pksend: SETV    V_REQ, REQ_PLACE
        BEEP    6
        FCALL   pdraw                   ; the last one stops blinking
        PUTS    10H, s_sending
        OP      TOP_CLREOL
        FJMP    gpoll
