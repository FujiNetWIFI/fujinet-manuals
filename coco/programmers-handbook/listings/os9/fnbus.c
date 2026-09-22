/*
 * FNBUS.C --- the four moves, rebuilt above your own transport
 *
 * fujinet-lib's Color Computer build calls the Disk BASIC ROM
 * directly, so it cannot be linked into an OS-9 module.  This
 * file is the part of it that matters, written against DWPORT
 * instead.  Compare it with FNLOW.ASM: same four routines,
 * same order, same three-step handshake.
 */

#include <cmoc.h>
#include "dwport.h"
#include "fnbus.h"

#define OP_FUJI     0xE2
#define FN_READY    0x00
#define FN_RESPONSE 0x01
#define FN_ERROR    0x02

#define E_GENERAL   144

/* Block until the adapter answers.  It is allowed to be busy. */
void fn_wait(void)
{
    byte frame[2];
    byte r;

    frame[0] = OP_FUJI;
    frame[1] = FN_READY;

    do
    {
        dwwrite(frame, sizeof(frame));
    }
    while (!dwread(&r, 1));
}

/* Ask how the last command went.  1 means it went well. */
byte fn_error(void)
{
    byte frame[2];
    byte e;

    frame[0] = OP_FUJI;
    frame[1] = FN_ERROR;

    fn_wait();
    dwwrite(frame, sizeof(frame));
    return dwread(&e, 1) ? e : E_GENERAL;
}

/* Send a request frame and collect the verdict. */
byte fn_send(byte *frame, int len)
{
    fn_wait();
    dwwrite(frame, len);
    return fn_error();
}

/* Fetch whatever the last command left waiting. */
byte fn_response(byte *buf, int len)
{
    byte frame[2];

    frame[0] = OP_FUJI;
    frame[1] = FN_RESPONSE;

    fn_wait();
    dwwrite(frame, sizeof(frame));
    return dwread(buf, len) ? 1 : E_GENERAL;
}
