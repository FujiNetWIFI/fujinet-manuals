; bstrans.inc -- the transport, assembled ONCE into the fixed tail.
;
; $1F20-$1FFB is the only region of the window that every bank sees at the
; same address, so it is the only place shared code can live. Each 2K bank
; otherwise carries its own copy of everything it calls, and the transport is
; 137 bytes of that -- three times over, in a client whose game bank came in
; exactly 2048 bytes full.
;
; The banks do not include this file. They include build/tail.inc, which
; tools/mktail.py generates from THIS file's assembled addresses, so the two
; cannot drift: there is no hand-maintained address list to get wrong.
;
; TWO RULES ABOUT THE CONTROL PAGES, both enforced by tools/checkrom.py:
;
;   A register write is TWO stores on this console, not one:
;
;       lda #value
;       sta FNRSEL+reg          ; arm; this store's data is ignored
;       sta FNCMT               ; commit: register `reg` = value
;
;   And never a read-modify-write instruction on the control or TX pages.
;   INC/DEC/ASL/LSR/ROL/ROR absolute are three bus cycles at one address --
;   read, write old, write new -- and the cartridge's "last value before the
;   address changed" sampling has no defined answer in that burst. Only
;   STA/STX/STY, and never an indirect store anywhere.

;
; `sta FNRSEL,x` is safe for any X: the base low byte is $00 so the index can
; never carry, which means the dummy read STA abs,X always performs lands on
; the SAME address as the write.
FNRW:   sta     FNRSEL,x
        sta     FNCMT
        rts

; FNARM -- open the decode gate. Two stores, in order, carrying two specific
; values; nothing in the control page decodes until they arrive.
FNARM:  lda     #FNAM1
        sta     FNRSEL+FH_ARM1
        lda     #FNAM2
        sta     FNRSEL+FH_ARM2
        rts

; FNCHK -- Z set if a FujiNet cartridge is answering.
FNCHK:  lda     FNMAG0
        cmp     #'F'
        bne     FNCHK1
        lda     FNMAG1
        cmp     #'N'
FNCHK1: rts

; FNBEG -- begin a transaction described by FNDEV / FNCMD / FNNPR.
; Rewinds the TX stream LAST, so parameters may be appended immediately.
FNBEG:  lda     #16             ; ~9s; longer than the cart's own 5s budget so
        sta     FNTMO           ;   a real timeout is reported as ITS error
        lda     FNDEV
        ldx     #FR_DEV
        jsr     FNRW
        lda     FNCMD
        ldx     #FR_CMD
        jsr     FNRW
        lda     FNNPR
        ldx     #FR_NPAR
        jsr     FNRW
        lda     #0
        ldx     #FR_DRST
        jmp     FNRW

; FNPB -- append a one-byte parameter with value A. The stream is
; NPARAM x { size byte, then that many value bytes } and then the payload.
FNPB:   pha
        lda     #1
        sta     FNTX
        pla
        sta     FNTX
        rts

; FNPW -- append a two-byte little-endian parameter. A = low, X = high.
FNPW:   pha
        lda     #2
        sta     FNTX
        pla
        sta     FNTX
        txa
        sta     FNTX
        rts

; FNGO -- commit and wait. Returns A = FNE* (0 = the transaction completed).
;
; THE RULE EVERY PORT IN THIS FAMILY LEARNED THE HARD WAY: the next sequence
; number comes from the CART'S OWN persisted ACKSEQ + 1, never from a counter
; in RAM. A console RESET restarts this client and re-zeroes its variables but
; does NOT reset the cartridge -- there is no reset line on the connector at
; all, and the RESET switch is a bit in a RIOT register the cart never sees.
; A program-local counter would restart at 1, collide with a sequence already
; answered, and every later transaction would be dropped in silence.
FNGO:   lda     FNACKS
        clc
        adc     #1
        bne     FNGO1
        lda     #1              ; 0 is reserved as "never used"
FNGO1:  sta     FNSEQ
        ldx     #FR_SEQ
        jsr     FNRW            ; launching it is this single commit
        lda     FNTMO
        sta     FNCNT
FNGO2:  ldy     #0
FNGO3:  ldx     #0
        ; ACKSEQ is published LAST, after the reply, its length and the error
        ; code are all in place, so a match means everything behind it is
        ; already readable.
FNGO4:  lda     FNACKS
        cmp     FNSEQ
        beq     FNGO5
        dex
        bne     FNGO4
        dey
        bne     FNGO3
        dec     FNCNT
        bne     FNGO2
        lda     #FNEWAIT
        rts
FNGO5:  lda     FNERR
        rts

; FNACK -- 0 on success, FNENAK if the server said no.
FNACK:  lda     FNRCMD
        cmp     #$06
        beq     FNACK1
        lda     #FNENAK
        rts
FNACK1: lda     #FNEOK
        rts

; -----------------------------------------------------------------------
; Text, composed by the cartridge. Shared for the same reason the transport
; is: every bank draws.

; FNROWA -- begin composing text row A.
FNROWA: sta     FNRSEL+FH_TROW
        rts

; FNCHR -- append character A to the row being composed.
FNCHR:  sta     FNRSEL+FH_TCHR
        rts

; FNENDR -- render the composed row.
FNENDR: lda     #0
        sta     FNRSEL+FH_TEND
        rts

; FNSPC -- append A spaces.
FNSPC:  tax
FNSPC1: lda     #' '
        sta     FNRSEL+FH_TCHR
        dex
        bne     FNSPC1
        rts
