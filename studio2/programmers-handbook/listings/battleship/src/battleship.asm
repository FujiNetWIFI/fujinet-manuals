; battleship.asm -- Battleship for the RCA Studio II, over the FujiNet
; cartridge mailbox (fujinet-firmware/pico/studio2).
;
; A CDP1802 client in the mould of 5 Card Stud's (fujinet-5cardstud
; studio2/), whose network, name and lobby code this reuses. The cart draws
; the screen: every character is a hotspot read the cart's text engine turns
; into the 64x128 raster the 1861 fetches, so nothing here touches pixels. The
; four boards are the text engine's mosaic cells -- a cell split into 2 x 3
; squares, each one of 16 tiles this client defines (tiles.inc) -- so all four
; seats show at once, every hit, miss and hull of them (board.inc).
;
; The reply window (RPLY: the cart's $E400, or a canned state in ROM when
; DEMO) is ordinary readable memory between transactions; the screens are
; drawn straight out of it, and only the name, the table id and the header
; bytes a screen keys on are copied out.
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
        INCLUDE "flags.inc"

; ---- RAM ledger ----------------------------------------------------------
; $0800-$080F the runtime's (s2macro.inc); the client's from V_APP, all on
; page $08 so RA.1 stays HI(RAMVARS) and VAR is 2 bytes; MAP at $0900; the
; stack grows down from $09FF to well above MAP's end. main clears both
; pages: nothing trusts power-on RAM.
V_REQ   EQU     V_APP+00H       ; the request bldurl builds: REQ_*
V_SHOT  EQU     V_APP+01H       ; the square /attack sends
V_AVL   EQU     V_APP+02H       ; 2: STATUS bytes waiting, lo hi
V_PRV   EQU     V_APP+04H       ; 2: the reading before
V_MIN   EQU     V_APP+06H       ; 2: settle until at least this much
V_CAP   EQU     V_APP+08H       ; 2: READ at most this much
V_RXL   EQU     V_APP+0AH       ; 2: reply length, taken right after READ
V_TRY   EQU     V_APP+0CH       ; settle polls left
V_KLAT  EQU     V_APP+0DH       ; a key pressed while a transaction ran
V_OK    EQU     V_APP+0EH       ; 1: the window holds a validated state
V_SEAT  EQU     V_APP+0FH       ; 1: seated at V_TABLE
V_NAME  EQU     V_APP+10H       ; 9: player name, NUL-terminated
V_TABLE EQU     V_APP+19H       ; 9: table id, NUL-terminated
V_PC    EQU     V_APP+22H       ; this state: playerCount
V_ST    EQU     V_APP+23H       ; status (ST_*)
V_PST   EQU     V_APP+24H       ; our playerStatus (PS_*)
V_ACT   EQU     V_APP+25H       ; activePlayer, $FF nobody
V_PACT  EQU     V_APP+26H       ; activePlayer at the poll before
V_LAP   EQU     V_APP+27H       ; lastAttackPos
V_PRST  EQU     V_APP+28H       ; the status the last result cue was for
V_PRLAP EQU     V_APP+29H       ; and its lastAttackPos
V_CLK   EQU     V_APP+2AH       ; the move clock, seconds
V_CLKT  EQU     V_APP+2BH       ; RE.0 of its last tick
V_MODE  EQU     V_APP+2CH       ; what the keys do: M_*
V_SCR   EQU     V_APP+2DH       ; the screen on display: SC_*
V_IVL   EQU     V_APP+2EH       ; frames the game waits before the next poll
V_T0    EQU     V_APP+2FH       ; RE.0 a wait began
V_ROW   EQU     V_APP+30H       ; render loop row
V_NTBL  EQU     V_APP+31H       ; tables listed (at most 8)
V_EDX   EQU     V_APP+32H       ; name editor cursor column
V_EDY   EQU     V_APP+33H       ; and row
V_EDLEN EQU     V_APP+34H       ; characters typed
V_EDBUF EQU     V_APP+35H       ; 9: the name being typed
V_DIGS  EQU     V_APP+3EH       ; 5: a number, ASCII, leading blanks
V_ERRC  EQU     V_APP+43H       ; the failure code on screen
V_CTR   EQU     V_APP+44H       ; scratch counter
V_CX    EQU     V_APP+45H       ; the aiming cursor's column, 0-9
V_CY    EQU     V_APP+46H       ; and row
V_BLNK  EQU     V_APP+47H       ; blink phase, 0 or 1
V_BLT   EQU     V_APP+48H       ; RE.0 of the last blink
V_BSEAT EQU     V_APP+49H       ; the board being drawn: its seat
V_BTR   EQU     V_APP+4AH       ; its text row, 0-3
V_BK    EQU     V_APP+4BH       ; the third of that row, 0-2
V_BGF   EQU     V_APP+4CH       ; 2: its gamefield (hi, lo), or ZEROS
V_BPIP  EQU     V_APP+4EH       ; 2: its shipsLeft (hi, lo), or ONES
V_BMH   EQU     V_APP+50H       ; HI(MAP), or HI(ZEROS) for no marks
V_BUF   EQU     V_APP+51H       ; 15: a board row's mosaic parameters
V_PSHIP EQU     V_APP+60H       ; the ship being placed, 0-4; 5 all kept
V_SX    EQU     V_APP+61H       ; 5: each ship's column
V_SY    EQU     V_APP+66H       ; 5: row
V_SD    EQU     V_APP+6BH       ; 5: direction, 0 across, 1 down
V_RND   EQU     V_APP+70H       ; 2: the LFSR (hi, lo)
V_TRIES EQU     V_APP+72H       ; placement roll attempts
V_WIN   EQU     V_APP+73H       ; the winner's seat at game over, else $FF
V_KTM   EQU     V_APP+74H       ; RE.0 a held key repeats next
V_PLOK  EQU     V_APP+75H       ; 1: this placement has been set up
V_MX    EQU     V_APP+76H       ; a ship for the MAP routines: column
V_MY    EQU     V_APP+77H       ; row
V_MD    EQU     V_APP+78H       ; direction
V_ML    EQU     V_APP+79H       ; length
V_MT    EQU     V_APP+7AH       ; the tile to mark it with
V_MBAD  EQU     V_APP+7BH       ; 1: the last T_PLC mark lay on another ship
V_FLOOR EQU     V_APP+7CH       ; 2: the next poll's settle minimum (lo, hi)
V_PSUM  EQU     V_APP+7EH       ; the lobby prompt's checksum
V_OLDY  EQU     V_APP+7FH       ; the cursor row before a move
V_END   EQU     V_APP+80H

        IF      HI(V_END) <> HI(RAMVARS)
        ERROR   "RAM ledger runs off page $08"
        ENDIF

