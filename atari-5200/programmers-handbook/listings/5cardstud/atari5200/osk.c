#ifdef BUILD_ATARI5200

/**
 * @brief   Atari 5200 on-screen keyboard
 * @author  Thomas Cherryhomes
 * @email   thom dot cherryhomes at gmail dot com
 * @license gpl v. 3, see LICENSE for details
 */

#include <atari5200.h>
#include <string.h>
#include <fujinet-atari5200.h>
#include "vars.h"
#include "../platform-specific/graphics.h"
#include "../platform-specific/sound.h"

/*
  The grid of the ColecoVision client (src/coleco/osk.c) and the 7800 port
  (src/atari7800/osk.c): the cursor position IS the character, so there is no
  shift key and no paging. Cancel is the OK cell's absence -- the caller only
  reaches this screen when a name is required -- and the grid never runs a
  mailbox transaction. Uppercase only: drawText() uppercases everything it
  prints.

    stick  move      top fire  take the cell      0-9  type that digit
    lower fire, * or RESET  backspace             # or START  OK
*/

#define OSK_COLS   10
#define OSK_ROWS   4
#define OSK_PITCH  3                    /* marker column + two label columns */
#define OSK_X      5
#define OSK_Y      18

/* The last row is one short: its tenth cell does not exist. */
#define OSK_LAST_ROW_COLS 9

#define CELL_SPACE (OSK_COLS * 3 + 6)   /* index 36 */
#define CELL_DEL   (CELL_SPACE + 1)
#define CELL_OK    (CELL_SPACE + 2)
#define CELL_DIGIT (CELL_SPACE + 3)     /* a keypad digit, not a cell */
#define CELL_NONE  0xFF

static const char cells[] =
  "ABCDEFGHIJ"
  "KLMNOPQRST"
  "UVWXYZ0123"
  "456789";

#define REPEAT_FIRST 18                 /* vblanks before a held direction repeats */
#define REPEAT_NEXT  5

#define DIRS (JOY_UP_MASK | JOY_DOWN_MASK | JOY_LEFT_MASK | JOY_RIGHT_MASK)
#define BUTTONS (JOY_BTN_1_MASK | PAD_BTN_2)

static unsigned char curX, curY;

static unsigned char cellCols(unsigned char row)
{
  return row == OSK_ROWS - 1 ? OSK_LAST_ROW_COLS : OSK_COLS;
}

static void drawCell(unsigned char col, unsigned char row, unsigned char marked)
{
  unsigned char idx = row * OSK_COLS + col;
  unsigned char x = OSK_X + col * OSK_PITCH;
  unsigned char y = OSK_Y + row;
  char glyph[3];

  if (marked)
    drawChip(x, y);
  else
    drawText(x, y, " ");

  if (idx == CELL_SPACE)
    drawText(x + 1, y, "SP");
  else if (idx == CELL_DEL)
  {
    // The font's "<" is box art: a pointer and a dash instead.
    fcsPutGlyph(x + 1, y, G_POINT_LEFT);
    fcsPutGlyph(x + 2, y, G_DASH);
  }
  else if (idx == CELL_OK)
    drawText(x + 1, y, "OK");
  else
  {
    glyph[0] = cells[idx];
    glyph[1] = ' ';
    glyph[2] = 0;
    drawText(x + 1, y, glyph);
  }
}

static void drawGrid(void)
{
  unsigned char row, col;

  for (row = 0; row < OSK_ROWS; row++)
    for (col = 0; col < cellCols(row); col++)
      drawCell(col, row, row == curY && col == curX);
}

static void clearGrid(void)
{
  unsigned char row;

  for (row = 0; row < OSK_ROWS; row++)
    drawText(OSK_X, OSK_Y + row, "                              ");
}

/* Repaint the field and its trailing cursor chip, the same shape
   inputFieldCycle() draws on the platforms that have a keyboard. */
