/*
 * EXLIB -- the rest of fujinet-lib, in C: the names Chapter 7 lists
 * that the device exercisers (EXFUJI, EXNET, EXCLOCK, ...) do not
 * call. The helpers that send nothing, the one-call conveniences
 * (fuji_hash_data, qrcode_create, network_http_post, fuji_file_stat,
 * ...), and the generic calls the others are made of. C only: these
 * are library names, not commands, so there is no Z80 twin.
 *
 * Each example is marked //@ex KEY ... //@end and printed in the book;
 * the marker (ex_mark) and the report (ex_show) around it are not.
 * Keys are lib.<name>.
 *
 *   unit 1  HTTP GET (hello.txt)      unit 2  JSON, then HTML
 *   unit 3  HTTP POST                 unit 4  HTTP headers
 *   unit 8  files on the SD card
 *
 *   tools/cc.sh hdos EXLIB src/c/ex/exlib.c src/c/common/h89con.c \
 *       src/c/common/exlog.c                          ->  EXLIB.ABS
 *   tools/cc.sh cpm EXLIB ...the same...              ->  EXLIB.COM
 *
 * Copyright (C) 2026 Thomas Cherryhomes
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#include <stdio.h>
#include <string.h>
#include <fujinet-fuji.h>
#include <fujinet-network.h>
#include <fujinet-qrcode.h>
#include "h89con.h"
#include "exlog.h"

static uint8_t buf[512];                /* the shared read buffer */
static uint16_t avail;                  /* STATUS: bytes waiting, */
static uint8_t conn, nerr;              /*   connected, error */
static uint8_t digest[129];
static uint8_t qr[256];
static char path[256];
static char sel[256];
static char name[32];
static FujiDirEntry *fe;

//@ex lib.network_unit_status
static const char hello[] = "N1:HTTP://127.0.0.1:7802/hello.txt";
//@end
//@ex lib.network_set_query_param
static const char json[] = "N2:HTTP://127.0.0.1:7802/fuji.json";
//@end
//@ex lib.network_html_parse
static const char page[] = "N2:HTTP://127.0.0.1:7802/hello.txt";
//@end
//@ex lib.network_http_post
static const char post[] = "N3:HTTP://127.0.0.1:7802/post";
//@end
//@ex lib.network_http_post_bin
static const uint8_t word[4] = { 'H', 0, '8', '9' };   /* a NUL too */
//@end
//@ex lib.network_http_end_add_headers
static const char geth[] = "N4:HTTP://127.0.0.1:7802/hello.txt";
//@end

