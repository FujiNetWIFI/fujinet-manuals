/* netlib.c -- the five N: commands. See netlib.h.
 *
 * The one thing worth saying that is not in fujilib: the status reply, and the
 * read reply, both land in the reply window and are only valid until the next
 * transaction. NETCAT's session loop is written around that -- status, then
 * read, then draw, with nothing in between that would repaint the window.
 */

#include <stdint.h>

#include "fujilib.h"
#include "netlib.h"

bool net_present(void)
{
    return fn_present();
}

bool net_open(const char *spec)
{
    fn_start(NET_DEV_N1, NET_OPEN);
    fn_param8(NET_MODE_READWRITE);
    fn_param8(NET_TRANS_NONE);
    fn_tx_padded(spec, NET_SPEC_LEN);
    return fn_commit() == FN_OK && fn_acked();
}

void net_close(void)
{
    fn_start(NET_DEV_N1, NET_CLOSE);
    (void)fn_commit();          /* best effort */
}

bool net_status(unsigned int *avail, unsigned char *conn,
                unsigned char *devstatus)
{
    volatile unsigned char *r;

    fn_start(NET_DEV_N1, NET_STATUS);
    /* The RS232 build reads the request type from parameter 1 and wants both
     * present; parameter 0 is legacy and ignored. Two zeroes ask for the
     * open channel's own status. */
    fn_param8(0);
    fn_param8(0);
    if (fn_commit() != FN_OK || !fn_acked())
        return false;

    /* Four bytes: avail lo, avail hi, connected, device status. Read through a
     * local pointer -- never FN_REPLY[i] -- for the sccz80 reason in fujilib. */
    r = FN_REPLY;
    *avail = (unsigned int)r[0] | ((unsigned int)r[1] << 8);
    *conn = r[2];
    *devstatus = r[3];
    return true;
}

unsigned int net_read(unsigned int want)
{
    if (want > NET_READ_MAX)
        want = NET_READ_MAX;

    fn_start(NET_DEV_N1, NET_READ);
    fn_param16(want);
    if (fn_commit() != FN_OK || !fn_acked())
        return 0;

    /* The firmware always sends exactly `want` bytes on ACK, so this equals
     * what we asked for; capture it from the transaction rather than trusting
     * the argument, because a NAK read comes back short. */
    return fn_reply_len();
}

bool net_write(const unsigned char *buf, unsigned int len)
{
    if (len > NET_WRITE_MAX)
        len = NET_WRITE_MAX;

    fn_start(NET_DEV_N1, NET_WRITE);
    fn_param16(len);
    fn_tx_bytes(buf, len);
    return fn_commit() == FN_OK && fn_acked();
}
