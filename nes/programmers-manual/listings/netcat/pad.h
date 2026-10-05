/* pad.h -- the joypad, read by hand. */

#ifndef PAD_H
#define PAD_H

#include <stdint.h>

#define PAD_A      0x80
#define PAD_B      0x40
#define PAD_SELECT 0x20
#define PAD_START  0x10
#define PAD_UP     0x08
#define PAD_DOWN   0x04
#define PAD_LEFT   0x02
#define PAD_RIGHT  0x01

/* Call once a frame. Returns the buttons that went down this frame, with the
   D-pad auto-repeating while it is held. */
extern uint8_t pad_poll(void);

/* Wait for the next vblank by watching the NMI's frame count. (cc65's own
   waitvsync() polls PPUSTATUS, and a read in the cycle the vblank flag rises
   suppresses that frame's NMI -- and with it the PPU queue's flush.) */
extern void frame(void);

#endif
