/* conio.c -- the third road: cc65's own console, a 20 x 24 screen in ANTIC
 * mode 6 that cc65 keeps at $3E20-$3FFF. Link with __RESERVED_MEMORY__ of
 * at least 0x1E0, or the C stack is built on top of it (build.sh: RESERVE). */
#include <conio.h>
#include <fujinet-atari5200.h>

void main(void)
{
    clrscr();
    gotoxy(2, 2);
    cputs("HELLO FROM CONIO");
    gotoxy(2, 4);
    cputs(fuji_a5200_present() ? "CART FN OK" : "NO MAILBOX");
    for (;;)
        ;
}
