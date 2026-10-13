/*
 * EXFUJI -- the Fuji device (70H), every command it answers, in C with
 * fujinet-lib: EXFUJI.ASM's twin, the same examples in the same order
 * under the same keys, ending with RESET. Where fujinet-lib has no call
 * for a command, or its call does not fit the H89, the example calls
 * fuji_bus_call() itself and says why.
 *
 * Each example is marked //@ex KEY ... //@end and printed in the book;
 * the marker (ex_mark) and the report (ex_show) around it are not.
 *
 *   tools/cc.sh hdos EXFUJI src/c/ex/exfuji.c src/c/common/h89con.c \
 *       src/c/common/exlog.c                          ->  EXFUJI.ABS
 *   tools/cc.sh cpm EXFUJI ...the same...             ->  EXFUJI.COM
 *
 * Copyright (C) 2026 Thomas Cherryhomes
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#include <stdio.h>
#include <string.h>
#include <fujinet-fuji.h>
#include <fujinet-qrcode.h>
#include "h89con.h"
#include "exlog.h"

static AdapterConfig cfg;
static AdapterConfigExtended cfgx;
static uint8_t status, count;
static SSIDInfo scan;
static NetConfig net;
static HostSlot hosts[8];
static char name[32];
static FujiDirEntry ent;
static uint16_t pos;
static char path[256];
static char prefix[256];
static DeviceSlot slots[8];
static NewDisk nd;
static uint8_t key[66];
static uint16_t keylen;
static unsigned long b64len;
static char b64[64];
static uint8_t hashlen;
static uint8_t digest[128];
static unsigned long qrlen;
static uint8_t qr[256];
static char guid[37];
static uint32_t rnd;
static FNStatus fst;
static uint8_t buf[512];

//@ex fuji.open_appkey
/* OPEN_APPKEY's six bytes */
static struct {
    uint16_t creator;           /* who made the app: 4889H, "H89" */
    uint8_t app;                /* which of the creator's apps */
    uint8_t key;                /* which of the app's keys */
    uint8_t mode;               /* 0 read, 1 write */
    uint8_t reserved;
} ak = { 0x4889, 1, 0, 1, 0 };
//@end

