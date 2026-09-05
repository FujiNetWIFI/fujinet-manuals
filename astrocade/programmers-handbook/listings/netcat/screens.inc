; screens.inc -- the dial screen and the session loop.

; ----------------------------------------------------------------------
; DIAL: pick a devicespec and open it. Returns only once connected.
DIAL:   CALL    CLRSCR
        LD      HL,SBANNR
        LD      D,0
        LD      E,0
        LD      C,XAONK
        CALL    TXTAT
        LD      HL,SHELP1
        LD      D,2
        LD      E,0
        LD      C,XWONK
        CALL    TXTAT
        LD      HL,SHELP2
        LD      D,3
        LD      E,0
        LD      C,XWONK
        CALL    TXTAT
        LD      A,5
        LD      (EDTOPR),A
        LD      A,EDMAXL
        LD      (EDMAX),A
        LD      HL,SHDIAL
        LD      (EDHNT),HL
        CALL    EDIT
        JR      C,DDFLT         ; C: put the compiled-in default back
        CALL    EDLEN
        OR      A
        JR      Z,DIAL          ; nothing typed: ask again
        LD      HL,SCONN
        CALL    DMSG
        CALL    NOPEN
        RET     NC              ; connected
        CALL    NCLOSE          ; retire the half-open attempt
        LD      HL,SEFAIL
        CALL    DMSG
        CALL    INWAIT
        JR      DIAL
DDFLT:  CALL    SEEDU
        JR      DIAL

; DMSG: message at HL on the dial screen's message row.
DMSG:   LD      D,11
        LD      E,0
        LD      C,XAONK
        LD      B,TCOLS
        JP      TXTN

; SEEDU: copy the compiled-in default devicespec into EDBUF.
SEEDU:  LD      HL,UENDPT
        LD      DE,EDBUF
SEED1:  LD      A,(HL)
        LD      (DE),A
        OR      A
        RET     Z
        INC     HL
        INC     DE
        JR      SEED1

; ----------------------------------------------------------------------
; SESSN: pump the connection until it ends or the user hangs up.
SESSN:  CALL    TINIT
        CALL    SSTAT
        CALL    TCURON
SESS1:  CALL    NSTATUS
        JR      C,SLOST
        LD      A,(NCONN)
        OR      A
        JR      Z,SEOF
        LD      HL,(AVAIL)
        LD      A,H
        OR      L
        JR      Z,SESSI
        CALL    TCUROF
        CALL    NREAD
        JR      C,SLOST
        CALL    SREND
        CALL    TCURON
        JR      SESS2
; Nothing waiting: pause ~11 ms before asking again. Flat-out polling costs
; several hundred mailbox round trips a second to learn nothing, and this
; adds no delay at all to the path that matters -- once bytes ARE waiting the
; loop runs at full speed until the stream is drained.
SESSI:  CALL    DELAY10
SESS2:  CALL    SPOLL
        JR      NC,SESS1
        LD      HL,SHUNG        ; the user pressed C
        JR      SEND9

SEOF:   LD      HL,SDISC        ; the peer closed: NSDEVST would read
        JR      SEND9           ; END_OF_FILE here
SLOST:  LD      HL,SLOSTM       ; the transaction itself failed
SEND9:  PUSH    HL
        CALL    TCUROF
        CALL    NCLOSE
        POP     HL
        CALL    SSTATH
        CALL    INWAIT
        RET

; SSTAT: the session's status row.
SSTAT:  LD      HL,SHSESS
SSTATH: LD      D,STATROW
        LD      E,0
        LD      C,XKONA
        LD      B,TCOLS
        JP      TXTN

; SREND: put the whole reply through the terminal. The bytes are read where
; they lie, out of the cart's slice window; RXLEN was captured by NREAD.
SREND:  LD      HL,0            ; flat offset into the reply
SRD1:   LD      DE,(RXLEN)
        PUSH    HL
        OR      A
        SBC     HL,DE
        POP     HL
        RET     NC              ; consumed it all
        PUSH    HL
        CALL    RXGETB          ; preserves HL
        CALL    TPUTC           ; clobbers everything
        POP     HL
        INC     HL
        JR      SRD1

