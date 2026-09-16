#ifdef BUILD_COLECO

/**
 * @brief   ColecoVision Graphics Routines for 5cardstud
 * @author  Thomas Cherryhomes
 * @email   thom dot cherryhomes at gmail dot com
 * @license gpl v. 3, see LICENSE for details
 * @verbose TMS9918 GRAPHICS II via the z88dk generic console; card and
 *          frame art converted from the MS-DOS CGA tiles (see udg.h),
 *          text set in the Namco arcade font via the CRT_FONT redirect.
 */

#include <stdbool.h>
#include <string.h>
#include <video/tms99x8.h>
#include <conio.h>
#include <sys/ioctl.h>
#include "udg.h"
#include "vars.h"
#include "../platform-specific/graphics.h"

#define CORNER_TOP 0
#define CORNER_BOTTOM 18

// Table palette: MS-DOS felt/dark-red remapped to the TMS9918.
#define C_TABLE   VDP_INK_DARK_GREEN   // the felt
#define C_ACCENT  VDP_INK_MEDIUM_RED   // card outlines/backs, frames
#define C_CARD_BG VDP_INK_WHITE        // card face
#define C_TEXT    VDP_INK_WHITE        // table text
#define C_BORDER  VDP_INK_BLACK        // VDP border / status bar paper

// VDP interrupt hook living in util.c (bumps the timer + vsync flag)
extern void myInt(void);

// z88dk's generic console driver state; see initGraphics().
extern unsigned char generic_console_flags;

bool always_render_full_cards = 0;

/**
 * @brief Initialize graphics mode; set palette.
 */
void initGraphics()
{
    void *param = &udg;
    vdp_set_mode(2);
    console_ioctl(IOCTL_GENCON_SET_UDGS,&param);

    // Bit 6 = vertical scrolling disabled. Nothing here ever wants to scroll --
    // every screen is drawn by absolute position -- but a 32-character status
    // line printed to the last column of row 23 advances the cursor off the
    // bottom and the console would scroll on the way past. That would also be
    // the only caller of the scroll buffer that src/coleco/conbuf.asm has cut
    // down to 16 bytes, so this is what keeps that safe.
    generic_console_flags |= 0x40;

    vdp_color(C_TEXT,C_TABLE,C_BORDER);
    add_raster_int(myInt);
    clrscr();
}

void drawChip(unsigned char x, unsigned char y)
{
    vdp_color(C_ACCENT,C_TABLE,C_BORDER);
    gotoxy(x,y);
    cputc(UDG_CHIP);
}

void drawBuffer()
{
}

void drawBox(unsigned char x, unsigned char y, unsigned char w, unsigned char h)
{
    unsigned char i=0;
    // Correct coordinates;
    w++;
    h++;

    vdp_color(C_ACCENT,C_TABLE,C_BORDER);

    // Put box corners at coordinate extents
    gotoxy(x,y);
    cputc(UDG_BOX_TL);
    gotoxy(x+w,y);
    cputc(UDG_BOX_TR);
    gotoxy(x,y+h);
    cputc(UDG_BOX_BL);
    gotoxy(x+w,y+h);
    cputc(UDG_BOX_BR);

    x++;
    w--;

    // Put horizontal rules
    gotoxy(x,y);
    for (i=0;i<w;i++)
        cputc(UDG_BOX_H);

    gotoxy(x,y+h);
    for (i=0;i<w;i++)
        cputc(UDG_BOX_H);

    // Correct again
    x--;
    y++;
    h--;
    w++;

    // Put vertical rules
    for (i=0;i<h;i++)
    {
        gotoxy(x,y+i);
        cputc(UDG_BOX_V);
    }

    for (i=0;i<h;i++)
    {
        gotoxy(x+w,y+i);
        cputc(UDG_BOX_V);
    }
}

/**
 * @brief Draw text s at position x,y
 * @param x Horizontal position (0-31)
 * @param y Vertical Position (0-23)
 * @param s NULL terminated string to display.
 */
void drawText(unsigned char x, unsigned char y, const char* s)
{
    vdp_color(C_TEXT,C_TABLE,C_BORDER);
    gotoxy(x,y);
    cputs(strupr(s));
}

/**
 * @brief Draw the 5 Card Stud Logo
 */
void drawLogo()
{
    static unsigned char i;
    i=4;
    drawText(WIDTH/2-5,++i, "           ");
    drawText(WIDTH/2-5,++i, " FUJI  NET ");
    drawText(WIDTH/2-5,++i, "           ");
    drawText(WIDTH/2-5,++i, "5 CARD STUD");
    drawText(WIDTH/2-5,++i, "           ");
}

void clearStatusBar()
{
    // Clear row 23's patterns only; row 22 is left alone deliberately,
    // as the border aces and bottom-seat cards extend into it.
    vdp_vfill(0x1700,0x00,0x100);
}

/**
 * @brief Clear the screen
 */
void resetScreen()
{
    vdp_color(C_TEXT,C_TABLE,C_BORDER);
    clrscr();

    // Persistent status bar: row 23 renders white on black.
    vdp_vfill(MODE2_ATTR+0x1700,(VDP_INK_WHITE<<4)|VDP_INK_BLACK,0x100);

    // Round the felt off against the border/status bar, like the MS-DOS
    // build. Green ink on black paper; card draws may overlay these.
    vdp_color(C_TABLE,VDP_INK_BLACK,C_BORDER);
    gotoxy(0,0);
    cputc(UDG_SCREEN_TL);
    gotoxy(WIDTH-1,0);
    cputc(UDG_SCREEN_TR);
    gotoxy(0,22);
    cputc(UDG_SCREEN_BL);
    gotoxy(WIDTH-1,22);
    cputc(UDG_SCREEN_BR);
}

void disableDoubleBuffer()
{
}

void enableDoubleBuffer()
{
}

/**
 * @brief Draw card at position x,y
 * @param x Horizontal card position (0-31)
 * @param y Vertical card position (0-23)
 * @param partial enum (see ../platform-specific/graphics.h)
 * @param s String indicating number and suit. (e.g. "as" for ace of spades)
 * @param isHidden is card currently overturned?
 */
