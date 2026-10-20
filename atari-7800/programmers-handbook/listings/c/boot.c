/* boot.c -- push a program from the SD card into the cartridge and run it.
 *
 * MOUNT_HOST, SET_DEVICE_FULLPATH, then MOUNT_IMAGE, which makes the
 * FujiNet push the image into the cartridge's RAM. When the cartridge says
 * the image is READY, fuji_a7800_boot() hands the console to the loader,
 * which copies the image in and starts it. A bar shows the push. */
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <fujinet-fuji.h>
#include <fujinet-atari7800.h>
#include "maria.h"

#define HOSTSL   0                      /* host slot 0: the SD card */
#define DEVSL    0                      /* device slot 0 */
#define FMREAD   1                      /* mount for reading */
#define BOOTPATH "/a7800book/hello.bin"

static char path[256];                  /* SET_DEVICE_FULLPATH takes 256 */

static void fail(const char *what)
{
    mt_at(2, 22);
    mt_puts(what);
    mt_puts(" FAILED");
    for (;;)
        mt_sync();
}

void main(void)
{
    uint8_t state, pct, shown = 0;

    mt_init(' ');
    mt_background(0x00);
    mt_palette(0, 0x0F, 0x00, 0x0F);
    mt_at(2, 2);
    mt_puts("BOOT " BOOTPATH);

    strcpy(path, BOOTPATH);
    if (!fuji_mount_host_slot(HOSTSL))
        fail("MOUNT_HOST");
    if (!fuji_set_device_filename(FMREAD, HOSTSL, DEVSL, path))
        fail("SET_DEVICE_FULLPATH");
    if (!fuji_mount_disk_image(DEVSL, FMREAD))
        fail("MOUNT_IMAGE");

    /* the push may finish before or after MOUNT_IMAGE returns */
    mt_at(2, 4);
    for (;;) {
        state = fuji_a7800_boot_state();
        pct = fuji_a7800_boot_percent();
        while (shown < pct / 4) {       /* 25 cells for 100 per cent */
            mt_put('#');
            ++shown;
        }
        if (state == FUJI_A7800_BOOT_READY)
            break;
        if (state == FUJI_A7800_BOOT_FAILED)
            fail("PUSH");
        mt_sync();
    }
    fuji_a7800_boot();                  /* does not return */
}
