#ifdef BUILD_ATARI5200

/**
 * @brief   Atari 5200 Graphics Routines for 5cardstud
 * @author  Thomas Cherryhomes
 * @email   thom dot cherryhomes at gmail dot com
 * @license gpl v. 3, see LICENSE for details
 * @verbose The 8-bit client's screen (atari-fastbasic-version/5card.bas):
 *          ANTIC mode 4 in its font, felt and status-bar colours from a DLI,
 *          black player sidebars round the table, player 1 darkening the
 *          hole card and player 2 underlining the active name or move.
 *          Everything draws to the work screen; with double buffering on,
 *          the front copy is shown until drawBuffer(), and the display list,
 *          the hole-card mask and the underline change with it.
 */

#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include "vars.h"
#include "../platform-specific/graphics.h"
#include "../platform-specific/sound.h"

#define REG(a)  (*(volatile unsigned char *)(a))

/* The BIOS's shadows, which the crt0's VBI copies to the chips. */
#define RTCLOKH REG(0x01)
#define RTCLOKL REG(0x02)
#define CRITIC  REG(0x03)
#define ATRACT  REG(0x04)
#define SDLSTL  REG(0x05)
#define SDLSTH  REG(0x06)
#define SDMCTL  REG(0x07)
#define PCOLR0  REG(0x08)
#define PCOLR1  REG(0x09)
#define PCOLR2  REG(0x0A)
#define PCOLR3  REG(0x0B)
#define COLOR0  REG(0x0C)
#define COLOR1  REG(0x0D)
#define COLOR2  REG(0x0E)
#define COLOR3  REG(0x0F)
#define COLOR4  REG(0x10)
#define VVBLKD  (*(void (**)(void))0x0204)
#define VDSLST  (*(void (**)(void))0x0206)

/* No shadows: written once. */
#define HPOSP0  REG(0xC000)
#define HPOSP1  REG(0xC001)
#define HPOSP2  REG(0xC002)
#define HPOSP3  REG(0xC003)
#define SIZEP0  REG(0xC008)
#define SIZEP1  REG(0xC009)
#define SIZEP2  REG(0xC00A)
#define SIZEP3  REG(0xC00B)
#define GTIAPAL REG(0xC014)
#define PRIOR   REG(0xC01B)
#define GRACTL  REG(0xC01D)
#define PMBASE  REG(0xD407)
#define CHBASE  REG(0xD409)

/* antic.s */
extern unsigned char scrWork[], scrFront[], pmBase[];
extern const unsigned char dlFrontNorm[], dlFrontTall[], dlWorkNorm[], dlWorkTall[];
extern const unsigned char fcsFont[];
extern unsigned char dliBg[3], dliFg[3];
extern unsigned char barHpos, barTarget;
void fcsDli(void);
void fcsVbi(void);

#define SCREEN_SIZE (WIDTH * HEIGHT)
#define STATUS_ROW  (HEIGHT - 1)
#define TALL_ROW    (HEIGHT - 2)

#define P0 (pmBase + 0x400)
#define P1 (pmBase + 0x500)
#define P2 (pmBase + 0x600)
#define P3 (pmBase + 0x700)

/* Horizontal position of column 0, and the scan line of row 0. */
#define LEFT_EDGE 48
#define TOP_LINE  19
#define STATUS_BAR_LINE 232     /* just under the status row's text */

/* Glyphs in the font, as ANTIC internal codes; +$80 draws "11" in red. */
#define G_BLANK   0
#define G_CHIP    0xEF
#define G_BOX_TL  27
#define G_BOX_TR  28
#define G_BOX_BL  29
#define G_BOX_BR  30
#define G_BOX_V   31
#define G_BOX_H   32
#define G_CLOCK   0x7A
#define G_RED     0x80

/* Colours. Each theme is the felt and the card edges (5card.bas). */
#define C_BLACK      0x00
#define C_WHITE      0x0E
#define C_MASK       0x0A
#define C_CURSOR     0xFA
#define C_RED_NTSC   0x34
#define C_RED_PAL    0x24
#define C_MOVE_NTSC  0xFE
#define C_MOVE_PAL   0xEE
#define THEMES       4

