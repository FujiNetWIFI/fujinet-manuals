; cards.inc -- drawing cards.
;
; A card is 12x17 pixels (3 bytes x 17 lines) whose top-left sits on a
; char cell: col E (0-37), row D (0-12), pixel y = D*6. Hands lay cards
; left to right on an 8-pixel (2-byte) pitch, so a covered card shows its
; left 8 pixels: the black seam column at px0 (what separates overlapping
; white cards), the rank at px4-7, and the suit's ink at px1-7. The last
; card of a hand is fully visible; its right side is bare white with
; rounded corners against the felt.
;
; The white body is painted by code; rank glyphs come from the 4x6 font
; through the expander (red or black on white, matching the suit); the
; ten and the suits are raw 2bpp stamps from assets/cardart.inc with the
; seam baked in. Wire rank/suit characters are lowercase ASCII
; ('as' = ace of spades, 't?' never occurs: ten is 't'; '??' = face down,
; which DRWHND dispatches to DRWFDN).

; Card body row patterns (2bpp: felt 00, black 01, white 11).
CBTOP   EQU     3FH             ; ..WWWWWWWW   (rounded corner row, byte 0)
CBTOPR  EQU     0FCH            ; WWWWWWWWWW.. (corner row, byte 2)
CBMID   EQU     7FH             ; KWWW: seam + white (byte 0)
CBWHT   EQU     0FFH

; ----------------------------------------------------------------------
; DRWCRD: face-up card at char col E, row D; B = rank char, C = suit char.
; Clobbers everything.
DRWCRD: PUSH    BC
        CALL    CRDPOS          ; HL = screen dst, and (CRDMAG) = magic dst
        CALL    CBODY
        POP     BC

; Suit lookup: C -> table walk (stamp address, colors). A 0 tag is the
; catch-all row, so an unknown suit char cannot walk off the table.
        LD      A,C
        LD      HL,SUITTB
SUITL:  LD      E,(HL)
        INC     HL
        CP      E
        JR      Z,SUITF
        INC     E
        DEC     E
        JR      Z,SUITF         ; tag 0: catch-all
        INC     HL
        INC     HL
        INC     HL
        INC     HL
        JR      SUITL
SUITF:  LD      E,(HL)
        INC     HL
        LD      D,(HL)          ; DE = suit stamp
        INC     HL
        LD      C,(HL)          ; C = XPAND pair for the rank
        INC     HL
        LD      A,(HL)          ; A = ten stamp page flag (0 red, 1 black)
        PUSH    AF
        PUSH    BC

; Suit stamp: raw 12x6 at card rows 8-13.
        PUSH    DE
        LD      HL,(CRDDST)
        LD      DE,8*BYTEPL
        ADD     HL,DE
        EX      DE,HL
        POP     HL              ; HL = stamp, DE = dst
        LD      B,6
        LD      C,3
        CALL    RAWBLT

; Rank: rows 1-6. Ten is a raw stamp; the rest are font glyphs at px4-7.
        POP     BC
        POP     AF
        LD      E,A
        LD      A,B
        CP      't'
        JR      NZ,RANKG
        LD      HL,TENR
        LD      A,E
        OR      A
        JR      Z,RANK10
        LD      HL,TENB
RANK10: LD      DE,(CRDDST)
        LD      A,E
        ADD     A,BYTEPL
        LD      E,A
        JR      NC,RANK11
        INC     D
RANK11: LD      B,6
        LD      C,3
        JP      RAWBLT

RANKG:  LD      A,C             ; XPAND pair for this suit's color
        OUT     (XPAND),A
        LD      A,B             ; rank char -> glyph index
        CP      61H
        JR      C,RANKG1
        SUB     20H
RANKG1: SUB     20H
        PUSH    AF
        LD      HL,(CRDMAG)     ; glyph at byte 1, one line down
        LD      DE,BYTEPL+1
        ADD     HL,DE
        PUSH    HL
        EXX
        POP     DE              ; shadow DE = magic dst
        EXX
        POP     AF
        JP      GLYPH

