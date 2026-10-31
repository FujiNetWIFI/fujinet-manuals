; antic_dl.s -- vendored from fujinet-config atari5200/ (main cb44218). The
; font is the bring-up clients' (tools/mkfont.py), so both languages' screens match.

        .export _mt_dlist, _mt_font

SCREEN = $3C00

        .segment "DLIST"
_mt_dlist:
        .byte   $70, $70, $70                   ; 24 blank lines
        .byte   $42, <SCREEN, >SCREEN           ; mode 2, from the screen
        .repeat 23
        .byte   $02
        .endrepeat
        .byte   $41, <_mt_dlist, >_mt_dlist     ; wait for the next frame

        .segment "FONT"
_mt_font:
        .include "font.inc"
