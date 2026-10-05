#ifdef BUILD_NES

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
#include <time.h>
#include <fujinet-fuji.h>
#include <fujinet-nes.h>
#include "vars.h"
#include "../platform-specific/graphics.h"
#include "../platform-specific/util.h"

// The firmware's WRITE HOST SLOTS expects all 8 slots.
#define FUJI_HOST_SLOT_COUNT 8
#define LOBBY_DEVICE_SLOT 0
#define LOBBY_MODE_READ   1

// cc65's NMI handler counts frames in clock(); the game timer is frames since
// the last resetTimer().
static clock_t timerBase;

void resetTimer(void)
{
  timerBase = clock();
}

int getTime(void)
{
  return (int) (clock() - timerBase);
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
*/
static const char lobbyPath[MAX_FILENAME_LEN] = "nes/lobby.nes";
static const char lobbyHost[] = "ec.tnfs.io";

static HostSlot slots[FUJI_HOST_SLOT_COUNT];

static uint8_t findLobbyHost(void)
{
  uint8_t i;

  if (!fuji_get_host_slots(slots, FUJI_HOST_SLOT_COUNT))
    return FUJI_HOST_SLOT_COUNT;
  for (i = 0; i < FUJI_HOST_SLOT_COUNT; i++)
    if (sameHost(lobbyHost, (const char *) slots[i]))
      return i;
  return FUJI_HOST_SLOT_COUNT;
}

// The slot is used as found, never created: a player who reached this client
// through the FujiNet Lobby already has the host, and anyone else is told to
// add it in CONFIG.
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

  if (!fuji_nes_present())
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
    bootState = fuji_nes_boot_state();
    if (bootState == FUJI_NES_BOOT_READY)
      break;
    if (bootState == FUJI_NES_BOOT_FAILED)
    {
      drawStatusText("LOBBY LOAD FAILED");
      return;
    }
    if (fuji_nes_boot_percent() != pct)
    {
      pct = fuji_nes_boot_percent();
      itoa(pct, pctText, 10);
      strcat(pctText, "%");
      drawStatusTextAt(18, pctText);
    }
  }

  // Stop the firmware serving CONFIG at boot, then hand the console to the
  // cartridge's loader ROM. It does not return.
  fuji_set_boot_config(0);
  fuji_nes_boot();
}

#endif /* BUILD_NES */
