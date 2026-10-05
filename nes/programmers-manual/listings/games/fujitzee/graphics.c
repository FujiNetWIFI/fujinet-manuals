#ifdef BUILD_NES

/*
  Graphics functionality - NES PPU

  One background layer: the game's 32x25 cells are nametable rows ROW0 on,
  so the picture sits inside a CRT's overscan. The art is the MS-DOS
  client's CGA sheet, converted tile for tile by src/nes/mkchr.py, and the
  drawing is the MS-DOS client's (src/msdos/graphics.c) on the Adam's 32
  column grid: the MS-DOS board shifted eight cells left lands exactly on the
  Adam's columns, and the MS-DOS 25 rows fit the NES with room to spare.

  The write path is fujinet-battleship's src/nes/graphics.c. The PPU can only
  be written in vblank, so a cell goes into a RAM shadow of the nametable
  and, if it changed, into cc65's NMI-flushed ring buffer (ppu.s). The shadow
  is also what saveScreenBuffer() keeps, and what the whole-screen operations
  (resetScreen, drawBoard, restoreScreenBuffer) copy in one go with rendering
  switched off -- 800 cells through a ring that drains about 70 a frame would
  take a visible half second.

  Two things the MS-DOS client does pixel by pixel are done by the NES
  hardware instead:
    - the active player's column turns its blue background black: that
      column is exactly one attribute-byte column wide, and background
      palette 1 is palette 0 with blue made black (mkchr.py puts blue on its
      own pixel value for this).
    - the dice cursor, a checkerboard frame one pixel outside the die, is
      twelve sprites, so drawing and hiding it never touches the nametable.
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
#define OAM_ADDR   (*(volatile unsigned char *) 0x2003)
#define PPU_SCROLL (*(volatile unsigned char *) 0x2005)
#define PPU_ADDR   (*(volatile unsigned char *) 0x2006)
#define PPU_DATA   (*(volatile unsigned char *) 0x2007)
#define OAM_DMA    (*(volatile unsigned char *) 0x4014)

#define CTRL_ON    0x98 /* NMI on; background and sprite tiles from $1000 (CHARS1) */
#define CTRL_OFF   0x18 /* the same with NMI off */
#define MASK_ON    0x1E /* background and sprites on, left column shown */

#define NT_BASE    0x2000
#define AT_BASE    0x23C0
#define ROW0       3    /* game row 0 is nametable row 3: 25 rows inside 30 */

/* The MS-DOS client's CGA palette (blue table, cyan, black, white), with
   black as the universal colour -- see mkchr.py. */
#define PAL_BLACK  0x0F
#define PAL_BLUE   0x02
#define PAL_CYAN   0x2C
#define PAL_WHITE  0x30

void __fastcall__ ppu_put(unsigned int addr, unsigned char val); /* ppu.s */
void ppu_drain(void);                                             /* ppu.s */

unsigned char colorMode = 0;

/* What each cell shows, as a tile number, and the copy saveScreenBuffer()
   keeps. Both live in the cartridge's WRAM with the rest of BSS. */
static unsigned char shadow[HEIGHT][WIDTH];
static unsigned char saved[HEIGHT][WIDTH];

/* The attribute table, likewise. */
static unsigned char attr[64];
static unsigned char savedAttr[64];

/* While set, cells only go to the shadow; the caller blits it whole. */
static bool batch;

/* Set by drawBoard: the logo's first cell carries the score-box border. */
static bool boardDrawn;

static int8_t highlightX = -1;
static int8_t savedHighlightX = -1;

/* The sprite page, DMA'd to OAM. Its own segment at the top of the
   cartridge WRAM (src/nes/nes.cfg), because OAM DMA wants a whole page. */
#pragma bss-name(push, "OAM")
static unsigned char oam[256];
#pragma bss-name(pop)

static bool cursorActive, savedCursorActive;
static unsigned char cursorX, savedCursorX;

/* Atari-derived dice/roll-button tile layout: the MS-DOS client's table,
   whose glyph numbers sheetTile[] maps. */
