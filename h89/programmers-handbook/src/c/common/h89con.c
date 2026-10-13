/*
 * h89con.c -- the H19 console, raw: see h89con.h.
 * After Battleship's src/h89/console.c.
 *
 * Copyright (C) 2026 Thomas Cherryhomes
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#include <string.h>
#include "h89con.h"

#ifdef __HDOS__

/* HDOS system calls are RST 38H and a function byte. */
void con_putc(uint8_t c) __z88dk_fastcall __naked
{
#asm
    ld      a,l
    rst     38h
    defb    2               ; .SCOUT
    ret
#endasm
}

int con_getc(void) __naked
{
#asm
    rst     38h
    defb    1               ; .SCIN: carry set when nothing waits
    ld      hl,-1
    ret     c
    ld      l,a
    ld      h,0
    ret
#endasm
}

/* .CONSL: A = which console byte, B = the bits to set, C = the bits to
   change. The five bytes, S.CSLMD to S.CONFL, sit at 20D6H. */
static uint8_t cs_index, cs_bits, cs_mask;

static void consl(void) __naked
{
#asm
    ld      a,(_cs_bits)
    ld      b,a
    ld      a,(_cs_mask)
    ld      c,a
    ld      a,(_cs_index)
    rst     38h
    defb    6               ; .CONSL
    ret
#endasm
}

static void consl_set(uint8_t index, uint8_t bits, uint8_t mask)
{
    cs_index = index;
    cs_bits = bits;
    cs_mask = mask;
    consl();
}

#define S_CSLMD ((uint8_t *)0x20D6)
#define I_CSLMD 0               /* mode */
#define I_CONTY 1               /* type */
#define I_CONWI 3               /* width */
#define CSL_ECH 0x80            /* no echo */
#define CSL_RAW 0x04            /* no CTRL-C, -S, -O, -P */
#define CSL_WRP 0x02            /* wrap at the width */
#define CSL_CHR 0x01            /* a character at a time */
#define CTP_MLI 0x20            /* lower to upper case, in */
#define CTP_MLO 0x10            /* lower to upper case, out */
#define CTP_BKM 0x02            /* BACKSPACE becomes RUBOUT, in */

static uint8_t saved[5];

void con_init(uint8_t raw)
{
    memcpy(saved, S_CSLMD, sizeof saved);
    consl_set(I_CONTY, 0, CTP_MLI | CTP_MLO | CTP_BKM);
    if (raw) {
        consl_set(I_CSLMD, CSL_ECH | CSL_RAW | CSL_CHR,
                  CSL_ECH | CSL_RAW | CSL_WRP | CSL_CHR);
        consl_set(I_CONWI, 255, 0xFF);   /* escape sequences are not columns */
    }
}

void con_exit(void)
{
    consl_set(I_CSLMD, saved[I_CSLMD], 0xFF);
    consl_set(I_CONTY, saved[I_CONTY], 0xFF);
    consl_set(I_CONWI, saved[I_CONWI], 0xFF);
}

#else /* CP/M */

/* The BIOS jump table: (0001H) points at WBOOT, at its base + 3; CONST is
   3 bytes on from there, CONIN 6, CONOUT 9. The BIOS may use any register,
   so IX and IY are kept for the C code. */
void con_putc(uint8_t c) __z88dk_fastcall __naked
{
#asm
    EXTERN  l_dcal
    push    ix
    push    iy
    ld      c,l
    ld      hl,(1)
    ld      de,9
    add     hl,de
    call    l_dcal          ; CONOUT
    pop     iy
    pop     ix
    ret
#endasm
}

int con_getc(void) __naked
{
#asm
    EXTERN  l_dcal
    push    ix
    push    iy
    ld      hl,(1)
    ld      de,3
    add     hl,de
    call    l_dcal          ; CONST: A = FFH when a key waits
    or      a
    ld      hl,-1
    jr      z,con_getc_none
    ld      hl,(1)
    ld      de,6
    add     hl,de
    call    l_dcal          ; CONIN
    ld      l,a
    ld      h,0
con_getc_none:
    pop     iy
    pop     ix
    ret
#endasm
}

void con_init(uint8_t raw)
{
    (void)raw;              /* the BIOS calls are raw already */
}

void con_exit(void)
{
}

#endif

void con_puts(const char *s)
{
    while (*s)
        con_putc(*s++);
}
