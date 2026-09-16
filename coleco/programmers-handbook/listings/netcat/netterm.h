/* netterm.h -- a scrolling text pane.
 *
 * The TMS9918 in Graphics 1 has no hardware scroll, so a terminal has to move
 * its own pixels: when the cursor falls off the bottom, every row is copied up
 * one and the last is cleared. That is a VRAM-to-VRAM block move a row at a
 * time, done through OS7's read_vram / write_vram (the name table is at 0x1800
 * in the layout mode_1 sets up).
 *
 * There is no RAM shadow of the pane -- a ColecoVision does not have the bytes
 * for one. When the on-screen keyboard has to borrow the screen to compose a
 * line, the pane is saved to spare VRAM and restored afterwards, so the
 * conversation survives the interruption without ever occupying console RAM.
 */

#ifndef NETTERM_H
#define NETTERM_H

/* The pane: rows TERM_TOP through TERM_BOT of the 32x24 screen, full width.
 * Row 0 is the title, row 23 the key legend. */
#define TERM_TOP   2
#define TERM_BOT   21
#define TERM_ROWS  (TERM_BOT - TERM_TOP + 1)
#define TERM_COLS  32

/* Clear the pane and home the cursor. */
void term_init(void);

/* Put one character. Handles CR (column 0), LF (next line, scrolling at the
 * bottom), backspace, and printable ASCII; anything else is shown as a dot so
 * a control-heavy stream still looks like something. */
void term_putc(char c);

/* Put `n` bytes -- one whole NET_READ, straight out of the reply window, which
 * is why the argument is volatile. */
void term_puts(volatile unsigned char *p, unsigned int n);

/* Save the pane to spare VRAM before the on-screen keyboard takes the screen,
 * and put it back after. */
void term_save(void);
void term_restore(void);

#endif /* NETTERM_H */