MAP     EQU     0900H           ; 100: a tile to OR into each square (board.inc)

; The reply: the cart's window, or the canned state DEMO builds into ROM.
; Page-aligned either way: rpeek takes offsets below 256 as one byte.
        IF      DEMO
RPLY    EQU     DEMOREP
        ELSE
RPLY    EQU     FN_REPLY
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

; ---- $0C00-$0FFF: start-up, the tiles, the drawing helpers ----------------
        ORG     0C00H
        FIT     64
main:   LDI     HI(RAMVARS)
        PHI     RA
        LDR     R8, MAP+0FFH            ; clear both pages, the stack's too:
        SEX     R8                      ; nothing has been pushed yet
mclr:   LDI     0
        STXD
        GHI     R8
        XRI     HI(RAMVARS)-1
        BNZ     mclr
        SEX     R2
        GLO     RE                      ; a seed; key timing stirs it later
        ORI     1
        PUTV    V_RND+1
        FCALL   tinit
        IF      DEMO
        FJMP    st_demo
        ELSE
        FCALL   fn_chk
        BDF     mgo
        FCALL   d_cls
        PUTS    40H, s_nocart
mhalt:  BR      mhalt
mgo:    FJMP    st_start
        ENDIF

        INCLUDE "tiles.inc"
        INCLUDE "ui.inc"
        SEGEND  1000H

; ---- $1400-$1FFF: the network, the name ----------------------------------
        ORG     1400H
        INCLUDE "net.inc"
        INCLUDE "url.inc"
        INCLUDE "nament.inc"
        SEGEND  2000H

; ---- $2400-$2FFF: the lobby, the menu, the waiting room -------------------
        ORG     2400H
        INCLUDE "lobby.inc"
        INCLUDE "menu.inc"
        INCLUDE "wait.inc"
        SEGEND  3000H

; ---- $3400-$3FFF: the table ------------------------------------------------
        ORG     3400H
        INCLUDE "game.inc"
        SEGEND  4000H

; ---- $4400-$4FFF: the boards -----------------------------------------------
        ORG     4400H
        INCLUDE "board.inc"
        SEGEND  5000H

; ---- $5400-$5FFF: placing the fleet, aiming --------------------------------
        ORG     5400H
        INCLUDE "place.inc"
        INCLUDE "target.inc"
        SEGEND  6000H

; ---- $6400-$6FFF: text ------------------------------------------------------
        ORG     6400H
        INCLUDE "strings.inc"
        INCLUDE "endpoint.inc"
        SEGEND  7000H

        IF      DEMO
; ---- $7400-$75FF: the canned state (tools/mkdemo.py) -----------------------
        ORG     7400H
        INCLUDE "demo.inc"
        SEGEND  8000H
        ENDIF

        S2CLAIM
