;=====================================================================
; FUJIBUS.INC -- the FujiBus (FEP-004) packet layer, in Z80
;
; Builds a command packet, frames it with SLIP, sends it, and collects
; and checks the reply.  It touches no hardware itself: bytes go out
; through FNOUT and come in through FNIN (see ALTAIR.INC).
;
; Building a packet:
;   FBNEW   A = device, C = command, B = first descriptor byte
;   FBBYTE  A        append one byte (a u8 parameter, an extra
;                    descriptor byte, or payload)
;   FBWORD  HL       append a 16-bit value, low byte first
;   FBMEM   HL, BC   append BC bytes from (HL)
;   FBSTR   HL, BC   append the NUL-terminated string at (HL), padded
;                    with zeroes (or cut) to exactly BC bytes
; Sending it:
;   FBCALL  send the packet and wait for the reply, retrying as needed
;           returns  carry set   -- no good reply after FBTRIES tries
;                    carry clear -- reply in RXBUF, and then
;                      Z  set    -- ACK; HL = payload, BC = its length
;                      Z  clear  -- NAK (no payload)
;
; Registers: FBNEW/FBBYTE/FBWORD/FBMEM/FBSTR preserve everything but
; AF (FBMEM and FBSTR also advance HL past what they copied).  FBCALL
; destroys AF, BC, DE, HL.
;=====================================================================

SLEND   EQU     0C0h            ; SLIP END
SLESC   EQU     0DBh            ; SLIP ESC
SLEEND  EQU     0DCh            ; ESC + this = a data byte C0h
SLEESC  EQU     0DDh            ; ESC + this = a data byte DBh

ACK     EQU     06h             ; reply command: success
NAK     EQU     15h             ; reply command: failure
RESEND  EQU     05h             ; "send your last reply again"
                                ;   (fujinet-pc rs232-resend only)

TXMAX   EQU     320             ; largest packet we build
RXMAX   EQU     600             ; largest reply we accept
FBTRIES EQU     3               ; attempts before FBCALL gives up

; Assemble with USE_RESEND defined non-zero to ask for a garbled reply
; again (command 05h) instead of sending the whole command a second
; time.  Only firmware that implements RESEND answers it.
        IF      !USE_RESEND
USE_RESEND EQU  0
        ENDIF

;---------------------------------------------------------------------
; FBNEW -- start a packet: device in A, command in C, descriptor in B
;---------------------------------------------------------------------
FBNEW:  PUSH    HL
        LD      HL,TXBUF
        LD      (HL),A          ; +0 device
        INC     HL
        LD      (HL),C          ; +1 command
        INC     HL
        LD      (HL),0          ; +2 length, filled in by FBCALL
        INC     HL
        LD      (HL),0          ; +3
        INC     HL
        LD      (HL),0          ; +4 checksum, filled in by FBCALL
        INC     HL
        LD      (HL),B          ; +5 first descriptor
        INC     HL
        LD      (TXPTR),HL
        POP     HL
        RET

;---------------------------------------------------------------------
; FBBYTE -- append A;  FBWORD -- append HL, low byte first
;---------------------------------------------------------------------
FBBYTE: PUSH    HL
        LD      HL,(TXPTR)
        LD      (HL),A
        INC     HL
        LD      (TXPTR),HL
        POP     HL
        RET

FBWORD: LD      A,L
        CALL    FBBYTE
        LD      A,H
        JR      FBBYTE

;---------------------------------------------------------------------
; FBMEM -- append BC bytes from (HL)
;---------------------------------------------------------------------
FBMEM:  PUSH    BC
        PUSH    DE
        LD      DE,(TXPTR)
        LD      A,B
        OR      C
        JR      Z,FBM1
        LDIR
FBM1:   LD      (TXPTR),DE
        POP     DE
        POP     BC
        RET

;---------------------------------------------------------------------
; FBSTR -- append the string at (HL) as a field exactly BC bytes long
;---------------------------------------------------------------------
FBSTR:  PUSH    BC
        PUSH    DE
        LD      DE,(TXPTR)
FBS1:   LD      A,B
        OR      C
        JR      Z,FBS3          ; field full
        LD      A,(HL)
        OR      A
        JR      Z,FBS2          ; end of string: pad the rest
        LD      (DE),A
        INC     HL
        INC     DE
        DEC     BC
        JR      FBS1
