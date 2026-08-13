' netcat.bas -- a line-mode network terminal in IntyBASIC. Type any N:
' devicespec on the on-screen keyboard (the same character grid FujiNet
' CONFIG uses for WiFi SSIDs), connect, and everything the far end sends
' scrolls up rows 0-9 of the screen. The action button opens the keyboard
' again to compose a line; OK sends it (plus CR LF). The default URL is
' tcpbin.com's echo service, so an untouched OK at the URL screen gives a
' self-test needing no server of your own.
'
' URL screen:  disc + action button  pick characters on the grid
'              OK (or keypad ENTER)  connect
'              ESC                   restore the default URL
'              keypad 0 / CLEAR      space / backspace
'              The URL buffer holds 256 bytes; rows 0-2 are a 60-character
'              window that scrolls once a long URL outgrows them.
'
' Terminal:    action button         open the keyboard to compose a line
'                                    (OK sends + CR LF, ESC cancels)
'              keypad CLEAR          hang up, back to the URL screen
'
' While the keyboard is open the connection is not polled; incoming bytes
' simply wait on the FujiNet and are drained when the terminal returns.
'
' Build:  intybasic netcat.bas netcat.asm && as1600 -o netcat netcat.asm
    GOTO main

    INCLUDE "fujinet.bas"
    INCLUDE "kbd.bas"

    CONST TERM_CELLS = 200      ' rows 0-9 are the terminal
    CONST STATUS_ROW = 220      ' row 11: status + key hints

    ' Scratch RAM, ours, above fujinet.bas's buffers (which end at $917F).
    CONST SC_URL  = $9200       ' devicespec, 256 bytes (255 chars + NUL)
    CONST SC_LINE = $9300       ' composed line, 253 bytes (252 + NUL)
    CONST SC_TERM = $9400       ' 200-byte shadow of the terminal cells

' The default devicespec (24 bytes): "N:TCP://TCPBIN.COM:4242/"
lit_spec:
    DATA 78,58,84,67,80,58,47,47,84,67,80,66,73,78
    DATA 46,67,79,77,58,52,50,52,50,47
    CONST LEN_SPEC = 24

    DIM term_pos, nc_i, nc_c, nc_cr, nc_row, tc_i

' ---------------------------------------------------------------------------
' term_clear_row: blank the terminal row term_pos sits in, screen and
' shadow both -- called on entering a fresh row so wrapped-around output
' never interleaves with a stale line. Uses its own loop variable (tc_i):
' it's called from term_putc/term_newline while those run inside the
' receive loop's "FOR nc_i = 0 TO #net_gotlen - 1" in main -- reusing nc_i
' here would clobber that outer loop's counter on every line break.
' ---------------------------------------------------------------------------
term_clear_row: PROCEDURE
    nc_row = (term_pos / 20) * 20
    FOR tc_i = 0 TO 19
        #BACKTAB(nc_row + tc_i) = CS_BLACK
        POKE (SC_TERM + nc_row + tc_i), 32
    NEXT tc_i
END

' ---------------------------------------------------------------------------
' term_putc: draw ASCII nc_c at the terminal cursor, handling CR/LF and
' wrap-around, mirroring every cell into SC_TERM so the display can be
' repainted after the keyboard has been over it. GROM cards 0-94 cover
' ASCII 32-126 directly.
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
    #BACKTAB(term_pos) = (nc_c - 32) * 8 + COL_NORMAL
    POKE (SC_TERM + term_pos), nc_c
    term_pos = term_pos + 1
    IF term_pos >= TERM_CELLS THEN term_pos = 0
    IF (term_pos % 20) = 0 THEN GOSUB term_clear_row
END

term_newline: PROCEDURE
    term_pos = (term_pos / 20) * 20 + 20
    IF term_pos >= TERM_CELLS THEN term_pos = 0
    GOSUB term_clear_row
END

' ---------------------------------------------------------------------------
' term_init / term_repaint: reset the pane, or redraw all 200 cells from
' the shadow after the keyboard borrowed the screen.
' ---------------------------------------------------------------------------
term_init: PROCEDURE
    term_pos = 0
    nc_cr = 0
    FOR nc_i = 0 TO TERM_CELLS - 1
        POKE (SC_TERM + nc_i), 32
    NEXT nc_i
END

term_repaint: PROCEDURE
    FOR nc_i = 0 TO TERM_CELLS - 1
        nc_c = PEEK(SC_TERM + nc_i) AND 255
        IF nc_c < 32 OR nc_c > 126 THEN nc_c = 32
        #BACKTAB(nc_i) = (nc_c - 32) * 8 + COL_NORMAL
    NEXT nc_i
END

