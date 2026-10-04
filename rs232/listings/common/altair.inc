;=====================================================================
; ALTAIR.INC -- platform layer for an Altair 8800 with a MITS 88-2SIO
;
; Everything that touches hardware lives in this one file.  Port A of
; the 88-2SIO is the operator's terminal (or Teletype); port B is the
; FujiNet.  To move the examples to another machine, rewrite only the
; routines between the PLATFORM BEGIN / PLATFORM END markers below and
; keep their register contracts.
;
; Contracts (all routines preserve BC, DE, HL unless stated):
;   PINIT          initialise both serial ports
;   CONST          A = 0 if no key waiting, NZ (A = FFh) if a key is
;   CONIN          wait for a key; A = character, bit 7 stripped
;   CONOUT         send the character in A to the terminal
;   FNOUT          send the byte in A to the FujiNet
;   FNST           A = 0 if no byte waiting from the FujiNet, NZ if one is
;   FNIN           receive a byte from the FujiNet with a timeout:
;                    carry clear, A = byte  -- a byte arrived
;                    carry set              -- nothing within FNTMO
;   DELAY          wait about 10 ms x A (A = 0 means 256)
;   PEXIT          return to the monitor / CP/M
;=====================================================================

;---------------------------------------------------------------------
; PLATFORM BEGIN: 88-2SIO port assignments
;---------------------------------------------------------------------
CONSTAT EQU     10h             ; port A control/status  (terminal)
CONDATA EQU     11h             ; port A data
FNSTAT  EQU     12h             ; port B control/status  (FujiNet)
FNDATA  EQU     13h             ; port B data

RDRF    EQU     01h             ; 6850 status: receive data register full
TDRE    EQU     02h             ; 6850 status: transmit data register empty

ACIARST EQU     03h             ; 6850 control: master reset
ACIAMOD EQU     15h             ; 6850 control: /16 clock, 8 data, no
                                ;   parity, 1 stop, interrupts off.
                                ;   The baud rate itself is set by the
                                ;   jumpers on the 88-2SIO board.

; FNIN gives up after FNTMO passes through its polling loop.  One pass
; is 51 T-states, so at 2 MHz 9600 passes is about 250 ms -- longer
; than the 200 ms inter-byte gap the FujiNet itself allows.  Scale it
; with your CPU clock (double it at 4 MHz).
FNTMO   EQU     9600

; DELAY's inner loop: 10 ms at 2 MHz.  Again, scale with the clock.
DLY10MS EQU     769
;---------------------------------------------------------------------
; PLATFORM END
;---------------------------------------------------------------------

;---------------------------------------------------------------------
; PLATFORM BEGIN: PINIT -- reset and program both 6850 ACIAs
;---------------------------------------------------------------------
PINIT:  LD      A,ACIARST
        OUT     (CONSTAT),A
        OUT     (FNSTAT),A
        LD      A,ACIAMOD
        OUT     (CONSTAT),A
        OUT     (FNSTAT),A
        RET
;---------------------------------------------------------------------
; PLATFORM END
;---------------------------------------------------------------------

;---------------------------------------------------------------------
; PLATFORM BEGIN: terminal I/O on port A
;---------------------------------------------------------------------
CONST:  IN      A,(CONSTAT)
        AND     RDRF
        RET     Z               ; A = 0: nothing waiting
        LD      A,0FFh
        RET

CONIN:  IN      A,(CONSTAT)
        AND     RDRF
        JR      Z,CONIN
        IN      A,(CONDATA)
        AND     7Fh
        RET

CONOUT: PUSH    AF
COUT1:  IN      A,(CONSTAT)
        AND     TDRE
        JR      Z,COUT1
        POP     AF
        OUT     (CONDATA),A
        RET
;---------------------------------------------------------------------
; PLATFORM END
;---------------------------------------------------------------------

;---------------------------------------------------------------------
; PLATFORM BEGIN: FujiNet I/O on port B
;---------------------------------------------------------------------
FNOUT:  PUSH    AF
FOUT1:  IN      A,(FNSTAT)
        AND     TDRE
        JR      Z,FOUT1
        POP     AF
        OUT     (FNDATA),A
        RET

FNST:   IN      A,(FNSTAT)
        AND     RDRF
        RET

FNIN:   PUSH    BC
        LD      BC,FNTMO
FIN1:   IN      A,(FNSTAT)      ; 11
        AND     RDRF            ;  7
        JR      NZ,FIN2         ;  7
        DEC     BC              ;  6
        LD      A,B             ;  4
        OR      C               ;  4
        JR      NZ,FIN1         ; 12  = 51 T-states a pass
        POP     BC
        SCF                     ; timed out
        RET
FIN2:   IN      A,(FNDATA)
        POP     BC
        OR      A               ; clear carry: byte received
        RET
;---------------------------------------------------------------------
; PLATFORM END
;---------------------------------------------------------------------

;---------------------------------------------------------------------
; PLATFORM BEGIN: DELAY -- about A x 10 ms, PEXIT -- leave the program
;---------------------------------------------------------------------
DELAY:  PUSH    BC
        PUSH    DE
        LD      D,A
DLY1:   LD      BC,DLY10MS
DLY2:   DEC     BC              ;  6
        LD      A,B             ;  4
        OR      C               ;  4
        JR      NZ,DLY2         ; 12  = 26 T-states a pass
        DEC     D
        JR      NZ,DLY1
        POP     DE
        POP     BC
        RET

; Bare metal: halt with the front-panel lights showing PC.  Under CP/M
; assemble with CPM defined (-DCPM) and the program warm-boots instead.
PEXIT:
        IF      CPM
        JP      0000h
        ELSE
        HALT
        JR      PEXIT
        ENDIF
;---------------------------------------------------------------------
; PLATFORM END
;---------------------------------------------------------------------
