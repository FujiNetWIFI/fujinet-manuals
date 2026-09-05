; url.inc -- building the devicespec for a request.
;
; The URL is streamed straight into the mailbox's TX byte stream a
; character at a time (the card-game ports' way): it is never assembled
; in RAM. The cart counts the payload itself, so nothing here tracks a
; length; the worst case (/score/14 with the query) is ~90 bytes against
; the 320-byte TX ceiling.
;
; The roll mask needs no conversion at all: KEEPBF is staged as the five
; ascii '0'/'1' bytes the wire wants ('1' = re-roll), NUL-terminated, so
; it streams through FNTXSTR verbatim. The score category is a raw byte
; that BYTDEC turns into decimal digits on the way out.
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
        LD      HL,UROLL        ; roll/MMMMM -- the staged mask verbatim
        CALL    FNTXSTR
        LD      HL,KEEPBF
        CALL    FNTXSTR
        JR      BURLQ
BURL5:  CP      4
        JR      NZ,BURL6
        LD      HL,USCORE       ; score/N
        CALL    FNTXSTR
        LD      A,(SCOREIX)
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
        LD      HL,UQBIN
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
UROLL:  DB      "roll/",0
USCORE: DB      "score/",0
ULEAVE: DB      "leave",0
UQTAB:  DB      "?table=",0
UQPLR:  DB      "&player=",0
UQBIN:  DB      "&bin=1",0
