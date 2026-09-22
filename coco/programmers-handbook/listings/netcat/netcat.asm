***************************************************************
* NETCAT.ASM --- a wire, in both directions
*
* Opens a TCP channel, sends what you type, prints what comes
* back.  BREAK hangs up.  It is the smallest program that uses
* all five moves of the N: device, which is why every one of
* these handbooks ends with it.
*
*   lwasm --6809 --format=decb -I../fnlib -o NETCAT.BIN netcat.asm
*   LOADM"NETCAT":EXEC
*
* Somewhere to point it:
*   HOST? fujinet.online   PORT? 6502
***************************************************************

RXMAX   EQU     200             how much we take in one gulp

        ORG     $3F00

        INCLUDE "fn.inc"

START   JSR     CLRSCR
        LDX     #MSIGN
        JSR     PUTS

* --- ask where to go ------------------------------------------
        LDX     #MHOST
        JSR     PUTS
        LDX     #HOSTB
        JSR     GETLIN
        LBCS    QUIT
        LDX     #MPORT
        JSR     PUTS
        LDX     #PORTB
        JSR     GETLIN
        LBCS    QUIT

* --- build "N:TCP://host:port/" -------------------------------
        LDY     #SPEC
        LDX     #MPFX
        JSR     SCOPY
        LDX     #HOSTB
        JSR     SCOPY
        LDA     #':'
        STA     ,Y+
        LDX     #PORTB
        JSR     SCOPY

* --- open it ---------------------------------------------------
        LDX     #MOPEN
        JSR     PUTS
        LDX     #SPEC
        LDA     #OMRW           read and write
        LDB     #TRNONE         leave the bytes alone
        JSR     NTOPEN
        BNE     BADOPN
        LDX     #MREADY
        JSR     PUTS

* --- the loop --------------------------------------------------
LOOP    JSR     [POLCAT]        anything typed?
        TSTA
        BEQ     LRECV
        CMPA    #BREAK
        BEQ     BYE
        STA     KEYB
        LDX     #KEYB
        LDY     #1
        JSR     NTWRIT          one byte, up the wire
        BNE     BADIO

LRECV   LDX     #STBUF
        JSR     NTSTAT
        BNE     BADIO
        LDD     STBUF           bytes waiting, high byte first
        BEQ     LCONN
        CMPD    #RXMAX
        BLS     LREAD
        LDD     #RXMAX          take only what we can hold
LREAD   PSHS    D
        LDX     #RXBUF
        TFR     D,Y
        JSR     NTREAD
        PULS    D
        LDX     #RXBUF
        JSR     PUTBUF
        BRA     LOOP

LCONN   LDA     STBUF+2         still connected?
        BNE     LOOP
        LDX     #MDROP
        JSR     PUTS

BYE     JSR     NTCLOS
        LDX     #MBYE
        JSR     PUTS
QUIT    RTS

BADOPN  PSHS    A
        LDX     #MNOOPN
        JSR     PUTS
        BRA     BADX
BADIO   PSHS    A
        LDX     #MNOIO
        JSR     PUTS
BADX    PULS    A
        JSR     PUTDEC
        JSR     CRLF
        JSR     NTCLOS
        RTS

MSIGN   FCC     "FUJINET NETCAT"
        FCB     CR,0
MHOST   FCC     "HOST? "
        FCB     0
MPORT   FCC     "PORT? "
        FCB     0
MOPEN   FCC     "OPENING..."
        FCB     CR,0
MREADY  FCC     "CONNECTED. BREAK HANGS UP."
        FCB     CR,0
MDROP   FCB     CR
        FCC     "THE OTHER END CLOSED."
        FCB     CR,0
MBYE    FCC     "CHANNEL CLOSED."
        FCB     CR,0
MNOOPN  FCC     "COULD NOT OPEN, ERROR "
        FCB     0
MNOIO   FCB     CR
        FCC     "CHANNEL ERROR "
        FCB     0
MPFX    FCC     "N:TCP://"
        FCB     0

        INCLUDE "cocoio.asm"
        INCLUDE "fnlow.asm"
        INCLUDE "fnnet.asm"

KEYB    RMB     1
STBUF   RMB     4
HOSTB   RMB     64
PORTB   RMB     8
SPEC    RMB     SZSPEC
RXBUF   RMB     RXMAX

        END     START
