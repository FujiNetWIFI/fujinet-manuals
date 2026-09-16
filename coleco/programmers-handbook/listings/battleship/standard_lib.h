#ifndef STANDARD_LIB_H
#define STANDARD_LIB_H

/*
 * All standard library includes should be added here for use by
 * platform agnostic code in the "src" directory.
 * 
 * This creates one place to manage platform/compiler specific standard headers.
 * 
 * This ONLY applies to code in the immediate "src" directory.
 * Files in "/src/[platform]" may reference misc.h, this file, or headers directly as needed.
 */

// Include FujiNet Fuji header, which sets std int and bool types (uint8_t, bool, etc)
#include "fujinet-fuji.h"

#ifdef _CMOC_VERSION_
#include <coco.h>

/* (Non blocking) Return a character if there's a key waiting, otherwise 0.
 */
unsigned char kbhit (void);

/* (Blocking) Return a character from the keyboard. If there is no key waiting,
 * the function waits until the user does press a key.
 */
char cgetc (void);

#elif defined(__ADAM__)
// z88dk's conio.h maps cgetc() onto getk(), which is a dead stub on the
// Adam target - kbhit/cgetc are implemented over EOS in src/adam/input.c
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

/* (Non blocking) Return non-zero if a key is waiting. */
unsigned char kbhit (void);

/* (Blocking) Return a character from the keyboard.
 * Must be unsigned: sccz80 chars are signed, and the Adam's arrow/smart
 * keys are 0x81-0xA8 - a plain char return would sign-extend them and no
 * KEY_* case in the input switch would ever match. */
unsigned char cgetc (void);

#elif defined(BUILD_COLECO)
// No keyboard at all: src/coleco/input.c synthesizes key codes from the
// twelve-key keypad and the second fire button. unsigned for the same
// sign-extension reason as the Adam above.
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

/* (Non blocking) Return non-zero if a synthesized key is waiting. */
unsigned char kbhit (void);

/* (Blocking) Return a synthesized key code. */
unsigned char cgetc (void);

#else
// Standard libraries
#include <conio.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#endif

#endif /* STANDARD_LIB_H */
