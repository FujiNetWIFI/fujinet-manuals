/* osk.h -- an on-screen keyboard for the joypad. */

#ifndef OSK_H
#define OSK_H

#include <stdint.h>

#define OSK_ROWS 9                      /* screen rows it occupies */
#define OSK_DEL  '\b'
#define OSK_DONE '\r'

extern void osk_draw(uint8_t top);      /* draw it with its top on conio row top */
extern char osk_input(uint8_t pad);     /* feed it pad_poll(); a key, or 0 */

#endif
