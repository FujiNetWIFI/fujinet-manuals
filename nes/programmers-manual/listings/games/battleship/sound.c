#ifdef BUILD_NES

/**
 * @brief   NES Sound Routines (2A03 APU)
 * @author  Thomas Cherryhomes
 * @email   thom dot cherryhomes at gmail dot com
 * @license gpl v. 3, see LICENSE for details
 *
 * The cue table is the msdos port's PC-speaker one, which every C client
 * shares. Tones play on both pulse channels in unison (one alone at full
 * volume is quiet). The explosions -- attack, hit, sink -- are msdos sweeps
 * between 120 and 30Hz: below the pulse channels' ~55Hz floor, which is why
 * the ColecoVision port gave them up for noise. The triangle reaches 27Hz, so
 * here the sweep plays as written on the triangle, with the ColecoVision's
 * noise burst layered over it, falling in pitch and fading out.
 */

#include <stdint.h>
#include <stdlib.h>
#include "../misc.h"

#define PULSE1_CTRL   (*(volatile uint8_t *) 0x4000)
#define PULSE1_SWEEP  (*(volatile uint8_t *) 0x4001)
#define PULSE1_LO     (*(volatile uint8_t *) 0x4002)
#define PULSE1_HI     (*(volatile uint8_t *) 0x4003)
#define PULSE2_CTRL   (*(volatile uint8_t *) 0x4004)
#define PULSE2_SWEEP  (*(volatile uint8_t *) 0x4005)
#define PULSE2_LO     (*(volatile uint8_t *) 0x4006)
#define PULSE2_HI     (*(volatile uint8_t *) 0x4007)
#define TRI_CTRL      (*(volatile uint8_t *) 0x4008)
#define TRI_LO        (*(volatile uint8_t *) 0x400A)
#define TRI_HI        (*(volatile uint8_t *) 0x400B)
#define NOISE_CTRL    (*(volatile uint8_t *) 0x400C)
#define NOISE_PERIOD  (*(volatile uint8_t *) 0x400E)
#define NOISE_LEN     (*(volatile uint8_t *) 0x400F)
#define APU_STATUS    (*(volatile uint8_t *) 0x4015)

#define PULSE_ON  0xBF  /* 50% duty, length halted, constant volume 15 */
#define PULSE_OFF 0xB0  /* same, volume 0 */
#define TRI_ON    0xFF  /* linear counter reloaded every frame: sustained */
#define TRI_OFF   0x80  /* linear counter 0: silent */
#define NOISE_VOL 0x30  /* length halted, constant volume (OR in 0-15) */

#define MIN_GATE  3     /* shorter pulse blips are barely audible */

/**
 * @brief Beep the pulse channels
 * @param hz Frequency in Hz
 * @param gate Tone-on time in vertical blanks
 * @param postGate Delay after tone off in vertical blanks
 */
static void beep(unsigned int hz, uint8_t gate, uint8_t postGate)
{
    // 11-bit timer from the 1.79MHz CPU clock
    uint16_t t = 111861UL / hz - 1;

    if (prefs.disableSound)
        return;

    if (t > 0x7FF)
        t = 0x7FF;

    // Stretch short blips, taking the extra out of the rest so the cue
    // keeps its rhythm.
    if (gate < MIN_GATE)
    {
        postGate = postGate > MIN_GATE - gate ? postGate - (MIN_GATE - gate) : 0;
        gate = MIN_GATE;
    }

    // The high writes restart the phase, so back to back they stay in step.
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

/**
 * @brief One step of an explosion: the triangle at hz under a noise burst
 * @param hz Triangle frequency in Hz, 0 for noise alone
 * @param noise Noise period index, 0 (hiss) - 15 (rumble)
 * @param vol Noise volume, 0-15
 * @param gate Time in vertical blanks
 */
static void boom(unsigned int hz, uint8_t noise, uint8_t vol, uint8_t gate)
{
    uint16_t t;

    if (prefs.disableSound)
        return;

    if (hz)
    {
        // The triangle steps through 32 levels, so it runs at half the
        // pulse channels' rate for the same note.
        t = 55930UL / hz - 1;
        TRI_LO = t & 0xFF;
        TRI_HI = t >> 8;
        TRI_CTRL = TRI_ON;
    }
    else
        TRI_CTRL = TRI_OFF;

    NOISE_PERIOD = noise;
    NOISE_CTRL = NOISE_VOL | vol;
    NOISE_LEN = 0x08;

    while (gate--)
        waitvsync();

    TRI_CTRL = TRI_OFF;
    NOISE_CTRL = NOISE_VOL;
}

/**
 * @brief Let the explosion's noise ring out, fading from vol to silence
 */
static void tail(uint8_t noise, uint8_t vol, uint8_t step)
{
    while (vol)
    {
        boom(0, noise, vol, step);
        vol--;
    }
}

void initSound()
{
    APU_STATUS = 0x0F;                  /* pulse 1, pulse 2, triangle, noise */
    PULSE1_SWEEP = PULSE2_SWEEP = 0x08; /* sweep off, negate set so low notes are not muted */
    PULSE1_CTRL = PULSE2_CTRL = PULSE_OFF;
    TRI_CTRL = TRI_OFF;
    NOISE_CTRL = NOISE_VOL;
}

void soundJoinGame()
{
    beep(430, 5, 8);
    beep(340, 5, 0);
    beep(500, 5, 0);
}

void soundMyTurn()
{
    beep(430, 4, 2);
    beep(430, 4, 2);
}

void soundGameDone()
{
    beep(311, 10, 0);
    beep(330, 20, 0);
    beep(392, 10, 0);
    beep(415, 20, 0);
}

void soundCursor()
{
    beep(300, 1, 0);
}

void soundPlaceShip()
{
    beep(300, 3, 1);
    beep(350, 3, 0);
}

void soundTick()
{
    beep(100, 1, 0);
}

void soundSelect()
{
    beep(350, 2, 1);
    beep(250, 2, 0);
    beep(150, 2, 0);
}

void soundMiss()
{
    beep(150, 1, 0);
    beep(170, 1, 0);
}

void soundInvalid()
{
    beep(150, 2, 2);
    beep(150, 2, 0);
}

void soundAttack()
{
    // msdos: three jittered ~90Hz blips, two ~70Hz, one ~60Hz - the shot
    // leaving. The noise starts as a hiss and drops.
    uint8_t i;

    for (i = 0; i < 3; i++)
        boom(90 + (rand() & 1), 0x09, 10, 2);
    for (i = 0; i < 2; i++)
        boom(70 + (rand() & 1), 0x0B, 8, 2);
    boom(60 + (rand() & 1), 0x0C, 6, 2);
}

void soundHit()
{
    // msdos: 70 down to 30Hz in steps of 10
    uint8_t i, n = 0x0B;

    for (i = 70; i >= 30; i -= 10)
        boom(i, n++, 15, 2);
    tail(0x0F, 10, 2);
}

void soundSink()
{
    // msdos: 120 down to 60Hz in steps of 10, then a long rumble
    uint8_t i, n = 0x09;

    for (i = 120; i >= 60; i -= 10)
        boom(i, n++, 15, 2);
    tail(0x0F, 15, 3);
}

// Not applicable to the NES
void soundStop() {}
void disableKeySounds() {}
void enableKeySounds() {}

#endif /* BUILD_NES */
