#ifdef BUILD_NES

/**
 * @brief NES input routines
 * @author Thomas Cherryhomes
 * @license gpl v.3
 */

#include <joystick.h>
#include "../platform-specific/input.h"

/*
  An NES controller is a d-pad and four buttons, read through cc65's joystick
  driver (installed by initGraphics() -- see graphics.c, which needs it for
  the same reason it needs the PPU: both are platform start-up).

  Every button is reported as a KEY rather than as a stick bit. readCommonInput()
  returns early whenever readJoystick()'s value changes and only reaches
  getPlatformKey() when it has not, so a button that appeared in both places
  would be seen twice: once as the joystick edge, and again on the next pass as
  a key, because the button is still held. Keeping every button in
  getPlatformKey() puts all of them behind one edge detector.

    A           RETURN  (select / join / confirm)
    B           ESCAPE  (back / the in-game menu)
    START       'h'     how to play
    SELECT      'n'     change name
    SELECT+START 'q'    quit the table

  START and SELECT are reported on RELEASE so that the chord can be told from
  either button alone: whatever set of the two was down when the last of them
  came up is the key. A and B report on press.
*/

#define DIRS (JOY_UP_MASK | JOY_DOWN_MASK | JOY_LEFT_MASK | JOY_RIGHT_MASK)
#define MODS (JOY_SELECT_MASK | JOY_START_MASK)

static unsigned char lastButtons;
static unsigned char modsSeen;

unsigned char readJoystick()
{
  return joy_read(JOY_1) & DIRS;
}

void initPlatformKeyboardInput(void)
{
  lastButtons = 0;
  modsSeen = 0;
}

int getPlatformKey(void)
{
  unsigned char buttons = joy_read(JOY_1) & ~DIRS;
  unsigned char pressed = buttons & ~lastButtons;
  unsigned char released = lastButtons & ~buttons;

  lastButtons = buttons;
  modsSeen |= buttons & MODS;

  if (pressed & JOY_BTN_A_MASK)
    return KEY_RETURN;
  if (pressed & JOY_BTN_B_MASK)
    return KEY_ESCAPE;

  if ((released & MODS) && !(buttons & MODS)) {
    unsigned char chord = modsSeen;
    modsSeen = 0;
    if (chord == MODS)
      return 'q';
    if (chord == JOY_START_MASK)
      return 'h';
    if (chord == JOY_SELECT_MASK)
      return 'n';
  }
  return 0;
}

#endif /* BUILD_NES */
