/*
 * HELLO -- first contact, in C. Asks the FujiNet for its adapter
 * configuration and prints the network it has joined, its name, its address
 * and its firmware version: FNHELLO's job, done with fujinet-lib.
 *
 *   tools/cc.sh hdos HELLO src/c/hello/hello.c   ->  HELLO.ABS (HDOS)
 *   tools/cc.sh cpm  HELLO src/c/hello/hello.c   ->  HELLO.COM (CP/M)
 *
 * Copyright (C) 2026 Thomas Cherryhomes
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#include <stdio.h>
#include <fujinet-fuji.h>

static AdapterConfig cfg;

int main(void)
{
    printf("HELLO - first contact with the FujiNet\n");
//@ex hello.config
    if (!fuji_get_adapter_config(&cfg)) {
        printf("The FujiNet did not answer.\n");
        return 1;
    }
//@end
    printf("Network:  %s\n", cfg.ssid);
    printf("Name:     %s\n", cfg.hostname);
    printf("Address:  %u.%u.%u.%u\n", cfg.localIP[0], cfg.localIP[1],
           cfg.localIP[2], cfg.localIP[3]);
    printf("Firmware: %s\n", cfg.fn_version);
    return 0;
}
