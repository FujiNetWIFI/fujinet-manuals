***************************************************************
* WEATHER.ASM --- a JSON channel, end to end
*
* Opens an HTTPS channel, puts the JSON parser on it, and asks
* three questions of the document.  The adapter keeps the
* document; the CoCo only ever holds the answer.
*
*   lwasm --6809 --format=decb -I../fnlib -o WEATHER.BIN weather.asm
*   LOADM"WEATHER":EXEC
***************************************************************

ANSMAX  EQU     64

        ORG     $3F00

        INCLUDE "fn.inc"

START   JSR     CLRSCR
        LDX     #MSIGN
        JSR     PUTS

* --- open the channel -----------------------------------------
        LDX     #SPEC
        LDA     #OMHGET         HTTP GET
        LDB     #TRNONE
        JSR     NTOPEN
        LBNE    ENOOPN

* --- put the JSON parser on it --------------------------------
*       The mode rides in aux2.  fujinet-lib puts it in aux1,
*       which is why its network_json_parse() quietly selects
*       no parser at all on a current adapter.
        LDA     NTUNI
        STA     SPFRM+1
        LDX     #SPFRM
        LDY     #5
        LDB     NTUNI
        JSR     NTXACT
        LBNE    ENOPAR

* --- and parse what is waiting --------------------------------
        LDA     NTUNI
        STA     PAFRM+1
        LDX     #PAFRM
        LDY     #5
        LDB     NTUNI
        JSR     NTXACT
        LBNE    ENOPAR

* --- three questions ------------------------------------------
        LDX     #MTIME
        LDY     #QTIME
        JSR     ASK
        LDX     #MTEMP
        LDY     #QTEMP
        JSR     ASK
        LDX     #MWIND
        LDY     #QWIND
        JSR     ASK

        JSR     NTCLOS
        RTS

ENOOPN  LDX     #MENOOP
        BRA     FAIL
ENOPAR  LDX     #MENOPA
FAIL    PSHS    A
        JSR     PUTS
        PULS    A
        JSR     PUTDEC
        JSR     CRLF
        JSR     NTCLOS
        RTS

* --------------------------------------------------------------
* ASK --- print the label at X, then the answer to the query at Y
*
* A query sets the channel's contents to the value it selected.
* STATUS then says how many bytes that is, and READ takes them.
* --------------------------------------------------------------
ASK     PSHS    X,Y
        JSR     PUTS            the label
*       copy the query into the frame's 256-byte field
        LDX     #QYSTR
        LDY     #SZSPEC
ASKCLR  CLR     ,X+
        LEAY    -1,Y
        BNE     ASKCLR
        LDX     2,S             the query string
        LDY     #QYSTR
        JSR     SCOPY
        LDA     NTUNI
        STA     QYFRM+1
        LDX     #QYFRM
        LDY     #QYLEN
        LDB     NTUNI
        JSR     NTXACT
        BNE     ASKBAD
*       how much did it select?
        LDX     #STBUF
        JSR     NTSTAT
        BNE     ASKBAD
        LDD     STBUF
        BEQ     ASKBAD
        CMPD    #ANSMAX
        BLS     ASKRD
        LDD     #ANSMAX
ASKRD   PSHS    D
        LDX     #ANS
        TFR     D,Y
        JSR     NTREAD
        PULS    D
        LDX     #ANS
        JSR     PUTBUF
        JSR     CRLF
        PULS    X,Y,PC
ASKBAD  LDX     #MHUH
        JSR     PUTS
        PULS    X,Y,PC

MSIGN   FCC     "FUJINET WEATHER"
        FCB     CR,CR,0
MTIME   FCC     "TIME.. "
        FCB     0
MTEMP   FCC     "TEMP.. "
        FCB     0
MWIND   FCC     "WIND.. "
        FCB     0
MHUH    FCC     "?"
        FCB     CR,0
MENOOP  FCC     "CANNOT OPEN, ERROR "
        FCB     0
MENOPA  FCC     "CANNOT PARSE, ERROR "
        FCB     0

SPEC    FCC     "N:HTTPS://api.open-meteo.com/v1/forecast"
        FCC     "?latitude=39.10&longitude=-94.58"
        FCC     "&current=temperature_2m,wind_speed_10m"
        FCB     0
QTIME   FCC     "/current/time"
        FCB     0
QTEMP   FCC     "/current/temperature_2m"
        FCB     0
QWIND   FCC     "/current/wind_speed_10m"
        FCB     0

SPFRM   FCB     OPNET,0,NCSPARS,0,PMJSON
PAFRM   FCB     OPNET,0,NCPARSE,0,0
QYFRM   FCB     OPNET,0,NCQUERY,0,0
QYSTR   RMB     SZSPEC
QYLEN   EQU     *-QYFRM

        INCLUDE "cocoio.asm"
        INCLUDE "fnlow.asm"
        INCLUDE "fnnet.asm"

STBUF   RMB     4
ANS     RMB     ANSMAX

        END     START
