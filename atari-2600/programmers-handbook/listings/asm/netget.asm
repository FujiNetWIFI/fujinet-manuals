; netget.asm -- fetch a URL through the N: device and show the text.
;
; OPEN the devicespec as an HTTP GET, STATUS until the byte count settles,
; READ up to 228 bytes -- nineteen rows of twelve -- into the reply window,
; then stream the reply into text rows a line at a time: LF ends a row, CR is
; skipped, a row is at most twelve characters. Then CLOSE. Nothing of the
; reply ever lands in console RAM: the cartridge holds it and the cartridge
; composes it, and the console's part is a cursor and a row number.
;
; The transaction runs before the display starts, with the screen blanked, as
; fujitest.asm does; a client that wants to keep a picture up while it talks
; does its transactions from inside the frame loop, which Battleship shows.

        CPU     6502
        INCLUDE "vcs.inc"

; ---------------- zero page ----------------
PAD3    EQU     $81             ; the display kernel's 3-cycle pad target
SAVSP   EQU     $82             ; stack pointer, parked across the kernel
APERR   EQU     $8F             ; what went wrong, if anything
NAVLO   EQU     $90             ; bytes waiting, from STATUS
NAVHI   EQU     $91
NPRLO   EQU     $92             ; the previous STATUS reading
NPRHI   EQU     $93
NSRC    EQU     $94             ; the reply cursor
NROW    EQU     $95             ; the text row being composed
NCOL    EQU     $96             ; characters in it so far
NTRY    EQU     $97             ; STATUS readings taken

        INCLUDE "fujinet.inc"
        INCLUDE "netdefs.inc"

NMAX    EQU     228             ; nineteen rows of twelve: rows 2-20
NROW0   EQU     2               ; the first text row of the reply
NTRIES  EQU     30              ; STATUS readings before giving up

        ORG     $1000

; ---------------- cold start ----------------
START:  sei
        cld
        ldx     #$FF
        txs
        lda     #0
CLRLP:  sta     $00,x           ; $00-$7F is the TIA, $80-$FF is RAM
        dex
        bne     CLRLP
        sta     $00

        lda     #2              ; keep the screen blanked while we talk
        sta     VBLANK
        lda     #0
        sta     APERR

        jsr     FNARM           ; open the decode gate
        jsr     FNCHK
        beq     GOTCART
        lda     #FNENOC         ; no cartridge is answering
        sta     APERR
        jmp     SHOW

; ---------------- OPEN ----------------
; Two one-byte parameters -- the mode and the translation -- then the
; devicespec as the payload, streamed a byte at a time from ROM.
GOTCART:
        lda     #NETDEV
        sta     FNDEV
        lda     #NCOPEN
        sta     FNCMD
        lda     #2
        sta     FNNPR
        jsr     FNBEG
        lda     #NMHTTPG
        jsr     FNPB
        lda     #NTRNONE
        jsr     FNPB
        ldy     #0
NURL:   lda     TURL,y
        beq     NURLE
        sta     FNTX
        iny
        bne     NURL
NURLE:  jsr     NGOACK

; ---------------- STATUS, until it settles ----------------
; The adapter reports STATUS as soon as SOME of the response has arrived, so
; one reading can be a fraction of the page. Take readings until two agree
; and the count is not zero.
        lda     #$FF
        sta     NPRLO
        sta     NPRHI
        lda     #0
        sta     NTRY
NSTAT:  lda     #NETDEV
        sta     FNDEV
        lda     #NCSTAT
        sta     FNCMD
        lda     #2
        sta     FNNPR
        jsr     FNBEG
        lda     #0
        jsr     FNPB
        lda     #0
        jsr     FNPB
        jsr     NGOACK
        lda     FNRPLY+NSAVLO
        sta     NAVLO
        lda     FNRPLY+NSAVHI
        sta     NAVHI
        cmp     NPRHI
        bne     NSAGN
        lda     NAVLO
        cmp     NPRLO
        bne     NSAGN
        ora     NAVHI
        bne     NREAD           ; settled, and there is something to read
NSAGN:  lda     NAVLO
        sta     NPRLO
        lda     NAVHI
        sta     NPRHI
        inc     NTRY
        lda     NTRY
        cmp     #NTRIES
        bcc     NSWAIT
        lda     #FNEWAIT
        sta     APERR
        jmp     SHOW
