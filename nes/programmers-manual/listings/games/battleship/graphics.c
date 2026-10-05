#ifdef BUILD_NES

/*
  Graphics functionality - NES PPU

  One background layer, 32x24 cells of the 32x30 nametable, drawn from row
  ROW0 so the game sits inside a CRT's overscan. The art is the MS-DOS
  client's CGA sheet, converted tile for tile by src/nes/mkchr.py: CGA's four
  colours are one NES palette, so every cell uses palette 0 and no attribute
  byte is ever written after initGraphics().

  The layout and the drawing calls are the ColecoVision port's
  (src/coleco/graphics.c) -- the same 32x24 screen. The difference is the
  write path: the PPU can only be written in vblank, so a cell goes into a RAM
  shadow of the nametable and, if it changed, into cc65's NMI-flushed ring
  buffer (ppu.s). The shadow is also what saveScreenBuffer() keeps, and what
  the two whole-screen operations (resetScreen, restoreScreenBuffer) copy in
  one go with rendering switched off -- 768 cells through a ring that drains
  about 70 a frame would take a visible third of a second.
*/

#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <joystick.h>
#include "vars.h"
#include "tiles.h"
#include "../misc.h"

#define PPU_CTRL   (*(volatile unsigned char *) 0x2000)
#define PPU_MASK   (*(volatile unsigned char *) 0x2001)
#define PPU_STATUS (*(volatile unsigned char *) 0x2002)
#define PPU_SCROLL (*(volatile unsigned char *) 0x2005)
#define PPU_ADDR   (*(volatile unsigned char *) 0x2006)
#define PPU_DATA   (*(volatile unsigned char *) 0x2007)

#define CTRL_ON    0x90 /* NMI on; background tiles from $1000 (CHARS1) */
#define CTRL_OFF   0x10 /* the same with NMI off */
#define MASK_ON    0x0A /* background on, left column shown, no sprites */

#define NT_BASE    0x2000
#define ROW0       3    /* game row 0 is nametable row 3: 24 rows centred in 30 */

/* CGA palette 1, high intensity, the MS-DOS client's: blue field, cyan,
   red, white. */
#define PAL_BLUE   0x02
#define PAL_CYAN   0x2C
#define PAL_RED    0x26
#define PAL_WHITE  0x30

void __fastcall__ ppu_put(unsigned int addr, unsigned char val); /* ppu.s */
void ppu_drain(void);                                             /* ppu.s */

/* What each cell shows, as a tile number, and the copy saveScreenBuffer()
   keeps. Both live in the cartridge's WRAM with the rest of BSS. */
static unsigned char shadow[HEIGHT][WIDTH];
static unsigned char saved[HEIGHT][WIDTH];

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
 * @brief put tile t at column x, row y - queued only if the cell changes
 */
static void put(unsigned char x, unsigned char y, unsigned char t)
{
    if (x >= WIDTH || y >= HEIGHT || shadow[y][x] == t)
        return;

    shadow[y][x] = t;
    ppu_put(NT_BASE + ((unsigned int)(y + ROW0) << 5) + x, t);
}

/**
 * @brief Copy the whole shadow to the nametable with rendering off.
 * The ring is drained first (it would otherwise land stale cells afterwards),
 * and NMI is held off for the duration: its flush and scroll reset write
 * $2006 too, and would move the address out from under the copy.
 */
static void blitShadow(void)
{
    unsigned char x, y;

    ppu_drain();
    waitvsync();
    PPU_CTRL = CTRL_OFF;
    PPU_MASK = 0;

    PPU_ADDR = (unsigned char)((NT_BASE + (ROW0 << 5)) >> 8);
    PPU_ADDR = (unsigned char)(NT_BASE + (ROW0 << 5));
    for (y = 0; y < HEIGHT; y++)
        for (x = 0; x < WIDTH; x++)
            PPU_DATA = shadow[y][x];

    // Back on at the top of a frame, so the picture never starts mid-screen.
    while (!(PPU_STATUS & 0x80))
        ;
    PPU_ADDR = 0;
    PPU_ADDR = 0;
    PPU_SCROLL = 0;
    PPU_SCROLL = 0;
    PPU_CTRL = CTRL_ON;
    PPU_MASK = MASK_ON;
}

/**
 * @brief plot two sheet tiles merged at column x, row y. Used for the one row
 * the top and bottom board borders share on a 24-row screen (msdos has 25).
 * The merged bitmaps are pre-built by mkchr.py; k is the PAIRS index.
 */
static void plotTilePair(unsigned char k, unsigned char add, unsigned char x, unsigned char y)
{
    put(x, y, pairTile[(add ? 6 : 0) + k]);
}

#define PAIR_CORNER_L_BOT 0 /* (0x08,0x0A) */
#define PAIR_CORNER_L_TOP 1 /* (0x0A,0x08) */
#define PAIR_EDGE_BOT 2     /* (0x27,0x29) */
#define PAIR_EDGE_TOP 3     /* (0x29,0x27) */
#define PAIR_CORNER_R_BOT 4 /* (0x09,0x0B) */
#define PAIR_CORNER_R_TOP 5 /* (0x0B,0x09) */

/**
 * @brief plot char c in the white text font
 */
static void plotChar(unsigned char x, unsigned char y, char c)
{
    unsigned char g = (unsigned char)c - 0x20;

    put(x, y, g < 96 ? fontTile[g] : T_BLANK);
}

/**
 * @brief plot name text on its plate: white on red for the active player,
 * blue on cyan for the rest. Anything without a glyph shows as plate.
 */
static void plotName(unsigned char x, unsigned char y, bool active, const char *s)
{
    static const char nameChars[] = NAME_CHARS;
    unsigned char base = active ? T_NAME_ON : T_NAME_OFF;
    unsigned char plate = sheetTile[active ? 0x60 : 0xE0];
    const char *p;
    char c;

    while (c = *s++)
    {
        if (c >= 'a' && c <= 'z')
            c -= 'a' - 'A';

        p = c > ' ' ? strchr(nameChars, c) : NULL;
        put(x++, y, p ? base + (unsigned char)(p - nameChars) : plate);
    }
}

/**
 * @brief Clear screen to the blue field
 */
void resetScreen(void)
{
    memset(shadow, T_BLANK, sizeof shadow);
    blitShadow();
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
    unsigned int i;

    joy_install(joy_static_stddrv);

    // PPU warm-up: two vblanks with rendering off before touching VRAM.
    PPU_CTRL = 0;
    PPU_MASK = 0;
    while (!(PPU_STATUS & 0x80))
        ;
    while (!(PPU_STATUS & 0x80))
        ;

    // Every palette the same; only background palette 0 is ever used.
    PPU_ADDR = 0x3F;
    PPU_ADDR = 0x00;
    for (i = 0; i < 8; i++)
    {
        PPU_DATA = PAL_BLUE;
        PPU_DATA = PAL_CYAN;
        PPU_DATA = PAL_RED;
        PPU_DATA = PAL_WHITE;
    }

    // Nametable 0: blank field, overscan rows included; attributes all
    // palette 0.
    PPU_ADDR = 0x20;
    PPU_ADDR = 0x00;
    for (i = 0; i < 960; i++)
        PPU_DATA = T_BLANK;
    for (i = 0; i < 64; i++)
        PPU_DATA = 0;

    memset(shadow, T_BLANK, sizeof shadow);

    PPU_ADDR = 0;
    PPU_ADDR = 0;
    PPU_SCROLL = 0;
    PPU_SCROLL = 0;
    PPU_CTRL = CTRL_ON;
    PPU_MASK = MASK_ON;
    waitvsync();
}

/**
 * @brief Reset graphics mode - nothing to reset, the cart never exits
 */
void resetGraphics(void)
{
}

/**
 * @brief Store screen buffer - the shadow is the screen, so keep a copy
 */
bool saveScreenBuffer()
{
    memcpy(saved, shadow, sizeof saved);
    return true;
}

void restoreScreenBuffer()
{
    memcpy(shadow, saved, sizeof shadow);
    blitShadow();
}

/**
 * @brief Text output, clipped at the screen edges. No wrap: the shared code
 * centres some strings wider than 32 columns, which start at x = 255 - a wrap
 * would carry them onto the row below.
 */
void drawText(unsigned char x, unsigned char y, const char *s)
{
    char c;
    while (c = *s++)
        plotChar(x++, y, c);
}

void drawTextAlt(unsigned char x, unsigned char y, const char *s)
{
    char c;
    while (c = *s++)
    {
        if (c >= 'A' && c <= 'Z')
            put(x++, y, T_ALT_A + (c - 'A'));
        else
            plotChar(x++, y, c);
    }
}

/**
 * @brief draw icon (tile) from the msdos sheet
 */
void drawIcon(unsigned char x, unsigned char y, unsigned char icon)
{
    put(x, y, sheetTile[icon]);
}

void drawBlank(unsigned char x, unsigned char y)
{
    put(x, y, T_BLANK);
}

void drawSpace(unsigned char x, unsigned char y, unsigned char w)
{
    while (w--)
        put(x++, y, T_BLANK);
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
        plotName(x + 2, y + 11, active, name);

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
        plotName(x + 2, y, active, name);

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
    unsigned char i;
    playerCount = currentPlayerCount;

    fieldX = playerCount > 2 ? 0 : 6;

    for (i = 0; i < playerCount; i++)
    {
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

#endif /* BUILD_NES */
