; screens.inc -- table selection, the poll loop, and the per-class
; renderers.
;
; Rendering policy (the card-game ports'): every poll redraws everything,
; opaquely, straight out of the reply window -- identical pixels
; rewritten are invisible, so there is no flicker and no digest
; bookkeeping. The one thing opaque overdraw cannot fix is content that
; SHRANK, so CHKNEW watches the screen class (lobby / play / over) and
; the seat count, and answers a change with a full clear + statics
; before the ordinary render.
;
; The poll loop is the battleship GAMELP reshaped for Fujitzee: one
; staged action (PENDACT) rides the next request in place of /state --
; every endpoint returns the same state blob -- and the reply is
; dispatched by class. The turn edge (V_TRNF) is computed from PRVACT at
; the top of every successful poll, lobby included, so the lobby->play
; transition is caught by the same comparison as any other turn change.
; The roll edge rides PRVRLS the same way: rollsLeft DECREASING means a
; roll landed (a new turn resets it upward), and that is what triggers
; the dice animation -- for your rolls and everyone else's alike.

; ======================================================================
; Table selection
; ======================================================================
TBLSCR: CALL    KEYRAW          ; a key still held from the previous
        LD      (V_KEY),A       ; screen must not fire here
        CALL    CLRSCR
        SYSSUK  STRDIS          ; title, BIOS font at 2x
        DB      16              ; "FUJITZEE": 8 chars x 16px, centred
        DB      0
        DB      4CH
        DW      TTITLE
        LD      HL,TCHOOS
        LD      DE,6*256+2
        LD      C,XWONF
        CALL    TXTAT
TBLRF:  XOR     A               ; fetch /tables
        CALL    APICALL
        JR      NC,TBLOK
        LD      HL,ENET
        LD      DE,14*256+0
        LD      C,XRONF
        CALL    TXTAT
TBLRW:  CALL    KEYSCN
        OR      A
        JR      Z,TBLRW
        JR      TBLRF
TBLOK:  LD      HL,0
        CALL    RXGETB          ; table count
        OR      A
        JR      Z,TBLRW         ; none yet: wait for a key, refetch
        CP      9
        JR      C,TBOK2
        LD      A,8             ; eight rows fit under the title
TBOK2:  LD      (V_CNT),A
        XOR     A
        LD      (V_SEL),A
        CALL    TBDRAW
TBKEY:  CALL    KEYSCN
        OR      A
        JR      Z,TBKEY
        CP      'U'
        JR      NZ,TBK1
        LD      A,(V_SEL)
        OR      A
        JR      Z,TBKEY
        DEC     A
        LD      (V_SEL),A
        CALL    SNDKEY
        CALL    TBDRAW
        JR      TBKEY
TBK1:   CP      'D'
        JR      NZ,TBK2
        LD      A,(V_SEL)
        INC     A
        LD      HL,V_CNT
        CP      (HL)
        JR      NC,TBKEY
        LD      (V_SEL),A
        CALL    SNDKEY
        CALL    TBDRAW
        JR      TBKEY
TBK2:   CP      'E'             ; CE: back to the name screen
        JR      NZ,TBK2A
        CALL    NAMESCR
        JP      TBLSCR
TBK2A:  CP      '.'             ; the . key: how to play
        JR      NZ,TBK2B
        CALL    HELPSCR
        JP      TBLSCR
TBK2B:  CP      'T'
        JR      Z,TBJOIN
        CP      '0'             ; digit shortcut: 1-9 then 0 = row 10
        JR      C,TBKEY
        CP      '9'+1
        JR      NC,TBKEY
        SUB     '1'
        CP      0FFH            ; '0' wrapped to FF: row 10
        JR      NZ,TBK3
        LD      A,9
TBK3:   LD      HL,V_CNT
        CP      (HL)
        JR      NC,TBKEY
        LD      (V_SEL),A
; falls into the join
TBJOIN: CALL    SNDSEL
        LD      A,(V_SEL)       ; record base = 1 + sel*36
        CALL    TBOFF
        LD      DE,TBLBUF       ; id, up to its NUL
        LD      B,9
        CALL    RXSTRN
        LD      DE,TBID+TBNAME  ; the name field, for the lobby header
        ADD     HL,DE
        LD      DE,TBLNAM
        LD      B,21
        CALL    RXSTRN
        CALL    CLRSCR
        LD      HL,TJOIN
        LD      DE,7*256+14
        LD      C,XWONF
        CALL    TXTAT
        LD      A,0FFH
        LD      (PRVCLS),A      ; force the statics on the first poll
        LD      (PRVACT),A      ; and arm the your-turn cue
        LD      (PRVRLS),A      ; and mute the roll edge across the join
        XOR     A
        LD      (PENDACT),A
        LD      (VIEWIDX),A
        LD      (UIMODE),A
        LD      (DCUR),A
        CALL    KEEPRST
        JP      GAMELP

; TBOFF: HL = window offset of table record A (1 + A*36, and 36 = 32+4).
; Clobbers A,DE.
TBOFF:  LD      L,A
        LD      H,0
        ADD     HL,HL
        ADD     HL,HL           ; *4
        LD      E,L
        LD      D,H
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL           ; *32
        ADD     HL,DE           ; *36
        INC     HL              ; + the count byte
        RET

; TBDRAW: the list rows: name and "cur / max", selected row inverse.
TBDRAW: XOR     A
        LD      (V_TMP),A
TBD1:   LD      A,(V_TMP)
        LD      HL,V_CNT
        CP      (HL)
        RET     NC
        CALL    TBOFF
        PUSH    HL
        LD      DE,TBNAME       ; the display name field
        ADD     HL,DE
        LD      DE,LINBUF
        LD      B,21
        CALL    RXSTRN
        LD      A,(V_SEL)       ; row color
        LD      HL,V_TMP
        CP      (HL)
        LD      C,XFONW
        JR      Z,TBD2
        LD      C,XWONF
TBD2:   LD      A,(V_TMP)       ; row y = 7 + i
        ADD     A,7
        LD      D,A
        LD      E,2
        LD      HL,LINBUF
        LD      B,21
        PUSH    BC
        CALL    TXTN
        POP     BC
        POP     HL
        LD      DE,TBPLYRS      ; the "cur / max" field
        ADD     HL,DE
        LD      DE,LINBUF
        LD      B,6
        CALL    RXSTRN
        LD      A,(V_TMP)
        ADD     A,7
        LD      D,A
        LD      E,25
        LD      HL,LINBUF
        LD      B,6
        CALL    TXTN
        LD      A,(V_TMP)
        INC     A
        LD      (V_TMP),A
        JR      TBD1

; ======================================================================
; The poll loop
; ======================================================================
GAMELP: LD      A,(PENDACT)     ; a staged action rides the next request:
        INC     A               ; 0 none -> 1 /state, 1 -> 2 /ready,
        CALL    APICALL         ; 2 -> 3 /roll, 3 -> 4 /score
        JP      C,GLFAIL
        XOR     A
        LD      (PENDACT),A     ; consumed
        LD      HL,GOACTPL      ; this poll's header, cached
        CALL    RXGETB
        LD      (V_ACT),A
        LD      HL,PRVACT       ; the turn edge -- computed on EVERY good
        CP      (HL)            ; poll (lobby included), so the
        LD      (HL),A          ; lobby->play transition rides it too
        LD      A,0
        JR      Z,GLTE1
        INC     A
GLTE1:  LD      (V_TRNF),A
        LD      HL,GOPC
        CALL    RXGETB
        LD      (V_PC),A
        XOR     A               ; my turn = active seat 0 and not viewing
        LD      (V_MYTRN),A
        LD      A,(V_ACT)
        OR      A
        JR      NZ,GLMT1
        LD      HL,GOVIEW
        CALL    RXGETB
        OR      A
        JR      NZ,GLMT1
        LD      A,1
        LD      (V_MYTRN),A
GLMT1:  CALL    CHKNEW
        LD      A,(V_CLS)       ; dispatch by class
        OR      A
        JP      Z,GLLOB
        CP      1
        JP      Z,GLGAM
        CALL    GOVERR          ; class 2: game over
        LD      B,150           ; ~3 s; the server resets to the lobby
        JP      GLWAIT

GLLOB:  CALL    LOBBYR
        LD      B,90            ; ~2 s between lobby polls
        JP      GLWAIT

; ---- A play-class poll ------------------------------------------------
GLGAM:  LD      HL,GORLEFT      ; the roll edge: rollsLeft DECREASED
        CALL    RXGETB
        LD      (V_ST),A
        LD      A,(PRVRLS)
        CP      0FFH            ; sentinel: no edge across a boundary
        JR      Z,GLGR3
        LD      HL,V_ST
        CP      (HL)            ; PRVRLS vs new
        JR      Z,GLGR3         ; unchanged
        JR      C,GLGR3         ; increased: a fresh turn, not a roll
        CALL    ROLLANM         ; a roll landed: rattle the dice
        LD      A,(V_MYTRN)
        OR      A
        JR      Z,GLGR3
        CALL    KEEPSYN         ; restage the mask the server echoed
        LD      A,(V_ST)
        OR      A               ; out of rolls: jump to the best row
        JR      NZ,GLGR3
        LD      A,1
        LD      (UIMODE),A
        CALL    PICKBEST
GLGR3:  LD      A,(V_ST)
        LD      (PRVRLS),A
        LD      A,(V_TRNF)      ; the turn edge
        OR      A
        JR      Z,GLGT2
        LD      A,(V_MYTRN)
        OR      A
        JR      Z,GLGT1
        XOR     A               ; my turn arrived: dice mode, cursor on
        LD      (UIMODE),A      ; ROLL, my own card
        LD      (DCUR),A
        LD      (VIEWIDX),A
        LD      HL,GODICE       ; a fresh turn stages roll-everything; a
        CALL    RXGETB          ; mid-turn rejoin restages the wire's
        OR      A               ; mask instead
        JR      Z,GLGT0
        CALL    KEEPSYN
        JR      GLGT0A
GLGT0:  CALL    KEEPRST
GLGT0A: LD      A,(V_ST)        ; rejoined with the rolls spent: straight
        OR      A               ; to the score rows
        JR      NZ,GLGT0B
        LD      A,1
        LD      (UIMODE),A
        CALL    PICKBEST
GLGT0B: CALL    SNDTRN          ; announce BEFORE the input slice
        JR      GLGT2
GLGT1:  LD      A,(V_ACT)       ; someone else's turn: follow the roller
        INC     A
        JR      Z,GLGT2         ; FFH: nobody
        DEC     A
        LD      HL,V_PC
        CP      (HL)
        JR      NC,GLGT2
        LD      (VIEWIDX),A
GLGT2:  CALL    PLAYRD
        LD      A,(V_MYTRN)
        OR      A
        JR      Z,GLGW          ; not my turn: watch only
        CALL    TURNIN
        LD      A,(V_FLAG)
        CP      1
        JR      NZ,GLG2
        LD      A,2             ; rolled: stage /roll
        LD      (PENDACT),A
        JP      GAMELP
GLG2:   CP      2
        JR      NZ,GLG3
        LD      A,3             ; scored: stage /score
        LD      (PENDACT),A
        JP      GAMELP
GLG3:   CP      3
        JP      Z,GLLEAV        ; CE inside the turn
        CP      4
        JR      NZ,GLG4
        CALL    HELPSCR         ; '.' inside the turn
        LD      A,0FFH
        LD      (PRVCLS),A
GLG4:   JP      GAMELP          ; slice burned either way: poll now
GLGW:   LD      B,45            ; ~1 s between game polls
        JP      GLWAIT

; The between-polls input scan. The lobby ready toggle lives HERE, in the
; input path -- edge-detected by KEYSCN, so one press cannot ready and
; un-ready across two polls, and the trigger that joined the table cannot
; toggle on arrival while still held (the Intellivision lesson). The
; scorecard paging while it is someone else's turn lives here too.
GLWAIT: PUSH    BC
        CALL    KEYSCN
        POP     BC
        OR      A
        JR      NZ,GLKEY
        LD      DE,2500         ; ~20 ms
GLDLY:  DEC     DE
        LD      A,D
        OR      E
        JR      NZ,GLDLY
        DJNZ    GLWAIT
        JP      GAMELP
GLKEY:  CP      'E'             ; CE leaves the table
        JR      Z,GLLEAV
        CP      '.'
        JR      NZ,GLK1
        CALL    HELPSCR
        LD      A,0FFH
        LD      (PRVCLS),A      ; force the statics on return
        JP      GAMELP
GLK1:   CP      'T'
        JR      NZ,GLK2
        LD      A,(V_CLS)
        OR      A
        JP      NZ,GLWAIT       ; the trigger only means READY in the lobby
        CALL    SNDSEL
        LD      A,1
        LD      (PENDACT),A     ; stage /ready
        JP      GAMELP
GLK2:   CP      '0'
        JP      Z,GAMELP        ; poll now
        CP      'L'
        LD      E,0FFH
        JR      Z,GLPAGE
        CP      'R'
        LD      E,1
        JR      Z,GLPAGE
        JP      GLWAIT
GLPAGE: LD      A,(V_CLS)       ; page the viewed card: play class,
        CP      1               ; someone else's turn, more than one seat
        JP      NZ,GLWAIT
        LD      A,(V_MYTRN)
        OR      A
        JP      NZ,GLWAIT
        LD      A,(V_PC)
        CP      2
        JP      C,GLWAIT
        LD      A,(VIEWIDX)
        ADD     A,E             ; +1 or -1
        CP      0FFH
        JR      NZ,GLPG1
        LD      A,(V_PC)        ; wrapped below 0
        DEC     A
GLPG1:  LD      HL,V_PC
        CP      (HL)
        JR      C,GLPG2
        XOR     A               ; wrapped past the end
GLPG2:  LD      (VIEWIDX),A
        PUSH    BC
        CALL    SNDKEY
        CALL    HDRDRW          ; immediate redraw from the cached reply
        CALL    CARDRW
        CALL    PANEL
        POP     BC
        JP      GLWAIT
GLLEAV: LD      A,5
        CALL    APICALL         ; best effort; we are going regardless
        JP      TBLSCR
GLFAIL: LD      HL,TBANG        ; a red mark in the corner; back off and
        LD      DE,0*256+39     ; try again
        LD      C,XRONF
        CALL    TXTAT
        LD      B,150
GLFW:   PUSH    BC
        CALL    KEYSCN
        POP     BC
        CP      'E'
        JR      Z,GLLEAV
        LD      DE,2500
GLFD:   DEC     DE
        LD      A,D
        OR      E
        JR      NZ,GLFD
        DJNZ    GLFW
        JP      GAMELP

; ----------------------------------------------------------------------
; CHKNEW: map the round to a screen class (0 lobby, 1 play, 2 over). A
; class or seat-count change means the screen holds content that no
; longer exists: clear, redraw the statics, and reset the edges that
; must not fire across the boundary. V_NEWS = 1 when that happened
; (GOVERR's cue plays on it).
CHKNEW: LD      HL,GORND
        CALL    RXGETB
        OR      A
        JR      Z,CHKC          ; 0 -> lobby
        CP      RNOVER
        JR      NZ,CHKC1
        LD      A,2
        JR      CHKC
CHKC1:  LD      A,1
CHKC:   LD      (V_CLS),A
        LD      HL,PRVCLS
        CP      (HL)
        LD      (HL),A
        JR      NZ,CHKN1
        LD      A,(V_PC)
        LD      HL,PRVPC
        CP      (HL)
        LD      (HL),A
        JR      NZ,CHKN1
        XOR     A
        LD      (V_NEWS),A
        RET
CHKN1:  LD      A,(V_PC)        ; keep PRVPC honest on the class path too
        LD      (PRVPC),A
        LD      A,0FFH          ; a roll edge must not fire across the
        LD      (PRVRLS),A      ; boundary
        LD      A,1
        LD      (V_NEWS),A
        CALL    CLRSCR
        LD      A,(V_CLS)
        CP      1
        RET     NZ              ; lobby/gameover draw everything per poll
        JP      CARDST          ; play statics: the scorecard labels

; PRMPT: the server prompt (41 wire bytes) as a fixed-width field at
; row D, col 0 -- 36 cells; the clock owns the last three. Clobbers
; everything.
PRMPT:  PUSH    DE
        LD      HL,GOPRMPT
        LD      DE,LINBUF
        LD      B,37
        CALL    RXSTRN
        POP     DE
        LD      E,0
        LD      HL,LINBUF
        LD      C,XWONF
        LD      B,36
        JP      TXTN

; CLOCK: the move timer, red, in the prompt row's last three cells.
CLOCK:  LD      A,(V_ACT)
        INC     A               ; FFH = nobody: blank the field
        JR      Z,CLKB
        LD      HL,GOMVTIM
        CALL    RXGETB
        LD      L,A
        LD      H,0
        CALL    U16STR
        LD      HL,LINBUF
        LD      DE,14*256+37
        LD      C,XRONF
        LD      B,3
        JP      TXTN
CLKB:   LD      HL,TNUL
        LD      DE,14*256+37
        LD      C,XWONF
        LD      B,3
        JP      TXTN

; ======================================================================
; The lobby
; ======================================================================
; LOBBYR: a full-text screen. Fixed-width TXTN fields make every row
; self-clearing; the ready toggle itself is sampled in GLWAIT (the input
; path), never here -- this runs only once per poll. The ready flag is
; the seat's scores[0] word: 1 ready, 0 not, FFFEH spectator.
LOBBYR: LD      HL,TBLNAM
        LD      DE,0*256+0
        LD      C,XWONF
        LD      B,21
        CALL    TXTN
        LD      HL,GOSRVNM
        LD      DE,LINBUF
        LD      B,21
        CALL    RXSTRN
        LD      HL,LINBUF
        LD      DE,1*256+0
        LD      C,XWONF
        LD      B,21
        CALL    TXTN
        XOR     A
        LD      (V_TMP),A
LOBP:   LD      A,(V_TMP)
        CP      8               ; list rows 3-10
        JR      NC,LOBP9
        LD      HL,V_PC
        CP      (HL)
        JR      NC,LOBBLK       ; row beyond the seat count: blank it
        CALL    PLBASE
        PUSH    HL
        LD      DE,LINBUF       ; the name
        LD      B,9
        CALL    RXSTRN
        LD      A,(V_TMP)
        ADD     A,3
        LD      D,A
        LD      E,2
        LD      HL,LINBUF
        LD      C,XWONF
        LD      B,9
        CALL    TXTN
        POP     HL
        LD      C,0             ; the seat's ready word, scores[0]
        CALL    RDSCOR          ; DE = word
        LD      HL,TREADY
        LD      C,XFONW
        LD      A,D
        OR      A
        JR      NZ,LOBS0
        LD      A,E
        CP      1
        JR      Z,LOBS1         ; 0001: ready
LOBS0:  LD      HL,TVIEWW
        LD      C,XWONF
        LD      A,D
        CP      0FFH
        JR      NZ,LOBS2
        LD      A,E
        CP      0FEH
        JR      Z,LOBS1         ; FFFE: a spectator
LOBS2:  LD      HL,TDOT         ; anything else: not ready yet
        LD      C,XWONF
LOBS1:  LD      A,(V_TMP)
        ADD     A,3
        LD      D,A
        LD      E,15
        LD      B,6
        CALL    TXTN
        JR      LOBNXT
LOBBLK: ADD     A,3             ; vacated row: blank name + status
        LD      D,A
        LD      E,2
        LD      HL,TNUL
        LD      C,XWONF
        LD      B,19
        CALL    TXTN
LOBNXT: LD      A,(V_TMP)
        INC     A
        LD      (V_TMP),A
        JR      LOBP
LOBP9:  LD      D,11
        CALL    PRMPT
        LD      HL,GOPRMPT      ; "starting in N..." begins with 's':
        CALL    RXGETB          ; tick along with the countdown
        CP      73H
        CALL    Z,SNDTICK
        LD      HL,TLOBK1
        LD      DE,12*256+0
        LD      C,XWONF
        CALL    TXTAT
        LD      HL,TLOBK2
        LD      DE,14*256+0
        LD      C,XWONF
        JP      TXTAT

; ======================================================================
; Rendering a play poll
; ======================================================================
; PLAYRD: header, scorecard, standings panel, banner, dice, prompt,
; clock -- all straight out of the reply window.
PLAYRD: CALL    HDRDRW
        CALL    CARDRW
        CALL    PANEL
        LD      A,(V_MYTRN)     ; the your-turn banner, row 9
        OR      A
        LD      HL,TYOURT
        JR      NZ,PLYB1
        LD      HL,TNUL
PLYB1:  LD      DE,9*256+6
        LD      C,XRONF
        LD      B,28
        CALL    TXTN
        LD      A,(V_MYTRN)     ; the paging hint, row 8 right
        OR      A
        LD      HL,TNUL
        JR      NZ,PLYH1
        LD      A,(V_PC)
        CP      2
        JR      C,PLYH1
        LD      HL,TPAGE
PLYH1:  LD      DE,8*256+32
        LD      C,XWONF
        LD      B,8
        CALL    TXTN
        CALL    DICEROW
        CALL    DICEHUD
        LD      D,14
        CALL    PRMPT
        JP      CLOCK

; HDRDRW: row 0 -- the viewed player's name and the round counter.
HDRDRW: LD      A,(VIEWIDX)
        CALL    PLBASE
        LD      DE,LINBUF
        LD      B,9
        CALL    RXSTRN
        LD      HL,LINBUF
        LD      DE,0*256+0
        LD      C,XWONF
        LD      B,9
        CALL    TXTN
        LD      HL,TROUND
        LD      DE,0*256+10
        LD      C,XWONF
        CALL    TXTAT
        LD      HL,GORND
        CALL    RXGETB
        LD      L,A
        LD      H,0
        LD      B,2
        CALL    DECFLD
        LD      HL,LINBUF
        LD      DE,0*256+13
        LD      C,XWONF
        LD      B,2
        CALL    TXTN
        LD      HL,TOF13
        LD      DE,0*256+15
        LD      C,XWONF
        JP      TXTAT

; ======================================================================
; Game over (class 2)
; ======================================================================
; GOVERR: every player with their final total (the running-total sum --
; at gameover all nine summed slots are filled, so it equals the wire's
; grand total), the leader inverse, the winner text in the prompt. The
; cue plays once, on the class edge; the server auto-resets to the lobby
; and that class change rides CHKNEW like any other.
GOVERR: LD      HL,TGOVER
        LD      DE,0*256+11
        LD      C,XRONF
        CALL    TXTAT
        XOR     A               ; find the leader
        LD      (V_WIN),A
        LD      (V_TMP),A
        LD      HL,0
        LD      (BSTTOT),HL
GOVF1:  LD      A,(V_TMP)
        LD      HL,V_PC
        CP      (HL)
        JR      NC,GOVF9
        CALL    RUNTOT          ; HL = the player's total
        LD      DE,(BSTTOT)
        OR      A
        SBC     HL,DE
        JR      C,GOVF2
        JR      Z,GOVF2         ; first max wins
        ADD     HL,DE
        LD      (BSTTOT),HL
        LD      A,(V_TMP)
        LD      (V_WIN),A
GOVF2:  LD      A,(V_TMP)
        INC     A
        LD      (V_TMP),A
        JR      GOVF1
GOVF9:  XOR     A               ; the list, rows 2-9
        LD      (V_TMP),A
GOVL1:  LD      A,(V_TMP)
        CP      8
        JR      NC,GOVL9
        LD      HL,V_PC
        CP      (HL)
        JR      NC,GOVL9
        CALL    PLBASE
        LD      DE,LINBUF
        LD      B,9
        CALL    RXSTRN
        LD      A,(V_WIN)       ; the leader's row inverse
        LD      HL,V_TMP
        CP      (HL)
        LD      C,XFONW
        JR      Z,GOVL2
        LD      C,XWONF
GOVL2:  LD      A,(V_TMP)
        ADD     A,2
        LD      D,A
        LD      E,4
        LD      HL,LINBUF
        LD      B,9
        PUSH    BC
        CALL    TXTN
        POP     BC
        LD      A,(V_TMP)
        CALL    RUNTOT
        LD      B,4
        CALL    DECFLD
        LD      A,(V_WIN)       ; the row color again -- RUNTOT and
        LD      HL,V_TMP        ; DECFLD clobbered C
        CP      (HL)
        LD      C,XFONW
        JR      Z,GOVL3
        LD      C,XWONF
GOVL3:  LD      A,(V_TMP)
        ADD     A,2
        LD      D,A
        LD      E,16
        LD      HL,LINBUF
        LD      B,4
        CALL    TXTN
        LD      A,(V_TMP)
        INC     A
        LD      (V_TMP),A
        JR      GOVL1
GOVL9:  LD      D,11
        CALL    PRMPT
        LD      HL,TGOK
        LD      DE,14*256+0
        LD      C,XWONF
        CALL    TXTAT
        LD      A,(V_NEWS)
        OR      A
        RET     Z
        JP      SNDOVER

; ----------------------------------------------------------------------
; HELPSCR: how to play. Any key returns.
HELPSCR: CALL   KEYRAW
        LD      (V_KEY),A
        CALL    CLRSCR
        LD      HL,HELPTX
        LD      D,0             ; row; strings run in order, one per row,
HELP1:  LD      A,(HL)          ; first byte = column (FF ends)
        CP      0FFH
        JR      Z,HELP9
        LD      E,A
        INC     HL
        PUSH    DE
        PUSH    HL
        LD      C,XWONF
        CALL    TXTAT
        POP     HL
HELP2:  LD      A,(HL)          ; skip past the NUL
        INC     HL
        OR      A
        JR      NZ,HELP2
        POP     DE
        INC     D
        JR      HELP1
HELP9:  CALL    KEYSCN
        OR      A
        JR      Z,HELP9
        RET

HELPTX: DB      16,"FUJITZEE",0
        DB      0,"",0
        DB      1,"ROLL FIVE DICE, UP TO THREE",0
        DB      1,"ROLLS A TURN. TRIGGER MARKS",0
        DB      1,"DICE TO HOLD, THEN PICK ONE",0
        DB      1,"SCORE ROW: RED SHOWS WHAT AN",0
        DB      1,"OPEN ROW WOULD EARN. BEST",0
        DB      1,"TOTAL AFTER 13 ROUNDS WINS.",0
        DB      0,"",0
        DB      1,"STICK MOVES  TRIGGER SELECTS",0
        DB      1,"UP ENTERS THE SCORE ROWS",0
        DB      1,"TRIGGER READIES IN THE LOBBY",0
        DB      1,"CE LEAVES    . THIS SCREEN",0
        DB      0,"",0
        DB      1,"FUJITZEE.CARR-DESIGNS.COM",0
        DB      0FFH

TCHOOS: DB      "CHOOSE A TABLE",0
TJOIN:  DB      "JOINING...",0
TREADY: DB      "READY",0
TVIEWW: DB      "VIEW",0
TDOT:   DB      ".",0
TTURN:  DB      "TURN",0
TYOURT: DB      "YOUR TURN - ROLL OR SCORE",0
TPAGE:  DB      "< > VIEW",0
TROUND: DB      "RD",0
TOF13:  DB      "/13",0
TGOVER: DB      "G A M E  O V E R",0
TGOK:   DB      "CE LEAVES         NEXT GAME SOON",0
TLOBK1: DB      "TRIGGER = READY ON/OFF",0
TLOBK2: DB      "CE LEAVES  . HELP  0 REFRESH",0
TBANG:  DB      "!",0
