' netcat.bas -- a line-mode network terminal in IntyBASIC. Opens a TCP
' connection through FujiNet's Network device, shows everything the far
' end sends on rows 0-9 of the screen, and lets you compose a line with
' the disc (the same letter-picker the games use for name entry) and send
' it with ENTER. Default target is tcpbin.com's echo service, so what you
' send comes straight back -- a self-test needing no server of your own.
'
' Controls:  disc up/down    cycle the character under the cursor
'            disc left/right move the cursor
'            ENTER           send the line (plus CR LF)
'            CLEAR           erase the line
'
' Build:  intybasic netcat.bas netcat.asm && as1600 -o netcat netcat.asm
    GOTO main

    INCLUDE "fujinet.bas"

    CONST COL_WHITE  = 7
    CONST COL_YELLOW = 6
    CONST TERM_CELLS = 200      ' rows 0-9 are the terminal
    CONST EDIT_ROW   = 220      ' row 11 is the composer
    CONST EDIT_LEN   = 18

' The devicespec, as ASCII DATA (20 bytes): "N:TCP://TCPBIN.COM:4242/"
lit_spec:
    DATA 78,58,84,67,80,58,47,47,84,67,80,66,73,78
    DATA 46,67,79,77,58,52,50,52,50,47
    CONST LEN_SPEC = 24

    DIM term_pos, nc_i, nc_c, nc_cr
    DIM ed_cur, ed_len, ed_i, ed_c
    DIM ed_buf(18)
    DIM inp_lock, #nc_color

' ---------------------------------------------------------------------------
' term_putc: draw ASCII nc_c at the terminal cursor, handling CR/LF and
' wrap-around. GROM cards 0-94 cover ASCII 32-126 directly in MODE 0.
' ---------------------------------------------------------------------------
term_putc: PROCEDURE
    IF nc_c = 13 THEN nc_cr = 1 : GOSUB term_newline : RETURN
    IF nc_c = 10 THEN
        ' collapse the LF of a CR LF pair; a bare LF is a newline
        IF nc_cr = 0 THEN GOSUB term_newline
        nc_cr = 0
        RETURN
    END IF
    nc_cr = 0
    IF nc_c < 32 OR nc_c > 126 THEN RETURN
    #BACKTAB(term_pos) = (nc_c - 32) * 8 + COL_WHITE
    term_pos = term_pos + 1
    IF term_pos >= TERM_CELLS THEN GOSUB term_home
END

term_newline: PROCEDURE
    term_pos = (term_pos / 20) * 20 + 20
    IF term_pos >= TERM_CELLS THEN GOSUB term_home
END

' Wrap back to the top and blank the first row -- a crude circular
' terminal, but 4K of scroll code has no place in an example program.
term_home: PROCEDURE
    term_pos = 0
    FOR nc_i = 0 TO 19
        #BACKTAB(nc_i) = 0
    NEXT nc_i
END

' ---------------------------------------------------------------------------
' ed_draw: paint the composer row: 18 character cells + a send arrow.
' ---------------------------------------------------------------------------
ed_draw: PROCEDURE
    FOR ed_i = 0 TO EDIT_LEN - 1
        #nc_color = COL_WHITE
        IF ed_i = ed_cur THEN #nc_color = COL_YELLOW
        ed_c = ed_buf(ed_i)
        IF ed_c = 32 THEN ed_c = 95   ' show blanks as underscores
        #BACKTAB(EDIT_ROW + ed_i) = (ed_c - 32) * 8 + #nc_color
    NEXT ed_i
END