static const unsigned char diceChars[] = {
    /* Normal (white) dice */
    0x41,0x40,0x42, 0x40,0x45,0x40, 0x43,0x40,0x44,
    0x41,0x40,0x47, 0x40,0x40,0x40, 0x48,0x40,0x44,
    0x41,0x40,0x47, 0x40,0x45,0x40, 0x48,0x40,0x44,
    0x46,0x40,0x47, 0x40,0x40,0x40, 0x48,0x40,0x49,
    0x46,0x40,0x47, 0x40,0x45,0x40, 0x48,0x40,0x49,
    0x46,0x40,0x47, 0x4A,0x40,0x4B, 0x48,0x40,0x49,

    /* Kept (selected/locked) dice */
    0x21,0x4C,0x22, 0x20,0x25,0x20, 0x23,0x4D,0x24,
    0x21,0x4C,0x27, 0x20,0x20,0x20, 0x28,0x4D,0x24,
    0x21,0x4C,0x27, 0x20,0x25,0x20, 0x28,0x4D,0x24,
    0x26,0x4C,0x27, 0x20,0x20,0x20, 0x28,0x4D,0x29,
    0x26,0x4C,0x27, 0x20,0x25,0x20, 0x28,0x4D,0x29,
    0x26,0x4C,0x27, 0x2A,0x20,0x2B, 0x28,0x4D,0x29,

    /* 13 - empty space (Roll button background) */
    0x00,0x00,0x00, 0x00,0x00,0x00, 0x00,0x00,0x00,

    /* 14 - "Roll" button: 1 roll left */
    0x41,0x40,0x42, 0x2C,0x2D,0x2E, 0x43,0x30,0x44,
    /* 15 - "Roll" button: 2 rolls left */
    0x41,0x40,0x42, 0x2C,0x2D,0x2E, 0x43,0x2F,0x44,
    /* 16 - "Roll" button: cannot roll */
    0x41,0x40,0x42, 0x2C,0x2D,0x2E, 0x43,0x50,0x44,

    /* 17-19 - Roll button pushed (alt color) */
    0xC1,0xC0,0xC2, 0xAC,0xAD,0xAE, 0xC3,0xB0,0xC4,
    0xC1,0xC0,0xC2, 0xAC,0xAD,0xAE, 0xC3,0xAF,0xC4,
    0xC1,0xC0,0xC2, 0xAC,0xAD,0xAE, 0xC3,0xD0,0xC4,

    /* Highlighted dice (alt color) */
    0xC1,0xC0,0xC2, 0xC0,0xC5,0xC0, 0xC3,0xC0,0xC4,
    0xC1,0xC0,0xC7, 0xC0,0xC0,0xC0, 0xC8,0xC0,0xC4,
    0xC1,0xC0,0xC7, 0xC0,0xC5,0xC0, 0xC8,0xC0,0xC4,
    0xC6,0xC0,0xC7, 0xC0,0xC0,0xC0, 0xC8,0xC0,0xC9,
    0xC6,0xC0,0xC7, 0xC0,0xC5,0xC0, 0xC8,0xC0,0xC9,
    0xC6,0xC0,0xC7, 0xCA,0xC0,0xCB, 0xC8,0xC0,0xC9,

    /* Highlighted kept dice (alt color) */
    0xA1,0xCC,0xA2, 0xA0,0xA5,0xA0, 0xA3,0xCD,0xA4,
    0xA1,0xCC,0xA7, 0xA0,0xA0,0xA0, 0xA8,0xCD,0xA4,
    0xA1,0xCC,0xA7, 0xA0,0xA5,0xA0, 0xA8,0xCD,0xA4,
    0xA6,0xCC,0xA7, 0xA0,0xA0,0xA0, 0xA8,0xCD,0xA9,
    0xA6,0xCC,0xA7, 0xA0,0xA5,0xA0, 0xA8,0xCD,0xA9,
    0xA6,0xCC,0xA7, 0xAA,0xA0,0xAB, 0xA8,0xCD,0xA9
};

/**
 * @brief put tile t at column x, row y - queued only if the cell changes
 */
static void put(unsigned char x, unsigned char y, unsigned char t)
{
    if (x >= WIDTH || y >= HEIGHT || shadow[y][x] == t)
        return;

    shadow[y][x] = t;
    if (!batch)
        ppu_put(NT_BASE + ((unsigned int)(y + ROW0) << 5) + x, t);
}

/**
 * @brief plot MS-DOS glyph g, as MS-DOS plot_glyph() with MASK_WHITE
 */
static void glyph(unsigned char x, unsigned char y, unsigned char g)
{
    put(x, y, sheetTile[g]);
}

