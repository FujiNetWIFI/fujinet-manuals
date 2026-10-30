#ifdef BUILD_ATARI5200

/**
 * @brief   Atari 5200 Sound Routines (POKEY)
 * @author  Thomas Cherryhomes
 * @email   thom dot cherryhomes at gmail dot com
 * @license gpl v. 3, see LICENSE for details
 */

#include <stdint.h>
#include "vars.h"
#include "../platform-specific/graphics.h"

/* The console's POKEY. SKCTL stays as the crt0 set it: scanning the keypad,
   which also keeps POKEY out of initialisation, so the counters run. */
#define POKEY(r)  (*(volatile uint8_t *)(0xE800 + (r)))
#define AUDF1     POKEY(0x0)
#define AUDC1     POKEY(0x1)
#define AUDF2     POKEY(0x2)
#define AUDC2     POKEY(0x3)
#define AUDCTL    POKEY(0x8)

/* Channels 1 and 2 joined into one 16-bit divider on the 1.79MHz clock, so
   the sub-bass beeps and the high ones are both in reach. */
#define AUDCTL_179_JOINED 0x50
#define TONE_ON   0xA8          /* pure tone, volume 8 */
#define TONE_OFF  0x00

#define MIN_GATE  3             /* shorter blips are barely audible */

/**
 * @brief Brain dead beep routine
 * @param hz Frequency in Hz
 * @param gate Delay in vertical blanks
 * @param postGate Delay after tone off in vertical blanks
 */
void beep(int hz, int gate, int postGate)
{
    // f = 1789773 / (2 * (N + 7)) in the joined mode.
    uint16_t n = (uint16_t)(894886UL / (uint16_t)hz) - 7;

    // Stretch short blips, taking the extra out of the rest so the cue
    // keeps its rhythm.
    if (gate < MIN_GATE)
    {
        postGate -= MIN_GATE - gate;
        if (postGate < 0)
            postGate = 0;
        gate = MIN_GATE;
    }

    AUDF1 = n & 0xFF;
    AUDF2 = n >> 8;
    AUDC2 = TONE_ON;

    while (gate--)
        waitvsync();

    AUDC2 = TONE_OFF;

    while (postGate--)
        waitvsync();
}

void soundDealCard()
{
    beep(150,1,5);
}

void soundJoinGame()
{
    beep(430,5,8);
    beep(340,5,0);
    beep(500,5,0);
}

void soundPlayerLeft()
{
    uint8_t i;
    for (i=80;i>=50;i-=10)
        beep(i,2,15);
}

void soundPlayerJoin()
{
    uint8_t i;
    for (i=50;i<=80;i+=10)
        beep(i,2,15);
}

void soundGameDone()
{
    beep(311,10,0);
    beep(330,20,0);
    beep(392,10,0);
    beep(415,20,0);
}

void soundMyTurn()
{
    beep(430,4,2);
    beep(430,4,2);
}

void soundTick()
{
    beep(50,2,0);
}

void soundCursor()
{
    beep(300,2,0);
}

void soundCursorInvalid()
{
    beep(100,2,0);
}

void soundSelectMove()
{
    beep(300,3,1);
    beep(350,3,0);
}

void initSound()
{
    AUDCTL = AUDCTL_179_JOINED;
    AUDC1 = TONE_OFF;           /* the joined pair sounds on channel 2 only */
    AUDC2 = TONE_OFF;
}

void soundTakeChip(uint16_t counter)
{
    beep(50+counter*20,2,2);
}

#endif /* BUILD_ATARI5200 */
