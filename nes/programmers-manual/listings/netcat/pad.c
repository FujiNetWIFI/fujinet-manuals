/* pad.c -- controller 1, with auto-repeat on the D-pad.
 *
 * $4016 is the controller port, not the mailbox, so the usual rules about
 * read-modify-write instructions do not apply here. */

#include <time.h>
#include "pad.h"

#define JOY1 (*(volatile uint8_t *) 0x4016)

#define REPEAT_DELAY 18                 /* frames before a held arrow repeats */
#define REPEAT_RATE   5                 /* frames between repeats */

static uint8_t held, timer;

static uint8_t read_pad(void)
{
  uint8_t i, b = 0;

  JOY1 = 1;                             /* latch the buttons ... */
  JOY1 = 0;                             /* ... and shift them out */
  for (i = 0; i < 8; i++)
    b = (b << 1) | (JOY1 & 1);          /* A, B, Select, Start, Up ... Right */
  return b;
}

uint8_t pad_poll(void)
{
  uint8_t now = read_pad();
  uint8_t down = now & ~held;
  uint8_t arrows = now & 0x0F;

  if (down)
    timer = REPEAT_DELAY;
  else if (arrows && --timer == 0) {
    timer = REPEAT_RATE;
    down |= arrows;
  }
  held = now;
  return down;
}

void frame(void)
{
  clock_t t = clock();                  /* cc65's NMI counts frames here */

  while (clock() == t)
    ;
}
