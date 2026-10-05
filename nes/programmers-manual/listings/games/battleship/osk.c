#ifdef BUILD_NES

/**
 * @brief   NES on-screen keyboard
 * @author  Thomas Cherryhomes
 * @email   thom dot cherryhomes at gmail dot com
 * @license gpl v. 3, see LICENSE for details
 */

#include <joystick.h>
#include <string.h>
#include "vars.h"
#include "../platform-specific/graphics.h"
#include "../platform-specific/sound.h"

/*
  An NES controller has no keys at all, so any text the player has to type
  gets typed on screen. This is src/coleco/osk.c's grid -- the one the
  5 Card Stud clients, the Intellivision client's grid_entry and the CONFIG
  clients all use -- with the keypad shortcuts moved to the buttons: A types
  the cell under the cursor, B backspaces and START accepts. The cursor
  position IS the character, so there is no shift key and no paging.

  One rule is inherited deliberately: cancel is the OK cell's absence, not
  the backspace key. Backspace must never discard the edit; there is no
  cancel here at all, because the caller only reaches this screen when a name
  is required.

  Entry is uppercase-only (the server lowercases names anyway - see
  welcomeActionVerifyPlayerName()).
*/

#define OSK_COLS 10
#define OSK_ROWS 4
#define OSK_PITCH 3 /* marker column + two label columns */
#define OSK_X 1
#define OSK_Y 19    /* below the name box showPlayerNameScreen draws at 16-18 */

/* The last row is one short: its tenth cell does not exist. */
#define OSK_LAST_ROW_COLS 9

#define CELL_SPACE (OSK_COLS * 3 + 6) /* index 36 */
#define CELL_DEL (CELL_SPACE + 1)
#define CELL_OK (CELL_SPACE + 2)

static const char cells[] =
    "ABCDEFGHIJ"
    "KLMNOPQRST"
    "UVWXYZ0123"
    "456789";

#define DIRS (JOY_UP_MASK | JOY_DOWN_MASK | JOY_LEFT_MASK | JOY_RIGHT_MASK)

#define REPEAT_FIRST 18 /* vblanks before a held stick repeats */
#define REPEAT_NEXT 5

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
        drawText(x + 1, OSK_Y + row, "SP");
    else if (idx == CELL_DEL)
        drawText(x + 1, OSK_Y + row, "<-");
    else if (idx == CELL_OK)
        drawText(x + 1, OSK_Y + row, "OK");
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
        drawSpace(0, OSK_Y + row, WIDTH);
}

/* Repaint the field and its trailing cursor chip, the same shape
   inputFieldCycle() draws on the platforms that have a keyboard. */
static void drawField(unsigned char x, unsigned char y, unsigned char max,
                      const char *buffer)
{
    unsigned char len = (unsigned char)strlen(buffer);

    drawSpace(x, y, max);
    drawText(x, y, buffer);
    if (len < max)
        drawIcon(x + len, y, ICON_TEXT_CURSOR);
}

static void appendChar(char *buffer, unsigned char *len, unsigned char max,
                       char ch)
{
    if (*len >= max)
    {
        soundInvalid();
        return;
    }
    buffer[(*len)++] = ch;
    buffer[*len] = 0;
    soundCursor();
}

void platformNameEntry(unsigned char x, unsigned char y, unsigned char max,
                       char *buffer)
{
    unsigned char len = (unsigned char)strlen(buffer);
    unsigned char hold = 0, lastDir = 0, lastButtons;
    unsigned char pad, dir, move, pressed, idx;

    curX = 0;
    curY = 0;
    drawGrid();
    drawField(x, y, max, buffer);

    // Whatever is already held (the A that opened this screen) is not a press.
    lastButtons = joy_read(JOY_1) & ~DIRS;

    for (;;)
    {
        waitvsync();

        pad = joy_read(JOY_1);
        dir = pad & DIRS;
        pressed = pad & ~DIRS & ~lastButtons;
        lastButtons = pad & ~DIRS;

        /* Auto-repeat is counted in vblanks. This loop runs once per frame,
           so `hold` is already a frame count. */
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

        if (!pressed)
            continue;

        /* A takes whatever the cursor is sitting on; B and START are
           shortcuts for the backspace and OK cells. */
        if (pressed & JOY_BTN_B_MASK)
            idx = CELL_DEL;
        else if (pressed & JOY_START_MASK)
            idx = CELL_OK;
        else if (pressed & JOY_BTN_A_MASK)
            idx = curY * OSK_COLS + curX;
        else
            continue;

        if (idx == CELL_OK)
        {
            if (!len)
            {
                soundInvalid();
                continue;
            }
            break;
        }

        if (idx == CELL_DEL)
        {
            if (!len)
            {
                soundInvalid();
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

#endif /* BUILD_NES */
