; netcat.asm -- talk to a TCP server, a line at
; a time.
;
; The URL comes up in CONFIG's on-screen
; keyboard, ready to change; 9 connects. Then
; rows 0-8 show what the server sends, scrolling
; up as it comes, and row 9 the keys: 5 types a
; line (9 sends it with CR LF), 0 closes the
; connection and goes back to CONFIG. What
; arrives while you type waits in the FujiNet.
;
; The text engine has no memory of its own a
; program can read back, so a shadow of rows 0-8
; lives in console RAM to repaint the view after
; the keyboard has used the screen.

        CPU     1802
        INCLUDE "fujinet.inc"
        INCLUDE "s2macro.inc"
        INCLUDE "s2defs.inc"
        INCLUDE "bookcfg.inc"

; ---- RAM ledger: $0800-$09FF ----
; $0800-$080F  the runtime's V_*
; $0810-$081A  the state below
; $0870-$08B0  V_EDIT, the line being typed
; $0900-$098F  SHADOW, rows 0-8 as shown
; $0990-$09FF  the stack (112 bytes)
V_ROW   EQU     V_APP+00H       ; receive row, 0-8
V_COL   EQU     V_APP+01H       ; its column, 0-16
V_EDLEN EQU     V_APP+02H       ; keyboard: length
V_EDMAX EQU     V_APP+03H       ;   the most
V_OSK   EQU     V_APP+04H       ;   its cell, 0-95
V_KOLD  EQU     V_APP+05H       ; key_wait's
V_KTO   EQU     V_APP+06H       ;   own two
V_EDWHAT EQU    V_APP+07H       ; 0: URL, 1: line
V_CONN  EQU     V_APP+08H       ; 1: connected
V_N     EQU     V_APP+09H       ; reply bytes left
V_TS    EQU     V_APP+0AH       ; RE.0 at STATUS
V_EDIT  EQU     0870H           ; 65
SHADOW  EQU     0900H           ; 9 rows of 16
NROWS   EQU     9
NMAX    EQU     128             ; the most a READ

        ORG     0400H
        INCLUDE "s2call.inc"
        INCLUDE "fujilib.inc"
        INCLUDE "fujidisp.inc"
        INCLUDE "input.inc"

        ORG     0C00H
        INCLUDE "booklib.inc"
        INCLUDE "osk.inc"

; ---- start: the URL into the keyboard ----
        RFIT    60
main:   LDI     HI(V_APP)
        PHI     RB              ; for LDV and STV
        FCALL   fn_chk
        BDF     mn1
        LDI     FNENOC
        FJMP    fail
mn1:    LDR     R8, url
        LDR     R9, V_EDIT
mn2:    LDA     R8              ; copy it, NUL too
        STR     R9
        INC     R9
        BNZ     mn2
        SETV    V_EDWHAT, 0
        SETV    V_EDMAX, 63
        SETV    V_CONN, 0
        FJMP    st_edit

; ---- the keyboard's screen ----
        RFIT    94
st_edit:
        FCALL   d_cls
        PUTS    00H, t_okeys
        LDV     V_EDWHAT
        BNZ     ste1
        PUTS    20H, t_url
        BR      ste2
ste1:   PUTS    20H, t_line
ste2:   LDR     R8, V_EDIT      ; its length
ste3:   LDA     R8
        BNZ     ste3
        DEC     R8
        GLO     R8
        SMI     LO(V_EDIT)
        STV     V_EDLEN
        SETV    V_OSK, 'a'-20H
        FCALL   ed_grid
        LDV     V_OSK
        FCALL   ed_sel
        FCALL   ed_text
        FJMP    ed_in

; ed_ok: 9. ed_esc: 1.
        RFIT    40
ed_ok:  LDV     V_EDWHAT
        BNZ     eok1
        FJMP    connect
eok1:   FJMP    send
ed_esc: LDV     V_EDWHAT
        BNZ     ees1
        FJMP    quit            ; no URL: CONFIG
ees1:   FJMP    view

; ---- OPEN the URL, read and write ----
        RFIT    111
connect:
        FCALL   d_cls
        PUTS    00H, t_conn
        FNBEGIN NETDEV, NCOPEN, 2
        LDI     NMHTTPG         ; 12: read and write
        FCALL   fn_pb
        LDI     NTRNONE
        FCALL   fn_pb
        LDR     R8, V_EDIT
        FCALL   fn_str
        SLOW    95
        GOACK
        SETV    V_CONN, 1
        LDR     R8, SHADOW      ; a blank shadow
        LDI     NROWS*16
        PLO     R9
cn1:    LDI     ' '
        STR     R8
        INC     R8
        DEC     R9
        GLO     R9
        BNZ     cn1
        SETV    V_ROW, 0
        SETV    V_COL, 0
        LDR     R8, V_EDIT      ; an empty line
        LDI     0
        STR     R8
        FJMP    view

; ---- the receive view: repaint, then poll ----
        RFIT    60
view:   FCALL   d_cls
        LDR     RA, SHADOW
        LDI     NROWS*16
        PLO     RC
vw1:    LDA     RA              ; rows 0-8; PUTC
        FCALL   d_putc          ; wraps the rows
        DEC     RC
        GLO     RC
        BNZ     vw1
        FCALL   legend
        FJMP    poll

        RFIT    60
poll:   FCALL   in_get
        BZ      pl2
        ANI     0FH
        XRI     5
        BNZ     pl1
        SETV    V_EDWHAT, 1     ; 5: type a line
        SETV    V_EDMAX, 60
        FJMP    st_edit
pl1:    XRI     5               ; 0: close, CONFIG
        BNZ     pl2
        FJMP    quit
