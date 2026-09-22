/*
 * FCDEMO.C --- First Contact
 *
 * The same program as FCDEMO.ASM, in C.  fujinet-lib does the
 * frame building; what is left is the part you came for.
 *
 *   cmoc -o FCDEMO.BIN fcdemo.c -lfujinet
 *   LOADM"FCDEMO":EXEC
 */

#include <cmoc.h>
#include <coco.h>
#include <fujinet-fuji.h>

int main(void)
{
    AdapterConfigExtended ac;

    putchar(12);                        /* clear the screen */
    printf("FUJINET FIRST CONTACT\n");

    if (!fuji_get_adapter_config_extended(&ac))
    {
        printf("NO ANSWER\n");
        return 1;
    }

    printf("NETWORK.. %s\n", ac.ssid);
    printf("ADDRESS.. %s\n", ac.sLocalIP);   /* already dotted text */
    printf("FIRMWARE. %s\n", ac.fn_version);

    return 0;
}
