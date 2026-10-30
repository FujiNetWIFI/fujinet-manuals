; book.inc -- what the handbook's own assembly programs share beyond the
; bring-up's fujinet.inc: their zero page, and the PUTS macro.
;
; a52.cfg starts the ZEROPAGE segment at $19, which is also KEY, the byte
; a52init.s's keypad handler writes. These programs leave the segment
; empty: variables go in BSS ($0300 up), and the few pointers that must be
; in zero page sit here, above fujilib's $E0-$ED.
PTR1    = $F0                   ; a pointer (2 bytes)
PTR2    = $F2                   ; another (2 bytes)
ZTMP    = $F4                   ; scratch (2 bytes)

; PUTS row, col, str -- the NUL-terminated string at str, from (row, col).
.macro  PUTS    row, col, str
        lda     #row
        ldx     #col
        jsr     disp_at
        lda     #<str
        sta     FN_PTR
        lda     #>str
        sta     FN_PTR+1
        jsr     disp_str
.endmacro

; WAITFRAME -- until the VBI next counts a frame. Clobbers A.
.macro  WAITFRAME
        .local  w
        lda     RTCLOKL
w:      cmp     RTCLOKL
        beq     w
.endmacro
