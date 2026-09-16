; ============================================================
; fujimail.inc -- the FujiNet mailbox, in Z80 assembly.
;
; The console's half of the cartridge mailbox, hand-mirrored from
; firmware/include/fuji_mailbox.h. Every address here is a CONSOLE address
; (the cartridge image offset plus $8000).
;
; Both directions of the mailbox are cartridge READS -- the ColecoVision
; cartridge port has no write strobe, so the ADDRESS carries the payload:
;
;   console -> cart   reading $FD05 arms register 5; reading $FE2A then
;                     delivers the value $2A to it. Reading $FF41 appends
;                     the byte $41 ('A') to the outgoing TX stream.
;   cart -> console   the cartridge repaints its own ROM, so by the time the
;                     Z80 looks, the reply at $F800 is just bytes.
;
; In C this took a volatile sink to stop sccz80 discarding the "read whose
; value we throw away". In assembly there is no such hazard: `ld a,(hl)`
; always performs the read. That is the one real advantage assembly has here.
;
; Calling conventions are register-based and documented at each routine. The
; two scratch bytes NPARAM and WANT live in low RAM; see the demo's equates.
; ============================================================

; ---- cart -> console: the painted status page and reply window ----
FN_REPLY    equ $F800        ; the whole 1K reply, in one piece
FN_ACKSEQ   equ $FC00        ; echoes our SEQ when the reply is ready
FN_STATUS   equ $FC01        ; bit0 link up, bit1 busy
FN_ERR      equ $FC02        ; transport verdict of the last transaction
FN_REPLYCMD equ $FC03        ; $06 ACK / $15 NAK
FN_RXLEN    equ $FC04        ; reply length, little-endian word
FN_BOOTSTAT equ $FC06
FN_BOOTPCT  equ $FC07
FN_BOOTERR  equ $FC08
FN_MAGIC0   equ $FC09        ; 'F' -- cartridge presence
FN_MAGIC1   equ $FC0A        ; 'N'

; ---- console -> cart: the hotspot pages ----
FN_REGSELP  equ $FD          ; high byte: read $FD00+r arms register r
FN_REGDATP  equ $FE          ; high byte: read $FE00+v delivers v
FN_DATAP    equ $FF          ; high byte: read $FF00+v appends v to TX

; ---- register file ----
FNR_DEVICE   equ $00
FNR_CMD      equ $01
FNR_NPARAM   equ $02
FNR_DATA_RST equ $05
FNR_SEQ      equ $10
FNR_BOOTLOCK equ $11
FN_BOOTLOCK_MAGIC equ $B5

; ---- FujiBus reply codes ----
FN_ACK      equ $06
FN_NAK      equ $15

; ============================================================
; FNREGWR -- write one mailbox register.
;   in:  C = register number, A = value
;   out: -                 clobbers: A, H, L
;
; A register write is exactly two reads, back to back: one to arm the
; register number, one to deliver the value. The cartridge disarms after a
; single use, so a lone stray read of the data page changes nothing -- which
; is what makes the unmaskable vblank NMI harmless between these two lines.
; ============================================================
FNREGWR:
        push    af              ; hold the value
        ld      h,FN_REGSELP    ; $FD00 + register: arm it
        ld      l,c
        ld      a,(hl)
        pop     af
        ld      h,FN_REGDATP    ; $FE00 + value: deliver it
        ld      l,a
        ld      a,(hl)
        ret

; ============================================================
; FNTXB -- append one byte to the TX stream.
;   in:  A = byte            clobbers: H, L (A preserved on exit? no -- see)
; ============================================================
FNTXB:
        ld      h,FN_DATAP      ; $FF00 + value
        ld      l,a
        ld      a,(hl)
        ret

; ============================================================
; FNSTART -- begin a transaction.
;   in:  D = device, E = command      clobbers: A, H, L
;
; Rewinds the TX write pointer and sets DEVICE, COMMAND and NPARAM. D and E
; survive because FNREGWR touches only A, H and L. Afterwards the stream is
; empty and waiting for parameters and payload.
; ============================================================
FNSTART:
        xor     a
        ld      (NPARAM),a
        ld      c,FNR_DATA_RST      ; any value rewinds the TX pointer
        ld      a,0
        call    FNREGWR
        ld      c,FNR_DEVICE
        ld      a,d
        call    FNREGWR
        ld      c,FNR_CMD
        ld      a,e
        call    FNREGWR
        ld      c,FNR_NPARAM
        xor     a
        call    FNREGWR
        ret