static const unsigned char themeNtsc[THEMES * 2] = { 0xB4,0x88, 0x84,0x08, 0x22,0x28, 0x04,0x08 };
static const unsigned char themePal[THEMES * 2]  = { 0xA4,0x78, 0x74,0x08, 0x12,0x18, 0x04,0x08 };

static const unsigned int rowOff[HEIGHT] = {
    0, 40, 80, 120, 160, 200, 240, 280, 320, 360, 400, 440, 480,
    520, 560, 600, 640, 680, 720, 760, 800, 840, 880, 920, 960, 1000
};

#define CELL(x, y) (scrWork + rowOff[y] + (x))

bool always_render_full_cards = 0;

static unsigned char theme;
static bool pal;
static bool dbl;                /* the front copy is shown while drawing */
static bool tall;               /* rows 24 and 25 are the status bar */

static unsigned char maskX, maskY;  /* the hole card under player 1 */
static bool maskWanted, maskDirty;
#define MASK_LINES 26
static unsigned char *maskBuilt;    /* the player 1 lines last written */

#define NO_BAR 0xFF
static unsigned char barRow = NO_BAR, barA, barB;  /* underline: cells [a,b) */
static unsigned char shownRow = NO_BAR, shownBits;

static unsigned char felt(void)
{
    return (pal ? themePal : themeNtsc)[theme * 2];
}

/* Frames since start-up, from the VBI's RTCLOK. */
unsigned int fcsFrames(void)
{
    unsigned char hi, lo;

    do {
        hi = RTCLOKH;
        lo = RTCLOKL;
    } while (hi != RTCLOKH);
    return ((unsigned int) hi << 8) | lo;
}

unsigned char fcsPal(void)
{
    return pal;
}

void waitvsync(void)
{
    unsigned char f = RTCLOKL;

    while (RTCLOKL == f) ;
}

/* The scan lines an underline at `row` occupies, and how many. */
static unsigned char barLine(unsigned char row)
{
    return row == STATUS_ROW ? STATUS_BAR_LINE : TOP_LINE + 1 + (row << 3);
}

static unsigned char barLines(unsigned char row)
{
    return row == STATUS_ROW ? 3 : 2;
}

static void setBarData(unsigned char row, unsigned char bits)
{
    memset(P2 + barLine(row), bits, barLines(row));
}

/* Put player 2 where barRow/barA/barB say: at most 8 cells, centred on the
   range. It slides there (antic.s), in from the left on a new row. */
static void applyBar(void)
{
    unsigned char w, n, bits, target;

    if (barRow == NO_BAR || barB <= barA)
    {
        if (shownRow != NO_BAR)
            setBarData(shownRow, 0);
        shownRow = NO_BAR;
        barTarget = barHpos = 0;
        HPOSP2 = 0;
        return;
    }

    w = barB - barA;
    n = w > 8 ? 8 : w;
    bits = (unsigned char) (0xFF00 >> n);
    target = LEFT_EDGE + ((barA + ((w - n) >> 1)) << 2);

    if (shownRow != barRow)
    {
        if (shownRow != NO_BAR)
            setBarData(shownRow, 0);
        barHpos = target - 20;
        HPOSP2 = barHpos;
        shownRow = barRow;
        shownBits = 0;
    }
    if (shownBits != bits)
    {
        setBarData(barRow, bits);
        shownBits = bits;
    }
    barTarget = target;
}

/* The two interior columns of the hole card, darkened wherever the glyph is
   not ink: CreatePlayerSecretCardMask in 5card.bas. It is rewritten in place,
   as the beam may be passing: the same card writes the same bytes. */
static void buildMask(void)
{
    unsigned char *p = P1 + TOP_LINE + (maskY << 3) + 7;
    unsigned char *cell = CELL(maskX, maskY + 1);
    const unsigned char *l, *r;
    unsigned char row, j, v, m;

    if (maskBuilt != p)
    {
        if (maskBuilt)
            memset(maskBuilt, 0, MASK_LINES);
        maskBuilt = p;
    }
    *p++ = 0x7E;
    for (row = 0; row < 3; row++, cell += WIDTH)
    {
        l = fcsFont + ((cell[0] & 0x7F) << 3);
        r = fcsFont + ((cell[1] & 0x7F) << 3);
        for (j = 0; j < 8; j++)
        {
            m = 0;
            v = l[j];
            if ((v & 0xC0) != 0xC0) m |= 0x80;
            if ((v & 0x30) != 0x30) m |= 0x40;
            if ((v & 0x0C) != 0x0C) m |= 0x20;
            if ((v & 0x03) != 0x03) m |= 0x10;
            v = r[j];
            if ((v & 0xC0) != 0xC0) m |= 0x08;
            if ((v & 0x30) != 0x30) m |= 0x04;
            if ((v & 0x0C) != 0x0C) m |= 0x02;
            *p++ = m;
        }
    }
    *p = 0x7E;
    maskDirty = false;
}

/* Show what has been drawn: the screen, the status bar's height, the mask
   and the underline. The four display lists share a page, so one store
   switches between them. */
static void present(void)
{
    const unsigned char *dl;

    if (dbl)
        dl = tall ? dlFrontTall : dlFrontNorm;
    else
        dl = tall ? dlWorkTall : dlWorkNorm;
    SDLSTL = (unsigned char) (unsigned int) dl;

    dliBg[1] = tall ? C_BLACK : felt();
    dliFg[1] = tall ? dliFg[2] : C_WHITE;

    if (maskWanted && maskDirty)
        buildMask();
    HPOSP1 = maskWanted ? LEFT_EDGE + (maskX << 2) : 0;

    applyBar();
}

/* A change shows at once while the work screen is the one shown. */
static void changed(void)
{
    if (!dbl)
        present();
}

static void put(unsigned char x, unsigned char y, unsigned char g)
{
    if (x < WIDTH && y < HEIGHT)
        *CELL(x, y) = g;
}

/* ASCII to the font, as the BASIC's Print does it: upper case, its own
   glyphs for , - . / and its occupied-table mark for *. What the font has
   turned into card or box art prints blank. */
static unsigned char textGlyph(unsigned char c)
{
    if (c >= 'a' && c <= 'z')
        c -= 'a' - 'A';
    switch (c)
    {
    case ',': return 116;
    case '-': return 125;
    case '.': return 115;
    case '/': return 124;
    case '*': return 123;
    }
    if (c < 0x20 || c > 0x5F)
        return G_BLANK;
    c -= 0x20;
    if ((c >= 1 && c <= 11) || (c >= G_BOX_TL && c <= G_BOX_H))
        return G_BLANK;
    return c;
}

/* Up to n characters of s from (x,y). */
static void putText(unsigned char x, unsigned char y, const char *s, unsigned char n)
{
    unsigned char *p;
    unsigned char c;

    if (y >= HEIGHT || x >= WIDTH)
        return;
    if (n > WIDTH - x)
        n = WIDTH - x;
    p = CELL(x, y);
    while (n-- && (c = (unsigned char) *s++) != 0)
        *p++ = textGlyph(c);
}

static void applyTheme(void)
{
    const unsigned char *t = (pal ? themePal : themeNtsc) + theme * 2;

    dliBg[0] = t[0];
    if (!tall)
        dliBg[1] = t[0];
    COLOR0 = t[1];
}

/**
 * @brief Initialize graphics mode; set palette.
 */
void initGraphics()
{
    pal = (GTIAPAL & 0x0E) == 0;

    memset(scrWork, 0, SCREEN_SIZE);
    memset(scrFront, 0, SCREEN_SIZE);

    /* Players 0 and 3 are the black sidebars, 1 the hole-card mask, 2 the
       underline; 0 and 1 in front of the playfield, 2 and 3 behind it. */
    memset(P0, 0, 0x400);
    memset(P0, 0xFF, 255);
    memset(P3, 0xFF, 255);
    SIZEP0 = SIZEP2 = SIZEP3 = 3;
    SIZEP1 = 0;
    HPOSP0 = 16;
    HPOSP3 = 208;
    HPOSP1 = HPOSP2 = 0;
    PRIOR = 2;
    PMBASE = (unsigned char) ((unsigned int) pmBase >> 8);
    GRACTL = 2;

    PCOLR0 = C_BLACK;
    PCOLR1 = C_MASK;
    PCOLR2 = C_CURSOR;
    PCOLR3 = C_BLACK;
    COLOR1 = C_WHITE;
    COLOR2 = C_BLACK;
    COLOR3 = pal ? C_RED_PAL : C_RED_NTSC;
    COLOR4 = C_BLACK;

    dliFg[0] = dliFg[1] = C_WHITE;
    dliBg[2] = C_BLACK;
    dliFg[2] = pal ? C_MOVE_PAL : C_MOVE_NTSC;
    applyTheme();

    CHBASE = (unsigned char) ((unsigned int) fcsFont >> 8);
    VDSLST = fcsDli;

    // The VBI skips its deferred vector while CRITIC is set.
    CRITIC = 1;
    VVBLKD = fcsVbi;
    SDLSTH = (unsigned char) ((unsigned int) dlWorkNorm >> 8);
    SDLSTL = (unsigned char) (unsigned int) dlWorkNorm;
    CRITIC = 0;

    SDMCTL = 0x3A;              /* normal playfield, single-line players, DL DMA */

    resetScreen();
    enableDoubleBuffer();
    waitvsync();
}

