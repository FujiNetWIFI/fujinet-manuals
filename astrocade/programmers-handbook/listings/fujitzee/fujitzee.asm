; fujitzee.asm -- Fujitzee for the Bally Astrocade, over FujiNet.
;
; A standalone-assembly client in the battleship/astrocade mold: same
; mailbox cartridge, same 4x6 renderer, same one-poll-loop shape. The
; gameplay logic is transcribed from the Intellivision port (intv/), the
; freshest client written directly against the binary wire format; the
; screen plan trades the Intellivision's 20-column squeeze for this
; machine's 40 columns: the compact two-column scorecard keeps its shape
; and the reclaimed right half becomes an always-visible standings panel,
; so the seat strip and the hold-to-view standings overlay disappear.
;
; The server owns the whole game: every endpoint returns the same state
; blob, validScores[] carries the exact points each open row would earn,
; and the client's only arithmetic is the running total (the wire's grand
; total is empty until game over). You are always player index 0.
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
        INCLUDE "build/flags.inc"

; ---- RAM map ----------------------------------------------------------
LINES   EQU     90              ; 15 rows of 4x6 text

; What the last poll established. Rendering is opaque, so these are not a
; dirty list -- they exist only for the things overdraw cannot fix:
; content that SHRANK (a class or seat-count change clears the screen)
; and edges (your turn arriving, a roll landing, the game ending).
PRVCLS  EQU     4E10H           ; previous screen class (FF forces statics)
V_NEWS  EQU     4E11H           ; the statics were redrawn this poll
PRVACT  EQU     4E12H           ; previous activePlayer (the turn edge)
PRVPC   EQU     4E13H           ; previous playerCount
PRVRLS  EQU     4E14H           ; previous rollsLeft (FF = sentinel: no
                                ; roll edge across a screen boundary)
PENDACT EQU     4E15H           ; staged action: 0 none, 1 ready, 2 roll,
                                ; 3 score -- rides the next poll
SCOREIX EQU     4E16H           ; staged /score category, 0-14
KEEPBF  EQU     4E17H           ; staged roll mask, 5 ascii '0'/'1' + NUL
                                ; ('1' = re-roll); streamed verbatim
UIMODE  EQU     4E1DH           ; my-turn input mode: 0 dice, 1 score
DCUR    EQU     4E1EH           ; dice cursor 0-5 (0 = the ROLL tile)
SCUR    EQU     4E1FH           ; score cursor = category index 0-5, 8-14
VIEWIDX EQU     4E20H           ; whose scorecard is shown
TGLEFT  EQU     4E21H           ; local countdown, reseeded each poll
TGFRM   EQU     4E22H           ; ~20 ms ticks toward the next second
RNDST   EQU     4E23H           ; LFSR state, 2 bytes
V_CLS   EQU     4E25H           ; this poll's class (0 lobby, 1 play,
                                ; 2 over)
V_TRNF  EQU     4E26H           ; turn-changed edge, this poll
V_MYTRN EQU     4E27H           ; my turn and not a spectator, this poll
V_FLAG  EQU     4E28H           ; turn-input outcome: 0 slice out, 1 roll,
                                ; 2 score, 3 leave, 4 help
V_ST    EQU     4E29H           ; scratch
V_TOT   EQU     4E2AH           ; running-total scratch, word
V_WIN   EQU     4E2CH           ; gameover: the leader's seat
V_CAT   EQU     4E2DH           ; scorecard loop: category being drawn
V_FACE  EQU     4E2EH           ; dice loop scratch
V_TM2   EQU     4E2FH           ; inner loop index

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
                                ; 2 ready, 3 roll, 4 score, 5 leave)
V_TMP   EQU     4E59H           ; loop index (player being rendered)
V_ACT   EQU     4E5AH           ; this poll's activePlayer
V_PC    EQU     4E5BH           ; this poll's playerCount
V_NCUR  EQU     4E5CH           ; name-entry cursor
V_BASE  EQU     4E5EH           ; player record base offset (word)
TBLNAM  EQU     4E60H           ; joined table's display name, 21 + NUL
NAMEED  EQU     4E76H           ; name-entry edit buffer, 8 slots
BSTTOT  EQU     4E80H           ; gameover: the leading total, word

LINBUF  EQU     4F00H           ; display line being built; page-aligned
                                ; (U16STR's empty test reads the low byte)
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
PRGNAM: DB      "FUJITZEE"
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
        DB      48              ; "FUJITZEE", 8 chars x 8px, centred
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
        LD      (PENDACT),A
        LD      (V_KEY),A
        LD      HL,1            ; LFSR seed; RNDNXT mixes R in per call
        LD      (RNDST),HL
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
TTITLE: DB      "FUJITZEE",0
ENET:   DB      "NET ERR - ANY KEY RETRIES",0
ENOCART: DB     "NO FUJINET CART",0
DEFNAM: DB      "ASTRO",0

; COLSET stores descending, ports 7 down to 0; both halves identical since
; HORCB is 0. Right palette: 3 = white, 2 = red, 1 = black, 0 = felt green
; (the texasHoldEm table color: hue 20, luma 0).
; Byte = (hue << 3) | luminance; hue 0 is the grayscale column.
PALET:  DB      07H,52H,00H,0A0H
        DB      07H,52H,00H,0A0H

        INCLUDE "build/endpoint.inc"

        IF      DEMO
MB_DICE:
        INCLUDE "dice.inc"
MB_CARDST:
        INCLUDE "cardst.inc"
MB_DEMO:
        INCLUDE "demo.inc"
MB_SOUND:
        INCLUDE "sound.inc"
MB_INPUT:
        INCLUDE "input.inc"
MB_STATE:
        INCLUDE "state.inc"
MB_GFX:
        INCLUDE "gfx.inc"
MB_RND:
        INCLUDE "rnd.inc"
        ELSE
MB_SCREENS:
        INCLUDE "screens.inc"
MB_CARD:
        INCLUDE "card.inc"
MB_CARDST:
        INCLUDE "cardst.inc"
MB_TURN:
        INCLUDE "turn.inc"
MB_DICE:
        INCLUDE "dice.inc"
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
        ENDIF
MB_FONT:
        INCLUDE "assets/font.inc"
MB_FUJILIB:
        INCLUDE "fujilib.inc"
MB_END:
