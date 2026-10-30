#ifdef BUILD_ATARI5200

/**
 * @brief   Atari 5200 controller - shared by input.c and osk.c
 * @license gpl v. 3, see LICENSE for details
 */

#ifndef PAD_H
#define PAD_H

// The stick in cc65's JOY_*_MASK bits (0x0F), the fire buttons above them.
#define PAD_FIRE 0x10 /* top fire */
#define PAD_BACK 0x20 /* lower fire */

#define PAD_DIRS (JOY_UP_MASK | JOY_DOWN_MASK | JOY_LEFT_MASK | JOY_RIGHT_MASK)

unsigned char readPad(void);

/* The keypad key pressed since the last call, as FUJI_A5200_KEY_*; 0 none. */
unsigned char readKeypad(void);

#endif /* PAD_H */

#endif /* BUILD_ATARI5200 */
