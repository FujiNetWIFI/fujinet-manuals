/*
 * EXPRINT -- the exerciser for the printer (40H), in C: EXPRINT.ASM's
 * twin. A line of text with WRITE, another with PUT, the printer's
 * STATUS, and the ways the printer goes wrong: STATUS without its
 * field, WRITE with nothing to print, and WRITEs of 256 and 300 bytes,
 * which the firmware counts in a byte (more than 320 would overrun its
 * buffer, so none are sent).
 *
 * fujinet-lib has no printer calls, so these go out through
 * fuji_bus_call(). What was printed lands in the file PAPER on
 * FujiNet's SD card.
 *
 * The book's printer cards are cut from this file: see
 * tools/EXERCISERS.md.
 *
 * Copyright (C) 2026 Thomas Cherryhomes
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#include <stdio.h>
#include <string.h>
#include <fujinet-bus.h>
#include <fujinet-commands.h>
#include "h89con.h"
#include "exlog.h"

static uint8_t pstat[4];
static uint8_t big[300];

//@ex printer.write
static const char line[] = "Printed on the H89 through FujiNet.\r\n";
//@end
//@ex printer.put
static const char line2[] = "And this line went by PUT.\r\n";
//@end

/* big = text, dashes, and RETURN, LINE FEED at big[n], big[n+1] */
static void fill(const char *text, uint16_t n)
{
    memset(big, '-', sizeof big);
    memcpy(big, text, strlen(text));
    big[n] = '\r';
    big[n + 1] = '\n';
}

int main(void)
{
    bool ok;

    con_init(0);

    ex_mark("printer.write");
//@ex printer.write
    /* fujinet-lib has no printer calls: fuji_bus_call sends it */
    ok = fuji_bus_call(FUJI_DEVICEID_PRINTER, PRINTERCMD_WRITE,
                       FUJI_FIELD_DATA, 0, 0, 0, 0,
                       line, sizeof line - 1);     /* not the NUL */
//@end
    ex_show(ok);

    ex_mark("printer.put");
//@ex printer.put
    ok = fuji_bus_call(FUJI_DEVICEID_PRINTER, PRINTERCMD_PUT,
                       FUJI_FIELD_DATA, 0, 0, 0, 0,
                       line2, sizeof line2 - 1);   /* WRITE, renamed */
//@end
    ex_show(ok);

    ex_mark("printer.status");
//@ex printer.status
    /* one field, any value, but it must be there */
    ok = fuji_bus_call(FUJI_DEVICEID_PRINTER, PRINTERCMD_STATUS,
                       FUJI_FIELD_A1 | FUJI_FIELD_REPLY, 0, 0, 0, 0,
                       pstat, 4);
    if (ok)             /* 0, a byte nobody set, the timeout (5), 0 */
        printf("\n%02X %02X %02X %02X",
               pstat[0], pstat[1], pstat[2], pstat[3]);
//@end
    ex_showb(ok, pstat, 4);

    ex_mark("printer.status.nofield");
//@ex printer.status.nofield
    ok = fuji_bus_call(FUJI_DEVICEID_PRINTER, PRINTERCMD_STATUS,
                       FUJI_FIELD_REPLY, 0, 0, 0, 0,
                       pstat, 4);                   /* no field: NAK */
//@end
    ex_show(ok);

    ex_mark("printer.write.empty");
//@ex printer.write.empty
    ok = fuji_bus_call(FUJI_DEVICEID_PRINTER, PRINTERCMD_WRITE,
                       FUJI_FIELD_DATA, 0, 0, 0, 0,
                       NULL, 0);                    /* nothing: NAK */
//@end
    ex_show(ok);

    fill("This 256-byte line never reaches the paper.", 254);
    ex_mark("printer.write.256");
//@ex printer.write.256
    /* 256 bytes: ACK, and nothing printed (256 is 0 in a byte) */
    ok = fuji_bus_call(FUJI_DEVICEID_PRINTER, PRINTERCMD_WRITE,
                       FUJI_FIELD_DATA, 0, 0, 0, 0, big, 256);
//@end
    ex_show(ok);

    fill("Of 300 bytes sent, just these 44 print out\r\n", 298);
    ex_mark("printer.write.300");
//@ex printer.write.300
    /* 300 bytes: ACK, and the first 44 printed (300 - 256) */
    ok = fuji_bus_call(FUJI_DEVICEID_PRINTER, PRINTERCMD_WRITE,
                       FUJI_FIELD_DATA, 0, 0, 0, 0, big, 300);
//@end
    ex_show(ok);

    ex_done();
    con_exit();
    return 0;
}