void drawChip(unsigned char x, unsigned char y)
{
    put(x, y, G_CHIP);
    changed();
}

void fcsPutGlyph(unsigned char x, unsigned char y, unsigned char g)
{
    put(x, y, g);
    changed();
}

/* Copy the work screen to the front one and show the result. */
void drawBuffer()
{
    waitvsync();
    memcpy(scrFront, scrWork, SCREEN_SIZE);
    ATRACT = 0;
    present();
}

void drawBox(unsigned char x, unsigned char y, unsigned char w, unsigned char h)
{
    unsigned char i, red;

    // The pot's box is red, as the BASIC prints it inverse.
    red = (x == WIDTH/2-3 && y == 11+POT_Y_MODIFIER) ? G_RED : 0;

    // Correct coordinates;
    w++;
    h++;

    put(x, y, G_BOX_TL | red);
    put(x + w, y, G_BOX_TR | red);
    put(x, y + h, G_BOX_BL | red);
    put(x + w, y + h, G_BOX_BR | red);

    for (i = 1; i < w; i++)
    {
        put(x + i, y, G_BOX_H | red);
        put(x + i, y + h, G_BOX_H | red);
    }

    for (i = 1; i < h; i++)
    {
        put(x, y + i, G_BOX_V | red);
        put(x + w, y + i, G_BOX_V | red);
    }
    changed();
}

/**
 * @brief Draw text s at position x,y
 * @param x Horizontal position (0-39)
 * @param y Vertical Position (0-25)
 * @param s NULL terminated string to display.
 */
void drawText(unsigned char x, unsigned char y, const char* s)
{
    putText(x, y, s, WIDTH);
    changed();
}

/* The logo of the BASIC's WelcomeScreen, in the font's own pieces. */
static const unsigned char logo0[] = { 105, 0 };
static const unsigned char logo1[] = { 108, 106, 108, 0 };
static const unsigned char logo2[] = { 110, 106, 112, 106, 104, 0 };
static const unsigned char logo3[] = { 108, 108, 106, 104, 0 };
static const unsigned char logo4[] = { 109, 108, 108, 0 };

static void putRaw(unsigned char x, unsigned char y, const unsigned char *g)
{
    unsigned char *p = CELL(x, y);

    while (*g)
        *p++ = *g++;
}

/**
 * @brief Draw the 5 Card Stud Logo
 */
void drawLogo()
{
    putRaw(19, 3, logo0);
    putRaw(18, 4, logo1);
    putText(13, 5, "FUJI", 4);
    putRaw(17, 5, logo2);
    putText(22, 5, "NET", 3);
    putRaw(18, 6, logo3);
    putRaw(19, 7, logo4);
    putText(17, 9, "5 CARD STUD", 11);
    changed();
}

void clearStatusBar()
{
    memset(CELL(0, STATUS_ROW), G_BLANK, WIDTH);
    if (tall)
    {
        tall = false;
        memset(CELL(0, TALL_ROW), G_BLANK, WIDTH);
        put(0, TALL_ROW, 91);
        put(WIDTH-1, TALL_ROW, 92);
    }
    if (barRow == STATUS_ROW)
        barRow = NO_BAR;
    changed();
}

/**
 * @brief Clear the screen to an empty table: ResetScreen in 5card.bas.
 */
