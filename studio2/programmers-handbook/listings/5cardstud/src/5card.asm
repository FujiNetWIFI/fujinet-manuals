; 5card.asm -- 5 Card Stud for the RCA Studio II, over the FujiNet cartridge
; mailbox (fujinet-firmware/pico/studio2).
;
; A CDP1802 client in the Arcadia and Channel F mould. The cart draws the
; screen: every character is a hotspot read the cart's text engine turns into
; the raster the 1861 fetches, so nothing here touches pixels, and the reply
; window ($E400) is ordinary readable memory between transactions. Screens are
; drawn straight out of it; only the name, the table id and a move code are
; copied out, because the next request overwrites the window.
;
; fujinet.inc, s2macro.inc, s2call.inc, fujilib.inc, fujidisp.inc and input.inc
; are verbatim copies of fujinet-firmware/pico/studio2/testrom/.
;
; Structure: a flat state machine. Each screen (st_start, st_edit, st_lobby,
; st_game, st_menu) is entered by FJMP with the stack reset, so a screen can
; jump to any other without unwinding. Routines are FCALLed; R8, R9, RB, RC
; and RA.0 are anybody's, RA.1 is always the RAM page, and a loop that spans a
; call keeps its counter in RAM.

        CPU     1802
        INCLUDE "fujinet.inc"
        INCLUDE "s2macro.inc"
        INCLUDE "state.inc"

; ---- RAM ledger ----------------------------------------------------------
; $0800-$080F the runtime's (s2macro.inc); the client's from V_APP; the stack
; grows down from $09FF. main clears the page: nothing trusts power-on RAM.
; Every variable is on page $08, so RA.1 stays HI(RAMVARS) and VAR is 2 bytes.
V_REQ   EQU     V_APP+00H       ; the request BLDURL builds: REQ_*
V_MOVE  EQU     V_APP+01H       ; 2: the move code /move sends
V_AVL   EQU     V_APP+03H       ; 2: STATUS bytes waiting, lo hi
V_PRV   EQU     V_APP+05H       ; 2: the reading before
V_MIN   EQU     V_APP+07H       ; 2: settle until at least this much
V_CAP   EQU     V_APP+09H       ; 2: READ at most this much
V_RXL   EQU     V_APP+0BH       ; 2: reply length, taken right after READ
V_TRY   EQU     V_APP+0DH       ; settle polls left
V_KLAT  EQU     V_APP+0EH       ; a key pressed while a transaction ran
V_OK    EQU     V_APP+0FH       ; 1: the window holds a validated /state
V_NAME  EQU     V_APP+10H       ; 9: player name, NUL-terminated
V_TABLE EQU     V_APP+19H       ; 9: table id, NUL-terminated
V_PC    EQU     V_APP+22H       ; this /state: playerCount
V_ACT   EQU     V_APP+23H       ; activePlayer ($FF none)
V_NMV   EQU     V_APP+24H       ; validMoveCount
V_PNMV  EQU     V_APP+25H       ; validMoveCount at the poll before
V_VIEW  EQU     V_APP+26H       ; 0 cards, 1 chips
V_LRSUM EQU     V_APP+27H       ; lastResult checksum
V_HOLD  EQU     V_APP+28H       ; polls the result banner stays up
V_MQON  EQU     V_APP+29H       ; row 9 is the result marquee
V_MQPOS EQU     V_APP+2AH       ; marquee: first character shown
V_MQLEN EQU     V_APP+2BH       ; lastResult's length
V_MQW   EQU     V_APP+2CH       ; length + 3 gap if it scrolls, else 0
V_MQT   EQU     V_APP+2DH       ; RE.0 of the last step
V_T0    EQU     V_APP+2EH       ; RE.0 a wait began
V_SEAT  EQU     V_APP+2FH       ; 1: seated at V_TABLE
V_ROW   EQU     V_APP+30H       ; render loop row
V_NTBL  EQU     V_APP+31H       ; tables listed (at most 8)
V_EDX   EQU     V_APP+32H       ; name editor cursor column
V_EDY   EQU     V_APP+33H       ; and row
V_EDLEN EQU     V_APP+34H       ; characters typed
V_EDBUF EQU     V_APP+35H       ; 9: the name being typed
V_DIGS  EQU     V_APP+3EH       ; 5: a number, ASCII, leading blanks
V_ERRC  EQU     V_APP+43H       ; the failure code on screen
V_CTR   EQU     V_APP+44H       ; scratch counter
V_RND   EQU     V_APP+45H       ; this /state: round
V_IVL   EQU     V_APP+46H       ; frames the game waits before the next poll
V_END   EQU     V_APP+47H

        IF      HI(V_END) <> HI(RAMVARS)
        ERROR   "RAM ledger runs off page $08"
        ENDIF

