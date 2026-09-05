; sound.inc -- three cues, written straight to the music processor.
;
; Tone A only: set the master oscillator and tone A period, open the
; volume, busy-wait, close it. Blocking is fine here -- every caller is
; already in an input loop, and the longest cue is under a fifth of a
; second.

TONEA   EQU     11H             ; tone A period (TONMO+1)

; BEEP: A = tone A period (higher = lower pitch), B = duration, ~10 ms
; units. Clobbers A,B,DE.
BEEP:   PUSH    BC
        LD      C,A
        LD      A,20H
        OUT     (TONMO),A
        LD      A,C
        OUT     (TONEA),A
        LD      A,08H
        OUT     (VOLAB),A
        POP     BC
BEEPW:  LD      DE,600
BEEPD:  DEC     DE
        LD      A,D
        OR      E
        JR      NZ,BEEPD
        DJNZ    BEEPW
        XOR     A
        OUT     (VOLAB),A
        RET

SNDKEY: LD      A,18H           ; key click
        LD      B,2
        JP      BEEP

SNDSEL: LD      A,28H           ; select / join / move sent
        LD      B,5
        JP      BEEP

SNDTRN: LD      A,30H           ; your turn: low then high
        LD      B,6
        CALL    BEEP
        LD      A,18H
        LD      B,8
        JP      BEEP