/**
 * @brief DMA the sprite page to OAM. Must run inside vblank: the ring is
 * drained first, so the NMI that waitvsync() waits for has nothing to flush
 * and returns with most of the vblank left.
 */
static void oamFlush(void)
{
    ppu_drain();
    waitvsync();
    OAM_ADDR = 0;
    OAM_DMA = (unsigned char)((unsigned int)oam >> 8);
}

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

    PPU_ADDR = (unsigned char)(AT_BASE >> 8);
    PPU_ADDR = (unsigned char)AT_BASE;
    for (x = 0; x < 64; x++)
        PPU_DATA = attr[x];

    // Back on at the top of a frame, so the picture never starts mid-screen.
    // OAM is refreshed there too: it fades while rendering is off.
    while (!(PPU_STATUS & 0x80))
        ;
    OAM_ADDR = 0;
    OAM_DMA = (unsigned char)((unsigned int)oam >> 8);
    PPU_ADDR = 0;
    PPU_ADDR = 0;
    PPU_SCROLL = 0;
    PPU_SCROLL = 0;
    PPU_CTRL = CTRL_ON;
    PPU_MASK = MASK_ON;
}

/* ---- Active player column: attribute palette 1 ---- */

/* The column of player p is cells SCORES_X+6+p*4 .. +3: exactly attribute
   column 2+p. Its game rows 1-20 are nametable rows 4-23, attribute rows
   1-5; the board's top edge (game row 0) shares attribute row 0 with the
   blank row above it and stays blue, as it would be black above the board. */
static void columnAttr(int8_t player, unsigned char value)
{
    unsigned char r, i;

    if (player < 0)
        return;

    for (r = 1; r <= 5; r++)
    {
        i = (r << 3) + 2 + player;
        if (attr[i] != value)
        {
            attr[i] = value;
            if (!batch)
                ppu_put(AT_BASE + i, value);
        }
    }
}

void setHighlight(int8_t player, bool isThisPlayer, uint8_t flash)
{
    (void)isThisPlayer;
    (void)flash;

    if (highlightX != player)
    {
        columnAttr(highlightX, 0x00);
        highlightX = player;
    }
    columnAttr(player, 0x55);
}

/* ---- Dice cursor: sprites ---- */

static void placeCursor(unsigned char x)
{
    unsigned char i, *o = oam;
    const unsigned char *s = cursorSprite;

    for (i = 0; i < CURSOR_SPRITES; i++)
    {
        // OAM Y is the line above the sprite's first one
        o[0] = ((ROW0 + HEIGHT - 4) << 3) - 4 + (s[1] << 3) - 1;
        o[1] = s[2];
        o[2] = 0;
        o[3] = (x << 3) - 4 + (s[0] << 3);
        o += 4;
        s += 3;
    }
}

static void clearOam(void)
{
    memset(oam, 0xFF, sizeof oam);
}

void drawDiceCursor(unsigned char x)
{
    cursorX = x;
    cursorActive = true;
    placeCursor(x);
    oamFlush();
}

void hideDiceCursor(unsigned char x)
{
    (void)x;
    if (!cursorActive)
        return;
    cursorActive = false;
    clearOam();
    oamFlush();
}

/* ---- Screen ---- */

uint8_t cycleNextColor()
{
    return 0;
}

void setColorMode()
{
}

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

    // Background palette 0 is the CGA set; palette 1 makes blue black (the
    // active column). Sprite palette 0 is mkchr.py's cursor numbering.
    PPU_ADDR = 0x3F;
    PPU_ADDR = 0x00;
    PPU_DATA = PAL_BLACK;
    PPU_DATA = PAL_BLUE;
    PPU_DATA = PAL_CYAN;
    PPU_DATA = PAL_WHITE;
    PPU_DATA = PAL_BLACK;
    PPU_DATA = PAL_BLACK;
    PPU_DATA = PAL_CYAN;
    PPU_DATA = PAL_WHITE;
    for (i = 0; i < 8; i++)
        PPU_DATA = PAL_BLACK;
    PPU_DATA = PAL_BLACK;
    PPU_DATA = PAL_CYAN;
    PPU_DATA = PAL_BLACK;
    PPU_DATA = PAL_WHITE;
    for (i = 0; i < 12; i++)
        PPU_DATA = PAL_BLACK;

    // Nametable 0: blue field, overscan rows included; attributes all
    // palette 0.
    PPU_ADDR = 0x20;
    PPU_ADDR = 0x00;
    for (i = 0; i < 960; i++)
        PPU_DATA = T_BLANK;
    for (i = 0; i < 64; i++)
        PPU_DATA = 0;

    memset(shadow, T_BLANK, sizeof shadow);
    memset(attr, 0, sizeof attr);
    clearOam();

    PPU_ADDR = 0;
    PPU_ADDR = 0;
    PPU_SCROLL = 0;
    PPU_SCROLL = 0;
    PPU_CTRL = CTRL_ON;
    PPU_MASK = MASK_ON;
    oamFlush();
}

