;=====================================================================
; HELLO.ASM -- first contact: ask the FujiNet for its WiFi status and
; print the eight host slots.  Altair 8800 + 88-2SIO; ORG 0100h.
;=====================================================================
        ORG     0100h

START:  LD      SP,STACK
        CALL    PINIT
        CALL    PRINT
        DEFB    "FUJINET RS-232 HELLO",13,10,0

; GET_WIFISTATUS: device 70h, command FAh, no parameters
        LD      A,70h
        LD      C,0FAh
        LD      B,00h           ; descriptor 0: no parameters
        CALL    FBNEW
        CALL    FBCALL
        JR      C,NOREPLY
        JR      NZ,GOTNAK
        CALL    PRINT
        DEFB    "WIFI STATUS ",0
        LD      A,(HL)          ; 3 = connected, 6 = disconnected
        CALL    PRHEX
        CALL    CRLF

; READ_HOST_SLOTS: device 70h, command F4h -> 8 x 32 bytes
        LD      A,70h
        LD      C,0F4h
        LD      B,00h
        CALL    FBNEW
        CALL    FBCALL
        JR      C,NOREPLY
        JR      NZ,GOTNAK
        LD      C,'1'           ; slot number
HLOOP:  LD      A,C
        CALL    CONOUT
        CALL    PRINT
        DEFB    ": ",0
        PUSH    HL
        LD      B,32
        CALL    PRSTRN
        CALL    CRLF
        POP     HL
        LD      DE,32
        ADD     HL,DE
        INC     C
        LD      A,C
        CP      '9'
        JR      NZ,HLOOP
        JP      PEXIT

NOREPLY:CALL    PRINT
        DEFB    "NO REPLY FROM FUJINET",13,10,0
        JP      PEXIT
GOTNAK: CALL    PRINT
        DEFB    "FUJINET SAID NAK",13,10,0
        JP      PEXIT

        INCLUDE "../common/altair.inc"
        INCLUDE "../common/conio.inc"
        INCLUDE "../common/fujibus.inc"

        DEFS    128
STACK:
