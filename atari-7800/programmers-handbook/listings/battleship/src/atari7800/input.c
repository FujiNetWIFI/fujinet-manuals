#ifdef BUILD_ATARI7800

/**
 * @brief Atari 7800 input routines
 * @author Thomas Cherryhomes
 * @license gpl v.3
 */

#include <joystick.h>
#include "vars.h"
#include "pad.h"
#include "../platform-specific/input.h"
#include "../platform-specific/graphics.h"

/*
  The left joystick and the console's switches, read straight from RIOT and
  TIA's input ports; the TIA is only ever read ($00-$1F is never written).
  A ProLine stick is read in two-button mode; a 2600 stick's one button
  arrives on INPT4, and RESET stands in for button 2, as in CONFIG.

  Only the stick travels in readJoystick(). The buttons are synthesized as
  key codes behind kbhit()/cgetc(), as on the NES (src/nes/input.c), with
  SELECT as the shift for the extra letter shortcuts (vars.h lists them):

    1            RETURN    2 / RESET    'r'      PAUSE        ESCAPE
    SELECT+1     'h'       SELECT+2     's'      SELECT+PAUSE 'q'
    SELECT alone 'n', reported when it is let go without having shifted
    anything.
*/

#define REG(a)  (*(volatile unsigned char *)(a))
#define INPT0   REG(0x08)   /* button 2, two-button mode: bit 7 set */
#define INPT1   REG(0x09)   /* button 1, two-button mode: bit 7 set */
#define INPT4   REG(0x0C)   /* a 2600 stick's button: bit 7 clear */
#define SWCHA   REG(0x280)  /* bits 7-4: right, left, down, up; low */
#define SWCHB   REG(0x282)  /* bit 0 RESET, 1 SELECT, 3 PAUSE; low */
#define CTLSWB  REG(0x283)

#define PB2     0x04        /* left port's two-button mode, driven low */

#define DIRS (JOY_UP_MASK | JOY_DOWN_MASK | JOY_LEFT_MASK | JOY_RIGHT_MASK)

static unsigned char lastButtons;
static unsigned char shifted;
static unsigned char pendingKey;

void initInput(void)
{
    CTLSWB = PB2;
    SWCHB = 0;
}

unsigned char readPad(void)
{
    unsigned char b = (unsigned char)~SWCHA & DIRS;
    unsigned char sw = (unsigned char)~SWCHB;

    if ((INPT1 & 0x80) || !(INPT4 & 0x80))
        b |= PAD_FIRE;
    if ((INPT0 & 0x80) || (sw & 0x01))
        b |= PAD_BACK;
    if (sw & 0x02)
        b |= PAD_SELECT;
    if (sw & 0x08)
        b |= PAD_PAUSE;
    return b;
}

unsigned char readJoystick()
{
    return readPad() & DIRS;
}

static unsigned char poll(void)
{
    unsigned char buttons = readPad() & ~DIRS;
    unsigned char pressed = buttons & ~lastButtons;
    unsigned char released = lastButtons & ~buttons;
    unsigned char sel = buttons & PAD_SELECT;

    lastButtons = buttons;

    if (pressed & PAD_SELECT)
        shifted = 0;

    if (pressed & PAD_FIRE)
    {
        shifted = 1;
        return sel ? 'h' : KEY_RETURN;
    }
    if (pressed & PAD_BACK)
    {
        shifted = 1;
        return sel ? 's' : 'r';
    }
    if (pressed & PAD_PAUSE)
    {
        shifted = 1;
        return sel ? 'q' : KEY_ESCAPE;
    }
    if ((released & PAD_SELECT) && !shifted)
        return 'n';

    return 0;
}

unsigned char kbhit(void)
{
    if (!pendingKey)
        pendingKey = poll();

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

#endif /* BUILD_ATARI7800 */
