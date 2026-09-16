#ifdef BUILD_COLECO

/**
 * @brief ColecoVision input routines
 * @author Thomas Cherryhomes
 * @license gpl v.3
 */

#include <games.h>
#include "vars.h"
#include "joystick.h"
#include "../platform-specific/input.h"
#include "../platform-specific/graphics.h"

/*
  A ColecoVision controller is a four-way stick, two fire buttons and a
  twelve-key keypad. z88dk's joystick() is coleco_joypad(): device 3 returns
  the player-1 stick and fire buttons in the low byte and the keypad as an
  ASCII character in the high byte ('0'-'9', '*', '#').

  Only the stick travels in readJoystick(). Both fire buttons and the keypad
  are synthesized as key codes behind kbhit()/cgetc() - the surface the
  keyboard platforms present - with one edge detector so a held key reports
  exactly once. Fire-1 is KEY_RETURN, which the shared readCommonInput()
  already maps to input.trigger, and which also satisfies the screens that
  block on cgetc() ("press any key"); fire-2 is KEY_ESCAPE (the in-game menu).
  clearCommonInput()'s drain loop terminates because a consumed edge does not
  re-arm until the key is released.
*/

#define PAD_KEYPAD 3 /* joystick() device: stick + keypad, player 1 */

/* The fire buttons, as values the keypad never returns. */
#define EV_FIRE1 0x01
#define EV_FIRE2 0x02

static unsigned char lastEvent;
static unsigned char pendingKey;

unsigned char readJoystick()
{
    return (unsigned char)joystick(PAD_KEYPAD) & 0x0F;
}

static unsigned char mapEvent(unsigned char event)
{
    switch (event)
    {
    case EV_FIRE1:
        return KEY_RETURN;
    case EV_FIRE2:
        return KEY_ESCAPE;

    /* The keypad stands in for the letter shortcuts the other ports type.
       vars.h's *_TEXT labels tell the player these; keep the two in step. */
    case '1':
        return 'r'; /* refresh, and rotate during placement */
    case '2':
        return 'h'; /* how to play */
    case '3':
        return 's'; /* sound      */
    case '4':
        return 'n'; /* name       */
    case '5':
        return 'q'; /* quit       */

    case '*':
        return KEY_ESCAPE;
    case '#':
        return KEY_RETURN;
    }

    return 0;
}

unsigned char kbhit(void)
{
    unsigned int pad;
    unsigned char event;

    if (pendingKey)
        return 1;

    pad = joystick(PAD_KEYPAD);
    /* The keypad wins over the buttons: it is the deliberate press. */
    event = (unsigned char)(pad >> 8);
    if (!event)
    {
        if (pad & JOY_BTN_2_MASK)
            event = EV_FIRE2;
        else if (pad & JOY_BTN_1_MASK)
            event = EV_FIRE1;
    }

    if (event == lastEvent)
        return 0;
    lastEvent = event;
    if (!event)
        return 0;

    pendingKey = mapEvent(event);
    return pendingKey != 0;
}

unsigned char cgetc(void)
{
    unsigned char k;

    while (!kbhit())
        waitvsync();

    k = pendingKey;
    pendingKey = 0;
    return k;
}

#endif /* BUILD_COLECO */
