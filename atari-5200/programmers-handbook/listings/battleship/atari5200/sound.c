#ifdef BUILD_ATARI5200

/*
  Platform specific sound functions - Atari 5200

  The Atari 8-bit's cues, unchanged. There is no OS, so no _sound(): voice()
  stores AUDF/AUDC as it did. SKCTL stays as the crt0 set it (scanning the
  keypad, which also keeps POKEY out of initialisation, so the counters run).
*/

#include <stdlib.h>
#include "../misc.h"

#define POKEY(r) (*(volatile uint8_t *)(0xE800 + (r)))
#define AUDF(v) POKEY((v) * 2)
#define AUDC(v) POKEY((v) * 2 + 1)
#define AUDCTL POKEY(0x8)

static void voice(uint8_t v, uint8_t frequency, uint8_t distortion, uint8_t volume)
{
    AUDF(v) = frequency;
    AUDC(v) = (uint8_t)(distortion << 4) + volume;
}

void initSound()
{
    AUDCTL = 0;
    soundStop();
}

void sound(unsigned char v, unsigned char frequency, unsigned char distortion, unsigned char volume)
{
    if (!prefs.disableSound)
        voice(v, frequency, distortion, volume);
}

void note(uint8_t n, uint8_t n2, uint8_t n3, uint8_t d, uint8_t f, uint8_t p)
{
    static uint8_t i;
    if (prefs.disableSound)
        return;

    voice(0, n, 10, 8);
    if (n2)
        voice(1, n2, 10, 6);
    if (n3)
        voice(2, n3, 10, 4);

    pause(d);

    for (i = 7; i < 255; i--)
    {
        voice(0, n, 10, i);
        if (n2 && i > 1)
            voice(1, n2, 10, i - 2);
        if (n3 && i > 3)
            voice(2, n3, 10, i - 4);
        pause(f);
    }
    pause(p);
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

void soundMyTurn()
{
    static uint8_t i, j;
    for (j = 0; j < 2; j++)
    {
        sound(0, 81, 10, 5);
        pause(2);
        for (i = 6; i < 255; i--)
        {
            sound(0, 81, 10, i);
            waitvsync();
        }
        waitvsync();
    }
}

void soundGameDone()
{
    note(128, 204, 64, 6, 2, 0);
    note(96, 153, 193, 25, 2, 3);
    note(76, 128, 153, 6, 2, 0);
    note(96, 153, 193, 25, 2, 3);
}

void soundCursor()
{
    sound(0, 91, 10, 7);
    pause(1);
    sound(0, 91, 10, 3);
    pause(1);
    soundStop();
}

void soundPlaceShip()
{
    sound(0, 96, 10, 5);
    pause(2);
    sound(0, 81, 10, 4);
    pause(2);
    soundStop();
}

void soundTick()
{
    sound(0, 200, 8, 7);
    waitvsync();
    soundStop();
}

void soundSelect()
{
    sound(0, 96, 10, 5);
    pause(2);
    sound(0, 81, 10, 4);
    pause(2);
    soundStop();
}

void soundMiss()
{
    uint8_t i;
    for (i = 0; i < 10; i++)
    {
        sound(0, 0, 8, 4 - i / 2);
        pause(2);
    }
}

void soundInvalid()
{
    static uint8_t i;
    for (i = 6; i < 255; i--)
    {
        sound(0, 255 - i * 5, 10, i);
        waitvsync();
    }
}

void soundAttack()
{
    uint8_t i;
    for (i = 1; i < 8; i++)
    {
        sound(0, 200 + i, 2, 7 - i);
        pause(2);
    }
}

void soundHit()
{
    uint8_t i;
    for (i = 0; i < 10; i++)
    {
        sound(0, 80 + i, 0, 9 - i);
        pause(2);
    }
    soundStop();
}

void soundSink()
{
    uint8_t i;
    for (i = 0; i < 10; i++)
    {
        sound(0, 50 + i, 0, 9 - i);
        pause(1);
        sound(0, 80 + i, 0, 9 - i);
        pause(1);
    }
    soundStop();
}

void soundStop()
{
    voice(0, 0, 0, 0);
}

// No key click to silence: the keypad is read through the IRQ, not the OS
void disableKeySounds()
{
}

void enableKeySounds()
{
}

#endif /* BUILD_ATARI5200 */