; ---- macros --------------------------------------------------------------
VAR     MACRO   v               ; RA -> v
        LDI     LO(v)
        PLO     RA
        ENDM

GETV    MACRO   v               ; D = v
        VAR     v
        LDN     RA
        ENDM

PUTV    MACRO   v               ; v = D (RD.1 is free between calls)
        PHI     RD
        VAR     v
        GHI     RD
        STR     RA
        ENDM

SETV    MACRO   v, val          ; v = val
        VAR     v
        LDI     val
        STR     RA
        ENDM

AT      MACRO   rc              ; cursor to row r, column c ($rc)
        LDI     rc
        FCALL   d_at
        ENDM

PUTS    MACRO   rc, str         ; a string at $rc
        AT      rc
        LDR     R8, str
        FCALL   d_puts
        ENDM

OP      MACRO   code            ; a text engine operation
        LDI     code
        FCALL   d_op
        ENDM

BEEP    MACRO   n               ; Q for n frames (the ISR counts RD.0 down)
        LDI     n
        PLO     RD
        ENDM

RESET   MACRO                   ; a screen's entry: drop whatever was stacked,
        LDR     R2, STACK       ; and any key pressed for the screen before
        SETV    V_KLAT, 0       ; (R2.1 never changes, so the ISR is safe)
        ENDM

SEGEND  MACRO   lim             ; a code segment must stop short of lim
        IF      $ > lim
        ERROR   "segment overflows its window"
        ENDIF
        ENDM

; ---- the runtime: $0400-$07FB ----------------------------------------------
        ORG     0400H
        INCLUDE "s2call.inc"
        INCLUDE "fujilib.inc"
        INCLUDE "fujidisp.inc"
        INCLUDE "input.inc"
        SEGEND  FN_CLAIM

; ---- $0C00-$0FFF: start-up and the drawing helpers ------------------------
        ORG     0C00H
        FIT     48
main:   LDI     HI(RAMVARS)
        PHI     RA
        LDR     R8, RAMVARS+0FFH        ; clear the variable page
        SEX     R8
mclr:   LDI     0
        STXD
        GHI     R8
        XRI     HI(RAMVARS)
        BZ      mclr
        SEX     R2
        FCALL   glyphs
        FCALL   fn_chk
        BDF     mgo
        FCALL   d_cls
        PUTS    40H, s_nocart
mhalt:  BR      mhalt
mgo:    FJMP    st_start

        INCLUDE "ui.inc"
        INCLUDE "cards.inc"
        SEGEND  1000H

; ---- $1400-$1FFF: the network, the name ----------------------------------
        ORG     1400H
        INCLUDE "net.inc"
        INCLUDE "url.inc"
        INCLUDE "nament.inc"
        SEGEND  2000H

; ---- $2400-$2FFF: the lobby and the menu ---------------------------------
        ORG     2400H
        INCLUDE "lobby.inc"
        INCLUDE "menu.inc"
        SEGEND  3000H

; ---- $3400-$3FFF: the table ------------------------------------------------
        ORG     3400H
        INCLUDE "game.inc"
        INCLUDE "strings.inc"
        INCLUDE "endpoint.inc"
        SEGEND  4000H

        S2CLAIM
