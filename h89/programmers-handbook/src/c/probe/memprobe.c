/*
 * MEMPROBE -- where a z88dk program sits on the H89: its load address, the
 * end of its data, the stack, the top of user memory, and what the command
 * line said. Built with the book's link options, it shows they work.
 *
 * Copyright (C) 2026 Thomas Cherryhomes
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#include <stdio.h>
#include <stdint.h>
#include "hdosargs.h"

int main(int argc, char *argv[]);
static unsigned char probe_bss[16];

static uint16_t sp_now(void) __naked
{
#asm
    ld      hl,0
    add     hl,sp
    ret
#endasm
}

int main(int argc, char *argv[])
{
    int i;
    ARGS(argc, argv);
    printf("MEMPROBE\n");
    printf("  main     %04X\n", (unsigned)main);
    printf("  bss      %04X\n", (unsigned)probe_bss);
    printf("  sp       %04X\n", sp_now());
#ifdef __HDOS__
    printf("  S.SYSM   %04X\n", *(uint16_t *)0x20D0);
    printf("  S.USRM   %04X\n", *(uint16_t *)0x20D2);
#else
    printf("  BDOS     %04X\n", *(uint16_t *)0x0006);
#endif
    printf("  argc     %d\n", argc);
    for (i = 0; i < argc; i++)
        printf("  argv[%d]  '%s'\n", i, argv[i]);
    return 0;
}
