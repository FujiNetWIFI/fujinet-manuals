/* boot.c -- fetch a cartridge image from the SD card and run it. */

#include <conio.h>
#include <fujinet-fuji.h>
#include <fujinet-nes.h>

#define HOST  0                         /* host slot 1: the SD card */
#define SLOT  0                         /* device slot 1 */
#define MODE_READ 1                     /* disk access mode: read only */

static char path[256] = "/nesbook/hello.bin";

void main(void)
{
  clrscr();
  cprintf("BOOTING %s\r\n\r\n", path);

  if (!fuji_mount_host_slot(HOST)
      || !fuji_set_device_filename(MODE_READ, HOST, SLOT, path)) {
    cputs("CANNOT MOUNT");
    for (;;) ;
  }

  /* MOUNT_IMAGE does not answer until the whole image has crossed the
     link into the cartridge's staging store. */
  if (!fuji_mount_disk_image(SLOT, MODE_READ)
      || fuji_nes_boot_state() != FUJI_NES_BOOT_READY) {
    cprintf("FAILED, BOOT ERROR %u", fuji_nes_boot_error());
    for (;;) ;
  }

  cprintf("%lu BYTES STAGED\r\n", fuji_nes_boot_total());
  fuji_set_boot_config(0);              /* don't come back to CONFIG */
  fuji_nes_boot();                      /* never returns */
}
