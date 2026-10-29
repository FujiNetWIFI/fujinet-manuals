; osk.inc -- the on-screen keyboard netcat uses:
; CONFIG's own, copied unchanged from fujinet-config
; 86c763d between the >>> and <<< lines
; (tools/vendorcheck.py holds them to it). The
; program supplies st_edit, ed_ok, ed_esc and the
; RAM: V_EDIT, V_EDLEN, V_EDMAX, V_OSK, V_KOLD and
; V_KTO, with RB.1 = HI(V_APP) throughout.

; >>> fujinet-config 86c763d studio2/src/cfgdefs.inc: the macros
; D = var.
LDV     MACRO   var
        LDI     LO(var)
        PLO     RB
        LDN     RB
        ENDM

; var = D. Leaves D, and RB on var. Uses RD.1.
STV     MACRO   var
        PHI     RD
        LDI     LO(var)
        PLO     RB
        GHI     RD
        STR     RB
        ENDM

; var = constant.
SETV    MACRO   var, val
        LDI     LO(var)
        PLO     RB
        LDI     val
        STR     RB
        ENDM

; RB = var.
PTV     MACRO   var
        LDI     LO(var)
        PLO     RB
        ENDM

; The 2-byte var = adr, high byte first (go_ind).
SETW    MACRO   var, adr
        LDI     LO(var)
        PLO     RB
        LDI     HI(adr)
        STR     RB
        INC     RB
        LDI     LO(adr)
        STR     RB
        ENDM

; Every state starts with an empty stack: R2.1 never leaves $09.
STATE   MACRO
        LDI     LO(STACK)
        PLO     R2
        ENDM

; One kdisp table entry.
KEYTO   MACRO   k, adr
        DB      k
        DW      adr
        ENDM

; FIT that also keeps out of $x000-$x3FF: `size` bytes start on the next
; page if they would cross one, and at $x400 if that page is $x000-$x3FF.
RFIT    MACRO   size
        IF      ((($) & 0FFH) + (size)) > 100H
        ORG     (($) + 0FFH) & 0FF00H
        ENDIF
        IF      (($) & 0C00H) == 0
        ORG     (($) & 0F000H) + 0400H
        ENDIF
        ENDM
; <<<

; >>> fujinet-config 86c763d studio2/src/ui.inc: keys and dispatch
; key_wait -- D = the next key, 0-9, from either pad. A held key repeats
; only for 2/4/6/8: a held select must not fire twice.
; key_tmo  -- the same, but D = $FF once D seconds pass without one.
        RFIT    67
key_tmo: FCALL  fn_frames
        LDI     1
        BR      kw0
key_wait:
        LDI     0
kw0:    STV     V_KTO
kw1:    LDV     V_KLAST
        STV     V_KOLD
        FCALL   in_get
        BNZ     kw2
        LDV     V_KTO
        BZ      kw1
        FCALL   fn_tick
        BDF     kw1
        LDI     0FFH
        FRET
kw2:    STR     R2
        LDV     V_KOLD
        XOR
        BNZ     kw3                     ; a fresh press
        LDN     R2
        ANI     0FH
        BZ      kw1
        SHR
        BDF     kw1                     ; an odd key: no repeat
kw3:    LDI     2
        PLO     RD                      ; a click
        LDN     R2
        ANI     0FH
        FRET

; kdisp -- FCALL kdisp with D = a key, then KEYTO entries and DB $FF: go to
; the first entry's address whose key is D (with D kept), else return past
; the table. The jump is a return with R6 swapped, so the stack balances.
        RFIT    27
kdisp:  PLO     R9
kd1:    LDA     R6
        XRI     0FFH
        BZ      kd3                     ; the end of the table
        XRI     0FFH
        STR     R2
        GLO     R9
        XOR
        BZ      kd2
        INC     R6
        INC     R6
        BR      kd1
kd2:    LDA     R6
        PHI     R9
        LDN     R6
        PLO     R6
        GHI     R9
        PHI     R6
        GLO     R9
        FRET
kd3:    GLO     R9
        FRET
; <<<

; >>> fujinet-config 86c763d studio2/src/edit.inc: moves, add, delete
        RFIT    34
ed_in:  FCALL   key_wait
        FCALL   kdisp
        KEYTO   2, ed_up
        KEYTO   8, ed_dn
        KEYTO   4, ed_lt
        KEYTO   6, ed_rt
        KEYTO   5, ed_add
        KEYTO   0, ed_del
        KEYTO   9, ed_ok
        KEYTO   1, ed_esc
        DB      0FFH
        FJMP    ed_in

