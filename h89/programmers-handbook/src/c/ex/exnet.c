/*
 * EXNET -- the network device exerciser, in C: every command the
 * network units (71H-78H) answer, sent through fujinet-lib the way a
 * program would, against the book's helper servers on 127.0.0.1 and
 * the SD card. EXNET.ASM's twin: the same examples, the same keys, in
 * the same order.
 *
 *   unit 1  HTTP GET, translation, unit settings, errors
 *   unit 2  JSON           unit 3  HTTP POST, PUT, DELETE
 *   unit 4  HTTP headers   unit 5  TCP client (the test board, 7801)
 *   unit 6  TCP server (7803)      unit 7  UDP (7804, answers to 7805)
 *   unit 8  files on the SD card
 *
 *   tools/cc.sh hdos EXNET src/c/ex/exnet.c src/c/common/h89con.c \
 *       src/c/common/exlog.c                          ->  EXNET.ABS
 *   tools/cc.sh cpm EXNET ...the same...              ->  EXNET.COM
 *
 * Copyright (C) 2026 Thomas Cherryhomes
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#include <stdio.h>
#include <string.h>
#include <fujinet-network.h>
#include "h89con.h"
#include "exlog.h"

static uint8_t buf[2048];               /* the shared read buffer */
static uint16_t avail;                  /* STATUS: bytes waiting, */
static uint8_t conn, nerr;              /*   connected, error */

//@ex net.open
static const char hello[] = "N1:HTTP://127.0.0.1:7802/hello.txt";
//@end
//@ex net.read.loop
static const char bin[] = "N1:HTTP://127.0.0.1:7802/data.bin";
//@end
//@ex net.open.json
static const char json[] = "N2:HTTP://127.0.0.1:7802/fuji.json";
//@end
//@ex net.open.http_post
static const char post[] = "N3:HTTP://127.0.0.1:7802/post";
//@end
//@ex net.open.http_put
static const char put[] = "N3:HTTP://127.0.0.1:7802/put.txt";
//@end
//@ex net.open.http_delete
static const char del[] = "N3:HTTP://127.0.0.1:7802/old.txt";
//@end
//@ex net.close.unsent
static const char del2[] = "N3:HTTP://127.0.0.1:7802/never.txt";
//@end
//@ex net.open.http_put_h
static const char puth[] = "N3:HTTP://127.0.0.1:7802/puth.txt";
//@end
//@ex net.open.http_get_h
static const char geth[] = "N4:HTTP://127.0.0.1:7802/hello.txt";
//@end
//@ex net.open.tcp
static const char tcp[] = "N5:TCP://127.0.0.1:7801/";
//@end
//@ex net.open.tcp_server
static const char srv[] = "N6:TCP://:7803/";
//@end
//@ex net.open.udp
static const char udp[] = "N7:UDP://:7804/";
//@end
//@ex net.get_remote
static char remote[256];        /* the answer is always 256 bytes */
//@end
//@ex net.open.dir
static const char dir[] = "N8:SD:/test/";
//@end
//@ex net.open.file
static const char img[] = "N8:SD:/test/disk.img";
//@end
//@ex net.getcwd
static char cwd[256];
//@end

//@ex net.read
/* type len bytes as they are, line ends and all */
static void type(const uint8_t *p, uint16_t len)
{
    while (len--)
        putchar(*p++);
}
//@end

//@ex net.query.array
/* show len bytes, anything unprintable as '.' */
static void show(const uint8_t *p, uint16_t len)
{
    for (; len; len--, p++)
        putchar(*p >= ' ' && *p < 0x7F ? *p : '.');
}
//@end

//@ex net.status.tcp
/* 0.1 s: 50 ticks of the 2 ms clock */
static void pause_tenth(void)
{
    uint16_t t0 = TICKS;

    while ((uint16_t)(TICKS - t0) < 50)
        ;
}

/* Ask every 0.1 s, at most tries times, until bytes are
   waiting: how many, or 0 if none came. */
