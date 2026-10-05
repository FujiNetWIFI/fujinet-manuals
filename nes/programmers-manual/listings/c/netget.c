/* netget.c -- read a text file over HTTP and print it. */

#include <conio.h>
#include <fujinet-network.h>

static const char url[] = "N:HTTP://127.0.0.1:8765/hello.txt";
static char buf[256];

void main(void)
{
  int16_t n, i;

  clrscr();
  cputs("NETGET\r\n\r\n");

  network_init();
  if (network_open(url, OPEN_MODE_READ, OPEN_TRANS_NONE) != FN_ERR_OK) {
    cputs("OPEN FAILED");
    for (;;) ;
  }

  /* network_read() returns once it has len bytes or the file has ended. */
  while ((n = network_read(url, buf, sizeof buf)) > 0) {
    for (i = 0; i < n; i++) {
      if (buf[i] == '\n')
        cputs("\r\n");
      else
        cputc(buf[i]);
    }
  }

  network_close(url);
  cputs("\r\n-- END --");
  for (;;) ;
}
