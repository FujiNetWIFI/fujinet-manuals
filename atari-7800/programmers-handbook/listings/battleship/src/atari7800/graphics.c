#ifdef BUILD_ATARI7800

/*
  Graphics functionality - Atari 7800 MARIA

  The shared text and tile engine (maria.h): 32x24 cells, each a tile and a
  palette select. The layout and the drawing calls are the NES port's
  (src/nes/graphics.c), drawn from the same MS-DOS sheet; src/atari7800/mkchr.py
  fits it into the engine's 128 tiles by letting the two palettes do what the
  NES did with extra glyph sets (see its header).

  Each palette change starts a new run in the row's display list, and a row
  holds at most MT_MAXRUNS. So cells keep runs long: text sets its whole
  string, white-only art leaves the cell's palette alone, and drawBoard()
  turns the fields and drawers to the art palette before anything lands in
  them.
*/

#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include "vars.h"
#include "tiles.h"
#include "maria.h"
#include "pad.h"
#include "../misc.h"

/* MARIA colours, hue << 4 | luminance: the MS-DOS client's CGA palette 1,
   high intensity. A PAL console's hues sit one higher. */
#define C_BLUE     0x82
#define C_CYAN     0xAC
#define C_RED      0x46
#define C_WHITE    0x0F
#define PAL_HUE    0x10

/* The whole screen, tiles then palettes, for saveScreenBuffer(). */
static unsigned char saved[2][HEIGHT * WIDTH];

/**
 * @brief Top left of each playfield quadrant (32x24 layout)
 */
static const unsigned char quadrant_offset[4][2] =
    {
        {5, 12}, // bottom left
        {5, 1},  // Top left
        {17, 1}, // top right
        {17, 12} // bottom right
    };

/**
 * @brief offset of legends for each player
 */
static const signed char legendShipOffset[5][2] =
    {
        {2, 0},
        {1, 0},
        {0, 0},
        {0, 5},
        {1, 6},
    };

/**
 * @brief Horizontal Field offset
 */
static unsigned char fieldX = 0;

/**
 * @brief Number of active players
 */
static unsigned char playerCount = 0;

/**
 * @brief set n cells from column x, row y to palette pal
 */
static void paint(unsigned char x, unsigned char y, unsigned char n, unsigned char pal)
{
    mt_at(x, y);
    mt_setpal(pal, n);
}

/**
 * @brief put tile t in palette pal (or AGNOSTIC: leave it) at column x, row y
 */
static void put(unsigned char x, unsigned char y, unsigned char t, unsigned char pal)
{
    if (x >= WIDTH || y >= HEIGHT)
        return;

    mt_at(x, y);
    mt_put(t);
    if (pal != AGNOSTIC && mt_attr[y * WIDTH + x] != pal)
        paint(x, y, 1, pal);
}

/**
 * @brief plot two sheet tiles merged at column x, row y. Used for the one row
 * the top and bottom board borders share on a 24-row screen (msdos has 25).
 * The merged bitmaps are pre-built by mkchr.py; k is the PAIRS index.
 */
static void plotTilePair(unsigned char k, unsigned char add, unsigned char x, unsigned char y)
{
    put(x, y, pairTile[k], add ? PAL_ART : PAL_TEXT);
}

#define PAIR_CORNER_L_BOT 0 /* (0x08,0x0A) */
#define PAIR_CORNER_L_TOP 1 /* (0x0A,0x08) */
#define PAIR_EDGE_BOT 2     /* (0x27,0x29) */
#define PAIR_EDGE_TOP 3     /* (0x29,0x27) */
#define PAIR_CORNER_R_BOT 4 /* (0x09,0x0B) */
#define PAIR_CORNER_R_TOP 5 /* (0x0B,0x09) */

/**
 * @brief The font tile for c: the font is at its ASCII codes, upper case
 * only, and anything it lacks is a blank
 */
static unsigned char glyph(char c)
{
    if (c >= 'a' && c <= 'z')
        return (unsigned char)(c - ('a' - 'A'));
    if (c < ' ' || c >= 0x60)
        return T_BLANK;
    return (unsigned char)c;
}

/**
 * @brief plot name text on its plate. The font has no plate-coloured glyphs,
 * so the name is white text in a window cut into the plate, spaces included:
 * one run per name, however many words it has.
 */
static void plotName(unsigned char x, unsigned char y, const char *s)
{
    char c;

    while (c = *s++)
        put(x++, y, glyph(c), PAL_TEXT);
}

/**
 * @brief Clear screen to the blue field
 */
void resetScreen(void)
{
    mt_clear(T_BLANK);
}

/**
 * @brief cycle to next color palette
 */
unsigned char cycleNextColor()
{
    return 0;
}

/**
 * @brief Initialize Graphics mode
 */
void initGraphics()
{
    unsigned char hue;

    initInput();
    mt_init(T_BLANK);
    hue = mt_pal ? PAL_HUE : 0;
    mt_background(C_BLUE + hue);
    mt_palette(PAL_TEXT, C_WHITE, C_RED + hue, C_WHITE);
    mt_palette(PAL_ART, C_RED + hue, C_CYAN + hue, C_WHITE);
}

/**
 * @brief Reset graphics mode - nothing to reset, the cart never exits
 */
void resetGraphics(void)
{
}

/**
 * @brief Store screen buffer - the engine's map is the screen, so keep a copy
 */
bool saveScreenBuffer()
{
    memcpy(saved[0], mt_map, sizeof saved[0]);
    memcpy(saved[1], mt_attr, sizeof saved[1]);
    return true;
}

void restoreScreenBuffer()
{
    unsigned char x, y, n;
    unsigned int i = 0;

    for (y = 0; y < HEIGHT; y++, i += WIDTH)
    {
        mt_at(0, y);
        for (x = 0; x < WIDTH; x++)
            mt_put(saved[0][i + x] >> 1);

        // One setpal per run of a palette
        for (x = 0; x < WIDTH; x += n)
        {
            for (n = 1; x + n < WIDTH && saved[1][i + x + n] == saved[1][i + x]; n++)
                ;
            paint(x, y, n, saved[1][i + x]);
        }
    }
}

/**
 * @brief Text output, clipped at the screen edges. No wrap: the shared code
 * centres some strings wider than 32 columns, which start at x = 255.
 */
void drawText(unsigned char x, unsigned char y, const char *s)
{
    char c;
    while (c = *s++)
        put(x++, y, glyph(c), PAL_TEXT);
}

void drawTextAlt(unsigned char x, unsigned char y, const char *s)
{
    char c;
    while (c = *s++)
        put(x++, y, glyph(c), c >= 'A' && c <= 'Z' ? PAL_ART : PAL_TEXT);
}

/**
 * @brief draw icon (tile) from the msdos sheet
 */
void drawIcon(unsigned char x, unsigned char y, unsigned char icon)
{
    put(x, y, sheetTile[icon], sheetPal[icon]);
}

void drawBlank(unsigned char x, unsigned char y)
{
    put(x, y, T_BLANK, AGNOSTIC);
}

void drawSpace(unsigned char x, unsigned char y, unsigned char w)
{
    while (w--)
        put(x++, y, T_BLANK, AGNOSTIC);
}

void drawClock(void)
{
    drawIcon(WIDTH - 1, HEIGHT - 1, 0x1D);
}

void drawConnectionIcon(bool show)
{
    if (show)
    {
        drawIcon(0, HEIGHT - 1, 0x1E);
        drawIcon(1, HEIGHT - 1, 0x1F);
    }
    else
    {
        drawBlank(0, HEIGHT - 1);
        drawBlank(1, HEIGHT - 1);
    }
}

/**
 * @brief true when this player's board shares its middle border row (row 11)
 * with the board above/below it, which happens whenever that counterpart is
 * actually drawn
 */
