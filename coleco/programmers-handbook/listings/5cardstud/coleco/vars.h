#ifdef BUILD_COLECO

#ifndef KEYMAP_H
#define KEYMAP_H

// Screen dimensions for platform

#define WIDTH 32
#define HEIGHT 24

#define SINGLE_BUFFER 1

#define POT_Y_MODIFIER -1
#define STATUS_TIMER_WIDTH 0
#define HOW_TO_PLAY_ROW_START 2

// The whole reply to the last mailbox transaction, as directly addressable
// cartridge ROM. bus/coleco/fujinet-bus-coleco.h (FN_REPLY) is the source of
// truth; keep the two in step.
//
// This is where ClientState lives on this platform (see src/misc.h). The
// console has 1K of RAM and the state alone is 418 bytes, so the state is
// never copied down -- the game renders straight out of the window. Two rules
// follow, and neither is optional:
//
//   - it is READ-ONLY. A store here goes nowhere; the cartridge cannot even
//     see a write cycle.
//   - it is valid only until the next fuji_* call of ANY kind. Every
//     transaction repaints the window, appkey reads and writes included.
#define COLECO_REPLY_WINDOW 0xF800

// There is no keyboard: a stick, two fire buttons and a twelve-key keypad.
// src/coleco/input.c synthesises key codes from the keypad and the second fire
// button, and src/coleco/osk.c types text on screen.
#define USE_PLATFORM_SPECIFIC_INPUT 1
#define USE_PLATFORM_NAME_ENTRY 1

/**
 * Platform specific key map for common input
 */

// Direction comes from the stick, never from a key, so the arrow codes are
// deliberately unreachable placeholders -- they exist because readCommonInput()
// switches on all twelve of them.
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

// Keypad # and the left fire button; keypad * and the right fire button.
#define KEY_RETURN       0x0D
#define KEY_ESCAPE       0x1B
#define KEY_ESCAPE_ALT   0x03
#define KEY_SPACE        0x20
#define KEY_BACKSPACE    0x08

/*
  Mapping for converting incoming ALT letters to a standard case
*/

#define LINE_ENDING 0x0A
#define ALT_LETTER_START 0x0
#define ALT_LETTER_END 0x0
#define ALT_LETTER_AND 0x0

#define QUERY_SUFFIX ""

/*
 Screen related variables
*/

// Screen specific player/bet coordinates. const, and therefore in ROM: on a
// 1K machine 96 bytes of never-written seat tables is worth the qualifier.
extern const unsigned char playerXMaster[];
extern const unsigned char playerYMaster[];

extern const char playerDirMaster[];
extern const char playerBetXMaster[];
extern const char playerBetYMaster[];

// Simple hard coded arrangment of players around the table based on player count.
// These refer to index positions in the Master arrays above
// Downside is new players will cause existing player positions to move.

//                               2                3                4
extern const char playerCountIndex[];


#endif /* KEYMAP_H */

#endif /* BUILD_COLECO */
