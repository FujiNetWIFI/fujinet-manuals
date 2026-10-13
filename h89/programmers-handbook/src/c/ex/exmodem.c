/*
 * EXMODEM -- the exerciser for the modem (50H), in C: EXMODEM.ASM's
 * twin. The modem is the one device that does not answer in frames:
 * its replies, and everything it hears from the far end, are bare
 * bytes, and an ACK or a NAK is no byte at all. fujinet-lib's
 * fuji_bus_call() would wait 15 s for a frame that never comes, so
 * every request here goes out with raw_frame() and what comes back is
 * taken with raw_get() (src/c/common/rawbus.c).
 *
 * It sends all ten commands the modem knows, dials the test board on
 * 127.0.0.1:7801 with ATDT (in a WRITE, then as bare bytes), shows
 * that AT's OK never comes and +++ no longer escapes, and answers a
 * call on port 7803. Not sent, because each one stops FujiNet: ATCPM,
 * LISTEN on port 0, and the commands whose field is required
 * (SET_DUMP, LISTEN, BAUDRATELOCK, AUTOANSWER, STATUS) without it.
 *
 *   tools/cc.sh hdos EXMODEM src/c/ex/exmodem.c src/c/common/h89con.c \
 *       src/c/common/exlog.c src/c/common/rawbus.c
 *
 * The book's modem cards are cut from this file: see
 * tools/EXERCISERS.md.
 *
 * Copyright (C) 2026 Thomas Cherryhomes
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#include <stdio.h>
#include <fujinet-bus.h>
#include <fujinet-commands.h>
#include "h89con.h"
#include "exlog.h"
#include "rawbus.h"

#define MODEM FUJI_DEVICEID_SERIAL      /* 50H */
#define SEND_FATAL 0                    /* 1 crashes FujiNet */

static uint8_t mstat[2];
static uint8_t mbuf[257];

/* the exerciser's report: RAW, how many bytes, the first of them */
static void ex_raw(const uint8_t *p, uint16_t n)
{
    uint16_t i;

    printf("\nRAW %u", n);
    for (i = 0; i < n && i < 24; i++)
        printf(" %02X", p[i]);
}

//@ex modem.write
/* type the modem's bytes as they come, until 2 s pass with none;
   returns how many came in all */
static uint16_t type_raw(void)
{
    uint16_t n, total = 0;

    while ((n = raw_get(mbuf, sizeof mbuf - 1)) != 0) {
        mbuf[n] = 0;
        printf("%s", (char *)mbuf);
        total += n;
    }
    return total;
}

static const char dial[] = "ATDT127.0.0.1:7801\r";
//@end