void resetScreen()
{
    memset(scrWork, G_BLANK, SCREEN_SIZE);
    put(0, 0, 89);
    put(WIDTH-1, 0, 90);
    put(0, TALL_ROW, 91);
    put(WIDTH-1, TALL_ROW, 92);
    tall = false;
    maskWanted = false;
    if (barRow == STATUS_ROW)
        barRow = NO_BAR;
    changed();
}

/* Draw on the work screen, and show it as it is drawn. */
void disableDoubleBuffer()
{
    dbl = false;
    present();
}

/* Show a copy of the work screen while the next frame is drawn on it. */
void enableDoubleBuffer()
{
    if (!dbl)
    {
        memcpy(scrFront, scrWork, SCREEN_SIZE);
        dbl = true;
        present();
    }
}

/* A hand's first card goes at its seat: clear the seat first, as the BASIC
   does before the final flip, so a hand is never joined onto the one it
   replaces. */
static void clearSeat(unsigned char x, unsigned char y)
{
    unsigned char i, r, left;

    for (i = 0; i < state.playerCount && i < 8; i++)
    {
        if (playerX[i] == x && playerY[i] == y)
        {
            left = x - 1 - (playerDir[i] < 0 ? 7 : 0);
            for (r = 0; r < 5; r++)
                memset(CELL(left, y + r), G_BLANK, 11);
            return;
        }
    }
}

/**
 * @brief Draw card at position x,y: DrawCard in 5card.bas. The card is the
 *        interior at x and x+1 with its edges at x-1 and x+2, and is drawn
 *        over whatever card is already there.
 * @param x Horizontal card position (0-39)
 * @param y Vertical card position (0-25)
 * @param partial ignored: every card is drawn whole, as the BASIC does
 * @param s String indicating number and suit. (e.g. "as" for ace of spades)
 * @param isHidden is card currently overturned?
 */
void drawCard(unsigned char x, unsigned char y, unsigned char partial, const char* s, unsigned char isHidden)
{
    unsigned char *loc, *side;
    unsigned char val, suit, hi, v, i;
    signed char tbo = 0;
    bool rightUnder, isTen, back;

    (void) partial;

    if (y + 4 >= HEIGHT || x == 0 || x + 2 >= WIDTH)
        return;
    if (state.playerCount > 1)
        clearSeat(x, y);
    loc = CELL(x, y);

    back = s[0] == '?';
    switch (s[0] | 0x20)
    {
    case 't': val = 10; break;
    case 'j': val = 12; break;
    case 'q': val = 13; break;
    case 'k': val = 14; break;
    case 'a': val = 15; break;
    default:  val = (unsigned char) (s[0] - '0'); break;
    }
    if (back)
    {
        tbo = 4;
        val = 0x3C;
    }

    switch (s[1] | 0x20)
    {
    case 'h': suit = 0xC0; val += 0x80; break;
    case 'd': suit = 0xC2; val += 0x80; break;
    case 'c': suit = 0x44; break;
    default:  suit = 0x46; break;
    }

    // A card underneath to the right shows past this one's right edge.
    rightUnder = loc[WIDTH + 2] != G_BLANK;
    if (rightUnder)
    {
        tbo = -4;
        loc[-1] = 75;
        loc[4 * WIDTH - 1] = 76;
        suit += 32;
    }

    loc[0] = 0x51 + tbo;
    loc[1] = 0x52 + tbo;

    if (!back)
    {
        isTen = val == 10 || val == 138;
        hi = 1;
        if (isTen)
            hi += val;
        if (rightUnder)
            hi += isTen ? 52 : 61;
        loc[WIDTH] = val;
        loc[WIDTH + 1] = hi;
        loc[2 * WIDTH] = 1;
        loc[2 * WIDTH + 1] = rightUnder ? 62 : 1;
        loc[3 * WIDTH] = suit;
        loc[3 * WIDTH + 1] = suit + 1;
    }
    else
    {
        loc[WIDTH] = 0x3C;
        loc[WIDTH + 1] = 0xBC;
        loc[2 * WIDTH] = 0xBC;
        loc[2 * WIDTH + 1] = 0x3C;
        loc[3 * WIDTH] = 0x3C;
        loc[3 * WIDTH + 1] = 0xBC;
    }

    // Edges, joined onto any card this one lies over.
    side = loc + WIDTH - 1;
    for (i = 0; i < 3; i++, side += WIDTH)
    {
        v = *side;
        if (v == 0x3C || v == 0xBC)
            v++;
        else if (v == 1)
            v = 62;
        else if ((v > 64 && v < 72) || (v > 191 && v < 201))
        {
            v += 32;
            side[-1] += 32;
        }
        else if (v == 11 || v == 139)
            v += 52;
        else
            v = rightUnder ? 72 : 73;
        *side = v;

        if (!rightUnder)
            side[3] = 74;
    }

    loc[4 * WIDTH] = 0x53 + tbo;
    loc[4 * WIDTH + 1] = 0x54 + tbo;

    // The player's own hole card is darkened, as long as it is face up.
    if (isHidden && !back)
    {
        maskX = x;
        maskY = y;
        maskWanted = maskDirty = true;
    }
    else if (maskWanted && x == maskX && y == maskY)
        maskWanted = false;

    changed();
}

