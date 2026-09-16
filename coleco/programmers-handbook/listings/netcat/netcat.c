/* netcat.c -- a terminal for the FujiNet N: device.
 *
 * Give it any N: devicespec and it pumps bytes between the connection and a
 * scrolling pane, forever: call a telnet BBS, watch a TCP echo server, talk to
 * anything that talks back. It is the network-device counterpart to fujitest --
 * the smallest program that exercises N: open/status/read/write/close end to
 * end -- and the one client in this handbook that holds a single connection
 * open for its whole life rather than opening one per request.
 *
 * The session loop is three moves in a fixed order:
 *
 *   1. NET_STATUS  -- how many bytes wait, and are we still connected;
 *   2. NET_READ    -- pull them into the reply window (if any);
 *   3. draw them   -- straight out of the window, before anything else runs.
 *
 * Nothing may fall between the read and the draw: every transaction repaints
 * the reply window, so a stray status poll there would erase the bytes we were
 * about to show. That is the whole discipline; the rest is a keyboard.
 */

#include <os7.h>

#include "fujidisp.h"
#include "fujiin.h"
#include "fujiedit.h"
#include "fujisnd.h"
#include "fujilib.h"
#include "netlib.h"
#include "netterm.h"

/* The devicespec NETCAT dials unless you edit it. A telnet BBS makes the best
 * demonstration: it answers in ASCII, in lowercase, and it scrolls. */
static char spec[NET_SPEC_LEN] = "N:TELNET://bbs.fozztexx.com/";

static void title(const char *s)
{
    disp_row_clear(0);
    disp_at(1, 0, s);
}

static void legend(const char *s)
{
    disp_row_clear(23);
    disp_at(1, 23, s);
}

/* The dial screen: edit the devicespec on the on-screen keyboard, then open
 * it. Returns when a connection is live. fn_edit preloads and reads back
 * fn_entry, so the spec round-trips through the 64-byte editor buffer -- which
 * is why a devicespec here cannot exceed FN_ENTRY_MAX-1. That is plenty for a
 * host and path; the 256-byte NET_OPEN buffer is the firmware's limit, not the
 * user's. */
static void dial(void)
{
    unsigned int i;

    for (;;) {
        /* Copy the current spec into the editor buffer, edit, copy back. */
        for (i = 0; i < FN_ENTRY_MAX - 1 && spec[i]; i++)
            fn_entry[i] = spec[i];
        fn_entry[i] = '\0';

        if (fn_edit("DIAL  N: DEVICESPEC", FN_ENTRY_MAX - 1)) {
            for (i = 0; i < FN_ENTRY_MAX - 1 && fn_entry[i]; i++)
                spec[i] = fn_entry[i];
            spec[i] = '\0';
        }

        disp_cls();
        title("NETCAT");
        disp_at(1, TERM_TOP, "DIALING...");

        if (net_open(spec))
            return;

        disp_at(1, TERM_TOP + 1, "CONNECT FAILED");
        disp_at(1, TERM_TOP + 3, "FIRE TO EDIT AND RETRY");
        while (in_read() != IN_FIRE)
            ;
    }
}

/* Compose a line on the on-screen keyboard and send it with a trailing CR.
 * The pane is saved first because fn_edit clears the screen, and restored
 * after so the conversation is unbroken. fn_edit runs no transactions, so the
 * connection is undisturbed by the detour. */
static void compose_and_send(void)
{
    unsigned char n;

    term_save();
    fn_entry[0] = '\0';
    if (fn_edit("SEND  (# sends)", NET_WRITE_MAX - 1)) {
        for (n = 0; fn_entry[n]; n++)
            ;
        fn_entry[n++] = '\r';   /* the line terminator most hosts expect */
        term_restore();
        net_write((const unsigned char *)fn_entry, n);
    } else {
        term_restore();
    }
}

static void session(void)
{
    unsigned int avail, got;
    unsigned char conn, ds, ev;

    term_init();
    title("NETCAT  CONNECTED");
    legend("# SEND   * HANG UP");

    for (;;) {
        if (!net_status(&avail, &conn, &ds)) {
            title("NETCAT  LINK LOST");
            return;
        }
        if (!conn && avail == 0) {
            title("NETCAT  DISCONNECTED");
            return;
        }

        if (avail != 0) {
            got = net_read(avail > NET_READ_MAX ? NET_READ_MAX : avail);
            /* Draw immediately, straight out of the reply window, before any
             * other transaction can repaint it. */
            term_puts(FN_REPLY, got);
        }

        ev = in_read();
        if (ev == IN_KEYHASH || ev == IN_FIRE)
            compose_and_send();
        else if (ev == IN_KEYSTAR) {
            net_close();
            title("NETCAT  HUNG UP");
            return;
        }
    }
}

void main(void)
{
    snd_init();                 /* the PSG powers up buzzing; see fujisnd.h */
    disp_init();
    in_init();

    if (!net_present()) {
        disp_at(4, 8, "NO FUJINET CART");
        for (;;)
            ;
    }

    for (;;) {
        dial();
        session();
    }
}