' ---------------------------------------------------------------------------
' seed_url: (re)load the default devicespec into SC_URL.
' ---------------------------------------------------------------------------
seed_url: PROCEDURE
    FOR nc_i = 0 TO LEN_SPEC - 1
        POKE (SC_URL + nc_i), PEEK(VARPTR lit_spec(0) + nc_i) AND 255
    NEXT nc_i
    POKE (SC_URL + LEN_SPEC), 0
END

' ---------------------------------------------------------------------------
' url_screen: full-screen URL editor on the character grid. Returns with
' fn_ok = 1 and the accepted devicespec NUL-terminated in SC_URL. ESC
' restores the default and keeps editing (there is nothing to cancel to).
' ---------------------------------------------------------------------------
url_screen: PROCEDURE
us_again:
    CLS
    PRINT AT STATUS_ROW COLOR COL_DIM, "TYPE URL - OK DIALS "
    #ge_dst = SC_URL
    #g_max = 256
    GOSUB grid_entry
    IF fn_ok = 0 THEN
        GOSUB seed_url
        GOTO us_again
    END IF
    IF g_len = 0 THEN
        GOSUB seed_url
        GOTO us_again
    END IF
END

' ---------------------------------------------------------------------------
' compose_line: the same grid over the terminal screen. On OK, sends the
' line plus CR LF out the open channel. Restores the terminal afterward.
' ---------------------------------------------------------------------------
compose_line: PROCEDURE
    CLS
    PRINT AT STATUS_ROW COLOR COL_DIM, "OK SENDS - ESC BACK "
    POKE SC_LINE, 0             ' fresh line every time
    #ge_dst = SC_LINE
    #g_max = 253
    GOSUB grid_entry

    IF fn_ok THEN
        #fn_txlen = 0
        #fn_src = SC_LINE : ls_max = 253 : GOSUB fn_strlen : GOSUB fn_putstr
        POKE (FN_TX + #fn_txlen), 13
        POKE (FN_TX + #fn_txlen + 1), 10
        fn_len = #fn_txlen + 2
        GOSUB net_write
    END IF

    CLS
    GOSUB term_repaint
    PRINT AT STATUS_ROW COLOR COL_DIM, "BTN TYPE - CLR URL  "
END

main:
    MODE 0, 0, 0, 0, 0 : WAIT
    CLS
    PRINT AT 0 COLOR COL_NORMAL, "FUJINET NETCAT"
    PRINT AT 40, "CONNECTING TO FUJINET"
    GOSUB fn_wait_mailbox
    IF fn_ok = 0 THEN
        PRINT AT 40, "NO CARTRIDGE MAILBOX "
        GOTO halt
    END IF
    GOSUB seed_url

dial:
    GOSUB url_screen

    ' Open the accepted devicespec: read-write, no translation (we handle
    ' CR LF ourselves).
    CLS
    PRINT AT 0 COLOR COL_NORMAL, "DIALING..."
    #fn_txlen = 0
    #fn_src = SC_URL : ls_max = 255 : GOSUB fn_strlen : GOSUB fn_putstr
    mb_dev = NET_DEVICEID
    mb_cmd = NETCMD_OPEN
    mb_nparam = 2
    pm_i = 0 : pm_size = 1 : #pm_val = OPEN_MODE_RW : GOSUB fn_param
    pm_i = 1 : pm_size = 1 : #pm_val = OPEN_TRANS_NONE : GOSUB fn_param
    GOSUB fn_transact
    IF fn_ok = 0 THEN
        PRINT AT 40 COLOR COL_ERROR, "CONNECT FAILED"
        PRINT AT 60 COLOR COL_DIM, "PRESS BUTTON TO EDIT"
con_wait:
        WAIT
        GOSUB in_poll
        IF in_btn = 0 THEN GOTO con_wait
        GOTO dial                  ' SC_URL still holds the typo -- fix it
    END IF

    CLS
    GOSUB term_init
    GOSUB term_clear_row
    PRINT AT STATUS_ROW COLOR COL_DIM, "BTN TYPE - CLR URL  "

term_loop:
    WAIT

    ' --- receive: anything waiting? read up to 64 bytes and print it ---
    GOSUB net_status
    IF fn_ok = 0 THEN
        PRINT AT STATUS_ROW COLOR COL_ERROR, "CONNECTION LOST     "
lost_wait:
        WAIT
        GOSUB in_poll
        IF in_btn = 0 THEN GOTO lost_wait
        GOSUB net_close            ' free the unit regardless
        GOTO dial
    END IF
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

    ' --- input ---
    GOSUB in_poll
    IF in_btn THEN GOSUB compose_line
    IF in_key = KEYPAD_CLEAR THEN
        GOSUB net_close
        GOTO dial
    END IF
    GOTO term_loop

halt:
    WAIT
    GOTO halt
