/*
 * EXCLOCK -- the exerciser for the clock (45H), in C: EXCLOCK.ASM's
 * twin. The time in every format the clock gives it, in the system
 * time zone and in the alternate one, the time zone itself, and
 * setting both zones (and a bad one, which the clock takes and
 * quietly throws away).
 *
 * fujinet-lib's clock_get_time() writes a NUL after the reply, so every
 * buffer it fills is one byte longer than the reply.
 *
 * The book's clock cards are cut from this file: see
 * tools/EXERCISERS.md.
 *
 * Copyright (C) 2026 Thomas Cherryhomes
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#include <stdio.h>
#include <fujinet-clock.h>
#include <fujinet-bus.h>
#include <fujinet-commands.h>
#include "h89con.h"
#include "exlog.h"

//@ex clock.gettime
static uint8_t when[7];         /* 6 bytes + the NUL fujinet-lib adds */
//@end
//@ex clock.settz_alt2
static uint8_t simple[8];       /* 7 bytes + the NUL fujinet-lib adds */
//@end
//@ex clock.get_simple_hundredths
static uint8_t hund[9];         /* 8 + 1 */
//@end
//@ex clock.get_prodos
static uint8_t prodos[5];       /* 4 + 1 */
//@end
//@ex clock.get_sos
static char sos[20];            /* 19, its own NUL counted, + 1 */
//@end
//@ex clock.get_iso_local
static char iso[26];            /* 25, its own NUL counted, + 1 */
//@end
//@ex clock.get_general
static char tz[64];             /* clock_get_tz() trusts it is enough */
//@end
//@ex clock.settz
static const char central[] = "CST6CDT,M3.2.0,M11.1.0";
//@end
//@ex clock.settz_alt
static const char eastern[] = "EST5EDT,M3.2.0,M11.1.0";
//@end

