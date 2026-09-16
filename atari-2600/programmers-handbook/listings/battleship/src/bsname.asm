; bsname.asm -- bank 4: who you are.
;
; The shared FujiNet username lives in an appkey -- creator 1, app 1, key 0 --
; and every game in the family reads the same slot, which is the point of it.
; Read it, and if it is empty type one.
;
; The name never lands in console RAM. It goes straight from the appkey reply
; into a cartridge path buffer, and from there into every URL: 128 bytes of
; RAM, of which the stack owns the top, cannot hold nine bytes it does not
; have to.

        CPU     6502
        INCLUDE "vcs.inc"
        INCLUDE "fujinet.inc"
        INCLUDE "bsdefs.inc"

BSBANK  EQU     BANKNAM
BSHASINP EQU    1
BSHASUI EQU     0               ; the keyboard reads no player record
BSHASED EQU     1
BSHASNET EQU    0               ; appkeys are FUJI device calls, not N:
BSHASCLS EQU    1
BSHASSTR EQU    1
BSHASRPL EQU    0
BSHASDEC EQU    0

        INCLUDE "../build/tail.inc"

; The keyboard's grid: three rows of twelve, which is A-Z and 0-9 exactly,
; then a row of three control cells. Twelve columns will not hold a
; conventional four-by-sixteen keyboard, and 36 is the number that comes out
; even.
KGRIDW  EQU     12
KGRIDH  EQU     3
KCELLS  EQU     KGRIDW*KGRIDH
KOK     EQU     KCELLS+0
KDEL    EQU     KCELLS+1
KSPC    EQU     KCELLS+2
KLAST   EQU     KCELLS+2

RNTITL  EQU     0
RNNAME  EQU     3
RNGRID  EQU     6               ; three rows: 6, 7, 8
RNCTRL  EQU     11
RNPICK  EQU     14
RNFOOT  EQU     19

        ORG     $1000

NMENTRY: lda    #2
        sta     VBLANK
        jsr     DINIT
        jsr     FNCLS

; Ask the cartridge's adapter for the shared username.
        jsr     AKREAD
        bne     NMEDIT          ; no appkey, or an empty one: type it
        lda     #0
        sta     VBLANK
        jmp     NMDONE

; ---------------------------------------------------------------------------
; The keyboard.
NMEDIT: lda     #0
        sta     BSSEL
        sta     BSNLEN
        lda     #PBNAME
        jsr     FNWSEL
        jsr     FNWRST
        jsr     NMDRAW
        lda     #0
        sta     VBLANK
        jmp     DFRESH

APPVBL: jsr     INREPT
        sta     BSINP
        and     #IN_LEFT
        beq     NAV1
        lda     BSSEL
        beq     NAV1
        dec     BSSEL
        jsr     NMDRAW
NAV1:   lda     BSINP
        and     #IN_RIGHT
        beq     NAV2
        lda     BSSEL
        cmp     #KLAST
        bcs     NAV2
        inc     BSSEL
        jsr     NMDRAW
NAV2:   lda     BSINP
        and     #IN_UP
        beq     NAV3
        lda     BSSEL
        sec
        sbc     #KGRIDW
        bcc     NAV3
        sta     BSSEL
        jsr     NMDRAW
NAV3:   lda     BSINP
        and     #IN_DOWN
        beq     NAV4
; DOWN out of the last grid row always lands on OK, whatever column it
; started in. The control row is three cells wide against the grid's twelve,
; so a straight +12 reaches OK, DEL or SPC depending on where you happened to
; be and nothing at all from nine of the twelve columns -- which reads as a
; stuck cursor rather than as a boundary, and put a space on the end of a name
; that was trying to press OK.
        lda     BSSEL
        cmp     #KCELLS
        bcs     NAV4            ; already on the control row: nowhere below
        cmp     #KCELLS-KGRIDW
        bcc     NAV3B           ; not in the last grid row: a plain row step
        lda     #KOK
        jmp     NAV3A
NAV3B:  clc
        adc     #KGRIDW
NAV3A:  sta     BSSEL
        jsr     NMDRAW
NAV4:   lda     BSINP
        and     #IN_FIRE
        beq     NAV5
        jmp     NMFIRE
NAV5:   rts

