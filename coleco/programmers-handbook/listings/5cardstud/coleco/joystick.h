#ifdef BUILD_COLECO

/**
 * @brief ColecoVision joystick definitions
 * @author Thomas Cherryhomes
 * @license gpl v.3
 */

#ifndef _JOYSTICK_H
#define _JOYSTICK_H

/*****************************************************************************/
/*                              Joystick Definitions                         */
/*****************************************************************************/

/*
  These are z88dk's coleco_joypad() bit layout, not cc65's: the reader is what
  defines the masks here rather than the other way round, the same way
  src/msx/joystick.h follows joyread.asm. Bit 5 (the second fire button) is
  masked off by readJoystick() and handled as a key instead -- see input.c.
*/

/* Argument for the joy_read function */
#define JOY_1                   0
#define JOY_2                   1

/* Masks for joy_read */
#define JOY_RIGHT_MASK          0x01
#define JOY_LEFT_MASK           0x02
#define JOY_DOWN_MASK           0x04
#define JOY_UP_MASK             0x08
#define JOY_BTN_1_MASK          0x10
#define JOY_BTN_2_MASK          0x20

/* Macros that evaluate the return code of joy_read */
#define JOY_UP(v)               ((v) & JOY_UP_MASK)
#define JOY_DOWN(v)             ((v) & JOY_DOWN_MASK)
#define JOY_LEFT(v)             ((v) & JOY_LEFT_MASK)
#define JOY_RIGHT(v)            ((v) & JOY_RIGHT_MASK)
#define JOY_BTN_1(v)            ((v) & JOY_BTN_1_MASK)
#define JOY_BTN_2(v)            ((v) & JOY_BTN_2_MASK)

/* End of joystick.h */
#endif

#endif /* BUILD_COLECO */
