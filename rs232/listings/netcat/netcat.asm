;=====================================================================
; NETCAT.ASM -- a dumb terminal to anywhere, through the FujiNet
;
; Asks for a devicespec (N:TCP://host:port/ or N:TELNET://host/),
; opens it on network unit 1, then shuttles bytes: keys typed on the
; terminal go out with WRITE, and whatever the far end sends comes
; back with STATUS + READ and is printed.  Ctrl-] hangs up.
;
; Hardware lives in ALTAIR.INC (88-2SIO: terminal on port A, FujiNet
; on port B); the packet layer is FUJIBUS.INC.
; Assemble:  z88dk-z80asm -b netcat.asm
;=====================================================================

        ORG     0100h

NET     EQU     71h             ; network unit 1 (N1:)
HANGUP  EQU     1Dh             ; Ctrl-]
CHUNK   EQU     256             ; most bytes asked for in one READ

START:  LD      SP,STACK
        CALL    PINIT
        CALL    PRINT
        DEFB    13,10,"NETCAT FOR THE RS-232 FUJINET",13,10,0

ASKURL: CALL    PRINT
        DEFB    13,10,"CONNECT TO (RETURN TO QUIT)?",13,10,"> ",0
        LD      HL,URL
        LD      B,250
        CALL    GETLN
        LD      A,B
        OR      A
        JP      Z,PEXIT

; OPEN ('O'): p0 = mode 12 (read/write), p1 = translation 0 (none),
; payload = the devicespec, NUL-terminated
        LD      A,NET
        LD      C,'O'
        LD      B,02h           ; descriptor 2: two u8s
        CALL    FBNEW
        LD      A,12
        CALL    FBBYTE
        XOR     A
        CALL    FBBYTE
        LD      HL,URL
        CALL    STRLEN          ; BC = length, then the NUL too
        INC     BC
        CALL    FBMEM
        LD      A,80            ; DNS + TLS can be slow: allow 20 s
        LD      (FBWAIT),A
        CALL    FBCALL
        LD      A,40
        LD      (FBWAIT),A
        JP      C,NOREPLY
        JR      Z,OPENED
        CALL    STATUS          ; NAK: STATUS says why
        CALL    PRINT
        DEFB    "OPEN FAILED, ERROR ",0
        LD      A,(ERR)
        LD      L,A
        LD      H,0
        CALL    PRDEC
        CALL    CRLF
        JP      ASKURL

OPENED: CALL    PRINT
        DEFB    "CONNECTED.  CTRL-] HANGS UP.",13,10,0

;---------------------------------------------------------------------
; The terminal loop
;---------------------------------------------------------------------
TLOOP:  CALL    CONST           ; a key?
        JR      Z,TL2
        CALL    CONIN
        CP      HANGUP
        JR      Z,BYE
; WRITE ('W'): p0 = byte count (u16), payload = the bytes
        LD      (KEY),A
        LD      A,NET
        LD      C,'W'
        LD      B,05h           ; descriptor 5: one u16
        CALL    FBNEW
        LD      HL,1
        CALL    FBWORD
        LD      A,(KEY)
        CALL    FBBYTE
        CALL    FBCALL
        JR      C,NOREPLY
TL2:    CALL    STATUS
        JR      C,NOREPLY
        LD      HL,(AVAIL)
        LD      A,H
        OR      L
        JR      NZ,TL3
        LD      A,(CONN)        ; nothing waiting: still connected?
        OR      A
        JR      NZ,TLOOP
        CALL    PRINT
        DEFB    13,10,"DISCONNECTED.",13,10,0
        JR      CLOSE
TL3:    LD      DE,CHUNK        ; ask for min(AVAIL, CHUNK)
        OR      A
        SBC     HL,DE
        ADD     HL,DE
        JR      C,TL4
        EX      DE,HL
; READ ('R'): p0 = byte count (u16) -> the bytes
TL4:    PUSH    HL
        LD      A,NET
        LD      C,'R'
        LD      B,05h
        CALL    FBNEW
        POP     HL
        CALL    FBWORD
        CALL    FBCALL
        JR      C,NOREPLY
        JR      NZ,TLOOP
TL5:    LD      A,B             ; print BC bytes from (HL)
        OR      C
        JR      Z,TLOOP
        LD      A,(HL)
        CALL    CONOUT
        INC     HL
        DEC     BC
        JR      TL5

BYE:    CALL    PRINT
        DEFB    13,10,"HANGING UP.",13,10,0
; CLOSE ('C'): no parameters
CLOSE:  LD      A,NET
        LD      C,'C'
        LD      B,00h
        CALL    FBNEW
        CALL    FBCALL
        JP      ASKURL

NOREPLY:CALL    PRINT
        DEFB    13,10,"NO REPLY FROM FUJINET.",13,10,0
        JP      ASKURL

;---------------------------------------------------------------------
; STATUS ('S') -> 4 bytes: bytes waiting (u16), connected, error
;---------------------------------------------------------------------
STATUS: LD      A,NET
        LD      C,'S'
        LD      B,00h
        CALL    FBNEW
        CALL    FBCALL
        RET     C
        LD      DE,AVAIL
        LD      BC,4
        LDIR
        OR      A
        RET

; STRLEN -- BC = length of the string at HL
STRLEN: PUSH    HL
        LD      BC,0
SL1:    LD      A,(HL)
        OR      A
        JR      Z,SL2
        INC     HL
        INC     BC
        JR      SL1
SL2:    POP     HL
        RET

        INCLUDE "../common/altair.inc"
        INCLUDE "../common/conio.inc"
        INCLUDE "../common/fujibus.inc"

AVAIL:  DEFW    0               ; the STATUS reply, as it arrives
CONN:   DEFB    0
ERR:    DEFB    0
KEY:    DEFB    0
URL:    DEFS    256
        DEFS    256
STACK:
