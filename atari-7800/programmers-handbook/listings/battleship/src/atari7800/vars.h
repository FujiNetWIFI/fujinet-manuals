#ifdef BUILD_ATARI7800

#ifndef KEYMAP_H
#define KEYMAP_H

#include <joystick.h>

// Screen dimensions for platform: the MARIA engine's 32x24 (src/atari7800/maria.h),
// the ColecoVision and NES layout.
#define WIDTH 32
#define HEIGHT 24

#define GAMEOVER_PROMPT_Y HEIGHT - 2

// Icons - msdos tile sheet indices; graphics.c maps them through sheetTile[]
#define ICON_TEXT_CURSOR 0x3A
#define ICON_PLAYER 0x2A
#define ICON_MARK 0x2B
#define ICON_MARK_ALT 0x19
#define ICON_ACTIVE_PLAYER 0x05

/* readJoystick() (src/atari7800/input.c) returns the stick only, in cc65's
   joystick bits. The buttons never appear in the joystick byte: input.c
   reports them as key codes behind kbhit()/cgetc(), as on the NES. */
#undef JOY_BTN_1
#undef JOY_BTN_2
#define JOY_BTN_1(v) ((v) & 0)
#define JOY_BTN_2(v) ((v) & 0)

/**
 * Platform specific key map for common input
 */

// No keyboard: a joystick and the console's switches. Direction comes from
// the stick, so the arrow codes are unreachable placeholders for
// readCommonInput()'s switch.
#define KEY_LEFT_ARROW      0xF1
#define KEY_LEFT_ARROW_2    0xF2
#define KEY_LEFT_ARROW_3    0xF3

#define KEY_RIGHT_ARROW     0xF4
#define KEY_RIGHT_ARROW_2   0xF5
#define KEY_RIGHT_ARROW_3   0xF6

#define KEY_UP_ARROW        0xF7
#define KEY_UP_ARROW_2      0xF8
#define KEY_UP_ARROW_3      0xF9

#define KEY_DOWN_ARROW      0xFA
#define KEY_DOWN_ARROW_2    0xFB
#define KEY_DOWN_ARROW_3    0xFC

#define KEY_RETURN 0x0D
#define KEY_ESCAPE 0x1B
#define KEY_ESCAPE_ALT 0x03
#define KEY_SPACEBAR 0x20
#define KEY_BACKSPACE 0x08

// What the shared screens call the escape key
#define ESCAPE "PAUSE"
#define ESC "PAUSE"

// Countdown can reach two digits
#define TIMER_WIDTH 2

// Name entry happens on src/atari7800/osk.c's on-screen keyboard.
#define USE_PLATFORM_NAME_ENTRY 1

// The buttons stand in for the letter shortcuts the other ports type.
// src/atari7800/input.c maps them; keep the two in step. Button 2 is a
// ProLine's right button, or RESET for a one-button stick.
//   1 (fire)        RETURN   join / fire / place
//   2 or RESET      'r'      refresh the table list, rotate a ship
//   PAUSE           ESCAPE   the in-game menu
//   SELECT          'n'      change name (on release, alone)
//   SELECT+1        'h'      how to play
//   SELECT+2        's'      sound on/off
//   SELECT+PAUSE    'q'      quit
// Capitals draw in red, each group a palette run, and a row holds at most 12
// runs (maria.h MT_MAXRUNS): keep these to a few capital groups.
#define TABLE_STATUS_TEXT "2:Refresh SEL:Name SEL+1:Help"
#define MENU_QUIT_TEXT "  SEL+PAUSE: quit"
#define MENU_HELP_TEXT "  SEL+1: help"
#define MENU_SOUND_ON_TEXT "  SEL+2: sound ON "
#define MENU_SOUND_OFF_TEXT "  SEL+2: sound OFF"
#define ROTATE_PROMPT_TEXT "press 2/RESET to rotate"
#define READY_PROMPT_TEXT "press FIRE when ready"
#define MENU_CLOSE_TEXT "press FIRE to close"

#endif /* KEYMAP_H */

#endif /* BUILD_ATARI7800 */