int main(void)
{
    FN_ERR rc;
    int16_t len;
    uint16_t n;
    int r;
    bool ok;

    con_init(0);

    /* ================================================ Fuji device */
    ex_mark("lib.fuji_hash_data");
    printf("\n");
//@ex lib.fuji_hash_data
    /* CLEAR, INPUT, COMPUTE, LENGTH, OUTPUT: five frames */
    ok = fuji_hash_data(MD5, (uint8_t *)"abc", 3, true, digest);
    if (ok) {
        digest[fuji_hash_size(MD5, true)] = 0;  /* hex has no NUL */
        printf("%s\n", (char *)digest);
    }
//@end
    ex_showb(ok, digest, 32);

    ex_mark("lib.fuji_hash_add");
    printf("\n");
//@ex lib.fuji_hash_add
    fuji_hash_clear();                  /* start with nothing */
    fuji_hash_add((uint8_t *)"ab", 2);  /* "abc", in two pieces */
    ok = fuji_hash_add((uint8_t *)"c", 1);
//@end
    ex_show(ok);

    ex_mark("lib.fuji_hash_calculate");
    printf("\n");
//@ex lib.fuji_hash_calculate
    /* SHA-1 of what was added, keeping it; then MD5, letting go */
    if (fuji_hash_calculate(SHA1, true, false, digest)) {
        digest[40] = 0;
        printf("%s\n", (char *)digest);
    }
    ok = fuji_hash_calculate(MD5, true, true, digest);
    if (ok) {
        digest[32] = 0;
        printf("%s\n", (char *)digest);
    }
//@end
    ex_showb(ok, digest, 32);

    ex_mark("lib.qrcode_create");
    printf("\n");
//@ex lib.qrcode_create
    /* INPUT, ENCODE, LENGTH, OUTPUT; the length, or minus an error */
    r = qrcode_create(0, QR_ECC_LOW, false, QR_OUTPUT_MODE_BITMAP,
                      "HTTPS://FUJINET.ONLINE/", 23, qr, sizeof qr);
    if (r > 0)                  /* a size byte, then the rows */
        printf("%d bytes, %u x %u\n", r, qr[0], qr[0]);
//@end
    ex_showb(r > 0, qr, r > 0 ? r : 0);

    ex_mark("lib.fuji_enable_device");
//@ex lib.fuji_enable_device
    /* the H89's firmware has no ENABLE_DEVICE: a NAK, so false */
    ok = fuji_enable_device(FUJI_DEVICEID_PRINTER);
//@end
    ex_show(ok);

    ex_mark("lib.fuji_disable_device");
//@ex lib.fuji_disable_device
    ok = fuji_disable_device(FUJI_DEVICEID_PRINTER); /* NAK as well */
//@end
    ex_show(ok);

    /* ============================================ the network units */
    ex_mark("lib.network_unit_status");
    printf("\n");
//@ex lib.network_unit_status
    network_open(hello, OPEN_MODE_HTTP_GET, OPEN_TRANS_NONE);
    /* STATUS by unit number, into fujinet-lib's own nw_status;
       0 means it worked (the macro is !fuji_bus_call) */
    n = network_unit_status(1, &nw_status);
    if (n == 0)
        printf("%u waiting\n", nw_status.avail);    /* 55 */
//@end
    ex_showb(n == 0, &nw_status, 4);
    ex_mark("_tidy");
    network_close(hello);

    ex_mark("lib.network_http_post");
    printf("\n");
//@ex lib.network_http_post
    network_open(post, OPEN_MODE_HTTP_POST, OPEN_TRANS_NONE);
    /* SET_HTTP_MODE 4, WRITE, SET_HTTP_MODE 0: a string, no NULs */
    rc = network_http_post(post, "name=H89&cpu=Z80");
    network_status(post, &avail, &conn, &nerr);     /* sends it */
    len = network_read(post, buf, avail);
    if (len > 0) {
        buf[len] = 0;
        printf("%s", (char *)buf);          /* GOT 16 BYTES */
    }
//@end
    ex_show(rc == FN_ERR_OK);
    ex_mark("_tidy");
    network_close(post);

    ex_mark("lib.network_http_post_bin");
    printf("\n");
//@ex lib.network_http_post_bin
    network_open(post, OPEN_MODE_HTTP_POST, OPEN_TRANS_NONE);
    rc = network_http_post_bin(post, word, sizeof word);
    network_status(post, &avail, &conn, &nerr);     /* sends it */
    len = network_read(post, buf, avail);
    if (len > 0) {
        buf[len] = 0;
        printf("%s", (char *)buf);          /* GOT 4 BYTES */
    }
//@end
    ex_show(rc == FN_ERR_OK);
    ex_mark("_tidy");
    network_close(post);

    ex_mark("lib.network_http_end_add_headers");
    printf("\n");
//@ex lib.network_http_end_add_headers
    network_open(geth, OPEN_MODE_HTTP_GET_H, OPEN_TRANS_NONE);
    network_http_start_add_headers(geth);
    network_http_add_header(geth, "X-Machine: H89");
    rc = network_http_end_add_headers(geth);    /* back to BODY */
    network_status(geth, &avail, &conn, &nerr); /* sends the GET */
    len = network_read(geth, buf, avail);
    printf("%d bytes\n", len);              /* 55: the body */
//@end
    ex_show(rc == FN_ERR_OK);
    ex_mark("_tidy");
    network_close(geth);

    ex_mark("lib.network_set_query_param");
    printf("\n");
//@ex lib.network_set_query_param
    network_open(json, OPEN_MODE_HTTP_GET, OPEN_TRANS_NONE);
    network_json_parse(json);
    /* 10H: plain ASCII out, entities decoded; set after the parse */
    rc = network_set_query_param(json, 0x10);
    len = network_json_query(json, "/name", (char *)buf);
    printf("[%s]\n", (char *)buf);  /* [FujiNet ]: in this mode a */
                                    /*   string's LF comes as a space */
//@end
    ex_showb(rc == FN_ERR_OK, buf, len > 0 ? len : 0);

    ex_mark("lib.network_set_line_ending");
    printf("\n");
//@ex lib.network_set_line_ending
    /* the byte put after every value; CR, LF or 9BH would come off
       again in network_json_query(), anything else stays */
    rc = network_set_line_ending(json, ',');
    len = network_json_query(json, "/ports/0", (char *)buf);
    printf("%s\n", (char *)buf);            /* 208, */
//@end
    ex_showb(rc == FN_ERR_OK, buf, len > 0 ? len : 0);
    ex_mark("_tidy");
    network_close(json);

    ex_mark("lib.network_html_parse");
//@ex lib.network_html_parse
    network_open(page, OPEN_MODE_HTTP_GET, OPEN_TRANS_NONE);
    /* SET_PARSER 2, then PARSE: the page is read in whole; plain
       text parses too, as the page's body */
    rc = network_html_parse(page);
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("lib.network_html_query");
    printf("\n");
//@ex lib.network_html_query
    /* a CSS selector. All 256 bytes go and the firmware keeps them
       all (an @ among them would ask for an attribute): clear first */
    memset(sel, 0, sizeof sel);
    strcpy(sel, "body");
    len = network_html_query(page, sel, (char *)buf);
    if (len > 0)
        printf("%s\n", (char *)buf);        /* the text, both lines */
//@end
    ex_showb(len > 0, buf, len > 0 ? len : 0);
    ex_mark("_tidy");
    network_close(page);

    ex_mark("lib.network_bus_write");
    printf("\n");
//@ex lib.network_bus_write
    network_open("N8:SD:/h89lib.txt", OPEN_MODE_WRITE, OPEN_TRANS_NONE);
    /* one WRITE frame to unit 8 (78H): the length, or 0 on a NAK */
    n = network_bus_write(FUJI_DEVICEID_NETWORK + 7,
                          "Written by EXLIB.\r\n", 19);
    printf("%u\n", n);                      /* 19 */
    network_close("N8:");
//@end
    ex_show(n == 19);

    ex_mark("lib.network_fs_command");
//@ex lib.network_fs_command
    /* what network_fs_mkdir() and the others are made of */
    rc = network_fs_command(NETCMD_MKDIR, "N8:SD:/test/libdir");
//@end
    ex_show(rc == FN_ERR_OK);
    ex_mark("_tidy");
    network_fs_rmdir("N8:SD:/test/libdir");

    ex_mark("lib.fuji_devcall_vld");
//@ex lib.fuji_devcall_vld
    /* a payload and no fields, to any device: SET_EOL on unit 1 */
    ok = fuji_devcall_vld(FUJI_DEVICEID_NETWORK, NETCMD_SET_EOL,
                          "\r\n", 2);
//@end
    ex_show(ok);
    ex_mark("_tidy");
    network_set_eol("N1:", "");

    /* ============================================ the SD directory */
    ex_mark("lib.fuji_open_directory_filter");
    printf("\n");
//@ex lib.fuji_open_directory_filter
    fuji_mount_host_slot(0);            /* the SD card, first */
    ok = fuji_open_directory_filter(0, "/test/", "*.txt");
    while (ok && fuji_read_directory(32, 0, name)
           && name[0] != FUJI_DIR_EOF)
        printf("%s ", name);            /* readme.txt */
    fuji_close_directory();
//@end
    ex_show(ok);

    ex_mark("lib.fuji_open_directory2");
    printf("\n");
//@ex lib.fuji_open_directory2
    /* no pattern: then the 256 bytes go from path itself */
    memset(path, 0, sizeof path);
    strcpy(path, "/test/");
    ok = fuji_open_directory2(0, path, "");
    for (n = 0; ok && fuji_read_directory(32, 0, name)
                && name[0] != FUJI_DIR_EOF; n++)
        ;
    printf("%u entries\n", n);              /* 3 */
    fuji_close_directory();
//@end
    ex_show(ok);

    ex_mark("lib.fuji_file_stat");
    printf("\n");
//@ex lib.fuji_file_stat
    /* MOUNT_HOST, OPEN_DIRECTORY, READ_DIR_ENTRY until the name
       matches, CLOSE_DIRECTORY; NULL if the file is not there */
    fe = fuji_file_stat(0, "/h89lib.txt");
    if (fe)
        printf("%lu bytes, %u/%u/%u\n", fe->size, fe->modified.month,
               fe->modified.day, fe->modified.year + 1970);
//@end
    if (fe)
        ex_showb(true, fe, 12);
    else
        ex_show(false);

    /* ===================== helpers: no frames, so last, on screen */
    ex_mark("lib.network_init");
//@ex lib.network_init
    rc = network_init();        /* nothing to set up on the H89 */
    if (rc != FN_ERR_OK)
        printf("No network.\n");
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("lib.network_unit");
    printf("\n");
//@ex lib.network_unit
    /* the unit in a devicespec (N: is 1); no frame is sent */
    printf("%u %u %u\n", network_unit("N:TCP://127.0.0.1:7801/"),
           network_unit("N3:HTTP://127.0.0.1:7802/"),
           network_unit("N8:SD:/test/"));       /* 1 3 8 */
//@end
    ex_show(network_unit("N8:") == 8);

    ex_mark("lib.fuji_field_numbytes");
    printf("\n");
//@ex lib.fuji_field_numbytes
    /* how many field bytes a descriptor means: two words here */
    n = fuji_field_numbytes(FUJI_FIELD_B12_B34);
    printf("%u bytes\n", n);                /* 4 */
//@end
    ex_show(n == 4);

    ex_mark("lib.fuji_field_numfields");
    printf("\n");
//@ex lib.fuji_field_numfields
    n = fuji_field_numfields(FUJI_FIELD_B12_B34);
    printf("%u fields\n", n);               /* 2 */
//@end
    ex_show(n == 2);

    ex_mark("lib.network_json_strip_newlines");
    printf("\n");
//@ex lib.network_json_strip_newlines
    strcpy((char *)buf, "H89\r\n");
    /* drops CR, LF and 9BH from the end, then writes a NUL */
    n = network_json_strip_newlines((char *)buf, 5);
    printf("%u \"%s\"\n", n, (char *)buf);  /* 3 "H89" */
//@end
    ex_show(n == 3);

    ex_mark("lib.fuji_hash_size");
    printf("\n");
//@ex lib.fuji_hash_size
    n = fuji_hash_size(SHA256, true);   /* 64: two hex digits a byte */
    printf("%u\n", n);
//@end
    ex_show(n == 64);

    ex_done();
    con_exit();
    return 0;
}
