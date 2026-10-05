#ifdef BUILD_NES

/**
 * @brief   NES Sound Routines (2A03 APU, pulse channels 1+2)
 * @author  Thomas Cherryhomes
 * @email   thom dot cherryhomes at gmail dot com
 * @license gpl v. 3, see LICENSE for details
 */

#include <stdint.h>

void waitvsync(void);

#define PULSE1_CTRL   (*(volatile uint8_t *) 0x4000)
#define PULSE1_SWEEP  (*(volatile uint8_t *) 0x4001)
#define PULSE1_LO     (*(volatile uint8_t *) 0x4002)
#define PULSE1_HI     (*(volatile uint8_t *) 0x4003)
#define PULSE2_CTRL   (*(volatile uint8_t *) 0x4004)
#define PULSE2_SWEEP  (*(volatile uint8_t *) 0x4005)
#define PULSE2_LO     (*(volatile uint8_t *) 0x4006)
#define PULSE2_HI     (*(volatile uint8_t *) 0x4007)
#define APU_STATUS    (*(volatile uint8_t *) 0x4015)

#define PULSE_ON  0xBF          /* 50% duty, length halted, constant volume 15 */
#define PULSE_OFF 0xB0          /* same, volume 0 */

#define MIN_GATE  3             /* shorter blips are barely audible */

/**
 * @brief Brain dead beep routine
 * @param hz Frequency in Hz
 * @param gate Delay in vertical blanks
 * @param postGate Delay after tone off in vertical blanks
 */
void beep(int hz, int gate, int postGate)
{
    // 11-bit timer from the 1.79MHz CPU clock; the lowest reachable tone is
    // ~55Hz, so the sub-bass beeps clamp there.
    uint16_t t = 111861UL / (uint16_t)hz - 1;

    if (t > 0x7FF)
        t = 0x7FF;

    // Stretch short blips, taking the extra out of the rest so the cue
    // keeps its rhythm.
    if (gate < MIN_GATE)
    {
        postGate -= MIN_GATE - gate;
        if (postGate < 0)
            postGate = 0;
        gate = MIN_GATE;
    }

    // Both pulses in unison: one alone at volume 15 is quiet. The high
    // writes restart the phase, so back to back they stay in step.
    PULSE1_LO = PULSE2_LO = t & 0xFF;
    PULSE1_HI = t >> 8;
    PULSE2_HI = t >> 8;
    PULSE1_CTRL = PULSE2_CTRL = PULSE_ON;

    while (gate--)
        waitvsync();

    PULSE1_CTRL = PULSE2_CTRL = PULSE_OFF;

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
    APU_STATUS = 0x03;          /* pulse 1 and 2 */
    PULSE1_SWEEP = PULSE2_SWEEP = 0x08; /* sweep off, negate set so low notes are not muted */
    PULSE1_CTRL = PULSE2_CTRL = PULSE_OFF;
}

void soundTakeChip(uint16_t counter)
{
    beep(50+counter*20,2,2);
}

#endif /* BUILD_NES */