FBS2:   XOR     A               ; zero-fill to the field size
        LD      (DE),A
        INC     DE
        DEC     BC
        LD      A,B
        OR      C
        JR      NZ,FBS2
FBS3:   LD      (TXPTR),DE
        POP     DE
        POP     BC
        RET

;---------------------------------------------------------------------
; CKSUM -- FujiBus checksum of BC bytes at (HL), result in A
;
; An 8-bit sum with end-around carry: after each add, the carry out of
; bit 7 is added back in.  ADD then ADC 0 is exactly that.
;---------------------------------------------------------------------
CKSUM:  XOR     A
CKS1:   ADD     A,(HL)
        ADC     A,0
        INC     HL
        DEC     BC
        LD      D,A
        LD      A,B
        OR      C
        LD      A,D
        JR      NZ,CKS1
        RET

;---------------------------------------------------------------------
; FBCALL -- finish the packet, send it, return the reply
;---------------------------------------------------------------------
FBCALL: LD      HL,(TXPTR)      ; length = TXPTR - TXBUF
        LD      DE,TXBUF
        OR      A
        SBC     HL,DE
        LD      (TXLEN),HL
        LD      (TXBUF+2),HL    ; +2/+3 length, little-endian
        XOR     A
        LD      (TXBUF+4),A     ; checksum is computed over a zero
        LD      B,H
        LD      C,L
        LD      HL,TXBUF
        CALL    CKSUM
        LD      (TXBUF+4),A
        LD      A,FBTRIES
        LD      (TRIES),A
        CALL    FBDRAIN         ; throw away anything stale first
        CALL    FBSEND
FBC1:   CALL    FBRECV
        JR      NC,FBC3         ; a good frame
        LD      A,(TRIES)
        DEC     A
        LD      (TRIES),A
        SCF
        RET     Z               ; out of tries: carry set
        IF      USE_RESEND
        LD      A,(RXGOT)       ; did any of the reply arrive?
        OR      A
        JR      Z,FBC2          ; no: the command itself was lost
        CALL    FBRSND          ; yes: ask for the reply again
        JR      FBC1
        ENDIF
FBC2:   CALL    FBSEND          ; send the whole command again
        JR      FBC1
FBC3:   LD      HL,(RXLEN)      ; payload length = frame length - 6
        LD      DE,6
        OR      A
        SBC     HL,DE
        LD      B,H
        LD      C,L
        LD      HL,RXBUF+6      ; replies carry no parameters
        LD      A,(RXBUF+1)     ; the reply's command byte
        CP      ACK             ; Z = ACK, carry clear
        RET

;---------------------------------------------------------------------
; FBDRAIN -- discard whatever is already waiting on the FujiNet port
;
; A reply should only ever answer the command just sent.  Some commands
; can answer twice (SET_SSID sends a second NAK when the connect fails),
; and a reply abandoned after a timeout may still trickle in; either
; would be taken for the answer to the NEXT command.
;---------------------------------------------------------------------
FBDRAIN:CALL    FNST
        RET     Z
        CALL    FNIN
        JR      FBDRAIN

;---------------------------------------------------------------------
; FBSEND -- SLIP-frame TXBUF (TXLEN bytes) out through FNOUT
;---------------------------------------------------------------------
FBSEND: LD      HL,TXBUF
        LD      BC,(TXLEN)
FBTX:   LD      A,SLEND         ; exactly one END opens the frame
        CALL    FNOUT
FBT1:   LD      A,(HL)
        CP      SLEND
        JR      Z,FBT2
        CP      SLESC
        JR      Z,FBT3
        CALL    FNOUT           ; an ordinary byte
        JR      FBT4
FBT2:   LD      A,SLESC         ; C0h -> DB DC
        CALL    FNOUT
        LD      A,SLEEND
        CALL    FNOUT
        JR      FBT4
FBT3:   CALL    FNOUT           ; DBh -> DB DD
        LD      A,SLEESC
        CALL    FNOUT
FBT4:   INC     HL
        DEC     BC
        LD      A,B
        OR      C
        JR      NZ,FBT1
        LD      A,SLEND         ; and one END closes it
        JP      FNOUT

        IF      USE_RESEND
