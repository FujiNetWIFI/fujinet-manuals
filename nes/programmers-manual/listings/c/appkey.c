/* appkey.c -- count how many times this program has been run. */

#include <conio.h>
#include <fujinet-fuji.h>

#define CREATOR 0x5E5E                  /* a scratch creator id */
#define APP     0x01
#define KEY     0x00

static uint8_t data[MAX_APPKEY_LEN + 2];

void main(void)
{
  uint16_t len = 0;
  uint16_t runs = 0;

  clrscr();
  cputs("APPKEY\r\n\r\n");

  fuji_set_appkey_details(CREATOR, APP, DEFAULT);

  /* A key that has never been written reads back empty. */
  if (fuji_read_appkey(KEY, &len, data) && len >= 2)
    runs = data[0] | (data[1] << 8);

  ++runs;
  data[0] = runs & 0xFF;
  data[1] = runs >> 8;

  if (!fuji_write_appkey(KEY, 2, data)) {
    cputs("WRITE FAILED");
    for (;;) ;
  }

  cprintf("THIS PROGRAM HAS RUN\r\n%u TIME%s.\r\n", runs, runs == 1 ? "" : "S");
  cputs("\r\nPRESS RESET TO COUNT AGAIN.");
  for (;;) ;
}
