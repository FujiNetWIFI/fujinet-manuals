; The Atari 8-bit's custom charset and display list, in ROM. graphics.c copies
; the charset into RAM, where it is rewritten for the game board, and ANTIC
; reads the display list from here. Keep SCREEN in step with graphics.c.

        .export _charset, _displayList

SCREEN = $3400

        .segment "FONT"
_charset:
        .incbin "support/atari/charset.fnt"

; 26 lines of mode 4 under 16 blank ones, as the 8-bit's
        .segment "DLIST"
_displayList:
        .byte   $70, $70
        .byte   $44, <SCREEN, >SCREEN
        .repeat 25
        .byte   $04
        .endrepeat
        .byte   $41, <_displayList, >_displayList
