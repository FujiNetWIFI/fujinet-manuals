; ppu.s -- PPU writes through cc65's NMI-flushed ring buffer.
;
; The game draws whenever it likes; the writes queue here and the NES runtime's
; vblank handler (crt0.s nmi -> ppubuf_flush) lands them while rendering is
; off. ppubuf_put blocks when the queue is full, so this needs NMI enabled --
; initGraphics() turns it on before the first call.

        .export         _ppu_put, _ppu_drain
        .import         popax, ppubuf_put, ppubuf_waitempty
        .importzp       tmp1

; void __fastcall__ ppu_put(unsigned addr, unsigned char val)
.proc   _ppu_put
        sta     tmp1
        jsr     popax           ; A = addr low, X = addr high
        pha
        txa
        tay                     ; Y = high
        pla
        tax                     ; X = low
        lda     tmp1
        jmp     ppubuf_put      ; A = value, X = low, Y = high
.endproc

; void ppu_drain(void) -- wait until NMI has landed every queued write
.proc   _ppu_drain
        jmp     ppubuf_waitempty
.endproc
