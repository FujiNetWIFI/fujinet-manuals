/* bank.c -- a 64K Super Cart FujiNet app in C: bank 1 (the power-on
 * bank) runs a transaction, calls into bank 0 -- whose own code runs
 * another -- and comes back. The same screen as bank.s.
 *
 * Built with bank.cfg, supercart.s and bank0.c (build.sh's "bank"). */
#include <stdint.h>
#include <stdbool.h>
#include <fujinet-fuji.h>
#include <fujinet-atari5200.h>
#include "antic.h"
#include "book.h"

#define MARK (*(const char *) 0xA000)   /* '1' in bank 1, '0' in bank 0 */

#pragma rodata-name (push, "MARK1")
const char mark1 = '1';
#pragma rodata-name (pop)

extern uint8_t far_bank0(void);         /* supercart.s */

static AdapterConfigExtended ac;

static void fail(uint8_t step)
{
    mt_at(2, 12);
    mt_puts("FAILED STEP ");
    mt_put('0' + step);
    for (;;)
        mt_sync();
}

void main(void)
{
    mt_init(' ');
    mt_colours(0x84, 0x0E);             /* blue background, white text */
    mt_at(2, 2);
    mt_puts("BANKS ON A SUPER CART");
    mt_at(2, 4);
    mt_puts("BANK 1 ");
    mt_put(MARK);

    if (!fuji_a5200_present() || !fuji_get_adapter_config_extended(&ac))
        fail(0);
    mt_at(2, 5);
    mt_puts("IP");
    mt_at(9, 5);
    mt_text(ac.sLocalIP, 16);

    if (!far_bank0())                   /* bank 0 runs a transaction of its own */
        fail(1);
    mt_at(2, 8);
    mt_puts("BACK FROM BANK 0: BANK ");
    mt_put(MARK);                       /* bank 1's byte again */
    mt_at(2, 10);
    mt_puts("DONE");
    for (;;)
        mt_sync();
}
