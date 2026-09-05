; rnd.inc -- a 16-bit Galois LFSR for the placement seeds.
;
; The state is a pure maximal LFSR (poly mask 2DH, period 65535),
; stepped a full 8 bits per call so consecutive outputs are independent
; PRNG bytes. The R register is folded into the OUTPUT only, never the
; state: R advances with every opcode fetch, so it varies with input
; and network timing and makes runs differ -- but XORing it into the
; state (the first cut here) correlated consecutive calls whenever the
; code path between them was fixed, and every placement seeded dir=0,
; x=0. State out, output in.

; RNDNXT: A = the next pseudo-random byte. Clobbers B,HL.
RNDNXT: LD      HL,(RNDST)
        LD      B,8
RNDS:   ADD     HL,HL           ; one LFSR bit: shift left, tap on carry
        JR      NC,RNDS2
        LD      A,L
        XOR     2DH             ; maximal 16-bit polynomial
        LD      L,A
RNDS2:  DJNZ    RNDS
        LD      A,H
        OR      L
        JR      NZ,RNDS3
        INC     L               ; never park on zero
RNDS3:  LD      (RNDST),HL
        LD      A,R
        XOR     L
        RET

; RNDMOD: A = a random value 0 .. A-1 (A >= 1). Clobbers B,C,HL.
RNDMOD: LD      C,A
        CALL    RNDNXT
RNDM1:  SUB     C
        JR      NC,RNDM1
        ADD     A,C
        RET
