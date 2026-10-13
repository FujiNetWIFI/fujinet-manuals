/*
 * exlog.c -- the C exercisers' markers and reports: see exlog.h.
 *
 * Copyright (C) 2026 Thomas Cherryhomes
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#include <stdio.h>
#include <string.h>
#include <fujinet-bus.h>
#include "exlog.h"

#define MARK_DEV 0x0F

void ex_mark(const char *key)
{
    printf("\n@ex %s", key);
    fuji_bus_call(MARK_DEV, 0x00, FUJI_FIELD_NONE, 0, 0, 0, 0, key, strlen(key));
}

void ex_show(bool ok)
{
    printf("\n%s", ok ? "ACK" : "NAK");
}

void ex_showb(bool ok, const void *buf, uint16_t len)
{
    const uint8_t *p = buf;
    uint16_t i;

    ex_show(ok);
    printf(" %u", len);
    for (i = 0; i < len && i < 24; i++)
        printf(" %02X", p[i]);
    if (len > 24)
        printf("...");
}

void ex_done(void)
{
    printf("\n@done\n");
}
