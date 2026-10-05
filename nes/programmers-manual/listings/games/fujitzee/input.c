#ifdef BUILD_NES

/**
 * @brief NES input routines
 * @author Thomas Cherryhomes
 * @license gpl v.3
 */

#include <joystick.h>
#include "vars.h"
#include "../platform-specific/input.h"
#include "../platform-specific/graphics.h"
#include "../misc.h"

/*
  An NES controller is a d-pad and four buttons, read through cc65's joystick
  driver (installed by initGraphics()).

  Only the d-pad travels in readJoystick(). The buttons are synthesized as key
  codes behind kbhit()/cgetc() -- the surface the keyboard platforms present
  -- so a held button reports exactly once. A is KEY_RETURN, which the shared
  readCommonInput() maps to input.trigger and which also satisfies the screens
  that block on cgetc() ("press any key").

  SELECT is a shift key, because the shared screens want more letter
  shortcuts than there are buttons (vars.h's *_TEXT labels say which):

    A            RETURN    B            'h' help     START        ESCAPE
    SELECT+B     's'       SELECT+START 'q' quit
    SELECT alone 'r' refresh, reported when it is let go without having
                 shifted anything -- the only way to tell it from a chord.

  A, B and START report on press. While the on-screen keyboard is open
  (osk.c) it owns the pad, and kbhit() reports what it types instead.
*/

#define DIRS (JOY_UP_MASK | JOY_DOWN_MASK | JOY_LEFT_MASK | JOY_RIGHT_MASK)

extern unsigned char oskActive;   /* osk.c */
unsigned char oskPoll(void);      /* osk.c */

static unsigned char lastButtons;
static unsigned char shifted;
static unsigned char pendingKey;

unsigned char readJoystick()
{
    return oskActive ? 0 : joy_read(JOY_1) & DIRS;
}

static unsigned char poll(void)
{
    unsigned char buttons = joy_read(JOY_1) & ~DIRS;
    unsigned char pressed = buttons & ~lastButtons;
    unsigned char released = lastButtons & ~buttons;
    unsigned char sel = buttons & JOY_SELECT_MASK;

    lastButtons = buttons;

    if (pressed & JOY_SELECT_MASK)
        shifted = 0;

    if (pressed & JOY_BTN_A_MASK)
    {
        shifted = 1;
        return KEY_RETURN;
    }
    if (pressed & JOY_BTN_B_MASK)
    {
        shifted = 1;
        return sel ? 's' : 'h';
    }
    if (pressed & JOY_START_MASK)
    {
        shifted = 1;
        return sel ? 'q' : KEY_ESCAPE;
    }
    if ((released & JOY_SELECT_MASK) && !shifted)
        return 'r';

    return 0;
}

unsigned char kbhit(void)
{
    if (!pendingKey)
    {
        if (oskActive)
        {
            pendingKey = oskPoll();
            // Whatever the grid used up is not a press once it closes.
            lastButtons = joy_read(JOY_1) & ~DIRS;
            shifted = 1;
        }
        else
            pendingKey = poll();
    }

    return pendingKey != 0;
}

char cgetc(void)
{
    unsigned char k;

    while (!kbhit())
        waitvsync();

    k = pendingKey;
    pendingKey = 0;
    return k;
}

#endif /* BUILD_NES */
