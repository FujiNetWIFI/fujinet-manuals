/* dir.c -- list a directory on a TNFS host. */

#include <conio.h>
#include <string.h>
#include <fujinet-fuji.h>

#define HOST  7                         /* host slot 8: ec.tnfs.io */
#define ROWS  20

static HostSlot hosts[8];
static char path[256];
static char entry[32];

void main(void)
{
  uint8_t n;

  clrscr();
  if (!fuji_get_host_slots(hosts, 8)) {
    cputs("NO HOST SLOTS");
    for (;;) ;
  }
  cprintf("DIR OF %s\r\n\r\n", (char *) hosts[HOST]);

  /* The path and an optional filter travel as one 256-byte block:
     "/" NUL "*.nes" NUL. Here there is no filter. */
  memset(path, 0, sizeof path);
  path[0] = '/';

  if (!fuji_mount_host_slot(HOST) || !fuji_open_directory(HOST, path)) {
    cputs("CANNOT OPEN");
    for (;;) ;
  }

  for (n = 0; n < ROWS; n++) {
    if (!fuji_read_directory(30, 0, entry))
      break;
    if (entry[0] == 0x7F)               /* $7F = end of directory */
      break;
    cprintf(" %s\r\n", entry);
  }

  fuji_close_directory();
  for (;;) ;
}