main:
    MODE 0, 0, 0, 0, 0 : WAIT
    CLS
    PRINT AT EDIT_ROW COLOR COL_WHITE, "                    "
    PRINT AT 200 COLOR COL_YELLOW, "FUJINET NETCAT      "

    GOSUB fn_wait_mailbox
    IF fn_ok = 0 THEN
        PRINT AT 0 COLOR COL_WHITE, "NO CARTRIDGE MAILBOX"
        GOTO halt
    END IF

    ' Open the connection: devicespec into FN_TX, then OPEN in
    ' read-write mode with no translation (we handle CR LF ourselves).
    #fn_txlen = 0
    #fn_src = VARPTR lit_spec(0) : fn_len = LEN_SPEC : GOSUB fn_putstr
    mb_dev = NET_DEVICEID
    mb_cmd = NETCMD_OPEN
    mb_nparam = 2
    pm_i = 0 : pm_size = 1 : #pm_val = OPEN_MODE_RW : GOSUB fn_param
    pm_i = 1 : pm_size = 1 : #pm_val = OPEN_TRANS_NONE : GOSUB fn_param
    GOSUB fn_transact
    IF fn_ok = 0 THEN
        PRINT AT 0 COLOR COL_WHITE, "CONNECT FAILED      "
        GOTO halt
    END IF

    term_pos = 0
    nc_cr = 0
    ed_cur = 0
    inp_lock = 0
    FOR ed_i = 0 TO EDIT_LEN - 1
        ed_buf(ed_i) = 32
    NEXT ed_i
    GOSUB ed_draw

loop:
    WAIT

    ' --- receive: anything waiting? read up to 64 bytes and print it ---
    GOSUB net_status
    IF fn_ok THEN
        IF #net_avail > 0 THEN
            #net_readlen = #net_avail
            IF #net_readlen > 64 THEN #net_readlen = 64
            GOSUB net_read
            IF fn_ok THEN
                FOR nc_i = 0 TO #net_gotlen - 1
                    nc_c = PEEK(FN_RX + nc_i) AND 255
                    GOSUB term_putc
                NEXT nc_i
            END IF
        END IF
    END IF

    ' --- compose ---
    IF inp_lock > 0 THEN inp_lock = inp_lock - 1 : GOTO loop

    IF CONT1.RIGHT THEN
        ed_cur = ed_cur + 1
        IF ed_cur >= EDIT_LEN THEN ed_cur = 0
        inp_lock = 8 : GOSUB ed_draw
        GOTO loop
    END IF
    IF CONT1.LEFT THEN
        IF ed_cur = 0 THEN ed_cur = EDIT_LEN
        ed_cur = ed_cur - 1
        inp_lock = 8 : GOSUB ed_draw
        GOTO loop
    END IF
    IF CONT1.UP THEN
        ed_c = ed_buf(ed_cur) + 1
        IF ed_c > 126 THEN ed_c = 32
        ed_buf(ed_cur) = ed_c
        inp_lock = 6 : GOSUB ed_draw
        GOTO loop
    END IF
    IF CONT1.DOWN THEN
        ed_c = ed_buf(ed_cur) - 1
        IF ed_c < 32 THEN ed_c = 126
        ed_buf(ed_cur) = ed_c
        inp_lock = 6 : GOSUB ed_draw
        GOTO loop
    END IF

    IF CONT1.KEY = 10 THEN
        ' CLEAR: wipe the line
        FOR ed_i = 0 TO EDIT_LEN - 1
            ed_buf(ed_i) = 32
        NEXT ed_i
        ed_cur = 0
        inp_lock = 10 : GOSUB ed_draw
        GOTO loop
    END IF

    IF CONT1.KEY = 11 THEN
        ' ENTER: trim trailing blanks, stage line + CR LF in FN_TX, send.
        ed_len = EDIT_LEN
        WHILE ed_len > 0 AND ed_buf(ed_len - 1) = 32
            ed_len = ed_len - 1
        WEND
        FOR ed_i = 0 TO ed_len - 1
            POKE (FN_TX + ed_i), ed_buf(ed_i)
        NEXT ed_i
        POKE (FN_TX + ed_len), 13
        POKE (FN_TX + ed_len + 1), 10
        fn_len = ed_len + 2
        GOSUB net_write
        FOR ed_i = 0 TO EDIT_LEN - 1
            ed_buf(ed_i) = 32
        NEXT ed_i
        ed_cur = 0
        inp_lock = 10 : GOSUB ed_draw
    END IF
    GOTO loop

halt:
    WAIT
    GOTO halt
