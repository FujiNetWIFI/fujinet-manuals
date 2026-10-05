#ifdef BUILD_NES

/**
 * @brief   Utility Functions - NES
 * @author  Thomas Cherryhomes
 * @email   thom dot cherryhomes at gmail dot com
 * @license gpl v. 3, see LICENSE for details
 */

#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include "vars.h"
#include "../platform-specific/graphics.h"
#include "../platform-specific/util.h"

// cc65's NMI handler counts frames in clock(); the game timer is frames since
// the last resetTimer().
static clock_t timerBase;
static bool seeded;

/*
  cc65's own waitvsync() polls PPUSTATUS for the vblank flag. With NMI on that
  races the NMI: a read in the same cycle the flag rises suppresses the NMI,
  and with it that frame's ring-buffer flush. Waiting for the NMI's frame
  count to move instead is race-free, and needs NMI on, which it always is
  outside graphics.c's blitShadow().
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

uint8_t getRandomNumber(uint8_t maxExclusive)
{
    if (!seeded)
    {
        // Seeded from the frame count at the first request, which arrives
        // only after some human-paced input
        seeded = true;
        srand((unsigned int)clock());
    }
    return (uint8_t)(rand() % maxExclusive);
}

void housekeeping()
{
}

// quit() is in fujinet.c, with the rest of the cartridge calls.

#endif /* BUILD_NES */
