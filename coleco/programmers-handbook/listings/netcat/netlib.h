/* netlib.h -- the N: network device, five commands, on top of fujilib.
 *
 * Where fujilib is the transport (registers, TX stream, the SEQ handshake),
 * this is the network unit N1: (FujiBus device 0x71) that rides on it: open a
 * devicespec, ask how many bytes are waiting, read them, write some back, hang
 * up. Every one of these is one fujilib transaction -- fn_start, parameters,
 * fn_commit -- so read fujilib.h first and this file is nothing new.
 *
 * NETCAT uses only N1:. The eight network units 0x71-0x78 (N1:-N8:) are
 * independent connections; a program that wanted two at once would talk to two
 * device ids, everything else the same.
 */

#ifndef NETLIB_H
#define NETLIB_H

#include <stdbool.h>

/* The network device ids and the five command opcodes. The opcodes are the
 * ASCII letters of their names -- 'O'pen, 'S'tatus, 'R'ead, 'W'rite, 'C'lose --
 * a habit inherited from the Atari SIO handlers. */
#define NET_DEV_N1  0x71
#define NET_OPEN    0x4F        /* 'O' */
#define NET_STATUS  0x53        /* 'S' */
#define NET_READ    0x52        /* 'R' */
#define NET_WRITE   0x57        /* 'W' */
#define NET_CLOSE   0x43        /* 'C' */

/* NET_OPEN parameter 0, fileAccessMode_t (lib/network-protocol/Protocol.h):
 * READ 4, WRITE 8, READWRITE 12. A socket is read/write. */
#define NET_MODE_READ      4
#define NET_MODE_WRITE     8
#define NET_MODE_READWRITE 12

/* NET_OPEN parameter 1, netProtoTranslation_t: 0 none, 1 CR, 2 LF, 3 CR/LF.
 * NETCAT sends 0 and does its own end-of-line handling in the terminal. */
#define NET_TRANS_NONE 0

/* The fixed devicespec buffer the ESP32 expects for NET_OPEN. A short payload
 * is padded up to this; the transaction layer refuses anything shorter. */
#define NET_SPEC_LEN 256

/* NET_READ / NET_WRITE ceiling. The reply window is 1K, but the whole point of
 * a terminal is to show bytes as they arrive, so a modest read keeps the loop
 * responsive; a write has to leave room in the 320-byte TX stream for the
 * length parameter. */
#define NET_READ_MAX  512
#define NET_WRITE_MAX 120

/* NET_STATUS byte 3 (device status): the two a terminal cares about. */
#define NET_DS_SUCCESS 1
#define NET_DS_EOF     136

/* One-time init: bring up the mailbox client. Safe to call more than once. */
bool net_present(void);

/* Open the devicespec (e.g. "N:TELNET://bbs.example.com/") read/write. Returns
 * true on ACK. */
bool net_open(const char *spec);

/* Hang up. Best-effort -- a terminal calls it on the way out and does not
 * care whether the far side was still there. */
void net_close(void);

/* Poll the connection. Fills *avail (bytes waiting), *conn (socket up), and
 * *devstatus (NET_DS_*). Returns false if the transaction itself failed. */
bool net_status(unsigned int *avail, unsigned char *conn,
                unsigned char *devstatus);

/* Read up to `want` bytes into the reply window. Returns how many landed (from
 * the transaction's own length bytes); the data is at FN_REPLY, valid until the
 * next transaction of any kind. */
unsigned int net_read(unsigned int want);

/* Write `len` bytes. Returns true on ACK. `len` is capped at NET_WRITE_MAX. */
bool net_write(const unsigned char *buf, unsigned int len);

#endif /* NETLIB_H */
