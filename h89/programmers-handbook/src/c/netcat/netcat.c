/*
 * NETCAT -- the H89 as a terminal on the network, in C. Opens a connection
 * (a TELNET or TCP devicespec, from the command line or asked for), then
 * passes keys out and bytes in until the far end hangs up or CTRL-] is
 * struck. The H19 is put in ANSI mode for the session, since that is what
 * bulletin boards speak, and back in Heath mode after. NETCAT.ASM's twin.
 *
 *   NETCAT N:TELNET://BBS.FOZZTEXX.COM/      or just NETCAT, and answer
 *
 *   tools/cc.sh hdos NETCAT src/c/netcat/netcat.c src/c/common/h89con.c \
 *       src/c/common/hdosargs.c                       ->  NETCAT.ABS
 *   tools/cc.sh cpm NETCAT ...the same...             ->  NETCAT.COM
 *
 * Copyright (C) 2026 Thomas Cherryhomes
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <fujinet-network.h>
#include "h89con.h"
#include "hdosargs.h"

#define QUIT_KEY 0x1D           /* CTRL-] ends the session */
#define BUFSZ    512            /* bytes taken from the FujiNet at once */
#define DEFAULT  "N:TELNET://BBS.FOZZTEXX.COM/"

static char spec[124];
static char line[120];
static uint8_t rxbuf[BUFSZ];

/* a line typed at the keyboard, shown as it is typed */
static void getline(char *buf, uint8_t size)
{
    uint8_t n = 0;
    int c;

    for (;;) {
        while ((c = con_getc()) < 0)
            ;
        if (c == '\r')
            break;
        if ((c == 8 || c == 0x7F) && n) {
            n--;
            con_puts("\b \b");
        } else if (c >= ' ' && n < size - 1) {
            buf[n++] = c;
            con_putc(c);
        }
    }
    buf[n] = 0;
    con_puts("\r\n");
}

/* what was typed, with N: in front unless it has N: or Nn: already */
static void set_spec(const char *s)
{
    if (toupper(s[0]) == 'N' && (s[1] == ':' || s[2] == ':'))
        strcpy(spec, s);
    else {
        strcpy(spec, "N:");
        strcat(spec, s);
    }
}

int main(int argc, char *argv[])
{
    uint16_t avail, len, i;
    uint8_t connected, err;
    int c;

    ARGS(argc, argv);
    con_init(1);
    con_puts("NETCAT - the H89 on the network.  CTRL-] hangs up.\r\n");

//@ex netcat.spec
    if (argc > 1)
        set_spec(argv[1]);
    else {
        con_puts("Connect to (RETURN for BBS.FOZZTEXX.COM): ");
        getline(line, sizeof line);
        set_spec(line[0] ? line : DEFAULT);
    }
//@end
    con_puts("Connecting to ");
    con_puts(spec);
    con_puts("\r\n");

//@ex netcat.open
    if (network_open(spec, 12, 0) != FN_ERR_OK) {   /* read and write */
        con_puts("The FujiNet could not open that.\r\n");
        con_exit();
        return 1;
    }
//@end
    con_puts("\x1B<");                              /* the H19 in ANSI mode */

//@ex netcat.loop
    for (;;) {
        c = con_getc();                             /* a key struck? */
        if (c == QUIT_KEY)
            break;
        if (c >= 0) {
            rxbuf[0] = c;                           /* send it */
            network_write(spec, rxbuf, 1);
        }
        if (network_status(spec, &avail, &connected, &err) != FN_ERR_OK)
            continue;
        if (!avail) {
            if (!connected)                         /* the far end has gone */
                break;
            continue;
        }
        len = avail > BUFSZ ? BUFSZ : avail;        /* take what waits */
        len = network_read(spec, rxbuf, len);
        for (i = 0; i < len; i++)                   /* and type it */
            con_putc(rxbuf[i]);
    }
//@end

    con_puts("\x1B[?2h");                           /* back to Heath mode */
//@ex netcat.close
    network_close(spec);
//@end
    con_puts("\r\nDisconnected.\r\n");
    con_exit();
    return 0;
}
