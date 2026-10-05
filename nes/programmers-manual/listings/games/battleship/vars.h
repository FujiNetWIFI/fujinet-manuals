#ifdef BUILD_NES

#ifndef KEYMAP_H
#define KEYMAP_H

#include <joystick.h>

// Screen dimensions for platform. The NES shows 32x30 tiles, but the top and
// bottom rows sit in a CRT's overscan, so the 32x24 layout the ColecoVision
// port uses is drawn centred, three rows down (src/nes/graphics.c ROW0).
#define WIDTH 32
#define HEIGHT 24

#define GAMEOVER_PROMPT_Y HEIGHT - 2

// Icons - msdos tile sheet indices; graphics.c maps them through sheetTile[]
#define ICON_TEXT_CURSOR 0x3A
#define ICON_PLAYER 0x2A
#define ICON_MARK 0x2B
#define ICON_MARK_ALT 0x19
#define ICON_ACTIVE_PLAYER 0x05

/* readJoystick() (src/nes/input.c) returns the d-pad only, as cc65's joystick
   driver bits. The buttons never appear in the joystick byte: input.c reports
   them as key codes behind kbhit()/cgetc(), with one edge detector, the way
   the ColecoVision port reports its fire buttons. A is KEY_RETURN, which the
   shared input maps to the trigger. cc65's <joystick.h> defines JOY_UP() and
   friends already; the buttons are overridden to never fire. */
#undef JOY_BTN_1
#undef JOY_BTN_2
#define JOY_BTN_1(v) ((v) & 0)
#define JOY_BTN_2(v) ((v) & 0)

/**
 * Platform specific key map for common input
 */

// There is no keyboard: a d-pad and A, B, SELECT, START. Direction comes from
// the d-pad, never from a key, so the arrow codes are deliberately unreachable
// placeholders -- they exist because readCommonInput() switches on all twelve.
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
#define ESCAPE "START"
#define ESC "START"

// Countdown can reach two digits
#define TIMER_WIDTH 2

// Name entry happens on src/nes/osk.c's on-screen keyboard, not
// inputFieldCycle() -- there are no letter keys to type into it.
#define USE_PLATFORM_NAME_ENTRY 1

// The buttons stand in for the letter shortcuts the other ports type.
// src/nes/input.c maps them; keep the two in step:
//   A            RETURN   join / fire / place
//   B            'r'      refresh the table list, rotate a ship
//   START        ESCAPE   the in-game menu
//   SELECT       'n'      change name (on release, alone)
//   SELECT+A     'h'      how to play
//   SELECT+B     's'      sound on/off
//   SELECT+START 'q'      quit
#define TABLE_STATUS_TEXT "B:Refresh SEL:Name SEL+A:Help"
#define MENU_QUIT_TEXT "  SEL+START: quit"
#define MENU_HELP_TEXT "  SEL+A: help"
#define MENU_SOUND_ON_TEXT "  SEL+B: sound ON "
#define MENU_SOUND_OFF_TEXT "  SEL+B: sound OFF"
#define ROTATE_PROMPT_TEXT "press B to rotate"
#define READY_PROMPT_TEXT "press A when ready"
#define MENU_CLOSE_TEXT "press A to close"

#endif /* KEYMAP_H */

#endif /* BUILD_NES */
