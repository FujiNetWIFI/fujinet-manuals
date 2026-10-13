/*
 * CMDPROBE -- which bytes below 2280H does HDOS change while a program
 * runs? Copies 2100H-227FH before anything is printed, prints, and lists
 * the bytes that moved.
 *
 * Copyright (C) 2026 Thomas Cherryhomes
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#include <stdio.h>
#include <string.h>
#include <stdint.h>

static unsigned char before[0x180], after[0x180];

int main(int argc, char *argv[])
{
    unsigned i, first = 0xFFFF, last = 0;
    memcpy(before, (void *)0x2100, sizeof before);
    printf("CMDPROBE %d ARGS\n", argc);
    printf("THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG\n");
    memcpy(after, (void *)0x2100, sizeof after);
    for (i = 0; i < sizeof before; i++)
        if (before[i] != after[i]) {
            if (first == 0xFFFF) first = i;
            last = i;
        }
    if (first == 0xFFFF) { printf("NOTHING CHANGED\n"); first = last = 0; }
    printf("CHANGED %04X-%04X\n", 0x2100 + first, 0x2100 + last);
    for (i = first & ~15; i <= last; i++) {
        if ((i & 15) == 0) printf("\n%04X ", 0x2100 + i);
        printf(before[i] != after[i] ? "%02X*" : "%02X ", after[i]);
    }
    printf("\nAT ENTRY TO MAIN:");
    for (i = 0x150; i < 0x180; i++) {
        if ((i & 15) == 0) printf("\n%04X ", 0x2100 + i);
        printf("%02X ", before[i]);
    }
    for (i = 0; i < argc; i++) printf("\nARGV[%d] %04X '%s'", i, (unsigned)argv[i], argv[i]);
    printf("\nENDPROBE\n");
    return 0;
}
