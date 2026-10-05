#ifndef FUJINET_NES_H
#define FUJINET_NES_H

/*
  NES-only facilities that the cross-platform API has no place for.

  The vblank NMI is harmless to a transaction in flight as long as the handler
  never WRITES to $5500-$57FF (reads anywhere are inert): a register write is
  one store and the TX stream is append-only, so an interrupted transaction
  simply resumes. cc65's own conio handler only touches the PPU and RAM.

  Building through makefiles/platforms/nes.mk links against the FujiNet
  linker config, which keeps $FFF0-$FFF9 clear for the "FUJI" claim that
  nes-romstamp.py writes: without it the cartridge shuts the mailbox down for
  the session the moment the image boots.
*/

#include <fujinet-int.h>

/* fuji_nes_boot_state() values. */
#define FUJI_NES_BOOT_IDLE   0
#define FUJI_NES_BOOT_XFER   1
#define FUJI_NES_BOOT_READY  2
#define FUJI_NES_BOOT_FAILED 0x80

/*
  Is a FujiNet cartridge actually underneath us, and does it speak a protocol
  version we understand? On a plain game cartridge these addresses are open
  bus.
*/
extern bool fuji_nes_present(void);

/*
  MOUNT_IMAGE does not reply until the FujiNet has pushed the whole image to
  the cartridge, so fuji_mount_disk_image() blocks for the entire transfer
  (and fn_commit() may give up before a slow one finishes). A client that
  wants to show progress starts MOUNT_IMAGE itself, sets FNR_SEQ, and polls
  these while FN_ACKSEQ has not yet echoed it. Then, as for a plain mount,
  fuji_nes_boot_state() should read READY (or FAILED, in which case
  fuji_nes_boot_error() says why).

  fuji_nes_boot_percent() runs 0-100. fuji_nes_boot_got() and
  fuji_nes_boot_total() are the image's byte counts; total is 0 until the
  image stream opens.
*/
extern uint8_t fuji_nes_boot_state(void);
extern uint8_t fuji_nes_boot_percent(void);
extern uint8_t fuji_nes_boot_error(void);
extern uint32_t fuji_nes_boot_got(void);
extern uint32_t fuji_nes_boot_total(void);

/*
  Boot the image that was just pushed: arm the load and jump into the
  cartridge's loader ROM, which copies it into the SRAMs and cold-starts it.
  Does not return. Only meaningful once fuji_nes_boot_state() reads READY.
*/
extern void fuji_nes_boot(void);

/*
  The Famicom expansion-port keyboards: Nintendo's Family BASIC Keyboard and
  the Subor keyboard. Call fuji_nes_kbd_detect() once (it says which one, if
  any, answers); then fuji_nes_kbd_getc() once a frame returns the character
  of a key that has just gone down, 0 if none. Letters come lower case, upper
  case with Shift (or Caps Lock, on the Subor). The keys below come as these
  codes; function keys and the modifiers return nothing.

  fuji_nes_kbd_scan() is the raw matrix for a program that wants it: rows[r *
  2 + c] holds row r's half c, bit b set while key b is down (9 rows on the
  Family BASIC keyboard, 13 on the Subor; the rest are 0).
*/
#define FUJI_NES_KBD_NONE         0
#define FUJI_NES_KBD_FAMILY_BASIC 1
#define FUJI_NES_KBD_SUBOR        2

#define FUJI_NES_KEY_BS    0x08
#define FUJI_NES_KEY_TAB   0x09
#define FUJI_NES_KEY_ENTER 0x0D
#define FUJI_NES_KEY_ESC   0x1B
#define FUJI_NES_KEY_UP    ((char) 0x80)
#define FUJI_NES_KEY_DOWN  ((char) 0x81)
#define FUJI_NES_KEY_LEFT  ((char) 0x82)
#define FUJI_NES_KEY_RIGHT ((char) 0x83)
#define FUJI_NES_KEY_HOME  ((char) 0x84)

extern uint8_t fuji_nes_kbd_detect(void);
extern uint8_t fuji_nes_kbd_type(void);
extern char fuji_nes_kbd_getc(void);
extern void fuji_nes_kbd_scan(uint8_t rows[26]);

#endif /* FUJINET_NES_H */
