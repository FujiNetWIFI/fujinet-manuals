/* hello.c -- the C road to the first screen: text through CONFIG's ANTIC
 * engine, the frame counter ticking, the keypad answering, and the cart's
 * status page answering 'F','N'. The same screen as hello.s.
 */
#include <stdint.h>
#include <fujinet-atari5200.h>
#include "antic.h"

#define RTCLOKH (*(volatile uint8_t *) 0x01)
#define RTCLOKL (*(volatile uint8_t *) 0x02)

static void puts_at(uint8_t row, uint8_t col, const char *s)
{
    mt_at(col, row);
    mt_text(s, MT_COLS);
}

static void hex(uint8_t v)
{
    static const char digits[] = "0123456789ABCDEF";

    mt_put(digits[v >> 4]);
    mt_put(digits[v & 15]);
}

void main(void)
{
    mt_init(' ');
    mt_colours(0x84, 0x0E);             /* blue background, white text */
    puts_at(2, 2, "FUJINET ATARI 5200 C");
    puts_at(4, 2, "CART");
    puts_at(4, 8, fuji_a5200_present() ? "FN OK" : "NO MAILBOX");
    puts_at(6, 2, "FRAME");
    puts_at(8, 2, "KEY");
    for (;;) {
        mt_at(9, 6);
        hex(RTCLOKH);
        hex(RTCLOKL);
        mt_at(9, 8);
        hex(fuji_a5200_key);
    }
}