void resetGraphics()
{
}

void resetScreen(bool forBorderScreen)
{
    unsigned char y;

    cursorActive = false;
    clearOam();
    highlightX = -1;
    memset(attr, 0, sizeof attr);
    boardDrawn = false;

    if (!forBorderScreen)
        memset(shadow, T_BLANK, sizeof shadow);
    else
    {
        // Moving between bordered screens: clear everything except the
        // corner dice.
        for (y = 0; y < HEIGHT; y++)
        {
            if (y < 3 || y >= HEIGHT - 3)
                memset(&shadow[y][3], T_BLANK, WIDTH - 6);
            else
                memset(shadow[y], T_BLANK, WIDTH);
        }
    }
    blitShadow();
}

bool saveScreenBuffer()
{
    memcpy(saved, shadow, sizeof saved);
    memcpy(savedAttr, attr, sizeof savedAttr);
    savedHighlightX = highlightX;
    savedCursorActive = cursorActive;
    savedCursorX = cursorX;
    return true;
}

void restoreScreenBuffer()
{
    memcpy(shadow, saved, sizeof shadow);
    memcpy(attr, savedAttr, sizeof attr);
    highlightX = savedHighlightX;
    cursorActive = savedCursorActive;
    cursorX = savedCursorX;
    if (cursorActive)
        placeCursor(cursorX);
    else
        clearOam();
    blitShadow();
}

/**
 * @brief Text, clipped at the right edge. No wrap: the shared code centres
 * some strings wider than 32 columns, which start at x = 255 - a wrap would
 * carry them onto the row below.
 *
 * As MS-DOS drawText: ASCII 32-64 are glyphs 0-32. Upper case, which MS-DOS
 * leaves on its art glyphs, folds onto the lower-case letters.
 */
void drawText(unsigned char x, unsigned char y, char *s)
{
    unsigned char c;

    if (x >= WIDTH)
        x = 0;
    while ((c = (unsigned char)*s++) && x < WIDTH)
    {
        if (c >= 32 && c < 65)
            c -= 32;
        else if (c >= 'A' && c <= 'Z')
            c += 32;
        glyph(x++, y, c);
    }
}

/**
 * @brief As MS-DOS drawTextAlt: upper case is drawn as the plain (white)
 * lower-case letter; lower case, digits and punctuation in cyan.
 */
void drawTextAlt(unsigned char x, unsigned char y, char *s)
{
    unsigned char c;

    if (x >= WIDTH)
        x = 0;
    while ((c = (unsigned char)*s++) && x < WIDTH)
    {
        if (c >= 32 && c < 65)
            c -= 32;
        if (c >= 'A' && c <= 'Z')
            glyph(x++, y, c + 32);
        else
            put(x++, y, c < 128 ? altTile[c] : sheetTile[c]);
    }
}

void drawChar(unsigned char x, unsigned char y, char c, unsigned char alt)
{
    unsigned char ch = (unsigned char)c;

    if (ch >= 32 && ch < 65)
        ch -= 32;
    if (ch >= 'A' && ch <= 'Z')
        ch += 32;
    put(x, y, alt && ch < 128 ? altTile[ch] : sheetTile[ch]);
}

