; sound.inc -- cues, written straight to the music processor.
;
; Tone A only, plus the noise generator for the dice rattle -- the first
; use of the noise channel in this family of ports. Everything blocks:
; every caller is already in an input loop, and the longest cue is under
; half a second.

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

SNDSEL: LD      A,28H           ; select / join / confirm
        LD      B,5
        JP      BEEP

SNDHLD: LD      A,14H           ; a die kept (or released): a short
        LD      B,2             ; high click, distinct from the key
        JP      BEEP

SNDTRN: LD      A,30H           ; your turn: low then high
        LD      B,6
        CALL    BEEP
        LD      A,18H
        LD      B,8
        JP      BEEP

SNDSCOR: LD     A,30H           ; a row scored: rising chirp
        LD      B,3
        CALL    BEEP
        LD      A,20H
        LD      B,4
        JP      BEEP

SNDFUJI: LD     A,40H           ; FUJITZEE! five rising notes
        LD      B,4
        CALL    BEEP
        LD      A,30H
        LD      B,4
        CALL    BEEP
        LD      A,28H
        LD      B,4
        CALL    BEEP
        LD      A,20H
        LD      B,4
        CALL    BEEP
        LD      A,18H
        LD      B,10
        JP      BEEP

; SNDROLL: the dice rattle -- a decaying burst of noise. Noise mode is
; bit 5 of VOLC (the tone C volume / noise control register); the noise
; level itself rides VOLN. Clobbers A,B,C,DE.
SNDROLL: LD     A,20H
        OUT     (TONMO),A       ; master oscillator clocks the noise LFSR
        LD      A,20H
        OUT     (VOLC),A        ; noise mode on, tone C volume 0
        LD      B,8             ; eight ~35 ms bursts, fading
        LD      C,0F0H
SNROL1: LD      A,C
        OUT     (VOLN),A
        LD      DE,4400         ; ~35 ms
SNROL2: DEC     DE
        LD      A,D
        OR      E
        JR      NZ,SNROL2
        LD      A,C             ; fade a step
        SUB     20H
        LD      C,A
        DJNZ    SNROL1
        XOR     A
        OUT     (VOLN),A
        OUT     (VOLC),A        ; noise mode off
        RET

SNDBAD: LD      A,70H           ; the rejection buzz
        LD      B,5
        JP      BEEP

SNDTICK: LD     A,10H           ; the last-seconds tick
        LD      B,1
        JP      BEEP

SNDOVER: LD     A,40H           ; game over
        LD      B,5
        CALL    BEEP
        LD      A,30H
        LD      B,5
        CALL    BEEP
        LD      A,20H
        LD      B,10
        JP      BEEP
