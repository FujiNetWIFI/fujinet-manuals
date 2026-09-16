; appkey.asm -- read the shared FujiNet username, then write a key of our
; own and read it back.
;
; An appkey is a small file on the adapter's SD card, named by a creator id,
; an application id and a key number. Creator 1, app 1, key 0 is the slot
; every FujiNet game reads the player's name from. This client shows it, then
; writes "HELLO 2600" into creator $2600 / app 1 / key 0 and reads that back.
;
; OPEN_APPKEY's payload is ONE six-byte packed struct -- creator (u16, little-
; endian), app, key, mode, and a reserved byte that is not optional -- not
; four parameters. READ_APPKEY's reply is a two-byte length and then the
; value. WRITE_APPKEY takes one parameter, the length, then the bytes.

        CPU     6502
        INCLUDE "vcs.inc"

PAD3    EQU     $81
SAVSP   EQU     $82
APERR   EQU     $8F             ; what went wrong, if anything
APSTEP  EQU     $90             ; which step
AKCRL   EQU     $91             ; the key being opened: creator lo, hi...
AKCRH   EQU     $92
AKKEYN  EQU     $93             ; ...key number...
AKMODE  EQU     $94             ; ...and mode (AKMRD / AKMWR)

        INCLUDE "fujinet.inc"
        INCLUDE "devdefs.inc"

OURCRE  EQU     $2600           ; our creator id: the console's name
OURKEY  EQU     0

        ORG     $1000

START:  sei
        cld
        ldx     #$FF
        txs
        lda     #0
CLRLP:  sta     $00,x
        dex
        bne     CLRLP
        sta     $00
        lda     #2
        sta     VBLANK
        lda     #0
        sta     APERR
        sta     APSTEP

        jsr     FNARM
        jsr     FNCHK
        beq     GOTCART
        lda     #FNENOC
        sta     APERR
        jmp     SHOW

; ---------------- the shared username: creator 1, app 1, key 0 ----------------
GOTCART:
        lda     #(TNAME)&$FF
        sta     FNPTRL
        lda     #(TNAME)>>8
        sta     FNPTRH
        lda     #2
        jsr     FNRSTR
        lda     #AKCREAT
        sta     AKCRL
        lda     #0
        sta     AKCRH
        lda     #AKKEY
        sta     AKKEYN
        lda     #AKMRD
        sta     AKMODE
        jsr     AKOPEN
        jsr     AKREAD
        lda     #3
        jsr     AKSHOW

; ---------------- write our own key, then read it back ----------------
        lda     #(TOURS)&$FF
        sta     FNPTRL
        lda     #(TOURS)>>8
        sta     FNPTRH
        lda     #6
        jsr     FNRSTR
        lda     #(OURCRE)&$FF
        sta     AKCRL
        lda     #(OURCRE)>>8
        sta     AKCRH
        lda     #OURKEY
        sta     AKKEYN
        lda     #AKMWR
        sta     AKMODE
        jsr     AKOPEN
        jsr     AKWRITE
        lda     #AKMRD
        sta     AKMODE
        jsr     AKOPEN
        jsr     AKREAD
        lda     #7
        jsr     AKSHOW
        lda     #0
        sta     APERR

SHOW:   lda     #(TTITLE)&$FF
        sta     FNPTRL
        lda     #(TTITLE)>>8
        sta     FNPTRH
        lda     #0
        jsr     FNRSTR
        lda     APERR
        beq     RUN
        lda     #10
        jsr     FNROWA
        lda     #'S'
        sta     FNRSEL+FH_TCHR
        lda     APSTEP
        jsr     FNHEX
        lda     #' '
        sta     FNRSEL+FH_TCHR
        lda     #'E'
        sta     FNRSEL+FH_TCHR
        lda     APERR
        jsr     FNHEX
        jsr     FNENDR
RUN:    lda     #0
        sta     VBLANK
        jsr     DINIT
        jmp     DLOOP

; AKOPEN -- OPEN_APPKEY for the key in AKCRL/AKCRH/AKKEYN, mode AKMODE.
AKOPEN: inc     APSTEP
        lda     #FNDEVF
        sta     FNDEV
        lda     #FNCAKOP
        sta     FNCMD
        lda     #0
        sta     FNNPR
        jsr     FNBEG
        lda     AKCRL           ; the six-byte struct, as the payload
        sta     FNTX
        lda     AKCRH
        sta     FNTX
        lda     #AKAPP
        sta     FNTX
        lda     AKKEYN
        sta     FNTX
        lda     AKMODE
        sta     FNTX
        lda     #0
        sta     FNTX            ; reserved, and not optional
        jmp     NGOACK

; AKREAD -- READ_APPKEY. The value is left in the reply window: two bytes
; of length, then the bytes.
AKREAD: inc     APSTEP
        lda     #FNDEVF
        sta     FNDEV
        lda     #FNCAKRD
        sta     FNCMD
        lda     #0
        sta     FNNPR
        jsr     FNBEG
        jmp     NGOACK

; AKWRITE -- WRITE_APPKEY: one parameter, the length, then the value.
AKWRITE: inc    APSTEP
        lda     #FNDEVF
        sta     FNDEV
        lda     #FNCAKWR
        sta     FNCMD
        lda     #1
        sta     FNNPR
        jsr     FNBEG
        lda     #TVALE-TVAL
        jsr     FNPB
        ldy     #0
AKW1:   lda     TVAL,y
        sta     FNTX
        iny
        cpy     #TVALE-TVAL
        bne     AKW1
        jmp     NGOACK

; AKSHOW -- the value just read, into text row A; "(EMPTY)" if none.
AKSHOW: pha
        lda     FNRPLY+0
        ora     FNRPLY+1
        bne     AKSH1
        pla
        pha
        lda     #(TEMPTY)&$FF
        sta     FNPTRL
        lda     #(TEMPTY)>>8
        sta     FNPTRH
        pla
        jmp     FNRSTR
AKSH1:  pla
        ldx     #2              ; the value starts after the length word
        ldy     #FNTCOL
        jmp     FNRRPL

; NGOACK -- commit and wait, then check the ACK; on failure, straight to SHOW.
NGOACK: jsr     FNGO
        sta     APERR
        bne     NGOA1
        jsr     FNACK
        sta     APERR
        beq     NGOA2
NGOA1:  pla
        pla
        jmp     SHOW
NGOA2:  rts

TTITLE: DB      "APPKEYS",0
TNAME:  DB      "USERNAME",0
TOURS:  DB      "KEY 2600:1:0",0
TEMPTY: DB      "(EMPTY)",0
TVAL:   DB      "HELLO 2600"
TVALE:

        INCLUDE "fujilib.inc"
APPVBL: rts
        INCLUDE "fujidisp.inc"

        ORG     $1FFC
        DW      START
        DW      START
        END