/* A message too long for one row (the round result) takes row 24 into the
   bar as well, split after its comma as the BASIC does, or at a space. */
void drawStatusTextAt(unsigned char x, const char* s)
{
    unsigned char len = (unsigned char) strlen(s);
    unsigned char brk;

    if (len <= WIDTH)
    {
        putText(x, STATUS_ROW, s, WIDTH);
        changed();
        return;
    }

    for (brk = 0; brk < len && s[brk] != ','; brk++) ;
    if (brk >= WIDTH || len - brk > WIDTH)
        for (brk = WIDTH - 1; brk > 0 && s[brk] != ' '; brk--) ;
    if (brk == 0)
        brk = WIDTH - 1;

    tall = true;
    memset(CELL(0, TALL_ROW), G_BLANK, WIDTH * 2);
    putText(0, TALL_ROW, s, brk + 1);
    s += brk + 1;
    if (*s == ' ')
        s++;
    putText(0, STATUS_ROW, s, WIDTH);
    changed();
}

void drawStatusText(const char* s)
{
    clearStatusBar();
    drawStatusTextAt(0, s);
}

/* The clock after the move timer, as the BASIC draws it. */
void drawStatusTimer()
{
    put(WIDTH - 1, STATUS_ROW, G_CLOCK);
    changed();
}

/* Underline cells [x,x+w) of row y with player 2: the active player's name
   (the row under it) or the move under the cursor (the status row). A rule
   wider than the player is drawn in the font instead, as on the C64. */
void drawLine(unsigned char x, unsigned char y, unsigned char w)
{
    if (y >= HEIGHT || w == 0)
        return;
    if (w > 8 && y != STATUS_ROW)
    {
        memset(CELL(x, y), G_BOX_H, x + w > WIDTH ? WIDTH - x : w);
    }
    else
    {
        barRow = y;
        barA = x;
        barB = x + w;
    }
    changed();
}

/* Take cells [x,x+w) of row y out of the underline: from either end it
   shrinks, over all of it it goes. w = 0 hides it wherever it is. */
void hideLine(unsigned char x, unsigned char y, unsigned char w)
{
    unsigned char e = x + w;

    if (barRow == NO_BAR)
        return;
    if (w == 0)
        barRow = NO_BAR;
    else if (y != barRow || e <= barA || x >= barB)
        return;
    else if (x <= barA && e >= barB)
        barRow = NO_BAR;
    else if (x <= barA)
        barA = e;
    else if (e >= barB)
        barB = x;
    changed();
}

/* The table colour: 5card.bas's four themes, felt and card edges. */
unsigned char cycleNextColor()
{
    theme = (theme + 1) % THEMES;
    applyTheme();
    soundCursor();
    return theme;
}

void setColorMode(unsigned char mode)
{
    theme = mode < THEMES ? mode : 0;
}

/* The four aces and the rows of red and black between them. */
static const unsigned char trim[] = { 220, 217, 90, 91, 0 };

void drawBorder()
{
    unsigned char i;

    drawCard(1, 0, FULL_CARD, "as", 0);
    drawCard(WIDTH-3, 0, FULL_CARD, "ah", 0);
    drawCard(1, 20, FULL_CARD, "ad", 0);
    drawCard(WIDTH-3, 20, FULL_CARD, "ac", 0);

    for (i = 4; i < 36; i += 4)
    {
        putRaw(i, 1, trim);
        putRaw(i, 22, trim);
    }
    changed();
}

#endif /* BUILD_ATARI5200 */
