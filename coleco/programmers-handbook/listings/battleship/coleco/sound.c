#ifdef BUILD_COLECO

/**
 * @brief   ColecoVision Sound Routines (SN76489)
 * @author  Thomas Cherryhomes
 * @email   thom dot cherryhomes at gmail dot com
 * @license gpl v. 3, see LICENSE for details
 *
 * The effect tables are the msdos port's PC-speaker frequencies. The SN76489's
 * tone floor is ~109Hz (10-bit divider from the 3.58MHz color clock), so the
 * sub-bass explosion effects (attack/hit/sink at 30-120Hz) play on the noise
 * channel instead of clamping into thin beeps.
 */

#include <stdint.h>
#include "../misc.h"

// The SN76489 sits at I/O port 0xFF (write only).
__sfr __at 0xFF psg_port;

static void sn_out(uint8_t b)
{
    psg_port = b;
}

/**
 * @brief Beep channel 0
 * @param hz Frequency in Hz
 * @param gate Tone-on time in vertical blanks
 * @param postGate Delay after tone off in vertical blanks
 */
static void beep(unsigned int hz, uint8_t gate, uint8_t postGate)
{
    uint16_t n;

    if (prefs.disableSound)
        return;

    n = 3579545UL / (32UL * hz);
    if (n > 1023)
        n = 1023;

    sn_out(0x80 | (n & 0x0F)); // channel 0 tone, low 4 bits
    sn_out((n >> 4) & 0x3F);   // high 6 bits
    sn_out(0x90 | 0x02);       // channel 0 attenuation -4dB

    while (gate--)
        waitvsync();

    sn_out(0x9F); // channel 0 off

    while (postGate--)
        waitvsync();
}

/**
 * @brief Noise burst for the explosion effects
 * @param ctrl noise control bits (0x04 = white; rate 0=high..2=low pitch)
 * @param gate Noise-on time in vertical blanks
 */
static void noise(uint8_t ctrl, uint8_t gate)
{
    if (prefs.disableSound)
        return;

    sn_out(0xE0 | ctrl);
    sn_out(0xF0 | 0x02); // noise attenuation -4dB

    while (gate--)
        waitvsync();

    sn_out(0xFF); // noise off
}

void initSound()
{
    // Silence all four channels - the 55AA cartridge header path skips the
    // BIOS power-on silencing
    sn_out(0x9F);
    sn_out(0xBF);
    sn_out(0xDF);
    sn_out(0xFF);
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
    beep(110, 1, 0);
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
    // Descending rumble: white noise, high to low shift rate
    noise(0x04, 4);
    noise(0x05, 4);
    noise(0x06, 4);
}

void soundHit()
{
    noise(0x04, 2);
    noise(0x05, 3);
    noise(0x06, 5);
}

void soundSink()
{
    noise(0x04, 4);
    noise(0x05, 6);
    noise(0x06, 10);
}

// Not applicable to coleco
void soundStop() {}
void disableKeySounds() {}
void enableKeySounds() {}

#endif /* BUILD_COLECO */
