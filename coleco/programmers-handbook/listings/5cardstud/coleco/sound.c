#ifdef BUILD_COLECO

/**
 * @brief   ColecoVision Sound Routines (SN76489)
 * @author  Thomas Cherryhomes
 * @email   thom dot cherryhomes at gmail dot com
 * @license gpl v. 3, see LICENSE for details
 */

#include <stdint.h>

void waitvsync(void);

// The SN76489 sits at I/O port 0xFF (write only).
__sfr __at 0xFF psg_port;

static void sn_out(uint8_t b)
{
    psg_port = b;
}

/**
 * @brief Brain dead beep routine
 * @param hz Frequency in Hz
 * @param gate Delay in vertical blanks
 * @param postGate Delay after tone off in vertical blanks
 */
void beep(int hz, int gate, int postGate)
{
    // 10-bit divider from the 3.58MHz color clock; lowest reachable
    // tone is ~109Hz, so the sub-bass beeps clamp there.
    uint16_t n = 3579545UL / (32UL * (uint16_t)hz);

    if (n > 1023)
        n = 1023;

    sn_out(0x80 | (n & 0x0F));      // channel 0 tone, low 4 bits
    sn_out((n >> 4) & 0x3F);        // high 6 bits
    sn_out(0x90 | 0x02);            // channel 0 attenuation -4dB

    while (gate--)
        waitvsync();

    sn_out(0x9F);                   // channel 0 off

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
    // Silence all four channels
    sn_out(0x9F);
    sn_out(0xBF);
    sn_out(0xDF);
    sn_out(0xFF);
}

void soundTakeChip(uint16_t counter)
{
    beep(50+counter*20,2,2);
}

#endif /* BUILD_COLECO */
