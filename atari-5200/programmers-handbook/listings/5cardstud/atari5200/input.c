#ifdef BUILD_ATARI5200

/**
 * @brief Atari 5200 input routines
 * @author Thomas Cherryhomes
 * @license gpl v.3
 */

#include <atari5200.h>
#include <fujinet-atari5200.h>
#include "../platform-specific/input.h"

/*
  Controller 1. The stick comes from the VBI's POT shadows, read through a
  dead zone; the keypad from the lib's keypad IRQ, which latches one press in
  fuji_a5200_key until it is read here.

  Every button and key is reported as a KEY rather than as a stick bit.
  readCommonInput() returns early whenever readJoystick()'s value changes and
  only reaches getPlatformKey() when it has not, so a button that appeared in
  both places would be seen twice. The keypad stands in for the letter
  shortcuts the other ports type, as on the ColecoVision (src/coleco/input.c);
  src/screens.c labels them.

    top fire, #, START       RETURN  (select / join / confirm)
    lower fire, *, RESET     ESCAPE  (back / the in-game menu)
    1 refresh   2 how to play (or PAUSE)   3 table colour   4 name   5 quit
*/

#define REG(a)  (*(volatile unsigned char *)(a))
#define ATRACT  REG(0x04)
#define PADDL0  REG(0x11)       /* stick X, 0-228, 114 at rest */
#define PADDL1  REG(0x12)       /* stick Y */
#define TRIG0   REG(0xC010)     /* top fire: 0 while held */
#define SKSTAT  REG(0xE80F)     /* bit 3 clear: the lower fire button */

/* Past these the stick is pushed; between them it is at rest. */
#define STICK_LO 0x40
#define STICK_HI 0xA4

#define DIRS    (JOY_UP_MASK | JOY_DOWN_MASK | JOY_LEFT_MASK | JOY_RIGHT_MASK)
#define BUTTONS (JOY_BTN_1_MASK | PAD_BTN_2)

static unsigned char lastButtons, lastPad;

unsigned char readPad(void)
{
  unsigned char pad = 0;
  unsigned char x = PADDL0, y = PADDL1;

  if (y < STICK_LO)
    pad |= JOY_UP_MASK;
  else if (y > STICK_HI)
    pad |= JOY_DOWN_MASK;
  if (x < STICK_LO)
    pad |= JOY_LEFT_MASK;
  else if (x > STICK_HI)
    pad |= JOY_RIGHT_MASK;
  if (TRIG0 == 0)
    pad |= JOY_BTN_1_MASK;
  if (!(SKSTAT & 0x08))
    pad |= PAD_BTN_2;

  // Any use of the controller holds off the VBI's attract-mode colours.
  if (pad != lastPad)
  {
    lastPad = pad;
    ATRACT = 0;
  }
  return pad;
}

unsigned char readJoystick()
{
  return readPad() & DIRS;
}

void initPlatformKeyboardInput(void)
{
  lastButtons = readPad() & BUTTONS;
  fuji_a5200_key = 0;
}

int getPlatformKey(void)
{
  unsigned char buttons = readPad() & BUTTONS;
  unsigned char pressed = buttons & ~lastButtons;
  unsigned char k = fuji_a5200_key;

  lastButtons = buttons;

  if (pressed & JOY_BTN_1_MASK)
    return KEY_RETURN;
  if (pressed & PAD_BTN_2)
    return KEY_ESCAPE;

  if (!k)
    return 0;
  fuji_a5200_key = 0;

  switch (k) {
    case FUJI_A5200_KEY_HASH:
    case FUJI_A5200_KEY_START:  return KEY_RETURN;
    case FUJI_A5200_KEY_STAR:
    case FUJI_A5200_KEY_RESET:  return KEY_ESCAPE;
    case FUJI_A5200_KEY_PAUSE:  return 'h';
    case FUJI_A5200_KEY_DIGIT(1): return 'r';   /* refresh     */
    case FUJI_A5200_KEY_DIGIT(2): return 'h';   /* how to play */
    case FUJI_A5200_KEY_DIGIT(3): return 'c';   /* colour      */
    case FUJI_A5200_KEY_DIGIT(4): return 'n';   /* name        */
    case FUJI_A5200_KEY_DIGIT(5): return 'q';   /* quit        */
  }
  return 0;
}

#endif /* BUILD_ATARI5200 */
