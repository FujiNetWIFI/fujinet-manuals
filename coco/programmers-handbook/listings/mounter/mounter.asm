***************************************************************
* MOUNTER.ASM --- host slots, a directory, and a disk in a drive
*
* The mounting sequence by hand: read the host slots, mount
* one, open its directory, read it, put a file into a device
* slot, mount it.  What CONFIG does, with the menus taken off.
*
*   lwasm --6809 --format=decb -I../fnlib -o MOUNTER.BIN mounter.asm
*   LOADM"MOUNTER":EXEC
***************************************************************

MAXENT  EQU     16              as many names as we will hold
NAMELEN EQU     37
NHOSTS  EQU     8
NDRIVES EQU     4               the CoCo has four, not eight

        ORG     $3F00

        INCLUDE "fn.inc"

START   JSR     CLRSCR
        LDX     #MSIGN
        JSR     PUTS

* --- the eight host slots -------------------------------------
        LDA     #FCRDHS
        JSR     FNCMD0
        LBNE    ENOHS
        LDX     #HOSTS
        LDY     #SZHOSTS        8 slots, 32 bytes each
        JSR     FNGRSP
        LBNE    ENOHS

        CLR     IDX
SHOW1   LDA     IDX
        INCA
        JSR     PUTDEC
        LDA     #' '
        JSR     OUTCH
        JSR     HSPTR           X = HOSTS + 32*IDX
        LDA     ,X
        BNE     SHOW2
        LDX     #MEMPTY         nothing in this slot
SHOW2   JSR     PUTS
        JSR     CRLF
        INC     IDX
        LDA     IDX
        CMPA    #NHOSTS
        BLO     SHOW1

* --- pick one -------------------------------------------------
        LDX     #MHOST
        LDA     #1
        LDB     #NHOSTS
        JSR     ASKDIG
        TSTA
        LBEQ    QUIT
        DECA
        STA     HS

* --- mount it and open its root -------------------------------
        LDA     #FCMNTHS
        LDB     HS
        JSR     FNCMD1          $E2 $F9 slot
        LBNE    ENOMH

*       the path field is one 256-byte block holding
*       "/" NUL "*.dsk" NUL --- path, then pattern
        LDX     #ODPATH
        LDY     #SZSPEC
ODCLR   CLR     ,X+
        LEAY    -1,Y
        BNE     ODCLR
        LDY     #ODPATH
        LDX     #MROOT
        JSR     SCOPY
        LEAY    1,Y             step over the NUL
        LDX     #MFILT
        JSR     SCOPY

        LDA     HS
        STA     ODFRM+2
        LDX     #ODFRM
        LDY     #ODLEN
        JSR     FNXACT
        LBNE    ENODIR

* --- read it --------------------------------------------------
        CLR     NENT
        LDU     #NAMES
DIR1    LDX     #RDFRM          $E2 $F6 maxlen aux2 --- two
        LDY     #4              parameters, so FNCMD1 will not do
        JSR     FNXACT
        BNE     DIR9
        LDX     #ENTRY
        LDY     #NAMELEN-1
        JSR     FNGRSP
        BNE     DIR9
        LDA     ENTRY
        CMPA    #$7F            two $7F bytes end the directory
        BEQ     DIR9
        LDA     NENT
        INCA
        JSR     PUTDEC
        LDA     #' '
        JSR     OUTCH
        LDX     #ENTRY
        JSR     PUTS
        JSR     CRLF
        LDX     #ENTRY
        LDY     #NAMELEN
CPY1    LDA     ,X+
        STA     ,U+
        BNE     CPY2
        LEAX    -1,X            keep filling with NULs
CPY2    LEAY    -1,Y
        BNE     CPY1
        INC     NENT
        LDA     NENT
        CMPA    #MAXENT
        BLO     DIR1

DIR9    LDA     #FCCLSDR
        JSR     FNCMD0
        LDA     NENT
        LBEQ    ENONE

* --- pick a file and a drive ----------------------------------
        LDX     #MFILE
        LDA     #1
        LDB     NENT
        CMPB    #9
        BLS     ASK1
        LDB     #9
ASK1    JSR     ASKDIG
        TSTA
        LBEQ    QUIT
        DECA
        STA     IDX

        LDX     #MDRIVE
        LDA     #1
        LDB     #NDRIVES
        JSR     ASKDIG
        TSTA
        LBEQ    QUIT
        DECA
        STA     DS

* --- write the name into the slot -----------------------------
*       mode 0 stores the name without opening anything
        LDX     #SDNAME
        LDY     #SZSPEC
