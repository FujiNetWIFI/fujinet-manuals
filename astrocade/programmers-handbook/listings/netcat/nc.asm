; nc.asm -- netcat for the Bally Astrocade, over FujiNet.
;
; The family's minimal terminal: open an N: devicespec and then pump bytes
; between the connection and the screen forever. This is the first Astrocade
; FujiNet client that holds a connection open rather than doing a one-shot
; HTTP GET, so it is also the first to send N: WRITE (net.inc) and the first
; with a pane that scrolls (term.inc).
;
; ROM budget: 0000H-1AFFH of the 8K window (6,912 bytes); 1B00H+ belongs to
; the mailbox and build.sh stamps the "FUJI" claim at 1CFCH so the mailbox
; stays alive when this image is booted over the network.
;
; RAM is screen RAM, full stop. LINES=84 shows 14 rows of 4x6 text and
; leaves 4D20H up -- 736 bytes -- to the program; the card games' LINES=90
; would have left 496, and the terminal's shadow does not fit in that.
;
; Interrupts stay off for the program's whole life (fujilib.inc's contract:
; with I = 0, refresh strays land in OS ROM and never hit the hotspots).

        INCLUDE "HVGLIB.H"
        INCLUDE "fujinet.inc"

; ---- geometry ---------------------------------------------------------
LINES   EQU     84              ; visible scanlines: 14 rows of 4x6
TCOLS   EQU     40              ; columns; also the cols= we tell the BBS
TROWS   EQU     13              ; scrolling terminal rows, 0..12
STATROW EQU     13              ; the status row
TSHTOP  EQU     9               ; first terminal row the overlay covers
TSHROWS EQU     4               ; how many, hence the shadow's size
EDMAXL  EQU     TXMAX-8         ; longest devicespec or composed line: the
                                ; write cap less the CR LF and some slack, so
                                ; a full line plus its terminator still fits
                                ; the mailbox's TX stream

; ---- RAM map ----------------------------------------------------------
; 4000H-4D1FH is the visible screen. Everything below is ours.
TSHAD   EQU     4D20H           ; 160: character shadow of rows 9-12
EDBUF   EQU     4DC0H           ; 128: devicespec / composed line. The two
                                ; are never live at the same time.
TXONE   EQU     4E40H           ; a one-byte write's staging cell
TCOL    EQU     4E41H           ; cursor column -- must sit immediately
TROW    EQU     4E42H           ; below TROW: term.inc does LD DE,(TCOL)
TESC    EQU     4E43H           ; escape-sequence state, 0 = normal
TESCN   EQU     4E44H           ; bytes swallowed in this sequence
V_KEY   EQU     4E45H           ; last raw key, for edge detection
V_RPT   EQU     4E46H           ; auto-repeat countdown
V_GX    EQU     4E47H           ; grid keyboard cursor
V_GY    EQU     4E48H
EDTOPR  EQU     4E49H           ; the editor's top row
EDMAX   EQU     4E4AH           ; the editor's length cap
EDVN    EQU     4E4BH           ; value characters currently shown
EDCIX   EQU     4E4CH           ; grid cell being drawn
EDHNT   EQU     4E4EH           ; word: the editor's hint string
CURSLC  EQU     4E50H           ; reply slice the cart is publishing
AVAIL   EQU     4E52H           ; word: NET_STATUS bytes waiting
NCONN   EQU     4E54H           ; NET_STATUS connected flag
NDEVST  EQU     4E55H           ; NET_STATUS nDevStatus_t
RXLEN   EQU     4E56H           ; word: reply length, captured after a READ
STACK   EQU     4FC0H           ; grows down; 4FC0H+ left to the BIOS cells

; MB_* labels are module fences for tools/checksize.py's budget table.
        ORG     FIRSTC
MB_MAIN:
        DB      55H
        DW      MENUST
        DW      PRGNAM
        DW      PRGSTR
PRGNAM: DB      "NETCAT"
        DB      0

PRGSTR: DI
        LD      SP,STACK
        SYSTEM  INTPC
        DO      SETOUT
        DB      LINES*2         ; blank below the text
        DB      0               ; HORCB 0: the whole line is the right palette
        DB      8
        DO      COLSET
        DW      PALET
        DO      FILL
        DW      NORMEM
        DW      LINES*BYTEPL
        DB      0               ; color 0 everywhere
        EXIT

        CALL    FNCHECK
        JP      NZ,NOCARD

        ; The keypress that picked us off the on-board menu is still down.
        ; Drain it, or the dial screen's editor takes it as typing.
KWAIT:  CALL    KEYRAW
        OR      A
        JR      NZ,KWAIT

        XOR     A
        LD      (V_KEY),A
        LD      (CURSLC),A
        LD      A,1             ; start the grid cursor on 'A', not on space
        LD      (V_GX),A
        LD      (V_GY),A
        CALL    SEEDU
MAINLP: CALL    DIAL
        CALL    SESSN
        JR      MAINLP

; ---- Errors -----------------------------------------------------------
NOCARD: LD      HL,SNOCART
        LD      D,6
        LD      E,3
        LD      C,XAONK
        CALL    TXTAT
HALTE:  JR      HALTE

; ---- Data -------------------------------------------------------------
MB_DATA:
; COLSET stores descending, ports 7 down to 0, four bytes per palette in the
; order color 3, 2, 1, 0; both halves are identical since HORCB is 0.
; Byte = (hue << 3) | luminance, and hue 0 is the grayscale column.
; 3 white, 2 green (the accent), 1 gray, 0 black.
PALET:  DB      07H,0A4H,03H,00H
        DB      07H,0A4H,03H,00H

        INCLUDE "build/endpoint.inc"

MB_SCREENS:
        INCLUDE "screens.inc"
MB_TERM:
        INCLUDE "term.inc"
MB_EDIT:
        INCLUDE "edit.inc"
MB_INPUT:
        INCLUDE "input.inc"
MB_NET:
        INCLUDE "net.inc"
MB_STATE:
        INCLUDE "state.inc"
MB_GFX:
        INCLUDE "gfx.inc"
MB_FONT:
        INCLUDE "assets/font.inc"
MB_FUJILIB:
        INCLUDE "fujilib.inc"
MB_END:
