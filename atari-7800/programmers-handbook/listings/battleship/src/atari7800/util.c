#ifdef BUILD_ATARI7800

/**
 * @brief   Utility Functions - Atari 7800
 * @author  Thomas Cherryhomes
 * @email   thom dot cherryhomes at gmail dot com
 * @license gpl v. 3, see LICENSE for details
 */

#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include "vars.h"
#include "maria.h"
#include "../platform-specific/graphics.h"
#include "../platform-specific/util.h"

// No interrupt counts frames on the 7800 (the engine uses no DLIs), so the
// game timer counts the vertical blanks the game waits for. Every loop that
// times something waits a frame per pass.
static uint16_t frames, timerBase;
static bool seeded;

/* mt_sync() also rebuilds the rows whose palettes changed: tiles show at
   once, palette changes only from here. */
void waitvsync(void)
{
    mt_sync();
    frames++;
}

void resetTimer(void)
{
    timerBase = frames;
}

uint16_t getTime(void)
{
    return frames - timerBase;
}

uint8_t getJiffiesPerSecond()
{
    return mt_pal ? 50 : 60;
}

uint8_t getRandomNumber(uint8_t maxExclusive)
{
    if (!seeded)
    {
        // Seeded from the frame count at the first request, which arrives
        // only after some human-paced input
        seeded = true;
        srand(frames);
    }
    return (uint8_t)(rand() % maxExclusive);
}

void housekeeping()
{
}

// quit() is in fujinet.c, with the rest of the cartridge calls.

#endif /* BUILD_ATARI7800 */
