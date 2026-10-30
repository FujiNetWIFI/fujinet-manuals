/* acfg.c -- First Contact in C: one GET_ADAPTERCONFIG_EXTENDED, and the
 * SSID, IP address and firmware version on the screen. */
#include <stdint.h>
#include <stdbool.h>
#include <fujinet-fuji.h>
#include <fujinet-atari5200.h>
#include "antic.h"
#include "book.h"

static AdapterConfigExtended ac;

static void hex(uint8_t v)
{
    static const char digit[] = "0123456789ABCDEF";
    mt_put(digit[v >> 4]);
    mt_put(digit[v & 15]);
}

static void field(uint8_t row, const char *label, const char *s, uint8_t max)
{
    mt_at(2, row);
    mt_puts(label);
    mt_at(8, row);
    mt_text(s, max);
}

void main(void)
{
    mt_init(' ');
    mt_colours(0x84, 0x0E);             /* blue background, white text */
    mt_at(2, 2);
    mt_puts("FUJINET 5200 C FIRST CONTACT");

    if (!fuji_a5200_present()) {
        mt_at(2, 5);
        mt_puts("NO FUJINET CARTRIDGE");
    } else if (!fuji_get_adapter_config_extended(&ac)) {
        mt_at(2, 5);
        mt_puts("FAILED: E");
        hex(fn_device_error);
    } else {
        field(5, "SSID", ac.ssid, 24);
        field(7, "IP", ac.sLocalIP, 16);
        field(9, "FW", ac.fn_version, 15);
    }
    for (;;)
        mt_sync();
}
