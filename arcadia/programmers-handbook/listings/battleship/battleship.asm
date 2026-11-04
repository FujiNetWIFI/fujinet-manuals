; battleship.asm -- Battleship for the Emerson Arcadia 2001, over the
; FujiNet cartridge mailbox (fujinet-firmware/pico/arcadia).
;
; Layout: block 1 (CPU $0000-$0FFF) holds everything that touches the
; screen; block 2 (CPU $2000-$2AFF) shares 2650 page 1 with the mailbox
; and holds everything that talks to the cart. Cross-page calls are
; BSTA/BCTA (15-bit); cross-page DATA goes through DWBE pointer words.
; tools/checkdepth.py holds the whole client to the 8-entry RAS.
;
; Build: ./build.sh          (DEMO=1 ./build.sh for the static mock board)
; Run:   ./run.sh            (MAME arcadia + fujinet cart + fujinet-pc)

        CPU     2650

        ORG     $0000
        BCTA    UN,START        ; cartridge header: jump past the
        DB      $17             ; RETC,UN interrupt guard at $0003

        ORG     $0020

        INCLUDE "build/flags.inc"

; ---- RAM ledger ---------------------------------------------------------
; Every permanent variable is a line here. In 26-line mode this is ALL
; the RAM there is: zone A $18D0-$18EF (the fujidisp/fujilib legacy cells
; keep their addresses), the 4 bytes at $18F8-$18FB, and zone B
; $1AD0-$1AFF -- 84 bytes. $1A00-$1ACF is free scratch in 13-line screens
; ONLY; GSTATIC clears it before the flip to 26 lines, because the moment
; 26-line mode comes on those bytes become visible screen.

; -- zone A: transport, display, input ($18D0-$18EA) --
CURSLC  EQU     $18D0           ; slice the cart is publishing
AVAIL   EQU     $18D1           ; u16 lo,hi: STATUS bytes-waiting
RXLEN   EQU     $18D3           ; u16 lo,hi: captured reply length
RXPTR   EQU     $18D5           ; reply cursor: slice, offset
V_URL   EQU     $18D7           ; request type (RQ*)
V_SAV   EQU     $18D8           ; RXNEXT's R2 shelter
V_TMP   EQU     $18D9           ; APICALL's settle-loop counter
SCRP    EQU     $18DA           ; screen-half base, big-endian word
DCOLOR  EQU     $18DC           ; attribute for DPUTC
V_KEY   EQU     $18DD           ; last raw control (edge detect)
PRVAVL  EQU     $18DE           ; u16 lo,hi: settle-loop compare
V_NUM   EQU     $18E0           ; u16 HI,LO: NUMPRT operand
V_TMP2  EQU     $18E2           ; DPRTN / RXPRNT field counter
BGCBAS  EQU     $18E3           ; this mode's BGCOL with the pot mux CLEAR
V_RPT   EQU     $18E4           ; disc auto-repeat countdown
AXV     EQU     $18E5           ; cached vertical pot
AXH     EQU     $18E6           ; cached horizontal pot
AXSEL   EQU     $18E7           ; which axis KEYRAW samples this frame
ATKPOS  EQU     $18E8           ; staged attack position 0-99
V_SHIX  EQU     $18E9           ; BLDURL's ship index across BYTDEC
V_CURS  EQU     $18EA           ; placement: the ship being adjusted
                                ;   (V_SHP is YSHIPR's walker and gets
                                ;    clobbered by every board repaint)
FSTRP   EQU     $18EB           ; FNTXSTR string pointer, big-endian
DSTRP   EQU     $18ED           ; DPRINT string pointer, big-endian
V_SAVP  EQU     $18EF           ; placement: its committed placement byte
;       $18F0-$18F7 SPRPOS (hardware)

; -- the four bytes between the sprite and mode registers --
V_ROW   EQU     $18F8           ; board renderer: current row
V_COL   EQU     $18F9           ; board renderer: cells left in the row
V_BTMP  EQU     $18FA           ; BRDFRM's row walker
V_SEG   EQU     $18FB           ; SHIPDR's segment index

; -- zone B: game state ($1AD0-$1AFF, all 48 bytes spoken for) --
PLNBUF  EQU     $1AD0           ; player name, 9 + NUL
TBLBUF  EQU     $1ADA           ; table id, 9 + NUL
SHIPS   EQU     $1AE4           ; the five placements, pos + 100*dir
PRVACT  EQU     $1AE9           ; last activePlayer (turn-cue edge)
PRVPC   EQU     $1AEA           ; last playerCount
PRVCLS  EQU     $1AEB           ; last screen class (statics edge)
PRVST   EQU     $1AEC           ; last status (result-sound edge)
V_ACT   EQU     $1AED           ; this reply: activePlayer
V_PC    EQU     $1AEE           ; this reply: playerCount
V_ST    EQU     $1AEF           ; this reply: status
V_PLST  EQU     $1AF0           ; this reply: your playerStatus
VIEWPL  EQU     $1AF1           ; which opponent the enemy board shows
CURX    EQU     $1AF2           ; targeting cursor
CURY    EQU     $1AF3
V_TICK  EQU     $1AF4           ; poll countdown
V_SEL   EQU     $1AF5           ; list cursor
V_CNT   EQU     $1AF6           ; list count
PENDACT EQU     $1AF7           ; staged request for the next poll
RNDST   EQU     $1AF8           ; u16 LFSR state
V_SHP   EQU     $1AFA           ; ship index being drawn/placed
V_PLC   EQU     $1AFB           ; its placement byte
V_DIR   EQU     $1AFC           ; its direction
V_SX    EQU     $1AFD           ; its walking x
V_SY    EQU     $1AFE           ; its walking y
V_LEN   EQU     $1AFF           ; its length

; -- 13-line scratch ($1A00-$1ACF), valid only while the lower screen is
;    off. The name editor lives here; GSTATIC clears it before the flip.
NAMEED  EQU     $1A00           ; 8 edit slots
V_NCUR  EQU     $1A08           ; name-entry cursor

; ---- modules ------------------------------------------------------------
MB_DISP:
        INCLUDE "fujinet.inc"
        INCLUDE "disp.inc"
MB_MAIN:
        INCLUDE "main.inc"
MB_INPUT:
        INCLUDE "input.inc"
MB_BOARD:
        INCLUDE "board.inc"
MB_SPRITE:
        INCLUDE "sprites.inc"
MB_FUJILIB:
        INCLUDE "fujilib.inc"
    IF DEMO
MB_DEMO:
        INCLUDE "demo.inc"
    ELSEIF
MB_NAMENT:
        INCLUDE "nament.inc"
MB_LOBBY:
        INCLUDE "lobby.inc"
MB_PLACE:
        INCLUDE "place.inc"
MB_GAME:
        INCLUDE "game.inc"
    ENDIF
MB_END1:

        ORG     $2000
MB_MAILBOX:
        INCLUDE "mailbox.inc"
MB_STATE:
        INCLUDE "state.inc"
MB_NET:
        INCLUDE "net.inc"
MB_URL:
        INCLUDE "url.inc"
    IF DEMO=0                   ; targeting calls into game.inc's renderers
MB_TARGET:
        INCLUDE "target.inc"
    ENDIF
MB_SOUND:
        INCLUDE "sound.inc"
MB_TABLES:
        INCLUDE "tables.inc"
MB_STRING:
        INCLUDE "strings.inc"
MB_UDC:
        INCLUDE "assets/udc.inc"
MB_END2:
