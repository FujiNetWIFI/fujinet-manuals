; screens.inc -- table selection, the game screen, and the poll loop.
;
; Rendering policy: every poll redraws everything, opaquely, straight out
; of the reply window -- identical pixels rewritten are invisible, so
; there is no flicker and no digest bookkeeping. The one thing opaque
; overdraw cannot fix is content that SHRANK (a new hand dealt, a player
; gone), so CHKNEW watches round/playerCount and answers with a full
; clear + statics before the ordinary render.
;
; Seat geometry is the Lynx port's, compressed to 15 rows: master seats
; 0-7 run bottom-center, bottom-left, mid-left, top-left, top-center,
; top-right, mid-right, bottom-right; PCIDX picks which masters serve a
; given player count, with the requesting player (index 0) always at
; master seat 0. Hands are 11 cols wide worst case; every hand draws
; left-to-right whatever its side of the table.

; ======================================================================
; Table selection
; ======================================================================
TBLSCR: CALL    KEYRAW          ; a key still held from the previous
        LD      (V_KEY),A       ; screen must not fire here
        CALL    CLRSCR
        SYSSUK  STRDIS          ; two-line title, BIOS font at 2x
        DB      40              ; "TEXAS": 5 chars x 16px, centred on 160
        DB      0
        DB      4CH
        DW      TTEXAS
        SYSSUK  STRDIS
        DB      32              ; "HOLDEM": 6 chars x 16px
        DB      17
        DB      4CH
        DW      THOLDM
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
        LD      DE,9            ; the name field, for the game header
        ADD     HL,DE
        LD      DE,TBLNAM
        LD      B,21
        CALL    RXSTRN
        CALL    CLRSCR
        LD      HL,TJOIN
        LD      DE,7*256+14
        LD      C,XWONF
        CALL    TXTAT
        LD      A,0FFH          ; force the new-hand path on first poll
        LD      (PRVRND),A
        LD      (PRVACT),A      ; and arm the your-turn cue
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
        LD      DE,9            ; the display name field
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
        LD      DE,30           ; the "cur / max" field
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
; The game loop
; ======================================================================
GAMELP: LD      A,(MOVBUF)      ; a staged move rides the next request --
        OR      A               ; its reply IS the next state
        LD      A,1
        JR      Z,GLREQ
        LD      A,2
GLREQ:  CALL    APICALL
        JR      C,GLFAIL
        XOR     A
        LD      (MOVBUF),A      ; consumed
        CALL    CHKNEW
        CALL    RENDER
        LD      B,90            ; ~2 s of input scanning between polls
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
        JR      GAMELP
GLKEY:  CP      'E'             ; CE leaves the table
        JR      NZ,GLK1
        LD      A,3
        CALL    APICALL         ; best effort; we are going regardless
        JP      TBLSCR
GLK1:   CP      '.'             ; how to play, then a forced full redraw
        JR      NZ,GLK1A
        CALL    HELPSCR
        LD      A,0FFH
        LD      (PRVRND),A
        JP      GAMELP
GLK1A:  CP      '1'
        JR      C,GLK3          ; '0' (or below): refresh now
        CP      '5'+1
        JR      NC,GLK3
        SUB     '1'             ; keypad 1-5 -> validMoves 0-4
        LD      HL,GOMVCNT
        LD      B,A
        CALL    RXGETB
        LD      C,A
        LD      A,B
        CP      C
        JR      NC,GLK3         ; not on the menu right now
        LD      L,A             ; move code offset = GOMOVES + n*13
        LD      H,0
        LD      E,A
        LD      D,H
        ADD     HL,HL
        ADD     HL,DE           ; *3
        ADD     HL,HL
        ADD     HL,HL           ; *12
        ADD     HL,DE           ; *13
        LD      DE,GOMOVES
        ADD     HL,DE
        CALL    RXGETB
        LD      (MOVBUF),A
        INC     HL
        CALL    RXGETB
        LD      (MOVBUF+1),A
        CALL    SNDSEL
GLK3:   JP      GAMELP          ; poll immediately (move or refresh)
GLFAIL: LD      HL,TBANG        ; a red mark in the corner; back off and
        LD      DE,0*256+39     ; try again
        LD      C,XRONF
        CALL    TXTAT
        LD      B,150
GLFW:   PUSH    BC
        CALL    KEYSCN
        POP     BC
        CP      'E'
        JR      NZ,GLFW1
        LD      A,3
        CALL    APICALL
        JP      TBLSCR
GLFW1:  LD      DE,2500
GLFD:   DEC     DE
        LD      A,D
        OR      E
        JR      NZ,GLFD
        DJNZ    GLFW
        JP      GAMELP

; CHKNEW: a new hand (round dropped) or a changed seat count means the
; screen holds cards that no longer exist: clear and redraw the statics.
CHKNEW: LD      HL,GOROUND
        CALL    RXGETB
        LD      HL,PRVRND
        CP      (HL)
        LD      (HL),A
        JR      C,CHKN1
        LD      HL,GOPLCNT
        CALL    RXGETB
        LD      HL,PRVPC
        CP      (HL)
        LD      (HL),A
        RET     Z
CHKN1:  LD      HL,GOPLCNT      ; keep PRVPC honest on the round path too
        CALL    RXGETB
        LD      (PRVPC),A
; falls through into GSTATIC

; GSTATIC: clear + the parts of the game screen a poll never changes.
GSTATIC: CALL   CLRSCR
        XOR     A               ; the clear took every card with it, so the
        LD      (PRVCOM),A      ; shrink checks have nothing left to chase
        LD      B,8
        LD      HL,PRVHND
GSTZ:   LD      (HL),A
        INC     HL
        DJNZ    GSTZ
        LD      HL,TBLNAM
        LD      DE,0*256+0
        LD      C,XWONF
        JP      TXTAT

; ======================================================================
; Rendering a poll
; ======================================================================
RENDER: LD      HL,GOROUND      ; the street, named above the board
        CALL    RXGETB
        CP      6               ; VALID8 checks the reply LENGTH, never the
        JR      C,RNDOK         ; round, and this indexes a table: clamp it
        XOR     A
RNDOK:  ADD     A,A             ; STREETS is 8 space-padded bytes per round
        ADD     A,A
        ADD     A,A
        LD      E,A
        LD      D,0
        LD      HL,STREETS
        ADD     HL,DE
        LD      DE,5*256+16
        LD      C,XWONF
        LD      B,8             ; TXTN pads the field, so a short label
        CALL    TXTN            ; wipes a long one with no blanking pass
        CALL    BOARD
        LD      HL,GOACTPL
        CALL    RXGETB
        LD      (V_ACT),A
        LD      HL,PRVACT       ; the your-turn cue, on the edge only
        CP      (HL)
        LD      (HL),A
        JR      Z,RENDA2
        OR      A
        JR      NZ,RENDA2
        CALL    SNDTRN
RENDA2: LD      HL,GOPLCNT
        CALL    RXGETB
        LD      (V_PC),A
        XOR     A               ; each seated player
        LD      (V_TMP),A
RENDP:  LD      A,(V_TMP)
        LD      HL,V_PC
        CP      (HL)
        JR      NC,RENDG
        CALL    SEAT1
        LD      A,(V_TMP)
        INC     A
        LD      (V_TMP),A
        JR      RENDP
RENDG:  CALL    PURSE
        JP      BAR

; ----------------------------------------------------------------------
; SEAT1: render player (V_TMP): name, bet, hand.
SEAT1:  LD      A,(V_PC)        ; master seat = PCIDX[(pc-2)*8 + i]
        SUB     2
        ADD     A,A
        ADD     A,A
        ADD     A,A
        LD      HL,V_TMP
        ADD     A,(HL)
        LD      HL,PCIDX
        LD      E,A
        LD      D,0
        ADD     HL,DE
        LD      A,(HL)
        LD      (V_SEAT),A
        LD      A,(V_TMP)       ; record base = GOPLYRS + i*33
        LD      L,A
        LD      H,0
        LD      E,A
        LD      D,H
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL           ; *32
        ADD     HL,DE           ; *33
        LD      DE,GOPLYRS
        ADD     HL,DE
        LD      (V_BASE),HL
        LD      DE,PLSTAT       ; status
        ADD     HL,DE
        CALL    RXGETB
        LD      (V_ST),A
        LD      HL,(V_BASE)     ; name
        LD      DE,LINBUF
        LD      B,9
        CALL    RXSTRN
        LD      A,(V_TMP)       ; color: active inverse, folded/left dim
        LD      HL,V_ACT
        CP      (HL)
        LD      C,XFONW
        JR      Z,SEATN
        LD      A,(V_ST)
        CP      2
        LD      C,XKONF
        JR      NC,SEATN
        LD      C,XWONF
SEATN:  LD      A,(V_SEAT)
        LD      HL,SEATNR
        CALL    TBLK
        LD      D,A
        LD      A,(V_SEAT)
        LD      HL,SEATNC
        CALL    TBLK
        LD      E,A
        LD      HL,LINBUF
        LD      B,9
        CALL    TXTN
        LD      A,(V_SEAT)      ; the bet chip; yours lives in the purse
        OR      A               ; line instead
        JR      Z,SEATH
        LD      HL,(V_BASE)
        LD      DE,PLBET
        ADD     HL,DE
        CALL    RXGETW
        LD      A,D
        OR      E
        JR      Z,SEATB0
        PUSH    DE
        CALL    SEATBP          ; D,E = bet row,col
        CALL    DRWCHP
        CALL    SEATBP
        INC     E               ; amount right of the chip
        POP     HL
        PUSH    DE
        CALL    U16STR
        POP     DE
        LD      HL,LINBUF
        LD      B,4
        LD      C,XWONF
        CALL    TXTN
        JR      SEATH
SEATB0: CALL    SEATBP          ; no bet: blank the chip cell + amount
        CALL    CRDPOS
        LD      B,6
        LD      C,1
        LD      D,0
        CALL    FILLRC
        CALL    SEATBP
        INC     E
        LD      HL,TNUL
        LD      B,4
        LD      C,XWONF
        CALL    TXTN
SEATH:  LD      HL,(V_BASE)     ; the hand: 2 hole cards
        LD      DE,PLHAND
        ADD     HL,DE
        LD      DE,HANDBUF
        LD      B,11
        CALL    RXSTRN
        CALL    HNDCNT
        LD      A,(V_SEAT)
        LD      HL,SEATHR
        CALL    TBLK
        LD      D,A
        LD      A,(V_SEAT)
        LD      HL,SEATHC
        CALL    TBLK
        LD      E,A
        LD      A,(V_SEAT)      ; what this seat showed last poll: a fold
        LD      HL,PRVHND       ; turns "????" into "??" mid-hand, and the
        CALL    TBLK            ; card that went away is not overdrawn
        LD      C,A
        CALL    HNDBLK
        LD      A,(V_SEAT)
        LD      HL,PRVHND
        PUSH    DE
        LD      E,A
        LD      D,0
        ADD     HL,DE
        LD      A,(V_NCNT)
        LD      (HL),A
        POP     DE
        LD      HL,HANDBUF
        LD      B,2
        JP      DRWHND

; ----------------------------------------------------------------------
; BOARD: the community cards, centred at row 6 col 14. Five cards on the
; 2-col pitch span cols 14-24, clear of the mid seats' hands at cols 0-4
; and 29-33. Drawn every poll like any other field; only the shrink needs
; help, because the server can empty the board without the round dropping.
BOARD:  LD      HL,GOCOMM
        LD      DE,HANDBUF
        LD      B,11
        CALL    RXSTRN
        CALL    HNDCNT
        LD      A,(PRVCOM)
        LD      C,A
        LD      DE,6*256+14
        CALL    HNDBLK
        LD      A,(V_NCNT)
        LD      (PRVCOM),A
        LD      HL,HANDBUF
        LD      B,5
        JP      DRWHND

; HNDCNT: (V_NCNT) = cards in HANDBUF -- two wire chars per card, and the
; field is packed from the left, so it is just the length halved.
; Clobbers A,HL.
HNDCNT: LD      HL,HANDBUF
        CALL    STRLEN
        SRL     A
        LD      (V_NCNT),A
        RET

; HNDBLK: blank the card cells the last poll drew here that this one will
; not repaint -- the one thing opaque overdraw cannot fix. C = cards drawn
; last poll, (V_NCNT) = cards now, D = card row, E = start col. Only the
; vacated tail is touched, so nothing that stays on screen ever flickers.
; Preserves D,E; clobbers A,BC,HL.
HNDBLK: LD      A,(V_NCNT)
        CP      C
        RET     NC              ; grew or held: the redraw covers it
        PUSH    DE
        LD      B,A             ; B = cards now
        LD      A,C
        SUB     B               ; cards that went away...
        ADD     A,A             ; ...at 2 cols each
        LD      C,A
        LD      A,B
        OR      A
        JR      Z,HNB0
        ADD     A,A             ; the new art ends at col E + 2*count,
        INC     A               ; so start one col past it
        ADD     A,E
        LD      E,A
        JR      HNB1
HNB0:   INC     C               ; nothing redrawn: take that last col too
HNB1:   PUSH    BC
        CALL    CRDPOS          ; HL = screen address of row D, col E
        POP     BC
        LD      B,17            ; a card is 17 lines tall
        LD      D,0             ; back to felt
        CALL    FILLRC
        POP     DE
        RET

; SEATBP: D,E = bet row,col of seat (V_SEAT). Clobbers A,HL.
SEATBP: LD      A,(V_SEAT)
        LD      HL,SEATBR
        CALL    TBLK
        LD      D,A
        LD      A,(V_SEAT)
        LD      HL,SEATBC
        CALL    TBLK
        LD      E,A
        RET

; TBLK: A = table(HL)[A]. Preserves DE (callers fill D and E from
; consecutive lookups).
TBLK:   PUSH    DE
        LD      E,A
        LD      D,0
        ADD     HL,DE
        LD      A,(HL)
        POP     DE
        RET

; ----------------------------------------------------------------------
; PURSE: row 13 -- your purse and bet (or the viewing banner), and the
; move clock at the right edge.
PURSE:  LD      HL,GOVIEW
        CALL    RXGETB
        OR      A
        JR      Z,PUR1
        LD      HL,TVIEW
        LD      DE,13*256+0
        LD      C,XWONF
        LD      B,22
        CALL    TXTN
        JR      PURT
PUR1:   LD      HL,TPURSE
        LD      DE,13*256+0
        LD      C,XWONF
        CALL    TXTAT
        LD      HL,GOPLYRS+PLPURSE
        CALL    RXGETW
        EX      DE,HL
        CALL    U16STR
        LD      HL,LINBUF
        LD      DE,13*256+6
        LD      C,XWONF
        LD      B,5
        CALL    TXTN
        LD      HL,TBET
        LD      DE,13*256+12
        LD      C,XWONF
        CALL    TXTAT
        LD      HL,GOPLYRS+PLBET
        CALL    RXGETW
        EX      DE,HL
        CALL    U16STR
        LD      HL,LINBUF
        LD      DE,13*256+16
        LD      C,XWONF
        LD      B,5
        CALL    TXTN
PURT:   LD      HL,GOPOT        ; the pot, right of your purse and bet:
        CALL    RXGETW          ; the board owns the middle of the table
        EX      DE,HL           ; now, and cols 22-30 stay clear here even
        CALL    U16STR          ; under the VIEWING banner (cols 0-21)
        LD      HL,TPOT
        LD      DE,13*256+22
        LD      C,XWONF
        CALL    TXTAT
        LD      HL,LINBUF
        LD      DE,13*256+26
        LD      C,XWONF
        LD      B,5
        CALL    TXTN
        LD      A,(V_ACT)       ; the move clock
        INC     A
        JR      Z,PURT0         ; nobody active
        LD      HL,GOMVTIM
        CALL    RXGETB
        LD      L,A
        LD      H,0
        CALL    U16STR
        LD      HL,LINBUF
        LD      DE,13*256+37
        LD      C,XRONF
        LD      B,2
        JP      TXTN
PURT0:  LD      HL,TNUL
        LD      DE,13*256+37
        LD      C,XWONF
        LD      B,2
        JP      TXTN

; ----------------------------------------------------------------------
; BAR: row 14, the white strip: your move menu when it is your turn,
; otherwise the last-result banner.
BAR:    LD      HL,NORMEM+14*240
        LD      B,6
        LD      C,BYTEPL
        LD      D,0FFH
        CALL    FILLRC
        LD      A,(V_ACT)
        OR      A
        JP      NZ,BARLR        ; not you (or nobody)
        LD      HL,GOVIEW
        CALL    RXGETB
        OR      A
        JP      NZ,BARLR
        LD      HL,GOMVCNT
        CALL    RXGETB
        OR      A               ; RXGETB's LD A,(DE) leaves flags alone
        JP      Z,BARLR
        CP      6               ; the wire says at most 5, but this indexes
        JR      C,BARMC         ; a table and bounds a loop: do not trust it
        LD      A,5
BARMC:  LD      (V_CNT),A       ; menu: "1 NAME 2 NAME ..."
        LD      HL,MVLEN-1      ; name width, scaled to the move count
        LD      E,A
        LD      D,0
        ADD     HL,DE
        LD      A,(HL)
        LD      (V_MVL),A
        XOR     A
        LD      (V_TMP2),A
        LD      (BARCOL),A