; ---------------------------------------------------------------------------
NMFIRE: lda     BSSEL
        cmp     #KOK
        beq     NMOK
        cmp     #KDEL
        beq     NMBS
        cmp     #KSPC
        bne     NMCHR
        lda     #' '
        jmp     NMADD
NMCHR:  jsr     NMGLYPH
NMADD:  ldx     BSNLEN
        cpx     #NAMEMAX
        bcs     NMR
        sta     FNRSEL+FH_PATHC
        inc     BSNLEN
        jmp     NMDRAW
NMBS:   lda     BSNLEN
        beq     NMR
        jsr     FNWPOP
        dec     BSNLEN
        jmp     NMDRAW
NMR:    rts

; OK with nothing typed is not OK: the server would see an empty player.
NMOK:   lda     BSNLEN
        beq     NMR
        jsr     AKWRITE         ; best effort: the table works without it
NMDONE: lda     #ENTABLE
        sta     BSENT
        lda     #BANKNET
        jmp     BSGOTO

; NMGLYPH -- A = the character at grid cell BSSEL.
NMGLYPH: ldx    BSSEL
        lda     KCHARS,x
        rts

; ---------------------------------------------------------------------------
; NMDRAW -- the whole keyboard.
NMDRAW: lda     #RNTITL
        jsr     FNROWA
        ldx     #(NSTITL)&$FF
        ldy     #(NSTITL)>>8
        jsr     FNSETP
        jsr     FNSTRA
        jsr     FNENDW

; What has been typed, rendered by the CARTRIDGE out of the buffer holding it.
; The console cannot read that buffer back -- the page it is written through is
; write-only -- so FB_PATH is the only way to see it at all.
        lda     #PBNAME
        jsr     FNWSEL
        lda     #0
        sta     FNRSEL+FH_BSL
        sta     FNRSEL+FH_BSH
        sta     FNRSEL+FH_BDH
        lda     #RNNAME
        sta     FNRSEL+FH_BDL
        lda     #FNTCOL
        sta     FNRSEL+FH_BCNT
        lda     #FB_PATH
        jsr     FNBLIT

; The grid.
        lda     #0
        sta     BSIDX
NMD1:   lda     BSIDX
        clc
        adc     #RNGRID
        jsr     FNROWA
        lda     BSIDX
        asl     a
        asl     a
        sta     BSTMP           ; row * 4
        asl     a               ; row * 8
        clc
        adc     BSTMP           ; row * 12
        tax
        ldy     #KGRIDW
NMD2:   lda     KCHARS,x
        sta     FNRSEL+FH_TCHR
        inx
        dey
        bne     NMD2
        jsr     FNENDW
        inc     BSIDX
        lda     BSIDX
        cmp     #KGRIDH
        bne     NMD1

        lda     #RNCTRL
        jsr     FNROWA
        ldx     #(NSCTRL)&$FF
        ldy     #(NSCTRL)>>8
        jsr     FNSETP
        jsr     FNSTRA
        jsr     FNENDW

; The cursor. A whole-row red bar says WHICH ROW, and this row says which cell
; in it -- there is no inverse video on this machine and no per-cell colour,
; so one highlight cannot say both.
        lda     #RNPICK
        jsr     FNROWA
        lda     #'>'
        jsr     FNCHR
        lda     BSSEL
        cmp     #KCELLS
        bcs     NMD3
        jsr     NMGLYPH
        jsr     FNCHR
        lda     #'<'
        jsr     FNCHR
        jmp     NMD4
NMD3:   sec
        sbc     #KCELLS
        asl     a
        asl     a               ; four bytes a control word
        tax
        ldy     #4
NMD3A:  lda     NSCTLW,x
        sta     FNRSEL+FH_TCHR
        inx
        dey
        bne     NMD3A
NMD4:   jsr     FNENDW

; Which row the bar is on.
        lda     BSSEL
        cmp     #KCELLS
        bcc     NMD5
        lda     #RNCTRL
        sta     BSBAR
        jmp     NMD6
NMD5:   ldx     #0
NMD5A:  cmp     #KGRIDW
        bcc     NMD5B
        sec
        sbc     #KGRIDW
        inx
        jmp     NMD5A
NMD5B:  txa
        clc
        adc     #RNGRID
        sta     BSBAR
