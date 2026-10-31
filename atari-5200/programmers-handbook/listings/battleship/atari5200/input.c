#ifdef BUILD_ATARI5200

/**
 * @brief Atari 5200 input routines
 * @author Thomas Cherryhomes
 * @license gpl v.3
 */

#include <joystick.h>
#include <fujinet-atari5200.h>
#include "vars.h"
#include "pad.h"
#include "../platform-specific/input.h"
#include "../platform-specific/graphics.h"

/*
  Controller 1: the analog stick from the crt0 VBI's POT shadows, the top
  fire on TRIG0, the lower fire on SKSTAT, and the keypad from the lib's
  keypad IRQ (fuji_a5200_key, one event per press).

  Only the stick travels in readJoystick(). The buttons and the keypad are
  synthesized as key codes behind kbhit()/cgetc(), as on the 7800; vars.h
  lists the mapping.
*/

#define REG(a)  (*(volatile unsigned char *)(a))
#define PADDL0  REG(0x11)   /* stick X, 0-228, 114 at rest */
#define PADDL1  REG(0x12)   /* stick Y */
#define TRIG0   REG(0xC010) /* top fire: 0 while held */
#define SKSTAT  REG(0xE80F) /* bit 3 clear: the lower fire */
#define ATRACT  REG(0x04)   /* the crt0 clears it for the keypad only */

/* Past these the stick is pushed; between them it is at rest. */
#define STICK_LO 0x40
#define STICK_HI 0xA4

static unsigned char lastButtons;
static unsigned char pendingKey;

unsigned char readPad(void)
{
    unsigned char b = 0, x = PADDL0, y = PADDL1;

    if (y < STICK_LO)
        b |= JOY_UP_MASK;
    else if (y > STICK_HI)
        b |= JOY_DOWN_MASK;
    if (x < STICK_LO)
        b |= JOY_LEFT_MASK;
    else if (x > STICK_HI)
        b |= JOY_RIGHT_MASK;

    if (TRIG0 == 0)
        b |= PAD_FIRE;
    if (!(SKSTAT & 0x08))
        b |= PAD_BACK;
    if (b)
        ATRACT = 0;
    return b;
}

unsigned char readKeypad(void)
{
    unsigned char k = fuji_a5200_key;

    if (k)
        fuji_a5200_key = 0;
    return k;
}

unsigned char readJoystick()
{
    return readPad() & PAD_DIRS;
}

static unsigned char keyFor(unsigned char k)
{
    switch (k)
    {
    case FUJI_A5200_KEY_HASH:
    case FUJI_A5200_KEY_START:
        return KEY_RETURN;
    case FUJI_A5200_KEY_DIGIT(1):
        return 'r';
    case FUJI_A5200_KEY_STAR:
    case FUJI_A5200_KEY_PAUSE:
        return KEY_ESCAPE;
    case FUJI_A5200_KEY_DIGIT(2):
        return 'h';
    case FUJI_A5200_KEY_DIGIT(3):
        return 's';
    case FUJI_A5200_KEY_DIGIT(4):
        return 'n';
    case FUJI_A5200_KEY_DIGIT(5):
        return 'q';
    }
    return 0;
}

static unsigned char poll(void)
{
    unsigned char buttons = readPad() & ~PAD_DIRS;
    unsigned char pressed = buttons & ~lastButtons;
    unsigned char k = keyFor(readKeypad());

    lastButtons = buttons;

    // The keypad wins: it is the deliberate press
    if (k)
        return k;
    if (pressed & PAD_FIRE)
        return KEY_RETURN;
    if (pressed & PAD_BACK)
        return 'r';
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

#endif /* BUILD_ATARI5200 */