BARM:   LD      A,(V_TMP2)
        LD      HL,V_CNT
        CP      (HL)
        RET     NC
        ADD     A,'1'           ; the digit
        LD      (HEXBUF),A
        XOR     A
        LD      (HEXBUF+1),A
        LD      A,(V_TMP2)      ; the name: GOMOVES + n*13 + MVNAME
        LD      L,A
        LD      H,0
        LD      E,A
        LD      D,H
        ADD     HL,HL
        ADD     HL,DE           ; *3
        ADD     HL,HL
        ADD     HL,HL           ; *12
        ADD     HL,DE           ; *13
        LD      DE,GOMOVES+MVNAME
        ADD     HL,DE
        LD      DE,LINBUF
        LD      B,10
        CALL    RXSTRN
        LD      A,(V_MVL)
        CALL    MVCOMP
        LD      A,(BARCOL)      ; digit
        LD      E,A
        LD      D,14
        LD      HL,HEXBUF
        LD      C,XRONW
        CALL    TXTAT
        LD      A,(BARCOL)      ; name, in its fixed field
        ADD     A,2
        LD      E,A
        LD      D,14
        LD      HL,LINBUF
        LD      C,XKONW
        LD      A,(V_MVL)
        LD      B,A
        CALL    TXTN
        LD      A,(V_MVL)       ; advance: digit + space + name + space
        ADD     A,3
        LD      HL,BARCOL
        ADD     A,(HL)
        LD      (HL),A
        LD      A,(V_TMP2)
        INC     A
        LD      (V_TMP2),A
        JR      BARM
; Not your turn. The server leaves lastResult holding the PREVIOUS hand's
; winner for the whole next hand, so showing it whenever the menu is down
; parks a stale banner on screen all hand long. Show it only between
; hands (round 0) and at the showdown; during a live hand, say whose
; turn it is.
BARLR:  LD      HL,GOROUND
        CALL    RXGETB
        OR      A
        JR      Z,BARRES        ; between hands: the result stands
        CP      5
        JR      NC,BARRES       ; showdown: the result is the news
        LD      A,(V_ACT)
        INC     A               ; FFH = nobody: leave the bar blank
        RET     Z
        LD      HL,TWAITON
        LD      DE,14*256+1
        LD      C,XKONW
        CALL    TXTAT
        LD      A,(V_ACT)       ; the active player's name
        LD      L,A
        LD      H,0
        LD      E,A
        LD      D,H
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL           ; *32
        ADD     HL,DE           ; *33
        LD      DE,GOPLYRS
        ADD     HL,DE
        LD      DE,LINBUF
        LD      B,9
        CALL    RXSTRN
        LD      HL,LINBUF
        LD      DE,14*256+12
        LD      C,XKONW
        LD      B,9
        JP      TXTN
BARRES: LD      HL,GOLASTR      ; the last-result banner
        LD      DE,LINBUF
        LD      B,39
        CALL    RXSTRN
        LD      HL,LINBUF
        LD      DE,14*256+1
        LD      C,XKONW
        LD      B,39
        JP      TXTN

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

HELPTX: DB      13,"HOW TO PLAY",0
        DB      0,"",0
        DB      1,"EACH PLAYER GETS TWO HOLE CARDS.",0
        DB      1,"FIVE SHARED CARDS ARE DEALT IN",0
        DB      1,"THE MIDDLE - THREE, THEN ONE,",0
        DB      1,"THEN ONE - WITH BETTING AFTER",0
        DB      1,"EACH. THE BEST FIVE CARD HAND",0
        DB      1,"TAKES THE POT.",0
        DB      0,"",0
        DB      1,"KEYPAD 1-5 CHOOSES A MOVE",0
        DB      1,"0 POLLS NOW    CE LEAVES",0
        DB      1,"STICK PICKS    TRIGGER JOINS",0
        DB      1,". SHOWS THIS SCREEN",0
        DB      0,"",0
        DB      1,"TH.CARR-DESIGNS.COM",0
        DB      0FFH

; MVCOMP: squeeze the move name in LINBUF into A cells.
;
; 5 Card Stud laid the menu out at whatever width the names happened to
; be, which was fine for its two or three moves. Hold'em routinely offers
; four or five, and the server's labels run to nine characters ("Raise
; 200", "All-in 10" -- capped by trimToWord in its util.go), so five of
; them want 65 of the 40 columns this row has.
;
; So squeeze, the way the C clients' compactMoveName() does: if the name
; has a space, keep its first letter and everything after that space
; ("Call 100" -> "C100"); otherwise drop any '-' ("All-in" -> "ALLIN").
; Every label the server actually emits lands inside 5 cells that way, so
; nothing is truncated even at the tightest width. Clobbers everything.
MVCOMP: LD      B,A             ; the budget
        LD      HL,LINBUF
        CALL    STRLEN
        CP      B
        RET     C
        RET     Z               ; it already fits: leave it in full
        LD      HL,LINBUF
