/* bank0.c -- bank 0's own code in bank.c's Super Cart: a transaction
 * through fujinet-lib, which lives in the common part, its result on the
 * screen, and a byte only this bank has. */
#include <stdint.h>
#include <stdbool.h>
#include <fujinet-fuji.h>
#include "antic.h"
#include "book.h"

#pragma rodata-name (push, "MARK0")
const char mark0 = '0';                 /* $A000: bank 1 has '1' here */
#pragma rodata-name (pop)

#pragma code-name (push, "BANK0")
#pragma rodata-name (push, "BANK0")

static AdapterConfigExtended ac;

uint8_t bank0_main(void)
{
    mt_at(2, 6);
    mt_puts("BANK ");
    mt_put(*(const char *) 0xA000);
    if (!fuji_get_adapter_config_extended(&ac))
        return 0;
    mt_at(12, 6);
    mt_text(ac.ssid, 20);
    return 1;
}

#pragma rodata-name (pop)
#pragma code-name (pop)
