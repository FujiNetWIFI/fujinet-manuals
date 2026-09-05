; url.inc -- building the devicespec for a request.
;
; The URL is streamed straight into the mailbox's TX byte stream a
; character at a time (o2/url.inc's way): it is never assembled in RAM.
; The cart counts the payload itself, so nothing here tracks a length; a
; whole /move request is ~90 bytes against the 320-byte TX ceiling.
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
BURL2:  CP      2
        JR      C,BURLST
        JR      Z,BURLMV
        LD      HL,ULEAVE
        CALL    FNTXSTR
        JR      BURLQ
BURLST: LD      HL,USTATE
        CALL    FNTXSTR
        JR      BURLQ
BURLMV: LD      HL,UMOVE
        CALL    FNTXSTR
        LD      A,(MOVBUF)      ; the move code's first 2 characters
        CALL    FNTXBYT
        LD      A,(MOVBUF+1)
        CALL    FNTXBYT
BURLQ:  LD      HL,UQTAB
        CALL    FNTXSTR
        LD      HL,TBLBUF
        CALL    FNTXSTR
        LD      HL,UQPLR
        CALL    FNTXSTR
        LD      HL,PLNBUF
        CALL    FNTXSTR
        LD      HL,UQBIN
        JP      FNTXSTR

UTABLS: DB      "tables?bin=1",0
USTATE: DB      "state",0
UMOVE:  DB      "move/",0
ULEAVE: DB      "leave",0
UQTAB:  DB      "?table=",0
UQPLR:  DB      "&player=",0
UQBIN:  DB      "&bin=1",0
