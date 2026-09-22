/*
 * DWPORT.C --- DWRead and DWWrite for OS-9
 *
 * Under Disk BASIC the ROM hands you these two at [$D93F] and
 * [$D941], and every other program in this book calls them.
 * Under OS-9 that ROM is not mapped and you must supply them.
 *
 * These are for the memory-mapped ports: the Becker port, the
 * CoCo 3 FPGA's DriveWire window, and the high-speed UART
 * cartridge.  Status at $FF41, data at $FF42.  There is no
 * timing to get right --- you poll a bit and move a byte.
 *
 * For the bit-banger port, which is what a FujiNet cartridge
 * plugs into on a stock machine, DWRead and DWWrite are
 * cycle-counted routines that live in the DriveWire and
 * NitrOS-9 sources.  Take them from there, put them behind
 * these two names, and nothing above this file changes.  That
 * is the whole argument for building on the vectors.
 *
 * Two details that are easy to miss:
 *
 * The interrupt mask.  These ports hold one byte.  An OS-9
 * clock tick in the wrong place loses it.  Frames are short
 * and the mask is shorter than the transfer.
 *
 * The timeout.  The ROM's DWRead gives up after about a
 * second, and FN_WAIT depends on that: it asks again when the
 * adapter is busy.  A poll loop with no timeout would hang
 * there forever instead, so this one counts.
 */

#include <cmoc.h>
#include "dwport.h"

byte dwread(byte *s, int l)
{
    asm
    {
        pshs    cc,x,y,u
        orcc    #$50            ; the port holds exactly one byte
        ldx     :s
        ldy     :l
        beq     @ok
@byte   ldu     #$2000          ; about a tenth of a second
@wait   lda     $FF41           ; DriveWire status
        bita    #$02            ; a byte waiting?
        bne     @got
        leau    -1,u
        bne     @wait
        bra     @timeout
@got    lda     $FF42           ; DriveWire data
        sta     ,x+
        leay    -1,y
        bne     @byte
@ok     puls    cc,x,y,u
        ldb     #1              ; every byte arrived
        bra     @exit
@timeout
        puls    cc,x,y,u
        clrb                    ; it went quiet on us
@exit
    }
}

byte dwwrite(byte *s, int l)
{
    asm
    {
        pshs    cc,x,y
        orcc    #$50
        ldx     :s
        ldy     :l
        beq     @done
@more   lda     ,x+
        sta     $FF42
        leay    -1,y
        bne     @more
@done   puls    cc,x,y
        clrb
    }
}
