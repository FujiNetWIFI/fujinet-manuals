#include <os7.h>

#include "fujidisp.h"
#include "netterm.h"

/* The name table's VRAM address in the layout mode_1() lays down: 32x24 bytes
 * at 0x1800. A row is 32 bytes at 0x1800 + row*32. */
#define NT_BASE  0x1800

/* Where the pane is stashed while the keyboard borrows the screen. The colour
 * table is 32 bytes at 0x2000 and the sprite generator does not start until
 * 0x3800, so 0x2800 is free VRAM the display code never touches. */
#define SAVE_BASE 0x2800

static unsigned char col;       /* 0..TERM_COLS-1 */
static unsigned char row;       /* TERM_TOP..TERM_BOT */
static unsigned char line[TERM_COLS];

void term_init(void)
{
    unsigned char r;

    for (r = TERM_TOP; r <= TERM_BOT; r++)
        disp_row_clear(r);
    col = 0;
    row = TERM_TOP;
}

/* Copy the pane up one row and clear the bottom. read_vram/write_vram take raw
 * VRAM addresses; a row at a time keeps every count well under the 8-bit
 * truncation that bites larger put_vram calls. */
static void scroll(void)
{
    unsigned char r;

    for (r = TERM_TOP; r < TERM_BOT; r++) {
        read_vram(line, (unsigned short)(NT_BASE + (r + 1) * TERM_COLS),
                  TERM_COLS);
        write_vram(line, (unsigned short)(NT_BASE + r * TERM_COLS), TERM_COLS);
    }
    disp_row_clear(TERM_BOT);
}

static void newline(void)
{
    col = 0;
    if (row < TERM_BOT)
        row++;
    else
        scroll();
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
        if (col > 0)
            col--;
        disp_char(col, row, ' ');
        return;
    }
    if (c < 0x20 || c > 0x7E)
        c = '.';                /* keep control bytes visible, not disruptive */

    disp_char(col, row, c);
    if (++col >= TERM_COLS)
        newline();
}

void term_puts(volatile unsigned char *p, unsigned int n)
{
    while (n--)
        term_putc((char)*p++);
}

void term_save(void)
{
    unsigned char r;

    for (r = 0; r < 24; r++) {
        read_vram(line, (unsigned short)(NT_BASE + r * TERM_COLS), TERM_COLS);
        write_vram(line, (unsigned short)(SAVE_BASE + r * TERM_COLS), TERM_COLS);
    }
}

void term_restore(void)
{
    unsigned char r;

    for (r = 0; r < 24; r++) {
        read_vram(line, (unsigned short)(SAVE_BASE + r * TERM_COLS), TERM_COLS);
        write_vram(line, (unsigned short)(NT_BASE + r * TERM_COLS), TERM_COLS);
    }
}