; Moves wrap at the edges. The old cell is repainted plain first.
        RFIT    117
ed_up:  LDV     V_OSK
        FCALL   ed_cell
        LDV     V_OSK
        SMI     16
        BDF     ed_mv
        ADI     96
        BR      ed_mv
ed_dn:  LDV     V_OSK
        FCALL   ed_cell
        LDV     V_OSK
        ADI     16
        STR     R2
        SMI     96
        BDF     ed_mv
        LDN     R2
        BR      ed_mv
ed_lt:  LDV     V_OSK
        FCALL   ed_cell
        LDV     V_OSK
        ANI     0FH
        BZ      edl1
        LDV     V_OSK
        SMI     1
        BR      ed_mv
edl1:   LDV     V_OSK
        ADI     15
        BR      ed_mv
ed_rt:  LDV     V_OSK
        FCALL   ed_cell
        LDV     V_OSK
        ANI     0FH
        XRI     0FH
        BZ      edr1
        LDV     V_OSK
        ADI     1
        BR      ed_mv
edr1:   LDV     V_OSK
        SMI     15
ed_mv:  STV     V_OSK
        FCALL   ed_sel
        FCALL   ed_text
        FJMP    ed_in

; ed_add -- type the selected character, if there is room ($7F types nothing).
        RFIT    77
ed_add: LDV     V_OSK
        XRI     7FH-20H
        BZ      ed_bad
        LDV     V_EDLEN
        STR     R2
        LDV     V_EDMAX
        SM
        BZ      ed_bad                  ; full
        LDN     R2
        ADI     LO(V_EDIT)
        PLO     R8
        LDI     HI(V_EDIT)
        PHI     R8
        LDV     V_OSK
        ADI     20H
        STR     R8
        INC     R8
        LDI     0
        STR     R8
        LDV     V_EDLEN
        ADI     1
        STR     RB
        BR      ed_shw
ed_del: LDV     V_EDLEN
        BZ      ed_bad
        SMI     1
        STR     RB
        ADI     LO(V_EDIT)
        PLO     R8
        LDI     HI(V_EDIT)
        PHI     R8
        LDI     0
        STR     R8
ed_shw: FCALL   ed_text
        FJMP    ed_in
ed_bad: LDI     8
        PLO     RD
        FJMP    ed_in
; <<<

; >>> fujinet-config 86c763d studio2/src/edit.inc: the grid and the text
; ed_grid -- characters $20-$7F from row 3: the engine wraps each row.
        RFIT    24
ed_grid:
        LDI     30H
        FCALL   d_at
        LDI     20H
        PLO     R8
        LDI     TX_PUTC
        PHI     RF
edg1:   GLO     R8
        PLO     RF
        LDN     RF
        INC     R8
        GLO     R8
        XRI     80H
        BNZ     edg1
        LDI     FN_PARK
        PHI     RF
        FRET

; ed_sel  -- paint cell D inverse: the keyboard's cursor.
; ed_cell -- paint cell D plain.
        RFIT    27
ed_sel: PLO     R9
        LDI     TOP_INV_ON
        FCALL   d_op
        GLO     R9
        FCALL   ed_cell
        LDI     TOP_INV_OFF
        FJMP    d_op
ed_cell:
        PLO     R9
        ADI     30H
        FCALL   d_at
        GLO     R9
        ADI     20H
        FJMP    d_putc

; ed_text -- row 1: the text's last 14 characters, then the selected key as
; an inverse block cursor (what 5 would type), short of the row's end so
; CLREOL never wraps onto row 2.
        RFIT    54
ed_text:
        LDI     10H
        FCALL   d_at
        LDV     V_EDLEN
        SMI     15
        BNF     edt1
        LDV     V_EDLEN
        ADI     LO(V_EDIT)-14
        BR      edt2
edt1:   LDI     LO(V_EDIT)
edt2:   PLO     R8
        LDI     HI(V_EDIT)
        PHI     R8
        FCALL   d_puts
        LDI     TOP_INV_ON
        FCALL   d_op
        LDV     V_OSK
        ADI     20H
        FCALL   d_putc
        LDI     TOP_INV_OFF
        FCALL   d_op
        LDI     TOP_CLREOL
        FJMP    d_op
; <<<
