/*
 * EXDISK -- the exerciser for the disk drives (31H-38H), in C:
 * EXDISK.ASM's twin. Mounts the SD card's /test/disk.img (sector n
 * holds 512 bytes of n) in drive slot 0 through the Fuji device, then
 * sends the drive every command it knows, and some it refuses, and
 * unmounts the image again.
 *
 * fujinet-lib has no disk calls, so the drive's commands go out through
 * fuji_bus_call(), the library's one door to the bus.
 *
 * The book's disk cards are cut from this file: see
 * tools/EXERCISERS.md.
 *
 * Copyright (C) 2026 Thomas Cherryhomes
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#include <stdio.h>
#include <string.h>
#include <fujinet-fuji.h>
#include <fujinet-bus.h>
#include <fujinet-commands.h>
#include "h89con.h"
#include "exlog.h"

static uint8_t sector[512];
static uint8_t dstat[4];
static uint8_t pblock[12];

//@ex disk.setup.set_path
static char path[256] = "/test/disk.img";   /* the library sends 256 */
//@end

//@ex disk.percom_write
static const uint8_t percom[12] = {
    80, 1, 0, 9,        /* 80 tracks, step 1, 9 sectors (high 1st) */
    1, 4, 2, 0,         /* two sides, MFM, 512 bytes a sector */
    0xFF, 0, 0, 0       /* drive present */
};
//@end

