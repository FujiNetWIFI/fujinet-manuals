/* term.c -- the terminal pane.
 *
 * cc65's NMI handler puts the scroll back to 0,0 every frame, so the pane
 * cannot be scrolled by the PPU. Instead every character goes into a shadow
 * copy of the pane in RAM, scrolling is a memmove of that copy, and
 * term_flush() sends the rows that changed to the screen through conio,
 * whose writes are queued for the vblank NMI. A burst of text costs one
 * redraw, not one per line. */

#include <conio.h>
#include <string.h>
#include "term.h"

static char shadow[TERM_ROWS][TERM_COLS];
static uint8_t dirty[TERM_ROWS];
static uint8_t col, row;

void term_clear(void)
{
  memset(shadow, ' ', sizeof shadow);
  memset(dirty, 1, sizeof dirty);
  col = row = 0;
}

static void scroll(void)
{
  memmove(shadow[0], shadow[1], (TERM_ROWS - 1) * TERM_COLS);
  memset(shadow[TERM_ROWS - 1], ' ', TERM_COLS);
  memset(dirty, 1, sizeof dirty);
}

static void newline(void)
{
  col = 0;
  if (row == TERM_ROWS - 1)
    scroll();
  else
    ++row;
}

void term_putc(char c)
{
  if (c == '\r') {
    col = 0;
    return;
  }
  if (c == '\n') {
    newline();
    return;
  }
  if (c == '\b') {
    if (col)
      --col;
    return;
  }
  if (c < 0x20 || c > 0x7E)             /* nothing else has a glyph */
    return;

  if (col == TERM_COLS)
    newline();
  shadow[row][col++] = c;
  dirty[row] = 1;
}

void term_flush(void)
{
  uint8_t r, c;

  for (r = 0; r < TERM_ROWS; r++) {
    if (!dirty[r])
      continue;
    gotoxy(TERM_LEFT, TERM_TOP + r);
    for (c = 0; c < TERM_COLS; c++)
      cputc(shadow[r][c]);              /* queued; written in the next vblank */
    dirty[r] = 0;
  }
}

void term_repaint(void)
{
  memset(dirty, 1, sizeof dirty);
  term_flush();
}