static bool sharedBorderRow(unsigned char player)
{
    if (player == 0)
        return playerCount >= 2;
    if (player == 2)
        return playerCount == 4;
    return true; // 1 always has 0 below; 3 only exists in 4-player
}

/**
 * @brief Draw Player Name plate and board chrome
 */
void drawPlayerName(unsigned char player, const char *name, bool active)
{
    uint8_t x = quadrant_offset[player][0] - 1;
    uint8_t y = quadrant_offset[player][1] - 1;
    uint8_t add = active ? 0x00 : 0x80;
    uint8_t i = 0;
    bool shared = sharedBorderRow(player);

    x += fieldX;

    if (player == 0 || player == 3)
    {
        // Bottom player boards

        // Thin horizontal border (row 11, shared with the top board's lower
        // border when both are on screen - merge the two tile sets)
        if (shared)
        {
            plotTilePair(PAIR_CORNER_L_BOT, add, x, y);
            for (i = 1; i < 11; i++)
            {
                plotTilePair(PAIR_EDGE_BOT, add, x + i, y);
            }
            plotTilePair(PAIR_CORNER_R_BOT, add, x + 11, y);
        }
        else
        {
            drawIcon(x, y, 0x08 + add);
            for (i = 1; i < 11; i++)
            {
                drawIcon(x + i, y, 0x27 + add);
            }
            drawIcon(x + 11, y, 0x09 + add);
        }

        // Name label
        drawIcon(x, y + 11, 0x5E + add);
        for (i = 1; i < 11; i++)
        {
            drawIcon(x + i, y + 11, 0x60 + add);
        }
        drawIcon(x + 11, y + 11, 0x5F + add);
        plotName(x + 2, y + 11, name);

        // Active indicator
        if (active)
            drawIcon(x + 1, y + 11, 0x5B);

        // Bottom border below name label
        drawIcon(x, y + 12, 0x20 + add);
        for (i = 1; i < 11; i++)
        {
            drawIcon(x + i, y + 12, 0x28 + add);
        }
        drawIcon(x + 11, y + 12, 0x21 + add);
    }
    else
    {
        // Top player boards

        // Name label
        drawIcon(x, y, 0x5C + add);
        for (i = 1; i < 11; i++)
        {
            drawIcon(x + i, y, 0x60 + add);
        }
        drawIcon(x + 11, y, 0x5D + add);
        plotName(x + 2, y, name);

        // Active indicator
        if (active)
            drawIcon(x + 1, y, 0x5B);

        // Thin Horizontal Border (row 11, see above)
        if (shared)
        {
            plotTilePair(PAIR_CORNER_L_TOP, add, x, y + 11);
            for (i = 1; i < 11; i++)
            {
                plotTilePair(PAIR_EDGE_TOP, add, x + i, y + 11);
            }
            plotTilePair(PAIR_CORNER_R_TOP, add, x + 11, y + 11);
        }
        else
        {
            drawIcon(x, y + 11, 0x0A + add);
            for (i = 1; i < 11; i++)
            {
                drawIcon(x + i, y + 11, 0x29 + add);
            }
            drawIcon(x + 11, y + 11, 0x0B + add);
        }
    }

    // Draw left/right borders and drawers
    if (player > 1 || playerCount == 2 && player > 0)
    {
        // Right drawer
        // top
        drawIcon(x + 11, y + 1, 0x25 + add);
        drawIcon(x + 12, y + 1, 0x31 + add);
        drawIcon(x + 13, y + 1, 0x31 + add);
        drawIcon(x + 14, y + 1, 0x31 + add);
        drawIcon(x + 15, y + 1, 0x2D + add);
        drawIcon(x, y + 1, 0x22 + add);

        // Edges
        for (i = 0; i < 8; i++)
        {
            drawIcon(x + 11, y + 2 + i, 0x03 + add);
            drawIcon(x + 15, y + 2 + i, 0x02 + add);
            drawIcon(x, y + 2 + i, 0x22 + add);
        }

        // bottom
        drawIcon(x, y + 10, 0x22 + add);
        drawIcon(x + 11, y + 10, 0x25 + add);
        drawIcon(x + 12, y + 10, 0x31 + add);
        drawIcon(x + 13, y + 10, 0x31 + add);
        drawIcon(x + 14, y + 10, 0x31 + add);
        drawIcon(x + 15, y + 10, 0x2F + add);
    }
    else
    {
        // Left drawer
        drawIcon(x - 4, y + 1, 0x2C + add);
        drawIcon(x - 3, y + 1, 0x31 + add);
        drawIcon(x - 2, y + 1, 0x31 + add);
        drawIcon(x - 1, y + 1, 0x31 + add);
        drawIcon(x, y + 1, 0x24 + add);
        drawIcon(x + 11, y + 1, 0x23 + add);

        // Edges
        for (i = 0; i < 8; i++)
        {
            drawIcon(x - 4, y + 2 + i, 0x02 + add);
            drawIcon(x, y + 2 + i, 0x02 + add);
            drawIcon(x + 11, y + 2 + i, 0x23 + add);
        }

        drawIcon(x - 4, y + 10, 0x2E + add);
        drawIcon(x - 3, y + 10, 0x31 + add);
        drawIcon(x - 2, y + 10, 0x31 + add);
        drawIcon(x - 1, y + 10, 0x31 + add);
        drawIcon(x, y + 10, 0x24 + add);
        drawIcon(x + 11, y + 10, 0x23 + add);
    }
}