; ============================================================
; FNP8 -- append a one-byte parameter and bump NPARAM.
;   in:  A = value           clobbers: A, B, C, H, L
; The parameter grammar is {size byte, value bytes...}; a byte is {1, v}.
; ============================================================
FNP8:
        ld      b,a             ; save value
        ld      a,1             ; size byte
        call    FNTXB
        ld      a,b
        call    FNTXB           ; the value
        ld      a,(NPARAM)
        inc     a
        ld      (NPARAM),a
        ld      c,FNR_NPARAM    ; A already = new count
        call    FNREGWR
        ret

; ============================================================
; FNP16 -- append a two-byte (little-endian) parameter, bump NPARAM.
;   in:  HL = value          clobbers: A, C, H, L
; ============================================================
FNP16:
        push    hl
        ld      a,2             ; size byte
        call    FNTXB
        pop     hl
        push    hl
        ld      a,l             ; low byte
        call    FNTXB
        pop     hl
        ld      a,h             ; high byte
        call    FNTXB
        ld      a,(NPARAM)
        inc     a
        ld      (NPARAM),a
        ld      c,FNR_NPARAM
        call    FNREGWR
        ret

; ============================================================
; FNTXPAD -- append a NUL-terminated string, then pad with NULs to a fixed
; width. SET_DEVICE_FULLPATH and OPEN_DIRECTORY want a fixed 256-byte buffer;
; a short one is rejected on the ESP32 side.
;   in:  HL = string, DE = total byte count      clobbers: A, B, D, E, H, L
; ============================================================
FNTXPAD:
FNTXP1:
        ld      a,(hl)
        or      a
        jr      z,FNTXP2        ; NUL: switch to padding
        push    hl
        push    de
        call    FNTXB           ; A = the character
        pop     de
        pop     hl
        inc     hl
        dec     de
        ld      a,d
        or      e
        jr      nz,FNTXP1
        ret                     ; filled exactly, no padding needed
FNTXP2:
        ld      a,d
        or      e
        ret     z               ; padded to width
        push    de
        xor     a               ; a NUL pad byte
        call    FNTXB
        pop     de
        dec     de
        jr      FNTXP2

; ============================================================
; FNCOMMIT -- launch the transaction and wait for the reply.
;   out: A = FN_ERR (transport verdict); CARRY set if the cart never answered.
;        clobbers: A, B, C, D, E, H, L
;
; The sequence number comes from the cartridge's own FN_ACKSEQ + 1, wrapping
; 255 -> 1 (0 is reserved), never from a local counter -- a console RESET
; restarts this program but not the cartridge, and a local counter would
; replay a sequence the cart has already answered. Then poll FN_ACKSEQ until
; it echoes what we wrote.
; ============================================================
FNCOMMIT:
        ld      a,(FN_ACKSEQ)
        inc     a
        jr      nz,FNCM1
        inc     a               ; 255 wrapped to 0; step past the reserved 0
FNCM1:
        ld      (WANT),a
        ld      c,FNR_SEQ       ; A = want
        call    FNREGWR
        ld      b,40            ; outer quanta; inner is a full 16-bit spin
FNCMO:
        ld      de,0
FNCMI:
        ld      a,(FN_ACKSEQ)
        ld      hl,WANT
        cp      (hl)
        jr      z,FNCMOK
        dec     de
        ld      a,d
        or      e
        jr      nz,FNCMI
        djnz    FNCMO
        scf                     ; timed out -- the cart never answered
        ret
FNCMOK:
        ld      a,(FN_ERR)
        or      a               ; clears carry, sets Z if FN_ERR == 0
        ret

; ============================================================
; FNACKED -- did the far side ACK?  out: Z set if FN_REPLYCMD == FN_ACK.
; ============================================================
FNACKED:
        ld      a,(FN_REPLYCMD)
        cp      FN_ACK
        ret

; ============================================================
; FNPRES -- is a FujiNet cartridge underneath us?
;   out: Z set if the 'F','N' magic is painted.       clobbers: A
; ============================================================
FNPRES:
        ld      a,(FN_MAGIC0)
        cp      'F'
        ret     nz
        ld      a,(FN_MAGIC1)
        cp      'N'
        ret