MVC1:   LD      A,(HL)
        OR      A
        JR      Z,MVC3          ; no space: fall back to dropping '-'
        CP      ' '
        JR      Z,MVC2
        INC     HL
        JR      MVC1
MVC2:   INC     HL              ; the amount, after the space
        LD      DE,LINBUF+1     ; kept behind LINBUF[0], the first letter
MVC2A:  LD      A,(HL)
        LD      (DE),A
        OR      A
        RET     Z
        INC     HL
        INC     DE
        JR      MVC2A
MVC3:   LD      HL,LINBUF
        LD      DE,LINBUF
MVC3A:  LD      A,(HL)
        INC     HL
        CP      '-'
        JR      Z,MVC3A
        LD      (DE),A
        INC     DE
        OR      A
        JR      NZ,MVC3A
        RET

; Move-name width by move count, 1-5. Each entry costs the digit, a space,
; the name and a trailing space, so the strides are 13/13/13/10/8 -- five
; moves fill the 40-column row exactly and four leave it flush.
MVLEN:  DB      10,10,10,7,5

; STRLEN: A = length of the string at HL. Clobbers HL.
STRLEN: PUSH    BC
        LD      B,0
STRL1:  LD      A,(HL)
        OR      A
        JR      Z,STRL2
        INC     HL
        INC     B
        JR      STRL1
STRL2:  LD      A,B
        POP     BC
        RET

; ----------------------------------------------------------------------
; Seat geometry: master seats 0-7 (see the header comment).
; A 2-card hand is 5 cols where a 5-card one was 11, so the hand columns
; are re-anchored: left seats stay put, the two centre seats centre on
; px 78 (the community board's own centre), and the right seats align to
; the right edge of their name field instead of trailing off to its left.
SEATNC: DB      14,0,0,0,15,29,31,29    ; name col (31+9 is the screen edge)
SEATNR: DB      12,12,5,1,1,1,5,12      ; name row
SEATHC: DB      17,0,0,0,17,33,35,33    ; hand col
SEATHR: DB      9,9,6,2,2,2,6,9         ; hand row
; The top seats' bets move off row 1 and down onto their own hand row.
; Row 1 cannot hold three lots of name + chip + amount (3 x 14 = 42 cols in
; 40): inherited from 5 Card Stud, seat 4's amount ran through seat 5's
; chip and into its name. That only showed there when two particular seats
; both had live bets, but in Hold'em every seat in the hand carries one on
; every street, so it would paint over the table constantly. Seat 1's
; amount likewise clipped the first cell of your own name on row 12.
SEATBC: DB      23,9,11,6,12,28,24,24   ; bet chip col (amount at +1)
SEATBR: DB      13,12,5,2,2,2,5,12      ; bet row

; playerCountIndex: which masters serve 2..8 players (Lynx vars.c,
; verbatim). The requesting player is always index 0 = master seat 0.
PCIDX:  DB      0,4,0,0,0,0,0,0
        DB      0,2,6,0,0,0,0,0
        DB      0,2,4,6,0,0,0,0
        DB      0,2,3,5,6,0,0,0
        DB      0,2,3,4,5,6,0,0
        DB      0,2,3,4,5,6,7,0
        DB      0,1,2,3,4,5,6,7

TCHOOS: DB      "CHOOSE A TABLE",0
TTEXAS: DB      "TEXAS",0
THOLDM: DB      "HOLDEM",0
TJOIN:  DB      "JOINING...",0
TPOT:   DB      "POT",0
TVIEW:  DB      "VIEWING - CE TO LEAVE",0

; Street names, 8 space-padded bytes per round value so round*8 indexes
; straight in and TXTN's fixed-width field needs no terminator. Every cell
; is rewritten opaquely each poll, so "PRE-FLOP" -> "FLOP    " clears
; itself with no separate blanking pass.
STREETS: DB     "WAITING "      ; 0 waiting (and the clamp target)
        DB      "PRE-FLOP"      ; 1
        DB      "FLOP    "      ; 2
        DB      "TURN    "      ; 3
        DB      "RIVER   "      ; 4
        DB      "SHOWDOWN"      ; 5
TPURSE: DB      "PURSE",0
TWAITON: DB     "WAITING ON",0
TBET:   DB      "BET",0
TBANG:  DB      "!",0
TNUL:   DB      0
