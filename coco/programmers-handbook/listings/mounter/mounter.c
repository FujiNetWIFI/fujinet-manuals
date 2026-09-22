/*
 * MOUNTER.C --- host slots, a directory, and a disk in a drive
 *
 * Walks the whole mounting sequence by hand: read the host
 * slots, mount one, open its directory, read it, put a file
 * into a device slot, mount it.  This is what CONFIG does,
 * with the menus taken off.
 *
 *   cmoc -I$(FNDIR) -o MOUNTER.BIN mounter.c -lfujinet
 *   LOADM"MOUNTER":EXEC
 */

#include <cmoc.h>
#include <coco.h>
#include <fujinet-fuji.h>

#define MAXENT   40             /* as many names as we will hold */
#define NAMELEN  37
#define NHOSTS   8
#define NDRIVES  4              /* the CoCo has four, not eight */

static HostSlot   hosts[NHOSTS];
static DeviceSlot drives[NDRIVES];
static char       names[MAXENT][NAMELEN];
static char       entry[NAMELEN];
static char       root[]   = "/";
static char       filter[] = "*.dsk";
static char       empty[]  = "(EMPTY)";

/* Ask for a number between lo and hi.  Returns 0 if BREAK. */
static byte ask(const char *prompt, byte lo, byte hi)
{
    byte k;

    for (;;)
    {
        printf("%s", prompt);
        k = waitkey(1);
        if (k == 3) { printf("\n"); return 0; }
        putchar(k);
        printf("\n");
        if (k >= '0' + lo && k <= '0' + hi)
            return k - '0';
        printf("BETWEEN %u AND %u, PLEASE.\n", lo, hi);
    }
}

int main(void)
{
    byte i, hs, ds, n;

    cls(1);
    printf("FUJINET MOUNTER\n\n");

    /* ---- the eight host slots ------------------------------ */
    if (!fuji_get_host_slots((uint8_t *) hosts, NHOSTS))
    {
        printf("CANNOT READ HOST SLOTS\n");
        return 1;
    }
    for (i = 0; i < NHOSTS; i++)
        printf("%u %s\n", i + 1, hosts[i][0] ? (char *) hosts[i] : empty);

    hs = ask("\nHOST? ", 1, NHOSTS);
    if (!hs)
        return 0;
    if (!hosts[hs - 1][0])
    {
        printf("THAT SLOT IS EMPTY.\n");
        return 1;
    }

    /* ---- mount it and read its root ------------------------ */
    if (!fuji_mount_host_slot(hs - 1))
    {
        printf("CANNOT MOUNT THAT HOST\n");
        return 1;
    }
    if (!fuji_open_directory2(hs - 1, root, filter))
    {
        printf("CANNOT OPEN THE DIRECTORY\n");
        return 1;
    }

    n = 0;
    while (n < MAXENT)
    {
        if (!fuji_read_directory(NAMELEN - 1, 0, entry))
            break;
        if ((byte) entry[0] == 0x7F)    /* two $7F bytes end it */
            break;
        strcpy(names[n], entry);
        printf("%u %s\n", n + 1, names[n]);
        n++;
    }
    fuji_close_directory();

    if (!n)
    {
        printf("NOTHING THERE.\n");
        return 1;
    }

    /* ---- pick a file and a drive --------------------------- */
    i = ask("\nFILE? ", 1, n > 9 ? 9 : n);
    if (!i)
        return 0;
    ds = ask("DRIVE (1-4)? ", 1, NDRIVES);
    if (!ds)
        return 0;

    /* mode 0 writes the name into the slot without opening it */
    if (!fuji_set_device_filename(0, hs - 1, ds - 1, names[i - 1]))
    {
        printf("CANNOT SET THE SLOT\n");
        return 1;
    }
    /* 1 is read-only, 2 is read and write */
    if (!fuji_mount_disk_image(ds - 1, 2))
    {
        printf("CANNOT MOUNT IT\n");
        return 1;
    }

    /* ---- show the drives as they now stand ----------------- */
    printf("\n");
    if (fuji_get_device_slots(drives, NDRIVES))
        for (i = 0; i < NDRIVES; i++)
            printf("%u%c %s\n", i,
                   (drives[i].mode & 0x40) ? '*' : ' ',
                   drives[i].file[0] ? (char *) drives[i].file : empty);

    printf("\nDRIVE %u IS READY.\n", ds - 1);
    return 0;
}