void drawCard(unsigned char x, unsigned char y, unsigned char partial, const char* s, unsigned char isHidden)
{
    static unsigned char val, suitColor, i, suit;

    if (x==WIDTH-3 && s[0]!='?' && cvpeek(x,y+1)==UDG_BACK_L_TOP) {
        drawCard(x+1,y,PARTIAL_RIGHT,"??",false);
    }

    if (partial == PARTIAL_LEFT)
    {
        gotoxy(x,y++);
        vdp_color(C_ACCENT,C_TABLE,C_BORDER);
        cputc(UDG_CARD_TL);

        gotoxy(x,y++);
        vdp_color(C_ACCENT,C_CARD_BG,C_BORDER);
        cputc(UDG_BACK_L_TOP);

        gotoxy(x,y++);
        vdp_color(C_ACCENT,C_CARD_BG,C_BORDER);
        cputc(UDG_BACK_L_MID);

        gotoxy(x,y++);
        vdp_color(C_ACCENT,C_CARD_BG,C_BORDER);
        cputc(UDG_BACK_L_BOT);

        gotoxy(x,y++);
        vdp_color(C_ACCENT,C_TABLE,C_BORDER);
        cputc(UDG_CARD_BL);

    }
    else if (partial == PARTIAL_RIGHT)
    {
        x++;
        gotoxy(x,y++);
        vdp_color(C_ACCENT,C_TABLE,C_BORDER);
        cputc(UDG_CARD_TOP_TRIM);

        gotoxy(x,y++);
        vdp_color(C_ACCENT,C_CARD_BG,C_BORDER);
        cputc(UDG_BACK_RCOL_TOP);

        gotoxy(x,y++);
        vdp_color(C_ACCENT,C_CARD_BG,C_BORDER);
        cputc(UDG_BACK_RCOL_MID);

        gotoxy(x,y++);
        vdp_color(C_ACCENT,C_CARD_BG,C_BORDER);
        cputc(UDG_BACK_RCOL_BOT);

        gotoxy(x,y++);
        vdp_color(C_ACCENT,C_TABLE,C_BORDER);
        cputc(UDG_CARD_BOT_TRIM);
    }
    else // FULL CARD
    {
        switch (s[1])
        {
        case 'h' :
            suit=UDG_SUIT_HEART;
            suitColor=C_ACCENT;
            break;
        case 'd' :
            suit=UDG_SUIT_DIAMOND;
            suitColor=C_ACCENT;
            break;
        case 'c' :
            suit=UDG_SUIT_CLUB;
            suitColor=VDP_INK_BLACK;
            break;
        case 's' :
            suit=UDG_SUIT_SPADE;
            suitColor=VDP_INK_BLACK;
            break;
        default:
            suit=UDG_CARD_VERT;
            suitColor=VDP_INK_DARK_YELLOW; // Something wrong.
            break;
        }

        // If card is overturned, draw the back
        if (s[0]=='?')
        {
            // Shift right card left one for easy drawing of border
            // As well as clear existing cards, assuming a fold
            vdp_color(C_TEXT,C_TABLE,C_BORDER);
            if (x>WIDTH-3) {
                for (i=0;i<5;i++) {
                    gotoxy(x-7,y+i);
                    cputs("      ");
                }
                x--;
            } else {
                for (i=0;i<5;i++) {
                    gotoxy(x+3,y+i);
                    cputs("       ");
                }
            }
            gotoxy(x,y++);
            vdp_color(C_ACCENT,C_TABLE,C_BORDER);
            cputc(UDG_CARD_TL);
            cputc(UDG_CARD_TOP);
            cputc(UDG_CARD_TR_STUB);

            gotoxy(x,y++);
            vdp_color(C_ACCENT,C_CARD_BG,C_BORDER);
            cputc(UDG_BACK_L_TOP);
            cputc(UDG_BACK_R_TOP);
            vdp_color(C_ACCENT,C_TABLE,C_BORDER);
            cputc(UDG_CARD_VERT);

            gotoxy(x,y++);
            vdp_color(C_ACCENT,C_CARD_BG,C_BORDER);
            cputc(UDG_BACK_L_MID);
            cputc(UDG_BACK_R_MID);
            vdp_color(C_ACCENT,C_TABLE,C_BORDER);
            cputc(UDG_CARD_VERT);

            gotoxy(x,y++);
            vdp_color(C_ACCENT,C_CARD_BG,C_BORDER);
            cputc(UDG_BACK_L_BOT);
            cputc(UDG_BACK_R_BOT);
            vdp_color(C_ACCENT,C_TABLE,C_BORDER);
            cputc(UDG_CARD_VERT);

            gotoxy(x,y++);
            cputc(UDG_CARD_BL);
            cputc(UDG_CARD_BOT);
            cputc(UDG_CARD_BR_STUB);

        }
        else // Draw the full card.
        {
            gotoxy(x,y);

            // Top card border
            if (cvpeek(x+1,y)!=UDG_CARD_TOP)
            {
                vdp_color(C_ACCENT,C_TABLE,C_BORDER);
                cputc(UDG_CARD_TL);
                cputc(UDG_CARD_TOP);
            }
            if (cvpeek(x+2,y)==' ')
            {
                gotoxy(x+2,y);
                vdp_color(C_ACCENT,C_TABLE,C_BORDER);
                cputc(UDG_CARD_TR_STUB);
            }

            // left border and card value
            switch (s[0])
            {
            case 't':
                val=UDG_RANK_T; // 10
                break;
            case 'j':
                val=UDG_RANK_J;
                break;
            case 'q':
                val=UDG_RANK_Q;
                break;
            case 'k':
                val=UDG_RANK_K;
                break;
            case 'a':
                val=UDG_RANK_A;
                break;
            default:
                val=UDG_RANK_2+(s[0]-'2');
                break;
            }

            // Left border/space
            gotoxy(x,++y);
            vdp_color(C_ACCENT,C_CARD_BG,C_BORDER);
            cputc(UDG_CARD_VERT);

            // Card value
            vdp_color(suitColor,C_CARD_BG,C_BORDER);
            cputc(val);

            // Right border (if no existing char)
            if (cvpeek(x+2,y)==' ')
            {
                vdp_color(C_ACCENT,C_TABLE,C_BORDER);
                cputc(UDG_CARD_VERT);
            }

            // left border and interior (hole-card marker band if hidden)
            gotoxy(x,++y);
            if (isHidden)
            {
                vdp_color(C_ACCENT,C_CARD_BG,C_BORDER);
                cputc(UDG_HIDDEN_L);
                cputc(UDG_HIDDEN_R);

                // The MS-DOS marker's double rule is black; GRAPHICS II
                // colors per pixel row, so repaint tile rows 1 and 6
                // (solid ink in the marker tiles) black-on-white.
                for (i=0;i<2;i++)
                {
                    vdp_vpoke(MODE2_ATTR+0x100*y+(x+i)*8+1,(VDP_INK_BLACK<<4)|VDP_INK_WHITE);
                    vdp_vpoke(MODE2_ATTR+0x100*y+(x+i)*8+6,(VDP_INK_BLACK<<4)|VDP_INK_WHITE);
                }
            }
            else
            {
                vdp_color(C_ACCENT,C_CARD_BG,C_BORDER);
                cputc(UDG_CARD_VERT);
                cputc(0x20);
            }

            // Right border (if no existing char)
            if (cvpeek(x+2,y)==' ')
            {
                vdp_color(C_ACCENT,C_TABLE,C_BORDER);
                gotoxy(x+2,y);
                cputc(UDG_CARD_VERT);
            }

            // left border
            gotoxy(x,++y);
            vdp_color(C_ACCENT,C_CARD_BG,C_BORDER);
            cputc(UDG_CARD_VERT);

            // suit
            vdp_color(suitColor,C_CARD_BG,C_BORDER);
            cputc(suit);

            // Right border (if no existing char)
            if (cvpeek(x+2,y)==' ')
            {
                vdp_color(C_ACCENT,C_TABLE,C_BORDER);
                gotoxy(x+2,y);
                cputc(UDG_CARD_VERT);
            }

            // bottom border
            gotoxy(x,++y);
            if (cvpeek(x+1,y)!=UDG_CARD_BOT)
            {
                vdp_color(C_ACCENT,C_TABLE,C_BORDER);
                cputc(UDG_CARD_BL);
                cputc(UDG_CARD_BOT);
            }
            if (cvpeek(x+2,y)==' ')
            {
                gotoxy(x+2,y);
                vdp_color(C_ACCENT,C_TABLE,C_BORDER);
                cputc(UDG_CARD_BR_STUB);
            }
        }
    }
}

