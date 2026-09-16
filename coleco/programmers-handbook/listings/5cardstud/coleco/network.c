#ifdef BUILD_COLECO

/**
 * @brief   Network functions
 * @author  Thomas Cherryhomes
 * @email   thom dot cherryhomes at gmail dot com
 * @license gpl v. 3, see LICENSE for details
 */

#include <stdint.h>
#include <fujinet-network.h>
#include "vars.h"

static uint8_t initialized = 0;
static uint8_t channelOpen = 0;

/*
  The response is never copied into RAM. `buffer` is the cartridge's reply
  window (COLECO_REPLY_WINDOW, and see src/misc.h's clientState) and the game
  renders straight out of it, because the console has 1K of RAM and the state
  alone is 418 bytes. Two things follow, and both are the reason this is not
  simply src/adam/network.c:

  1. The read has to be ONE transaction. network_read()'s loop would copy its
     second chunk to `buffer + count`, which is cartridge ROM -- the store goes
     nowhere and the tail is lost, silently. network_read_nb() waits for the
     adapter to report bytes available and then issues exactly one FUJICMD_READ,
     so what the cartridge paints is the whole body. The window is 1K and the
     largest response here is 418 bytes, so it always fits; what has to hold on
     the wire is that FujiNet has buffered the entire body before it reports
     any of it available, which it does for an HTTP GET.

  2. Nothing may run after the read. Every mailbox transaction repaints the
     window, network_close() included, so closing here would destroy the reply
     before the caller ever looked at it. The channel is closed at the top of
     the NEXT call instead.
*/
uint8_t getResponse(char *url, unsigned char *buffer, uint16_t max_len)
{
    int16_t count;

    if (!initialized) {
        if (network_init() != FN_ERR_OK)
            return 0;
        initialized = 1;
    }

    // The url handed in is the next request's, not the one that was opened,
    // but every url this client builds carries the bare "N:" prefix and so
    // resolves to the same network unit.
    if (channelOpen) {
        network_close(url);
        channelOpen = 0;
    }

    // Don't read from a channel that never opened - network_read_nb() would
    // otherwise poll status on a dead unit and hand back whatever it got.
    if (network_open(url, OPEN_MODE_HTTP_GET_H, OPEN_TRANS_NONE) != FN_ERR_OK)
        return 0;
    channelOpen = 1;

    count = network_read_nb(url, buffer, max_len);

    return count > 0;
}

#endif /* BUILD_COLECO */
