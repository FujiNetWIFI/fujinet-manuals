; game.inc -- st_game: the table.
;
; Poll /state (or the request whose reply is the state: ready, place,
; attack), validate it, draw it, and wait with the keys live. Every poll
; redraws the screen out of the reply window; rewriting a cell with what it
; already holds changes no pixel, so nothing flickers and nothing is tracked
; but which screen is up (V_SCR) and what the keys do (V_MODE).
;
; The screens: the waiting room (status 0) and placement (status 1) are in
; wait.inc and place.inc; play and game over are the four boards here, with
; a panel in columns 12-15:
;
;   row 0     the move clock      :38
;   rows 1-2  YOUR TURN / WAIT / YOU WIN! / name WINS / YOU SUNK / VIEW ONLY
;   row 4     the last shot       HIT / MISS / SUNK
;   rows 6-9  the keys            2468 AIM 5 FIRE, or 0 MENU

POLLF   EQU     90              ; frames between polls in play
AIMF    EQU     240             ; ...on our turn (the clock also ends a wait)
LOBF    EQU     120             ; in the waiting room
PLACEF  EQU     240             ; while placing: a keep-alive
OVERF   EQU     180             ; at game over
FAILF   EQU     150             ; after a failed poll

M_TEXT  EQU     0               ; V_MODE: 0 is the menu, nothing else
M_LOBBY EQU     1               ; 5 toggles ready
M_PLACE EQU     2               ; place.inc's keys
M_AIM   EQU     3               ; target.inc's keys

SC_NONE  EQU    0               ; V_SCR: what is on the screen
SC_LOBBY EQU    1
SC_PLACE EQU    2
SC_WAITP EQU    3
SC_PLAY  EQU    4

; st_game -- sit down at V_TABLE (or come back from the menu).
        FIT     80
st_game:
        RESET
        SETV    V_SEAT, 1
        SETV    V_REQ, REQ_STATE
        SETV    V_OK, 0
        SETV    V_PACT, 0FEH
        SETV    V_SCR, SC_NONE
        SETV    V_MODE, M_TEXT
        SETV    V_FLOOR, GMINLEN
        SETV    V_FLOOR+1, 0
        FCALL   d_cls
        PUTS    40H, s_joining
        FJMP    gpoll

        IF      DEMO
; st_demo -- the canned state: no network, the keys live, polls redraw it.
        FIT     40
st_demo:
        RESET
        SETV    V_SEAT, 1
        SETV    V_PACT, 0FEH
        SETV    V_CX, 3
        SETV    V_CY, 4
        FJMP    gdemo
        ENDIF

; gpoll -- one request, validated, then shown. The settle floor is the last
; good state's length (Channel F's sixth rule): a shorter reply cannot pass
; for a whole one. A failure drops the floor back to the minimum.
        FIT     120
gpoll:
        IF      DEMO
        SETV    V_REQ, REQ_STATE
        FJMP    gdemo
        ENDIF
        VAR     V_FLOOR
        LDA     RA
        PLO     R8
        LDN     RA
        PHI     R8
        LDR     R9, GMAXLEN
        FCALL   setlim
        FCALL   nfetch
        PLO     RC
        SETV    V_REQ, REQ_STATE
        GLO     RC
        BNZ     gfail
        FCALL   gvalid
        BNZ     gbad
gdemo:  SETV    V_OK, 1
        FCALL   ghead
        FCALL   gcues
        FJMP    gshow
gbad:   LDI     FE_LEN
gfail:  PUTV    V_ERRC
        SETV    V_OK, 0                 ; the window is not a state now
        SETV    V_MODE, M_TEXT
        SETV    V_FLOOR, GMINLEN
        SETV    V_FLOOR+1, 0
        OP      TOP_INV_ON
        PUTS    8CH, s_net
        AT      9CH
        GETV    V_ERRC
        FCALL   d_hex
        LDI     2
        FCALL   blanks
        OP      TOP_INV_OFF
        BEEP    20
        SETV    V_IVL, FAILF
        FJMP    gwait

