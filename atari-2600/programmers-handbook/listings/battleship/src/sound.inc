; sound.inc -- the cues, on one TIA channel.
;
; A cue is a SCRIPT: steps of (frames, AUDC, AUDF, AUDV), ended by a step of
; zero frames. SNDFIRE starts one and SNDTICK, once a frame from APPVBL,
; advances it. Nothing blocks: the display loop cannot afford to, and the
; whole point of a cue is to announce something the picture is showing NOW.
;
; The vocabulary is the family's (src/platform-specific/sound.h), with the
; TIA's own character: noise for the water and the explosions, pure tones for
; the interface. Two rules from the siblings: the result cue rides the STATUS
; edge, so an opponent's shot is heard too; and the turn cue plays before the
; draw, because it is an alert and an alert after the fact is not one.
;
; Two cells of zero page: SNDPTR, the offset of the current step in SNDDATA
; (0 = silent, so the table's first byte is a terminator and offset 0 is never
; a real step), and SNDCNT, the frames left on it.

; THE ORDER IS NOT ARBITRARY: a bank carries its own copy of every byte it
; includes, and the cues are 160 of them. They are numbered so that each
; bank's are a PREFIX, and SNDLAST says where that bank's copy stops -- the
; place bank needs four cues and used to carry twelve, which is 148 bytes it
; did not have.
SNDMOVE EQU     0               ; the cursor stepped one cell: a click
SNDSEL  EQU     1               ; a choice made, a table joined, readied
SNDPLC  EQU     2               ; a ship committed
SNDERR  EQU     3               ; refused: low, short, deliberately ugly
SNDSHOT EQU     4               ; the shot went out: a falling swoosh
SNDCLK  EQU     5               ; the clock's last seconds
SNDMISS EQU     6               ; a splash, low and short
SNDHIT  EQU     7               ; an explosion, brighter and longer
SNDSUNK EQU     8               ; the explosion, then three falling tones
SNDTURN EQU     9               ; your turn: three rising, carries a room
SNDOVER EQU     10              ; game over: three long falling tones
SNDJOIN EQU     11              ; the start countdown began

; SNDFIRE -- start cue A, replacing whatever is playing.
SNDFIRE: tax
        lda     SNDTAB,x
        sta     SNDPTR
        jmp     SNDSTEP

        IF      SNDFULL
; SNDSOFT -- start cue A only if nothing is playing. For the cursor click,
; which must never cut a hit short.
SNDSOFT: ldx    SNDPTR
        bne     SNDX
        jmp     SNDFIRE

; SNDTICK -- once a frame.
SNDTICK: lda    SNDPTR
        beq     SNDX
        dec     SNDCNT
        bne     SNDX
        clc
        adc     #4
        sta     SNDPTR
        ENDIF
; SNDSTEP -- load the step at SNDPTR; a zero-frame step ends the cue.
SNDSTEP: ldx    SNDPTR
        lda     SNDDATA,x
        beq     SNDOFF
        sta     SNDCNT
        lda     SNDDATA+1,x
        sta     AUDC0
        lda     SNDDATA+2,x
        sta     AUDF0
        lda     SNDDATA+3,x
        sta     AUDV0
SNDX:   rts
SNDOFF: sta     AUDV0
        sta     SNDPTR
        rts

; The scripts. Offsets into SNDDATA, one per cue, up to SNDLAST.
SNDTAB: DB      SDMOVE-SNDDATA, SDSEL-SNDDATA, SDPLC-SNDDATA, SDERR-SNDDATA
        IF      SNDLAST>=5
        DB      SDSHOT-SNDDATA, SDTICK-SNDDATA
        ENDIF
        IF      SNDLAST>=11
        DB      SDMISS-SNDDATA, SDHIT-SNDDATA, SDSUNK-SNDDATA, SDTURN-SNDDATA
        DB      SDOVER-SNDDATA, SDJOIN-SNDDATA
        ENDIF

SNDDATA: DB     0               ; offset 0 is "silent"
SDMOVE: DB      1, 12, 3, 4,  0
SDSEL:  DB      3, 12, 14, 6,  3, 12, 9, 6,  0
SDPLC:  DB      2, 12, 11, 5,  3, 12, 7, 5,  0
SDERR:  DB      10, 1, 28, 5,  0
        IF      SNDLAST>=5
SDSHOT: DB      2, 1, 6, 8,  2, 1, 9, 7,  2, 1, 12, 6,  2, 1, 16, 5
        DB      2, 1, 20, 4,  3, 1, 26, 3,  3, 1, 31, 2,  0
SDTICK: DB      1, 8, 4, 4,  0
        ENDIF
        IF      SNDLAST>=11
SDMISS: DB      2, 8, 24, 6,  3, 8, 28, 4,  4, 8, 31, 2,  0
SDHIT:  DB      3, 8, 6, 12,  3, 8, 10, 11,  4, 8, 15, 9,  4, 8, 20, 7
        DB      5, 8, 26, 5,  6, 8, 31, 3,  0
SDSUNK: DB      3, 8, 6, 12,  3, 8, 10, 11,  4, 8, 15, 9,  4, 8, 22, 6
        DB      5, 12, 9, 8,  5, 12, 12, 8,  10, 12, 16, 8,  0
SDTURN: DB      4, 12, 15, 6,  4, 12, 11, 6,  7, 12, 8, 7,  0
SDOVER: DB      10, 12, 8, 7,  10, 12, 12, 7,  20, 12, 18, 7,  0
SDJOIN: DB      4, 12, 12, 5,  4, 12, 10, 5,  6, 12, 8, 5,  0
        ENDIF
