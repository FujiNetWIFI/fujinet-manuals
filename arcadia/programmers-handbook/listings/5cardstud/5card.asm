; 5card.asm -- 5 Card Stud for the Emerson Arcadia 2001, over the FujiNet
; cartridge mailbox (fujinet-firmware/pico/arcadia).
;
; Layout: block 1 (CPU $0000-$0FFF) holds everything that touches the
; screen; block 2 (CPU $2000-$2AFF) shares 2650 page 1 with the mailbox
; and holds everything that talks to the cart. Cross-page calls are
; BSTA/BCTA (15-bit); cross-page DATA goes through DWBE pointer words.
; tools/checkdepth.py holds the whole client to the 8-entry RAS.
;
; Build: ./build.sh          (DEMO=1 ./build.sh for the static mock table)
; Run:   ./run.sh            (MAME arcadia + fujinet cart + fujinet-pc)

        CPU     2650

        ORG     $0000
        BCTA    UN,START        ; cartridge header: jump past the
        DB      $17             ; RETC,UN interrupt guard at $0003

        ORG     $0020

        INCLUDE "build/flags.inc"

; ---- RAM ledger ---------------------------------------------------------
; Every permanent variable is a line here. Zone A $18D0-$18EF (the
; fujidisp/fujilib legacy cells keep their addresses), the 4 bytes at
; $18F8-$18FB, zone B $1AD0-$1AFF. In 26-line mode this is ALL the RAM
; there is (84 bytes); $1A00-$1ACF is free scratch in 13-line screens
; only, and GSTATIC clears it before the flip to 26 lines.
CURSLC  EQU     $18D0           ; slice the cart is publishing
AVAIL   EQU     $18D1           ; u16 lo,hi: STATUS bytes-waiting
RXLEN   EQU     $18D3           ; u16 lo,hi: captured reply length
RXPTR   EQU     $18D5           ; state cursor: slice, offset
V_URL   EQU     $18D7           ; request type 0-3
MOVBUF  EQU     $18D8           ; staged move, 2 chars (0 = none)
SCRP    EQU     $18DA           ; screen-half base, big-endian word
DCOLOR  EQU     $18DC           ; attribute for DPUTC
V_KEY   EQU     $18DD           ; last raw control (edge detect)
PRVAVL  EQU     $18DE           ; u16 lo,hi: settle-loop compare
V_NUM   EQU     $18E0           ; u16 HI,LO: NUMPRT operand
V_TMP   EQU     $18E2
V_TMP2  EQU     $18E3
V_RNK   EQU     $18E4           ; DRWCRD rank char
V_SAV   EQU     $18E5           ; RXNEXT's R2 shelter
; $18E6-$18EA free
FSTRP   EQU     $18EB           ; FNTXSTR string pointer, big-endian
DSTRP   EQU     $18ED           ; DPRINT string pointer, big-endian
; $18F8-$18FB free
PLNBUF  EQU     $1AD0           ; player name, 9 + NUL
TBLBUF  EQU     $1ADA           ; table id, 9 + NUL
PRVRND  EQU     $1AE4           ; CHKNEW: last round
PRVACT  EQU     $1AE5           ; last activePlayer (turn-cue edge)
PRVPC   EQU     $1AE6           ; last playerCount
V_ACT   EQU     $1AE7           ; this reply: activePlayer
V_PC    EQU     $1AE8           ; this reply: playerCount
V_ROW   EQU     $1AE9           ; band renderer: current row
V_ST    EQU     $1AEA           ; band renderer: seat status
V_BASE  EQU     $1AEB           ; u16 hi,lo: player record base offset
V_SEL   EQU     $1AED           ; list cursor
V_CNT   EQU     $1AEE           ; list count / menu count
V_TICK  EQU     $1AEF           ; poll countdown
SPRTIC  EQU     $1AF0           ; sprite animation tick
SPRPH   EQU     $1AF1           ; sprite animation phase
V_RND   EQU     $1AF2           ; this reply: round
V_TIM   EQU     $1AF3           ; this reply: moveTime
V_VIEW  EQU     $1AF4           ; this reply: viewing
V_MVC   EQU     $1AF5           ; this reply: validMoveCount
V_SEAT  EQU     $1AF6           ; seat/list loop index
SPRROW  EQU     $1AF7           ; turn-cue band row ($FF parks the cue)
; $1AF8-$1AFF free

MB_DISP:
        INCLUDE "fujinet.inc"
        INCLUDE "disp.inc"

; ---- macros the screens use ---------------------------------------------
NUM16   MACRO   val             ; load a constant into NUMPRT's operand
        LODI,R0 (val)>>8
        STRA,R0 V_NUM
        LODI,R0 (val)&$FF
        STRA,R0 V_NUM+1
        ENDM

CARD    MACRO   rk,st           ; draw one card at the next two cells
        LODI,R0 rk
        STRA,R0 V_RNK
        LODI,R0 st
        BSTA,UN DRWCRD
        ENDM

MB_MAIN:
START:  EORZ    R0
        LPSU
        LODI,R0 $02             ; COM=1: logical compares everywhere
        LPSL
    IF DEMO
        BCTA    UN,DEMO0
    ELSEIF
        LODI,R3 7               ; default name
DEFCP:  LODA,R0 DEFNAM,R3
        STRA,R0 PLNBUF,R3
        BDRR,R3 DEFCP
        LODA,R0 DEFNAM
        STRA,R0 PLNBUF
        BSTA,UN MCHECK
        BCTR,EQ MHAVE
        BSTA,UN DINI13
        BSTA,UN DCLSU
        DAT     5,0
        DCOL    AALERT
        SETSTR  SNOFN
        BSTA,UN DPRINT
MHALT:  BCTA,UN MHALT
MHAVE:  BSTA,UN NAMESCR
        BCTA,UN LOBBY

DEFNAM: DB      "ARCADIA",0
SNOFN:  DB      "NO FUJINET CART",0
    ENDIF

MB_INPUT:
        INCLUDE "input.inc"
MB_SOUND:
        INCLUDE "sound.inc"
MB_CARDS:
        INCLUDE "cards.inc"
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
MB_GAME:
        INCLUDE "game.inc"
    ENDIF
MB_END1:

; ---- block 2: page 1, the mailbox side ------------------------------------
        ORG     $2000
MB_MAILBOX:
        INCLUDE "mailbox.inc"
MB_STATE:
        INCLUDE "state.inc"
MB_NET:
        INCLUDE "net.inc"
MB_URL:
        INCLUDE "url.inc"
MB_UDC:
        INCLUDE "assets/udc.inc"
MB_END2:
