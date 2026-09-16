#ifdef BUILD_COLECO

#ifndef KEYMAP_H
#define KEYMAP_H

// Screen dimensions for platform

#define WIDTH 32
#define HEIGHT 24

#define GAMEOVER_PROMPT_Y HEIGHT - 2

// The whole reply to the last mailbox transaction, as directly addressable
// cartridge ROM. fujinet-lib-experimental bus/coleco/fujinet-bus-coleco.h
// (FN_REPLY) is the source of truth; keep the two in step.
//
// This is where ClientState lives on this platform (see src/misc.h). The
// console has 1K of RAM and the game state alone is 509 bytes, so the state is
// never copied down -- the game renders straight out of the window. Two rules
// follow, and neither is optional:
//
//   - it is READ-ONLY. A store here goes nowhere; the cartridge cannot even
//     see a write cycle.
//   - it is valid only until the next fuji_* call of ANY kind. Every
//     transaction repaints the window, appkey reads and writes included.
#define COLECO_REPLY_WINDOW 0xF800

// Icons - msdos tile sheet indices (src/coleco/charset.c imports all 256)
#define ICON_TEXT_CURSOR 0x3A
#define ICON_PLAYER 0x2A
#define ICON_MARK 0x2B
#define ICON_MARK_ALT 0x19
#define ICON_ACTIVE_PLAYER 0x05

/* Macros that evaluate the return code of readJoystick(). These are z88dk's
   coleco_joypad() bits (see joystick.h). The fire buttons never appear in the
   joystick byte -- input.c reports fire-1 as KEY_RETURN (which the shared
   input maps to the trigger) and fire-2 as KEY_ESCAPE, behind the same edge
   detector as the keypad. */
#define JOY_UP(v) ((v) & 0x08)
#define JOY_DOWN(v) ((v) & 0x04)
#define JOY_LEFT(v) ((v) & 0x02)
#define JOY_RIGHT(v) ((v) & 0x01)
#define JOY_BTN_1(v) ((v) & 0)
#define JOY_BTN_2(v) ((v) & 0)

/**
 * Platform specific key map for common input
 */

// There is no keyboard: a stick, two fire buttons and a twelve-key keypad.
// Direction comes from the stick, never from a key, so the arrow codes are
// deliberately unreachable placeholders -- they exist because
// readCommonInput() switches on all twelve of them.
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

// Keypad # and the fire buttons; keypad * is escape.
#define KEY_RETURN 0x0D
#define KEY_ESCAPE 0x1B
#define KEY_ESCAPE_ALT 0x03
#define KEY_SPACEBAR 0x20
#define KEY_BACKSPACE 0x08

// What the shared screens call the escape key
#define ESCAPE "*"
#define ESC "*"

// Countdown can reach two digits
#define TIMER_WIDTH 2

// Name entry happens on src/coleco/osk.c's on-screen keyboard, not
// inputFieldCycle() -- there are no letter keys to type into it.
#define USE_PLATFORM_NAME_ENTRY 1

// The keypad stands in for the letter shortcuts the other ports type.
// src/coleco/input.c maps 1/2/3/4/5 to r/h/s/n/q; keep the two in step.
#define TABLE_STATUS_TEXT "1:Rfrsh 2:Help 4:Name 5:Quit"
#define MENU_QUIT_TEXT "  5: quit game"
#define MENU_HELP_TEXT "  2: how to play"
#define MENU_SOUND_ON_TEXT "  3: sound ON "
#define MENU_SOUND_OFF_TEXT "  3: sound OFF"
#define ROTATE_PROMPT_TEXT "press 1 to rotate"

#endif /* KEYMAP_H */

#endif /* BUILD_COLECO */
