/*
 * NETCAT.C --- a wire, in both directions
 *
 * The same program as NETCAT.ASM.  fujinet-lib builds the
 * frames; the five moves are still plainly visible.
 *
 *   cmoc -I$(FNDIR) -o NETCAT.BIN netcat.c -lfujinet
 *   LOADM"NETCAT":EXEC
 */

#include <cmoc.h>
#include <coco.h>
#include <fujinet-fuji.h>
#include <fujinet-network.h>

#define RXMAX  200              /* how much we take in one gulp */
#define KBREAK 3
#define KENTER 13
#define KBS    8

static char    spec[256];
static char    host[64];
static char    port[8];
static uint8_t rx[RXMAX];

/* Read a line, echoing as it goes.  BACKSPACE rubs out. */
static void getline_(char *buf, byte max)
{
    byte n = 0, k;

    for (;;)
    {
        k = waitkey(1);
        if (k == KENTER)
            break;
        if (k == KBS)
        {
            if (n) { n--; putchar(KBS); }
            continue;
        }
        if (k < ' ' || n >= max - 1)
            continue;
        buf[n++] = k;
        putchar(k);
    }
    buf[n] = '\0';
    putchar('\n');
}

int main(void)
{
    uint16_t bw, i;
    uint8_t  conn, err, k;
    int16_t  n;

    cls(1);
    printf("FUJINET NETCAT\n");

    printf("HOST? "); getline_(host, sizeof(host));
    printf("PORT? "); getline_(port, sizeof(port));

    strcpy(spec, "N:TCP://");
    strcat(spec, host);
    strcat(spec, ":");
    strcat(spec, port);

    printf("OPENING...\n");
    if (network_open(spec, OPEN_MODE_RW, OPEN_TRANS_NONE) != FN_ERR_OK)
    {
        printf("COULD NOT OPEN, ERROR %u\n", fn_device_error);
        return 1;
    }
    printf("CONNECTED. BREAK HANGS UP.\n");

    for (;;)
    {
        k = inkey();                    /* anything typed? */
        if (k == KBREAK)
            break;
        if (k)
            if (network_write(spec, &k, 1) != FN_ERR_OK)
                goto ioerr;

        if (network_status(spec, &bw, &conn, &err) != FN_ERR_OK)
            goto ioerr;

        if (bw)
        {
            if (bw > RXMAX)
                bw = RXMAX;             /* only what we can hold */
            n = network_read(spec, rx, bw);
            if (n < 0)
                goto ioerr;
            for (i = 0; i < (uint16_t) n; i++)
                putchar(rx[i]);
        }
        else if (!conn)
        {
            printf("\nTHE OTHER END CLOSED.\n");
            break;
        }
    }

    network_close(spec);
    printf("CHANNEL CLOSED.\n");
    return 0;

ioerr:
    printf("\nCHANNEL ERROR %u\n", fn_device_error);
    network_close(spec);
    return 1;
}
