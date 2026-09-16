; Override z88dk's 256-byte __tms9918_scroll_buffer.
;
; The library sizes that buffer for a whole GRAPHICS II text row -- 32 cells of
; 8 pattern bytes -- because scrolling one row means staging one row. A quarter
; of the ColecoVision's entire 1K of RAM, for a client that never scrolls: this
; screen is drawn by absolute positioning, and initGraphics() sets bit 6 of
; generic_console_flags, which is what makes the console skip its scrollup call
; outright (see fputc_cons_generic.inc). The two go together -- shrink this
; without disabling the scroll and a status line printed to the last column of
; row 23 walks 256 bytes through the globals.
;
; What is left is the only other use of the symbol on this path:
; __tms9918_mode2_printc stages one 8-byte glyph here before LDIRVM'ing it into
; VRAM. 16 is that, with room to spare.
;
; Defining it here keeps the library module unreferenced, so the linker never
; pulls it in.

    SECTION bss_user

    PUBLIC  __tms9918_scroll_buffer

__tms9918_scroll_buffer:
    defs    16


; z88dk's console flags byte, under the name sccz80 gives a C extern. Bit 6
; disables vertical scrolling; initGraphics() sets it. Same aliasing idiom
; z88dk itself uses for joystick -> coleco_joypad.

    SECTION code_user

    EXTERN  generic_console_flags
    PUBLIC  _generic_console_flags

    defc    _generic_console_flags = generic_console_flags
