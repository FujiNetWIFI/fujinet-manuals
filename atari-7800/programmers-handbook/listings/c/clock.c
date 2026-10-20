/* clock.c -- the time of day, from the adapter's clock.
 *
 * clock_get_time() with TZ_ISO_STRING answers with the local time as text,
 * "2026-10-20T10:45:31" and more, in the adapter's configured time zone;
 * UTC_ISO_STRING the same in UTC. */
#include <stdint.h>
#include <stdbool.h>
#include <fujinet-clock.h>
#include <fujinet-atari7800.h>
#include "maria.h"

static uint8_t when[32];

static void line(uint8_t row, const char *label, TimeFormat f)
{
    mt_at(2, row);
    mt_puts(label);
    mt_at(10, row);
    if (clock_get_time(when, f))
        mt_puts("FAILED");
    else
        mt_text((char *)when, 25);
}

void main(void)
{
    mt_init(' ');
    mt_background(0x00);
    mt_palette(0, 0x0F, 0x00, 0x0F);
    mt_at(2, 2);
    mt_puts("CLOCK");
    line(5, "LOCAL", TZ_ISO_STRING);
    line(7, "UTC", UTC_ISO_STRING);
    for (;;)
        mt_sync();
}
