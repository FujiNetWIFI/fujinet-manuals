***************************************************************
* FCDEMO.ASM --- First Contact
*
* Asks the adapter who it is, and prints the answer.  Three
* commands' worth of code, and the whole shape of every other
* command is in it.
*
*   lwasm --6809 --format=decb -o FCDEMO.BIN fcdemo.asm
*   LOADM"FCDEMO":EXEC
***************************************************************

        ORG     $3F00

        INCLUDE "fn.inc"

START   JSR     CLRSCR
        LDX     #MSIGN
        JSR     PUTS

* --- ask for the extended adapter configuration ---------------
        LDA     #FCADCFX
        JSR     FNCMD0          $E2 $C4, then collect the verdict
        BNE     FAILED          A came back as something else

        LDX     #CFG
        LDY     #SZADCFX
        JSR     FNGRSP          240 bytes land in CFG
        BNE     FAILED

* --- and print the three fields worth having ------------------
        LDX     #MSSID
        JSR     PUTS
        LDX     #CFG+0          ssid[33]
        JSR     PUTS
        JSR     CRLF

        LDX     #MADDR
        JSR     PUTS
        LDX     #CFG+140        sLocalIP[16] --- already dotted
        JSR     PUTS
        JSR     CRLF

        LDX     #MFIRM
        JSR     PUTS
        LDX     #CFG+125        fn_version[15]
        JSR     PUTS
        JSR     CRLF
        RTS

FAILED  PSHS    A
        LDX     #MFAIL
        JSR     PUTS
        PULS    A
        JSR     PUTDEC
        JMP     CRLF

MSIGN   FCC     "FUJINET FIRST CONTACT"
        FCB     CR,0
MSSID   FCC     "NETWORK.. "
        FCB     0
MADDR   FCC     "ADDRESS.. "
        FCB     0
MFIRM   FCC     "FIRMWARE. "
        FCB     0
MFAIL   FCC     "NO ANSWER, ERROR "
        FCB     0

        INCLUDE "cocoio.asm"
        INCLUDE "fnlow.asm"

CFG     RMB     SZADCFX

        END     START
