/*
 * ISS -- where is the International Space Station? In C. Asks a web
 * service for the station's position and the people in space, both as
 * JSON, has the FujiNet's JSON parser pick out the values, and plots the
 * station on a map of the world drawn on the H19, every 30 seconds until
 * ESC is struck. ISS.ASM's twin.
 *
 *   ISS                          api.open-notify.org
 *   ISS N:HTTP://192.168.1.10/   a server of your own, with iss-now.json
 *                                and astros.json
 *
 *   tools/cc.sh hdos ISS src/c/iss/iss.c src/c/common/h89con.c \
 *       src/c/common/hdosargs.c src/c/common/words.c    ->  ISS.ABS
 *   tools/cc.sh cpm ISS ...the same...                  ->  ISS.COM
 *
 * After Justin Skists's ISS tracker for the RC2014, itself after Bill
 * Kendrick's for the Atari. The map is theirs (map.h).
 *
 * Copyright (C) 2026 Thomas Cherryhomes
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fujinet-network.h>
#include "h89con.h"
#include "hdosargs.h"
#include "words.h"
#include "map.h"

#define ESC     0x1B
#define MAP_X   4               /* the map's top left on the screen */
#define MAP_Y   2
#define REFRESH 60              /* half-seconds between updates */

static char base[132], url[148];
static char q[MAX_JSON_QUERY_LEN];  /* fujinet-lib sends all 256 bytes */
static char val[256];               /* ...and reads with no limit */
static char lat[32], lng[32], stamp[32];
static char path[32];               /* a JSON Pointer being built */
static char line[96];
static uint8_t iss_x, iss_y, ok;

static void gotoxy(uint8_t x, uint8_t y)
{
    con_putc(ESC);
    con_putc('Y');
    con_putc(32 + y);
    con_putc(32 + x);
}

//@ex iss.open_json
/* open url on unit 1 (HTTP GET) and parse what comes as JSON */
static uint8_t open_json(const char *name)
{
    strcpy(url, base);
    strcat(url, name);
    if (network_open(url, 4, 0) != FN_ERR_OK)
        return 0;
    return network_json_parse(url) == FN_ERR_OK;
}
//@end

//@ex iss.jget
/* the value at a JSON Pointer, into val; 0 if it is not there */
static uint8_t jget(const char *pointer)
{
    int16_t n;

    memset(q, 0, sizeof q);             /* every byte sent is defined */
    strncpy(q, pointer, sizeof q - 1);
    n = network_json_query(url, q, val);
    if (n <= 0)
        return 0;
    val[n] = 0;
    return 1;
}
//@end

/* wait 0.5 s for a key: 2 = ESC, 1 = another key, 0 = none */
static uint8_t half_sec(void)
{
    uint16_t t0 = TICKS;
    int c;

    while ((uint16_t)(TICKS - t0) < TICKS_PER_SECOND / 2)
        if ((c = con_getc()) >= 0)
            return c == ESC ? 2 : 1;
    return 0;
}

//@ex iss.astros
/* list the people in space; 1 if ESC was struck after */
static uint8_t astros(void)
{
    uint8_t n, i, k;

    con_puts("\x1B" "E" "\x1B" "p PEOPLE IN SPACE \x1B" "q\r\n\r\n");
    if (open_json("astros.json") && jget("/number")) {
        n = atoi(val);
        sprintf(line, "There are %u\r\n\r\n", n);
        con_puts(line);
        for (i = 0; i < n; i++) {
            sprintf(path, "/people/%u/name", i);
            if (jget(path)) {
                con_puts("    ");
                con_puts(val);
            }
            sprintf(path, "/people/%u/craft", i);
            if (jget(path)) {
                con_puts("  (");
                con_puts(val);
                con_putc(')');
            }
            con_puts("\r\n");
        }
    } else
        con_puts("Could not read the list of people in space.\r\n");
    network_close(url);
    con_puts("\r\nRETURN shows the map; ESC quits.");
    for (i = 0; i < REFRESH; i++)
        if ((k = half_sec()) != 0)
            return k == 2;
    return 0;
}
//@end

//@ex iss.fetch
/* the station's latitude, longitude and time into lat, lng, stamp */
static void fetch_iss(void)
{
    ok = 0;
    if (open_json("iss-now.json")) {
        if (jget("/iss_position/latitude")) {
            strcpy(lat, val);
            if (jget("/iss_position/longitude")) {
                strcpy(lng, val);
                if (jget("/timestamp")) {
                    strcpy(stamp, val);
                    ok = 1;
                }
            }
        }
    }
    network_close(url);
}
//@end

