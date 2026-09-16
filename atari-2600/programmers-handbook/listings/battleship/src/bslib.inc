; bslib.inc -- the mailbox transport, the text ports, and the odd jobs.
;
; CODE. This file is included INSIDE the ORG; the equates are fujinet.inc and
; come before it.
;
; Transcribed from fujinet-firmware/pico/atari-2600/testrom/fujilib.inc by way
; of the 5 Card Stud port. Trimmed to what this program uses -- there is no
; boot, no ROM swap, no directory -- plus the two waits (FNENDW, FNBLIT) that
; make a burst of cartridge work safe on hardware as well as in emulation.
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
;   STA/STX/STY, and never an indirect store anywhere, because an indirect
;   store performs a read at the address it writes.

; The transport core -- FNRW, FNARM, FNCHK, FNBEG, FNPB, FNPW, FNGO and
; FNACK -- is NOT here. It lives in the fixed tail (src/bstrans.inc, assembled
; by bstail.asm) and the banks reach it through build/tail.inc.
;
; That is worth the build machinery. Every bank is 2048 bytes and carries its
; own copy of everything it calls, so a byte in this file costs three; the
; transport is 137 of them and the game bank came in exactly full without the
; move it needed. The fixed tail at $1F20-$1FFB is the one region every bank
; sees at the same address, which is what makes sharing possible at all.

; -----------------------------------------------------------------------
; Text, composed by the cartridge.
;
; FNROWA, FNCHR, FNENDR and FNSPC are in the fixed tail with the transport:
; every bank composes text, and four bytes apiece times seven banks is worth
; one copy. FNCLS is NOT -- it was, until the trampoline needed three bytes
; for the stack reset and the tail was exactly full.

        IF      BSHASCLS
; FNCLS -- blank every text row.
;
; THE TEXT PLANES ARE CARTRIDGE STATE AND SURVIVE A BANK SWITCH, so a screen
; that simply does not paint a row inherits whatever the previous screen left
; there. Every full redraw starts here rather than each bank tracking which
; rows it owns -- that is exactly the bookkeeping that goes wrong when a menu
; of a different length opens over a screen of a different shape.
FNCLS:  ldx     #0
FNCLS1: txa
        jsr     FNROWA
        jsr     FNENDR
        inx
        cpx     #FNTROW
        bcc     FNCLS1
        rts
        ENDIF


        IF      BSHASSTR
; FNSTRA -- append the NUL-terminated string at FNPTRL/FNPTRH to the row
; being composed, without ending it. Clobbers Y.
FNSTRA: ldy     #0
FNSA1:  lda     (FNPTRL),y
        beq     FNSA2
        sta     FNRSEL+FH_TCHR
        iny
        cpy     #FNTCOL
        bne     FNSA1
FNSA2:  rts

        ENDIF

; FNSETP -- point FNPTRL/H at the string whose address is X (lo) / Y (hi).
; Not guarded: url.inc needs it, and url.inc is in the bank that draws
; nothing.
FNSETP: stx     FNPTRL
        sty     FNPTRH
        rts

; FNENDW -- render the composed row and WAIT for it to land. FNBTXG is bumped
; by the cartridge after the row is actually on the planes; a client that
; goes on to the next row's characters before then, on hardware, hands the
; render a row that is already being overwritten. In emulation the render is
; done inside the store and the loop exits at once. Bounded, so a cartridge
; that never answers costs a millisecond and not the frame.
FNENDW: ldx     FNBTXG
        lda     #0
        sta     FNRSEL+FH_TEND
        ldy     #128
FNEW1:  cpx     FNBTXG
        bne     FNEW2
        dey
        bne     FNEW1
FNEW2:  rts

; FNBLIT -- fire blit transform A and wait for FNBGEN to say it has landed,
; for the same reason. A blit is a SINGLE-SLOT request on the cartridge --
; there is no queue -- so the next one's argument stores would overwrite this
; one's before it ran. Clobbers X and Y.
FNBLIT: ldx     FNBGEN
        sta     FNRSEL+FH_BGO
        ldy     #128
FNBL1:  cpx     FNBGEN
        bne     FNBL2
        dey
        bne     FNBL1
