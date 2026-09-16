; layout.asm -- the board screen, with no network at all.
;
; A flat 4K image whose playfield tables are BAKED INTO THE ROM at $1800+:
; the cartridge serves the image's own bytes there at power-on, so four
; composed boards are on screen before a single blit has run. It exists
; because the board kernel is the one component of this port with no template
; anywhere: the line-multiplexed colours, the abutting halves, the divider
; and the 262-line frame all have to be right before any of them is worth
; debugging over a socket.
;
; tools/mklayout.py writes the tables (build/layoutpf.inc) from a picture;
; tools/pfcheck.py reads a snapshot back against the same picture. SELECT
; flips between the four-quadrant layout and the two-player one; the stick
; walks a cursor with FB_PFCEL, which exercises the cartridge's transform and
; the FNBLIT wait with nothing else in the way.
;
;   ./build.sh layout && SLOT=fujinet ./run.sh layout shot

        CPU     6502
        INCLUDE "vcs.inc"
        INCLUDE "fujinet.inc"
        INCLUDE "bsdefs.inc"
BSBANK  EQU     BANKGAM
BSHASINP EQU    1               ; the switches pick the layout
BSHASUI EQU     0               ; the tables are baked in: no reply window
BSHASED EQU     0
BSHASNET EQU    0
BSHASCLS EQU    0
BSHASSTR EQU    1
BSHASRPL EQU    0
BSHASDEC EQU    0
; No build/tail.inc here: this ROM assembles the tail body itself at the
; bottom of the file, so the labels are the real thing.

        ORG     $1000

START:  sei
        cld
        ldx     #$FF
        txs
        lda     #0
LCLR:   sta     $00,x           ; $00-$7F is the TIA, $80-$FF is RAM
        dex
        bne     LCLR
        sta     $00

        lda     #2
        sta     VBLANK
        jsr     FNARM
        jsr     FNCHK
        beq     LGOT
        lda     #CRED           ; no cartridge: a red screen is the message
        sta     COLUBK
LHALT:  jmp     LHALT

LGOT:   lda     #1
        sta     BSMODE
        lda     #4
        sta     BSCURX
        lda     #3
        sta     BSCURY
        jsr     DINIT
        jsr     LTEXT
        lda     #0
        sta     VBLANK
        jmp     DFRESH

; ---------------------------------------------------------------------------
; The text rows: a status line, two name rows, and the two-player lower rows.
LTEXT:  ldx     #0
LT1:    stx     BSIDX
        lda     LROWS,x
        jsr     FNROWA
        lda     BSIDX
        asl     a
        asl     a
        asl     a
        asl     a               ; sixteen bytes a row
        tax
        ldy     #FNTCOL
LT2:    lda     LSTR,x
        jsr     FNCHR
        inx
        dey
        bne     LT2
        jsr     FNENDW
        ldx     BSIDX
        inx
        cpx     #NLROWS
        bne     LT1
        rts

NLROWS  EQU     9
LROWS:  DB      RSTAT, RLABA, RLABB, 15, 16, 17, 18, 19, 20
LSTR:   DB      "YOUR TURN 45    "
        DB      "  BOB  *CAROL   "
        DB      "  YOU   DAVE    "
        DB      "SANK BOB'S      "
        DB      "DESTROYER       "
        DB      "                "
        DB      "YOU  #####      "
        DB      "BOB  ##=#=      "
        DB      "FIRE=ATTACK     "

; ---------------------------------------------------------------------------
; APPVBL -- SELECT flips the layout; the stick moves the cursor on slot 0,
; which is the top-left board in both layouts.
APPVBL: jsr     INSCAN
        sta     BSINP
        and     #IN_SEL
        beq     AV1
        lda     BSMODE
        eor     #1
        sta     BSMODE
AV1:    lda     BSINP
        and     #INDIRS
        beq     AVX
        pha
        jsr     CURSET          ; take the old cursor off
        pla
        lsr     a
        bcc     AV2             ; up
        lda     BSCURY
        beq     AV5
        dec     BSCURY
        jmp     AV5
AV2:    lsr     a
        bcc     AV3             ; down
        lda     BSCURY
        cmp     #BRDDIM-1
        bcs     AV5
        inc     BSCURY
        jmp     AV5
AV3:    lsr     a
        bcc     AV4             ; left
        lda     BSCURX
        beq     AV5
        dec     BSCURX
        jmp     AV5
AV4:    lda     BSCURX          ; right
        cmp     #BRDDIM-1
        bcs     AV5
        inc     BSCURX
AV5:    jmp     CURSET2
AVX:    rts

; CURSET -- clear the AUX bits of the cursor cell on slot 0; CURSET2 sets
; them. One blit each: src low = the mask, dst = the slot, cnt = the cell.
CURSET: lda     #PFM_AUX|PFM_CLR
        jmp     CURS1
CURSET2: lda    #PFM_AUX
CURS1:  pha
        jsr     CELLNO
        tay
        pla
        ldx     #SLTL
        jsr     FNBARG
        lda     #FB_PFCEL
        jmp     FNBLIT

        INCLUDE "bslib.inc"
        INCLUDE "state.inc"
        INCLUDE "dispgame.inc"

; The boards, from tools/mklayout.py.
        INCLUDE "../build/layoutpf.inc"

        INCLUDE "bscore.inc"

        END