pl2:    LDV     V_CONN
        BZ      poll            ; closed: keys only
        LDV     V_TS            ; keys every frame,
        STR     R2              ; STATUS every 8th
        GLO     RE
        SM
        SMI     8
        BNF     poll
        GLO     RE
        STV     V_TS
        FJMP    status

; ---- STATUS: anything waiting? ----
        RFIT    106
status: FNBEGIN NETDEV, NCSTAT, 2
        LDI     0
        FCALL   fn_pb
        LDI     0
        FCALL   fn_pb
        SLOW    95
        GOACK
        PEEK    FN_REPLY+NSAVHI
        BNZ     st2             ; 256 or more
        PEEK    FN_REPLY+NSAVLO
        BNZ     st1
        PEEK    FN_REPLY+NSCONN
        BNZ     st3             ; nothing yet
        SETV    V_CONN, 0       ; the server closed
        FCALL   legend
st3:    FJMP    poll
st1:    SMI     NMAX+1
        BNF     st4             ; under NMAX + 1
st2:    LDI     NMAX
        BR      st5
st4:    ADI     NMAX+1          ; the count again
st5:    PLO     RA
        FJMP    read

; ---- READ RA.0 bytes, and show them ----
        RFIT    78
read:   FNBEGIN NETDEV, NCREAD, 1
        GLO     RA
        PLO     R8
        LDI     0
        PHI     R8
        FCALL   fn_pw
        SLOW    95
        GOACK
        PEEK    FN_RXLEN        ; what came
        STV     V_N
        LDR     RA, FN_REPLY    ; RA walks it
rd1:    LDV     V_N
        BZ      rd2
        SMI     1
        STR     RB
        LDA     RA
        FCALL   rx
        BR      rd1
rd2:    FJMP    poll

; rx -- one byte from the server: CR is
; dropped, LF ends the row, the rest is shown.
; The byte waits in RC.1: newline counts in RC.0.
        RFIT    48
rx:     PHI     RC
        XRI     0DH
        BZ      rx2             ; CR
        XRI     0DH ! 0AH
        BNZ     rx1
        FJMP    newline         ; LF
rx1:    LDV     V_COL
        XRI     16
        BNZ     rx3
        FCALL   newline         ; a full row
rx3:    FCALL   putch
rx2:    FRET

; putch -- RC.1 at V_ROW, V_COL, on the screen
; and in the shadow.
        RFIT    48
putch:  LDV     V_ROW
        SHL
        SHL
        SHL
        SHL
        STR     R2
        LDV     V_COL
        OR                      ; row * 16 + col
        PLO     RC
        FCALL   d_at
        GHI     RC
        FCALL   d_putc
        GLO     RC              ; the shadow index
        PLO     R9
        LDI     HI(SHADOW)
        PHI     R9
        GHI     RC
        STR     R9
        LDV     V_COL
        ADI     1
        STR     RB
        FRET

; newline -- the next row; at the bottom, the
; screen and the shadow scroll up a row.
        RFIT    80
newline:
        SETV    V_COL, 0
        LDV     V_ROW
        XRI     NROWS-1
        BZ      nl1
        LDV     V_ROW
        ADI     1
        STR     RB
        FRET
nl1:    LDI     TOP_SCROLL      ; rows 1-9 up
        FCALL   d_op
        LDI     80H             ; row 8 blank
        FCALL   d_at
        LDI     TOP_CLREOL
        FCALL   d_op
        FCALL   legend          ; row 9 again
        LDR     R8, SHADOW+16   ; the shadow, too
        LDR     R9, SHADOW
        LDI     (NROWS-1)*16
        PLO     RC
nl2:    LDA     R8
        STR     R9
        INC     R9
        DEC     RC
        GLO     RC
        BNZ     nl2
        LDI     16              ; R9: its last row
        PLO     RC
nl3:    LDI     ' '
        STR     R9
        INC     R9
        DEC     RC
        GLO     RC
        BNZ     nl3
        FRET

; legend -- row 9 in inverse: the keys, or
; that the server has gone.
        RFIT    48
legend: LDI     TOP_INV_ON
        FCALL   d_op
        LDV     V_CONN
        BZ      lg1
        PUTS    90H, t_keys
        BR      lg2
lg1:    PUTS    90H, t_gone
lg2:    LDI     TOP_INV_OFF
        FCALL   d_op
        FRET

; ---- WRITE the line, CR LF after it ----
        RFIT    80
send:   FNBEGIN NETDEV, NCWRITE, 1
        LDV     V_EDLEN
        ADI     2
        PLO     R8
        LDI     0
        PHI     R8
        FCALL   fn_pw           ; the count
        LDR     R8, V_EDIT
        FCALL   fn_str
        LDI     0DH
        FCALL   fn_txb
        LDI     0AH
        FCALL   fn_txb
        SLOW    95
        GOACK
        LDR     R8, V_EDIT      ; empty again
        LDI     0
        STR     R8
        FJMP    view

; ---- CLOSE, and back to CONFIG ----
        RFIT    40
quit:   LDV     V_CONN
        BZ      qt1
        FNBEGIN NETDEV, NCCLOSE, 0
        GOACK
qt1:    FCALL   fn_config       ; never returns...
        FJMP    fail            ; ...if not armed

url:     NC_URL
t_okeys: DB     "5:ADD 0:DEL 9:OK", 0
t_url:   DB     "URL, 1:QUIT", 0
t_line:  DB     "SEND, 1:BACK", 0
t_conn:  DB     "CONNECTING", 0
t_keys:  DB     "5:TYPE  0:QUIT  ", 0
t_gone:  DB     "CLOSED  0:QUIT  ", 0

        S2CLAIM
