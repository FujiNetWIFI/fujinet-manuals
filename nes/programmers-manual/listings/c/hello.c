/* hello.c -- the first transaction, in C.
 *
 * Asks the FujiNet for its adapter configuration and puts the network name,
 * the IP address and the firmware version on the screen. */

#include <conio.h>
#include <fujinet-fuji.h>
#include <fujinet-nes.h>

static AdapterConfigExtended ac;

void main(void)
{
  clrscr();
  cputs("FUJINET NES\r\n\r\n");

  if (!fuji_nes_present()) {            /* 'F','N' and version 1? */
    cputs("NO FUJINET CARTRIDGE");
    for (;;) ;
  }

  if (!fuji_get_adapter_config_extended(&ac)) {
    cputs("NO ANSWER");
    for (;;) ;
  }

  cprintf("SSID %s\r\n", ac.ssid);
  cprintf("IP   %s\r\n", ac.sLocalIP);
  cprintf("FW   %.15s\r\n", ac.fn_version);
  for (;;) ;
}
