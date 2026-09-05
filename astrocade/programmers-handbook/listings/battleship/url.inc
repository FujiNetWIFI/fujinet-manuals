; url.inc -- building the devicespec for a request.
;
; The URL is streamed straight into the mailbox's TX byte stream a
; character at a time (the card-game ports' way): it is never assembled
; in RAM. The cart counts the payload itself, so nothing here tracks a
; length; the worst case (/place with five 3-digit positions) is ~95
; bytes against the 320-byte TX ceiling.
;
; The staged move is raw bytes, not text -- MYSHP[5] and ATKPOS -- and
; BYTDEC turns each into decimal digits on the way out, so /place needs
; no 20-character move buffer.
;
; TBLBUF and PLNBUF are NUL-terminated copies of fixed-width wire fields
; -- pushed up to the NUL, never through it (padding in the middle of a
; URL corrupts the request on the wire).

; BLDURL: stream the devicespec for request (V_URL).
BLDURL: LD      A,(UENDPT)      ; "N:" unless the endpoint carries its own
        CP      'N'
        JR      Z,BURL1
        LD      A,'N'
        CALL    FNTXBYT
        LD      A,':'
        CALL    FNTXBYT
BURL1:  LD      HL,UENDPT
        CALL    FNTXSTR
        LD      A,(V_URL)
        OR      A
        JR      NZ,BURL2
        LD      HL,UTABLS       ; tables: no table, no player
        JP      FNTXSTR
BURL2:  CP      1
        JR      NZ,BURL3
        LD      HL,USTATE
        CALL    FNTXSTR
        JR      BURLQ
BURL3:  CP      2
        JR      NZ,BURL4
        LD      HL,UREADY       ; bare /ready toggles, matching the
        CALL    FNTXSTR         ; Intellivision client
        JR      BURLQ
BURL4:  CP      3
        JR      NZ,BURL5
        LD      HL,UPLACE       ; place/P,P,P,P,P
        CALL    FNTXSTR
        LD      HL,MYSHP
        LD      B,5
BURLP:  LD      A,(HL)
        PUSH    HL
        PUSH    BC
        CALL    BYTDEC
        POP     BC
        POP     HL
        INC     HL
        LD      A,B
        DEC     A
        JR      Z,BURLQ         ; no comma after the last
        LD      A,','
        CALL    FNTXBYT         ; clobbers only A,D,E
        DJNZ    BURLP
BURL5:  CP      4
        JR      NZ,BURL6
        LD      HL,UATTCK       ; attack/P
        CALL    FNTXSTR
        LD      A,(ATKPOS)
        CALL    BYTDEC
        JR      BURLQ
BURL6:  LD      HL,ULEAVE
        CALL    FNTXSTR
BURLQ:  LD      HL,UQTAB
        CALL    FNTXSTR
        LD      HL,TBLBUF
        CALL    FNTXSTR
        LD      HL,UQPLR
        CALL    FNTXSTR
        LD      HL,PLNBUF
        CALL    FNTXSTR
        LD      HL,UQBIN2
        JP      FNTXSTR

; BYTDEC: stream A as 1-3 decimal digits, no leading zeros. Rides on
; U16STR (which builds in LINBUF); safe mid-transaction -- it touches
; only RAM and registers, never the mailbox pages.
BYTDEC: LD      L,A
        LD      H,0
        CALL    U16STR
        LD      HL,LINBUF
        JP      FNTXSTR

UTABLS: DB      "tables?bin=1",0
USTATE: DB      "state",0
UREADY: DB      "ready",0
UPLACE: DB      "place/",0
UATTCK: DB      "attack/",0
ULEAVE: DB      "leave",0
UQTAB:  DB      "?table=",0
UQPLR:  DB      "&player=",0
UQBIN2: DB      "&bin=1&v=2",0  ; v=2: winner + ship reveal at gameover