; ----------------------------------------------------------------------
; SPOLL: one pass of the keyboard. Carry set if the user hung up.
;
; Keys send immediately -- a BBS menu is one keypress, and making the user
; open a composer for every "M" would be miserable. The stick sends cursor
; keys, which is free: nothing else wants it while the overlay is closed.
SPOLL:  CALL    INPOLL
        OR      A
        RET     Z               ; nothing pressed; carry clear
        CP      EVCLR
        JR      Z,SPHANG
        CP      EVTRIG
        JR      Z,SPCOMP
        CP      EVEQ
        JR      Z,SPCR
        CP      EVCE
        JR      Z,SPBS
        CP      EVMR
        JR      Z,SPESC
        CP      EVMS
        JR      Z,SPETX
        CP      EVUP
        JR      Z,SPAU
        CP      EVDOWN
        JR      Z,SPAD
        CP      EVLEFT
        JR      Z,SPAL
        CP      EVRIGHT
        JR      Z,SPAR
        CALL    EVTOCH
        OR      A
        RET     Z               ; a key that types nothing
        CALL    NWRIT1
        OR      A               ; a failed write is not a hangup: the next
        RET                     ; NSTATUS decides that

SPHANG: SCF
        RET
SPCR:   LD      HL,SCRLF
        JR      SPSTR
SPESC:  LD      A,27
        JR      SPBYT
SPETX:  LD      A,3
        JR      SPBYT
SPBS:   LD      A,8
SPBYT:  CALL    NWRIT1
        OR      A
        RET
SPAU:   LD      HL,SARRU
        JR      SPSTR
SPAD:   LD      HL,SARRD
        JR      SPSTR
SPAL:   LD      HL,SARRL
        JR      SPSTR
SPAR:   LD      HL,SARRR
SPSTR:  CALL    NWRSTR
        OR      A
        RET

; SPCOMP: the grid keyboard, over the bottom of the pane. The rows it
; covers come back from term.inc's shadow.
SPCOMP: CALL    TCUROF
        XOR     A
        LD      (EDBUF),A       ; each line starts empty
        LD      A,TSHTOP
        LD      (EDTOPR),A
        LD      A,EDMAXL
        LD      (EDMAX),A
        LD      HL,SHCOMP
        LD      (EDHNT),HL
        CALL    EDIT
        PUSH    AF              ; EDIT's carry, across the repaint
        CALL    TRSHAD
        CALL    SSTAT
        CALL    TCURON
        POP     AF
        JR      C,SPC9          ; cancelled
        CALL    EDLEN
        OR      A
        JR      Z,SPC9
        LD      B,A
        LD      HL,EDBUF
        CALL    NWRITE
        LD      HL,SCRLF
        CALL    NWRSTR
SPC9:   OR      A               ; not a hangup either way
        RET

; ----------------------------------------------------------------------
SBANNR: DB      "FujiNet netcat",0
SHELP1: DB      "Stick and trigger pick characters;",0
SHELP2: DB      "the keypad types digits directly.",0
SHDIAL: DB      "TRIG pick  CE del  = connect  C dflt",0
SHCOMP: DB      "TRIG pick  CE del  = send     C esc",0
SHSESS: DB      " keys type    = enter    C hang up",0
SCONN:  DB      "Connecting...",0
SEFAIL: DB      "Connect failed - press a key",0
SDISC:  DB      "Remote host closed - press a key",0
SLOSTM: DB      "Connection lost - press a key",0
SHUNG:  DB      "Disconnected - press a key",0
SNOCART: DB     "No FujiNet cartridge",0

SCRLF:  DB      13,10,0
SARRU:  DB      27,"[A",0
SARRD:  DB      27,"[B",0
SARRR:  DB      27,"[C",0
SARRL:  DB      27,"[D",0
