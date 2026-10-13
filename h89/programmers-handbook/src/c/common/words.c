/*
 * words.c -- the command line, or questions if there is none: see words.h.
 *
 * Copyright (C) 2026 Thomas Cherryhomes
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include "words.h"

static void ask(const char *q, char *a, int size)
{
    char *nl;

    fputs(q, stdout);
    fflush(stdout);
    if (!fgets(a, size, stdin))
        a[0] = 0;
    if ((nl = strchr(a, '\n')) != NULL)
        *nl = 0;
    if ((nl = strchr(a, '\r')) != NULL)
        *nl = 0;
}

int two_words(int argc, char **argv, const char *q1, char *a1, int size1,
              const char *q2, char *a2, int size2)
{
    if (argc >= 3) {
        strncpy(a1, argv[1], size1 - 1);
        a1[size1 - 1] = 0;
        strncpy(a2, argv[2], size2 - 1);
        a2[size2 - 1] = 0;
    } else if (argc == 1) {
        ask(q1, a1, size1);
        ask(q2, a2, size2);
    } else
        return -1;
    return a1[0] && a2[0] ? 0 : -1;
}

void net_spec(char *s)
{
    if (toupper(s[0]) == 'N' && (s[1] == ':' || s[2] == ':'))
        return;
    memmove(s + 2, s, strlen(s) + 1);
    s[0] = 'N';
    s[1] = ':';
}