//@ex iss.place
/* a number like "-95.3698" in tenths (-953) */
static int tenths(const char *s)
{
    int v = 0, neg = (*s == '-');

    if (neg)
        s++;
    while (*s >= '0' && *s <= '9')
        v = v * 10 + (*s++ - '0');
    v *= 10;
    if (*s == '.' && s[1] >= '0' && s[1] <= '9')
        v += s[1] - '0';
    return neg ? -v : v;
}

/* the station's column and row: 72 columns for 360 degrees of
   longitude, 18 rows for 180 of latitude */
static void place(void)
{
    int x = (tenths(lng) + 1800) / 50;
    int y = (900 - tenths(lat)) / 100;

    iss_x = x < 0 ? 0 : x >= MAP_W ? MAP_W - 1 : x;
    iss_y = y < 0 ? 0 : y >= MAP_H ? MAP_H - 1 : y;
}
//@end

//@ex iss.time
/* seconds since 1 January 1970 as YYYY-MM-DD hh:mm:ss */
static void print_stamp(void)
{
    static const uint8_t mdays[12] = {31, 28, 31, 30, 31, 30,
                                      31, 31, 30, 31, 30, 31};
    unsigned long t = strtoul(stamp, NULL, 10);
    uint16_t days = t / 86400UL, year = 1970, len, rest;
    uint8_t month = 0, sec, min, hour;

    t -= days * 86400UL;                /* seconds into the day: no long % */
    hour = t / 3600UL;
    rest = (uint16_t)(t - hour * 3600UL);
    min = rest / 60;
    sec = rest % 60;

    for (;;) {                          /* whole years */
        len = (year & 3) ? 365 : 366;
        if (days < len)
            break;
        days -= len;
        year++;
    }
    for (;;) {                          /* whole months */
        len = mdays[month] + (month == 1 && !(year & 3));
        if (days < len)
            break;
        days -= len;
        month++;
    }
    sprintf(line, "%u-%02u-%02u %02u:%02u:%02u UTC", year, month + 1,
            days + 1, hour, min, sec);
    con_puts(line);
}
//@end

static void hline(void)
{
    uint8_t i;

    for (i = 0; i < MAP_W; i++)
        con_putc('a');                  /* graphics: a horizontal line */
}

static void draw(void)
{
    uint8_t y;

    con_puts("\x1B" "E");
    gotoxy(MAP_X + 22, 0);
    con_puts("\x1B" "p INTERNATIONAL SPACE STATION \x1B" "q");
    con_puts("\x1B" "F");               /* graphics on for the frame */
    gotoxy(MAP_X - 1, MAP_Y - 1);
    con_putc('f');
    hline();
    con_putc('c');
    for (y = 0; y < MAP_H; y++) {
        gotoxy(MAP_X - 1, MAP_Y + y);
        con_puts("`\x1B" "G");          /* a side; graphics off */
        con_puts(map[y]);
        con_puts("\x1B" "F`");
    }
    gotoxy(MAP_X - 1, MAP_Y + MAP_H);
    con_putc('e');
    hline();
    con_putc('d');
    con_puts("\x1B" "G");
    gotoxy(MAP_X - 1, MAP_Y + MAP_H + 2);
    if (!ok) {
        con_puts("Could not read the station's position; trying again.");
        return;
    }
    place();
    con_puts("Time ");
    print_stamp();
    con_puts("   Lat ");
    con_puts(lat);
    con_puts("   Long ");
    con_puts(lng);
    gotoxy(MAP_X - 1, MAP_Y + MAP_H + 3);
    con_puts("Updates every 30 seconds.  RETURN updates now; ESC quits.");
}

/* show the station (reverse video *), or put the map back */
static void mark(uint8_t on)
{
    gotoxy(MAP_X + iss_x, MAP_Y + iss_y);
    if (on)
        con_puts("\x1B" "p*\x1B" "q");
    else
        con_putc(map[iss_y][iss_x]);
    gotoxy(0, 0);
}

int main(int argc, char *argv[])
{
    uint8_t i, k = 0;

    ARGS(argc, argv);
    strcpy(base, argc > 1 ? argv[1] : "N:HTTP://api.open-notify.org/");
    net_spec(base);
    con_init(1);
    con_puts("\x1B" "x5");              /* the cursor off */

    if (!astros()) {
        for (;;) {
            fetch_iss();
            draw();
            for (i = REFRESH; i; i--) {
                if (ok)
                    mark(!(i & 1));             /* on first */
                if ((k = half_sec()) != 0)
                    break;
            }
            if (k == 2)
                break;
        }
    }
    con_puts("\x1B" "G" "\x1B" "q" "\x1B" "E" "\x1B" "y5");
    con_exit();
    return 0;
}
