; fujibas.h -- the mailbox as batari Basic sees it.
;
; batari Basic emits any name it does not know verbatim, so a dasm equate is
; a BASIC variable: `FNH_TROW = 3` assembles to LDA #3 / STA $1DF0, and
; `x = FNRPLY[i]` to LDX i / LDA $1B00,x. BASIC has no way to write
; FNRSEL+FH_TROW, so every register arm address and every one-shot hotspot
; gets a name of its own here -- each DEFINED FROM the fujinet.h equates, so
; nothing in this file can drift from the cartridge header on its own.
;
; Include AFTER fujinet.h and devdefs.h. Never write `FNTX = FNTX + 1` or any other
; in-place arithmetic on one of these: batari Basic compiles that to an
; INC on the control page, which is the one instruction the cartridge
; cannot sample. Compute in a variable, then assign.

; ---- register arms: store anything here, then the value to FNCMT ----
FNA_DEV   = FNRSEL+FR_DEV       ; $1D00 device id
FNA_CMD   = FNRSEL+FR_CMD       ; $1D01 command id
FNA_NPAR  = FNRSEL+FR_NPAR      ; $1D02 parameter count
FNA_DRST  = FNRSEL+FR_DRST      ; $1D05 rewind the TX stream
FNA_RXSL  = FNRSEL+FR_RXSL      ; $1D06 select a reply slice
FNA_SEQ   = FNRSEL+FR_SEQ       ; $1D10 launch: commit ACKSEQ+1 here
FNA_BLCK  = FNRSEL+FR_BLCK      ; $1D11 arm the ROM swap ($B5)

; ---- one-shot operations: the store's data is the operand ----
FNH_BANK  = FNRSEL+FH_BANK      ; $1D80 + b: select bank b (store to FNH_BANK+b)
FNH_TROW  = FNRSEL+FH_TROW      ; $1DF0 begin text row (data = row)
FNH_TCHR  = FNRSEL+FH_TCHR      ; $1DF1 append a character
FNH_TEND  = FNRSEL+FH_TEND      ; $1DF2 render the row (data = 0)
FNH_PATHC = FNRSEL+FH_PATHC     ; $1DF3 append to the path buffer
FNH_PATHO = FNRSEL+FH_PATHO     ; $1DF4 path buffer operation (FP_*)
FNH_BLSL  = FNRSEL+$F5          ; $1DF5 blit source, low
FNH_BLSH  = FNRSEL+$F6          ; $1DF6 blit source, high
FNH_BLDL  = FNRSEL+$F7          ; $1DF7 blit destination, low
FNH_BLDH  = FNRSEL+$F8          ; $1DF8 blit destination, high
FNH_BLCNT = FNRSEL+$F9          ; $1DF9 blit count
FNH_BLGO  = FNRSEL+$FA          ; $1DFA fire the blit (data = transform)
FNH_ARM1  = FNRSEL+FH_ARM1      ; $1DFC the arming pair: $B5...
FNH_ARM2  = FNRSEL+FH_ARM2      ; $1DFD ...then $4A
FNH_SWAP  = FNRSEL+FH_SWAP      ; $1DFE serve the staged image (armed only)

; ---- the second reply slice page, for a 16-bit reply offset ----
FNRPLY2   = FNRPLY+$100         ; $1C00: bytes 256-511 of the reply slice

; The blit transforms (FB_*), the rest of the path operations (FP_*) and
; the playfield masks (PFM_*) come from devdefs.h, as they do for assembly.
