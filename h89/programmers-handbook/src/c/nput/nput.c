/*
 * NPUT -- copy a file from a disk to the network, in C. Opens the
 * devicespec on network unit 1 for writing, sends the file in pieces, and
 * closes the channel, which is when an HTTP PUT is really sent. NPUT.ASM's
 * twin.
 *
 *   NPUT SY1:HELLO.TXT N:HTTP://192.168.1.10/hello.txt      (HDOS)
 *   NPUT                    (and answer; CP/M capitalises a command line)
 *
 * HDOS and CP/M know a file's length only in whole sectors and records,
 * so the copy is that long.
 *
 *   tools/cc.sh hdos NPUT src/c/nput/nput.c src/c/common/words.c \
 *       src/c/common/hdosargs.c                     ->  NPUT.ABS
 *   tools/cc.sh cpm NPUT ...the same...             ->  NPUT.COM
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

#define BUFSZ 512               /* bytes sent to the FujiNet at once */

static char spec[132], fname[32];
static uint8_t buf[BUFSZ];

int main(int argc, char *argv[])
{
    FILE *f;
    size_t len;
    unsigned long total = 0;
    int result = 0;

    ARGS(argc, argv);
    con_init(0);
    printf("NPUT - copy a file to the network\n");
//@ex nput.args
    if (two_words(argc, argv, "From (file): ", fname, sizeof fname,
                  "To (devicespec): ", spec, sizeof spec - 2) < 0) {
        printf("Usage: NPUT file devicespec\n");
        goto out;
    }
    net_spec(spec);
//@end
    if ((f = fopen(fname, "rb")) == NULL) {
        printf("Cannot open the file.\n");
        goto out;
    }

//@ex nput.open
    if (network_open(spec, 8, 0) != FN_ERR_OK) {    /* write, no translation */
        printf("The FujiNet could not open that.\n");
        fclose(f);
        goto out;
    }
//@end

//@ex nput.loop
    while ((len = fread(buf, 1, BUFSZ, f)) > 0) {
        if (network_write(spec, buf, len) != FN_ERR_OK) {
            printf("Network error; the copy may be incomplete.\n");
            result = 1;
            break;
        }
        total += len;
    }
//@end

//@ex nput.close
    network_close(spec);                            /* an HTTP PUT goes now */
    fclose(f);
//@end
    if (!result)
        printf("%lu bytes sent.\n", total);
out:
    con_exit();
    return result;
}
