#ifdef BUILD_ATARI7800

/**
 * @brief   Atari 7800 joystick and console switches - shared by input.c,
 *          osk.c and graphics.c
 * @license gpl v. 3, see LICENSE for details
 */

#ifndef PAD_H
#define PAD_H

// The stick in cc65's JOY_*_MASK bits (0xF0), the buttons below them.
#define PAD_FIRE   0x01 /* button 1 */
#define PAD_BACK   0x02 /* button 2, or RESET */
#define PAD_SELECT 0x04
#define PAD_PAUSE  0x08

void initInput(void);
unsigned char readPad(void);

#endif /* PAD_H */

#endif /* BUILD_ATARI7800 */
