/* dir.c -- list a directory on a FujiNet host.
 *
 * fuji_mount_host_slot(), fuji_open_directory() with the path, then
 * fuji_read_directory() until the 0x7F,0x7F marker (or the screen is
 * full), then fuji_close_directory(). */
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <fujinet-fuji.h>
#include <fujinet-atari5200.h>
#include "antic.h"
#include "book.h"

#define HOSTSL  0                       /* host slot 0: the SD card */
#define NAMELN  36                      /* never 31: icon bytes come first */
#define ROW0    4
#define ROWS    18

static char path[256];                  /* OPEN_DIRECTORY takes exactly 256 */
static char name[NAMELN + 1];

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
    uint8_t row;

    mt_init(' ');
    mt_colours(0x84, 0x0E);             /* blue background, white text */
    mt_at(2, 2);
    mt_puts("DIRECTORY OF SD:/A5200BOOK/");

    strcpy(path, "/a5200book/");
    if (!fuji_mount_host_slot(HOSTSL))
        fail("MOUNT_HOST");
    if (!fuji_open_directory(HOSTSL, path))
        fail("OPEN_DIRECTORY");
    for (row = ROW0; row < ROW0 + ROWS; ++row) {
        if (!fuji_read_directory(NAMELN, 0, name))
            fail("READ_DIR_ENTRY");
        if (name[0] == 0x7F && name[1] == 0x7F)
            break;                      /* the end of the directory */
        mt_at(2, row);
        mt_text(name, NAMELN);
    }
    fuji_close_directory();
    for (;;)
        mt_sync();
}
