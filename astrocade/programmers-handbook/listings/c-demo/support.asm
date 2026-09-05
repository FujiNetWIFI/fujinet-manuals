; support.asm -- the two things C cannot say on this target.
;
; 1. fputc_cons_native: z88dk's classic runtime insists every target has a
;    console driver; the incomplete +astrocde target ships none, and this
;    demo paints screen RAM itself, so a stub satisfies the linker.
; 2. port_out: sccz80 has no port intrinsics here.  Arguments are pushed
;    left to right and widened to 16 bits, so at entry the value sits at
;    SP+2 and the port at SP+4; the caller cleans up.

        SECTION code_clib

        PUBLIC  fputc_cons_native
fputc_cons_native:
        ret

        PUBLIC  _port_out
_port_out:
        ld      hl,2
        add     hl,sp
        ld      a,(hl)          ; value (low byte of the widened arg)
        inc     hl
        inc     hl
        ld      c,(hl)          ; port
        out     (c),a
        ret
