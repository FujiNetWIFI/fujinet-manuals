/*
 * NGET -- copy a file from the network to a disk, in C. Opens the
 * devicespec on network unit 1 for reading and writes whatever comes to
 * the file, until the FujiNet says the end has been reached. NGET.ASM's
 * twin.
 *
 *   NGET N:HTTP://192.168.1.10/hello.txt SY1:HELLO.TXT      (HDOS)
 *   NGET                    (and answer; CP/M capitalises a command line)
 *
 * HDOS and CP/M keep files in whole sectors and records, so the copy ends
 * with up to a sector of zeros, or a record of CTRL-Z, after the data.
 *
 *   tools/cc.sh hdos NGET src/c/nget/nget.c src/c/common/words.c \
 *       src/c/common/hdosargs.c                     ->  NGET.ABS
 *   tools/cc.sh cpm NGET ...the same...             ->  NGET.COM
 *
 * Copyright (C) 2026 Thomas Cherryhomes
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#include <stdio.h>
#include <string.h>
#include <fujinet-network.h>
#include "h89con.h"
#include "hdosargs.h"
#include "words.h"

#define BUFSZ     512           /* bytes taken from the FujiNet at once */
#define EOF_ERR   136           /* STATUS error: the end of the data */
#define WAIT_SECS 30            /* give up after this long with nothing */

static char spec[132], fname[32];
static uint8_t buf[BUFSZ];

int main(int argc, char *argv[])
{
    FILE *f;
    uint16_t avail, len, last;
    uint8_t connected, err;
    unsigned long total = 0;
    int result = 0;

    ARGS(argc, argv);
    con_init(0);
    printf("NGET - copy a file from the network\n");
//@ex nget.args
    if (two_words(argc, argv, "From (devicespec): ", spec, sizeof spec - 2,
                  "To (file): ", fname, sizeof fname) < 0) {
        printf("Usage: NGET devicespec file\n");
        goto out;
    }
    net_spec(spec);
//@end

//@ex nget.open
    if (network_open(spec, 4, 0) != FN_ERR_OK) {    /* read, no translation */
        printf("The FujiNet could not open that.\n");
        goto out;
    }
//@end
    if ((f = fopen(fname, "wb")) == NULL) {
        printf("Cannot create the file.\n");
        network_close(spec);
        goto out;
    }

//@ex nget.loop
    last = TICKS;
    for (;;) {
        if (network_status(spec, &avail, &connected, &err) != FN_ERR_OK
            || (avail == 0 && err > 1 && err != EOF_ERR)) {
            printf("Network error %u\n", err);
            result = 1;
            break;
        }
        if (avail == 0) {
            if (err == EOF_ERR || !connected)       /* the end */
                break;
            if ((uint16_t)(TICKS - last) > WAIT_SECS * TICKS_PER_SECOND) {
                printf("Nothing came for %u seconds; stopped.\n", WAIT_SECS);
                result = 1;
                break;
            }
            continue;
        }
        len = avail > BUFSZ ? BUFSZ : avail;        /* never more than waits */
        len = network_read(spec, buf, len);
        if (fwrite(buf, 1, len, f) != len) {
            printf("Cannot write the file (disk full?).\n");
            result = 1;
            break;
        }
        total += len;
        last = TICKS;
    }
//@end

//@ex nget.close
    network_close(spec);
    fclose(f);
//@end
    if (!result)
        printf("%lu bytes copied.\n", total);
out:
    con_exit();
    return result;
}