/**
 * @brief Draw the board
 */
void drawBoard(unsigned char currentPlayerCount)
{
    unsigned char i, j, x, y;
    playerCount = currentPlayerCount;

    fieldX = playerCount > 2 ? 0 : 6;

    for (i = 0; i < playerCount; i++)
    {
        // The field and its drawer only ever hold art: one palette, so the
        // blank sea between hits starts no runs.
        x = quadrant_offset[i][0] + fieldX;
        y = quadrant_offset[i][1];
        for (j = 0; j < 10; j++)
        {
            paint(x, y + j, 10, PAL_ART);
            if (j < 8)
                paint(i > 1 || (i > 0 && fieldX) ? x + 11 : x - 4, y + 1 + j, 3, PAL_ART);
        }

        drawPlayerName(i, "", false);
    }
}

/**
 * @brief draw a horizontal line of w characters at x,y
 */
void drawLine(unsigned char x, unsigned char y, unsigned char w)
{
    while (w--)
        drawIcon(x++, y, 0x3F);
}

/**
 * @brief draw ship, shared between a few routines
 */
static void drawShipInternal(unsigned char x, unsigned char y, unsigned char size, unsigned char delta)
{
    uint8_t c = delta ? 0x37 : 0x32;

    if (delta)
    {
        // Vertical
        drawIcon(x, y++, c--); // top

        while (size > 2) // middle
        {
            drawIcon(x, y++, c);
            size--;
        }

        c--; // bottom
        drawIcon(x, y++, c);
    }
    else
    {
        // Horizontal
        drawIcon(x++, y, c++); // Left

        while (size > 2) // middle
        {
            drawIcon(x++, y, c);
            size--;
        }

        c++; // Right
        drawIcon(x++, y, c);
    }
}

/**
 * @brief Draw ship at position on sea
 */
void drawShip(unsigned char quadrant, unsigned char size, unsigned char pos, bool hide)
{
    uint8_t delta = 0;
    uint8_t x = 0, y = 0, i = 0;

    if (pos > 99)
    {
        delta = 1;
        pos -= 100;
    }

    x = pos % 10;
    y = pos / 10;

    x += fieldX + quadrant_offset[quadrant][0];
    y += quadrant_offset[quadrant][1];

    if (hide)
    {
        if (!delta)
        {
            for (i = 0; i < size; i++)
            {
                drawIcon(x++, y, 0x38);
            }
        }
        else
        {
            for (i = 0; i < size; i++)
            {
                drawIcon(x, y++, 0x38);
            }
        }
    }
    else
    {
        drawShipInternal(x, y, size, delta);
    }
}