FNBL2:  rts

; FNBARG -- the blit arguments: A = src low, X = dst low, Y = cnt; the two
; high bytes are zero, which every playfield blit and every text blit here
; wants. Nothing is fired.
FNBARG: sta     FNRSEL+FH_BSL
        stx     FNRSEL+FH_BDL
        sty     FNRSEL+FH_BCNT
        lda     #0
        sta     FNRSEL+FH_BSH
        sta     FNRSEL+FH_BDH
        rts

; BSHASRPL, not BSHASSTR: only the composer streams the reply window into a
; row. Every other bank that composes text composes it out of its own strings.
        IF      BSHASRPL
; FNRPLA -- append up to Y bytes of the reply window at offset X to the row
; being composed, stopping at NUL. Pads the rest with spaces so a shorter
; value leaves no debris behind it.
;
; This is the zero-copy path and on this console it is not an optimisation:
; the reply window is repainted only by a SEQ commit or a slice select, so it
; is stable while the row is streamed, and the bytes go from the cartridge
; back to the cartridge without ever occupying any of the 128 bytes.
FNRPLA: lda     FNRPLY,x
        beq     FNRPA2
        sta     FNRSEL+FH_TCHR
        inx
        dey
        bne     FNRPLA
        rts
FNRPA2: lda     #' '            ; NUL: pad out what is left of the field
        sta     FNRSEL+FH_TCHR
        dey
        bne     FNRPA2
        rts

        ENDIF

; -----------------------------------------------------------------------
; The cartridge's path buffers: where the player name and the table id live,
; because 128 bytes of console RAM cannot spare nineteen for them. They
; SURVIVE A CONSOLE RESET, so a cold start must empty all four.

; FNWSEL -- select path buffer A (FP_SEL0..SEL3).
FNWSEL: sta     FNRSEL+FH_PATHO
        rts

        IF      BSHASED
; FNWRST -- empty the selected buffer.
FNWRST: lda     #FP_RST
        sta     FNRSEL+FH_PATHO
        rts

; FNWPOP -- the text editor's backspace: drop the last character.
FNWPOP: lda     #FP_POPCH
        sta     FNRSEL+FH_PATHO
        rts

        ENDIF

; FNWRAW -- stream the selected buffer into TX exactly as it stands, with no
; padding. This is how a table id or a player name reaches a URL without ever
; crossing into console RAM.
FNWRAW: lda     #FP_TXRAW
        sta     FNRSEL+FH_PATHO
        rts

        IF      BSHASED
; FNWRPL -- append up to Y bytes of the reply window at offset X to the
; selected buffer, stopping at NUL.
;
; Fixed-width wire fields are pushed up to their NUL and never through it: the
; padding in the middle of a URL corrupts the request, which is the bug the
; Arcadia port calls out by name.
FNWRPL: lda     FNRPLY,x
        beq     FNWR2
        sta     FNRSEL+FH_PATHC
        inx
        dey
        bne     FNWRPL
FNWR2:  rts
        ENDIF

        IF      BSHASDEC
; -----------------------------------------------------------------------
; BSDEC -- print BSNUM0/BSNUM1 as decimal into the row being composed, in a
; field of exactly A characters (1-5). Clobbers X and Y, and NOT BSTMP.
;
; Sixteen bits, because a pot and a purse are u16 and the widest number any
; sibling 2600 client had to print was a board coordinate. Repeated
; subtraction against a table of powers of ten: five 16-bit subtracts is
; smaller than any division, and there is no multiply on this machine.
;
; The field width picks the STARTING power, so a four-wide field prints
; thousands down to units and nothing above -- callers with a narrow field
; call BSCL4 first so a value that would not fit cannot reach here. Leading
; zeros are spaces; the units digit always prints, so a pot of zero reads "0"
; and not as an empty field. The field is always exactly A wide, which is what
; makes a value that SHRINKS leave nothing behind it.
BSDEC:  eor     #$FF            ; A = 5 - width, so the field width picks the
        clc                     ;   first power of ten to use. No scratch cell
        adc     #6              ;   at all: BSDEC once borrowed BSTMP for this
        asl     a               ;   and silently ate its caller's loop index.
        tax
        lda     #0
        sta     BSDGT
