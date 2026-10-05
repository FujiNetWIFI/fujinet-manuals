/* term.h -- a scrolling text pane over cc65's conio. */

#ifndef TERM_H
#define TERM_H

#include <stdint.h>

#define TERM_TOP   2                    /* first conio row of the pane */
#define TERM_ROWS 24
#define TERM_LEFT  1                    /* stay clear of the overscan edge */
#define TERM_COLS 30

extern void term_clear(void);
extern void term_putc(char c);          /* into the shadow only */
extern void term_flush(void);           /* shadow rows that changed -> PPU */
extern void term_repaint(void);         /* every row, after an overlay */

#endif
