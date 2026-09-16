#ifdef BUILD_COLECO

/**
 * @brief ColecoVision input routines
 * @author Thomas Cherryhomes
 * @license gpl v.3
 */

#include <games.h>
#include "joystick.h"
#include "../platform-specific/input.h"

/*
  A ColecoVision controller is a four-way stick, two fire buttons and a
  twelve-key keypad. z88dk's joystick() is coleco_joypad(): device 1 returns
  the player-1 stick in the low byte, device 3 returns the same stick plus the
  keypad as an ASCII character in the high byte ('0'-'9', '*', '#', and 'C'/'D'
  for the two purple buttons).

  Both buttons are deliberately reported as KEYS rather than as stick bits.
  readCommonInput() returns early whenever readJoystick()'s value changes and
  only reaches getPlatformKey() when it has not, so a button that appeared in
  both places would be seen twice: once as the joystick edge, and again on the
  next pass as a key, because the button is still held. Keeping every button in
  getPlatformKey() puts all of them behind one edge detector.
*/

#define PAD_KEYPAD  3       /* joystick() device: stick + keypad, player 1 */
#define PAD_DIRS    0x0F    /* the four direction bits; see joystick.h */

/* Synthetic "what is pressed" byte, so one comparison covers the keypad and
   both buttons. Real keypad characters are all >= '#', so these cannot clash. */
#define EV_NONE   0x00
#define EV_FIRE1  0x01
#define EV_FIRE2  0x02

static unsigned char lastEvent;

unsigned char readJoystick()
{
  return (unsigned char) joystick(PAD_KEYPAD) & PAD_DIRS;
}

void initPlatformKeyboardInput(void)
{
  lastEvent = EV_NONE;
}

int getPlatformKey(void)
{
  unsigned int pad;
  unsigned char event;

  pad = joystick(PAD_KEYPAD);

  /* The keypad wins over the buttons: it is the deliberate press. */
  event = (unsigned char) (pad >> 8);
  if (!event) {
    if (pad & JOY_BTN_2_MASK)
      event = EV_FIRE2;
    else if (pad & JOY_BTN_1_MASK)
      event = EV_FIRE1;
  }

  if (event == lastEvent)
    return 0;
  lastEvent = event;

  switch (event) {
    case EV_NONE:  return 0;
    case EV_FIRE1: return KEY_RETURN;
    case EV_FIRE2: return KEY_ESCAPE;

    /* The keypad stands in for the letter shortcuts the other ports type.
       src/screens.c labels these; keep the two in step. */
    case '1': return 'r';   /* refresh    */
    case '2': return 'h';   /* how to play */
    case '3': return 'c';   /* colour     */
    case '4': return 'n';   /* name       */
    case '5': return 'q';   /* quit       */

    case '*': return KEY_ESCAPE;
    case '#': return KEY_RETURN;
  }

  return 0;
}

#endif /* BUILD_COLECO */
