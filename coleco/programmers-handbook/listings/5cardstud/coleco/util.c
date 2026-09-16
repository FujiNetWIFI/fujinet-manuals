#ifdef BUILD_COLECO

/**
 * @brief   Utility Functions
 * @author  Thomas Cherryhomes
 * @email   thom dot cherryhomes at gmail dot com
 * @license gpl v. 3, see LICENSE for details
 */

#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <interrupt.h>
#include <fujinet-fuji.h>
#include <fujinet-coleco.h>
#include "vars.h"
#include "../platform-specific/graphics.h"

// The firmware's WRITE HOST SLOTS expects all 8 slots.
#define FUJI_HOST_SLOT_COUNT 8

#define LOBBY_DEVICE_SLOT 0
#define LOBBY_MODE_READ   1

volatile unsigned long currentTime;
static volatile bool vsync;

// Installed as the VDP interrupt hook by initGraphics() via add_raster_int().
// On this machine that hook is the vblank NMI: it cannot be masked, DI will not
// stop it, and it lands in the middle of mailbox transactions by design. That
// is harmless only for as long as it stays away from $F800 and up -- a handler
// that reads the mailbox pages corrupts whatever transaction it interrupted.
// Bumping two counters is safe; do not grow this.
void myInt(void)
{
  currentTime++;
  vsync=true;
}

void waitvsync(void)
{
  while(!vsync);
  vsync=false;
}

void resetTimer(void)
{
  currentTime = 0;
}

int getTime(void)
{
  return currentTime;
}

static bool sameHost(const char *a, const char *b)
{
  while (*a && *b)
  {
    if ((*a | 0x20) != (*b | 0x20))
      return false;
    a++;
    b++;
  }
  return *a == *b;
}

/*
  SET_DEVICE_FULLPATH is a fixed 256-byte payload -- a short one is rejected on
  the ESP32 side -- so the path is padded here rather than at the call site.
  In ROM, so the padding costs no RAM.
*/
static const char lobbyPath[MAX_FILENAME_LEN] = "coleco/lobby.rom";
static const char lobbyHost[] = "ec.tnfs.io";

/*
  The 8x32 host slot table is read IN PLACE out of the cartridge's reply window,
  the same way the game state is (see src/misc.h). READ_HOST_SLOTS is a single
  transaction and 256 bytes fit inside the 1K window, so the whole table is
  addressable ROM by the time the call returns -- which is the only way it is
  affordable at all on a 1K machine.
*/
static uint8_t findLobbyHost(void)
{
  HostSlot *slots = (HostSlot *) COLECO_REPLY_WINDOW;
  uint8_t i;

  if (!fuji_get_host_slots(slots, FUJI_HOST_SLOT_COUNT))
    return FUJI_HOST_SLOT_COUNT;

  for (i = 0; i < FUJI_HOST_SLOT_COUNT; i++)
    if (sameHost(lobbyHost, (const char *) slots[i]))
      return i;

  return FUJI_HOST_SLOT_COUNT;
}

/*
  The slot is used as found; it is never created. WRITE_HOST_SLOTS is
  all-or-nothing over the whole 8x32 table, and the seven slots that would have
  to be preserved only exist in the reply window, which cannot be patched -- so
  creating one means staging 256 bytes somewhere. There is nowhere: BSS would
  cost a quarter of the machine permanently, and the C stack here is 289 bytes.
  A player who reached this client through the FujiNet Lobby already has the
  host; anyone else is told to add it in CONFIG, which is a better outcome than
  a stack overflow at the one moment the game is handing the console away.
*/
static bool mountLobby(uint8_t slot)
{
  if (!fuji_mount_host_slot(slot))
    return false;
  if (!fuji_set_device_filename(LOBBY_MODE_READ, slot, LOBBY_DEVICE_SLOT,
                                (char *) lobbyPath))
    return false;

  // Only starts the transfer. The image is pushed to the cartridge
  // asynchronously, after this has already been answered.
  return fuji_mount_disk_image(LOBBY_DEVICE_SLOT, LOBBY_MODE_READ) != 0;
}

void quit(void)
{
  // Not `state`: src/misc.h defines that as a macro for the game state.
  uint8_t bootState, slot, pct = 0xFF;
  char pctText[5];

  drawStatusText("LOADING LOBBY...");

  if (!fuji_coleco_present())
  {
    drawStatusText("NO FUJINET CARTRIDGE");
    return;
  }

  slot = findLobbyHost();
  if (slot == FUJI_HOST_SLOT_COUNT)
  {
    drawStatusText("ADD EC.TNFS.IO IN CONFIG");
    return;
  }

  if (!mountLobby(slot))
  {
    drawStatusText("LOBBY NOT AVAILABLE");
    return;
  }

  // Watch the cartridge's own progress counter rather than guessing a delay.
  for (;;)
  {
    bootState = fuji_coleco_boot_state();

    if (bootState == FUJI_COLECO_BOOT_READY)
      break;
    if (bootState == FUJI_COLECO_BOOT_FAILED)
    {
      drawStatusText("LOBBY LOAD FAILED");
      return;
    }

    if (fuji_coleco_boot_percent() != pct)
    {
      pct = fuji_coleco_boot_percent();
      itoa(pct, pctText, 10);
      strcat(pctText, "%");
      drawStatusTextAt(18, pctText);
    }
  }

  // Stop the firmware serving CONFIG at boot, then hand the console over. The
  // swap does not return: every byte of $8000-$FFFF changes underneath it.
  fuji_set_boot_config(0);
  fuji_coleco_boot_swap();
}

#endif /* BUILD_COLECO */
