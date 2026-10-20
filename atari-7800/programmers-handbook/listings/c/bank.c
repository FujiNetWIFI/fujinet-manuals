/* bank.c -- a C program bigger than the slot. Three 16K banks take turns at
 * $8000 under SuperGame banking; each makes a real transaction from its own
 * code and names itself on the screen. bank.cfg places the banks, and
 * crt0bank.s's claim tells the cartridge to bank the image that way. */
#include <stdint.h>
#include <stdbool.h>
#include <fujinet-fuji.h>
#include <fujinet-atari7800.h>
#include "maria.h"

static AdapterConfigExtended ac;

/* SuperGame: a store anywhere in $8000-$BFFF picks the bank shown there. */
#define BANK_SELECT (*(volatile uint8_t *)0x8000)

/* One function per bank, each at $8000 in its own bank. Each returns its
 * bank's number, so a wrong bank shows. */
#pragma code-name(push, "BANK0")
uint8_t bank0(void) { return fuji_get_adapter_config_extended(&ac) ? 0 : 0xFF; }
#pragma code-name(pop)
#pragma code-name(push, "BANK1")
uint8_t bank1(void) { return fuji_get_adapter_config_extended(&ac) ? 1 : 0xFF; }
#pragma code-name(pop)
#pragma code-name(push, "BANK2")
uint8_t bank2(void) { return fuji_get_adapter_config_extended(&ac) ? 2 : 0xFF; }
#pragma code-name(pop)

typedef uint8_t (*bankfn)(void);
static const bankfn entry[3] = { bank0, bank1, bank2 };

/* The call lives in the fixed bank, so it is still there after the switch. */
static uint8_t bank_call(uint8_t b)
{
    BANK_SELECT = b;
    return entry[b]();
}

void main(void)
{
    uint8_t b, got;

    mt_init(' ');
    mt_background(0x00);
    mt_palette(0, 0x0F, 0x00, 0x0F);
    mt_at(2, 2);
    mt_puts("FUJINET 7800 C BANKED APP");
    for (b = 0; b < 3; ++b) {
        got = bank_call(b);
        mt_at(2, 5 + 2 * b);
        mt_puts("BANK ");
        mt_put('0' + b);
        mt_puts(got == b ? "  OK  " : "  FAIL");
        mt_text(ac.ssid, 16);
    }
    for (;;)
        mt_sync();
}