;---------------------------------------------------------------------
; FBRSND -- send RESEND (05h) to the device we were talking to
;---------------------------------------------------------------------
FBRSND: LD      HL,RSPKT
        LD      A,(TXBUF)       ; same device as the command
        LD      (HL),A
        XOR     A
        LD      (RSPKT+4),A
        LD      BC,6
        CALL    CKSUM
        LD      (RSPKT+4),A
        LD      HL,RSPKT
        LD      BC,6
        JR      FBTX
RSPKT:  DEFB    0,RESEND,6,0,0,0
        ENDIF

;---------------------------------------------------------------------
; FBRECV -- collect one SLIP frame into RXBUF and check it
;   carry clear: good frame, RXLEN = its decoded length
;   carry set:   FBERR says why --
;                  1 no reply at all      4 shorter than a header
;                  2 stopped part-way     5 length field disagrees
;                  3 longer than RXMAX    6 bad checksum
;                RXGOT = 0 if not a single byte of it arrived
;---------------------------------------------------------------------
FBRECV: XOR     A
        LD      (RXGOT),A
        LD      (FBERR),A
        LD      A,(FBWAIT)      ; first byte: allow FBWAIT timeouts
        LD      E,A
FBR1:   CALL    FNIN
        JR      NC,FBR2
        DEC     E
        JR      NZ,FBR1
        LD      A,1             ; FBERR 1: the device never answered
        JR      FBFAIL
FBR2:   CP      SLEND           ; skip anything before the opening END
        JR      NZ,FBR1
        LD      A,1
        LD      (RXGOT),A
FBR3:   LD      HL,RXBUF        ; HL = store pointer
        LD      BC,0            ; BC = bytes stored
FBR4:   CALL    FNIN
        JR      C,FBSTAL        ; frame stalled part-way
        CP      SLEND
        JR      Z,FBR8          ; end of frame
        CP      SLESC
        JR      NZ,FBR6
        CALL    FNIN            ; an escape: take the next byte
        JR      C,FBSTAL
        CP      SLEEND
        LD      A,SLEND
        JR      Z,FBR6
        LD      A,SLESC
FBR6:   PUSH    HL              ; overlong?  keep reading, stop storing
        LD      HL,RXMAX
        OR      A
        SBC     HL,BC
        POP     HL
        JR      Z,FBR7          ; BC = RXMAX: buffer full
        JR      C,FBR7          ; BC > RXMAX: still full
        LD      (HL),A
        INC     HL
FBR7:   INC     BC              ; count every byte, stored or not
        JR      FBR4
FBR8:   LD      A,B             ; END with nothing before it: that was
        OR      C               ;   an opening END, so start again
        JR      Z,FBR3
        LD      (RXLEN),BC
        LD      HL,RXMAX        ; overlong frames fail
        OR      A
        SBC     HL,BC
        LD      A,3             ; FBERR 3: longer than RXMAX
        JR      C,FBFAIL
        LD      A,B             ; shorter than a header?
        OR      A
        JR      NZ,FBR9
        LD      A,C
        CP      6
        LD      A,4             ; FBERR 4: shorter than a header
        JR      C,FBFAIL
FBR9:   LD      HL,(RXBUF+2)    ; the length field must match
        OR      A
        SBC     HL,BC
        LD      A,5             ; FBERR 5: length field disagrees
        JR      NZ,FBFAIL
        LD      A,(RXBUF+4)     ; and so must the checksum
        LD      D,A
        PUSH    DE
        XOR     A
        LD      (RXBUF+4),A
        LD      HL,RXBUF
        CALL    CKSUM
        POP     DE
        CP      D
        LD      A,6             ; FBERR 6: bad checksum
        JR      NZ,FBFAIL
        OR      A               ; good frame: clear carry
        RET
FBSTAL: LD      A,2             ; FBERR 2: the frame stopped part-way
FBFAIL: LD      (FBERR),A
        SCF
        RET

;---------------------------------------------------------------------
; Data
;---------------------------------------------------------------------
FBWAIT: DEFB    40              ; first-byte wait, in FNIN timeouts
                                ;   (40 x 250 ms = 10 s); raise it for
                                ;   slow commands
FBERR:  DEFB    0               ; why the last receive failed (1-6)
TRIES:  DEFB    0
RXGOT:  DEFB    0
TXPTR:  DEFW    0
TXLEN:  DEFW    0
RXLEN:  DEFW    0
TXBUF:  DEFS    TXMAX
RXBUF:  DEFS    RXMAX
