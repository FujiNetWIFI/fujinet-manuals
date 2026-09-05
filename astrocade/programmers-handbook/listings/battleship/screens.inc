; screens.inc -- table selection, the poll loop, and the per-class
; renderers.
;
; Rendering policy (the card-game ports'): every poll redraws everything,
; opaquely, straight out of the reply window -- identical pixels
; rewritten are invisible, so there is no flicker and no digest
; bookkeeping. The one thing opaque overdraw cannot fix is content that
; SHRANK, so CHKNEW watches the screen class (lobby / place / game /
; over) and the seat count, and answers a change with a full clear +
; statics before the ordinary render.
;
; The poll loop is the Intellivision tl_loop reshaped into the texas
; GAMELP: one staged action (PENDACT) rides the next request in place of
; /state -- every endpoint returns the same state blob -- and the reply
; is dispatched by class. The turn edge (V_TRNF) is computed from
; PRVACT at the top of every successful poll, lobby and placement
; included, so the lobby->play transition is caught by the same
; comparison as any other turn change.

; ======================================================================
; Table selection
; ======================================================================
TBLSCR: CALL    KEYRAW          ; a key still held from the previous
        LD      (V_KEY),A       ; screen must not fire here
        CALL    CLRSCR
        SYSSUK  STRDIS          ; title, BIOS font at 2x
        DB      0               ; "BATTLESHIP": 10 chars x 16px = the row
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
        LD      (PRVRST),A      ; and the result-sound edge
        XOR     A
        LD      (PENDACT),A
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
        CALL    APICALL         ; 2 -> 3 /place, 3 -> 4 /attack
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
        CALL    CHKNEW
        LD      A,(V_CLS)       ; dispatch by class
        OR      A
        JP      Z,GLLOB
        CP      1
        JP      Z,GLPLC
        CP      2
        JP      Z,GLGAM
        CALL    RENDGO          ; class 3: game over
        LD      B,150           ; ~3 s; the server resets to the lobby
        JP      GLWAIT

GLLOB:  CALL    LOBBYR
        LD      B,90            ; ~2 s between lobby polls
        JP      GLWAIT

GLPLC:  LD      HL,GOPSTAT
        CALL    RXGETB
        CP      PSPLACE
        JR      NZ,GLPLW
        CALL    PLACESCR        ; blocking; fills MYSHP
        LD      A,2
        LD      (PENDACT),A     ; stage /place
        JP      GAMELP
GLPLW:  LD      D,14            ; placed already: show the server prompt
        CALL    PRMPT           ; ("waiting for others")
        LD      B,45
        JP      GLWAIT

GLGAM:  CALL    RENDER
        LD      A,(V_ACT)
        OR      A
        JR      NZ,GLGW         ; not your turn
        LD      HL,GOPSTAT
        CALL    RXGETB
        CP      PSPLAY
        JR      NZ,GLGW         ; defeated or viewing: watch only
        LD      A,(V_TRNF)      ; announce BEFORE targeting -- it holds
        OR      A               ; the loop for up to a slice, and a cue
        CALL    NZ,SNDTRN       ; after it is no alert at all
        CALL    TARGET
        LD      A,(V_FLAG)
        CP      1
        JR      NZ,GLG2
        LD      A,3             ; fired: stage /attack
        LD      (PENDACT),A
        JP      GAMELP
GLG2:   CP      2
        JP      Z,GLLEAV        ; CE inside targeting
        CP      3
        JR      NZ,GLG3
        CALL    HELPSCR         ; '.' inside targeting
        LD      A,0FFH
        LD      (PRVCLS),A
GLG3:   JP      GAMELP          ; slice burned either way: poll now
GLGW:   LD      B,45            ; ~1 s between game polls
        JP      GLWAIT

; The between-polls input scan. The lobby ready toggle lives HERE, in the
; input path -- edge-detected by KEYSCN, so one press cannot ready and
; un-ready across two polls, and the trigger that joined the table cannot
; toggle on arrival while still held (the Intellivision lesson).
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
; CHKNEW: map the status to a screen class (0 lobby, 1 place, 2 game,
; 3 over). A class or seat-count change means the screen holds content
; that no longer exists: clear, redraw the statics, and reset the edges
; that must not fire across the boundary. V_NEWS = 1 when that happened
; (RENDGO's cue plays on it).
CHKNEW: LD      HL,GOSTAT
        CALL    RXGETB
        OR      A
        JR      Z,CHKC          ; 0 -> lobby
        CP      STPLACE
        JR      Z,CHKC          ; 1 -> place
        CP      STOVER
        JR      Z,CHKC3
        LD      A,2             ; 10-13 -> game
        JR      CHKC
CHKC3:  LD      A,3
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
        LD      A,0FFH          ; a stale result pair must not swallow
        LD      (PRVRST),A      ; the new screen's first result
        LD      A,1
        LD      (V_NEWS),A
        CALL    CLRSCR
        LD      A,(V_CLS)
        OR      A
        RET     Z               ; lobby: LOBBYR draws everything
        JP      BRDSTAT         ; boards: the dividers

; PRMPT: the server prompt (33 wire bytes) as a fixed-width field at
; row D, col 0. Clobbers everything.
PRMPT:  PUSH    DE
        LD      HL,GOPRMPT
        LD      DE,LINBUF
        LD      B,33
        CALL    RXSTRN
        POP     DE
        LD      E,0
        LD      HL,LINBUF
        LD      C,XWONF
        LD      B,34
        JP      TXTN

; ======================================================================
; The lobby
; ======================================================================
; LOBBYR: a full-text screen. Fixed-width TXTN fields make every row
; self-clearing; the ready toggle itself is sampled in GLWAIT (the input
; path), never here -- this runs only once per poll.
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
        CP      4
        JR      NC,LOBP9
        LD      HL,V_PC
        CP      (HL)
        JR      NC,LOBBLK       ; row beyond the seat count: blank it
        LD      L,A             ; record base = GOLPLRS + i*10
        LD      H,0
        ADD     HL,HL
        LD      E,L
        LD      D,H
        ADD     HL,HL
        ADD     HL,HL           ; *8
        ADD     HL,DE           ; *10
        LD      DE,GOLPLRS
        ADD     HL,DE
        PUSH    HL
        LD      DE,LINBUF       ; the name
        LD      B,9
        CALL    RXSTRN
        LD      A,(V_TMP)
        ADD     A,3             ; list rows 3-6
        LD      D,A
        LD      E,2
        LD      HL,LINBUF
        LD      C,XWONF
        LD      B,9
        CALL    TXTN
        POP     HL
        LD      DE,LPSTAT       ; the seat's status word
        ADD     HL,DE
        CALL    RXGETB
        LD      HL,TREADY
        LD      C,XFONW
        CP      PSREADY
        JR      Z,LOBS1
        LD      HL,TVIEWW
        LD      C,XWONF
        CP      PSVIEW
        JR      Z,LOBS1
        LD      HL,TNUL
LOBS1:  LD      A,(V_TMP)
        ADD     A,3
        LD      D,A
        LD      E,13
        LD      B,6
        CALL    TXTN
        JR      LOBNXT
LOBBLK: ADD     A,3             ; vacated row: blank name + status
        LD      D,A
        LD      E,2
        LD      HL,TNUL
        LD      C,XWONF
        LD      B,17
        CALL    TXTN
LOBNXT: LD      A,(V_TMP)
        INC     A
        LD      (V_TMP),A
        JR      LOBP
LOBP9:  LD      D,8
        CALL    PRMPT
        LD      HL,TLOBK1
        LD      DE,10*256+0
        LD      C,XWONF
        CALL    TXTAT
        LD      HL,TLOBK2
        LD      DE,12*256+0
        LD      C,XWONF
        JP      TXTAT

; ======================================================================
; Rendering a game poll
; ======================================================================
RENDER: XOR     A               ; the quadrants, in wire order (walks the
        LD      (V_TMP),A       ; window forward: fewest slice flips)
RENQ:   LD      A,(V_TMP)
        LD      HL,V_PC
        CP      (HL)
        JR      NC,RENQ9
        CALL    QUADDRW
        LD      A,(V_TMP)
        INC     A
        LD      (V_TMP),A
        JR      RENQ
RENQ9:  LD      HL,GOPSTAT      ; own-ship overlay on quadrant 0 -- the
        CALL    RXGETB          ; wire is authoritative over what
        CP      PSVIEW          ; placement guessed (covers reconnects);
        JR      Z,RENP          ; a viewer has no ships
        LD      DE,GOMYSH
        XOR     A               ; quadrant 0
        LD      C,0FFH          ; per cell: your own field marks damage
        CALL    SHIPSET
RENP:   CALL    PANEL
        LD      D,14
        CALL    PRMPT
        CALL    CLOCK
        LD      HL,GOSTAT       ; the result edge: (status, lastAttack)
        CALL    RXGETB          ; as a pair -- the status repeats across
        CP      STMISS          ; polls when nobody has fired since
        RET     C               ; GAMESTART: no result yet
        CP      STSUNK+1
        RET     NC
        LD      B,A
        LD      HL,GOLATK
        CALL    RXGETB
        LD      C,A
        LD      A,(PRVRST)
        CP      B
        JR      NZ,RENR1
        LD      A,(PRVRPS)
        CP      C
        RET     Z               ; the same event as last poll
RENR1:  LD      A,B
        LD      (PRVRST),A
        LD      A,C
        LD      (PRVRPS),A
        LD      A,B
        CP      STMISS
        JP      Z,SNDMISS
        CP      STHIT
        JP      Z,SNDHIT
        JP      SNDSUNK

; CLOCK: the move timer, red, in the prompt row's last three cells --
; three digits, because single-player runs to 250.
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

; ----------------------------------------------------------------------
; PANEL: the right-hand chrome, char cols 22-39 (col 21 is the gutter).
; Two rows per player: the quadrant tag + name (inverse when active,
; black when defeated) + a red TURN tag, then five ship pips from
; shipsLeft ('#' afloat, '.' sunk) with SUNK when none remain. Absent
; seats blank themselves via the fixed-width fields. Row 13 carries the
; your-turn banner (game class only).
PANEL:  XOR     A
        LD      (V_TMP),A
PANL:   LD      A,(V_TMP)
        CP      4
        JP      NC,PAN9
        LD      HL,V_PC
        CP      (HL)
        JP      NC,PANBLK
        ADD     A,A             ; the quadrant tag
        LD      HL,QTAG
        LD      E,A
        LD      D,0
        ADD     HL,DE
        LD      A,(HL)
        LD      (LINBUF),A
        INC     HL
        LD      A,(HL)
        LD      (LINBUF+1),A
        XOR     A
        LD      (LINBUF+2),A
        LD      A,(V_TMP)
        LD      D,A
        ADD     A,A
        ADD     A,D
        LD      D,A             ; row = i*3
        LD      E,22
        LD      HL,LINBUF
        LD      C,XWONF
        LD      B,2
        CALL    TXTN
        LD      A,(V_TMP)       ; the name and its status color
        CALL    PLBASE
        PUSH    HL
        LD      DE,LINBUF
        LD      B,9
        CALL    RXSTRN
        POP     HL
        PUSH    HL
        LD      DE,PLSTAT
        ADD     HL,DE
        CALL    RXGETB
        LD      (V_ST),A
        LD      A,(V_TMP)
        LD      HL,V_ACT
        CP      (HL)
        LD      C,XFONW         ; active: inverse
        JR      Z,PANNC
        LD      A,(V_ST)
        CP      PSDEAD
        LD      C,XKONF         ; defeated: black
        JR      Z,PANNC
        LD      C,XWONF
PANNC:  LD      A,(V_TMP)
        LD      D,A
        ADD     A,A
        ADD     A,D
        LD      D,A
        LD      E,25
        LD      HL,LINBUF
        LD      B,9
        CALL    TXTN
        LD      A,(V_TMP)       ; the TURN tag
        LD      HL,V_ACT
        CP      (HL)
        LD      HL,TTURN
        JR      Z,PANT1
        LD      HL,TNUL
PANT1:  LD      A,(V_TMP)
        LD      D,A
        ADD     A,A
        ADD     A,D
        LD      D,A
        LD      E,35
        LD      C,XRONF
        LD      B,4
        CALL    TXTN
        POP     HL              ; ship pips from shipsLeft
        LD      DE,PLSHLFT
        ADD     HL,DE
        LD      DE,LINBUF
        LD      C,0             ; afloat count
        LD      B,5
PANP1:  CALL    RXGETB
        OR      A
        LD      A,'.'
        JR      Z,PANP2
        LD      A,'#'
        INC     C
PANP2:  LD      (DE),A
        INC     DE
        INC     HL
        DJNZ    PANP1
        XOR     A
        LD      (DE),A
        LD      A,C
        LD      (V_ST),A        ; the afloat count, for the SUNK tag
        LD      A,(V_TMP)
        LD      D,A
        ADD     A,A
        ADD     A,D
        INC     A
        LD      D,A             ; row = i*3 + 1
        LD      E,25
        LD      HL,LINBUF
        LD      C,XWONF
        LD      B,5
        CALL    TXTN
        LD      A,(V_ST)
        OR      A
        LD      HL,TSUNK
        JR      Z,PANS1
        LD      HL,TNUL
PANS1:  LD      A,(V_TMP)
        LD      D,A
        ADD     A,A
        ADD     A,D
        INC     A
        LD      D,A
        LD      E,31
        LD      C,XRONF
        LD      B,4
        CALL    TXTN
        JR      PANNXT
PANBLK: LD      A,(V_TMP)       ; absent seat: blank both rows whole
        LD      D,A
        ADD     A,A
        ADD     A,D
        LD      D,A
        LD      E,22
        LD      HL,TNUL
        LD      C,XWONF
        LD      B,18
        CALL    TXTN
        LD      A,(V_TMP)
        LD      D,A
        ADD     A,A
        ADD     A,D
        INC     A
        LD      D,A
        LD      E,22
        LD      HL,TNUL
        LD      C,XWONF
        LD      B,18
        CALL    TXTN
PANNXT: LD      A,(V_TMP)
        INC     A
        LD      (V_TMP),A
        JP      PANL
PAN9:   LD      A,(V_CLS)       ; the your-turn banner, game class only
        CP      2
        JR      NZ,PAN9A
        LD      A,(V_ACT)
        OR      A
        JR      NZ,PAN9A
        LD      HL,GOPSTAT
        CALL    RXGETB
        CP      PSPLAY
        JR      NZ,PAN9A
        LD      HL,TFIRE
        JR      PAN9B
PAN9A:  LD      HL,TNUL
PAN9B:  LD      DE,13*256+22
        LD      C,XRONF
        LD      B,17
        JP      TXTN

; ----------------------------------------------------------------------
; RENDGO: the final boards plus the winner's ships revealed in the SUNK
; pattern on their quadrant (v=2's myShips[5..9]). The cue plays once,
; on the class edge; the server auto-resets to the lobby and that class
; change rides CHKNEW like any other.
RENDGO: CALL    RENDER          ; final fields; the prompt carries the
        LD      A,(V_NEWS)      ; winner message
        OR      A
        CALL    NZ,SNDOVER
        LD      HL,TGOVER
        LD      DE,13*256+22
        LD      C,XRONF
        LD      B,17
        CALL    TXTN
        LD      A,(V_ACT)       ; v=2: activePlayer = the winner
        CP      4
        RET     NC              ; -1 (or junk): nothing to reveal
        LD      DE,GOMYSH+5
        LD      C,PSUNK
        JP      SHIPSET

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

HELPTX: DB      15,"BATTLESHIP",0
        DB      0,"",0
        DB      1,"PLACE FIVE SHIPS, THEN TAKE",0
        DB      1,"TURNS FIRING. ONE SHOT HITS",0
        DB      1,"THAT CELL ON EVERY ENEMY",0
        DB      1,"BOARD AT ONCE. SINK EVERY",0
        DB      1,"ENEMY FLEET TO WIN.",0
        DB      0,"",0
        DB      1,"STICK MOVES   TRIGGER FIRES",0
        DB      1,"0 ROTATES A SHIP / POLLS NOW",0
        DB      1,"TRIGGER READIES IN THE LOBBY",0
        DB      1,"CE LEAVES     . THIS SCREEN",0
        DB      0,"",0
        DB      1,"BATTLESHIP.CARR-DESIGNS.COM",0
        DB      0FFH

TCHOOS: DB      "CHOOSE A TABLE",0
TJOIN:  DB      "JOINING...",0
TREADY: DB      "READY",0
TVIEWW: DB      "VIEW",0
TTURN:  DB      "TURN",0
TSUNK:  DB      "SUNK",0
TFIRE:  DB      "YOUR TURN - FIRE",0
TGOVER: DB      "GAME OVER",0
TLOBK1: DB      "TRIGGER = READY ON/OFF",0
TLOBK2: DB      "CE LEAVES  . HELP  0 REFRESH",0
TBANG:  DB      "!",0
TNUL:   DB      0