static uint16_t wait_avail(const char *spec, uint8_t tries)
{
    uint8_t n;

    for (n = 0; n < tries; n++) {
        pause_tenth();
        network_status(spec, &avail, &conn, &nerr);
        if (avail)
            break;
    }
    return avail;
}
//@end

//@ex net.status.listen
/* Ask every 0.5 s, for up to 15 s, until a caller waits
   ("connected" = 1): 1 if one does, 0 if no one came. */
static uint8_t wait_caller(const char *spec)
{
    uint8_t n, i;

    for (n = 0; n < 30; n++) {
        network_status(spec, &avail, &conn, &nerr);
        if (conn)
            break;
        for (i = 0; i < 5; i++)
            pause_tenth();
    }
    return conn;
}
//@end

int main(void)
{
    FN_ERR rc;
    int16_t len;
    uint16_t n, total;
    uint32_t pos;
    bool ok;

    con_init(0);

    /* ================================================== unit 1: GET */
    ex_mark("net.status.closed");
//@ex net.status.closed
    rc = network_status(hello, &avail, &conn, &nerr);
    printf("%u", nerr);             /* 207: nothing open on unit 1 */
//@end
    ex_showb(rc == FN_ERR_OK, &nw_status, 4);

    ex_mark("net.open");
//@ex net.open
    rc = network_open(hello, OPEN_MODE_HTTP_GET, OPEN_TRANS_NONE);
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.status");
//@ex net.status
    rc = network_status(hello, &avail, &conn, &nerr);   /* sends GET */
    printf("%u waiting", avail);
//@end
    ex_showb(rc == FN_ERR_OK, &nw_status, 4);

    ex_mark("net.read");
//@ex net.read
    n = avail < sizeof buf ? avail : sizeof buf;
    len = network_read(hello, buf, n);  /* STATUS, then READ */
    if (len > 0)
        type(buf, len);
//@end
    ex_showb(len > 0, buf, len > 0 ? len : 0);

    ex_mark("net.status.eof");
//@ex net.status.eof
    rc = network_status(hello, &avail, &conn, &nerr);
    printf("%u", nerr);             /* 136: the end */
//@end
    ex_showb(rc == FN_ERR_OK, &nw_status, 4);

    ex_mark("net.read.eof");
//@ex net.read.eof
    len = network_read(hello, buf, 64);
    printf("%d", len);              /* 0: its STATUS saw the end */
//@end
    ex_show(len == 0);

    ex_mark("net.close");
//@ex net.close
    rc = network_close(hello);
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.read.loop");
//@ex net.read.loop
    network_open(bin, OPEN_MODE_HTTP_GET, OPEN_TRANS_NONE);
    total = 0;
    while ((len = network_read_nb(bin, buf, sizeof buf)) > 0)
        total += len;               /* what was there, up to 2048 */
    printf("%u bytes", total);      /* 0 from it: the end */
    rc = network_close(bin);
//@end
    ex_show(total == 3000);

    ex_mark("net.read.ahead");
//@ex net.read.ahead
    network_open(bin, OPEN_MODE_HTTP_GET, OPEN_TRANS_NONE);
    /* network_read asks STATUS first; the bus-level READ does not */
    n = network_bus_read(FUJI_DEVICEID_NETWORK, buf, 2048);
    printf("%u ", n);               /* 2048, all of them */
    n = network_bus_read(FUJI_DEVICEID_NETWORK, buf, 2048);
    printf("%u", n);                /* 2048 again, though 952 came */
//@end
    ex_showb(n != 0, buf, 8);
    ex_mark("_tidy");
    network_close(bin);

    /* ================================================= unit 2: JSON */
    ex_mark("net.open.json");
//@ex net.open.json
    rc = network_open(json, OPEN_MODE_HTTP_GET, OPEN_TRANS_NONE);
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.set_parser");
//@ex net.set_parser
    rc = network_set_parser(json, PARSER_JSON);     /* after OPEN */
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.parse");
//@ex net.parse
    rc = network_json_parse(json);  /* sets the parser itself too */
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.status.parsed");
//@ex net.status.parsed
    rc = network_status(json, &avail, &conn, &nerr);
    printf("%u", nerr);             /* 136: the body is used up */
//@end
    ex_showb(rc == FN_ERR_OK, &nw_status, 4);

    ex_mark("net.query");
//@ex net.query
    len = network_json_query(json, "/name", (char *)buf);
    printf("%s", buf);              /* "FujiNet", line end removed */
//@end
    ex_showb(len > 0, buf, len > 0 ? len : 0);

    ex_mark("net.query.array");
//@ex net.query.array
    len = network_json_query(json, "/ports/2", (char *)buf);
    show(buf, len);                 /* "210": they count from 0 */
//@end
    ex_showb(len > 0, buf, len > 0 ? len : 0);

    ex_mark("net.set_parameter");
//@ex net.set_parameter
    network_set_parameter(json, 1, '\r');   /* 1: the line end */
    len = network_json_query(json, "/machine", (char *)buf);
    show(buf, len);                 /* "H89" (the CR is stripped) */
//@end
    ex_showb(len > 0, buf, len > 0 ? len : 0);

    ex_mark("net.query.missing");
//@ex net.query.missing
    len = network_json_query(json, "/serial", (char *)buf);
    printf("%d", len);              /* 0: not there, but no error */
//@end
    ex_show(len == 0);
    ex_mark("_tidy");
    network_close(json);

    /* ==================================== unit 3: POST, PUT, DELETE */
    ex_mark("net.open.http_post");
//@ex net.open.http_post
    rc = network_open(post, OPEN_MODE_HTTP_POST, OPEN_TRANS_NONE);
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.set_http_mode");
//@ex net.set_http_mode
    rc = network_http_set_mode(post, HTTP_CHAN_MODE_POST_SET_DATA);
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.write.http_post");
//@ex net.write.http_post
    rc = network_write(post, "name=H89&cpu=Z80", 16);  /* the body */
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.set_http_mode.body");
//@ex net.set_http_mode.body
    rc = network_http_set_mode(post, HTTP_CHAN_MODE_BODY);
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.status.http_post");
//@ex net.status.http_post
    rc = network_status(post, &avail, &conn, &nerr);   /* sends it */
    printf("%u waiting", avail);
//@end
    ex_showb(rc == FN_ERR_OK, &nw_status, 4);

    ex_mark("net.read.http_post");
//@ex net.read.http_post
    len = network_read(post, buf, avail);   /* the server's answer */
    if (len > 0)
        type(buf, len);
//@end
    ex_showb(len > 0, buf, len > 0 ? len : 0);
    ex_mark("_tidy");
    network_close(post);

    ex_mark("net.open.http_put");
//@ex net.open.http_put
    rc = network_open(put, OPEN_MODE_HTTP_PUT, OPEN_TRANS_NONE);
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.write.http_put");
//@ex net.write.http_put
    /* the body goes in as POST data does; it waits for CLOSE */
    rc = network_http_put(put, "PUT from an H89");
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.close.http_put");
//@ex net.close.http_put
    rc = network_close(put);        /* this sends the PUT */
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.open.http_delete");
//@ex net.open.http_delete
    rc = network_http_delete(del, OPEN_TRANS_NONE);    /* mode 9 */
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.status.http_delete");
//@ex net.status.http_delete
    rc = network_status(del, &avail, &conn, &nerr);    /* sends it */
    printf("%u waiting", avail);
//@end
    ex_showb(rc == FN_ERR_OK, &nw_status, 4);
    ex_mark("_tidy");
    network_close(del);

    ex_mark("net.close.unsent");
//@ex net.close.unsent
    network_open(del2, OPEN_MODE_HTTP_DELETE, OPEN_TRANS_NONE);
    rc = network_close(del2);       /* no STATUS or READ between: */
                                    /*   the DELETE is never sent */
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.open.http_put_h");
//@ex net.open.http_put_h
    network_open(puth, OPEN_MODE_HTTP_PUT_H, OPEN_TRANS_NONE);
    network_http_put(puth, "PUT or POST?");
    rc = network_status(puth, &avail, &conn, &nerr);   /* a POST! */
//@end
    ex_showb(rc == FN_ERR_OK, &nw_status, 4);
    ex_mark("_tidy");
    network_close(puth);

    /* ============================================== unit 4: headers */
    ex_mark("net.open.http_get_h");
//@ex net.open.http_get_h
    rc = network_open(geth, OPEN_MODE_HTTP_GET_H, OPEN_TRANS_NONE);
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.set_http_mode.set_headers");
//@ex net.set_http_mode.set_headers
    rc = network_http_start_add_headers(geth);  /* mode 3 */
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.write.header");
//@ex net.write.header
    rc = network_http_add_header(geth, "X-Machine: H89");
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.set_http_mode.collect");
//@ex net.set_http_mode.collect
    rc = network_http_set_mode(geth, HTTP_CHAN_MODE_COLLECT_HEADERS);
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.write.collect");
//@ex net.write.collect
    network_write(geth, "X-Test-Server", 13);   /* keep these two */
    rc = network_write(geth, "Content-Type", 12);
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.set_http_mode.get_headers");
//@ex net.set_http_mode.get_headers
    rc = network_http_set_mode(geth, HTTP_CHAN_MODE_GET_HEADERS);
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.read.header");
//@ex net.read.header
    for (n = 0; n < 2; n++) {       /* exactly two: no more */
        network_status(geth, &avail, &conn, &nerr);
        len = network_read(geth, buf, avail);   /* ends with 9BH */
        show(buf, len);
        putchar('\n');
    }
//@end
    ex_showb(len > 0, buf, len > 0 ? len : 0);
    ex_mark("_tidy");
    network_close(geth);

    /* =========================================== unit 5: TCP client */
    ex_mark("net.open.tcp");
//@ex net.open.tcp
    rc = network_open(tcp, OPEN_MODE_RW, OPEN_TRANS_NONE);
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.status.tcp");
//@ex net.status.tcp
    printf("%u waiting", wait_avail(tcp, 100)); /* the greeting */
//@end
    ex_showb(avail != 0, &nw_status, 4);

    ex_mark("net.read.tcp");
//@ex net.read.tcp
    len = network_read(tcp, buf, avail);    /* no more than that */
    if (len > 0)
        type(buf, len);
//@end
    ex_showb(len > 0, buf, len > 0 ? len : 0);

    ex_mark("net.write");
//@ex net.write
    rc = network_write(tcp, "hello from the h89\r", 19);
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.read.tcp_reply");
//@ex net.read.tcp_reply
    n = 100;                        /* up to 10 s for the answer, */
    while (wait_avail(tcp, n)) {
        len = network_read(tcp, buf, avail);
        if (len > 0)
            type(buf, len);
        n = 5;                      /* then more, until 0.5 s */
    }                               /*   pass with none */
//@end
    ex_showb(len > 0, buf, len > 0 ? len : 0);

    ex_mark("net.status.hangup");
//@ex net.status.hangup
    network_write(tcp, "BYE\r", 4); /* the board hangs up */
    n = 0;
    do {                            /* watch for that, 5 s at most */
        pause_tenth();
        network_status(tcp, &avail, &conn, &nerr);
    } while (conn && ++n < 50);
    printf("%u %u", nerr, avail);   /* 136, but the goodbye is */
                                    /*   still there to be read */
//@end
    ex_showb(avail != 0, &nw_status, 4);
    ex_mark("_tidy");
    network_close(tcp);

    /* =========================================== unit 6: TCP server */
    ex_mark("net.open.tcp_server");
//@ex net.open.tcp_server
    rc = network_open(srv, OPEN_MODE_RW, OPEN_TRANS_NONE);  /* listen */
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.status.listen");
//@ex net.status.listen
    ok = wait_caller(srv);
//@end
    ex_showb(ok, &nw_status, 4);

    ex_mark("net.accept");
//@ex net.accept
    rc = network_accept(srv);       /* take the call */
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.read.server");
//@ex net.read.server
    len = network_read(srv, buf, wait_avail(srv, 100));
    if (len > 0)
        type(buf, len);
//@end
    ex_showb(len > 0, buf, len > 0 ? len : 0);

    ex_mark("net.write.server");
//@ex net.write.server
    rc = network_write(srv, "PONG\r\n", 6);
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.close_client");
//@ex net.close_client
    wait_caller(srv);               /* the next caller: */
    network_accept(srv);
    rc = network_close_client(srv); /* FN_ERR_IO_ERROR means it */
                                    /*   DID hang up: inverted */
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.close_client.none");
//@ex net.close_client.none
    rc = network_close_client(srv); /* nothing to do: FN_ERR_OK */
//@end
    ex_show(rc == FN_ERR_OK);
    ex_mark("_tidy");
    network_close(srv);

    /* ================================================== unit 7: UDP */
    ex_mark("net.open.udp");
//@ex net.open.udp
    rc = network_open(udp, OPEN_MODE_RW, OPEN_TRANS_NONE);
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.get_remote.early");
//@ex net.get_remote.early
    rc = network_udp_get_remote(udp, remote, sizeof remote);
    printf("%s", remote);           /* none yet: 255.255.255.255:0 */
//@end
    ex_showb(rc == FN_ERR_OK, remote, 24);

    ex_mark("net.read.udp");
//@ex net.read.udp
    /* STATUS counts only the datagram AFTER the one it took in, so
       wait until that one has come too, then read the first */
    len = network_read(udp, buf, wait_avail(udp, 50));
    show(buf, len);
//@end
    ex_showb(len > 0, buf, len > 0 ? len : 0);

    ex_mark("net.get_remote");
//@ex net.get_remote
    /* the buffer must hold all 256 bytes, or the call fails */
    rc = network_udp_get_remote(udp, remote, sizeof remote);
    printf("%s", remote);           /* who sent it */
//@end
    ex_showb(rc == FN_ERR_OK, remote, 24);

    ex_mark("net.set_destination");
//@ex net.set_destination
    /* not network_udp_set_destination(): it sends no NUL, which
       fujinet-pc needs, and wants "N7:", which the card misreads */
    ok = fuji_bus_call(FUJI_DEVICEID_NETWORK + 6,
                       NETCMD_SET_DESTINATION, FUJI_FIELD_NONE,
                       0, 0, 0, 0, "N:127.0.0.1:7805", 17);  /* +NUL */
//@end
    ex_show(ok);

    ex_mark("net.write.udp");
//@ex net.write.udp
    rc = network_write(udp, "PONG", 4);     /* one datagram */
//@end
    ex_show(rc == FN_ERR_OK);
    ex_mark("_tidy");
    network_close(udp);

    /* ========================================== unit 8: the SD card */
    ex_mark("net.open.dir");
//@ex net.open.dir
    rc = network_open(dir, 6, 0);   /* 6: a directory, short form */
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.read.dir");
//@ex net.read.dir
    network_status(dir, &avail, &conn, &nerr);
    len = network_read(dir, buf, avail);    /* a line a file */
    if (len > 0)
        type(buf, len);
//@end
    ex_showb(len > 0, buf, len > 0 ? len : 0);
    ex_mark("_tidy");
    network_close(dir);

    ex_mark("net.open.write");
//@ex net.open.write
    rc = network_open("N8:SD:/test/h89.txt", OPEN_MODE_WRITE,
                      OPEN_TRANS_NONE);     /* a new file */
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.write.file");
//@ex net.write.file
    rc = network_write("N8:", "Written by an H89.\r\n", 20);
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.close.file");
//@ex net.close.file
    rc = network_close("N8:");      /* finish the file */
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.open.file");
//@ex net.open.file
    rc = network_open(img, OPEN_MODE_READ, OPEN_TRANS_NONE);
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.seek");
//@ex net.seek
    network_seek(img, 1536);        /* sector 3 */
    len = network_read(img, buf, 8);
    for (n = 0; n < len; n++)
        printf("%02X ", buf[n]);    /* 03 03 03 ... */
//@end
    ex_showb(len == 8, buf, 8);

    ex_mark("net.tell");
//@ex net.tell
    rc = network_tell(img, &pos);
    printf("%lu", pos);             /* 1544 */
//@end
    ex_showb(rc == FN_ERR_OK, &pos, 4);
    ex_mark("_tidy");
    network_close(img);

    ex_mark("net.rename");
//@ex net.rename
    rc = network_fs_rename("N8:SD:/test/h89.txt,h89new.txt");
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.delete");
//@ex net.delete
    rc = network_fs_delete("N8:SD:/test/h89new.txt");
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.mkdir");
//@ex net.mkdir
    rc = network_fs_mkdir("N8:SD:/test/newdir");
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.rmdir");
//@ex net.rmdir
    rc = network_fs_rmdir("N8:SD:/test/newdir");    /* it is empty */
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.lock");
//@ex net.lock
    rc = network_fs_lock("N8:SD:/test/readme.txt"); /* SD: cannot */
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.unlock");
//@ex net.unlock
    rc = network_fs_unlock("N8:SD:/test/readme.txt");
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.chdir");
//@ex net.chdir
    rc = network_fs_cd("N8:SD:/test/");     /* names start here now */
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.getcwd");
//@ex net.getcwd
    memset(cwd, 0, sizeof cwd);     /* the answer has no NUL */
    rc = network_fs_pwd("N8:", cwd);
    printf("%s", cwd);
//@end
    ex_showb(rc == FN_ERR_OK, cwd, 16);

    ex_mark("net.open.relative");
//@ex net.open.relative
    network_open("N8:readme.txt", OPEN_MODE_READ, OPEN_TRANS_NONE);
    network_status("N8:", &avail, &conn, &nerr);
    len = network_read("N8:", buf, avail);
    if (len > 0)
        type(buf, len);
//@end
    ex_showb(len > 0, buf, len > 0 ? len : 0);
    ex_mark("_tidy");
    network_close("N8:");

    /* ===================================== unit 1: settings, errors */
    ex_mark("net.username");
//@ex net.username
    rc = network_set_username("N1:", "h89user");
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.password");
//@ex net.password
    rc = network_set_password("N1:", "swordfish");
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.set_eol");
//@ex net.set_eol
    rc = network_set_eol("N1:", "\r");      /* our lines end CR */
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.translation");
//@ex net.translation
    rc = network_set_translation("N1:", OPEN_TRANS_CRLF);
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.open.translated");
//@ex net.open.translated
    network_open(hello, OPEN_MODE_HTTP_GET, OPEN_TRANS_NONE);
    network_status(hello, &avail, &conn, &nerr);
    len = network_read(hello, buf, avail);  /* 53, not 55: each */
    show(buf, len);                         /*   CR LF came as CR */
//@end
    ex_showb(len > 0, buf, len > 0 ? len : 0);
    ex_mark("_tidy");
    network_close(hello);
    network_set_translation("N1:", OPEN_TRANS_NONE);
    network_set_eol("N1:", "");

    ex_mark("net.set_int_rate");
//@ex net.set_int_rate
    rc = network_set_interrupt_rate("N1:", 100);    /* never 0 */
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.open.refused");
//@ex net.open.refused
    rc = network_open("N1:TCP://127.0.0.1:1/", OPEN_MODE_RW,
                      OPEN_TRANS_NONE);     /* FN_ERR_IO_ERROR */
//@end
    ex_show(rc == FN_ERR_OK);

    ex_mark("net.status.refused");
//@ex net.status.refused
    rc = network_status("N1:", &avail, &conn, &nerr);
    printf("%u", nerr);             /* 200: connection refused */
//@end
    ex_showb(rc == FN_ERR_OK, &nw_status, 4);
    ex_mark("_tidy");
    network_close("N1:");

    ex_mark("net.get_error");
//@ex net.get_error
    /* fujinet-lib has no call for it: the units do not know it */
    ok = fuji_bus_call(FUJI_DEVICEID_NETWORK, NETCMD_GET_ERROR,
                       FUJI_FIELD_NONE, 0, 0, 0, 0, NULL, 0);
//@end
    ex_show(ok);

    ex_done();
    con_exit();
    return 0;
}