BSD1:   lda     BSDGT
        and     #$80            ; a new digit; significance is sticky
        sta     BSDGT
BSD2:   lda     BSNUM0          ; num -= power, sixteen bits, while it fits
        sec
        sbc     BSPOW10,x
        tay
        lda     BSNUM1
        sbc     BSPOW10+1,x
        bcc     BSD3            ; it did not fit: this digit is done
        sta     BSNUM1
        sty     BSNUM0
        inc     BSDGT           ; a digit is 0-9, so this cannot reach bit 7
        jmp     BSD2
BSD3:   lda     BSDGT
        and     #$0F
        bne     BSD4            ; a significant digit
        cpx     #8              ; the units digit prints even as a zero
        beq     BSD4
        bit     BSDGT           ; bit 7 into N
        bpl     BSD5            ; still leading: emit a space
BSD4:   lda     BSDGT
        ora     #$80
        sta     BSDGT
        and     #$0F
        clc
        adc     #'0'
        jmp     BSD6
BSD5:   lda     #' '
BSD6:   sta     FNRSEL+FH_TCHR
        inx
        inx
        cpx     #10
        bne     BSD1
        rts

; Powers of ten, little-endian, high to low.
BSPOW10: DW     10000
        DW      1000
        DW      100
        DW      10
        DW      1
        ENDIF

; BSHASINP, not BSHASUI: reading the stick and reading a player record out of
; the reply window are wanted by different banks, and 104 bytes of input
; scanning in the composer -- whose APPVBL is an rts -- was 104 bytes the
; fleet rows needed. state.inc's helpers keep BSHASUI.
        IF      BSHASINP
; -----------------------------------------------------------------------
; INSCAN -- fold the joystick and the console switches into one active-high
; byte in INCUR, and return only what is NEWLY pressed, so a held stick steps
; once.
;
; INCUR is left holding the LEVELS, which is what the purse overlay reads:
; "SELECT held" is a level and not an edge.
INSCAN: lda     SWCHA
        eor     #$FF            ; the port is active low
        and     #$F0            ; right, left, down, up in bits 7-4
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        sta     INCUR
        lda     INPT4
        bmi     INSC1           ; bit 7 high = fire not pressed
        lda     INCUR
        ora     #IN_FIRE
        sta     INCUR
INSC1:  lda     SWCHB
        and     #$01
        bne     INSC2
        lda     INCUR
        ora     #IN_RST
        sta     INCUR
INSC2:  lda     SWCHB
        and     #$02
        bne     INSC3
        lda     INCUR
        ora     #IN_SEL
        sta     INCUR
INSC3:  lda     INPREV          ; newly pressed = current AND NOT previous
        eor     #$FF
        and     INCUR
        pha
        lda     INCUR
        sta     INPREV
        pla
        rts

; INREPT -- INSCAN, plus auto-repeat on the four DIRECTIONS only.
;
; FIRE, SELECT and RESET are deliberately not repeated: a repeating fire would
; submit a bet and then submit whatever the cursor landed on next.
;
; Repeat is affordable only because moving a cursor costs no round trip on any
; screen here -- the reply window is stable between transactions, so a redraw
; reads names the cartridge is already holding.
INDLAY  EQU     30              ; ~0.5s before the first repeat
INRATE  EQU     6               ; ~10 a second after that

INREPT: jsr     INSCAN
        beq     INRP1           ; nothing newly pressed: a repeat may be due
        pha                     ; something was: restart the delay
        lda     #INDLAY
        sta     INRPT
        pla
        rts
INRP1:  lda     INCUR
        and     #INDIRS
        beq     INRP2           ; no direction held: disarm
        lda     INRPT
        beq     INRPF           ; already expired -- fire now
        dec     INRPT
        bne     INRP3
INRPF:  lda     #INRATE
        sta     INRPT
        lda     INCUR
        and     #INDIRS
        rts
INRP2:  lda     #INDLAY
        sta     INRPT
INRP3:  lda     #0
        rts
        ENDIF