int main(void)
{
    bool ok;
    uint8_t len;

    con_init(0);

    /* ---- the time, in the system zone (UTC on the rig) ---- */
    ex_mark("clock.gettime");
//@ex clock.gettime
    ok = clock_get_time(when, APETIME_BINARY) == FN_ERR_OK;
    if (ok)                     /* day, month, year - 2000, h, m, s */
        printf("\n%u/%u/%u %u:%02u:%02u", when[0], when[1],
               when[2] + 2000, when[3], when[4], when[5]);
//@end
    ex_showb(ok, when, 6);

    ex_mark("clock.settz_alt2");
//@ex clock.settz_alt2
    /* SIMPLE_BINARY is command 54H, which gets the time, whatever
       its name says: century, year, month, day, hour, minute, second */
    ok = clock_get_time(simple, SIMPLE_BINARY) == FN_ERR_OK;
    if (ok)
        printf("\n%u%02u-%02u-%02u %02u:%02u:%02u", simple[0],
               simple[1], simple[2], simple[3], simple[4], simple[5],
               simple[6]);
//@end
    ex_showb(ok, simple, 7);

    ex_mark("clock.get_simple_hundredths");
//@ex clock.get_simple_hundredths
    ok = clock_get_time(hund, SIMPLE_BINARY_WITH_HUNDREDTHS)
         == FN_ERR_OK;
    if (ok)                         /* as SIMPLE_BINARY, and byte 7 */
        printf("\n%02u:%02u.%02u", hund[5], hund[6], hund[7]);
//@end
    ex_showb(ok, hund, 8);

    ex_mark("clock.get_prodos");
//@ex clock.get_prodos
    ok = clock_get_time(prodos, PRODOS_BINARY) == FN_ERR_OK;
    if (ok)                     /* yyyyyyym mmmddddd, minute, hour */
        printf("\n%u/%u/%u %u:%02u", prodos[0] & 0x1F,
               ((prodos[1] & 1) << 3) | (prodos[0] >> 5),
               prodos[1] >> 1, prodos[3], prodos[2]);
//@end
    ex_showb(ok, prodos, 4);

    ex_mark("clock.get_sos");
//@ex clock.get_sos
    ok = clock_get_time((uint8_t *)sos, APPLE3_SOS_BINARY) == FN_ERR_OK;
    if (ok)                         /* Apple III SOS: 18 digits */
        printf("\n%s", sos);
//@end
    ex_showb(ok, sos, 19);

    ex_mark("clock.get_iso_local");
//@ex clock.get_iso_local
    ok = clock_get_time((uint8_t *)iso, TZ_ISO_STRING) == FN_ERR_OK;
    if (ok)                         /* ISO 8601, with the offset */
        printf("\n%s", iso);
//@end
    ex_showb(ok, iso, 25);

    ex_mark("clock.get_iso_utc");
//@ex clock.get_iso_utc
    ok = clock_get_time((uint8_t *)iso, UTC_ISO_STRING) == FN_ERR_OK;
    if (ok)                         /* ISO 8601 in UTC, always */
        printf("\n%s", iso);
//@end
    ex_showb(ok, iso, 25);

    /* ---- the system time zone ---- */
    ex_mark("clock.gettz_len");
//@ex clock.gettz_len
    /* fujinet-lib asks this only inside clock_get_tz(): ask it here */
    ok = fuji_bus_call(FUJI_DEVICEID_CLOCK, APETIMECMD_GETTZ_LEN,
                       FUJI_FIELD_REPLY, 0, 0, 0, 0, &len, 1);
    if (ok)                         /* its NUL counted */
        printf("\n%u", len);
//@end
    ex_showb(ok, &len, 1);

    ex_mark("clock.get_general");
//@ex clock.get_general
    ok = clock_get_tz(tz) == FN_ERR_OK;     /* asks the length first */
    if (ok)
        printf("\n%s", tz);
//@end
    ex_showb(ok, tz, 4);

    /* ---- the alternate time zone ---- */
    ex_mark("clock.settz");
//@ex clock.settz
    /* sets the alternate zone (in RAM only), then asks the time
       there: GETTIME with field 1 = 1 */
    ok = clock_get_time_tz(when, central, APETIME_BINARY) == FN_ERR_OK;
    if (ok)
        printf("\n%u:%02u in Chicago", when[3], when[4]);
//@end
    ex_showb(ok, when, 6);

    ex_mark("clock.gettztime");
//@ex clock.gettztime
    /* no fujinet-lib call: the time in the alternate zone */
    ok = fuji_bus_call(FUJI_DEVICEID_CLOCK, APETIMECMD_GETTZTIME,
                       FUJI_FIELD_REPLY, 0, 0, 0, 0, when, 6);
    if (ok)
        printf("\n%u:%02u there", when[3], when[4]);
//@end
    ex_showb(ok, when, 6);

    ex_mark("clock.gettime.alt");
//@ex clock.gettime.alt
    /* clock_get_time_common(..., true): field 1 = 1, the other zone */
    ok = clock_get_time_common(when, APETIME_BINARY, true) == FN_ERR_OK;
    if (ok)
        printf("\n%u:%02u there", when[3], when[4]);
//@end
    ex_showb(ok, when, 6);

    ex_mark("clock.settz_alt2.alt");
//@ex clock.settz_alt2.alt
    ok = clock_get_time_common(simple, SIMPLE_BINARY, true)
         == FN_ERR_OK;
//@end
    ex_showb(ok, simple, 7);

    ex_mark("clock.get_simple_hundredths.alt");
//@ex clock.get_simple_hundredths.alt
    ok = clock_get_time_common(hund, SIMPLE_BINARY_WITH_HUNDREDTHS,
                               true) == FN_ERR_OK;
//@end
    ex_showb(ok, hund, 8);

    ex_mark("clock.get_prodos.alt");
//@ex clock.get_prodos.alt
    ok = clock_get_time_common(prodos, PRODOS_BINARY, true)
         == FN_ERR_OK;
//@end
    ex_showb(ok, prodos, 4);

    ex_mark("clock.get_sos.alt");
//@ex clock.get_sos.alt
    ok = clock_get_time_common((uint8_t *)sos, APPLE3_SOS_BINARY, true)
         == FN_ERR_OK;
    if (ok)
        printf("\n%s", sos);
//@end
    ex_showb(ok, sos, 19);

    ex_mark("clock.get_iso_local.alt");
//@ex clock.get_iso_local.alt
    ok = clock_get_time_common((uint8_t *)iso, TZ_ISO_STRING, true)
         == FN_ERR_OK;
    if (ok)                         /* the offset is -0500 now */
        printf("\n%s", iso);
//@end
    ex_showb(ok, iso, 25);

    ex_mark("clock.get_iso_utc.alt");
//@ex clock.get_iso_utc.alt
    ok = clock_get_time_common((uint8_t *)iso, UTC_ISO_STRING, true)
         == FN_ERR_OK;
    if (ok)                         /* UTC pays the field no mind */
        printf("\n%s", iso);
//@end
    ex_showb(ok, iso, 25);

    /* ---- a new system time zone ---- */
    ex_mark("clock.settz_alt");
//@ex clock.settz_alt
    ok = clock_set_tz(eastern) == FN_ERR_OK;    /* and it is saved */
//@end
    ex_show(ok);

    ex_mark("clock.gettz_len.new");
//@ex clock.gettz_len.new
    ok = fuji_bus_call(FUJI_DEVICEID_CLOCK, APETIMECMD_GETTZ_LEN,
                       FUJI_FIELD_REPLY, 0, 0, 0, 0, &len, 1);
    if (ok)
        printf("\n%u", len);
//@end
    ex_showb(ok, &len, 1);

    ex_mark("clock.get_general.new");
//@ex clock.get_general.new
    ok = clock_get_tz(tz) == FN_ERR_OK;     /* read it back */
    if (ok)
        printf("\n%s", tz);
//@end
    ex_showb(ok, tz, 23);

    ex_mark("clock.get_iso_local.new");
//@ex clock.get_iso_local.new
    ok = clock_get_time((uint8_t *)iso, TZ_ISO_STRING) == FN_ERR_OK;
    if (ok)                         /* the system zone: -0400 */
        printf("\n%s", iso);
//@end
    ex_showb(ok, iso, 25);

    ex_mark("clock.settz_alt.bad");
//@ex clock.settz_alt.bad
    /* a RETURN on the end: ACK, and thrown away (20H-7EH only) */
    ok = clock_set_tz("PST8PDT\r") == FN_ERR_OK;
//@end
    ex_show(ok);

    ex_mark("clock.get_general.kept");
//@ex clock.get_general.kept
    ok = clock_get_tz(tz) == FN_ERR_OK;     /* still US Eastern */
    if (ok)
        printf("\n%s", tz);
//@end
    ex_showb(ok, tz, 23);

    ex_done();
    con_exit();
    return 0;
}
