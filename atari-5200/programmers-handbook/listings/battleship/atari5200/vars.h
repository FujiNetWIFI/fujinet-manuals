#ifdef BUILD_ATARI5200

#ifndef KEYMAP_H
#define KEYMAP_H

#include <joystick.h>

// Screen dimensions for platform: the Atari 8-bit's ANTIC mode 4 screen
#define WIDTH 40
#define HEIGHT 26

#define GAMEOVER_PROMPT_Y HEIGHT - 3

// Icons - codes in support/atari/charset.fnt, as on the Atari 8-bit
#define ICON_TEXT_CURSOR 0x3A
#define ICON_MARK 0x2B
#define ICON_MARK_ALT 0
#define ICON_PLAYER 0x2A

/* readJoystick() (src/atari5200/input.c) returns the stick only, in cc65's
   joystick bits. The buttons and the keypad never appear in the joystick
   byte: input.c reports them as key codes behind kbhit()/cgetc(), as on the
   7800, so the "press any key" screens see the fire buttons too. */
#undef JOY_BTN_1
#undef JOY_BTN_2
#define JOY_BTN_1(v) ((v) & 0)
#define JOY_BTN_2(v) ((v) & 0)

/**
 * Platform specific key map for common input
 */

// No keyboard: an analog stick, two fire buttons and a twelve-key keypad.
// Direction comes from the stick, so the arrow codes are unreachable
// placeholders for readCommonInput()'s switch.
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

// Name entry happens on src/atari5200/osk.c's on-screen keyboard.
#define USE_PLATFORM_NAME_ENTRY 1

// The keypad stands in for the letter shortcuts the other ports type, with
// the ColecoVision's digits. src/atari5200/input.c maps them; keep the two
// in step.
//   top fire, #, START    RETURN   join / fire / place / ready
//   lower fire, 1         'r'      refresh the table list, rotate a ship
//   PAUSE, *              ESCAPE   the in-game menu
//   2 'h' how to play     3 's' sound     4 'n' name     5 'q' quit
// The charset has letters, digits and : - . / ! , only.
#define TABLE_STATUS_TEXT "1:Refresh  2:Help  4:Name  5:Quit"
#define MENU_QUIT_TEXT "  5: quit game"
#define MENU_HELP_TEXT "  2: how to play"
#define MENU_SOUND_ON_TEXT "  3: sound ON "
#define MENU_SOUND_OFF_TEXT "  3: sound OFF"
#define ROTATE_PROMPT_TEXT "press LOWER FIRE to rotate"
#define READY_PROMPT_TEXT "press FIRE when ready"
#define MENU_CLOSE_TEXT "press FIRE to close"

#endif /* KEYMAP_H */

#endif /* BUILD_ATARI5200 */