; ----------------------------------------------------------------------
; DRWFDN: face-down card at char col E, row D. Clobbers everything.
DRWFDN: CALL    CRDPOS
        EX      DE,HL
        LD      HL,CARDBK
        LD      B,17
        LD      C,3
        JP      RAWBLT

; DRWCHP: bet chip (1 byte x 5 lines) at char col E, row D.
DRWCHP: CALL    CRDPOS
        EX      DE,HL
        LD      HL,CHIP
        LD      B,5
        LD      C,1
        JP      RAWBLT

; ----------------------------------------------------------------------
; CRDPOS: char col E, row D -> HL = screen dst; stashes both address
; forms for the stamp phases. Preserves DE.
CRDPOS: PUSH    DE
        LD      A,D
        ADD     A,A
        LD      H,0
        LD      L,A
        LD      BC,ROWTAB
        ADD     HL,BC
        LD      A,(HL)
        INC     HL
        LD      H,(HL)
        LD      L,A
        LD      B,0
        LD      C,E
        ADD     HL,BC           ; HL = magic-space offset
        LD      (CRDMAG),HL
        LD      BC,NORMEM
        ADD     HL,BC
        LD      (CRDDST),HL
        POP     DE
        RET

; CBODY: white card body with seam and rounded corners at HL. Clobbers
; A,B,C,DE,HL.
CBODY:  LD      A,CBTOP
        CALL    CBROW3
        LD      B,15
CBMIDL: PUSH    BC
        LD      A,CBMID
        LD      (HL),A
        INC     HL
        LD      A,CBWHT
        LD      (HL),A
        INC     HL
        LD      (HL),A
        DEC     HL
        DEC     HL
        CALL    CBNEXT
        POP     BC
        DJNZ    CBMIDL
        LD      A,CBTOP
; falls through: bottom row = top row
CBROW3: LD      (HL),A          ; corner row: A, white, mirrored corner
        INC     HL
        LD      A,CBWHT
        LD      (HL),A
        INC     HL
        LD      A,CBTOPR
        LD      (HL),A
        DEC     HL
        DEC     HL
; CBNEXT: HL down one screen line.
CBNEXT: LD      A,L
        ADD     A,BYTEPL
        LD      L,A
        RET     NC
        INC     H
        RET

; ----------------------------------------------------------------------
; DRWHND: a hand of cards laid left to right on the 2-col (8px) pitch.
; HL = wire card chars (2 per card), D = card row, E = start col,
; B = max cards. Stops at NUL or space. "??" draws a full face-down card.
; Serves both a seat's 2 hole cards and the 5-card community board.
; Clobbers everything.
;
; 5 Card Stud drew the FIRST "??" as a one-column sliver, because there it
; was the hole card peeking out from under the four face-up ones. Hold'em
; has no such card: an opponent in the hand shows "????" (two masked
; cards) and a folded one "??", so every masked card here is a whole card.
DRWHND: LD      A,(HL)
        OR      A
        RET     Z
        CP      ' '
        RET     Z
        PUSH    BC
        PUSH    HL
        PUSH    DE
        CP      '?'
        JR      NZ,DHFACE
        CALL    DRWFDN
        POP     DE
        JR      DHNEXT
DHFACE: LD      B,A             ; rank
        INC     HL
        LD      C,(HL)          ; suit
        CALL    DRWCRD
        POP     DE
DHNEXT: INC     E
        INC     E
        POP     HL
        INC     HL
        INC     HL
        POP     BC
        DJNZ    DRWHND
        RET

; suit char -> DW stamp, DB rank XPAND pair, DB ten flag (0 red, 1 black).
; The last row is the catch-all (unknown suit draws as spades).
SUITTB: DB      'h'
        DW      SUITH
        DB      XRONW,0
        DB      'd'
        DW      SUITD
        DB      XRONW,0
        DB      'c'
        DW      SUITC
        DB      XKONW,1
        DB      's'
        DW      SUITS
        DB      XKONW,1
        DB      0               ; catch-all: unknown suits draw as spades
        DW      SUITS
        DB      XKONW,1
