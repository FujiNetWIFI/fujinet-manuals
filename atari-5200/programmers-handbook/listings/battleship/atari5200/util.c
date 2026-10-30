#ifdef BUILD_ATARI5200

/**
 * @brief   Utility Functions - Atari 5200
 * @license gpl v. 3, see LICENSE for details
 */

#include <stdbool.h>
#include <stdint.h>
#include <peekpoke.h>
#include "vars.h"
#include "../platform-specific/util.h"

// The crt0's VBI keeps the BIOS's zero page: RTCLOK is two bytes, high then
// low, and ATRACT starts colour cycling once it passes $80.
#define RTCLOKH 0x01
#define RTCLOKL 0x02
#define ATRACT  0x04
#define PAL     0xC014
#define RANDOM  0xE80A

void resetTimer()
{
    POKEW(RTCLOKH, 0);
}

uint16_t getTime()
{
    uint8_t h, l;

    // The VBI carries into the high byte between the two reads
    do
    {
        h = PEEK(RTCLOKH);
        l = PEEK(RTCLOKL);
    } while (h != PEEK(RTCLOKH));

    return h * 256 + l;
}

void housekeeping()
{
    // Clear attract mode
    POKE(ATRACT, 0);
}

uint8_t getJiffiesPerSecond()
{
    return PEEK(PAL) == 1 ? 50 : 60;
}

uint8_t getRandomNumber(uint8_t maxExclusive)
{
    return PEEK(RANDOM) % maxExclusive;
}

// quit() is in fujinet.c, with the rest of the cartridge calls.

#endif /* BUILD_ATARI5200 */
