#ifdef BUILD_COLECO

/**
 * @brief   ColecoVision on-screen keyboard
 * @author  Thomas Cherryhomes
 * @email   thom dot cherryhomes at gmail dot com
 * @license gpl v. 3, see LICENSE for details
 */

#include <games.h>
#include <string.h>
#include "vars.h"
#include "joystick.h"
#include "../platform-specific/graphics.h"
#include "../platform-specific/sound.h"

/*
  A ColecoVision controller has twelve keys and a stick, so any text the player
  has to type gets typed on screen. This is the same grid the Intellivision
  client's grid_entry, the Astrocade's edit.inc and the ColecoVision CONFIG
  client's fujiedit.c all use, and they look alike for the same reason: the
  cursor position IS the character, so there is no shift key and no paging.

  Two rules are inherited deliberately from those three:

    - cancel is the OK cell's absence, not the backspace key. Backspace must
      never discard the edit, because reaching for it repeatedly while fixing a
      typo is exactly when a reflexive extra press happens. There is no cancel
      here at all: the caller only reaches this screen when a name is required.
    - the grid never runs a mailbox transaction. The caller may be holding data
      in the cartridge's reply window, and any transaction would repaint it.

  Where this one departs from fujiedit.c is the CASE toggle, which is not
  offered: drawText() runs strupr() over everything it prints, so lowercase is
  not representable anywhere in this port's text layer. Uppercase-only keeps
  what is typed and what is displayed the same thing.
*/

#define OSK_COLS   10
#define OSK_ROWS   4
#define OSK_PITCH  3                    /* marker column + two label columns */
#define OSK_X      1
#define OSK_Y      17

/* The last row is one short: its tenth cell does not exist. */
#define OSK_LAST_ROW_COLS 9

#define CELL_SPACE (OSK_COLS * 3 + 6)   /* index 36 */
#define CELL_DEL   (CELL_SPACE + 1)
#define CELL_OK    (CELL_SPACE + 2)

static const char cells[] =
  "ABCDEFGHIJ"
  "KLMNOPQRST"
  "UVWXYZ0123"
  "456789";

static const char *labelSpace = "SP";
static const char *labelDel   = "<-";
static const char *labelOk    = "OK";

/* The fire button, as a value the keypad never returns. */
#define EV_FIRE 1

#define REPEAT_FIRST 18                 /* vblanks before a held stick repeats */
#define REPEAT_NEXT  5

static unsigned char curX, curY;

static unsigned char cellCols(unsigned char row)
{
  return row == OSK_ROWS - 1 ? OSK_LAST_ROW_COLS : OSK_COLS;
}

static void drawCell(unsigned char col, unsigned char row, unsigned char marked)
{
  unsigned char idx = row * OSK_COLS + col;
  unsigned char x = OSK_X + col * OSK_PITCH;
  char glyph[3];

  drawText(x, OSK_Y + row, marked ? ">" : " ");

  if (idx == CELL_SPACE)
    drawText(x + 1, OSK_Y + row, labelSpace);
  else if (idx == CELL_DEL)
    drawText(x + 1, OSK_Y + row, labelDel);
  else if (idx == CELL_OK)
    drawText(x + 1, OSK_Y + row, labelOk);
  else
  {
    glyph[0] = cells[idx];
    glyph[1] = ' ';
    glyph[2] = 0;
    drawText(x + 1, OSK_Y + row, glyph);
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
    drawText(0, OSK_Y + row, "                                ");
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

void platformNameEntry(unsigned char x, unsigned char y, unsigned char max,
                       char *buffer)
{
  unsigned char len = (unsigned char) strlen(buffer);
  unsigned char hold = 0, lastDir = 0, lastEvent = 0;
  unsigned int pad;
  unsigned char dir, move, event, idx;

  curX = 0;
  curY = 0;
  drawGrid();
  drawField(x, y, max, buffer);

  for (;;)
  {
    waitvsync();

    pad = joystick(3);
    dir = (unsigned char) pad & 0x0F;
    event = (unsigned char) (pad >> 8);
    if (!event && (pad & JOY_BTN_1_MASK))
      event = EV_FIRE;

    /* Auto-repeat is counted in vblanks. This loop runs once per frame, so
       `hold` is already a frame count -- ageing it per pass instead would run
       the cursor across the whole grid on one push. */
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

    if (event == lastEvent)
      continue;
    lastEvent = event;
    if (!event)
      continue;

    /* The keypad is a shortcut over the grid, never a way into it: a digit
       types itself, * backspaces and # accepts, and the fire button is what
       takes whatever the cursor is sitting on. */
    if (event >= '0' && event <= '9')
    {
      appendChar(buffer, &len, max, (char) event);
      drawField(x, y, max, buffer);
      continue;
    }

    idx = curY * OSK_COLS + curX;
    if (event == '*')
      idx = CELL_DEL;
    else if (event == '#')
      idx = CELL_OK;
    else if (event != EV_FIRE)
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
    else
      appendChar(buffer, &len, max, idx == CELL_SPACE ? ' ' : cells[idx]);

    drawField(x, y, max, buffer);
  }

  clearGrid();
}

#endif /* BUILD_COLECO */
