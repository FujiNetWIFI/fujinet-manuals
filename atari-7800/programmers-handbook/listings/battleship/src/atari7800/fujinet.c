#ifdef BUILD_ATARI7800

/**
 * @brief   FujiNet calls - Atari 7800 (CUSTOM_FUJINET_CALLS, and the lobby boot)
 * @author  Thomas Cherryhomes
 * @email   thom dot cherryhomes at gmail dot com
 * @license gpl v. 3, see LICENSE for details
 *
 * Everything that talks to the cartridge through fujinet-lib is in this one
 * file, because it has to see the LIBRARY's <fujinet-fuji.h>: as on the NES,
 * the atari7800 target implements most fuji_* calls as macros over its bus
 * call, so the prototypes in src/fujinet-fuji.h link against nothing. This
 * file therefore includes none of the shared headers (src/misc.h,
 * src/platform-specific/), and the shared code reaches the cartridge through
 * the CUSTOM_FUJINET_CALLS hooks instead.
 */

#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <fujinet-fuji.h>
#include <fujinet-network.h>
#include <fujinet-atari7800.h>
#include "vars.h"
#include "maria.h"

// graphics.c - declared here rather than through ../platform-specific, which
// would bring in src/fujinet-fuji.h
void drawText(uint8_t x, uint8_t y, const char *s);
void drawSpace(uint8_t x, uint8_t y, uint8_t w);

#define FUJI_HOST_SLOT_COUNT 8
#define LOBBY_DEVICE_SLOT 0
#define LOBBY_MODE_READ 1

int16_t custom_network_call(char *url, uint8_t *buffer, uint16_t max_len)
{
    int16_t read;

    // Show what has been drawn (palette changes wait for a frame) before
    // the transaction holds the 6502.
    mt_sync();

    if (network_open(url, OPEN_MODE_HTTP_GET, OPEN_TRANS_NONE) != FN_ERR_OK)
        return -1;

    read = network_read(url, buffer, max_len);
    network_close(url);
    return read;
}

uint16_t custom_read_appkey(uint16_t creator_id, uint8_t app_id, uint8_t key_id, char *destination)
{
    uint16_t read = 0;

    fuji_set_appkey_details(creator_id, app_id, DEFAULT);
    if (!fuji_read_appkey(key_id, &read, (uint8_t *)destination))
        read = 0;
    return read;
}

void custom_write_appkey(uint16_t creator_id, uint8_t app_id, uint8_t key_id, uint16_t count, char *data)
{
    fuji_set_appkey_details(creator_id, app_id, DEFAULT);
    fuji_write_appkey(key_id, count, (uint8_t *)data);
}

static void quitStatus(const char *s)
{
    drawSpace(0, HEIGHT - 1, WIDTH);
    drawText((WIDTH - (unsigned char)strlen(s)) / 2, HEIGHT - 1, s);
    mt_sync();
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
  SET_DEVICE_FULLPATH is a fixed 256-byte payload, so the path is padded
  here rather than at the call site. The path is CONFIG's lobby.
*/
static const char lobbyPath[MAX_FILENAME_LEN] = "/atari7800/lobby.a78";
static const char lobbyHost[] = "ec.tnfs.io";
static HostSlot slots[FUJI_HOST_SLOT_COUNT];

static uint8_t findLobbyHost(void)
{
    uint8_t i;

    if (!fuji_get_host_slots(slots, FUJI_HOST_SLOT_COUNT))
        return FUJI_HOST_SLOT_COUNT;

    for (i = 0; i < FUJI_HOST_SLOT_COUNT; i++)
        if (sameHost(lobbyHost, (const char *)slots[i]))
            return i;

    return FUJI_HOST_SLOT_COUNT;
}

// CONFIG's wait: the cart gives a push 60 seconds.
#define LOBBY_FRAMES 3900u

void quit(void)
{
    uint8_t slot, state, pct = 0xFF;
    uint16_t frames = 0;
    char pctText[5];

    quitStatus("LOADING LOBBY...");

    if (!fuji_a7800_present())
    {
        quitStatus("NO FUJINET CARTRIDGE");
        return;
    }

    // The slot is used as found, never created: a player who came through
    // the FujiNet Lobby already has the host.
    slot = findLobbyHost();
    if (slot == FUJI_HOST_SLOT_COUNT)
    {
        quitStatus("ADD EC.TNFS.IO IN CONFIG");
        return;
    }

    if (!fuji_mount_host_slot(slot)
        || !fuji_set_device_filename(LOBBY_MODE_READ, slot, LOBBY_DEVICE_SLOT, (char *)lobbyPath)
        || !fuji_mount_disk_image(LOBBY_DEVICE_SLOT, LOBBY_MODE_READ))
    {
        quitStatus("LOBBY NOT AVAILABLE");
        return;
    }

    // Some FujiNets push the image after answering MOUNT_IMAGE, so watch the
    // cart's own progress rather than trust the reply.
    for (;;)
    {
        state = fuji_a7800_boot_state();
        if (state == FUJI_A7800_BOOT_READY)
            break;
        if (state == FUJI_A7800_BOOT_FAILED || ++frames > LOBBY_FRAMES)
        {
            quitStatus("LOBBY LOAD FAILED");
            return;
        }
        if (fuji_a7800_boot_percent() != pct)
        {
            pct = fuji_a7800_boot_percent();
            utoa(pct, pctText, 10);
            strcat(pctText, "%");
            drawText(25, HEIGHT - 1, pctText);
        }
        mt_sync();
    }

    // Hand the console to the cartridge's loader. It does not return.
    fuji_a7800_boot();
}

#endif /* BUILD_ATARI7800 */
