/*
 * WEATHER.C --- a JSON channel, end to end
 *
 * Opens an HTTPS channel, puts the JSON parser on it, and asks
 * three questions of the document without ever holding the
 * whole thing in the CoCo's memory.  That is the point of the
 * parser: the adapter keeps the document, you keep the answer.
 *
 *   cmoc -I$(FNDIR) -o WEATHER.BIN weather.c -lfujinet
 *   LOADM"WEATHER":EXEC
 */

#include <cmoc.h>
#include <coco.h>
#include <fujinet-fuji.h>
#include <fujinet-network.h>

/*
 * fujinet-lib keeps the bus primitives to itself, but they are
 * in the library all the same.  We need them for exactly one
 * frame; see json_mode() below.
 */
extern void    bus_ready(void);
extern byte    dwwrite(byte *s, int l);
extern uint8_t network_get_error(uint8_t unit);

#define OP_NET        0xE3
#define NC_SET_PARSER 0xFC
#define NC_PARSE      'P'
#define PARSER_JSON   1

static char spec[] =
    "N:HTTPS://api.open-meteo.com/v1/forecast"
    "?latitude=39.10&longitude=-94.58"
    "&current=temperature_2m,wind_speed_10m";

static char q_time[] = "/current/time";
static char q_temp[] = "/current/temperature_2m";
static char q_wind[] = "/current/wind_speed_10m";

static char ans[64];

/*
 * Put the JSON parser on the channel and parse what is there.
 *
 * network_json_parse() would do this, but it puts the parser
 * mode in aux1 and the firmware reads it out of aux2, so on a
 * current adapter it quietly selects no parser at all.  Two
 * frames by hand cost less than the afternoon that discovery
 * costs.
 */
static uint8_t json_mode(uint8_t unit)
{
    struct _f
    {
        uint8_t op, unit, cmd, aux1, aux2;
    } f;
    uint8_t e;

    f.op   = OP_NET;
    f.unit = unit;
    f.cmd  = NC_SET_PARSER;
    f.aux1 = 0;
    f.aux2 = PARSER_JSON;       /* aux2, not aux1 */

    bus_ready();
    dwwrite((byte *) &f, sizeof(f));
    e = network_get_error(unit);
    if (e != FN_ERR_OK)
        return e;

    f.cmd  = NC_PARSE;
    f.aux1 = 0;
    f.aux2 = 0;

    bus_ready();
    dwwrite((byte *) &f, sizeof(f));
    return network_get_error(unit);
}

static void show(const char *label, char *query)
{
    printf("%s", label);
    if (network_json_query(spec, query, ans) > 0)
        printf("%s\n", ans);
    else
        printf("?\n");
}

int main(void)
{
    uint8_t unit;

    cls(1);
    printf("FUJINET WEATHER\n\n");

    if (network_open(spec, OPEN_MODE_HTTP_GET, OPEN_TRANS_NONE) != FN_ERR_OK)
    {
        printf("CANNOT OPEN, ERROR %u\n", fn_device_error);
        return 1;
    }

    unit = network_unit(spec);

    if (json_mode(unit) != FN_ERR_OK)
    {
        printf("CANNOT PARSE, ERROR %u\n", fn_device_error);
        network_close(spec);
        return 1;
    }

    show("TIME.. ", q_time);
    show("TEMP.. ", q_temp);
    show("WIND.. ", q_wind);

    network_close(spec);
    return 0;
}
