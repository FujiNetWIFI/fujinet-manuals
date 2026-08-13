' hello.bas -- the smallest possible FujiNet program: ask the Fuji device
' for its WiFi status and report it. Demonstrates one complete mailbox
' transaction with no payload and no parameters.
'
' Build:  intybasic hello.bas hello.asm && as1600 -o hello -l hello.lst hello.asm
    GOTO main

    INCLUDE "fujinet.bas"

    CONST COL_WHITE = 7

main:
    MODE 0, 0, 0, 0, 0 : WAIT
    CLS
    PRINT AT 0 COLOR COL_WHITE, "FUJINET HELLO"
    PRINT AT 20, "WAITING FOR MAILBOX"

    GOSUB fn_wait_mailbox
    IF fn_ok = 0 THEN
        PRINT AT 40, "NO MAILBOX - IS THIS"
        PRINT AT 60, "A FUJINET CARTRIDGE?"
        GOTO halt
    END IF

    ' One transaction: device $70 (Fuji), command $FA (GET WIFI STATUS),
    ' no parameters, no payload. The one-byte reply lands in FN_RX.
    mb_dev = $70
    mb_cmd = $FA
    mb_nparam = 0
    #fn_txlen = 0
    GOSUB fn_transact

    IF fn_ok = 0 THEN
        PRINT AT 40, "TRANSACTION FAILED "
        PRINT AT 60, "FN ERR = "
        PRINT AT 69, <2>#mb_err
        GOTO halt
    END IF

    IF (PEEK(FN_RX) AND 255) = 3 THEN
        PRINT AT 40, "WIFI IS CONNECTED  "
    ELSE
        PRINT AT 40, "WIFI NOT CONNECTED "
    END IF

halt:
    WAIT
    GOTO halt
