#ifdef BUILD_COLECO

/**
 * @brief ColecoVision joystick definitions
 * @author Thomas Cherryhomes
 * @license gpl v.3
 */

#ifndef _JOYSTICK_H
#define _JOYSTICK_H

/*
  These are z88dk's coleco_joypad() bit layout, not cc65's: the reader is what
  defines the masks here rather than the other way round. Bit 5 (the second
  fire button) is masked off by readJoystick() and handled as a key instead --
  see input.c.
*/

#define JOY_RIGHT_MASK          0x01
#define JOY_LEFT_MASK           0x02
#define JOY_DOWN_MASK           0x04
#define JOY_UP_MASK             0x08
#define JOY_BTN_1_MASK          0x10
#define JOY_BTN_2_MASK          0x20

#endif /* _JOYSTICK_H */

#endif /* BUILD_COLECO */
