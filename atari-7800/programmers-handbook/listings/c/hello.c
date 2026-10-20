/* hello.c -- the smallest FujiNet program in C: a screen, some text, and
 * proof the cartridge is there. No transaction yet. */
#include <stdint.h>
#include <stdbool.h>
#include <fujinet-atari7800.h>
#include "maria.h"

void main(void)
{
    mt_init(' ');
    mt_background(0x00);
    mt_palette(0, 0x0F, 0x00, 0x0F);    /* ink white, paper = background */
    mt_at(2, 2);
    mt_puts("FUJINET ATARI 7800");
    mt_at(2, 4);
    mt_puts("HELLO, WORLD");
    mt_at(2, 6);
    mt_puts(fuji_a7800_present() ? "A FUJINET CARTRIDGE ANSWERS"
                                 : "NO FUJINET CARTRIDGE");
    mt_at(2, 7);
    mt_puts(fuji_a7800_mode() == FUJI_A7800_MODE_APP ? "RUNNING AS AN APP" : "");
    for (;;)
        mt_sync();
}
