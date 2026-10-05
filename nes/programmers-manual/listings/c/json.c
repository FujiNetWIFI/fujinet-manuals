/* json.c -- fetch a JSON document and pick fields out of it. */

#include <conio.h>
#include <fujinet-network.h>

static const char url[] = "N:HTTP://127.0.0.1:8765/hello.json";
static const char *const paths[] = {
  "/name", "/console", "/year", "/mailbox/base", "/mailbox/reply"
};
static char value[128];

void main(void)
{
  uint8_t i;

  clrscr();
  cputs("JSON\r\n\r\n");

  network_init();
  if (network_open(url, OPEN_MODE_READ, OPEN_TRANS_NONE) != FN_ERR_OK
      || network_json_parse(url) != FN_ERR_OK) {
    cputs("OPEN/PARSE FAILED");
    for (;;) ;
  }

  for (i = 0; i < 5; i++) {
    if (network_json_query(url, paths[i], value) < 0)
      value[0] = '\0';
    cprintf("%-14s %s\r\n", paths[i], value);
  }

  network_close(url);
  for (;;) ;
}
