; net.inc -- the N: device, for a connection that is HELD open.
;
; Every other Astrocade FujiNet client is one-shot: OPEN an HTTP GET, poll
; STATUS until the body has settled, READ it once, and CLOSE at the start of
; the NEXT request. netcat opens once and then pumps STATUS/READ/WRITE for
; the life of the session, so three of the card ports' rules change:
;
;  * CLOSE goes where it reads. They deferred it because every transaction
;    repaints the whole reply window and their screens render straight out of
;    that window between polls. We consume each READ into the terminal
;    immediately, so nothing is left pointing at the window; CLOSE belongs at
;    hangup and on failure.
;  * There is no settle loop. They polled STATUS until two consecutive
;    readings of `avail` agreed, because an HTTP body arrives in pieces and
;    they wanted all of it. On a live stream that never terminates -- a
;    chatty server never produces two equal readings -- and it would add a
;    poll's latency to every echoed keystroke. We take whatever is there.
;  * NSCONN, not NSDEVST, is the loop condition (see fujinet.inc).
;
; Kept from them, because they are properties of the mailbox and not of the
; request: FNCOMMIT derives the next SEQ from the cart's own persisted
; ACKSEQ, and FNRXLL/FNRXLH belong to the most recent transaction, so the
; reply length is captured the instant the READ returns.
;
; All routines return carry SET on failure, clear on success.

; NCMD: begin a network-device transaction. E = command, L = nparam.
NCMD:   LD      A,NETDEV
        JP      FNBEGIN

; SLC0: every transaction makes the cart republish slice 0, so re-home
; state.inc's slice cache. Clobbers A.
SLC0:   XOR     A
        LD      (CURSLC),A
        RET

; ----------------------------------------------------------------------
; NOPEN: OPEN the devicespec in EDBUF for read/write, no translation.
NOPEN:  LD      E,NCOPEN
        LD      L,2
        CALL    NCMD
        LD      A,NMRDWR
        CALL    FNPARB
        LD      A,NTRNONE
        CALL    FNPARB
        CALL    BLDURL
        LD      B,8             ; a TCP connect plus telnet negotiation
        CALL    FNCOMMIT
        RET     C
        JR      NZ,NOBAD
        CALL    SLC0
        LD      A,(FNREPLY)
        CP      FCACK
        RET     Z               ; equal: carry already clear
NOBAD:  SCF
        RET

; NCLOSE: hang up. A close with nothing open earns a NAK; callers that are
; already failing ignore the result.
NCLOSE: LD      E,NCCLOSE
        LD      L,0
        CALL    NCMD
        LD      B,3             ; ~6 s
        CALL    FNCOMMIT
        JP      SLC0

; NSTATUS: one poll. On success AVAIL, NCONN and NDEVST are fresh.
NSTATUS: LD     E,NCSTAT
        LD      L,2
        CALL    NCMD
        XOR     A
        CALL    FNPARB
        XOR     A
        CALL    FNPARB
        LD      B,4
        CALL    FNCOMMIT
        RET     C
        JR      NZ,NSBAD
        LD      A,(FNREPLY)
        CP      FCACK
        JR      NZ,NSBAD
        LD      A,(FNRDATA+NSAVLO)
        LD      (AVAIL),A
        LD      A,(FNRDATA+NSAVHI)
        LD      (AVAIL+1),A
        LD      A,(FNRDATA+NSCONN)
        LD      (NCONN),A
        LD      A,(FNRDATA+NSDEVST)
        LD      (NDEVST),A
        CALL    SLC0
        XOR     A               ; clears carry
        RET
NSBAD:  SCF
        RET

; NREAD: READ min(AVAIL, RXMAX) bytes into the reply window, then capture
; the reply length -- the next transaction's would replace it -- and re-home
; the slice cursor. The bytes stay in the window; state.inc reads them there.
NREAD:  LD      HL,(AVAIL)
        LD      DE,RXMAX
        OR      A
        SBC     HL,DE
        JR      C,NRD1          ; avail < clamp: take avail
        LD      H,D             ; else take the clamp
        LD      L,E
        JR      NRD2
NRD1:   ADD     HL,DE           ; undo the compare
NRD2:   PUSH    HL
        LD      E,NCREAD
        LD      L,1
        CALL    NCMD
        LD      A,2             ; one 2-byte parameter: the length, LE
        CALL    FNTXBYT
        POP     HL
        PUSH    HL
        LD      A,L
        CALL    FNTXBYT
        POP     HL
        LD      A,H
        CALL    FNTXBYT
        LD      B,8
        CALL    FNCOMMIT
        RET     C
        JR      NZ,NRBAD
        LD      A,(FNREPLY)
        CP      FCACK
        JR      NZ,NRBAD
        LD      A,(FNRXLL)      ; capture NOW
        LD      (RXLEN),A
        LD      A,(FNRXLH)
        LD      (RXLEN+1),A
        JP      SLC0            ; XOR A inside: carry clear
