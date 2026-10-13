/*
 * h89con.h -- the H19 console, raw, under HDOS or CP/M.
 *
 * printf() and friends go through the OS's ordinary console calls, which
 * is fine for text. A program that sends escape sequences, reads keys as
 * they are struck or must not wait for a key uses these instead: HDOS's
 * .SCOUT/.SCIN with the console in raw character mode, or the CP/M BIOS's
 * CONOUT/CONST/CONIN straight from its jump table.
 *
 * Copyright (C) 2026 Thomas Cherryhomes
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#ifndef H89CON_H
#define H89CON_H

#include <stdint.h>

/* The 2 ms clock both systems keep in low memory. */
#ifdef __HDOS__
#define TICKS (*(volatile uint16_t *)0x201B)
#else
#define TICKS (*(volatile uint16_t *)0x000B)
#endif
#define TICKS_PER_SECOND 500

/* raw = 0: just stop HDOS turning lower case into upper case.
   raw = 1: also no echo, no CTRL-C/S/O handling, a character at a time. */
void con_init(uint8_t raw);
void con_exit(void);                    /* the console as it was */
void con_putc(uint8_t c) __z88dk_fastcall;
int  con_getc(void);                    /* a key, or -1 if none waits */
void con_puts(const char *s);

#endif
