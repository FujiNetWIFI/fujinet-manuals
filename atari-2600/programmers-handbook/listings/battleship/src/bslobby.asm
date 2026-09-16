; bslobby.asm -- bank 0: the cold start and the table list.
;
; Bank 0 by construction: the cold stub in the fixed tail sends the console
; here, because it is the only bank whose number the stub can know before
; anything has run.

        CPU     6502
        INCLUDE "vcs.inc"
        INCLUDE "fujinet.inc"
        INCLUDE "bsdefs.inc"

BSBANK  EQU     BANKLOB
BSHASINP EQU    1
BSHASUI EQU     0               ; it lists tables, not player records
BSHASED EQU     1               ; it writes the joined table's id into a
                                ;   cartridge path buffer
BSHASNET EQU    0               ; BANKNET fetches for it
BSHASCLS EQU    1
BSHASSTR EQU    1
BSHASRPL EQU    0
BSHASDEC EQU    0

        INCLUDE "../build/tail.inc"

RLTITL  EQU     0
RLIST0  EQU     3
RLSEAT  EQU     15
RLFOOT  EQU     19

        ORG     $1000

; ---------------------------------------------------------------------------
LENTRY: lda     #2
        sta     VBLANK
        lda     BSENT
        cmp     #ENCOLD
        beq     LCOLD
        jmp     LWARM

; ---------------------------------------------------------------------------
; The cold start proper. The stub in the tail does only what has to be done
; from an address every bank can see -- the arming pair and the bank switch --
; because the tail is 220 bytes and the shared transport wants 160 of them.
;
; EVERY TIA REGISTER IS CLEARED, not just RAM: RESMP1's power-on state on
; real silicon is undefined, and set it locks the divider missile to its
; player and never draws it -- an emulator starts it at zero and would never
; show the difference.
LCOLD:  ldx     #$FF
        txs
        lda     #0
LCL1:   sta     $00,x           ; $00-$7F is the TIA, $80-$FF is RAM
        dex
        bne     LCL1
        sta     $00
        lda     #2
        sta     VBLANK

; THE CARTRIDGE'S PATH BUFFERS SURVIVE A CONSOLE RESET -- there is no reset
; line on this connector and the cart never sees the switch -- so a client
; that assumes they are empty comes back from a RESET with the last session's
; player name still in its URLs. Empty all four and leave a known one
; selected.
        ldx     #FP_SEL3
LCL2:   txa
        sta     FNRSEL+FH_PATHO
        lda     #FP_RST
        sta     FNRSEL+FH_PATHO
        dex
        cpx     #FP_SEL0-1
        bne     LCL2

        jsr     FNARM           ; harmless twice, and cheap insurance
        jsr     FNCHK
        beq     LGOT
; No cartridge means no character generator either, so there is nothing to say
; it with. A red screen is the whole message.
        lda     #CRED
        sta     COLUBK
        lda     #0
        sta     VBLANK
LHALT:  jmp     LHALT

LGOT:   jsr     DINIT
        jsr     FNCLS
        lda     #ENNAME
        sta     BSENT
        lda     #BANKNAM
        jmp     BSGOTO

; ---------------------------------------------------------------------------
; Back from a /tables fetch, or from a redraw.
; THE TEXT PLANES SURVIVE A BANK SWITCH. Coming back here from a table
; without clearing would leave the game's rows showing under the lobby's
; title and footer -- and the lobby paints only the rows it uses.
LWARM:  jsr     DINIT
        jsr     FNCLS
        lda     #0
        sta     BSSEL
        jsr     LDRAW           ; the WHOLE list. LDSEL is the cursor only and
                                ;   FNCLS above has just blanked every row.
        lda     #0
        sta     VBLANK
        jmp     DFRESH

; ---------------------------------------------------------------------------
APPVBL: jsr     INREPT
        sta     BSINP
        and     #IN_UP
        beq     LAV1
        lda     BSSEL
        beq     LAV1
        dec     BSSEL
        jsr     LDSEL
LAV1:   lda     BSINP
        and     #IN_DOWN
        beq     LAV2
        lda     BSSEL
        clc
        adc     #1
        cmp     BSCNT
        bcs     LAV2
        sta     BSSEL
        jsr     LDSEL
LAV2:   lda     BSINP
        and     #IN_RIGHT
        beq     LAV3
        lda     #ENTABLE        ; list again
        sta     BSENT
        lda     #BANKNET
        jmp     BSGOTO
LAV3:   lda     BSINP
        and     #IN_SEL
        beq     LAV4
        lda     #ENNAME         ; change the name
        sta     BSENT
        lda     #BANKNAM
        jmp     BSGOTO
LAV4:   lda     BSINP
        and     #IN_FIRE
        beq     LAV5
        lda     BSCNT
        beq     LAV5
        jmp     LJOIN
LAV5:   rts

; ---------------------------------------------------------------------------
; LJOIN -- take the selected table's id into path buffer 0 and sit down.
;
; This is one of exactly two strings this client copies out of a reply, and it
; goes into the CARTRIDGE, not into console RAM: it has to survive every
; /state poll after it, and each poll repaints the window it came from.
;
; The field is fixed-width and space-padded, so it is pushed up to its NUL and
; never through it -- padding in the middle of a URL corrupts the request.
; Joining a table is not a call: retrieving the state for one IS the join,
; and that is the game bank's first poll.
LJOIN:  lda     #PBTABLE
        jsr     FNWSEL
        jsr     FNWRST
        jsr     LTBPTR          ; FNPTRL/H -> the record
        ldy     #TBID
        ldx     #9
