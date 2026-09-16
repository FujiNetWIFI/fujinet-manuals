; Override z88dk's 256-byte __tms9918_scroll_buffer.
;
; The library sizes that buffer for a whole GRAPHICS II text row -- 32 cells of
; 8 pattern bytes -- because scrolling one row means staging one row. A quarter
; of the ColecoVision's entire 1K of RAM, for a client that never scrolls:
; battleship never prints through the console at all, every cell is drawn by
; absolute-positioned vdp writes in src/coleco/graphics.c. The symbol is still
; referenced by the mode-2 machinery vdp_set_mode(2) pulls in, so it has to
; exist; 16 bytes covers the one remaining use (a staged glyph).
;
; Defining it here keeps the library module unreferenced, so the linker never
; pulls the 256-byte one in.

    SECTION bss_user

    PUBLIC  __tms9918_scroll_buffer

__tms9918_scroll_buffer:
    defs    16