NMD6:   lda     #RNFOOT
        jsr     FNROWA
        ldx     #(NSFOOT)&$FF
        ldy     #(NSFOOT)>>8
        jsr     FNSETP
        jsr     FNSTRA
        jmp     FNENDW

; ---------------------------------------------------------------------------
; AKOPEN -- OPEN_APPKEY with mode A. Returns 0 if the adapter took it.
;
; The payload is a SIX-BYTE PACKED STRUCT and not four parameters:
; AppKeyMixin::appkey_open() does one transaction_get() of sizeof(appkey),
; which is creator as a u16, then app, key, mode and a reserved byte. The
; Intellivision port documents what happens when that last byte is left off --
; transaction_get() waits for a byte that never arrives, and it reads back as
; a timeout rather than as a protocol error.
;
; It also fails outright when no SD card is mounted on the adapter, which is
; not a client bug and is why the keyboard is the fallback rather than an
; error screen.
AKOPEN: pha
        lda     #FNDEVF
        sta     FNDEV
        lda     #FCAKOPN
        sta     FNCMD
        lda     #0
        sta     FNNPR
        jsr     FNBEG
        lda     #(AKCREAT)&$FF
        sta     FNTX
        lda     #(AKCREAT)>>8
        sta     FNTX
        lda     #AKAPP
        sta     FNTX
        lda     #AKKEY
        sta     FNTX
        pla
        sta     FNTX            ; the mode
        lda     #0
        sta     FNTX            ; reserved, and not optional
        jsr     FNGO
        bne     AKOX
        jmp     FNACK
AKOX:   rts

; AKREAD -- the shared username into path buffer 1. Z set if there was one.
;
; The name goes straight from the reply into a cartridge path buffer: 128
; bytes of console RAM, of which the stack owns the top, cannot hold nine
; bytes it does not have to.
AKREAD: lda     #AKMRD
        jsr     AKOPEN
        bne     AKBAD

        lda     #FNDEVF
        sta     FNDEV
        lda     #FCAKRD
        sta     FNCMD
        lda     #0
        sta     FNNPR
        jsr     FNBEG
        jsr     FNGO
        bne     AKBAD
        jsr     FNACK
        bne     AKBAD
; The reply is a length word and then the value.
        lda     FNRPLY+0
        ora     FNRPLY+1
        beq     AKBAD           ; the slot is empty: type one
        lda     #PBNAME
        jsr     FNWSEL
        jsr     FNWRST
        ldx     #2
        ldy     #NAMEMAX+1
        jsr     FNWRPL
        lda     #0
        rts
AKBAD:  lda     #$FF
        rts

; AKWRITE -- store what was typed, so the next FujiNet game finds it.
; Best effort: a table works perfectly well without the slot being written.
AKWRITE: lda    #AKMWR
        jsr     AKOPEN
        bne     AKWX
        lda     #FNDEVF
        sta     FNDEV
        lda     #FCAKWR
        sta     FNCMD
        lda     #1
        sta     FNNPR
        jsr     FNBEG
        lda     BSNLEN
        jsr     FNPB
        lda     #PBNAME
        jsr     FNWSEL
        jsr     FNWRAW
        jsr     FNGO
AKWX:   rts

NSTITL: DB      "YOUR NAME",0
NSCTRL: DB      "OK  DEL SPC",0
NSCTLW: DB      "OK  DEL SPC "
NSFOOT: DB      "FIRE PICKS",0
; A-Z then 0-9: thirty-six cells in three rows of twelve, which is the one
; shape that comes out even in this many columns.
KCHARS: DB      "ABCDEFGHIJKL"
        DB      "MNOPQRSTUVWX"
        DB      "YZ0123456789"

BSBGT:  DB      CBLACK,CBLACK,CBLACK,CBLACK,CBLACK,CBLACK
        DB      CBLACK,CBLACK,CBLACK,CBLACK,CBLACK,CBLACK
        DB      CBLACK,CBLACK,CBLACK,CBLACK,CBLACK,CBLACK
        DB      CBLACK,CBLACK,CBLACK
        DB      CWATER

        INCLUDE "bslib.inc"
        INCLUDE "state.inc"
        INCLUDE "disptext.inc"

        END
