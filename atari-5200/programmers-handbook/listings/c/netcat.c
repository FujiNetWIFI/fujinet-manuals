/* netcat.c -- talk to a TCP server a line at a time. The same screen and
 * keys as netcat.s.
 *
 * network_open() read/write, then every frame: the stick moves round an
 * on-screen keyboard and the bottom button types its key; the keypad's
 * digits type themselves, * rubs out, # sends the line with CR LF
 * (network_write()), and START closes the connection. Every eighth frame
 * network_status() asks what is waiting, and network_read() fetches it (at
 * most 128 bytes) into rows 3-14, which scroll. */
#include <stdint.h>
#include <string.h>
#include <fujinet-network.h>
#include <fujinet-atari5200.h>
#include "antic.h"
#include "book.h"

#define URL     "N:TCP://127.0.0.1:8769/"
#define ROW0    3               /* the received text: rows 3-14 */
#define NROWS   12
#define NCOLS   36
#define LROW    16              /* the line being typed, after "> " */
#define LMAX    34
#define KROW    18              /* the keyboard: rows 18-20 */
#define KCOLS   13
#define NMAX    128
#define LO      0x40            /* the stick's dead zone: $40-$A4 */
#define HI      0xA4
#define CR      0x0D            /* cc65's Atari targets read '\n' as $9B */
#define LF      0x0A

#define REG(a)  (*(volatile uint8_t *) (a))
#define PADDL0  REG(0x11)
#define PADDL1  REG(0x12)
#define TRIG0   REG(0xC010)
#define CONSOL  REG(0xC01F)
#define SCREEN  ((uint8_t *) 0x3C00)    /* antic.c's */

static const char keys[] = "ABCDEFGHIJKLM" "NOPQRSTUVWXYZ" "_.,:/?!-'@()=";

static uint8_t rrow = ROW0, rcol, llen, cx, cy, latch, fired;
static char line[LMAX + 2];
static uint8_t buf[NMAX];

static void fail(const char *what, uint8_t code)
{
    static const char digit[] = "0123456789ABCDEF";

    mt_at(2, LROW);
    mt_puts(what);
    mt_puts(" FAILED: E");
    mt_put(digit[code >> 4]);
    mt_put(digit[code & 15]);
    for (;;)
        mt_sync();
}

/* The key under the cursor in reverse video, or back. */
static void cursor(uint8_t on)
{
    mt_at(2 + 2 * cx, KROW + cy);
    mt_setpal(on, 1);
}

static void keyboard(void)
{
    uint8_t r, c;

    for (r = 0; r < 3; ++r) {
        mt_at(2, KROW + r);
        for (c = 0; c < KCOLS; ++c) {
            mt_put(keys[r * KCOLS + c]);
            mt_put(' ');
        }
    }
}

static void type(char c)
{
    if (llen == LMAX)
        return;
    mt_at(4 + llen, LROW);
    mt_put(c);
    line[llen++] = c;
}

static void rub(void)
{
    if (llen == 0)
        return;
    --llen;
    mt_at(4 + llen, LROW);
    mt_put(' ');
}

static void send(void)
{
    line[llen] = CR;
    line[llen + 1] = LF;
    if (network_write(URL, line, llen + 2))
        fail("WRITE", fn_device_error);
    llen = 0;
    mt_at(4, LROW);
    mt_fill(' ', LMAX);
}

/* One step per push: move, then wait for the stick to come back to the
 * centre. */
static void stick(void)
{
    uint8_t x = PADDL0, y = PADDL1;

    if (latch) {
        if (x >= LO && x <= HI && y >= LO && y <= HI)
            latch = 0;
        return;
    }
    if (x >= LO && x <= HI && y >= LO && y <= HI)
        return;
    cursor(0);
    if (x < LO)
        cx = cx ? cx - 1 : KCOLS - 1;
    else if (x > HI)
        cx = cx == KCOLS - 1 ? 0 : cx + 1;
    else if (y < LO)
        cy = cy ? cy - 1 : 2;
    else
        cy = cy == 2 ? 0 : cy + 1;
    cursor(1);
    latch = 1;
}

/* The bottom button types the key under the cursor, once a press. */
static void button(void)
{
    char c;

    if (TRIG0) {
        fired = 0;
        return;
    }
    if (fired)
        return;
    fired = 1;
    c = keys[cy * KCOLS + cx];
    type(c == '_' ? ' ' : c);
}

/* A new row; past the last, scroll the rows up one. */
static void newrow(void)
{
    rcol = 0;
    if (++rrow < ROW0 + NROWS)
        return;
    --rrow;
    memmove(SCREEN + ROW0 * 40, SCREEN + (ROW0 + 1) * 40, (NROWS - 1) * 40);
    mt_at(0, ROW0 + NROWS - 1);
    mt_fill(' ', 40);
}

static void show(uint8_t c)
{
    if (c == CR)
        return;
    if (c == LF) {
        newrow();
        return;
    }
    mt_at(2 + rcol, rrow);
    mt_put(c);
    if (++rcol == NCOLS)
        newrow();
}

static void receive(void)
{
    uint16_t bw;
    uint8_t connected, err;
    int16_t n, i;

    if (network_status(URL, &bw, &connected, &err))
        fail("STATUS", fn_device_error);
    if (bw == 0)
        return;
    n = network_read(URL, buf, bw > NMAX ? NMAX : bw);
    if (n < 0)
        fail("READ", fn_device_error);
    for (i = 0; i < n; ++i)
        show(buf[i]);
}

void main(void)
{
    uint8_t k;

    mt_init(' ');
    mt_colours(0x84, 0x0E);             /* blue background, white text */
    CONSOL = 0x04;                      /* the pots on; controller 1 */
    mt_at(2, 1);
    mt_puts("NETCAT  127.0.0.1:8769");
    mt_at(2, LROW);
    mt_puts("> ");
    mt_at(1, 22);
    mt_puts("FIRE TYPES  # SENDS  * RUBS  START ENDS");
    keyboard();
    cursor(1);
    fuji_a5200_key = 0;

    network_init();
    if (network_open(URL, OPEN_MODE_RW, OPEN_TRANS_NONE))
        fail("OPEN", fn_device_error);

    for (;;) {
        mt_sync();
        stick();
        button();
        k = fuji_a5200_key;             /* the last key + 1, 0 = none */
        if (k) {
            fuji_a5200_key = 0;
            --k;
            if (k < 10)
                type('0' + k);
            else if (k == 0x0A)         /* * */
                rub();
            else if (k == 0x0B)         /* # */
                send();
            else if (k == 0x0C) {       /* START */
                network_close(URL);
                mt_at(2, LROW);
                mt_puts("CLOSED");
                mt_fill(' ', 30);
                for (;;)
                    mt_sync();
            }
        }
        if ((mt_frames & 7) == 0)
            receive();
    }
}
