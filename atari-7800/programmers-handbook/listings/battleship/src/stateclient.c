/*******************************************************************
 * 
 * Do NOT include standard library headers (e.g. conio, std*). 
 * Instead, add to standard_lib.h, which gets included in misc.h
 * 
 ******************************************************************/

#include "misc.h"
#include "stateclient.h"
#include "fujinet-network.h"

// Internal to this file
#ifdef BUILD_COLECO
// 1K machine: the URL is staged in tempBuffer instead of its own buffer. Safe
// because no apiCall() path is ever tempBuffer itself (getStateFromServer()
// passes the move buffer or a literal), and nothing that lives in tempBuffer
// is needed across an API call.
#define url tempBuffer
#else
static char url[URL_BUFFER_LEN];
#endif
char *requestedMove;

#ifdef CUSTOM_FUJINET_CALLS
// Optional: This would be implemented in platform-specific code for emulators, etc
int16_t custom_network_call(char *url, uint8_t *buffer, uint16_t max_len);
#endif

/*
 * @brief Makes an Api call, returning true if valid payload received
 * Returns API_CALL_*:
 *  1 - successfully received a payload
 *  2 - async - received payload, still in process, call for more data
 *  0 - error - aborted
 */
uint8_t apiCall(const char *path)
{
    static int16_t read;

    strcpy(url, "n:");
    strcat(url, serverEndpoint);
    strcat(url, path);
    strcat(url, query);
    strcat(url, query[0] ? "&bin=1&v=" API_CLIENT_VERSION : "?bin=1&v=" API_CLIENT_VERSION);

    // Allow platform-specific override (e.g. for mocking network calls in
    // emulator, or the ColecoVision's read-into-cartridge-window transport).
    // sizeof(Game), not sizeof(clientState.game): on the ColecoVision
    // clientState is a macro for a cast-and-dereference of the reply window,
    // and sccz80 will not take sizeof() of that expression.
#ifdef CUSTOM_FUJINET_CALLS
    read = custom_network_call(url, &clientState.firstByte, sizeof(Game));
#else
    if (network_open(url, OPEN_MODE_HTTP_GET, OPEN_TRANS_NONE))
    {
        return API_CALL_ERROR;
    }

    read = network_read(url, &clientState.firstByte, sizeof(Game));
    network_close(url);
#endif

    // On error clientState is unspecified (and on the ColecoVision it is not
    // writable at all) - callers must trust the return code, not the state.
    if (read <= 0)
    {
        return API_CALL_ERROR;
    }

    return API_CALL_SUCCESS;
}

void sendMove(char *move)
{
    if (move != NULL)
        state.apiCallWait = 0;

    requestedMove = move;
}

uint8_t getStateFromServer()
{
    // The path is handed to apiCall() as-is - never staged in tempBuffer,
    // which doubles as the url build buffer on the ColecoVision
    const char *path = "state";

    if (requestedMove)
    {
        path = requestedMove;
        requestedMove = NULL;
    }

    return apiCall(path);
}
