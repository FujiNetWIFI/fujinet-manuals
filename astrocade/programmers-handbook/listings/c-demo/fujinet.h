/* fujinet.h -- the FujiNet cartridge mailbox for Z88DK C.
 *
 * A C rendering of the contract in fujilib.inc, which in turn mirrors the
 * single source of truth, fujinet-firmware/pico/astrocade/firmware/include/
 * fuji_mailbox.h.  Everything here is a READ: the Astrocade cartridge edge
 * has no write strobe, so the console talks by reading hotspot pages where
 * the low address byte IS the payload, and the cartridge answers by
 * repainting the ROM bytes it serves.
 *
 * All addresses are console addresses (cart offset + 0x2000).
 */

#ifndef FUJINET_H
#define FUJINET_H

/* ---- reply bytes (repainted ROM) ----------------------------------- */

#define FN_RDATA      ((volatile unsigned char *)0x3b00) /* 256-byte slice */

/* Reply byte at a CONSTANT offset.  sccz80 (z88dk 3bd06cad, 2026-07)
 * miscompiles a constant subscript on a cast-constant pointer --
 * FN_RDATA[2] becomes the constant 2, silently -- while a variable
 * subscript and this dereference-of-a-sum form both compile correctly.
 * Use FN_RDATA[i] only when i is a variable.
 */
#define FN_RDATA_B(i) (*(volatile unsigned char *)(0x3b00 + (i)))

#define FN_ACKSEQ     (*(volatile unsigned char *)0x3c00) /* echoes SEQ    */
#define FN_STATUS     (*(volatile unsigned char *)0x3c01) /* bit0 link up  */
#define FN_ERRBYTE    (*(volatile unsigned char *)0x3c02) /* last fb_status*/
#define FN_REPLY      (*(volatile unsigned char *)0x3c03) /* 0x06 ACK/0x15 */
#define FN_RXLEN_LO   (*(volatile unsigned char *)0x3c04) /* reply length  */
#define FN_RXLEN_HI   (*(volatile unsigned char *)0x3c05)
#define FN_BOOT_STATE (*(volatile unsigned char *)0x3c06)
#define FN_BOOT_PCT   (*(volatile unsigned char *)0x3c07) /* 0-100         */
#define FN_BOOT_ERR   (*(volatile unsigned char *)0x3c08)
#define FN_MAGIC0     (*(volatile unsigned char *)0x3c09) /* 'F'           */
#define FN_MAGIC1     (*(volatile unsigned char *)0x3c0a) /* 'N'           */
#define FN_PROTO      (*(volatile unsigned char *)0x3c0b) /* version, 2    */
#define FN_SLICE_ECHO (*(volatile unsigned char *)0x3c0c) /* published last*/

#define FN_STATUS_LINK 0x01
#define FN_STATUS_BUSY 0x02

/* ---- hotspot pages (console -> cart; reading is writing) ------------ */

#define FN_REGSEL     ((volatile unsigned char *)0x3d00) /* +reg: arm      */
#define FN_REGDATA    ((volatile unsigned char *)0x3e00) /* +val: deliver  */
#define FN_DATA       ((volatile unsigned char *)0x3f00) /* +val: TX byte  */
#define FN_SWAP       (*(volatile unsigned char *)0x3dfe) /* armed only    */
#define FN_BANKSEL    ((volatile unsigned char *)0x3d80) /* +page (v2)     */

/* ---- mailbox registers ---------------------------------------------- */

#define FN_REG_DEVICE   0x00    /* FujiBus device id                      */
#define FN_REG_CMD      0x01    /* FujiBus command id                     */
#define FN_REG_NPARAM   0x02    /* parameters in the TX stream            */
#define FN_REG_DATA_RST 0x05    /* any value: rewind the TX pointer       */
#define FN_REG_RXSLICE  0x06    /* which reply slice FN_RDATA shows       */
#define FN_REG_SEQ      0x10    /* nonzero, != ACKSEQ: launch transaction */
#define FN_REG_BOOTLOCK 0x11    /* 0xB5 arms the ROM swap                 */

#define FN_BOOTLOCK_MAGIC 0xb5

/* ---- devices and limits --------------------------------------------- */

#define FN_DEV_FUJI   0x70      /* the FujiNet itself                     */
#define FN_DEV_NET    0x71      /* network unit N1:                       */

#define FN_TX_MAX     320       /* TX stream: params + payload            */
#define FN_RX_MAX     1024      /* reply: 4 slices of 256                 */

/* ---- transaction error codes (FN_ERRBYTE / fn_commit result) -------- */

#define FN_ERR_OK        0
#define FN_ERR_NOLINK    1
#define FN_ERR_TIMEOUT   2
#define FN_ERR_BADFRAME  3
#define FN_ERR_TOOBIG    4
#define FN_ERR_CLIENT_TIMEOUT 0xff  /* fn_commit gave up waiting         */

#define FN_ACK        0x06
#define FN_NAK        0x15

/* ---- Fuji device (0x70) commands used here -------------------------- */

#define FUJI_GET_ADAPTERCONFIG_EXTENDED 0xc4

/* ---- network device (0x71) commands --------------------------------- */

#define NET_OPEN      0x4f      /* 'O' */
#define NET_CLOSE     0x43      /* 'C' */
#define NET_READ      0x52      /* 'R' */
#define NET_STATUS    0x53      /* 'S' */
#define NET_WRITE     0x57      /* 'W' */

#define NET_MODE_RDWR 0x0c      /* also HTTP GET */
#define NET_TRANS_NONE 0

/* ---- the transport (fujinet.c) --------------------------------------
 * fn_commit and fn_slice return FN_ERR_OK, an FN_ERR_* code, or
 * FN_ERR_CLIENT_TIMEOUT.  A timeout quantum is 65,536 polls of the ACK
 * byte -- about two seconds in the assembly library, a little longer in
 * C.  The sequence number is always derived from the cartridge's own
 * FN_ACKSEQ, never from a local counter: console RESET restarts this
 * program but not the cartridge.
 */

unsigned char fn_check(void);           /* 1 if the 'F','N' magic is there */
void fn_regwr(unsigned char reg, unsigned char val);
void fn_tx_byte(unsigned char v);
void fn_tx_parb(unsigned char v);       /* one-byte parameter  */
void fn_tx_parw(unsigned int v);        /* two-byte parameter  */
void fn_tx_str(const char *s);          /* payload, no NUL     */
void fn_begin(unsigned char device, unsigned char command,
              unsigned char nparam);
unsigned char fn_commit(unsigned char quanta);
unsigned char fn_slice(unsigned char n);

/* flat 0-1023 view over the four reply slices */
void rx_home(void);                     /* call after every transaction */
unsigned char rx_getb(unsigned int off);
unsigned int rx_getw(unsigned int off);
void rx_strn(char *dst, unsigned int off, unsigned char max);

/* N: device round trip, netcat's shape */
unsigned char net_open(const char *devicespec, unsigned char mode,
                       unsigned char translation);
unsigned char net_close(void);
unsigned char net_status(void);         /* fills the three cells below  */
extern unsigned int  net_avail;
extern unsigned char net_connected;
extern unsigned char net_devstatus;
unsigned char net_read(unsigned int len);   /* reply lands in FN_RDATA  */
extern unsigned int  net_rxlen;             /* captured after net_read  */
unsigned char net_write(const unsigned char *buf, unsigned char len);

#endif
