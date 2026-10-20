/* appkey.c -- read the shared FujiNet username, then write a key of our own
 * and read it back.
 *
 * Creator 1, app 1, key 0 is the slot every FujiNet game reads the player's
 * name from. Ours is creator 0x7800 (the cartridge's own), app 0xFF (this
 * handbook's scratch key), key 0. fuji_read_appkey() and
 * fuji_write_appkey() each do the OPEN_APPKEY themselves. */
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <fujinet-fuji.h>
#include <fujinet-atari7800.h>
#include "maria.h"

static uint8_t value[64 + 2];           /* a key, plus 2: the lib's rule */
static const char ours[] = "HELLO 7800";

static void show(uint8_t row)
{
    uint16_t n;

    mt_at(4, row);
    if (!fuji_read_appkey(0, &n, value))
        mt_puts("(READ FAILED)");
    else if (n == 0)
        mt_puts("(EMPTY)");
    else
        mt_text((char *)value, n);
}

void main(void)
{
    mt_init(' ');
    mt_background(0x00);
    mt_palette(0, 0x0F, 0x00, 0x0F);
    mt_at(2, 2);
    mt_puts("APPKEYS");

    mt_at(2, 5);
    mt_puts("USERNAME: KEY 1:1:0");
    fuji_set_appkey_details(1, 1, DEFAULT);
    show(6);

    mt_at(2, 9);
    mt_puts("OURS: KEY $7800:$FF:0");
    fuji_set_appkey_details(0x7800, 0xFF, DEFAULT);
    if (!fuji_write_appkey(0, sizeof ours - 1, (uint8_t *)ours)) {
        mt_at(4, 10);
        mt_puts("(WRITE FAILED)");
    } else
        show(10);
    for (;;)
        mt_sync();
}
