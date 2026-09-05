/* text.h -- byte-aligned 5x7 text on the Astrocade screen, in C.
 *
 * The C rendering of CONFIG's font.inc: BIOS glyph data for 0x20-0x63
 * plus a 26-glyph lowercase set, drawn in 8-pixel cells at byte-aligned
 * positions (two bytes per scanline at 2bpp), which is what makes the
 * blit shift-free.  20 columns; a text row is 8 scanlines.
 */

#ifndef TEXT_H
#define TEXT_H

void txt_clear(void);                   /* also the screen RAM init      */
void txt_putc(unsigned char x, unsigned char y, char c);
void txt_puts(unsigned char x, unsigned char y, const char *s);
void txt_hex(unsigned char x, unsigned char y, unsigned char v);

#endif
