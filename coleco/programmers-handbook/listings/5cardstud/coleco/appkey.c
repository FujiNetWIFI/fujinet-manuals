#ifdef BUILD_COLECO

/**
 * @brief   ColecoVision App Key Functions
 * @author  Thomas Cherryhomes
 * @email   thom dot cherryhomes at gmail dot com
 * @license gpl v. 3, see LICENSE for details
 */

#include <stdint.h>
#include <string.h>
#include <fujinet-fuji.h>

#include "../platform-specific/appkey.h"

void read_appkey(unsigned int creator_id, unsigned char app_id, unsigned char key_id, char *data)
{
    uint16_t read = 0;

    fuji_set_appkey_details(creator_id, app_id, DEFAULT);
    if (!fuji_read_appkey(key_id, &read, (uint8_t *) data))
        read = 0;

    // Terminate as a string. Callers hand us the shared tempBuffer scratch
    // global and then strlen() it, so this has to happen even on failure or
    // they read back whatever the previous screen left behind.
    data[read] = 0;
}

void write_appkey(unsigned int creator_id, unsigned char app_id, unsigned char key_id, const char *data)
{
    fuji_set_appkey_details(creator_id, app_id, DEFAULT);
    fuji_write_appkey(key_id, strlen(data), (uint8_t *) data);
}

#endif /* BUILD_COLECO */