int main(void)
{
    bool ok;
    uint8_t i;

    con_init(0);

    /* -------------------------------------------------- the adapter */
    ex_mark("fuji.get_adapterconfig");
    printf("\n");
//@ex fuji.get_adapterconfig
    ok = fuji_get_adapter_config(&cfg);
    if (ok)
        printf("%s %u.%u.%u.%u %s\n", cfg.ssid, cfg.localIP[0],
               cfg.localIP[1], cfg.localIP[2], cfg.localIP[3],
               cfg.fn_version);
//@end
    ex_showb(ok, &cfg, sizeof cfg);

    ex_mark("fuji.get_adapterconfig_extended");
    printf("\n");
//@ex fuji.get_adapterconfig_extended
    ok = fuji_get_adapter_config_extended(&cfgx);
    if (ok)                             /* the numbers as text too */
        printf("%s %s\n", cfgx.sLocalIP, cfgx.sMacAddress);
//@end
    ex_showb(ok, &cfgx, sizeof cfgx);

    /* ----------------------------------------------------- the WiFi */
    ex_mark("fuji.get_wifi_enabled");
    printf("\n");
//@ex fuji.get_wifi_enabled
    /* true if it is switched on; a call that fails returns the
       last answer, not false */
    ok = fuji_get_wifi_enabled();
    printf("WiFi %s\n", ok ? "on" : "off");
//@end
    ex_show(ok);

    ex_mark("fuji.get_wifistatus");
    printf("\n");
//@ex fuji.get_wifistatus
    ok = fuji_get_wifi_status(&status);
    if (ok)                             /* 3 = connected, 6 = not */
        printf("%u\n", status);
//@end
    ex_showb(ok, &status, 1);

    ex_mark("fuji.scan_networks");
    printf("\n");
//@ex fuji.scan_networks
    ok = fuji_scan_for_networks(&count);
    if (ok)
        printf("%u networks\n", count);
//@end
    ex_showb(ok, &count, 1);

    ex_mark("fuji.get_scan_result");
    printf("\n");
//@ex fuji.get_scan_result
    ok = fuji_get_scan_result(0, &scan);    /* the first found */
    if (ok)                             /* (and scan.rssi, in dBm) */
        printf("%s\n", scan.ssid);
//@end
    ex_showb(ok, &scan, sizeof scan);

    ex_mark("fuji.get_ssid");
    printf("\n");
//@ex fuji.get_ssid
    ok = fuji_get_ssid(&net);           /* and net.password, in */
    if (ok)                             /* the clear */
        printf("%s\n", net.ssid);
//@end
    ex_showb(ok, &net, sizeof net);

    ex_mark("fuji.set_ssid");
//@ex fuji.set_ssid
    memset(&net, 0, sizeof net);        /* join a network; keep it */
    strcpy(net.ssid, "Dummy Cafe");
    strcpy(net.password, "swordfish");
    ok = fuji_set_ssid(&net);
//@end
    ex_show(ok);

    /* ----------------------------------------------- the host slots */
    ex_mark("fuji.read_host_slots");
    printf("\n");
//@ex fuji.read_host_slots
    ok = fuji_get_host_slots(hosts, 8);     /* all eight, or it fails */
    if (ok)
        for (i = 0; i < 8; i++)
            printf("%s ", (char *)hosts[i]);
//@end
    ex_showb(ok, hosts, sizeof hosts);

    ex_mark("fuji.write_host_slots");
//@ex fuji.write_host_slots
    strcpy((char *)hosts[7], "localhost");  /* a name in slot 8 */
    ok = fuji_put_host_slots(hosts, 8);     /* and all eight go back */
//@end
    ex_show(ok);

    ex_mark("fuji.mount_host");
//@ex fuji.mount_host
    ok = fuji_mount_host_slot(0);       /* host slot 0, the SD card */
//@end
    ex_show(ok);

    /* -------------------------------------------------- a directory */
    ex_mark("fuji.open_directory");
//@ex fuji.open_directory
    /* the path, a NUL, then a pattern if wanted: fujinet-lib sends
       all 256 bytes of the buffer, so clear it first */
    memset(path, 0, sizeof path);
    strcpy(path, "/test/");
    ok = fuji_open_directory(0, path);  /* on host slot 0 */
//@end
    ex_show(ok);

    ex_mark("fuji.read_dir_entry");
    printf("\n");
//@ex fuji.read_dir_entry
    for (;;) {
        ok = fuji_read_directory(32, 0, name);  /* padded to 32 */
        if (!ok || name[0] == FUJI_DIR_EOF)     /* 7FH: no more */
            break;
        printf("%s ", name);
    }
//@end
    ex_showb(ok, name, sizeof name);

    ex_mark("fuji.get_directory_position");
    printf("\n");
//@ex fuji.get_directory_position
    ok = fuji_get_directory_position(&pos);
    if (ok)                             /* the next entry's number */
        printf("%u\n", pos);
//@end
    ex_showb(ok, &pos, 2);

    ex_mark("fuji.set_directory_position");
//@ex fuji.set_directory_position
    ok = fuji_set_directory_position(1);    /* on to the second */
//@end
    ex_show(ok);

    ex_mark("fuji.read_dir_entry.ext");
    printf("\n");
//@ex fuji.read_dir_entry.ext
    /* 12 bytes of details before the name. FUJI_DIR_ENTRY_IS_DIR()
       does not fit the H89's FujiDirEntry: test flags bit 0 */
    ok = fuji_read_directory(64, FUJI_DIR_FLAG_ADDITIONAL_DATA, &ent);
    if (ok)
        printf("%s %lu%s\n", ent.filename, ent.size,
               ent.flags & 0x01 ? " (directory)" : "");
//@end
    ex_showb(ok, &ent, 64);

    ex_mark("fuji.close_directory");
//@ex fuji.close_directory
    ok = fuji_close_directory();
//@end
    ex_show(ok);

    /* ---------------------------------------------- the host prefix */
    ex_mark("fuji.set_host_prefix");
//@ex fuji.set_host_prefix
    strcpy(prefix, "/test");            /* host slot 0's paths start */
    ok = fuji_set_host_prefix(0, prefix);   /* here (256 bytes go) */
//@end
    ex_show(ok);

    ex_mark("fuji.get_host_prefix");
    printf("\n");
//@ex fuji.get_host_prefix
    ok = fuji_get_host_prefix(0, prefix);   /* 256 bytes come back */
    if (ok)
        printf("%s\n", prefix);
//@end
    ex_showb(ok, prefix, 16);

    ex_mark("fuji.set_host_prefix.clear");
//@ex fuji.set_host_prefix.clear
    memset(prefix, 0, sizeof prefix);   /* no prefix: from the top */
    ok = fuji_set_host_prefix(0, prefix);
//@end
    ex_show(ok);

    /* ---------------------------------------------- the drive slots */
    ex_mark("fuji.set_device_fullpath");
//@ex fuji.set_device_fullpath
    memset(path, 0, sizeof path);       /* 256 bytes go */
    strcpy(path, "/test/disk.img");
    /* mode 1 (read), host slot 0, drive slot 0: not the order
       they go on the wire (drive, host, mode) */
    ok = fuji_set_device_filename(1, 0, 0, path);
//@end
    ex_show(ok);

    ex_mark("fuji.get_device_fullpath");
    printf("\n");
//@ex fuji.get_device_fullpath
    ok = fuji_get_device_filename(0, path);     /* drive slot 0 */
    if (ok)
        printf("%s\n", path);
//@end
    ex_showb(ok, path, 16);

    ex_mark("fuji.mount_image");
//@ex fuji.mount_image
    ok = fuji_mount_disk_image(0, 1);   /* drive slot 0, read-only */
//@end
    ex_show(ok);

    ex_mark("fuji.read_device_slots");
    printf("\n");
//@ex fuji.read_device_slots
    ok = fuji_get_device_slots(slots, 8);   /* all eight, or it fails */
    if (ok)                     /* host FFH: empty; mode 40H: mounted */
        printf("%u %02X %s\n", slots[0].hostSlot, slots[0].mode,
               (char *)slots[0].file);
//@end
    ex_showb(ok, slots, sizeof slots);

    ex_mark("fuji.write_device_slots");
//@ex fuji.write_device_slots
    slots[0].mode = 2;                  /* slot 0 read/write from now */
    ok = fuji_put_device_slots(slots, 8);   /* (names are not used) */
//@end
    ex_show(ok);

    ex_mark("fuji.unmount_image");
//@ex fuji.unmount_image
    ok = fuji_unmount_disk_image(0);    /* empty drive slot 0 */
//@end
    ex_show(ok);

    ex_mark("fuji.mount_all");
//@ex fuji.mount_all
    ok = fuji_mount_all();              /* whatever the slots name */
//@end
    ex_show(ok);

    /* --------------------------------------------- files, new disks */
    ex_mark("fuji.copy_file");
//@ex fuji.copy_file
    /* host slots count from 1 here. fujinet-lib sends 256 bytes:
       keep the spec in a cleared 256-byte buffer */
    memset(path, 0, sizeof path);
    strcpy(path, "/test/readme.txt|/test/copy.txt");
    ok = fuji_copy_file(1, 1, path);
//@end
    ex_show(ok);

    ex_mark("fuji.new_disk");
//@ex fuji.new_disk
    nd.numSectors = 400;                /* of 256 bytes */
    nd.sectorSize = 256;
    nd.hostSlot = 0;
    nd.deviceSlot = 1;
    strcpy(nd.filename, "/test/new.h8d");
    ok = fuji_create_new(&nd);          /* this firmware always NAKs */
//@end
    ex_show(ok);

    ex_mark("fuji.unmount_host");
//@ex fuji.unmount_host
    ok = fuji_unmount_host_slot(0);     /* the SD card NAKs */
//@end
    ex_show(ok);

    /* --------------------------------------------------------- boot */
    ex_mark("fuji.set_boot_mode");
//@ex fuji.set_boot_mode
    ok = fuji_set_boot_mode(0);         /* autorun.img into drive 31H */
//@end
    ex_show(ok);

    ex_mark("fuji.config_boot");
//@ex fuji.config_boot
    ok = fuji_set_boot_config(0);       /* and out again */
//@end
    ex_show(ok);

    /* ----------------------------------------------------- app keys */
    ex_mark("fuji.open_appkey");
//@ex fuji.open_appkey
    /* fujinet-lib opens a key only inside fuji_write_appkey() and
       fuji_read_appkey(); to open one by itself, use the bus */
    ok = fuji_bus_call(FUJI_DEVICEID_FUJINET, FUJICMD_OPEN_APPKEY,
                       FUJI_FIELD_NONE, 0, 0, 0, 0, &ak, sizeof ak);
//@end
    ex_show(ok);

    ex_mark("fuji.write_appkey");
//@ex fuji.write_appkey
    fuji_set_appkey_details(0x4889, 1, DEFAULT);    /* creator, app */
    /* key 0: opens it to write, then writes (which closes it) */
    ok = fuji_write_appkey(0, 16, (uint8_t *)"HIGH SCORE 12345");
//@end
    ex_show(ok);

    ex_mark("fuji.close_appkey");
//@ex fuji.close_appkey
    /* no fujinet-lib call for CLOSE_APPKEY */
    ok = fuji_bus_call(FUJI_DEVICEID_FUJINET, FUJICMD_CLOSE_APPKEY,
                       FUJI_FIELD_NONE, 0, 0, 0, 0, NULL, 0);
//@end
    ex_show(ok);

    ex_mark("fuji.open_appkey.read");
//@ex fuji.open_appkey.read
    ak.mode = 0;                        /* the same key, to read */
    ok = fuji_bus_call(FUJI_DEVICEID_FUJINET, FUJICMD_OPEN_APPKEY,
                       FUJI_FIELD_NONE, 0, 0, 0, 0, &ak, sizeof ak);
//@end
    ex_show(ok);

    ex_mark("fuji.read_appkey");
    printf("\n");
//@ex fuji.read_appkey
    /* key 0: opens it to read, then reads up to 64 bytes and their
       count (0 if there is no such key) */
    ok = fuji_read_appkey(0, &keylen, key);
    if (ok) {
        key[keylen] = 0;
        printf("%s\n", (char *)key);
    }
//@end
    ex_showb(ok, key, keylen);

    ex_mark("fuji.close_appkey.read");
//@ex fuji.close_appkey.read
    ok = fuji_bus_call(FUJI_DEVICEID_FUJINET, FUJICMD_CLOSE_APPKEY,
                       FUJI_FIELD_NONE, 0, 0, 0, 0, NULL, 0);
//@end
    ex_show(ok);

    /* ------------------------------------------------------- Base64 */
    ex_mark("fuji.base64_encode_input");
//@ex fuji.base64_encode_input
    ok = fuji_base64_encode_input("Heathkit H89", 12);
//@end
    ex_show(ok);

    ex_mark("fuji.base64_encode_compute");
//@ex fuji.base64_encode_compute
    ok = fuji_base64_encode_compute();
//@end
    ex_show(ok);

    ex_mark("fuji.base64_encode_length");
    printf("\n");
//@ex fuji.base64_encode_length
    ok = fuji_base64_encode_length(&b64len);    /* an unsigned long */
    if (ok)
        printf("%lu\n", b64len);
//@end
    ex_showb(ok, &b64len, 4);

    ex_mark("fuji.base64_encode_output");
    printf("\n");
//@ex fuji.base64_encode_output
    ok = fuji_base64_encode_output(b64, (uint16_t)b64len);  /* all */
    if (ok) {
        b64[(uint16_t)b64len] = 0;      /* it ends in a newline */
        printf("%s", b64);
    }
//@end
    ex_showb(ok, b64, (uint16_t)b64len);

    ex_mark("fuji.base64_decode_input");
//@ex fuji.base64_decode_input
    ok = fuji_base64_decode_input(b64, (uint16_t)b64len);   /* back */
//@end
    ex_show(ok);

    ex_mark("fuji.base64_decode_compute");
//@ex fuji.base64_decode_compute
    ok = fuji_base64_decode_compute();
//@end
    ex_show(ok);

    ex_mark("fuji.base64_decode_length");
    printf("\n");
//@ex fuji.base64_decode_length
    ok = fuji_base64_decode_length(&b64len);
    if (ok)
        printf("%lu\n", b64len);
//@end
    ex_showb(ok, &b64len, 4);

    ex_mark("fuji.base64_decode_output");
    printf("\n");
//@ex fuji.base64_decode_output
    ok = fuji_base64_decode_output(b64, (uint16_t)b64len);
    if (ok) {
        b64[(uint16_t)b64len] = 0;
        printf("%s\n", b64);
    }
//@end
    ex_showb(ok, b64, (uint16_t)b64len);

    /* --------------------------------------------------------- hash */
    ex_mark("fuji.hash_input");
//@ex fuji.hash_input
    ok = fuji_hash_input("abc", 3);     /* or fuji_hash_add() */
//@end
    ex_show(ok);

    ex_mark("fuji.hash_compute_no_clear");
//@ex fuji.hash_compute_no_clear
    ok = fuji_hash_compute_no_clear(MD5);   /* "abc" is kept */
//@end
    ex_show(ok);

    ex_mark("fuji.hash_compute");
//@ex fuji.hash_compute
    ok = fuji_hash_compute(SHA1);       /* then let go */
//@end
    ex_show(ok);

    ex_mark("fuji.hash_length");
    printf("\n");
//@ex fuji.hash_length
    ok = fuji_hash_length(1, &hashlen, 1);  /* 1: as hex; one byte */
    if (ok)
        printf("%u\n", hashlen);
//@end
    ex_showb(ok, &hashlen, 1);

    ex_mark("fuji.hash_output");
    printf("\n");
//@ex fuji.hash_output
    ok = fuji_hash_output(1, digest, hashlen);  /* hex, no NUL */
    if (ok) {
        digest[hashlen] = 0;
        printf("%s\n", (char *)digest);
    }
//@end
    ex_showb(ok, digest, hashlen);

    ex_mark("fuji.hash_output.bin");
    printf("\n");
//@ex fuji.hash_output.bin
    ok = fuji_hash_output(0, digest, 20);   /* SHA-1: 20 bytes */
    if (ok)
        for (i = 0; i < 20; i++)
            printf("%02X", digest[i]);
//@end
    ex_showb(ok, digest, 20);

    ex_mark("fuji.hash_clear");
//@ex fuji.hash_clear
    ok = fuji_hash_clear();             /* start again */
//@end
    ex_show(ok);

    /* ------------------------------------------------------ QR code */
    ex_mark("fuji.qrcode_input");
//@ex fuji.qrcode_input
    /* capitals: QR's alphanumeric mode makes a smaller code */
    ok = fuji_qrcode_input("HTTPS://FUJINET.ONLINE/", 23);
//@end
    ex_show(ok);

    ex_mark("fuji.qrcode_encode");
//@ex fuji.qrcode_encode
    /* version 0: the smallest that fits; not shortened */
    ok = fuji_qrcode_encode(0, QR_ECC_LOW, 0);
//@end
    ex_show(ok);

    ex_mark("fuji.qrcode_length");
    printf("\n");
//@ex fuji.qrcode_length
    ok = fuji_qrcode_length(QR_OUTPUT_MODE_BITMAP, &qrlen);
    if (ok)
        printf("%lu bytes\n", qrlen);
//@end
    ex_showb(ok, &qrlen, 4);

    ex_mark("fuji.qrcode_output");
    printf("\n");
//@ex fuji.qrcode_output
    ok = fuji_qrcode_output(qr, (uint16_t)qrlen);
    if (ok)                 /* the modules on a side, then the rows */
        printf("%u x %u\n", qr[0], qr[0]);
//@end
    ex_showb(ok, qr, (uint16_t)qrlen);

    /* ------------------------------------------------ odds and ends */
    ex_mark("fuji.generate_guid");
    printf("\n");
//@ex fuji.generate_guid
    ok = fuji_generate_guid(guid);      /* 36 characters and a NUL */
    if (ok)
        printf("%s\n", guid);
//@end
    ex_showb(ok, guid, 37);

    ex_mark("fuji.random_number");
    printf("\n");
//@ex fuji.random_number
    /* no fujinet-lib call for RANDOM_NUMBER */
    ok = fuji_bus_call(FUJI_DEVICEID_FUJINET, FUJICMD_RANDOM_NUMBER,
                       FUJI_FIELD_REPLY, 0, 0, 0, 0, &rnd, sizeof rnd);
    if (ok)
        printf("%08lX\n", rnd);
//@end
    ex_showb(ok, &rnd, 4);

    ex_mark("fuji.status");
    printf("\n");
//@ex fuji.status
    ok = fuji_status(&fst);             /* four bytes, all 0 here */
    if (ok)
        printf("%02X %02X %02X %02X\n", fst.value[0], fst.value[1],
               fst.value[2], fst.value[3]);
//@end
    ex_showb(ok, &fst, 4);

    ex_mark("fuji.device_ready");
    printf("\n");
//@ex fuji.device_ready
    /* a link test: 512 'A's come back. No fujinet-lib call */
    ok = fuji_bus_call(FUJI_DEVICEID_FUJINET, FUJICMD_DEVICE_READY,
                       FUJI_FIELD_REPLY, 0, 0, 0, 0, buf, 512);
    if (ok)
        printf("%c ... %c\n", buf[0], buf[511]);
//@end
    ex_showb(ok, buf, 512);

    ex_mark("fuji.get_time");
//@ex fuji.get_time
    ok = fuji_get_time(buf);    /* NAK: the clock is device 45H */
//@end
    ex_show(ok);

    ex_mark("fuji.reset");
//@ex fuji.reset
    ok = fuji_reset();          /* no reply: false, after 15 seconds */
//@end
    ex_show(ok);

    ex_done();
    con_exit();
    return 0;
}
