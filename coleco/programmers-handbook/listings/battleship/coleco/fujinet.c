#ifdef BUILD_COLECO

/**
 * @brief   FujiNet network + appkey hooks (CUSTOM_FUJINET_CALLS)
 * @author  Thomas Cherryhomes
 * @email   thom dot cherryhomes at gmail dot com
 * @license gpl v. 3, see LICENSE for details
 */

#include <stdint.h>
#include <fujinet-network.h>
#include <fujinet-fuji.h>
#include "vars.h"

static uint8_t initialized = 0;
static uint8_t channelOpen = 0;

/*
  The response is never copied into RAM. `buffer` is the cartridge's reply
  window (COLECO_REPLY_WINDOW, and see src/misc.h's clientState) and the game
  renders straight out of it, because the console has 1K of RAM and the state
  alone is 509 bytes. Two things follow:

  1. The read has to be ONE transaction. network_read()'s loop would copy its
     second chunk to `buffer + count`, which is cartridge ROM -- the store goes
     nowhere and the tail is lost, silently. network_read_nb() waits for the
     adapter to report bytes available and then issues exactly one read, so
     what the cartridge paints is the whole body. The window is 1K and the
     largest response is 509 bytes, so it always fits.

  2. Nothing may run after the read. Every mailbox transaction repaints the
     window, network_close() included, so closing here would destroy the reply
     before the caller ever looked at it. The channel is closed at the top of
     the NEXT call instead.
*/
int16_t custom_network_call(char *url, uint8_t *buffer, uint16_t max_len)
{
    if (!initialized)
    {
        if (network_init() != FN_ERR_OK)
            return -1;
        initialized = 1;
    }

    // The url handed in is the next request's, not the one that was opened,
    // but every url this client builds carries the bare "n:" prefix and so
    // resolves to the same network unit.
    if (channelOpen)
    {
        network_close(url);
        channelOpen = 0;
    }

    if (network_open(url, OPEN_MODE_HTTP_GET, OPEN_TRANS_NONE) != FN_ERR_OK)
        return -1;
    channelOpen = 1;

    return network_read_nb(url, buffer, max_len);
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

#endif /* BUILD_COLECO */
