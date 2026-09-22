***************************************************************
* FNLOW.ASM --- the low road to FujiNet from 6809 assembly
*
* Nine subroutines.  Everything else in this book is built on
* them.  INCLUDE FN.INC before this file.
*
* The Color Computer talks to FujiNet through the two DriveWire
* vectors Disk BASIC leaves at $D93F and $D941.  Both take the
* buffer in X and the count in Y.  DWRead returns with Z set
* when every byte arrived and the carry set on a framing error;
* it clobbers Y (it hands back a checksum) and the
* accumulators, but preserves X.  DWWrite consumes both X and Y
* and preserves everything else.  These routines put the
* registers back where you left them unless the header says
* otherwise.
***************************************************************

* --------------------------------------------------------------
* FNWAIT --- block until the adapter answers.
*
* Writes the two-byte frame $E2 $00 and waits for the single
* byte $01 to come back.  If nothing comes back it simply asks
* again.  Every command in this library begins here, because
* the adapter is free to be busy and the bus has no other way
* of saying so.
*
* Entry: nothing.   Exit: all registers preserved.
* --------------------------------------------------------------
FNWAIT  PSHS    D,X,Y
FNWAIT1 LDX     #FNRDYF
        LDY     #2
        JSR     [DWWRITV]
        LDX     #FNSCRP
        LDY     #1
        JSR     [DWREADV]
        BNE     FNWAIT1         nothing yet --- ask again
        PULS    D,X,Y,PC

* --------------------------------------------------------------
* FNXACT --- send a FUJI request and collect the verdict.
*
* Entry: X = the request frame, whose first byte must be $E2
*        Y = the length of that frame
* Exit:  A = the error byte, $01 on success
*        Z set when A is $01, so BNE branches on failure
*        X and Y are clobbered
* --------------------------------------------------------------
FNXACT  JSR     FNWAIT
        JSR     [DWWRITV]       X and Y are consumed here
*       fall into FNGERR

* --------------------------------------------------------------
* FNGERR --- ask the FUJI device how the last command went.
*
* Entry: nothing.
* Exit:  A = the error byte; Z set when it is $01; X, Y kept.
* --------------------------------------------------------------
FNGERR  PSHS    X,Y
        JSR     FNWAIT
        LDX     #FNERRF
        LDY     #2
        JSR     [DWWRITV]
        LDX     #FNSCRP
        LDY     #1
        JSR     [DWREADV]
        BNE     FNGE1           no answer at all
        LDA     FNSCRP
        BRA     FNGE2
FNGE1   LDA     #EGENERL        call silence a fatal error
FNGE2   PULS    X,Y
        CMPA    #ESUCC
        RTS

* --------------------------------------------------------------
* FNGRSP --- fetch the response the last command left waiting.
*
* The adapter does not push data at you.  A command that has
* something to say parks it, and you come back for it with this.
*
* Entry: X = where to put it
*        Y = how many bytes to take
* Exit:  Z set when every byte arrived; X preserved, Y clobbered
* --------------------------------------------------------------
FNGRSP  PSHS    X,Y
        JSR     FNWAIT
        LDX     #FNRSPF
        LDY     #2
        JSR     [DWWRITV]
        PULS    X,Y
        JMP     [DWREADV]

* --------------------------------------------------------------
* FNCMD0 --- issue a FUJI command that takes no parameters.
*
* Entry: A = the command byte
* Exit:  as FNXACT
* --------------------------------------------------------------
FNCMD0  STA     FNC0F+1
        LDX     #FNC0F
        LDY     #2
        BRA     FNXACT

* --------------------------------------------------------------
* FNCMD1 --- issue a FUJI command that takes one byte.
*
* Entry: A = the command byte, B = the parameter
* Exit:  as FNXACT
* --------------------------------------------------------------
FNCMD1  STA     FNC1F+1
        STB     FNC1F+2
        LDX     #FNC1F
        LDY     #3
        BRA     FNXACT

* --------------------------------------------------------------
* NTXACT --- send an N: request and collect the verdict.
*
* Entry: X = the request frame, whose first byte must be $E3
*            and whose second must be the unit
*        Y = the length of that frame
*        B = the unit again, for the error fetch
* Exit:  A = the error byte; Z set when it is $01
* --------------------------------------------------------------
NTXACT  JSR     FNWAIT
        JSR     [DWWRITV]
*       fall into NTGERR

* --------------------------------------------------------------
* NTGERR --- ask one N: unit how its last command went.
*
* Entry: B = the unit (1 to 255)
* Exit:  A = the error byte; Z set when it is $01; X, Y kept.
* --------------------------------------------------------------
NTGERR  PSHS    X,Y
        STB     NTERRF+1
        JSR     FNWAIT
        LDX     #NTERRF
        LDY     #5
        JSR     [DWWRITV]
        LDX     #FNSCRP
        LDY     #1
        JSR     [DWREADV]
        BNE     NTGE1
        LDA     FNSCRP
        BRA     NTGE2
NTGE1   LDA     #EGENERL
NTGE2   PULS    X,Y
        CMPA    #ESUCC
        RTS

* --------------------------------------------------------------
* NTGRSP --- fetch an N: unit's pending response.
*
* The length goes out in the frame as well as governing the
* read: the firmware pads the reply out to it.
*
* Entry: B = the unit, X = where to put it, Y = how many bytes
* Exit:  Z set when every byte arrived; X preserved
* --------------------------------------------------------------
NTGRSP  PSHS    X,Y
        STB     NTRSPF+1
        TFR     Y,D
        STD     NTRSPF+3
        JSR     FNWAIT
        LDX     #NTRSPF
        LDY     #5
        JSR     [DWWRITV]
        PULS    X,Y
        JMP     [DWREADV]

* --------------------------------------------------------------
* NTUNIT --- read the unit number out of a devicespec.
*
* "N:" is unit 1.  "N2:" is unit 2, and so on to "N8:".
*
* Entry: X = the devicespec
* Exit:  B = the unit; A and X clobbered
* --------------------------------------------------------------
NTUNIT  LDB     1,X             the character after the N
        CMPB    #':'
        BEQ     NTU1            plain "N:" --- unit 1
        SUBB    #'0'
        CMPB    #1
        BLO     NTU1            garbage --- use unit 1
        CMPB    #8
        BHI     NTU1
        RTS
NTU1    LDB     #1
        RTS

* --------------------------------------------------------------
* DWTIME --- read the adapter's clock the short way.
*
* OP_TIME is answered by the bus itself, so there is no command
* byte, no error byte and no response fetch: one byte out, six
* bytes back.
*
* Entry: X = a six-byte buffer
* Exit:  buffer holds year-1900, month, day, hour, minute,
*        second; Z set when all six arrived
* --------------------------------------------------------------
DWTIME  PSHS    X
        JSR     FNWAIT
        LDX     #DWTF
        LDY     #1
        JSR     [DWWRITV]
        PULS    X
        LDY     #6
        JMP     [DWREADV]

* --------------------------------------------------------------
* the frames these routines keep to themselves
* --------------------------------------------------------------
FNRDYF  FCB     OPFUJI,FNREADY
FNERRF  FCB     OPFUJI,FNERROR
FNRSPF  FCB     OPFUJI,FNRESP
FNC0F   FCB     OPFUJI,0
FNC1F   FCB     OPFUJI,0,0
NTERRF  FCB     OPNET,0,FNERROR,0,0
NTRSPF  FCB     OPNET,0,FNRESP,0,0
DWTF    FCB     OPTIME
FNSCRP  RMB     1
