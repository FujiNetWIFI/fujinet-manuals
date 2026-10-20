/* netget.c -- fetch a URL through the N: device and show the text.
 *
 * network_open() as an HTTP GET, network_read() what arrives, then
 * network_close(). The text goes up a line at a time: LF ends a row, CR is
 * skipped, a row is at most 30 characters. */
#include <stdint.h>
#include <stdbool.h>
#include <fujinet-network.h>
#include <fujinet-atari7800.h>
#include "maria.h"

#define URL   "N:http://127.0.0.1:8765/hello.txt"
#define ROW0  4
#define ROWS  18
#define COLS  30

static char buf[512];

static void hex(uint8_t v)
{
    static const char digit[] = "0123456789ABCDEF";
    mt_put(digit[v >> 4]);
    mt_put(digit[v & 15]);
}

static void fail(const char *what, uint8_t code)
{
    mt_at(2, 22);
    mt_puts(what);
    mt_puts(" FAILED: E");
    hex(code);
    for (;;)
        mt_sync();
}

void main(void)
{
    int16_t n, i;
    uint8_t row = ROW0, col = 0, err;

    mt_init(' ');
    mt_background(0x00);
    mt_palette(0, 0x0F, 0x00, 0x0F);
    mt_at(2, 2);
    mt_puts("NETGET");

    network_init();
    err = network_open(URL, OPEN_MODE_HTTP_GET_H, OPEN_TRANS_NONE);
    if (err)
        fail("OPEN", err);
    n = network_read(URL, buf, sizeof buf);
    if (n < 0)
        fail("READ", fn_device_error);

    mt_at(2, row);
    for (i = 0; i < n; ++i) {
        if (buf[i] == '\r')
            continue;
        if (buf[i] == '\n') {
            if (++row == ROW0 + ROWS)
                break;
            mt_at(2, row);
            col = 0;
        } else if (col < COLS) {
            mt_put(buf[i]);
            ++col;
        }
    }
    network_close(URL);
    mt_at(2, 22);
    mt_puts("CLOSED");
    for (;;)
        mt_sync();
}