int main(void)
{
    bool ok;
    uint16_t i;

    con_init(0);

    /* ---- the image in drive slot 0 (drive 31H) ---- */
    ex_mark("disk.setup.mount_host");
//@ex disk.setup.mount_host
    ok = fuji_mount_host_slot(0);           /* host slot 0: SD card */
//@end
    ex_show(ok);

    ex_mark("disk.setup.set_path");
//@ex disk.setup.set_path
    /* mode 2 (read and write), host slot 0, drive slot 0 */
    ok = fuji_set_device_filename(2, 0, 0, path);
//@end
    ex_show(ok);

    ex_mark("disk.setup.mount");
//@ex disk.setup.mount
    ok = fuji_mount_disk_image(0, 2);       /* slot 0, read and write */
//@end
    ex_show(ok);

    /* ---- reading and writing ---- */
    ex_mark("disk.read");
//@ex disk.read
    /* fujinet-lib has no disk calls: fuji_bus_call sends the frame */
    ok = fuji_bus_call(FUJI_DEVICEID_DISK, DISKCMD_READ,
                       FUJI_FIELD_C1234 | FUJI_FIELD_REPLY,
                       3, 0, 0, 0, sector, 512);    /* sector 3 */
    if (ok) {
        for (i = 0; i < 512 && sector[i] == 3; i++)
            ;                           /* sector n: 512 bytes of n */
        if (i == 512)
            printf("\nSector 3 is 512 bytes of 03H.");
    }
//@end
    ex_showb(ok, sector, 512);

    ex_mark("disk.write");
//@ex disk.write
    memset(sector, 0xE5, 512);              /* CP/M's empty byte */
    ok = fuji_bus_call(FUJI_DEVICEID_DISK, DISKCMD_WRITE,
                       FUJI_FIELD_C1234 | FUJI_FIELD_DATA,
                       5, 0, 0, 0, sector, 512);    /* to sector 5 */
//@end
    ex_show(ok);

    memset(sector, 0, 512);         /* so the read back proves it */
    ex_mark("disk.read.back");
//@ex disk.read.back
    ok = fuji_bus_call(FUJI_DEVICEID_DISK, DISKCMD_READ,
                       FUJI_FIELD_C1234 | FUJI_FIELD_REPLY,
                       5, 0, 0, 0, sector, 512);    /* E5H again */
//@end
    ex_showb(ok, sector, 512);

    ex_mark("disk.put");
//@ex disk.put
    /* PUT writes as WRITE does: the verify it skips, nobody does */
    ok = fuji_bus_call(FUJI_DEVICEID_DISK, DISKCMD_PUT,
                       FUJI_FIELD_C1234 | FUJI_FIELD_DATA,
                       6, 0, 0, 0, sector, 512);    /* to sector 6 */
//@end
    ex_show(ok);

    ex_mark("disk.write.past_end");
//@ex disk.write.past_end
    /* sector 16 of a 16-sector image (0-15): NAK, file left alone */
    ok = fuji_bus_call(FUJI_DEVICEID_DISK, DISKCMD_WRITE,
                       FUJI_FIELD_C1234 | FUJI_FIELD_DATA,
                       16, 0, 0, 0, sector, 512);
//@end
    ex_show(ok);

    ex_mark("disk.read.past_end");
//@ex disk.read.past_end
    ok = fuji_bus_call(FUJI_DEVICEID_DISK, DISKCMD_READ,
                       FUJI_FIELD_C1234 | FUJI_FIELD_REPLY,
                       16, 0, 0, 0, sector, 512);   /* NAK */
//@end
    ex_show(ok);

    /* ---- status, format, PERCOM ---- */
    ex_mark("disk.status");
//@ex disk.status
    ok = fuji_bus_call(FUJI_DEVICEID_DISK, DISKCMD_STATUS,
                       FUJI_FIELD_REPLY, 0, 0, 0, 0, dstat, 4);
    if (ok)                                 /* drive, controller, */
        printf("\n%02X %02X %02X %02X",     /* timeout, 0 */
               dstat[0], dstat[1], dstat[2], dstat[3]);
//@end
    ex_showb(ok, dstat, 4);

    ex_mark("disk.format");
//@ex disk.format
    /* FORMAT formats nothing: it ACKs, FF FF and 126 0s */
    ok = fuji_bus_call(FUJI_DEVICEID_DISK, DISKCMD_FORMAT,
                       FUJI_FIELD_REPLY, 0, 0, 0, 0, sector, 128);
//@end
    ex_showb(ok, sector, 128);

    ex_mark("disk.read.after_format");
//@ex disk.read.after_format
    ok = fuji_bus_call(FUJI_DEVICEID_DISK, DISKCMD_READ,
                       FUJI_FIELD_C1234 | FUJI_FIELD_REPLY,
                       3, 0, 0, 0, sector, 512);    /* 03H, as before */
//@end
    ex_showb(ok, sector, 512);

    ex_mark("disk.format_medium");
//@ex disk.format_medium
    ok = fuji_bus_call(FUJI_DEVICEID_DISK, DISKCMD_FORMAT_MEDIUM,
                       FUJI_FIELD_REPLY, 0, 0, 0, 0, sector, 128);
//@end
    ex_showb(ok, sector, 128);

    ex_mark("disk.percom_read");
//@ex disk.percom_read
    /* the geometry, 12 bytes: all 0 for a plain image */
    ok = fuji_bus_call(FUJI_DEVICEID_DISK, DISKCMD_PERCOM_READ,
                       FUJI_FIELD_REPLY, 0, 0, 0, 0, pblock, 12);
//@end
    ex_showb(ok, pblock, 12);

    ex_mark("disk.percom_write");
//@ex disk.percom_write
    /* the firmware keeps the block; the image is not changed */
    ok = fuji_bus_call(FUJI_DEVICEID_DISK, DISKCMD_PERCOM_WRITE,
                       FUJI_FIELD_DATA, 0, 0, 0, 0, percom, 12);
//@end
    ex_show(ok);

    ex_mark("disk.percom_read.back");
//@ex disk.percom_read.back
    ok = fuji_bus_call(FUJI_DEVICEID_DISK, DISKCMD_PERCOM_READ,
                       FUJI_FIELD_REPLY, 0, 0, 0, 0, pblock, 12);
//@end
    ex_showb(ok, pblock, 12);

    ex_mark("disk.status.percom");
//@ex disk.status.percom
    /* two sides in the PERCOM block: the status says 40H now */
    ok = fuji_bus_call(FUJI_DEVICEID_DISK, DISKCMD_STATUS,
                       FUJI_FIELD_REPLY, 0, 0, 0, 0, dstat, 4);
    if (ok)
        printf("\n%02X %02X %02X %02X",
               dstat[0], dstat[1], dstat[2], dstat[3]);
//@end
    ex_showb(ok, dstat, 4);

    /* ---- an empty drive, and the end ---- */
    ex_mark("disk.read.empty");
//@ex disk.read.empty
    ok = fuji_bus_call(FUJI_DEVICEID_DISK + 1, DISKCMD_READ,
                       FUJI_FIELD_C1234 | FUJI_FIELD_REPLY,
                       0, 0, 0, 0, sector, 512);    /* 32H: NAK */
//@end
    ex_show(ok);

    ex_mark("disk.setup.unmount");
//@ex disk.setup.unmount
    ok = fuji_unmount_disk_image(0);        /* drive slot 0 */
//@end
    ex_show(ok);

    ex_mark("disk.read.unmounted");
//@ex disk.read.unmounted
    ok = fuji_bus_call(FUJI_DEVICEID_DISK, DISKCMD_READ,
                       FUJI_FIELD_C1234 | FUJI_FIELD_REPLY,
                       3, 0, 0, 0, sector, 512);    /* empty: NAK */
//@end
    ex_show(ok);

    ex_mark("disk.status.unmounted");
//@ex disk.status.unmounted
    /* STATUS still answers, from the disk that was there */
    ok = fuji_bus_call(FUJI_DEVICEID_DISK, DISKCMD_STATUS,
                       FUJI_FIELD_REPLY, 0, 0, 0, 0, dstat, 4);
//@end
    ex_showb(ok, dstat, 4);

    ex_done();
    con_exit();
    return 0;
}