int main(void)
{
    uint16_t n;

    con_init(0);

    /* ---- the commands ---- */
    ex_mark("modem.status");
//@ex modem.status
    /* two bare bytes come back, not a frame; the field must be there */
    raw_frame(MODEM, MODEMCMD_STATUS, FUJI_FIELD_A1, 0, 0, 0, 0,
              NULL, 0);
    n = raw_get(mstat, 2);
    if (n == 2)                 /* 0, and C0H+0CH online, +01H data */
        printf("\n%02X %02X", mstat[0], mstat[1]);
//@end
    ex_raw(mstat, n);

    ex_mark("modem.stream");
//@ex modem.stream
    /* nine bare bytes: an Atari POKEY's divisors for the baud rate */
    raw_frame(MODEM, MODEMCMD_STREAM, FUJI_FIELD_NONE, 0, 0, 0, 0,
              NULL, 0);
    n = raw_get(mbuf, 9);
//@end
    ex_raw(mbuf, n);

    ex_mark("modem.configure");
//@ex modem.configure
    /* 9600 baud, whatever is asked; no reply at all */
    raw_frame(MODEM, MODEMCMD_CONFIGURE, FUJI_FIELD_NONE, 0, 0, 0, 0,
              NULL, 0);
//@end
    ex_raw(mbuf, raw_get(mbuf, sizeof mbuf));

    ex_mark("modem.stream.9600");
//@ex modem.stream.9600
    raw_frame(MODEM, MODEMCMD_STREAM, FUJI_FIELD_NONE, 0, 0, 0, 0,
              NULL, 0);
    n = raw_get(mbuf, 9);                   /* 9600 baud's now */
//@end
    ex_raw(mbuf, n);

    ex_mark("modem.baudratelock");
//@ex modem.baudratelock
    /* two fields: lock on, 2400 baud; CONNECT says 2400 from now on */
    raw_frame(MODEM, MODEMCMD_BAUDRATELOCK, FUJI_FIELD_B12_B34,
              1, 0, 2400 & 0xFF, 2400 >> 8, NULL, 0);
//@end
    ex_raw(mbuf, raw_get(mbuf, sizeof mbuf));

    ex_mark("modem.control");
//@ex modem.control
    /* does nothing on the H89, and says nothing */
    raw_frame(MODEM, MODEMCMD_CONTROL, FUJI_FIELD_NONE, 0, 0, 0, 0,
              NULL, 0);
//@end
    ex_raw(mbuf, raw_get(mbuf, sizeof mbuf));

    ex_mark("modem.set_dump");
//@ex modem.set_dump
    /* the traffic log off; the field must be there */
    raw_frame(MODEM, MODEMCMD_SET_DUMP, FUJI_FIELD_A1, 0, 0, 0, 0,
              NULL, 0);
//@end
    ex_raw(mbuf, raw_get(mbuf, sizeof mbuf));

    ex_mark("modem.autoanswer");
//@ex modem.autoanswer
    /* 0: we answer with ATA; the field must be there */
    raw_frame(MODEM, MODEMCMD_AUTOANSWER, FUJI_FIELD_A1, 0, 0, 0, 0,
              NULL, 0);
//@end
    ex_raw(mbuf, raw_get(mbuf, sizeof mbuf));

    /* ---- AT commands, in WRITE frames ---- */
    ex_mark("modem.write.at");
//@ex modem.write.at
    /* the modem takes AT, but its OK is never sent */
    raw_frame(MODEM, MODEMCMD_WRITE, FUJI_FIELD_NONE, 0, 0, 0, 0,
              "AT\r", 3);
//@end
    ex_raw(mbuf, raw_get(mbuf, sizeof mbuf));

    ex_mark("modem.write");
//@ex modem.write
    /* dial the test board, one AT command a WRITE; then type what
       comes: its greeting, and CONNECT a second later */
    raw_frame(MODEM, MODEMCMD_WRITE, FUJI_FIELD_NONE, 0, 0, 0, 0,
              dial, sizeof dial - 1);
    n = type_raw();
//@end
    ex_raw(mbuf, n);

    ex_mark("modem.status.online");
//@ex modem.status.online
    raw_frame(MODEM, MODEMCMD_STATUS, FUJI_FIELD_A1, 0, 0, 0, 0,
              NULL, 0);
    n = raw_get(mstat, 2);                  /* online: 00 CC */
//@end
    ex_raw(mstat, n);

    ex_mark("modem.write.online");
//@ex modem.write.online
    /* online, a WRITE goes to the far end: the board echoes it,
       then shouts it back */
    raw_frame(MODEM, MODEMCMD_WRITE, FUJI_FIELD_NONE, 0, 0, 0, 0,
              "hello\r", 6);
    n = type_raw();
//@end
    ex_raw(mbuf, n);

    ex_mark("modem.write.plus");
//@ex modem.write.plus
    /* +++ and a second of quiet: no OK; it went to the board */
    raw_frame(MODEM, MODEMCMD_WRITE, FUJI_FIELD_NONE, 0, 0, 0, 0,
              "+++", 3);
    n = type_raw();
//@end
    ex_raw(mbuf, n);

    ex_mark("modem.write.ath");
//@ex modem.write.ath
    /* so ATH is data too: the board gets it; the call stays up */
    raw_frame(MODEM, MODEMCMD_WRITE, FUJI_FIELD_NONE, 0, 0, 0, 0,
              "ATH\r", 4);
    n = type_raw();
//@end
    ex_raw(mbuf, n);

    ex_mark("modem.write.bye");
//@ex modem.write.bye
    /* the far end must hang up: BYE to the board; NO CARRIER */
    raw_frame(MODEM, MODEMCMD_WRITE, FUJI_FIELD_NONE, 0, 0, 0, 0,
              "BYE\r", 4);
    n = type_raw();
//@end
    ex_raw(mbuf, n);

    /* ---- AT commands as bare bytes ---- */
    ex_mark("modem.write.raw_dial");
//@ex modem.write.raw_dial
    /* the same ATDT as bare bytes: what is not in a frame goes to
       the modem as typed */
    raw_put(dial, sizeof dial - 1);
    n = type_raw();
//@end
    ex_raw(mbuf, n);

    ex_mark("modem.write.raw_bye");
//@ex modem.write.raw_bye
    raw_put("BYE\r", 4);        /* online: to the far end, as WRITE */
    n = type_raw();
//@end
    ex_raw(mbuf, n);

    /* ---- a call coming in ---- */
    ex_mark("modem.listen");
//@ex modem.listen
    /* take calls on port 7803 (a word): the rig's helper calls, and
       the modem says RING every 3 s */
    raw_frame(MODEM, MODEMCMD_LISTEN, FUJI_FIELD_B12,
              7803 & 0xFF, 7803 >> 8, 0, 0, NULL, 0);
    n = raw_get(mbuf, sizeof mbuf - 1);
    mbuf[n] = 0;
    printf("\n%s", (char *)mbuf);
//@end
    ex_raw(mbuf, n);

    ex_mark("modem.status.ring");
//@ex modem.status.ring
    raw_frame(MODEM, MODEMCMD_STATUS, FUJI_FIELD_A1, 0, 0, 0, 0,
              NULL, 0);
    n = raw_get(mstat, 2);                  /* a caller waits: 00 CD */
//@end
    ex_raw(mstat, n);

    ex_mark("modem.write.ata");
//@ex modem.write.ata
    /* ATA answers (just these 4 bytes); what the caller sent comes
       through, CONNECT a second later */
    raw_frame(MODEM, MODEMCMD_WRITE, FUJI_FIELD_NONE, 0, 0, 0, 0,
              "ATA\r", 4);
    n = type_raw();
//@end
    ex_raw(mbuf, n);

    ex_mark("modem.write.pong");
//@ex modem.write.pong
    /* answer; the caller hangs up: NO CARRIER */
    raw_frame(MODEM, MODEMCMD_WRITE, FUJI_FIELD_NONE, 0, 0, 0, 0,
              "PONG\r\n", 6);
    n = type_raw();
//@end
    ex_raw(mbuf, n);

    ex_mark("modem.unlisten");
//@ex modem.unlisten
    /* no more calls on 7803 */
    raw_frame(MODEM, MODEMCMD_UNLISTEN, FUJI_FIELD_NONE, 0, 0, 0, 0,
              NULL, 0);
//@end
    ex_raw(mbuf, raw_get(mbuf, sizeof mbuf));

    if (SEND_FATAL) {           /* never: each of these stops FujiNet */
        ex_mark("modem.write.atcpm");
//@ex modem.write.atcpm
        /* ATCPM: this build has no CP/M device, and FujiNet crashes */
        raw_frame(MODEM, MODEMCMD_WRITE, FUJI_FIELD_NONE, 0, 0, 0, 0,
                  "ATCPM\r", 6);
//@end
        ex_mark("modem.listen.port0");
//@ex modem.listen.port0
        /* LISTEN on port 0: a NAK, then an ACK, and an assert fails */
        raw_frame(MODEM, MODEMCMD_LISTEN, FUJI_FIELD_B12, 0, 0, 0, 0,
                  NULL, 0);
//@end
    }

    ex_done();
    con_exit();
    return 0;
}
