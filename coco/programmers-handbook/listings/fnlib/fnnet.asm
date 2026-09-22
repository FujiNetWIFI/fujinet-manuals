***************************************************************
* FNNET.ASM --- the five moves of the N: device in 6809
*
* Open, close, status, read, write.  Every network program in
* this book is these five in some order.  INCLUDE FN.INC and
* FNLOW.ASM before this file.
*
* One channel at a time: NTUNI remembers the unit that NTOPEN
* parsed out of the devicespec, and the other four use it.  To
* run two channels at once, keep your own unit bytes and call
* NTXACT, NTGERR and NTGRSP directly.
***************************************************************

* --------------------------------------------------------------
* NTOPEN --- instantiate a protocol and connect.
*
* Entry: X = the devicespec, NUL-terminated, under 256 bytes
*        A = the open mode  (OMREAD, OMWRITE, OMRW, OMDIR, ...)
*        B = the translation mode (TRNONE, TRCR, ...)
* Exit:  A = the error byte, Z set on success; NTUNI is set
* --------------------------------------------------------------
NTOPEN  STA     NTOFRM+3        aux1 is the open mode
        STB     NTOFRM+4        aux2 is the translation mode
        PSHS    X
        JSR     NTUNIT          B = the unit named in the spec
        STB     NTOFRM+1
        STB     NTUNI
        LDX     #NTOSPC         the spec field is a fixed 256
        LDY     #SZSPEC         bytes and must be NUL-padded
NTO1    CLR     ,X+
        LEAY    -1,Y
        BNE     NTO1
        PULS    X
        LDY     #NTOSPC
NTO2    LDA     ,X+
        STA     ,Y+
        BNE     NTO2
        LDX     #NTOFRM
        LDY     #NTOLEN
        LDB     NTUNI
        JMP     NTXACT

* --------------------------------------------------------------
* NTCLOS --- close the channel and destroy the protocol.
*
* Exit: A = the error byte, Z set on success
* --------------------------------------------------------------
NTCLOS  LDB     NTUNI
        STB     NTCFRM+1
        LDX     #NTCFRM
        LDY     #5
        JMP     NTXACT

* --------------------------------------------------------------
* NTSTAT --- how much is waiting, and are we still connected?
*
* Entry: X = a four-byte buffer
* Exit:  X+0,X+1 bytes waiting, high byte first
*        X+2     1 while the connection stands
*        X+3     the channel's own error byte
*        A = the error byte from the STATUS command itself
* --------------------------------------------------------------
NTSTAT  PSHS    X
        LDB     NTUNI
        STB     NTSFRM+1
        LDX     #NTSFRM
        LDY     #5
        JSR     NTXACT
        PULS    X
        LDB     NTUNI
        LDY     #4
        JMP     NTGRSP

* --------------------------------------------------------------
* NTREAD --- take bytes out of the channel.
*
* Ask for no more than NTSTAT said was waiting.  Asking for more
* makes the adapter pad the reply with zeros.
*
* Entry: X = buffer, Y = count
* Exit:  Z set when every byte arrived
* --------------------------------------------------------------
NTREAD  PSHS    X,Y
        LDB     NTUNI
        STB     NTRFRM+1
        TFR     Y,D             the count rides in the aux word,
        STD     NTRFRM+3        high byte first
        LDX     #NTRFRM
        LDY     #5
        LDB     NTUNI
        JSR     NTXACT
        PULS    X,Y
        LDB     NTUNI
        JMP     NTGRSP

* --------------------------------------------------------------
* NTWRIT --- put bytes into the channel.
*
* The header goes out first, then the payload as a second
* DriveWire write.  The adapter is already counting.
*
* Entry: X = buffer, Y = count
* Exit:  A = the error byte, Z set on success
* --------------------------------------------------------------
NTWRIT  PSHS    X,Y
        LDB     NTUNI
        STB     NTWFRM+1
        TFR     Y,D
        STD     NTWFRM+3
        LDX     #NTWFRM
        LDY     #5
        JSR     FNWAIT
        JSR     [DWWRITV]       the header
        PULS    X,Y
        JSR     [DWWRITV]       the payload
        LDB     NTUNI
        JMP     NTGERR

* --------------------------------------------------------------
* the frames, and the unit they all share
* --------------------------------------------------------------
NTOFRM  FCB     OPNET,0,NCOPEN,0,0
NTOSPC  RMB     SZSPEC
NTOLEN  EQU     *-NTOFRM
NTCFRM  FCB     OPNET,0,NCCLOSE,0,0
NTSFRM  FCB     OPNET,0,NCSTAT,0,0
NTRFRM  FCB     OPNET,0,NCREAD,0,0
NTWFRM  FCB     OPNET,0,NCWRITE,0,0
NTUNI   FCB     1
