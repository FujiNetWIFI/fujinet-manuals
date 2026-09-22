/*
 * FNSTAT.C --- who is on the other end of the wire, under OS-9
 *
 * The same question FCDEMO asks under Disk BASIC, and the same
 * two commands answer it.  Only DWRead and DWWrite changed.
 *
 *   cmoc --os9 -o fnstat fnstat.c fnbus.c dwport.c
 *   os9 copy fnstat /dd/CMDS/fnstat
 */

#include <cmoc.h>
#include "fnbus.h"

#define FUJI_ADAPTERCONFIG_EXTENDED 0xC4
#define CFGLEN 240

/* AdapterConfigExtended, by offset */
#define O_SSID      0           /* char[33]  */
#define O_VERSION   125         /* char[15]  */
#define O_LOCALIP   140         /* char[16], already dotted */

static byte cfg[CFGLEN];

int main(void)
{
    byte frame[2];
    byte e;

    frame[0] = 0xE2;
    frame[1] = FUJI_ADAPTERCONFIG_EXTENDED;

    e = fn_send(frame, sizeof(frame));
    if (e != FN_OK)
    {
        printf("fnstat: no answer, error %u\n", e);
        return 1;
    }

    e = fn_response(cfg, CFGLEN);
    if (e != FN_OK)
    {
        printf("fnstat: short reply, error %u\n", e);
        return 1;
    }

    printf("network  %s\n", (char *) &cfg[O_SSID]);
    printf("address  %s\n", (char *) &cfg[O_LOCALIP]);
    printf("firmware %s\n", (char *) &cfg[O_VERSION]);

    return 0;
}
