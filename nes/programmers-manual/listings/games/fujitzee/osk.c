#ifdef BUILD_NES

/**
 * @brief   NES on-screen keyboard
 * @author  Thomas Cherryhomes
 * @email   thom dot cherryhomes at gmail dot com
 * @license gpl v. 3, see LICENSE for details
 */

#include <joystick.h>
#include <time.h>
#include "vars.h"
#include "../platform-specific/graphics.h"
#include "../platform-specific/sound.h"

/*
  An NES controller has no keys at all, so the player's name is typed on
  screen. The grid is fujinet-battleship's src/nes/osk.c (itself the
  ColecoVision/5 Card Stud/CONFIG grid), but here it is a KEY SOURCE rather
  than an editor: while it is open, input.c's kbhit() asks oskPoll() for a
  key, and the shared inputFieldCycle() does the editing, the cursor chip and
  the minimum-length check exactly as it does on a keyboard machine.

  A types the cell under the cursor, B backspaces and START accepts (as does
  the OK cell). The cursor position IS the character, so there is no shift
  key and no paging. There is no cancel: the name screen only opens when a
  name is required.
*/

#define OSK_COLS 10
#define OSK_ROWS 4
#define OSK_PITCH 3 /* marker column + two label columns */
#define OSK_X 1
#define OSK_Y 17    /* below the "at least 2 letters" hint at row 16 */
#define OSK_ROW_STEP 2 /* a blank line between rows, or the grid reads as columns */

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

#define REPEAT_FIRST 18 /* frames before a held stick repeats */
#define REPEAT_NEXT 5

unsigned char oskActive;

static unsigned char curX, curY, hold, lastDir, lastButtons, lastFrame;

static unsigned char cellCols(unsigned char row)
{
    return row == OSK_ROWS - 1 ? OSK_LAST_ROW_COLS : OSK_COLS;
}

static void drawCell(unsigned char col, unsigned char row, unsigned char marked)
{
    unsigned char idx = row * OSK_COLS + col;
    unsigned char x = OSK_X + col * OSK_PITCH;
    char glyph[3];

    if (marked)
        drawIcon(x, OSK_Y + row * OSK_ROW_STEP, ICON_MARK);
    else
        drawBlank(x, OSK_Y + row * OSK_ROW_STEP);

    if (idx == CELL_SPACE)
        drawTextAlt(x + 1, OSK_Y + row * OSK_ROW_STEP, "sp");
    else if (idx == CELL_DEL)
        drawTextAlt(x + 1, OSK_Y + row * OSK_ROW_STEP, "dl");
    else if (idx == CELL_OK)
        drawTextAlt(x + 1, OSK_Y + row * OSK_ROW_STEP, "ok");
    else
    {
        glyph[0] = cells[idx];
        glyph[1] = ' ';
        glyph[2] = 0;
        drawText(x + 1, OSK_Y + row * OSK_ROW_STEP, glyph);
    }
}

void oskOpen(void)
{
    unsigned char row, col;

    curX = curY = 0;
    for (row = 0; row < OSK_ROWS; row++)
        for (col = 0; col < cellCols(row); col++)
            drawCell(col, row, row == curY && col == curX);

    drawTextAlt(WIDTH / 2 - 12, HEIGHT - 1, "A:TYPE B:DELETE START:OK");

    // Whatever is already held (the A that opened this screen) is not a press.
    lastButtons = joy_read(JOY_1) & ~DIRS;
    lastDir = joy_read(JOY_1) & DIRS;
    hold = REPEAT_FIRST;
    lastFrame = (unsigned char)clock();
    oskActive = 1;
}

void oskClose(void)
{
    unsigned char row;

    oskActive = 0;
    for (row = 0; row < OSK_ROWS; row++)
        drawSpace(0, OSK_Y + row * OSK_ROW_STEP, WIDTH);
    drawSpace(0, HEIGHT - 1, WIDTH);
}

/* One key for inputFieldCycle(), or 0. inputFieldCycle() spins on kbhit()
   without waiting for vblank, so the pad is read once a frame here: that is
   what auto-repeat and the button edges are counted in. */
unsigned char oskPoll(void)
{
    unsigned char pad, dir, move, pressed, idx;

    if ((unsigned char)clock() == lastFrame)
        return 0;
    lastFrame = (unsigned char)clock();

    pad = joy_read(JOY_1);
    dir = pad & DIRS;
    pressed = pad & ~DIRS & ~lastButtons;
    lastButtons = pad & ~DIRS;

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

    /* A takes whatever the cursor is sitting on; B and START are shortcuts
       for the backspace and OK cells. */
    if (pressed & JOY_BTN_B_MASK)
        idx = CELL_DEL;
    else if (pressed & JOY_START_MASK)
        idx = CELL_OK;
    else if (pressed & JOY_BTN_A_MASK)
        idx = curY * OSK_COLS + curX;
    else
        return 0;

    if (idx == CELL_OK)
        return KEY_RETURN;
    if (idx == CELL_DEL)
        return KEY_BACKSPACE;

    soundCursor();
    return idx == CELL_SPACE ? KEY_SPACEBAR : cells[idx];
}

#endif /* BUILD_NES */