void drawIcon(unsigned char x, unsigned char y, unsigned char icon)
{
    glyph(x, y, icon);
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

void drawClock(unsigned char x, unsigned char y)
{
    glyph(x, y, 0x37);
}

void drawConnectionIcon(unsigned char x, unsigned char y)
{
    glyph(x, y, 0x03);
    glyph(x + 1, y, 0x04);
}

/**
 * @brief The six-cell "fujiTZEE" logo, 0x38-0x3D, starting one cell left of
 * x. Its first cell carries the score-name box's left border; away from the
 * board that border is left off, as MS-DOS erases it.
 */
void drawFujitzee(unsigned char x, unsigned char y)
{
    unsigned char i;

    put(x - 1, y, boardDrawn ? sheetTile[0x38] : T_LOGO_NOBAR);
    for (i = 1; i < 6; i++)
        glyph(x - 1 + i, y, 0x38 + i);
}

void drawLine(unsigned char x, unsigned char y, unsigned char w)
{
    while (w--)
        glyph(x++, y, 0x52);
}

void drawBox(unsigned char x, unsigned char y, unsigned char w, unsigned char h)
{
    unsigned char i;

    glyph(x, y, 0x51);
    for (i = 0; i < w; i++)
        glyph(x + 1 + i, y, 0x52);
    glyph(x + w + 1, y, 0x55);

    for (i = 0; i < h; i++)
    {
        glyph(x, y + 1 + i, 0x7C);
        glyph(x + w + 1, y + 1 + i, 0x7C);
    }

    glyph(x, y + h + 1, 0x57);
    for (i = 0; i < w; i++)
        glyph(x + 1 + i, y + h + 1, 0x52);
    glyph(x + w + 1, y + h + 1, 0x5A);
}

void drawDie(unsigned char x, unsigned char y, unsigned char s, bool isSelected, bool isHighlighted)
{
    const unsigned char *src;
    unsigned char r, c;

    // Invalid index, or the bottom border-screen corners the Adam and CoCo
    // also skip: the status line at HEIGHT-1 runs under those columns.
    if (!s || s > 16 || y == HEIGHT - 3)
        return;

    src = diceChars + (s - 1) * 9;
    if (isSelected)
        src += 54;
    if (isHighlighted)
        src += (s < 14) ? 171 : 27;

    for (r = 0; r < 3; r++)
        for (c = 0; c < 3; c++)
            glyph(x + c, y + r, *src++);
}

/*
  The MS-DOS drawBoard, shifted left by BX = 10-SCORES_X cells: the score-name
  box's left edge goes from column 9 to 1 and the right-hand edge from 39 to
  31, the last column of the 32.
*/
#define BX (10 - SCORES_X)

void drawBoard()
{
    unsigned char x, y;

    batch = true;

    /* Thin horizontal rules (0x54). */
    for (x = 9 - BX; x < 40 - BX; x++)
        glyph(x, 9, 0x54);
    for (x = 10 - BX; x < 40 - BX; x++)
        glyph(x, 12, 0x54);

    /* Thick horizontal rules (0x52). */
    for (x = 16 - BX; x < 40 - BX; x++)
        glyph(x, 0, 0x52);
    for (x = 10 - BX; x < 40 - BX; x++)
    {
        glyph(x, 2, 0x52);
        glyph(x, 20, 0x52);
    }

    /* Score-name box. */
    drawBox(9 - BX, 2, 5, 17);

    /* Player column dividers; row 0 uses the upper tee. */
    for (y = 0; y < 20; y++)
        for (x = 15 - BX; x <= 39 - BX; x += 4)
            glyph(x, y, y == 0 ? 0x5B : 0x7C);

    /* Crosses and tees where the rules meet the dividers. */
    glyph(9 - BX, 9, 0x53);
    glyph(9 - BX, 12, 0x53);
    for (x = 15 - BX; x <= 39 - BX; x += 4)
    {
        glyph(x, 2, 0x50);
        glyph(x, 9, 0x4F);
        glyph(x, 12, 0x4F);
        glyph(x, 20, 0x58);
    }

    /* Corners and right-hand tees. */
    glyph(15 - BX, 0, 0x51);
    glyph(39 - BX, 0, 0x55);
    glyph(39 - BX, 2, 0x60);
    glyph(39 - BX, 9, 0x5F);
    glyph(39 - BX, 12, 0x5F);
    glyph(39 - BX, 20, 0x5A);

    /* Score-row labels. */
    for (y = 0; y < 14; y++)
        drawTextAlt(SCORES_X, scoreY[y], scores[y]);

    boardDrawn = true;
    drawFujitzee(SCORES_X, scoreY[14]);

    batch = false;
    blitShadow();
}

void clearBelowBoard()
{
    unsigned char y;

    hideDiceCursor(0);
    for (y = HEIGHT - 4; y < HEIGHT; y++)
        drawSpace(0, y, WIDTH);
}

#endif /* BUILD_NES */