static void drawField(unsigned char x, unsigned char y, unsigned char max,
                      const char *buffer)
{
  unsigned char len = (unsigned char) strlen(buffer);

  drawText(x, y, "         ");
  drawText(x, y, buffer);
  if (len < max)
    drawChip(x + len, y);
}

static void appendChar(char *buffer, unsigned char *len, unsigned char max,
                       char ch)
{
  if (*len >= max)
  {
    soundCursorInvalid();
    return;
  }
  buffer[(*len)++] = ch;
  buffer[*len] = 0;
  soundCursor();
}

/* A keypad key as a grid action: a digit is typed straight in. */
static unsigned char keypadCell(char *digit)
{
  unsigned char k = fuji_a5200_key;

  if (!k)
    return CELL_NONE;
  fuji_a5200_key = 0;
  switch (k) {
    case FUJI_A5200_KEY_HASH:
    case FUJI_A5200_KEY_START: return CELL_OK;
    case FUJI_A5200_KEY_STAR:
    case FUJI_A5200_KEY_RESET: return CELL_DEL;
  }
  if (k >= FUJI_A5200_KEY_DIGIT(0) && k <= FUJI_A5200_KEY_DIGIT(9))
  {
    *digit = (char) ('0' + k - FUJI_A5200_KEY_DIGIT(0));
    return CELL_DIGIT;
  }
  return CELL_NONE;
}

void platformNameEntry(unsigned char x, unsigned char y, unsigned char max,
                       char *buffer)
{
  unsigned char len = (unsigned char) strlen(buffer);
  unsigned char hold = 0, lastDir = 0, lastButtons = BUTTONS;
  unsigned char pad, dir, move, buttons, pressed, idx;
  char digit = 0;

  curX = 0;
  curY = 0;
  fuji_a5200_key = 0;
  drawGrid();
  drawField(x, y, max, buffer);

  for (;;)
  {
    waitvsync();

    pad = readPad();
    dir = pad & DIRS;
    buttons = pad & BUTTONS;

    /* Auto-repeat is counted in vblanks: this loop runs once per frame. */
    move = 0;
    if (dir != lastDir)
    {
      lastDir = dir;
      hold = REPEAT_FIRST;
      move = dir;
    }
    else if (dir && --hold == 0)
    {
      hold = REPEAT_NEXT;
      move = dir;
    }

    if (move)
    {
      drawCell(curX, curY, 0);

      if ((move & JOY_LEFT_MASK) && curX)
        curX--;
      else if ((move & JOY_RIGHT_MASK) && curX + 1 < cellCols(curY))
        curX++;
      else if ((move & JOY_UP_MASK) && curY)
        curY--;
      else if ((move & JOY_DOWN_MASK) && curY + 1 < OSK_ROWS)
        curY++;

      if (curX >= cellCols(curY))
        curX = cellCols(curY) - 1;

      drawCell(curX, curY, 1);
      soundCursor();
    }

    /* The lower button is backspace; the top one takes whatever the cursor
       is sitting on. */
    pressed = buttons & ~lastButtons;
    lastButtons = buttons;
    if (pressed & PAD_BTN_2)
      idx = CELL_DEL;
    else if (pressed & JOY_BTN_1_MASK)
      idx = curY * OSK_COLS + curX;
    else if ((idx = keypadCell(&digit)) == CELL_NONE)
      continue;

    if (idx == CELL_OK)
    {
      if (!len)
      {
        soundCursorInvalid();
        continue;
      }
      break;
    }

    if (idx == CELL_DEL)
    {
      if (!len)
      {
        soundCursorInvalid();
        continue;
      }
      buffer[--len] = 0;
      soundCursor();
    }
    else if (idx == CELL_SPACE)
      appendChar(buffer, &len, max, ' ');
    else if (idx == CELL_DIGIT)
      appendChar(buffer, &len, max, digit);
    else
      appendChar(buffer, &len, max, cells[idx]);

    drawField(x, y, max, buffer);
  }

  clearGrid();

  // Forget the press that said OK.
  initPlatformKeyboardInput();
}

#endif /* BUILD_ATARI5200 */
