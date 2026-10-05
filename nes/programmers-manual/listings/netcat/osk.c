/* osk.c -- an on-screen keyboard.
 *
 * Thirteen keys across, four rows of characters and a row of actions,
 * double-spaced because the font has no gap between rows. The
 * D-pad moves the highlight, A presses the key under it; B is a shortcut for
 * DEL, Start for DONE and Select for SHIFT. */

#include <conio.h>
#include "osk.h"
#include "pad.h"

#define COLS 13
#define LEFT  3                         /* screen column of the first key */

static const char keys[4][COLS + 1] = {
  "ABCDEFGHIJKLM",
  "NOPQRSTUVWXYZ",
  "0123456789.:/",
  "-_?=&@#%+~,;!",
};

/* The action row: where each label starts and which key columns pick it. */
static const char *const label[4] = { "SHIFT", "SPACE", "DEL", "DONE" };
static const uint8_t lx[4]   = { 3, 10, 17, 23 };
static const uint8_t first[4] = { 0, 3, 7, 10 };   /* key column -> label */

static uint8_t top, kx, ky, shift;

static uint8_t action(uint8_t x)
{
  uint8_t a = 3;

  while (x < first[a])
    --a;
  return a;
}

static char keychar(uint8_t y, uint8_t x)
{
  char c = keys[y][x];

  if (shift && y < 2)
    c += 'a' - 'A';
  return c;
}

/* Draw one key, highlighted or not. */
static void key(uint8_t y, uint8_t x, uint8_t on)
{
  revers(on);
  if (y < 4)
    cputcxy(LEFT + 2 * x, top + 2 * y, keychar(y, x));
  else
    cputsxy(lx[action(x)], top + 8, label[action(x)]);
  revers(0);
}

static void letters(void)
{
  uint8_t y, x;

  for (y = 0; y < 2; y++)
    for (x = 0; x < COLS; x++)
      key(y, x, y == ky && x == kx);
}

void osk_draw(uint8_t t)
{
  uint8_t y, x;

  top = t;
  for (y = 0; y < 4; y++)
    for (x = 0; x < COLS; x++)
      key(y, x, 0);
  for (x = 0; x < 4; x++)
    cputsxy(lx[x], top + 8, label[x]);
  key(ky, kx, 1);
}

static char press(void)
{
  if (ky < 4)
    return keychar(ky, kx);
  switch (action(kx)) {
  case 0:  shift ^= 1; letters(); return 0;
  case 1:  return ' ';
  case 2:  return OSK_DEL;
  default: return OSK_DONE;
  }
}

char osk_input(uint8_t pad)
{
  uint8_t ox = kx, oy = ky;

  if (pad & PAD_LEFT)  kx = kx ? kx - 1 : COLS - 1;
  if (pad & PAD_RIGHT) kx = kx < COLS - 1 ? kx + 1 : 0;
  if (pad & PAD_UP)    ky = ky ? ky - 1 : 4;
  if (pad & PAD_DOWN)  ky = ky < 4 ? ky + 1 : 0;

  if (kx != ox || ky != oy) {
    key(oy, ox, 0);                     /* also clears a whole action label */
    key(ky, kx, 1);
  }

  if (pad & PAD_A)      return press();
  if (pad & PAD_B)      return OSK_DEL;
  if (pad & PAD_START)  return OSK_DONE;
  if (pad & PAD_SELECT) { shift ^= 1; letters(); }
  return 0;
}