; gvalid -- D = 0 if the window holds a whole state: at most GMAXPL seats, a
; status on the enum, and exactly the length the two imply (placement's and
; the lobby's records are name + status only). Then V_FLOOR, the next poll's
; settle minimum: the shortest state that can follow this one with as many
; seats -- placement's after the lobby or placement, the lobby's after game
; over, play's after play. (The exact length, the first try, wedged every
; lobby -> placement change: that reply is ten bytes shorter.) A seat fewer
; fails one poll, which drops the floor to GMINLEN.
        FIT     160
gvalid: LDI     GPCNT
        FCALL   rpeek
        SMI     GMAXPL+1
        BDF     gvbad
        LDI     GSTAT
        FCALL   rpeek
        BZ      gvlob
        XRI     ST_PLACE
        BZ      gvplc
        LDN     RB
        XRI     ST_OVER
        BZ      gvply
        LDN     RB
        SMI     ST_START
        BNF     gvbad
        SMI     ST_SUNK-ST_START+1
        BDF     gvbad
gvply:  LDR     R8, GPLYRS
        LDI     PSTRIDE
        BR      gv1
gvplc:  LDR     R8, GPLYRS
        LDI     LSTRIDE
        BR      gv1
gvlob:  LDR     R8, GLPLYRS
        LDI     LSTRIDE
gv1:    PLO     R9
        LDI     GPCNT
        FCALL   rpeek
        FCALL   vlen                    ; leaves R8 = the length it wanted
        BNZ     gv9
        LDI     GSTAT
        FCALL   rpeek
        SMI     ST_START
        BNF     gvf1                    ; lobby or placement
        LDN     RB
        XRI     ST_OVER
        BNZ     gvf3                    ; play: R8 is the floor already
        LDR     R8, GLPLYRS
        BR      gvf2
gvf1:   LDR     R8, GPLYRS
gvf2:   LDI     GPCNT
        FCALL   rpeek
        PLO     RC
gvf4:   GLO     RC                      ; + LSTRIDE a seat
        BZ      gvf3
        GLO     R8
        ADI     LSTRIDE
        PLO     R8
        GHI     R8
        ADCI    0
        PHI     R8
        DEC     RC
        BR      gvf4
gvf3:   VAR     V_FLOOR
        GLO     R8
        STR     RA
        INC     RA
        GHI     R8
        STR     RA
        LDI     0
gv9:    FRET
gvbad:  LDI     1
        FRET

; ghead -- the header bytes the screens key on, into RAM; the clock starts.
        FIT     96
ghead:  LDI     GPCNT
        FCALL   rpeek
        PUTV    V_PC
        LDI     GSTAT
        FCALL   rpeek
        PUTV    V_ST
        LDI     GPSTAT
        FCALL   rpeek
        PUTV    V_PST
        LDI     GACT
        FCALL   rpeek
        PUTV    V_ACT
        LDI     GMVTIM
        FCALL   rpeek
        PUTV    V_CLK
        GLO     RE
        PUTV    V_CLKT
        LDI     GLAP
        FCALL   rpeek
        PUTV    V_LAP
        SETV    V_WIN, 0FFH             ; at 99, v=2 makes activePlayer the winner
        GETV    V_ST
        XRI     ST_OVER
        BNZ     gh9
        GETV    V_PC
        STR     R2
        GETV    V_ACT
        SM                              ; act - count: a borrow is a real seat
        BDF     gh9
        GETV    V_ACT
        PUTV    V_WIN
gh9:    FRET

; gcues -- the sounds, on edges and never on levels: a shot's result when
; (status, lastAttackPos) is new -- anyone's shot, so an opponent's is heard --
; and our turn when activePlayer becomes 0 (it stays 0 for every poll of the
; turn). The turn's beep is the longer, so it is set last.
        FIT     120