/**
 * @brief Draw a ship in the drawer
 */
void drawLegendShip(uint8_t player, uint8_t index, uint8_t size, uint8_t status)
{
    uint8_t i = 0;
    uint8_t x = quadrant_offset[player][0] + fieldX + legendShipOffset[index][0];
    uint8_t y = quadrant_offset[player][1] + legendShipOffset[index][1];

    if (player > 1 || (player > 0 && fieldX > 0))
    {
        y++;
        x += 11;
    }
    else
    {
        y++;
        x -= 4;
    }

    if (status)
    {
        drawShipInternal(x, y, size, 1); // draw a nice vertical ship
    }
    else
    {
        // Draw the red splats, instead
        for (i = 0; i < size; i++)
            drawIcon(x, y + i, 0x1C);
    }
}

/**
 * @brief Draw game field for given quadrant
 */
void drawGamefield(uint8_t quadrant, uint8_t *field)
{
    uint8_t ix = 0, iy = 0;
    uint8_t x = quadrant_offset[quadrant][0] + fieldX;
    uint8_t y = quadrant_offset[quadrant][1];

    for (iy = 0; iy < 10; iy++)
    {
        for (ix = 0; ix < 10; ix++)
        {
            if (*field)
            {
                drawIcon(x + ix, y + iy, *field == 1 ? 0x39 : 0xE1);
            }
            field++;
        }
    }
}

void drawGamefieldUpdate(uint8_t quadrant, uint8_t *gamefield, uint8_t attackPos, uint8_t anim)
{
    uint8_t x = quadrant_offset[quadrant][0] + fieldX + (attackPos % 10);
    uint8_t y = quadrant_offset[quadrant][1] + (attackPos / 10);
    uint8_t c = gamefield[attackPos];

    // Animate attack
    if (anim > 9)
    {
        drawIcon(x, y, 217 + anim);
        return;
    }

    if (c == FIELD_ATTACK)
    {
        drawIcon(x, y, anim ? 0x1B : 0x39);
    }
    else if (c == FIELD_MISS)
    {
        drawIcon(x, y, 0xE1);
    }
}

/**
 * @brief Draw game field cursor
 */
void drawGamefieldCursor(uint8_t quadrant, uint8_t x, uint8_t y, uint8_t *gamefield, uint8_t blink)
{
    unsigned char ex = quadrant_offset[quadrant][0] + fieldX + x;
    unsigned char ey = quadrant_offset[quadrant][1] + y;
    unsigned char pos = (y * 10) + x;
    unsigned char c;

    switch (gamefield[pos])
    {
    case FIELD_ATTACK:
        c = 0x43;
        break;
    case FIELD_MISS:
        c = 0x46;
        break;
    default:
        c = 0x40;
        break;
    }

    drawIcon(ex, ey, c + blink);
}

/**
 * @brief Draw end game message
 */
void drawEndgameMessage(const char *message)
{
    uint8_t i, x, ix;
    i = (uint8_t)strlen(message);
    x = WIDTH / 2 - i / 2;

    for (ix = 0; ix < WIDTH; ix++)
        drawIcon(ix, HEIGHT - 2, 0xE2);

    drawSpace(0, HEIGHT - 1, WIDTH);
    drawText(x, HEIGHT - 1, message);
}

/**
 * @brief Draw a box
 */
void drawBox(unsigned char x, unsigned char y, unsigned char w, unsigned char h)
{
    drawIcon(x, y, 0x3B);
    drawIcon(x + w + 1, y, 0x3C);
    drawIcon(x, y + h + 1, 0x3D);
    drawIcon(x + w + 1, y + h + 1, 0x3E);
}

#endif /* BUILD_ATARI7800 */
