/* main.c -- FUJINET C DEMO for the Bally Astrocade.
 *
 * The C rendering of "first contact": check the cartridge magic, run one
 * GET_ADAPTERCONFIG_EXTENDED transaction, and show the adapter's SSID,
 * firmware version and IP address on screen.  Built with z88dk's
 * +astrocde target -- see the Makefile for the recipe and the handbook's
 * C chapter for the caveats.
 *
 * The crt0 runs with interrupts disabled (CRT_ENABLE_EIDI=1) and they
 * stay off for the program's whole life: with I = 0, Z80 refresh strays
 * land in the on-board ROM and never touch the mailbox hotspots.
 */

#include "fujinet.h"
#include "text.h"

void port_out(unsigned char port, unsigned char val);   /* support.asm */

#define LINES 80                /* visible scanlines: 10 text rows      */

/* COLSET order, descending ports 7..0: color 3,2,1,0 for the left
 * palette, then the same for the right.  3 white, 2 red, 1 gray,
 * 0 black; byte = (hue << 3) | luminance.
 */
static const unsigned char palette[8] = {
    0x07, 0x52, 0x03, 0x00,
    0x07, 0x52, 0x03, 0x00,
};

static void screen_init(void)
{
    unsigned char i;

    for (i = 0; i < 8; ++i)
        port_out(7 - i, palette[i]);
    port_out(0x09, 0);          /* HORCB: one palette all the way over  */
    port_out(0x0a, LINES * 2);  /* VERBL: blank below the text          */
    port_out(0x0e, 8);          /* INMOD                                */
    txt_clear();
}

static char buf[33];

int main(void)
{
    unsigned char r;

    screen_init();
    txt_puts(0, 0, "FUJINET C DEMO");

    if (!fn_check()) {
        txt_puts(0, 2, "NO FUJINET CART");
        for (;;) ;
    }

    txt_puts(0, 1, "PROTO");
    txt_hex(6, 1, FN_PROTO);
    txt_puts(9, 1, (FN_STATUS & FN_STATUS_LINK) ? "LINK UP" : "NO LINK");

    /* One whole transaction: no parameters, no payload, 240-byte reply. */
    fn_begin(FN_DEV_FUJI, FUJI_GET_ADAPTERCONFIG_EXTENDED, 0);
    r = fn_commit(8);
    rx_home();
    if (r != FN_ERR_OK) {
        txt_puts(0, 3, "ERR");
        txt_hex(4, 3, r);
        for (;;) ;
    }
    if (FN_REPLY != FN_ACK) {
        txt_puts(0, 3, "NAK");
        for (;;) ;
    }

    rx_strn(buf, 0, 20);        /* ssid[33] at offset 0                 */
    txt_puts(0, 3, "SSID");
    txt_puts(0, 4, buf);

    rx_strn(buf, 125, 15);      /* fn_version[15] at offset 125         */
    txt_puts(0, 5, "FW");
    txt_puts(3, 5, buf);

    rx_strn(buf, 140, 16);      /* sLocalIP[16] at offset 140           */
    txt_puts(0, 6, "IP");
    txt_puts(3, 6, buf);

    txt_puts(0, 8, "OK");
    for (;;) ;
    return 0;
}
