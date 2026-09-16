; state.inc -- what the reply window holds, and how to find things in it.
;
; Nothing here copies. The reply stays in the cartridge's window and the
; routines below turn a player index into an offset or a pointer into it.

        IF      BSHASNET
; ---------------------------------------------------------------------------
; VALID8 -- sanity-check the reply length against what the header implies,
; transcribed from arcadia/net.inc's (itself the Intellivision's
; validate_state), and note the four bytes every bank keys on.
;
; Minimum, not exact: a longer reply is harmless. A SHORTER one means the
; fixed offsets would read stale bytes out of a window that is never cleared,
; which is the failure this exists to stop.
;
;   tables    any nonzero length
;   lobby     59 + 10 * playerCount
;   place     49          (records are name+status only)
;   in play   49 + 115 * playerCount
VALID8: lda     BSREQ
        cmp     #RQTABLE
        bne     VALG0
        lda     BSRXL0          ; tables: any nonzero length will do
        ora     BSRXL1
        bne     VALT0
        jmp     VALBAD
VALT0:  lda     FNRPLY          ; the count byte; the lobby shows MAXTBL
        cmp     #MAXTBL+1
        bcc     VALT1
        lda     #MAXTBL
VALT1:  sta     BSCNT
        lda     #FNEOK
        rts
VALG0:  cmp     #RQLEAVE
        bne     VALG0A
        lda     #FNEOK          ; /leave: we are going whatever it said
        rts
VALG0A: lda     BSRXL1          ; a header at minimum, always
        bne     VALG1
        lda     BSRXL0
        cmp     #GHDRLEN
        bcc     VALBAD
VALG1:  lda     FNRPLY+GOPLCNT
        cmp     #MAXPLYR+1
        bcs     VALBAD
        sta     BSPCNT

        lda     FNRPLY+GOSTAT
        sta     BSSTAT
        bne     VALG2
        ; lobby: 59 + 10 * playerCount
        lda     #0
        ldx     BSPCNT
        beq     VALG1B
VALG1A: clc
        adc     #LBSTRID
        dex
        bne     VALG1A
VALG1B: clc
        adc     #GLPLYRS
        jmp     VALMIN          ; always < 256

VALG2:  cmp     #STPLACE
        bne     VALG3
        lda     #GIPLYRS        ; place: the fixed header only
        jmp     VALMIN

VALG3:  ; in play: 49 + 115 * playerCount, which passes 256 at two players
        lda     #0
        sta     BSTMP           ; the high byte accumulates here
        lda     #GIPLYRS
        ldx     BSPCNT
        beq     VALMIN
VALG3A: clc
        adc     #PLSTRID
        bcc     VALG3B
        inc     BSTMP
VALG3B: dex
        bne     VALG3A
        ldx     BSTMP
        beq     VALMIN
        ; 16-bit compare: high byte first
        cpx     BSRXL1
        beq     VALLO
        bcc     VALOK
        bcs     VALBAD
VALLO:  cmp     BSRXL0
        beq     VALOK
        bcc     VALOK
        bcs     VALBAD

; VALMIN -- A is the minimum length and it is under 256.
VALMIN: ldx     BSRXL1
        bne     VALOK           ; the reply is 256+, so it is long enough
        cmp     BSRXL0
        beq     VALOK
        bcs     VALBAD
VALOK:  lda     FNRPLY+GOPLST
        sta     BSMYST
        lda     FNRPLY+GOACTPL
        sta     BSACT
        lda     #FNEOK
        rts
VALBAD: lda     #FNEBADL
        sta     BSERR
        lda     #4
        sta     BSSTEP
        lda     #$FF
        rts
        ENDIF

; ---------------------------------------------------------------------------
; CELLNO -- A = the cursor's cell, y*10 + x. Clobbers BSTMP2.
CELLNO: lda     BSCURY
        asl     a
        sta     BSTMP2
        asl     a
        asl     a
        clc
        adc     BSTMP2
        clc
        adc     BSCURX
        rts

; BSHASUI is the REPLY-WINDOW half of what used to be one flag; the stick is
; bslib.inc's BSHASINP. No bank but the game one wants both, and the place
; bank wanting neither of these three is 118 bytes.
        IF      BSHASUI
; PLRECP -- FNPTRL/H = the address of player X's record in the reply window,
; phase-aware: ten bytes a record at GLPLYRS in the lobby, ten at GIPLYRS
; during placement (the serializer appends the gamefield only once it
; exists), 115 at GIPLYRS in play -- where player 2 onward is past 256, out
; of a single-byte index's reach, which is why this is a pointer.
;
; The stride and the name are the two things the three record shapes share:
; LBNAME and PLNAME are both 0, LBSTAT and PLSTAT both 9.
PLRECP: lda     #(FNRPLY)>>8
        sta     FNPTRH
        lda     BSSTAT
        cmp     #STSTART
        bcs     PLR2
        cmp     #STPLACE
        beq     PLR1
        lda     #GLPLYRS        ; the lobby
        jmp     PLR1A
PLR1:   lda     #GIPLYRS        ; placement: ten-byte records
PLR1A:  cpx     #0
        beq     PLR9
PLR1B:  clc
        adc     #LBSTRID
        dex
        bne     PLR1B
        jmp     PLR9
PLR2:   lda     #GIPLYRS        ; in play: 115-byte records, 16 bits
        cpx     #0
        beq     PLR9
PLR2A:  clc
        adc     #PLSTRID
        bcc     PLR2B
        inc     FNPTRH
PLR2B:  dex
        bne     PLR2A
PLR9:   sta     FNPTRL
        rts

; GCURS -- the cursor: one FB_PFCEL with mask A at the cursor's cell, on
; every slot in BSLIVE. Shared by the game bank, which moves it, and the
; composer, which puts it back after a poll.
; GCURS -- one FB_PFCEL with mask A at the cursor's cell, on every slot in
; BSLIVE.
GCURS:  sta     BSTMP
        jsr     CELLNO          ; clobbers BSTMP2
        sta     BSTMP2
        ldx     #0
GC1:    stx     BSIDX
        lda     SLOTBIT,x
        and     BSLIVE
        beq     GC2
        lda     BSTMP
        ldy     BSTMP2
        jsr     FNBARG          ; A = the mask, X = the slot, Y = the cell
        lda     #FB_PFCEL
        jsr     FNBLIT
GC2:    ldx     BSIDX
        inx
        cpx     #PFSLOTS
        bne     GC1
        rts

SLOTBIT: DB     1, 2, 4, 8

; FNRPLP -- append up to X bytes of the string at FNPTRL/H to the row being
; composed, stopping at NUL and padding the rest with spaces so a shorter
; value leaves no debris. The pointer form of FNRPLA, for records past 256.
FNRPLP: ldy     #0
FNRPP1: lda     (FNPTRL),y
        beq     FNRPP2
        sta     FNRSEL+FH_TCHR
        iny
        dex
        bne     FNRPP1
        rts
FNRPP2: lda     #' '
        sta     FNRSEL+FH_TCHR
        dex
        bne     FNRPP2
        rts
        ENDIF
