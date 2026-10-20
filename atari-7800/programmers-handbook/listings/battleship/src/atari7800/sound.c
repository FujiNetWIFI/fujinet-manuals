#ifdef BUILD_ATARI7800

/**
 * @brief   Atari 7800 Sound Routines (the cartridge's POKEY at $0450)
 * @author  Thomas Cherryhomes
 * @email   thom dot cherryhomes at gmail dot com
 * @license gpl v. 3, see LICENSE for details
 *
 * The NES port's cues (src/nes/sound.c), which are the msdos PC-speaker
 * table. Never the TIA: its registers are INPTCTRL until locked. Tones are
 * channels 1+2 joined into 16 bits off the 1.79MHz clock, which reaches the
 * whole table exactly. The explosions sweep 120-30Hz on channels 3+4 joined
 * the same way, where the NES used its triangle, with the noise burst on
 * channel 1.
 */

#include <stdint.h>
#include <stdlib.h>
#include "../misc.h"

#define POKEY(r)  (*(volatile uint8_t *)(0x0450 + (r)))
#define AUDF1     POKEY(0x0)
#define AUDC1     POKEY(0x1)
#define AUDF2     POKEY(0x2)
#define AUDC2     POKEY(0x3)
#define AUDF3     POKEY(0x4)
#define AUDC3     POKEY(0x5)
#define AUDF4     POKEY(0x6)
#define AUDC4     POKEY(0x7)
#define AUDCTL    POKEY(0x8)
#define SKCTL     POKEY(0xF)

#define CTL_TONE  0x50  /* 1+2 joined, channel 1 at 1.79MHz */
#define CTL_BOOM  0x28  /* 3+4 joined, channel 3 at 1.79MHz; 1 and 2 at 64kHz */
#define PURE      0xA0  /* AUDC: pure tone; the low nibble is the volume */
#define NOISE     0x80  /* AUDC: the 17-bit poly, white noise */

#define TONE_VOL  10
#define BOOM_VOL  8

#define MIN_GATE  3     /* shorter blips are barely audible */

/* 16-bit divider for hz off the 1.79MHz clock */
static uint16_t divider(unsigned int hz)
{
    return (uint16_t)(894886UL / hz - 7);
}

/* The NES noise periods 9-15 (hiss to rumble) as channel 1 dividers at 64kHz */
static const uint8_t noiseF[7] = {8, 13, 17, 26, 35, 72, 144};

/**
 * @brief Beep
 * @param hz Frequency in Hz
 * @param gate Tone-on time in vertical blanks
 * @param postGate Delay after tone off in vertical blanks
 */
static void beep(unsigned int hz, uint8_t gate, uint8_t postGate)
{
    uint16_t n;

    if (prefs.disableSound)
        return;

    n = divider(hz);

    // Stretch short blips, taking the extra out of the rest so the cue
    // keeps its rhythm.
    if (gate < MIN_GATE)
    {
        postGate = postGate > MIN_GATE - gate ? postGate - (MIN_GATE - gate) : 0;
        gate = MIN_GATE;
    }

    AUDCTL = CTL_TONE;
    AUDF1 = n & 0xFF;
    AUDF2 = n >> 8;
    AUDC1 = 0;
    AUDC2 = PURE | TONE_VOL;

    while (gate--)
        waitvsync();

    AUDC2 = PURE;

    while (postGate--)
        waitvsync();
}

/**
 * @brief One step of an explosion: a tone at hz under a noise burst
 * @param hz Tone frequency in Hz, 0 for noise alone
 * @param noise NES noise period index, 9 (hiss) - 15 (rumble)
 * @param vol Noise volume, 0-15
 * @param gate Time in vertical blanks
 */
static void boom(unsigned int hz, uint8_t noise, uint8_t vol, uint8_t gate)
{
    uint16_t n;

    if (prefs.disableSound)
        return;

    AUDCTL = CTL_BOOM;
    if (hz)
    {
        n = divider(hz);
        AUDF3 = n & 0xFF;
        AUDF4 = n >> 8;
        AUDC3 = 0;
        AUDC4 = PURE | BOOM_VOL;
    }
    else
        AUDC4 = PURE;

    AUDF1 = noiseF[noise - 9];
    AUDC1 = NOISE | (vol * 3 >> 2);

    while (gate--)
        waitvsync();

    AUDC4 = PURE;
    AUDC1 = NOISE;
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
    SKCTL = 0;
    SKCTL = 3;      /* out of initialisation: the counters run */
    AUDCTL = 0;
    AUDC1 = 0;
    AUDC2 = 0;
    AUDC3 = 0;
    AUDC4 = 0;
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

// Not applicable to the 7800
void soundStop() {}
void disableKeySounds() {}
void enableKeySounds() {}

#endif /* BUILD_ATARI7800 */
