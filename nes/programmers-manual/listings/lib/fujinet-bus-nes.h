#ifndef FUJINET_BUS_NES_H
#define FUJINET_BUS_NES_H

/*
  The NES's half of the FujiNet mailbox.

  These equates mirror fujinet-firmware/pico/nes/firmware/include/fuji_mailbox.h
  by hand, which is the upstream source of truth; every address here is a
  CONSOLE address, i.e. the arena offset plus $5000. Keep the two in step.

  The NES cartridge edge carries a real R/W line, so unlike the ColecoVision
  this is the Channel F protocol family: console -> cart is an ordinary WRITE
  to a hotspot page, cart -> console is memory the cartridge paints. Reads of
  the hotspot pages are inert, so the vblank NMI can land anywhere in a
  transaction without disturbing it, as long as the handler never WRITES to
  $5500-$57FF.

  THE ONE RULE for code that touches $5500-$57FF: plain or indexed stores
  only (STA/STX/STY), never a read-modify-write instruction. The 6502 writes
  the old value back first during INC/DEC/ASL/LSR/ROL/ROR, and that lands as a
  spurious event. In C that means never `++`, `|=` or the like on a mailbox
  address; the helpers below only ever assign. The cartridge's checkrom tool
  rejects the opcodes in a built image.

  There is no framing, no checksum and no ACK/NAK exchange on this side. SLIP
  and the end-around-carry checksum live between the RP2354 and the ESP32.
*/

#include <fujinet-bus.h>

/* ---- cart -> console: painted memory ---- */

/* The whole 1K reply in one piece, read in place out of cartridge memory. */
#define FN_REPLY     ((volatile uint8_t *) 0x5000)
#define FN_REPLY_MAX 1024

#define FN_ACKSEQ    (*(volatile uint8_t *) 0x5400)
#define FN_STATUS    (*(volatile uint8_t *) 0x5401)
#define FN_ERRCODE   (*(volatile uint8_t *) 0x5402)
#define FN_REPLYCMD  (*(volatile uint8_t *) 0x5403)
#define FN_RXLEN_LO  (*(volatile uint8_t *) 0x5404)
#define FN_RXLEN_HI  (*(volatile uint8_t *) 0x5405)
#define FN_BOOTSTAT  (*(volatile uint8_t *) 0x5406)
#define FN_BOOTPCT   (*(volatile uint8_t *) 0x5407)
#define FN_BOOTERR   (*(volatile uint8_t *) 0x5408)
#define FN_MAGIC0    (*(volatile uint8_t *) 0x5409)
#define FN_MAGIC1    (*(volatile uint8_t *) 0x540A)
#define FN_PROTOVER  (*(volatile uint8_t *) 0x540B)
#define FN_LINK      (*(volatile uint8_t *) 0x5415)
#define FN_BOOTGOT   ((volatile uint8_t *) 0x5416)   /* 24-bit LE */
#define FN_BOOTTOT   ((volatile uint8_t *) 0x5419)   /* 24-bit LE */

#define FN_STATUS_LINK 0x01
#define FN_STATUS_BUSY 0x02

#define FN_PROTO_VER   1

/* ---- console -> cart: write-only hotspot pages ---- */
#define FN_REGSEL    ((volatile uint8_t *) 0x5500)   /* [reg] = value */
#define FN_TXPAGE    (*(volatile uint8_t *) 0x5700)  /* = byte: append */
#define FN_LOADER    0x5800                          /* the swap stub */

/* Register file. */
#define FNR_DEVICE   0x00
#define FNR_CMD      0x01
#define FNR_NPARAM   0x02
#define FNR_DATA_RST 0x05
#define FNR_RXSLICE  0x06
#define FNR_SEQ      0x10
#define FNR_BOOTLOCK 0x11

#define FN_BOOTLOCK_MAGIC 0xB5

/* The TX stream is NPARAM x { size byte (1|2|4), then that many value bytes,
   little-endian }, followed by the raw payload. */
#define FN_TX_MAX    320

/* fn_commit() results: the cart's own error codes, plus our own timeout. */
#define FN_OK        0
#define FN_ENOLINK   1
#define FN_ETIMEOUT  2
#define FN_EBADFRAME 3
#define FN_ETOOBIG   4
#define FN_EWAIT     0xFF  /* the cart never answered at all */

/* One register write is ONE store; one TX byte is one store. These are
   functions rather than macros so that every mailbox store in a program is
   a plain `sta`, whatever the optimiser might do to an inline expression. */
extern void __fastcall__ fn_tx(uint8_t b);
extern void fn_regwr(uint8_t reg, uint8_t val);
extern uint8_t fn_commit(void);

/* Length of the reply left in the window by the last fuji_bus_call(). */
extern uint16_t fuji_bus_call_rlen;

#endif /* FUJINET_BUS_NES_H */