gcues:  GETV    V_ST
        SMI     ST_MISS
        BNF     gc5
        SMI     3
        BDF     gc5                     ; not 11-13
        GETV    V_PRST
        STR     R2
        GETV    V_ST
        XOR
        BNZ     gc1
        GETV    V_PRLAP
        STR     R2
        GETV    V_LAP
        XOR
        BZ      gc5
gc1:    GETV    V_ST
        PUTV    V_PRST
        GETV    V_LAP
        PUTV    V_PRLAP
        GETV    V_ST
        XRI     ST_MISS
        BZ      gc5                     ; a miss is quiet
        BEEP    16
gc5:    GETV    V_ST                    ; our turn, newly?
        SMI     ST_START
        BNF     gc8
        SMI     4
        BDF     gc8
        GETV    V_PST
        BNZ     gc8                     ; PS_PLAY is 0
        GETV    V_ACT
        BNZ     gc8
        GETV    V_PACT
        BZ      gc8
        BEEP    40
gc8:    GETV    V_ACT
        PUTV    V_PACT
        FRET

; gshow -- the screen for this status.
        FIT     24
gshow:  GETV    V_ST
        BNZ     gsh1
        FJMP    globby
gsh1:   XRI     ST_PLACE
        BNZ     gsh2
        FJMP    gplace
gsh2:   FJMP    gplay

; gwait -- V_IVL frames of keys, blinking and the clock, then the next poll.
; Aiming and placing repeat a held key; elsewhere a press is one press, so a
; held 5 cannot ready and unready.
        FIT     80
gwait:  GLO     RE
        PUTV    V_T0
gw1:    GETV    V_MODE
        SMI     M_PLACE
        BDF     gw1r
        FCALL   kget
        BR      gw1k
gw1r:   FCALL   krep
gw1k:   BZ      gw2
        FJMP    gkey
gw2:    FCALL   tblink
        FCALL   gtick
        BDF     gw9                     ; our clock ran out: poll now
        GETV    V_T0
        STR     R2
        GLO     RE
        SM                              ; frames gone
        STR     R2
        GETV    V_IVL
        SD                              ; gone - interval
        BNF     gw1
gw9:    FJMP    gpoll

; gkey -- a key, D, by mode. 0 is always the menu; the rest need a good
; window. The handlers end with FJMP gw1 (the wait goes on) or gpoll.
        FIT     80
gkey:   ANI     0FH
        PLO     RC
        BNZ     gk1
        FJMP    st_menu
gk1:    GETV    V_OK
        BZ      gk9
        GETV    V_MODE
        XRI     M_LOBBY
        BZ      gklob
        GETV    V_MODE
        XRI     M_PLACE
        BNZ     gk2
        FJMP    pkey                    ; the digit in RC.0
gk2:    GETV    V_MODE
        XRI     M_AIM
        BNZ     gk9
        FJMP    akey
