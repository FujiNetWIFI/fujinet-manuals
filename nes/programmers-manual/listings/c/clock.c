/* clock.c -- the FujiNet's network time, once a second. */

#include <conio.h>
#include <time.h>
#include <fujinet-clock.h>

static uint8_t now[26];

/* One second of vblanks, counted by cc65's NMI handler in clock(). */
static void second(void)
{
  clock_t t = clock() + 60;

  while (clock() < t)
    ;
}

void main(void)
{
  clrscr();
  cputs("CLOCK\r\n\r\n");

  for (;;) {
    if (clock_get_time(now, TZ_ISO_STRING) == FN_ERR_OK) {
      gotoxy(0, 3);
      cprintf("%.10s\r\n%.8s", now, now + 11);   /* date, then time */
    }
    second();
  }
}