void drawStatusText(const char* s)
{
    clearStatusBar();
    drawStatusTextAt(0, s);
}

void drawStatusTextAt(unsigned char x, const char* s)
{
    vdp_color(VDP_INK_WHITE,VDP_INK_BLACK,C_BORDER);
    gotoxy(x,22+(strlen(s)<=WIDTH?1:0));
    cputs(strupr(s));
}

unsigned char cycleNextColor()
{
    return 0;
}

void drawStatusTimer()
{
}

void hideLine(unsigned char x, unsigned char y, unsigned char w)
{
    uint8_t i;
    if (y==23)
    {
        vdp_vfill(MODE2_ATTR+0x1700+x*8,(VDP_INK_WHITE<<4)|VDP_INK_BLACK,8*w);
    }
    else
    {
        for(i=0;i<w*8;i+=8)
        {
            vdp_vfill(MODE2_ATTR+0x100*y+x*8+i,(VDP_INK_WHITE<<4)|C_TABLE,2);
        }
    }

}

void drawLine(unsigned char x, unsigned char y, unsigned char w)
{
    uint8_t i;
    if (y==23)
    {
        for(i=0;i<w*8;i+=8)
        {
            vdp_vpoke(MODE2_ATTR+0x1707+x*8+i,(VDP_INK_WHITE<<4)|C_ACCENT);
        }
    }
    else
    {
        for(i=0;i<w*8;i+=8)
        {
            vdp_vfill(MODE2_ATTR+0x100*y+x*8+i,(VDP_INK_WHITE<<4)|C_ACCENT,2);
        }
    }
}

void setColorMode(unsigned char mode)
{
}

void drawBorder()
{
    drawCard(1,CORNER_TOP,FULL_CARD, "as", 0);
    drawCard(WIDTH-3,CORNER_TOP,FULL_CARD, "ah", 0);
    drawCard(1,CORNER_BOTTOM,FULL_CARD, "ad", 0);
    drawCard(WIDTH-3,CORNER_BOTTOM,FULL_CARD, "ac", 0);
}

#endif /* BUILD_COLECO */
