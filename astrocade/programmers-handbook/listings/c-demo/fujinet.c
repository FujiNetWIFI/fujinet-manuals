/* fujinet.c -- the mailbox transport, in C.
 *
 * Every routine is a direct rendering of its fujilib.inc counterpart; the
 * comments there apply here too.  The one C-specific trick is fn_sink: a
 * hotspot is "written" by READING it, and assigning the volatile read to a
 * volatile byte guarantees the compiler emits the load and never elides
 * or reorders it.  Instruction fetches in between are harmless -- the
 * program executes from 0x2000-0x3aff and the hotspot pages start at
 * 0x3d00, so ordinary code never trips them.
 */

#include "fujinet.h"

static volatile unsigned char fn_sink;

#define FN_HOT(page, v) (fn_sink = (page)[v])

unsigned int  net_avail;
unsigned char net_connected;
unsigned char net_devstatus;
unsigned int  net_rxlen;

static unsigned char cur_slice;

unsigned char fn_check(void)
{
    return FN_MAGIC0 == 'F' && FN_MAGIC1 == 'N';
}

void fn_regwr(unsigned char reg, unsigned char val)
{
    FN_HOT(FN_REGSEL, reg);     /* arm the register        */
    FN_HOT(FN_REGDATA, val);    /* deliver the value       */
}

void fn_tx_byte(unsigned char v)
{
    FN_HOT(FN_DATA, v);
}

void fn_tx_parb(unsigned char v)
{
    fn_tx_byte(1);              /* size byte               */
    fn_tx_byte(v);
}

void fn_tx_parw(unsigned int v)
{
    fn_tx_byte(2);
    fn_tx_byte(v & 0xff);       /* little-endian           */
    fn_tx_byte(v >> 8);
}

void fn_tx_str(const char *s)
{
    while (*s)
        fn_tx_byte(*s++);
}

void fn_begin(unsigned char device, unsigned char command,
              unsigned char nparam)
{
    fn_regwr(FN_REG_DATA_RST, 0);
    fn_regwr(FN_REG_DEVICE, device);
    fn_regwr(FN_REG_CMD, command);
    fn_regwr(FN_REG_NPARAM, nparam);
}

/* Commit the transaction and wait for the cartridge to acknowledge.
 * The next sequence number is the cart's own persisted ACKSEQ + 1,
 * wrapping 255 -> 1 (0 is reserved as "never used").
 */
unsigned char fn_commit(unsigned char quanta)
{
    unsigned char want;
    unsigned int spin;

    want = FN_ACKSEQ + 1;
    if (want == 0)
        want = 1;
    fn_regwr(FN_REG_SEQ, want);
    while (quanta--) {
        spin = 0;
        do {
            if (FN_ACKSEQ == want)
                return FN_ERRBYTE;
        } while (--spin != 0);  /* 65,536 polls per quantum */
    }
    return FN_ERR_CLIENT_TIMEOUT;
}

/* Select reply slice n and wait for the repaint: the cart publishes
 * FN_SLICE_ECHO last, so the slice is whole once it echoes.
 */
unsigned char fn_slice(unsigned char n)
{
    unsigned int spin;

    fn_regwr(FN_REG_RXSLICE, n);
    spin = 0;
    do {
        if (FN_SLICE_ECHO == n)
            return FN_ERR_OK;
    } while (--spin != 0);
    return FN_ERR_CLIENT_TIMEOUT;
}

/* ---- flat reply window ---------------------------------------------- */

/* Every transaction makes the cart republish slice 0; call rx_home after
 * each one so the cache agrees.
 */
void rx_home(void)
{
    cur_slice = 0;
}

unsigned char rx_getb(unsigned int off)
{
    unsigned char s = off >> 8;

    if (s != cur_slice) {
        cur_slice = s;
        fn_slice(s);
    }
    return FN_RDATA[off & 0xff];
}

unsigned int rx_getw(unsigned int off)
{
    unsigned char lo = rx_getb(off);

    return lo | ((unsigned int)rx_getb(off + 1) << 8);
}

void rx_strn(char *dst, unsigned int off, unsigned char max)
{
    unsigned char c;

    while (max--) {
        c = rx_getb(off++);
        if (c == 0)
            break;
        *dst++ = c;
    }
    *dst = 0;
}

/* ---- N: device round trip (netcat's shape) --------------------------- */

unsigned char net_open(const char *devicespec, unsigned char mode,
                       unsigned char translation)
{
    unsigned char r;

    fn_begin(FN_DEV_NET, NET_OPEN, 2);
    fn_tx_parb(mode);
    fn_tx_parb(translation);
    fn_tx_str(devicespec);
    r = fn_commit(8);           /* 16 s: HTTPS handshakes are slow */
    rx_home();
    if (r != FN_ERR_OK)
        return r;
    return FN_REPLY == FN_ACK ? FN_ERR_OK : FN_NAK;
}

unsigned char net_close(void)
{
    unsigned char r;

    fn_begin(FN_DEV_NET, NET_CLOSE, 0);
    r = fn_commit(3);
    rx_home();
    return r;
}

unsigned char net_status(void)
{
    unsigned char r;

    fn_begin(FN_DEV_NET, NET_STATUS, 2);
    fn_tx_parb(0);
    fn_tx_parb(0);
    r = fn_commit(4);
    rx_home();
    if (r != FN_ERR_OK)
        return r;
    if (FN_REPLY != FN_ACK)
        return FN_NAK;
    net_avail = FN_RDATA_B(0) | ((unsigned int)FN_RDATA_B(1) << 8);
    net_connected = FN_RDATA_B(2);
    net_devstatus = FN_RDATA_B(3);
    return FN_ERR_OK;
}

unsigned char net_read(unsigned int len)
{
    unsigned char r;

    fn_begin(FN_DEV_NET, NET_READ, 1);
    fn_tx_byte(2);              /* one two-byte parameter: the length */
    fn_tx_byte(len & 0xff);
    fn_tx_byte(len >> 8);
    r = fn_commit(8);
    rx_home();
    if (r != FN_ERR_OK)
        return r;
    if (FN_REPLY != FN_ACK)
        return FN_NAK;
    /* capture NOW: the length bytes belong to this transaction only */
    net_rxlen = FN_RXLEN_LO | ((unsigned int)FN_RXLEN_HI << 8);
    return FN_ERR_OK;
}

unsigned char net_write(const unsigned char *buf, unsigned char len)
{
    unsigned char r;
    unsigned char n = len;

    if (n == 0)
        return FN_ERR_OK;
    fn_begin(FN_DEV_NET, NET_WRITE, 1);
    fn_tx_byte(2);              /* the count rides twice: as this      */
    fn_tx_byte(len);            /* parameter, and as the payload the   */
    fn_tx_byte(0);              /* cartridge measures                  */
    while (n--)
        fn_tx_byte(*buf++);
    r = fn_commit(4);
    rx_home();
    if (r != FN_ERR_OK)
        return r;
    return FN_REPLY == FN_ACK ? FN_ERR_OK : FN_NAK;
}