SDCLR   CLR     ,X+
        LEAY    -1,Y
        BNE     SDCLR
        LDA     #NAMELEN
        LDB     IDX
        MUL
        LDX     #NAMES
        LEAX    D,X
        LDY     #SDNAME
        JSR     SCOPY

        LDA     DS
        STA     SDFRM+2
        LDA     HS
        STA     SDFRM+3
        CLR     SDFRM+4         mode 0
        LDX     #SDFRM
        LDY     #SDLEN
        JSR     FNXACT
        LBNE    ENOSET

* --- and mount it ---------------------------------------------
*       1 is read-only, 2 is read and write
        LDA     DS
        STA     MIFRM+2
        LDA     #2
        STA     MIFRM+3
        LDX     #MIFRM
        LDY     #4
        JSR     FNXACT
        LBNE    ENOMNT

        JSR     CRLF
        LDX     #MOK
        JSR     PUTS
        LDA     DS
        JSR     PUTDEC
        JSR     CRLF
QUIT    RTS

ENOHS   LDX     #MENOHS
        BRA     FAIL
ENOMH   LDX     #MENOMH
        BRA     FAIL
ENODIR  LDX     #MENODR
        BRA     FAIL
ENOSET  LDX     #MENOST
        BRA     FAIL
ENOMNT  LDX     #MENOMT
        BRA     FAIL
ENONE   LDX     #MENONE
        JSR     PUTS
        RTS
FAIL    PSHS    A
        JSR     PUTS
        PULS    A
        JSR     PUTDEC
        JMP     CRLF

* --------------------------------------------------------------
* ASKDIG --- prompt with the string at X and take one digit
*            between A and B.  Returns A = the digit, or zero
*            if BREAK was pressed.
* --------------------------------------------------------------
ASKDIG  PSHS    B,X
        STA     ADLO
        STB     ADHI
AD1     LDX     1,S
        JSR     PUTS
AD2     JSR     [POLCAT]
        TSTA
        BEQ     AD2
        CMPA    #BREAK
        BEQ     AD8
        JSR     OUTCH
        JSR     CRLF
        SUBA    #'0'
        CMPA    ADLO
        BLO     AD1
        CMPA    ADHI
        BHI     AD1
        PULS    B,X,PC
AD8     CLRA
        JSR     CRLF
        PULS    B,X,PC

* --------------------------------------------------------------
* HSPTR --- X = HOSTS + 32*IDX
* --------------------------------------------------------------
HSPTR   PSHS    D
        LDA     #32
        LDB     IDX
        MUL
        LDX     #HOSTS
        LEAX    D,X
        PULS    D,PC

MSIGN   FCC     "FUJINET MOUNTER"
        FCB     CR,CR,0
MEMPTY  FCC     "(EMPTY)"
        FCB     0
MHOST   FCB     CR
        FCC     "HOST? "
        FCB     0
MFILE   FCB     CR
        FCC     "FILE? "
        FCB     0
MDRIVE  FCC     "DRIVE (1-4)? "
        FCB     0
MROOT   FCC     "/"
        FCB     0
MFILT   FCC     "*.dsk"
        FCB     0
MOK     FCC     "READY ON DRIVE "
        FCB     0
MENOHS  FCC     "CANNOT READ HOST SLOTS, ERROR "
        FCB     0
MENOMH  FCC     "CANNOT MOUNT THAT HOST, ERROR "
        FCB     0
MENODR  FCC     "CANNOT OPEN DIRECTORY, ERROR "
        FCB     0
MENOST  FCC     "CANNOT SET THE SLOT, ERROR "
        FCB     0
MENOMT  FCC     "CANNOT MOUNT IT, ERROR "
        FCB     0
MENONE  FCC     "NOTHING THERE."
        FCB     CR,0

* --- the frames with payloads ---------------------------------
ODFRM   FCB     OPFUJI,FCOPNDR,0
ODPATH  RMB     SZSPEC
ODLEN   EQU     *-ODFRM
SDFRM   FCB     OPFUJI,FCSDVFP,0,0,0
SDNAME  RMB     SZSPEC
SDLEN   EQU     *-SDFRM
MIFRM   FCB     OPFUJI,FCMNTIM,0,0
RDFRM   FCB     OPFUJI,FCRDDIR,NAMELEN-1,0

        INCLUDE "cocoio.asm"
        INCLUDE "fnlow.asm"

ADLO    RMB     1
ADHI    RMB     1
IDX     RMB     1
HS      RMB     1
DS      RMB     1
NENT    RMB     1
ENTRY   RMB     NAMELEN
HOSTS   RMB     SZHOSTS
NAMES   RMB     MAXENT*NAMELEN

        END     START
