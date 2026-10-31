#ifdef BUILD_ATARI5200

#ifndef KEYMAP_H
#define KEYMAP_H

// The 8-bit Atari client's screen: ANTIC mode 4, 40x26, the bottom row the
// status bar under its own colours (src/atari5200/antic.s).

#define WIDTH 40
#define HEIGHT 26

#define POT_Y_MODIFIER 1
#define STATUS_TIMER_WIDTH 1

// A controller is an analog stick, two fire buttons and a 12-key keypad with
// START, PAUSE and RESET. src/atari5200/input.c synthesises key codes from
// them and src/atari5200/osk.c types text on screen.
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

// Fire buttons and keypad.
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
 The controls, as readPad() reports them: the stick in cc65's JOY_*_MASK
 bits, the top button as JOY_BTN_1_MASK and the lower one as PAD_BTN_2.
*/
#define PAD_BTN_2 0x20

unsigned char readPad(void);

// Frames since start-up (the VBI's RTCLOK), and whether the console is PAL.
unsigned int fcsFrames(void);
unsigned char fcsPal(void);

// One glyph of the font, by its ANTIC internal code.
void fcsPutGlyph(unsigned char x, unsigned char y, unsigned char g);
#define G_POINT_LEFT 121
#define G_DASH       125

/*
 Screen related variables
*/

// Screen specific player/bet coordinates, in ROM.
extern const unsigned char playerXMaster[];
extern const unsigned char playerYMaster[];
extern const char playerDirMaster[];
extern const char playerBetXMaster[];
extern const char playerBetYMaster[];

// Simple hard coded arrangment of players around the table based on player count.
// These refer to index positions in the Master arrays above
// Downside is new players will cause existing player positions to move.
extern const char playerCountIndex[];

#endif /* KEYMAP_H */

#endif /* BUILD_ATARI5200 */