gklob:  GLO     RC
        XRI     5
        BNZ     gk9
        GETV    V_PST                   ; /ready/1 or /ready/0, never the
        XRI     PS_READY                ; deprecated toggle (Channel F's lesson)
        BZ      gk3
        SETV    V_REQ, REQ_READY1
        BR      gk4
gk3:    SETV    V_REQ, REQ_READY0
gk4:    BEEP    6
        FJMP    gpoll
gk9:    FJMP    gw1

; gtick -- the move clock: a second off every 60 frames, redrawn while the
; boards are up. DF = 1 when it reaches 0 on our turn.
        FIT     80
gtick:  GETV    V_CLK
        BZ      gtk8
        GETV    V_CLKT
        STR     R2
        GLO     RE
        SM
        SMI     60
        BNF     gtk8                    ; not a second yet
        GETV    V_CLKT
        ADI     60
        STR     RA
        GETV    V_CLK
        SMI     1
        STR     RA
        GETV    V_SCR
        XRI     SC_PLAY
        BNZ     gtk1
        FCALL   pclock
gtk1:   GETV    V_CLK
        BNZ     gtk8
        GETV    V_MODE
        XRI     M_AIM
        BNZ     gtk8
        SMI     0                       ; D = 0: DF = 1
        FRET
gtk8:   LDI     0
        ADI     0                       ; DF = 0
        FRET

; ---- play and game over: the four boards ----------------------------------

; gplay -- the boards, the names, the panel; aim if it is our turn.
        FIT     96
gplay:  SETV    V_PLOK, 0
        GETV    V_SCR
        XRI     SC_PLAY
        BZ      gp1
        SETV    V_SCR, SC_PLAY
        FCALL   d_cls
gp1:    SETV    V_MODE, M_TEXT
        SETV    V_IVL, POLLF
        GETV    V_ST
        XRI     ST_OVER
        BNZ     gp2
        SETV    V_IVL, OVERF
        BR      gp3
gp2:    GETV    V_PST
        BNZ     gp3                     ; we play (PS_PLAY is 0)...
        GETV    V_ACT
        BNZ     gp3                     ; ...and it is our turn
        SETV    V_MODE, M_AIM
        SETV    V_IVL, AIMF
gp3:    FCALL   gnames
        FCALL   gboards
        FCALL   gpanel
        FJMP    gwait

; gboards -- every seat's board. Ours with our hulls (unless we only watch);
; then MAP becomes the cursor while we aim, or the winner's fleet at game
; over, for the others.
        FIT     112
gboards:
        SETV    V_BSEAT, 0
        FCALL   mclear
        GETV    V_PST
        XRI     PS_VIEW
        BZ      gb1
        LDR     RB, RPLY+GSHIPS
        FCALL   mships
gb1:    SETV    V_BMH, HI(MAP)
        FCALL   bdraw
        GETV    V_MODE
        XRI     M_AIM
        BNZ     gb2
        FCALL   mcur
        BR      gb3
gb2:    FCALL   mclear
        GETV    V_WIN
        XRI     0FFH
        BZ      gb3
        GETV    V_WIN
        BZ      gb3                     ; we won: our own hulls already show
        LDR     RB, RPLY+GSHIPS+NSHIPS
        FCALL   mships
gb3:    SETV    V_BSEAT, 1
gb4:    GETV    V_PC
        STR     R2
        GETV    V_BSEAT
        SM                              ; seat - count: no borrow, no seat
        BNF     gb5
        FCALL   bblank
        BR      gb6
gb5:    FCALL   gbmap
        FCALL   bdraw
gb6:    GETV    V_BSEAT
        ADI     1
        STR     RA
        XRI     GMAXPL
        BNZ     gb4
        FRET

; gbmap -- V_BMH for seat V_BSEAT, one of the others: MAP when it is a live
; target and we aim, or it is the winner; ZEROS otherwise.
        FIT     64
gbmap:  SETV    V_BMH, HI(ZEROS)
        GETV    V_MODE
        XRI     M_AIM
        BNZ     gbm2
        GETV    V_BSEAT
        FCALL   prec
        LDI     PSTAT
        FCALL   radd
        LDN     RB
        BNZ     gbm9                    ; sunk: nothing to aim at
        BR      gbm8
gbm2:   GETV    V_WIN
        STR     R2
        GETV    V_BSEAT
        XOR
        BNZ     gbm9
gbm8:   SETV    V_BMH, HI(MAP)
gbm9:   FRET

; gnames -- each seat's name over its board, five cells to its first space:
; YOU for ours, the player to move (the winner, at 99) in inverse.
        FIT     120
gnames: SETV    V_ROW, 0
gn1:    GETV    V_ROW
        ADI     LO(orgrc)
        FCALL   tbyte
        SMI     10H
        FCALL   d_at
        GETV    V_PC
        STR     R2
        GETV    V_ROW
        SM                              ; row - count: a borrow is a seat
        BNF     gn2
        LDI     5
        FCALL   blanks
        BR      gn8
gn2:    GETV    V_ACT
        STR     R2
        GETV    V_ROW
        XOR
        BNZ     gn3
        OP      TOP_INV_ON
gn3:    GETV    V_ROW
        BNZ     gn4
        GETV    V_PST
        XRI     PS_VIEW
        BZ      gn4
        LDR     R8, s_you5
        FCALL   d_puts
        BR      gn5
gn4:    GETV    V_ROW
        FCALL   prec
        LDI     1
        PHI     R8
        LDI     5
        FCALL   rpu
gn5:    OP      TOP_INV_OFF
gn8:    GETV    V_ROW
        ADI     1
        STR     RA
        XRI     GMAXPL
        BNZ     gn1
        FRET

; pclock -- panel row 0: " :ss" (":sss" past 99) while someone is to move.
        FIT     64
pclock: AT      0CH
        GETV    V_ST
        SMI     ST_START
        BNF     pck8
        SMI     4
        BDF     pck8
        GETV    V_ACT
        XRI     0FFH
        BZ      pck8
        GETV    V_CLK
        PLO     R8
        LDI     0
        PHI     R8
        GLO     R8
        SMI     100
        BDF     pck1
        LDI     ' '
        FCALL   d_putc
        LDI     ':'
        FCALL   d_putc
        LDI     2
        FJMP    dnum
pck1:   LDI     ':'
        FCALL   d_putc
        LDI     3
        FJMP    dnum
pck8:   LDI     4
        FJMP    blanks

; gpanel -- columns 12-15.
        FIT     160
gpanel: FCALL   pclock
        GETV    V_ST
        XRI     ST_OVER
        BNZ     gpn3
        GETV    V_WIN                   ; game over
        BNZ     gpn1
        LDR     R8, s_you4
        LDR     R9, s_win
        BR      gpn6
gpn1:   XRI     0FFH
        BNZ     gpn2
        LDR     R8, s_game
        LDR     R9, s_over
        BR      gpn6
gpn2:   AT      1CH                     ; the winner's name, then WINS
        GETV    V_WIN
        FCALL   prec
        LDI     1
        PHI     R8
        LDI     4
        FCALL   rpu
        PUTS    2CH, s_wins
        BR      gpn7
gpn3:   GETV    V_MODE
        XRI     M_AIM
        BNZ     gpn4
        LDR     R8, s_your
        LDR     R9, s_turn
        BR      gpn6
gpn4:   GETV    V_PST
        XRI     PS_DEAD
        BNZ     gpn5
        LDR     R8, s_you4
        LDR     R9, s_sunk
        BR      gpn6
gpn5:   GETV    V_PST
        XRI     PS_VIEW
        BNZ     gpn5w
        LDR     R8, s_view
        LDR     R9, s_only
        BR      gpn6
gpn5w:  LDR     R8, s_wait
        LDR     R9, s_blank4
gpn6:   FCALL   p2rows
gpn7:   FJMP    gpanel2

; p2rows -- the strings at R8 and R9 on panel rows 1 and 2.
        FIT     24
p2rows: AT      1CH
        FCALL   d_puts
        AT      2CH
        GHI     R9
        PHI     R8
        GLO     R9
        PLO     R8
        FJMP    d_puts

; gpanel2 -- panel rows 3-9: the last shot, then the keys.
        FIT     120
gpanel2:
        PUTS    3CH, s_blank4
        LDR     R8, s_blank4
        GETV    V_ST
        XRI     ST_MISS
        BNZ     gq1
        LDR     R8, s_miss
gq1:    GETV    V_ST
        XRI     ST_HIT
        BNZ     gq2
        LDR     R8, s_hit
gq2:    GETV    V_ST
        XRI     ST_SUNK
        BNZ     gq3
        LDR     R8, s_sunk
gq3:    AT      4CH
        FCALL   d_puts
        PUTS    5CH, s_blank4
        GETV    V_MODE
        XRI     M_AIM
        BNZ     gq4
        PUTS    6CH, s_k2468
        PUTS    7CH, s_aim
        PUTS    8CH, s_k5
        PUTS    9CH, s_fire
        FRET
gq4:    PUTS    6CH, s_blank4
        PUTS    7CH, s_blank4
        PUTS    8CH, s_k0
        PUTS    9CH, s_mnu
        FRET
