/*
 * hdosargs.c -- the command line under HDOS: see hdosargs.h.
 *
 * HDOS starts a program with SP pointing at the first character of its
 * arguments; they run up to a NUL at 227FH. With no arguments SP is 2280H.
 * The start-up code keeps the entry SP inside its own exit code, as the
 * operand of "ld sp,nnnn" at __restore_sp_onexit, so it can be read back
 * from there.
 *
 * Copyright (C) 2026 Thomas Cherryhomes
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#ifdef __HDOS__
#include "hdosargs.h"

extern unsigned char _restore_sp_onexit[];   /* asm: __restore_sp_onexit */

static char *args_v[HDOS_MAXARGS + 2];
static char args_name[] = "";

int hdos_args(char ***argvp)
{
    char *p = *(char **)(_restore_sp_onexit + 1);   /* the entry SP */
    char *end = (char *)0x227F;
    int n = 0;

    args_v[n++] = args_name;
    while (p < end && n <= HDOS_MAXARGS) {
        while (p < end && *p == ' ')
            p++;
        if (p >= end || *p == 0)
            break;
        args_v[n++] = p;
        while (p < end && *p != ' ' && *p != 0)
            p++;
        if (p < end && *p == ' ')
            *p++ = 0;
    }
    args_v[n] = 0;
    *argvp = args_v;
    return n;
}
#endif
