; bsmenu.asm -- bank 3: the in-game menu and the help screen.
;
; Reached by the RESET switch during a game. The 2600 has one button and four
; directions and no keypad; the stick aims and FIRE shoots, SELECT polls,
; and RESET is the only labelled button going spare. It is a SWITCH on this
; console, SWCHB bit 0, which the program reads: it restarts nothing, and what
; it means is the client's to choose. RESET again backs out of here, for the
; same reason a door opens both ways.
;
; The game bank switched here from inside its vblank hook, so this bank
; finishes that frame after it has drawn the menu; the menu's rows take more
; than a vblank to compose, so that one frame runs long, once, on a screen
; change.

        CPU     6502
        INCLUDE "vcs.inc"
        INCLUDE "fujinet.inc"
        INCLUDE "bsdefs.inc"

BSBANK  EQU     BANKMNU
BSHASINP EQU    1
BSHASUI EQU     0               ; no player record is read here
BSHASED EQU     0
BSHASNET EQU    0               ; /leave is BANKNET's, like every request
BSHASCLS EQU    1
BSHASSTR EQU    1
BSHASRPL EQU    0
BSHASDEC EQU    0

        INCLUDE "../build/tail.inc"

RMTITL  EQU     0
RMITEM0 EQU     3
NMITEMS EQU     3
RMHELP0 EQU     9

MIRES   EQU     0               ; resume
MIHELP  EQU     1               ; how to play
MILEAVE EQU     2               ; leave the table

        ORG     $1000

MENTRY: jsr     DINIT
        jsr     FNCLS
        lda     #0
        sta     BSSEL
        sta     BSMHELP
        sta     AUDV0           ; whatever cue was playing
        sta     SNDPTR
        jsr     MDRAW
        jsr     DFRAME2
        jmp     DLOOP

APPVBL: jsr     INREPT
        sta     BSINP

; The help screen swallows everything but a button, which closes it.
        lda     BSMHELP
        beq     MAV0
        lda     BSINP
        and     #IN_FIRE|IN_RST
        beq     MAVR
        lda     #0
        sta     BSMHELP
        jsr     FNCLS
        jmp     MDRAW

MAV0:   lda     BSINP
        and     #IN_UP
        beq     MAV1
        lda     BSSEL
        beq     MAV1
        dec     BSSEL
        jsr     MDRAW
MAV1:   lda     BSINP
        and     #IN_DOWN
        beq     MAV2
        lda     BSSEL
        cmp     #NMITEMS-1
        bcs     MAV2
        inc     BSSEL
        jsr     MDRAW
MAV2:   lda     BSINP
        and     #IN_RST         ; RESET again backs out, as it came in
        bne     MRESUME
        lda     BSINP
        and     #IN_FIRE
        beq     MAVR
        lda     BSSEL
        cmp     #MIHELP
        beq     MHELP
        cmp     #MILEAVE
        beq     MLEAVE
; Resuming goes back to the game bank as if from a poll: it recomposes the
; boards from the reply window, which still holds the last state, and its
; poll clock is left at zero so the first frame back fetches a fresh one.
MRESUME: lda    #ENRESUME
        sta     BSENT
        lda     #0
        sta     BSERR2          ; resuming is not a failed poll
        sta     BSPOLL
        lda     #BANKCMP
        jmp     BSGOTO
MAVR:   rts

MHELP:  lda     #1
        sta     BSMHELP
        lda     #$FF
        sta     BSBAR
        jsr     FNCLS
        jmp     MDRAW

; Leaving is a request, and requests live in BANKNET. It sends /leave and goes
; on to the lobby whatever the server says: the seat is given up either way,
; and a client that refused to leave because the link hiccuped would be stuck.
MLEAVE: lda     #ENLEAVE
        sta     BSENT
        lda     #BANKNET
        jmp     BSGOTO

; ---------------------------------------------------------------------------
MDRAW:  lda     BSMHELP
        bne     MDHELP

        lda     #RMTITL
        jsr     FNROWA
        ldx     #(MSTITL)&$FF
        ldy     #(MSTITL)>>8
        jsr     FNSETP
        jsr     FNSTRA
        jsr     FNENDW

        lda     #0
        sta     BSIDX
MD1:    lda     BSIDX
        clc
        adc     #RMITEM0
        jsr     FNROWA
        lda     BSIDX
        asl     a
        asl     a
        sta     BSTMP           ; twelve bytes an item
        asl     a
        clc
        adc     BSTMP
        tax
        ldy     #FNTCOL
MD2:    lda     MSITEMS,x
        sta     FNRSEL+FH_TCHR
        inx
        dey
        bne     MD2
        jsr     FNENDW
        inc     BSIDX
        lda     BSIDX
        cmp     #NMITEMS
        bne     MD1

        lda     BSSEL
        clc
        adc     #RMITEM0
        sta     BSBAR
        rts

; The help screen: a list of rows in ROM, terminated by a zero length.
MDHELP: lda     #0
        sta     BSIDX
MDH1:   lda     BSIDX
        clc
        adc     #RMHELP0-RMHELP0
        sta     BSTMP
        lda     BSIDX
        asl     a
        asl     a
        sta     BSNUM0
        asl     a
        clc
        adc     BSNUM0          ; twelve bytes a row
        tax
        lda     MSHELP,x
        beq     MDH2            ; a zero first byte ends the list
        lda     BSIDX
        jsr     FNROWA
        ldy     #FNTCOL
MDH1A:  lda     MSHELP,x
        sta     FNRSEL+FH_TCHR
        inx
        dey
        bne     MDH1A
        jsr     FNENDW
        inc     BSIDX
        lda     BSIDX
        cmp     #FNTROW
        bne     MDH1
MDH2:   rts

MSTITL: DB      "GAME MENU",0
MSITEMS: DB     "RESUME      "
        DB      "HOW TO PLAY "
        DB      "LEAVE TABLE "
; Twelve columns a row, padded, terminated by a row that starts with a NUL.
; It exists for one sentence: A SHOT LANDS ON EVERY ENEMY AT ONCE. That is
; the rule this game does not share with the board game, and nothing on the
; play screen can teach it.
MSHELP: DB      "HOW TO PLAY "
        DB      "            "
        DB      "PLACE 5     "
        DB      "SHIPS. ONE  "
        DB      "SHOT HITS   "
        DB      "EVERY ENEMY "
        DB      "AT ONCE.    "
        DB      "LAST FLEET  "
        DB      "AFLOAT WINS."
        DB      "            "
        DB      "STICK AIMS  "
        DB      "FIRE SHOOTS "
        DB      "SEL TURNS A "
        DB      "SHIP, POLLS "
        DB      "RESET  MENU "
        DB      "            "
        DB      "GOLD  YOURS "
        DB      "RED   HIT   "
        DB      "WHITE MISS  "
        DB      "            "
        DB      "FIRE CLOSES "
        DB      0

BSBGT:  DB      CBLACK,CBLACK,CBLACK,CBLACK,CBLACK,CBLACK
        DB      CBLACK,CBLACK,CBLACK,CBLACK,CBLACK,CBLACK
        DB      CBLACK,CBLACK,CBLACK,CBLACK,CBLACK,CBLACK
        DB      CBLACK,CBLACK,CBLACK
        DB      CWATER

        INCLUDE "bslib.inc"
        INCLUDE "state.inc"
        INCLUDE "disptext.inc"

        END
