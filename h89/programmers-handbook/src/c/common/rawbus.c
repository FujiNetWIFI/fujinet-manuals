/*
 * rawbus.c -- FujiBus frames out, bare bytes in: see rawbus.h.
 *
 * The 82C55A at D0H is driven as fujinet-lib's bus/h89/portio.c does:
 * port A carries the bytes, straight to the ESP32, which drives it through
 * /ACK; /OBF high says the ESP32 has taken our last byte, IBF says a byte
 * waits for us.
 *
 * Copyright (C) 2026 Thomas Cherryhomes
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#include <arch/z80.h>
#include "h89con.h"                     /* TICKS: the 2 ms clock */
#include "rawbus.h"

#define PORTA   0xD0
#define PORTC   0xD2
#define OBF     0x80                    /* PC7 /OBF: 1 = byte taken */
#define IBF     0x20                    /* PC5 IBF: 1 = a byte waits */

#define END     0xC0                    /* SLIP */
#define ESC     0xDB

#define FIRST   (2 * TICKS_PER_SECOND)  /* raw_get: the first byte, */
#define QUIET   (TICKS_PER_SECOND / 5)  /*   then this much quiet */

static const uint8_t nbytes[8] = { 0, 1, 2, 3, 4, 2, 4, 4 };

/* drop what an earlier reply left */
static void begin(void)
{
    while (z80_inp(PORTC) & IBF)
        z80_inp(PORTA);
}

/* one byte out, once the last has been taken */
static void put(uint8_t c)
{
    while (!(z80_inp(PORTC) & OBF))
        ;
    z80_outp(PORTA, c);
}

/* wait for the last byte to be taken */
static void end(void)
{
    while (!(z80_inp(PORTC) & OBF))
        ;
}

/* n bytes, SLIP-escaped */
static void slip(const uint8_t *p, uint16_t n)
{
    for (; n; n--, p++) {
        if (*p == END) {
            put(ESC);
            put(0xDC);
        } else if (*p == ESC) {
            put(ESC);
            put(0xDD);
        } else
            put(*p);
    }
}

/* the FujiBus checksum: an 8-bit sum with the carries added back */
static uint8_t sum(uint8_t chk, const uint8_t *p, uint16_t n)
{
    uint16_t c = chk;

    for (; n; n--) {
        c += *p++;
        c = (c >> 8) + (c & 0xFF);
    }
    return c;
}

void raw_frame(uint8_t dev, uint8_t cmd, uint8_t fields,
               uint8_t a1, uint8_t a2, uint8_t a3, uint8_t a4,
               const void *data, uint16_t len)
{
    uint8_t h[10];
    uint8_t n = 6 + nbytes[fields & 7];
    uint16_t total = n + len;

    h[0] = dev;                         /* the header */
    h[1] = cmd;
    h[2] = total;                       /* whole packet, low byte 1st */
    h[3] = total >> 8;
    h[4] = 0;                           /* checksum, below */
    h[5] = fields & 7;                  /* the descriptor */
    h[6] = a1;                          /* the fields: n - 6 of these */
    h[7] = a2;
    h[8] = a3;
    h[9] = a4;
    h[4] = sum(sum(0, h, n), data, len);

    begin();
    put(END);
    slip(h, n);
    slip(data, len);
    put(END);
    end();
}

void raw_put(const void *data, uint16_t len)
{
    const uint8_t *p = data;

    begin();
    for (; len; len--)
        put(*p++);
    end();
}

uint16_t raw_get(void *buf, uint16_t size)
{
    uint8_t *p = buf;
    uint16_t n = 0, t0 = TICKS, wait = FIRST;

    while (n < size && (uint16_t)(TICKS - t0) < wait) {
        if (z80_inp(PORTC) & IBF) {
            p[n++] = z80_inp(PORTA);
            t0 = TICKS;
            wait = QUIET;
        }
    }
    return n;
}
