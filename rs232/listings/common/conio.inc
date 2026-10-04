;=====================================================================
; CONIO.INC -- terminal helpers built on CONIN/CONOUT
;
;   PRINT    print the NUL-terminated string that follows the CALL
;   PRSTR    print the NUL-terminated string at (HL); HL ends past NUL
;   PRSTRN   print at most B characters of the string at (HL)
;   CRLF     carriage return + line feed
;   SPACE    one space;  SPACES  B spaces
;   PRHEX    A as two hex digits
;   PRDEC    HL as an unsigned decimal number (no leading zeroes)
;   PRDECW   HL in decimal, right-aligned in a field of B characters
;   GETLN    read a line into (HL), at most B characters; BS/DEL rub
;            out, CR ends; on return the line is NUL-terminated and
;            B = its length (C is destroyed).  Ctrl-C leaves the
;            line empty.
;   GETKEY   CONIN with lower case folded to upper case
;   UCASE    fold the character in A to upper case
;
; All preserve BC, DE, HL except where a result is returned in them.
;=====================================================================

CR      EQU     0Dh
LF      EQU     0Ah
BS      EQU     08h
DEL     EQU     7Fh
CTRLC   EQU     03h

PRINT:  EX      (SP),HL         ; HL = the string after the CALL
        CALL    PRSTR
        EX      (SP),HL         ; return just past its NUL
        RET

PRSTR:  LD      A,(HL)
        INC     HL
        OR      A
        RET     Z
        CALL    CONOUT
        JR      PRSTR

PRSTRN: PUSH    BC
PRN1:   LD      A,B
        OR      A
        JR      Z,PRN2
        LD      A,(HL)
        OR      A
        JR      Z,PRN2
        CALL    CONOUT
        INC     HL
        DEC     B
        JR      PRN1
PRN2:   POP     BC
        RET

CRLF:   LD      A,CR
        CALL    CONOUT
        LD      A,LF
        JP      CONOUT

SPACE:  LD      A,' '
        JP      CONOUT

SPACES: PUSH    BC
SPC1:   LD      A,B
        OR      A
        JR      Z,SPC2
        CALL    SPACE
        DEC     B
        JR      SPC1
SPC2:   POP     BC
        RET

PRHEX:  PUSH    AF
        RRCA
        RRCA
        RRCA
        RRCA
        CALL    PRNIB
        POP     AF
PRNIB:  AND     0Fh
        ADD     A,90h           ; the classic DAA trick: 0-9 -> '0'-'9',
        DAA                     ;   A-F -> 'A'-'F'
        ADC     A,40h
        DAA
        JP      CONOUT

; PRDEC / PRDECW share the conversion: digits are built backwards in
; DECBUF, then printed (PRDECW pads on the left first).
PRDEC:  PUSH    BC
        LD      B,0
        CALL    PRDECW
        POP     BC
        RET
PRDECW: PUSH    BC
        PUSH    DE
        PUSH    HL
        LD      DE,DECBUF+5
        XOR     A
        LD      (DE),A          ; NUL terminator
        LD      C,0             ; C = digits made
PRD1:   PUSH    BC
        LD      C,10
        CALL    DIV8            ; HL = HL / 10, A = remainder
        POP     BC
        ADD     A,'0'
        DEC     DE
        LD      (DE),A
        INC     C
        LD      A,H
        OR      L
        JR      NZ,PRD1
        LD      A,B             ; pad: B - C spaces, if positive
        SUB     C
        JR      C,PRD2
        JR      Z,PRD2
        LD      B,A
        CALL    SPACES
PRD2:   EX      DE,HL
        CALL    PRSTR
        POP     HL
        POP     DE
        POP     BC
        RET

; DIV8 -- HL = HL / C, A = remainder (C non-zero, 8-bit)
DIV8:   PUSH    BC
        XOR     A
        LD      B,16
DV1:    ADD     HL,HL
        RLA
        CP      C
        JR      C,DV2
        SUB     C
        INC     L
DV2:    DJNZ    DV1
        POP     BC
        RET

UCASE:  CP      'a'
        RET     C
        CP      'z'+1
        RET     NC
        SUB     20h
        RET

GETKEY: CALL    CONIN
        JR      UCASE

GETLN:  PUSH    DE
        PUSH    HL
        LD      D,B             ; D = limit
        LD      E,0             ; E = count
GLN1:   CALL    CONIN
        CP      CR
        JR      Z,GLN4
        CP      CTRLC
        JR      Z,GLN5
        CP      BS
        JR      Z,GLN2
        CP      DEL
        JR      Z,GLN2
        CP      ' '
        JR      C,GLN1           ; ignore other control characters
        LD      C,A
        LD      A,E
        CP      D
        JR      NC,GLN1          ; full: ignore
        LD      A,C
        LD      (HL),A
        INC     HL
        INC     E
        CALL    CONOUT          ; echo
        JR      GLN1
GLN2:   LD      A,E             ; rub out the last character
        OR      A
        JR      Z,GLN1
        DEC     HL
        DEC     E
        CALL    PRINT
        DEFB    BS,' ',BS,0
        JR      GLN1
GLN5:   POP     HL              ; Ctrl-C: empty line
        PUSH    HL
        LD      E,0
GLN4:   LD      (HL),0
        LD      B,E
        CALL    CRLF
        POP     HL
        POP     DE
        RET

DECBUF: DEFS    6
