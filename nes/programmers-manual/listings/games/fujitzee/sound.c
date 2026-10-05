#ifdef BUILD_NES

/**
 * @brief   NES Sound Routines (2A03 APU)
 * @author  Thomas Cherryhomes
 * @email   thom dot cherryhomes at gmail dot com
 * @license gpl v. 3, see LICENSE for details
 *
 * The cue set is the Adam port's (src/adam/sound.c), which is itself the
 * Atari POKEY set transposed, so sound() keeps the POKEY-style (voice,
 * frequency, distortion, volume) interface and converts:
 *
 *   - frequency: POKEY 64kHz divisor f is 63921/(2*(f+1)) Hz. A pulse
 *     channel's timer for that is 1789773/(16*Hz) - 1, which works out to
 *     7*(f+1)/2 - 1 -- the Adam's SN76489 period less one. The triangle
 *     steps through 32 levels rather than 16, so its timer is half that.
 *   - voices: the Adam's three tone generators become pulse 1, pulse 2 and
 *     the triangle, so the chords in note() keep all three notes. The
 *     triangle has no volume control; it plays until its voice's volume
 *     reaches zero.
 *   - distortion 10 is a pure tone; anything else is the noise channel, the
 *     POKEY divisor picking one of its sixteen periods.
 *   - volume: the Adam's 0-8 scaled by 1.5 into the APU's 0-15.
 */

#include <stdint.h>
#include <stdlib.h>
#include "../misc.h"
#include "../platform-specific/sound.h"

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

#define PULSE_VOL 0xB0  /* 50% duty, length halted, constant volume (OR 0-15) */
#define TRI_ON    0xFF  /* linear counter reloaded every frame: sustained */
#define TRI_OFF   0x80  /* linear counter 0: silent */
#define NOISE_VOL 0x30  /* length halted, constant volume (OR in 0-15) */

/* The last high timer byte written to each pulse channel. Writing it
   restarts the waveform, which clicks, so a decay that only changes the
   volume leaves it alone. 0xFF is never a valid high byte. */
static uint8_t pulseHi[2];

void soundStop()
{
    PULSE1_CTRL = PULSE_VOL;
    PULSE2_CTRL = PULSE_VOL;
    TRI_CTRL = TRI_OFF;
    NOISE_CTRL = NOISE_VOL;
}

static uint8_t apuVol(uint8_t volume)
{
    volume += volume >> 1;
    return volume > 15 ? 15 : volume;
}

static void sound(uint8_t voice, uint8_t frequency, uint8_t distortion, uint8_t volume)
{
    static uint16_t t;
    static uint8_t hi;

    if (prefs.disableSound)
        return;

    if (!volume)
    {
        soundStop();
        return;
    }

    if (distortion != 10)
    {
        // POKEY divisors 150-245 (the dice rattle, the clock tick) onto the
        // noise channel's mid periods, higher divisor = lower rumble.
        NOISE_PERIOD = 4 + (frequency >> 5);
        NOISE_CTRL = NOISE_VOL | apuVol(volume);
        NOISE_LEN = 0x08;
        return;
    }

    t = (((uint16_t)frequency + 1) * 7 >> 1) - 1;

    if (voice == 2)
    {
        t >>= 1;
        TRI_LO = (uint8_t)t;
        TRI_HI = (uint8_t)(t >> 8);
        TRI_CTRL = TRI_ON;
        return;
    }

    hi = (uint8_t)(t >> 8);
    if (voice == 0)
    {
        PULSE1_CTRL = PULSE_VOL | apuVol(volume);
        PULSE1_LO = (uint8_t)t;
        if (hi != pulseHi[0])
            PULSE1_HI = pulseHi[0] = hi;
    }
    else
    {
        PULSE2_CTRL = PULSE_VOL | apuVol(volume);
        PULSE2_LO = (uint8_t)t;
        if (hi != pulseHi[1])
            PULSE2_HI = pulseHi[1] = hi;
    }
}

static void note(uint8_t n, uint8_t n2, uint8_t n3, uint8_t d, uint8_t f, uint8_t p)
{
    static uint8_t i;

    if (prefs.disableSound)
        return;

    sound(0, n, 10, 8);
    if (n2)
        sound(1, n2, 10, 6);
    if (n3)
        sound(2, n3, 10, 4);

    pause(d);

    for (i = 7; i < 255; i--)
    {
        sound(0, n, 10, i);
        if (n2 && i > 1)
            sound(1, n2, 10, i - 2);
        if (n3 && i == 3)
            TRI_CTRL = TRI_OFF; // the triangle has no volume: cut it where the Adam's voice 3 falls silent
        pause(f);
    }
    soundStop();
    pause(p);
}

void initSound()
{
    APU_STATUS = 0x0F;                  /* pulse 1, pulse 2, triangle, noise */
    PULSE1_SWEEP = PULSE2_SWEEP = 0x08; /* sweep off, negate set so low notes are not muted */
    pulseHi[0] = pulseHi[1] = 0xFF;
    soundStop();
}

void soundJoinGame()
{
    static uint8_t j;
    for (j = 0; j < 2; j++)
    {
        note(81, 0, 0, 0, 1, 0);
        if (j == 0)
            note(96, 0, 0, 0, 1, 0);
    }
}

void soundFujitzee()
{
    note(76, 153, 0, 5, 0, 0);
    note(57, 230, 0, 5, 0, 0);
    note(45, 182, 0, 5, 0, 0);
    note(37, 153, 0, 5, 1, 2);
    note(45, 182, 0, 5, 0, 0);
    note(37, 153, 0, 6, 2, 0);
}

void soundMyTurn()
{
    static uint8_t i;

    sound(0, 81, 10, 5);
    pause(2);
    for (i = 7; i < 255; i--)
    {
        sound(0, 81, 10, i);
        waitvsync();
    }
    waitvsync();
    soundStop();
}

void soundGameDone()
{
    note(128, 204, 64, 6, 2, 0);
    note(96, 153, 193, 25, 2, 3);
    note(85, 144, 172, 6, 2, 0);
    note(76, 128, 153, 30, 3, 0);
}

void soundRollDice()
{
    // Distortion 8 takes the noise path; retriggered every roll frame
    sound(0, 150 + (rand() % 20) * 5, 8, 8);
}

void soundRollButton()
{
    sound(0, 96, 10, 5);
    pause(2);
    sound(0, 81, 10, 4);
    pause(2);
    soundStop();
}

void soundCursor()
{
    sound(0, 102, 10, 7);
    pause(1);
    soundStop();
}

void soundScoreCursor()
{
    sound(0, 91, 10, 7);
    pause(1);
    soundStop();
}

void soundKeep()
{
    static uint8_t i, j;
    j = 0;
    for (i = 200; i > 150; i -= 10)
    {
        sound(0, i, 10, 3 + j++);
        waitvsync();
    }
    soundStop();
}

void soundRelease()
{
    static uint8_t i;
    for (i = 6; i < 255; i--)
    {
        sound(0, 255 - i * 5, 10, i);
        waitvsync();
    }
    soundStop();
}

void soundTick()
{
    sound(0, 200, 8, 7);
    waitvsync();
    soundStop();
}

void soundScore()
{
    static uint8_t i, j;
    j = 0;
    for (i = 80; i > 50; i -= 10)
    {
        sound(0, i, 10, 4 + j++);
        waitvsync();
    }
    soundStop();
}

void disableKeySounds()
{
}

void enableKeySounds()
{
}

#endif /* BUILD_NES */