LJ1:    lda     (FNPTRL),y
        beq     LJ2
        cmp     #' '
        beq     LJ2
        sta     FNRSEL+FH_PATHC
        iny
        dex
        bne     LJ1
LJ2:    lda     #ENGCOLD
        sta     BSENT
        lda     #BANKGAM
        jmp     BSGOTO

; LTBPTR -- FNPTRL/H points at table BSSEL's record; LTBPTR2 at table
; BSIDX's, for the row being drawn.
;
; The records start at offset ONE, after the count byte, and are 36 bytes
; apart -- so the eighth one is past 256 and this has to be a pointer.
; Dividing the reply length by the stride to get the count looks equivalent
; to reading that first byte and is not: 181 bytes is 1 + 5*36, and the
; division says 5 only by accident of rounding.
LTBPTR: ldx     BSSEL
        jmp     LTB0
LTBPTR2: ldx    BSIDX
LTB0:   lda     #(FNRPLY+1)&$FF
        sta     FNPTRL
        lda     #(FNRPLY+1)>>8
        sta     FNPTRH
        cpx     #0
        beq     LTB2
LTB1:   lda     FNPTRL
        clc
        adc     #TBSTRID
        sta     FNPTRL
        bcc     LTB1A
        inc     FNPTRH
LTB1A:  dex
        bne     LTB1
LTB2:   rts

; ---------------------------------------------------------------------------
; LDRAW -- the whole lobby.
LDRAW:  lda     #RLTITL
        jsr     FNROWA
        ldx     #(LSTITL)&$FF
        ldy     #(LSTITL)>>8
        jsr     FNSETP
        jsr     FNSTRA
        jsr     FNENDW

        lda     BSCNT
        bne     LD1
; An empty list is a real answer, not a failure. Say so and offer the retry.
        lda     #RLIST0
        jsr     FNROWA
        ldx     #(LSNONE)&$FF
        ldy     #(LSNONE)>>8
        jsr     FNSETP
        jsr     FNSTRA
        jsr     FNENDW
        lda     #$FF
        sta     BSBAR
        jmp     LDFOOT

LD1:    lda     #0
        sta     BSIDX
LD2:    lda     BSIDX
        clc
        adc     #RLIST0
        jsr     FNROWA
        lda     BSIDX
        cmp     BSCNT
        bcs     LDBLK
        ; the row is the table's name, twelve of the twenty-one bytes it sends
        jsr     LTBPTR2
        ldy     #TBNAME
        ldx     #FNTCOL
LD3:    lda     (FNPTRL),y
        beq     LD4
        sta     FNRSEL+FH_TCHR
        iny
        dex
        bne     LD3
        jmp     LD5
LD4:    lda     #' '
        sta     FNRSEL+FH_TCHR
        dex
        bne     LD4
LD5:    jsr     FNENDW
        jmp     LDNXT
LDBLK:  lda     #FNTCOL
        jsr     FNSPC
        jsr     FNENDW
LDNXT:  inc     BSIDX
        lda     BSIDX
        cmp     #MAXTBL
        bne     LD2

        jsr     LDSEL

LDFOOT: lda     #RLFOOT
        jsr     FNROWA
        ldx     #(LSFOOT)&$FF
        ldy     #(LSFOOT)>>8
        jsr     FNSETP
        jsr     FNSTRA
        jmp     FNENDW

; ---------------------------------------------------------------------------
; LDSEL -- the cursor moved, and NOTHING ELSE DID: the bar, and the seat
; count of the selected table. Redrawing the whole list for a cursor key is
; about 3,800 cycles against a vblank budget of 2,812, and the overrun pushes
; the picture down the screen for a frame -- the list bounced on every press.
;
; The cursor is a whole-row red bar: there is no inverse video and no
; per-cell colour on this machine. The kernel reads BSBAR on its seam line,
; so moving the bar really is just the store.
LDSEL:  lda     BSSEL
        clc
        adc     #RLIST0
        sta     BSBAR

; The seat count the server pre-formats as "cur / max". It is a literal
; string, not two numbers, so it is printed verbatim.
        lda     #RLSEAT
        jsr     FNROWA
        ldx     #(LSSEAT)&$FF
        ldy     #(LSSEAT)>>8
        jsr     FNSETP
        jsr     FNSTRA
        jsr     LTBPTR
        ldy     #TBPLYRS
        ldx     #6
LD6:    lda     (FNPTRL),y
        beq     LD7
        sta     FNRSEL+FH_TCHR
        iny
        dex
        bne     LD6
LD7:    jmp     FNENDW

LSTITL: DB      "BATTLESHIP",0
LSNONE: DB      "NO TABLES",0
LSSEAT: DB      "SEATS ",0
LSFOOT: DB      "FIRE JOINS",0

; The lobby is a list, so its rows are plain.
BSBGT:  DB      CBLACK,CBLACK,CBLACK,CBLACK,CBLACK,CBLACK
        DB      CBLACK,CBLACK,CBLACK,CBLACK,CBLACK,CBLACK
        DB      CBLACK,CBLACK,CBLACK,CBLACK,CBLACK,CBLACK
        DB      CBLACK,CBLACK,CBLACK
        DB      CWATER                  ; row 21: back to the sea

        INCLUDE "bslib.inc"
        INCLUDE "state.inc"
        INCLUDE "disptext.inc"

        END
