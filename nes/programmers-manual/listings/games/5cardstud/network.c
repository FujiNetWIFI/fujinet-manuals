#ifdef BUILD_NES

/**
 * @brief   Network functions
 * @author  Thomas Cherryhomes
 * @email   thom dot cherryhomes at gmail dot com
 * @license gpl v. 3, see LICENSE for details
 */

#include <stdint.h>
#include <fujinet-network.h>

static uint8_t initialized = 0;

uint8_t getResponse(char *url, unsigned char *buffer, uint16_t max_len)
{
    int16_t count;

    if (!initialized) {
        if (network_init() != FN_ERR_OK)
            return 0;
        initialized = 1;
    }

    // Don't read from a channel that never opened - network_read() would
    // otherwise poll status on a dead unit and hand back whatever it got.
    if (network_open(url, OPEN_MODE_HTTP_GET_H, OPEN_TRANS_NONE) != FN_ERR_OK)
        return 0;

    count = network_read(url, buffer, max_len);
    network_close(url);

    return count > 0;
}

#endif /* BUILD_NES */