NSWAIT: ldy     #3              ; about three frames of scanlines
NSW1:   ldx     #0
NSW2:   sta     WSYNC
        dex
        bne     NSW2
        dey
        bne     NSW1
        jmp     NSTAT

; ---------------- READ ----------------
; ONE parameter of TWO bytes: the count, capped at what the rows can show.
NREAD:  lda     NAVHI
        bne     NRCAP
        lda     NAVLO
        cmp     #NMAX+1
        bcc     NRLEN
NRCAP:  lda     #NMAX
NRLEN:  sta     NAVLO
        lda     #0
        sta     NAVHI
        lda     #NETDEV
        sta     FNDEV
        lda     #NCREAD
        sta     FNCMD
        lda     #1
        sta     FNNPR
        jsr     FNBEG
        lda     NAVLO
        ldx     #0
        jsr     FNPW
        jsr     NGOACK

; ---------------- show it: a text row per line ----------------
        lda     #0
        sta     NSRC
        lda     #NROW0
        sta     NROW
NXROW:  lda     NROW
        cmp     #21
        bcs     NSHOWN
        jsr     FNROWA
        lda     #0
        sta     NCOL
NXCH:   ldx     NSRC
        cpx     NAVLO
        beq     NROWE           ; the reply is used up
        lda     FNRPLY,x
        inc     NSRC
        cmp     #10
        beq     NROWE           ; LF: the row is done
        cmp     #13
        beq     NXCH            ; CR: nothing to show
        ldy     NCOL
        cpy     #FNTCOL
        bcs     NXCH            ; past twelve: the rest of the line is lost
        sta     FNRSEL+FH_TCHR
        inc     NCOL
        jmp     NXCH
NROWE:  jsr     NENDW
        inc     NROW
        lda     NSRC
        cmp     NAVLO
        bcc     NXROW
NSHOWN:

; ---------------- CLOSE ----------------
        lda     #NETDEV
        sta     FNDEV
        lda     #NCCLOSE
        sta     FNCMD
        lda     #0
        sta     FNNPR
        jsr     FNBEG
        jsr     FNGO
        lda     #0
        sta     APERR

; ---------------- the title, and the verdict ----------------
SHOW:   lda     #(TTITLE)&$FF
        sta     FNPTRL
        lda     #(TTITLE)>>8
        sta     FNPTRH
        lda     #0
        jsr     FNRSTR
        lda     APERR
        beq     RUN
        lda     #(TFAIL)&$FF
        sta     FNPTRL
        lda     #(TFAIL)>>8
        sta     FNPTRH
        lda     #1
        jsr     FNRSTR
        lda     #1
        jsr     FNROWA
        lda     #(TFAIL)&$FF
        sta     FNPTRL
        lda     #(TFAIL)>>8
        sta     FNPTRH
        ldy     #0
NFL:    lda     (FNPTRL),y
        beq     NFLE
        sta     FNRSEL+FH_TCHR
        iny
        bne     NFL
NFLE:   lda     #' '
        sta     FNRSEL+FH_TCHR
        lda     APERR
        jsr     FNHEX
        jsr     FNENDR

RUN:    lda     #0
        sta     VBLANK
        jsr     DINIT
        jmp     DLOOP

; NGOACK -- commit and wait, then check the ACK. On success it returns; on
; any failure it leaves the code in APERR, drops its own return address and
; goes straight to SHOW, so a caller needs no branch after it (and none of
; them would reach SHOW in one branch anyway).
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

; NENDW -- render the composed row and wait (bounded) for the cartridge to
; say it has landed on the planes. Instant in emulation; on the RP2040 the
; row is composed on the other core, and a client that starts the next row's
; characters before then hands it a row already being overwritten.
NENDW:  ldx     FNBTXG
        jsr     FNENDR
        ldy     #0
NENDW1: cpx     FNBTXG
        bne     NENDW2
        dey
        bne     NENDW1
NENDW2: rts

; ---------------- strings ----------------
TURL:   DB      "N:http://127.0.0.1:8765/hello.txt",0
TTITLE: DB      "NETGET",0
TFAIL:  DB      "FAILED",0

        INCLUDE "fujilib.inc"
APPVBL: rts                     ; this client needs no per-frame work

        INCLUDE "fujidisp.inc"

; ---------------- the fixed tail ----------------
        ORG     $1FFC
        DW      START           ; RESET
        DW      START           ; BRK -- a runaway reboots rather than hangs

        END
