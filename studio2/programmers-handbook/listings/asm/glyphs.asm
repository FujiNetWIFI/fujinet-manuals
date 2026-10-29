; glyphs.asm -- the text engine draws more than
; text: 32 glyphs of your own, 16 tiles and the
; mosaic cells built from them, repeats and
; inverse video.
;
; A GLYPH is 12 row bytes, bit 3 the leftmost of
; its four dots. Four of them make an 8 x 24 dot
; FujiNet mark. A TILE is 2 dots by 4 lines, four
; row bytes, bit 1 the left dot; a MOSAIC cell is
; 2 x 3 tiles, a byte for each third (left tile
; in the high nibble).

        CPU     1802
        INCLUDE "fujinet.inc"
        INCLUDE "s2macro.inc"
        INCLUDE "s2defs.inc"

        ORG     0400H
        INCLUDE "s2call.inc"
        INCLUDE "fujilib.inc"
        INCLUDE "fujidisp.inc"

        ORG     0C00H
        INCLUDE "booklib.inc"

        FIT     120
main:   FCALL   d_cls
        PUTS    00H, t_title
        ; four glyphs, then the mark from them
        LDR     RA, g_mark
        LDI     4
        PLO     RB
gl1:    LDI     13              ; code + 12 rows
        FCALL   params
        LDI     TOP_GLYPH
        FCALL   d_op
        DEC     RB
        GLO     RB
        BNZ     gl1
        PUTS    20H, t_glyph
        LDI     28H
        FCALL   d_at
        LDI     80H
        FCALL   d_putc
        LDI     81H
        FCALL   d_putc
        LDI     38H
        FCALL   d_at
        LDI     82H
        FCALL   d_putc
        LDI     83H
        FCALL   d_putc
        FJMP    tiles

; params -- push D bytes from RA as parameters.
        FIT     16
params: PLO     R9
prm1:   LDA     RA
        FCALL   d_par
        DEC     R9
        GLO     R9
        BNZ     prm1
        FRET

        FIT     120
tiles:  LDR     RA, t_tiles     ; tiles 0, 1, 2
        LDI     3
        PLO     RB
tl1:    LDI     5               ; tile + 4 rows
        FCALL   params
        LDI     TOP_TILE
        FCALL   d_op
        DEC     RB
        GLO     RB
        BNZ     tl1
        PUTS    50H, t_mosaic
        LDI     56H
        FCALL   d_at
        LDR     RA, m_cells     ; five cells
        LDI     15
        FCALL   params
        LDI     TOP_MOSAIC
        FCALL   d_op
        PUTS    70H, t_rpt
        LDI     77H
        FCALL   d_at
        LDI     SYM_BLOCK       ; REPEAT char, count
        FCALL   d_par
        LDI     6
        FCALL   d_par
        LDI     TOP_REPEAT
        FCALL   d_op
        LDI     TOP_INV_ON
        FCALL   d_op
        PUTS    80H, t_inv
        LDI     TOP_INV_OFF
        FCALL   d_op
hang:   BR      hang

; the mark: dots of 2 x 6, four glyphs of 4 x 12
g_mark: DB      80H                     ; top left
        DB      1,1,1,1,1,1,0,0,0,0CH,0CH,0CH
        DB      81H             ; top right
        DB      8,8,8,8,8,8,0,0,0,3,3,3
        DB      82H             ; bottom left
        DB      0CH,0CH,0CH,0,0,0,0,0,0,0,0,0
        DB      83H             ; bottom right
        DB      3,3,3,0,0,0,3,3,3,3,3,3
; tiles: blank, solid, a checker
t_tiles: DB     0, 0, 0, 0, 0
        DB      1, 3, 3, 3, 3
        DB      2, 2, 1, 2, 1
; a pyramid on a checkered sky, five cells
m_cells: DB     22H, 22H, 11H
        DB      22H, 11H, 11H
        DB      11H, 11H, 11H
        DB      22H, 11H, 11H
        DB      22H, 22H, 11H
t_title: DB     "GLYPHS, TILES", 0
t_glyph: DB     "GLYPH", 0
t_mosaic: DB    "MOSAIC", 0
t_rpt:   DB     "REPEAT", 0
t_inv:   DB     "INVERSE", 0

        S2CLAIM
