; mailbox.inc -- the cartridge mailbox, spoken from page 1.
;
; The bring-up's fujilib.inc reaches the mailbox from page-0 code through
; indirect pointer words. This client turns that inside out: everything
; that talks to the cart lives in BLOCK 2 (CPU $2000-$2AFF), which shares
; 2650 page 1 with the hotspots and the reply window -- so a register arm
; is a direct indexed load and a TX append is ONE instruction. What page-1
; code cannot name absolutely is page-0 RAM; those few cells go through
; the DWBE pointer words at the bottom (indirect addressing carries the
; full 15 bits).
;
; The protocol rules carried over unchanged from fujilib.inc:
;   - a register write is a REGSEL read then a REGDATA read, back to back
;     (the pairing is the stray-read defense);
;   - the SEQ for a commit comes from the cart's own persisted ACKSEQ + 1,
;     never a local counter (console RESET restarts this program, not the
;     cart), wrapping 255 -> 1, 0 reserved;
;   - FNSECHO is published last on a slice repaint, FNACKSQ last on a
;     transaction: once they echo, the window is whole.

; ---- reply bytes (repainted ROM) --------------------------------------
FNRDATA EQU     $2B00           ; 256-byte reply slice
FNACKSQ EQU     $2C00           ; echoes SEQ when the reply is ready
FNSTATS EQU     $2C01           ; bit0 link up
FNERR   EQU     $2C02           ; fb_status_t of the last transaction
FNREPLY EQU     $2C03           ; $06 ACK / $15 NAK
FNRXLL  EQU     $2C04           ; reply length, low
FNRXLH  EQU     $2C05           ; reply length, high
FNMAGF  EQU     $2C09           ; 'F'
FNMAGN  EQU     $2C0A           ; 'N'
FNSECHO EQU     $2C0C           ; echoes RXSLICE after each repaint

; ---- hotspot pages ----------------------------------------------------
FNRSEL  EQU     $2D00           ; read +reg: arm register
FNRDAT  EQU     $2E00           ; read +val: armed register = val
FNDATA  EQU     $2F00           ; read +val: append val to TX stream

; ---- register numbers and values --------------------------------------
FRDEVIC EQU     $00
FRCMD   EQU     $01
FRNPARM EQU     $02
FRDATRS EQU     $05
FRRXSLC EQU     $06
FRSEQ   EQU     $10
FCACK   EQU     $06
FCNAK   EQU     $15
FEOK    EQU     0
FETIMO  EQU     $FF             ; helper-local: commit/slice gave up

SETFS1  MACRO   adr             ; page-1 SETSTR for FNTXSTR (clobbers R0)
        LODI,R0 (adr)>>8
        STRA,R0 *PFSTRH
        LODI,R0 (adr)&$FF
        STRA,R0 *PFSTRL
        ENDM

; ---- routines (all page 1) --------------------------------------------

; MREGWR: mailbox register R1 = value R2. Leaf. Clobbers R0.
MREGWR: LODA,R0 FNRSEL,R1
        LODA,R0 FNRDAT,R2
        RETC,UN

; MSTART: rewind the TX stream and set the N: device id. The caller then
; writes FRCMD/FRNPARM, streams params, and calls MCOMMIT. Leaf.
; Clobbers R0,R1,R2.
MSTART: LODI,R1 FRDATRS
        LODI,R2 0
        LODA,R0 FNRSEL,R1
        LODA,R0 FNRDAT,R2
        LODI,R1 FRDEVIC
        LODI,R2 NETDEV
        LODA,R0 FNRSEL,R1
        LODA,R0 FNRDAT,R2
        RETC,UN

; MPARB: append a 1-byte parameter with value R2. Leaf. Clobbers R0,R1.
; (A bare TX append is one instruction: LODA,R0 FNDATA,Rn.)
MPARB:  LODI,R1 1
        LODA,R0 FNDATA,R1       ; size byte
        LODA,R0 FNDATA,R2       ; value
        RETC,UN

; MCOMMIT: derive the SEQ from the cart's ACKSEQ, write it, poll ~6 s
; (the cart's own transact budget is 5 s, so a silent cart is truly
; gone). R0 = FNERR value (0 = ok) or FETIMO. Leaf. Clobbers R0-R3.
MCOMMIT: LODA,R0 FNACKSQ
        ADDI,R0 1
        BCFR,EQ MCM1
        LODI,R0 1               ; 255 wraps past the reserved 0
MCM1:   STRZ    R2
        LODI,R1 FRSEQ
        LODA,R0 FNRSEL,R1
        LODA,R0 FNRDAT,R2
        LODI,R3 0               ; outer x256
MCMO:   LODI,R1 0               ; inner x256
MCMI:   NOP                     ; pad the poll to ~90 us so the sweep
        NOP                     ; outlasts the cart's transact timeout
        NOP
        NOP
        NOP
        NOP
        LODA,R0 FNACKSQ
        COMZ    R2
        BCTR,EQ MCMOK
        BDRR,R1 MCMI
        BDRR,R3 MCMO
        LODI,R0 FETIMO
        RETC,UN
MCMOK:  LODA,R0 FNERR
        RETC,UN

; MSLICE: select reply slice R2 (0-3) and wait for FNSECHO (~1.5 s).
; R0 = 0 ok / FETIMO. Preserves R2. Leaf. Clobbers R0,R1,R3.
MSLICE: LODI,R1 FRRXSLC
        LODA,R0 FNRSEL,R1
        LODA,R0 FNRDAT,R2
        LODI,R3 64
MSLO:   LODI,R1 0
MSLI:   LODA,R0 FNSECHO
        COMZ    R2
        BCTR,EQ MSLOK
        BDRR,R1 MSLI
        BDRR,R3 MSLO
        LODI,R0 FETIMO
        RETC,UN
MSLOK:  EORZ    R0
        RETC,UN

; MCHECK: R0 = 0 when the 'F','N' cartridge magic is present. Leaf.
MCHECK: LODA,R0 FNMAGF
        COMI,R0 'F'
        BCFR,EQ MCKNO
        LODA,R0 FNMAGN
        COMI,R0 'N'
        BCFR,EQ MCKNO
        EORZ    R0
        RETC,UN
MCKNO:  LODI,R0 $FF
        RETC,UN

; ---- pointer words: the page-0 cells page-1 code touches ---------------
PFSTRH: DWBE    FSTRP           ; FNTXSTR string pointer, hi/lo
PFSTRL: DWBE    FSTRP+1
PRXSLC: DWBE    RXPTR           ; state cursor: slice
PRXOFF: DWBE    RXPTR+1         ; state cursor: offset within slice
PCURSL: DWBE    CURSLC          ; slice the cart is publishing
PSAV2:  DWBE    V_SAV           ; R2 shelter for RXNEXT's slice cross
PVURL:  DWBE    V_URL           ; request type
PVTMP:  DWBE    V_TMP           ; APICALL settle-loop counter
PAVA0:  DWBE    AVAIL           ; STATUS bytes-waiting, lo/hi
PAVA1:  DWBE    AVAIL+1
PRXL0:  DWBE    RXLEN           ; captured reply length, lo/hi
PRXL1:  DWBE    RXLEN+1
PPRA0:  DWBE    PRVAVL          ; settle-loop compare, lo/hi
PPRA1:  DWBE    PRVAVL+1
PMOVB0: DWBE    MOVBUF          ; staged move code, 2 chars
PMOVB1: DWBE    MOVBUF+1
