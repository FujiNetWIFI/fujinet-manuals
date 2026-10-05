#ifdef BUILD_NES

/**
 * @brief   Utility Functions - NES
 * @author  Thomas Cherryhomes
 * @email   thom dot cherryhomes at gmail dot com
 * @license gpl v. 3, see LICENSE for details
 */

#include <stdbool.h>
#include <stdint.h>
#include <time.h>
#include "../misc.h"
#include "../platform-specific/graphics.h"
#include "../platform-specific/util.h"

/* The server sends the packed wire layout straight into clientState.game,
 * so cc65 must not pad Game. Fails the build if it ever does. */
typedef char game_wire_size_check[(sizeof(Game) == 599) ? 1 : -1];

// cc65's NMI handler counts frames in clock(); the game timer is frames since
// the last resetTimer().
static clock_t timerBase;

/*
  cc65's own waitvsync() polls PPUSTATUS for the vblank flag. With NMI on that
  races the NMI: a read in the same cycle the flag rises suppresses the NMI,
  and with it that frame's ring-buffer flush. Waiting for the NMI's frame
  count to move instead is race-free, and needs NMI on, which it always is
  outside graphics.c's whole-screen copies.
*/
void waitvsync(void)
{
    uint8_t t = (uint8_t)clock();

    while ((uint8_t)clock() == t)
        ;
}

void resetTimer(void)
{
    timerBase = clock();
}

uint16_t getTime(void)
{
    return (uint16_t)(clock() - timerBase);
}

uint8_t getJiffiesPerSecond()
{
    return 60;
}

void housekeeping()
{
}

// quit() is in fujinet.c, with the rest of the cartridge calls.

#endif /* BUILD_NES */
