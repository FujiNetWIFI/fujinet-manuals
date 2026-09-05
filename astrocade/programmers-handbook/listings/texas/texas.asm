; texas.asm -- Texas Hold'em for the Bally Astrocade, over FujiNet.
;
; A standalone-assembly client in the o2/ mold: the shared C core cannot fit
; this machine, so the game is written to it. The cartridge is the FujiNet
; RP2040 cart (fujinet-firmware pico/astrocade); the graphics plan is the
; Lynx port's, whose 160x102 screen this hardware matches exactly.
;
; Converted from fujinet-5cardstud/astrocade the way the other clients were:
; the wire offsets shift +11 past viewing (community[11] at 87), each seat
; holds 2 hole cards instead of 5, a 5-card community board owns the middle
; of the table, and a street label names the round. The betting UI is
; unchanged -- move codes and labels come from the server, so the client
; still needs no poker rules.
;
; ROM budget: 0000H-1AFFH of the 8K window (6,912 bytes); 1B00H+ belongs to
; the mailbox and build.sh stamps the "FUJI" claim at 1CFCH so the mailbox
; stays alive when this image is booted over the network. RAM is screen RAM
; alone: 90 visible lines use 4000H-4E0FH and everything above is ours.
;
; Interrupts stay off for the program's whole life (fujilib.inc's contract:
; with I = 0, refresh strays land in OS ROM and never hit the hotspots).

        INCLUDE "HVGLIB.H"
        INCLUDE "fujinet.inc"
        INCLUDE "build/flags.inc"

; ---- RAM map ----------------------------------------------------------
LINES   EQU     90              ; 15 rows of 4x6 text

; What the last render drew. Rendering is opaque, so this is not a dirty
; list -- it exists only for the two things overdraw cannot fix: content
; that SHRANK, and edges (a new hand, your turn arriving).
PRVHND  EQU     4E10H           ; 8 bytes: cards each master seat showed
PRVCOM  EQU     4E18H           ; community cards drawn last poll
PRVRND  EQU     4E19H
PRVACT  EQU     4E1AH
PRVPC   EQU     4E1BH

; Session state.
PLNBUF  EQU     4E30H           ; player name, 9 + NUL
TBLBUF  EQU     4E3AH           ; table id, 9 + NUL
MOVBUF  EQU     4E44H           ; staged move code, 2 chars; 0 = none
CURSLC  EQU     4E46H           ; reply slice the cart is publishing
AVAIL   EQU     4E48H           ; NET_STATUS bytes waiting, u16
PRVAVL  EQU     4E4AH           ; previous reading, for the settle loop
RXLEN   EQU     4E4CH           ; reply length, captured after the READ
V_SEL   EQU     4E4EH           ; list cursor (tables / menus)
V_CNT   EQU     4E4FH           ; list entry count
V_KEY   EQU     4E50H           ; last keypad/handle scan state (edges)
CRDMAG  EQU     4E54H           ; card being drawn: magic-space address
CRDDST  EQU     4E56H           ; ...and its direct screen address
V_URL   EQU     4E58H           ; request being built (0 tables, 1 state,
                                ; 2 move, 3 leave)
V_TMP   EQU     4E59H           ; loop index (player being rendered)
V_ACT   EQU     4E5AH           ; this poll's activePlayer
V_PC    EQU     4E5BH           ; this poll's playerCount
V_SEAT  EQU     4E5CH           ; master seat of the player being rendered
V_ST    EQU     4E5DH           ; that player's status byte
V_BASE  EQU     4E5EH           ; that player's record base offset (word)
BARCOL  EQU     4E60H           ; status-bar column cursor
V_TMP2  EQU     4E61H           ; loop index (move menu entry)
V_NCUR  EQU     4E62H           ; name-entry cursor
V_NCNT  EQU     4E63H           ; cards the hand/board being drawn holds
V_MVL   EQU     4E64H           ; move-menu name width, from the move count
NAMEED  EQU     4EA0H           ; name-entry edit buffer, 8 slots
TBLNAM  EQU     4E70H           ; joined table's display name, 21 + NUL
HANDBUF EQU     4E88H           ; hand or board being drawn, 11 + NUL

LINBUF  EQU     4F00H           ; display line being built (fujicfg style)
HEXBUF  EQU     4F30H
STACK   EQU     4FC0H           ; grows down; 4FC0H+ left to the BIOS cells

; ---- Display options (BIOS STRDIS, used until the 4x6 font lands) ------
OPTFB   EQU     0CH             ; fg color 3, bg color 0

; MB_* labels are module fences for tools/checksize.py's budget table.
        ORG     FIRSTC
MB_MAIN:
        DB      55H
        DW      MENUST
        DW      PRGNAM
        DW      PRGSTR
PRGNAM: DB      "TEXAS HOLDEM"
        DB      0

PRGSTR: DI
        LD      SP,STACK
        SYSTEM  INTPC
        DO      SETOUT
        DB      LINES*2
        DB      0               ; HORCB 0: the whole line is the right palette
        DB      8
        DO      COLSET
        DW      PALET
        DO      FILL
        DW      NORMEM
        DW      LINES*BYTEPL
        DB      0               ; color 0 everywhere: the felt
        DO      STRDIS
        DB      32              ; "TEXAS HOLDEM", 12 chars x 8px, centred
        DB      38
        DB      OPTFB
        DW      TTITLE
        EXIT

        CALL    FNCHECK
        JP      NZ,NOCARD

        IF      DEMO
        CALL    DEMOSCR         ; the static mock table (M1)
HALT0:  JR      HALT0
        ELSE
        LD      HL,DEFNAM       ; player name until appkeys land
        LD      DE,PLNBUF
        LD      BC,6
        LDIR
        XOR     A
        LD      (MOVBUF),A
        LD      (V_KEY),A
        CALL    NAMESCR         ; pick a name, then choose a table
        JP      TBLSCR
        ENDIF

; ---- Errors -----------------------------------------------------------
NOCARD: SYSSUK  STRDIS
        DB      20
        DB      56
        DB      OPTFB
        DW      ENOCART
HALTE:  JR      HALTE

; ---- Data -------------------------------------------------------------
MB_DATA:
TTITLE: DB      "TEXAS HOLDEM",0
ENET:   DB      "NET ERR - ANY KEY RETRIES",0
ENOCART: DB     "NO FUJINET CART",0
DEFNAM: DB      "ASTRO",0

; COLSET stores descending, ports 7 down to 0; both halves identical since
; HORCB is 0. Right palette: 3 = white, 2 = red, 1 = black, 0 = felt green.
; Byte = (hue << 3) | luminance; hue 0 is the grayscale column.
PALET:  DB      07H,52H,00H,0A0H
        DB      07H,52H,00H,0A0H

        INCLUDE "build/endpoint.inc"

        IF      DEMO
        ELSE
MB_SCREENS:
        INCLUDE "screens.inc"
MB_NAMENT:
        INCLUDE "nament.inc"
MB_SOUND:
        INCLUDE "sound.inc"
        ENDIF
MB_INPUT:
        INCLUDE "input.inc"
MB_NET:
        INCLUDE "net.inc"
MB_URL:
        INCLUDE "url.inc"
MB_STATE:
        INCLUDE "state.inc"
MB_GFX:
        INCLUDE "gfx.inc"
MB_CARDS:
        INCLUDE "cards.inc"
        IF      DEMO
MB_DEMO:
        INCLUDE "demo.inc"
        ENDIF
MB_FONT:
        INCLUDE "assets/font.inc"
MB_ART:
        INCLUDE "assets/cardart.inc"
MB_FUJILIB:
        INCLUDE "fujilib.inc"
MB_END:
