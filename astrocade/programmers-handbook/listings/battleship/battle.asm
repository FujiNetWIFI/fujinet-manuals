; battle.asm -- Battleship for the Bally Astrocade, over FujiNet.
;
; A standalone-assembly client in the texasHoldEm/astrocade mold: same
; mailbox cartridge, same 4x6 renderer, same one-poll-loop shape. The
; gameplay logic is transcribed from the Intellivision port (intv/), the
; freshest client written directly against the binary wire format; the
; screen plan is the Intellivision's four-quadrant board compressed onto
; this machine's byte-aligned 2bpp bitmap.
;
; The board geometry is the whole trick: a grid cell is 4x4 pixels = one
; byte per row, so a 10x10 board is a 10-byte-wide, 40-line square and
; nothing ever shifts. Two boards fit side by side with a divider byte,
; two rows of boards fit in 84 lines, and the right 19 byte columns hold
; the panel. You are always quadrant 0 (bottom-left) -- the server
; rotates its player list so this client is index 0.
;
; ROM budget: 0000H-1AFFH of the 8K window (6,912 bytes); 1B00H+ belongs
; to the mailbox and build.sh stamps the "FUJI" claim at 1CFCH so the
; mailbox stays alive when this image is booted over the network. RAM is
; screen RAM alone: 90 visible lines use 4000H-4E0FH and everything above
; is ours.
;
; Interrupts stay off for the program's whole life (fujilib.inc's
; contract: with I = 0, refresh strays land in OS ROM and never hit the
; hotspots).

        INCLUDE "HVGLIB.H"
        INCLUDE "fujinet.inc"

; ---- RAM map ----------------------------------------------------------
LINES   EQU     90              ; 15 rows of 4x6 text

; What the last poll established. Rendering is opaque, so these are not a
; dirty list -- they exist only for the things overdraw cannot fix:
; content that SHRANK (a class or seat-count change clears the screen)
; and edges (your turn arriving, a shot landing, the game ending).
PRVCLS  EQU     4E10H           ; previous screen class (FF forces statics)
V_NEWS  EQU     4E11H           ; the statics were redrawn this poll
PRVACT  EQU     4E12H           ; previous activePlayer (the turn edge)
PRVPC   EQU     4E13H           ; previous playerCount
PRVRST  EQU     4E14H           ; previous result status  } the pair that
PRVRPS  EQU     4E15H           ; previous lastAttackPos  } gates sounds
PENDACT EQU     4E16H           ; staged action: 0 none, 1 ready, 2 place,
                                ; 3 attack -- rides the next poll
ATKPOS  EQU     4E17H           ; staged /attack position
MYSHP   EQU     4E18H           ; 5 staged /place bytes, pos + 100*dir
TGX     EQU     4E1DH           ; targeting cursor; persists across turns
TGY     EQU     4E1EH
TGLEFT  EQU     4E1FH           ; local countdown, reseeded each poll
TGFRM   EQU     4E20H           ; ~20 ms ticks toward the next second
RNDST   EQU     4E21H           ; LFSR state, 2 bytes
V_ST    EQU     4E23H           ; scratch: a player's status byte
V_QD    EQU     4E24H           ; quadrant being drawn
V_CX    EQU     4E25H           ; cell being drawn
V_CY    EQU     4E26H
PCX     EQU     4E27H           ; placement cursor
PCY     EQU     4E28H
PCDIR   EQU     4E29H           ; 0 horizontal, 1 vertical
PCSIZ   EQU     4E2AH
PCNUM   EQU     4E2BH           ; ship being placed, 0-4
V_FLAG  EQU     4E2CH           ; targeting outcome: 0 slice out, 1 fired,
                                ; 2 leave, 3 help
V_BLNK  EQU     4E2DH           ; cursor blink phase
V_CLS   EQU     4E2EH           ; this poll's class (0 lobby, 1 place,
                                ; 2 game, 3 over)
V_TRNF  EQU     4E2FH           ; turn-changed edge, this poll

; Session state.
PLNBUF  EQU     4E30H           ; player name, 9 + NUL (must stay in 4Exx:
                                ; nament tests its low byte)
TBLBUF  EQU     4E3AH           ; table id, 9 + NUL
CURSLC  EQU     4E46H           ; reply slice the cart is publishing
AVAIL   EQU     4E48H           ; NET_STATUS bytes waiting, u16
PRVAVL  EQU     4E4AH           ; previous reading, for the settle loop
RXLEN   EQU     4E4CH           ; reply length, captured after the READ
V_SEL   EQU     4E4EH           ; list cursor (tables)
V_CNT   EQU     4E4FH           ; list entry count
V_KEY   EQU     4E50H           ; last keypad/handle scan state (edges)
V_URL   EQU     4E58H           ; request being built (0 tables, 1 state,
                                ; 2 ready, 3 place, 4 attack, 5 leave)
V_TMP   EQU     4E59H           ; loop index (player being rendered)
V_ACT   EQU     4E5AH           ; this poll's activePlayer
V_PC    EQU     4E5BH           ; this poll's playerCount
V_NCUR  EQU     4E5CH           ; name-entry cursor
V_BASE  EQU     4E5EH           ; player record base offset (word)
TBLNAM  EQU     4E60H           ; joined table's display name, 21 + NUL
NAMEED  EQU     4E76H           ; name-entry edit buffer, 8 slots
OCCUPY  EQU     4E80H           ; placement occupancy map, 100 bytes

LINBUF  EQU     4F00H           ; display line being built; page-aligned
                                ; (U16STR's empty test reads the low byte)
HEXBUF  EQU     4F30H
STACK   EQU     4FC0H           ; grows down; 4FC0H+ left to the BIOS cells

; ---- Display options (BIOS STRDIS, titles only) ------------------------
OPTFB   EQU     0CH             ; fg color 3, bg color 0

; MB_* labels are module fences for tools/checksize.py's budget table.
        ORG     FIRSTC
MB_MAIN:
        DB      55H
        DW      MENUST
        DW      PRGNAM
        DW      PRGSTR
PRGNAM: DB      "BATTLESHIP"
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
        DB      0               ; color 0 everywhere: the sea
        DO      STRDIS
        DB      40              ; "BATTLESHIP", 10 chars x 8px, centred
        DB      38
        DB      OPTFB
        DW      TTITLE
        EXIT

        CALL    FNCHECK
        JP      NZ,NOCARD

        LD      HL,DEFNAM       ; player name until appkeys land
        LD      DE,PLNBUF
        LD      BC,6
        LDIR
        XOR     A
        LD      (PENDACT),A
        LD      (V_KEY),A
        LD      A,4             ; targeting cursor starts mid-board
        LD      (TGX),A
        LD      (TGY),A
        LD      HL,1            ; LFSR seed; RNDNXT mixes R in per call
        LD      (RNDST),HL
        CALL    NAMESCR         ; pick a name, then choose a table
        JP      TBLSCR

; ---- Errors -----------------------------------------------------------
NOCARD: SYSSUK  STRDIS
        DB      20
        DB      56
        DB      OPTFB
        DW      ENOCART
HALTE:  JR      HALTE

; ---- Data -------------------------------------------------------------
MB_DATA:
TTITLE: DB      "BATTLESHIP",0
ENET:   DB      "NET ERR - ANY KEY RETRIES",0
ENOCART: DB     "NO FUJINET CART",0
DEFNAM: DB      "ASTRO",0

; COLSET stores descending, ports 7 down to 0; both halves identical since
; HORCB is 0. Right palette: 3 = white, 2 = red, 1 = black, 0 = sea blue.
; Byte = (hue << 3) | luminance. Blue lives at the top of the hue circle
; (MAME's astrocade_palette: by = 1.15*cos(hue angle)): 0F2H = hue 30
; luma 2 = a deep sea blue. Checked against the palette math, not a
; guess -- 7AH (hue 15) reads "blue" in old notes but renders olive.
PALET:  DB      07H,52H,00H,0F2H
        DB      07H,52H,00H,0F2H

        INCLUDE "build/endpoint.inc"

MB_SCREENS:
        INCLUDE "screens.inc"
MB_PLACE:
        INCLUDE "place.inc"
MB_TARGET:
        INCLUDE "target.inc"
MB_BOARD:
        INCLUDE "board.inc"
MB_NAMENT:
        INCLUDE "nament.inc"
MB_SOUND:
        INCLUDE "sound.inc"
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
MB_RND:
        INCLUDE "rnd.inc"
MB_FONT:
        INCLUDE "assets/font.inc"
MB_FUJILIB:
        INCLUDE "fujilib.inc"
MB_END:
