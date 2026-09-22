***************************************************************
* COCOIO.ASM --- screen and keyboard, the plain way
*
* Color BASIC leaves two vectors in RAM for us.  POLCAT at
* $A000 returns the key that is down, or zero.  CHROUT at $A002
* prints the character in A.
*
* The ROM routines are documented as preserving everything but
* A, and mostly they do.  OUTCH saves the rest anyway: a
* corrupted X halfway through a string is a long evening.
***************************************************************

POLCAT  EQU     $A000           keyboard poll vector
CHROUT  EQU     $A002           console out vector

FF      EQU     12              CHROUT clears the screen on this
CR      EQU     13
BS      EQU     8
BREAK   EQU     3

* --------------------------------------------------------------
* OUTCH --- print A.  Everything else comes back untouched.
* --------------------------------------------------------------
OUTCH   PSHS    B,X,Y,U
        JSR     [CHROUT]
        PULS    B,X,Y,U,PC

* --------------------------------------------------------------
* CLRSCR --- clear the screen
* --------------------------------------------------------------
CLRSCR  LDA     #FF
        BRA     OUTCH

* --------------------------------------------------------------
* CRLF --- end the line
* --------------------------------------------------------------
CRLF    LDA     #CR
        BRA     OUTCH

* --------------------------------------------------------------
* PUTS --- print the NUL-terminated string at X.  X is kept.
* --------------------------------------------------------------
PUTS    PSHS    A,X
PUTS1   LDA     ,X+
        BEQ     PUTS9
        JSR     OUTCH
        BRA     PUTS1
PUTS9   PULS    A,X,PC

* --------------------------------------------------------------
* PUTBUF --- print D bytes starting at X, controls and all.
* --------------------------------------------------------------
PUTBUF  PSHS    D,X
        TSTA
        BNE     PUTB1
        TSTB
        BEQ     PUTB9
PUTB1   LDA     ,X+
        JSR     OUTCH
        SUBD    #1
        BNE     PUTB1
PUTB9   PULS    D,X,PC

* --------------------------------------------------------------
* PUTDEC --- print A as one to three decimal digits
* --------------------------------------------------------------
PUTDEC  PSHS    A,B
        CLRB
PD100   CMPA    #100
        BLO     PD100X
        SUBA    #100
        INCB
        BRA     PD100
PD100X  TSTB
        BEQ     PD10
        PSHS    A
        TFR     B,A
        ADDA    #'0'
        JSR     OUTCH
        PULS    A
PD10    CLRB
PD10L   CMPA    #10
        BLO     PD10X
        SUBA    #10
        INCB
        BRA     PD10L
PD10X   PSHS    A
        TFR     B,A
        ADDA    #'0'
        JSR     OUTCH
        PULS    A
        ADDA    #'0'
        JSR     OUTCH
        PULS    A,B,PC

* --------------------------------------------------------------
* PUTHEX --- print A as two hexadecimal digits
* --------------------------------------------------------------
PUTHEX  PSHS    A
        LSRA
        LSRA
        LSRA
        LSRA
        JSR     PUTNIB
        PULS    A
        PSHS    A
        ANDA    #$0F
        JSR     PUTNIB
        PULS    A,PC
PUTNIB  ANDA    #$0F
        CMPA    #9
        BLS     PUTN1
        ADDA    #7
PUTN1   ADDA    #'0'
        JMP     OUTCH

* --------------------------------------------------------------
* GETLIN --- read a line into the buffer at X, echoing as it
*            goes.  BACKSPACE rubs out.  ENTER ends it and a
*            terminating NUL is written.  BREAK gives an empty
*            line and leaves the carry set.
* --------------------------------------------------------------
GETLIN  PSHS    A,X,U
        LEAU    ,X
GL1     JSR     [POLCAT]
        TSTA
        BEQ     GL1
        CMPA    #CR
        BEQ     GL9
        CMPA    #BREAK
        BEQ     GL8
        CMPA    #BS
        BNE     GL2
        CMPU    1,S             anything left to rub out?
        BEQ     GL1
        LEAU    -1,U
        JSR     OUTCH
        BRA     GL1
GL2     CMPA    #' '
        BLO     GL1             ignore the other control keys
        STA     ,U+
        JSR     OUTCH
        BRA     GL1
GL8     LDU     1,S             BREAK --- give back nothing
        CLR     ,U
        JSR     CRLF
        PULS    A,X,U
        ORCC    #1              carry set: the user gave up
        RTS
GL9     CLR     ,U
        JSR     CRLF
        PULS    A,X,U
        ANDCC   #$FE            carry clear: a line was read
        RTS

* --------------------------------------------------------------
* SCOPY --- copy the NUL-terminated string at X to Y, leaving Y
*           on the terminator so the next copy runs straight on.
* --------------------------------------------------------------
SCOPY   PSHS    A,X
SCOPY1  LDA     ,X+
        BEQ     SCOPY9
        STA     ,Y+
        BRA     SCOPY1
SCOPY9  CLR     ,Y
        PULS    A,X,PC
