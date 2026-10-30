/* pads.c -- controller 1: the stick, both buttons and the keypad, and a
 * tone from POKEY while the bottom button is held. The same screen as
 * pads.s.
 *
 * The stick is two pots, which the VBI copies to PADDL0 (X) and PADDL1 (Y)
 * every frame; they read nothing until CONSOL bit 2 turns them on. The
 * bottom button is GTIA's TRIG0 (0 while held), the top one POKEY's SKSTAT
 * bit 3 (clear while held, for the controller CONSOL picks). The keypad is
 * the crt0's: fuji_a5200_key holds the last key + 1. */
#include <stdint.h>
#include <fujinet-atari5200.h>
#include "antic.h"
#include "book.h"

#define REG(a)  (*(volatile uint8_t *) (a))
#define PADDL0  REG(0x11)
#define PADDL1  REG(0x12)
#define TRIG0   REG(0xC010)
#define CONSOL  REG(0xC01F)
#define AUDF1   REG(0xE800)
#define AUDC1   REG(0xE801)
#define SKSTAT  REG(0xE80F)

#define TONE    0x50            /* AUDF1: the pitch */
#define VOICE   0xA8            /* AUDC1: a pure tone at volume 8 */

/* fuji_a5200_key is the key's code + 1: 0 none, then 0-9, *, #, START,
 * PAUSE, RESET. */
static const char *const names[16] = {
    "-    ", "0    ", "1    ", "2    ", "3    ", "4    ", "5    ", "6    ",
    "7    ", "8    ", "9    ", "*    ", "#    ", "START", "PAUSE", "RESET"
};

static void label(uint8_t row, const char *s)
{
    mt_at(2, row);
    mt_puts(s);
}

/* Three digits, leading zeros as spaces. */
static void dec3(uint8_t v)
{
    uint8_t h = v / 100, t = (v / 10) % 10;

    mt_put(h ? '0' + h : ' ');
    mt_put(h || t ? '0' + t : ' ');
    mt_put('0' + v % 10);
}

void main(void)
{
    mt_init(' ');
    mt_colours(0x84, 0x0E);             /* blue background, white text */
    CONSOL = 0x04;                      /* the pots on; controller 1 */
    label(2, "CONTROLLER 1");
    label(4, "STICK X");
    label(5, "STICK Y");
    label(7, "BOTTOM BUTTON");
    label(8, "TOP BUTTON");
    label(10, "KEYPAD");
    label(12, "SOUND");

    for (;;) {
        mt_sync();
        mt_at(16, 4);
        dec3(PADDL0);
        mt_at(16, 5);
        dec3(PADDL1);
        mt_at(16, 7);
        mt_puts(TRIG0 ? "UP  " : "DOWN");
        mt_at(16, 8);
        mt_puts(SKSTAT & 0x08 ? "UP  " : "DOWN");
        mt_at(16, 10);
        mt_puts(names[fuji_a5200_key & 15]);
        mt_at(16, 12);
        if (TRIG0 == 0) {
            AUDF1 = TONE;
            AUDC1 = VOICE;
            mt_puts("ON ");
        } else {
            AUDC1 = 0;
            mt_puts("OFF");
        }
    }
}