NRBAD:  SCF
        RET

; NWRITE: send B bytes from (HL). B is at most TXMAX, so the length's high
; byte is always zero. The count rides twice -- once as the parameter, once
; as the payload the cart measures -- exactly as the Intellivision client
; does it. Clobbers everything.
NWRITE: LD      A,B
        OR      A
        RET     Z               ; nothing to send, carry clear
        PUSH    HL
        PUSH    BC
        LD      E,NCWRITE
        LD      L,1
        CALL    NCMD            ; clobbers HL and BC, hence the pushes
        LD      A,2             ; parameter size byte: a 2-byte length
        CALL    FNTXBYT
        POP     BC
        PUSH    BC
        LD      A,B
        CALL    FNTXBYT         ; length, low
        XOR     A
        CALL    FNTXBYT         ; length, high
        POP     BC
        POP     HL
NWR1:   LD      A,(HL)          ; FNTXBYT touches only A,D,E
        CALL    FNTXBYT
        INC     HL
        DJNZ    NWR1
        LD      B,4
        CALL    FNCOMMIT
        RET     C
        JR      NZ,NWBAD
        CALL    SLC0
        LD      A,(FNREPLY)
        CP      FCACK
        RET     Z
NWBAD:  SCF
        RET

; NWRIT1: send the single byte in A.
NWRIT1: LD      (TXONE),A
        LD      HL,TXONE
        LD      B,1
        JP      NWRITE

; NWRSTR: send the NUL-terminated string at HL.
NWRSTR: PUSH    HL
        LD      B,0
NWS1:   LD      A,(HL)
        OR      A
        JR      Z,NWS2
        INC     HL
        INC     B
        JR      NWS1
NWS2:   POP     HL
        JP      NWRITE

; ----------------------------------------------------------------------
; BLDURL: stream the devicespec in EDBUF into the TX stream a character at
; a time -- the card ports' way; it is never assembled anywhere else.
;
; A bare spec gets "N:" prepended, and a TELNET spec with no query of its
; own gets ?cols=40&rows=13 appended. NetworkProtocolTELNET::open() reads
; cols/rows off the query and only then offers NAWS, and its default
; terminal type is already "dumb" -- so this one string is what makes a BBS
; wrap to this screen instead of to 80 columns. A spec that brought its own
; query is left exactly alone, so ?term=ansi stays available.
BLDURL: LD      A,(EDBUF)
        CALL    UPCASE
        CP      'N'
        JR      Z,BURL1
        LD      A,'N'
        CALL    FNTXBYT
        LD      A,':'
        CALL    FNTXBYT
BURL1:  LD      HL,EDBUF
        CALL    FNTXSTR
        CALL    WANTSZ
        RET     NZ
        LD      HL,UQNAWS
        JP      FNTXSTR

; WANTSZ: Z when EDBUF is a TELNET spec carrying no '?' of its own.
; Clobbers A,B,C,D,E,H,L.
WANTSZ: LD      HL,EDBUF        ; any query at all disqualifies it
WSQ:    LD      A,(HL)
        OR      A
        JR      Z,WSQ9
        CP      '?'
        JR      Z,WSNO
        INC     HL
        JR      WSQ
WSQ9:   LD      HL,EDBUF        ; step over a leading "N:" or "Nn:"
        LD      A,(HL)
        CALL    UPCASE
        CP      'N'
        JR      NZ,WSCMP        ; no unit prefix: the scheme starts here
        INC     HL
        LD      A,(HL)
        CP      ':'
        JR      Z,WSCOL
        INC     HL              ; "Nn:" -- skip the unit digit
        LD      A,(HL)
        CP      ':'
        JR      NZ,WSNO
WSCOL:  INC     HL
WSCMP:  LD      DE,STELNET
        LD      B,6
WSC1:   LD      A,(DE)
        LD      C,A
        LD      A,(HL)
        CALL    UPCASE
        CP      C
        JR      NZ,WSNO
        INC     HL
        INC     DE
        DJNZ    WSC1
        XOR     A               ; Z: append the window size
        RET
WSNO:   OR      1               ; NZ: leave the spec alone
        RET

; UPCASE: fold a-z in A to A-Z. Clobbers A only.
UPCASE: CP      'a'
        RET     C
        CP      'z'+1
        RET     NC
        SUB     20H
        RET

STELNET: DB     "TELNET"
UQNAWS: DB      "?cols=",'0'+TCOLS/10,'0'+TCOLS-(TCOLS/10)*10
        DB      "&rows=",'0'+TROWS/10,'0'+TROWS-(TROWS/10)*10
        DB      0
