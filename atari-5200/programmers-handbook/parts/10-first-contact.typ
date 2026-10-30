#import "../lib.typ": *
= First Contact <ch-first>

The first program that talks to the FujiNet asks it one question, GET_ADAPTERCONFIG_EXTENDED, and shows three parts of the answer: the WiFi network it is on, its IP address, and its firmware version. It is the smallest complete transaction there is: no parameters, no payload, a 240-byte reply.

#sect[Build and run]

#nsteps(
  [Start the FujiNet adapter (`fujinet-pc`), listening on bus-over-IP.],
  [Build the program: `listings/asm/build.sh fujitest` or `listings/c/build.sh acfg`.],
  [Run it: `emu/run.sh listings/c/build/acfg.bin`. The cartridge sees the claim, serves the program as an APP, and its first transaction comes back in well under a second.],
  [The SSID, IP address and firmware version appear. On the bench in this handbook the SSID is `Dummy Cafe`, fujinet-pc’s stand-in for a real network, and the address is `127.0.0.1`.],
)

#shots("asm-acfg", "c-acfg", caption: [First Contact in assembly and in C. The assembly one also shows `ACKSEQ` and `ERR`.])

#sect[The reply]

The reply is the adapter’s configuration, both as raw bytes and as text ready to print. Everything is at an offset under 256, so one index register reaches all of it.

#tbl((auto, auto, 1fr),
  th[Offset], th[Size], th[Field],
  [0], [33], [SSID, NUL-terminated],
  [33], [64], [hostname],
  [97, 101, 105, 109], [4 each], [IP address, gateway, netmask, DNS server: raw bytes],
  [113, 119], [6 each], [MAC address, BSSID: raw bytes],
  [125], [15], [firmware version],
  [140, 156, 172, 188], [16 each], [IP address, gateway, netmask, DNS server: as text],
  [204, 222], [18 each], [MAC address, BSSID: as text],
)

#sect[In assembly]

`fujitest.s` is the bring-up’s own first contact, unchanged. It checks for the cartridge, makes the one transaction through the library, and puts the three fields on the screen straight from the reply window with `disp_rpl`, which copies as it draws.

#ex((path: "listings/common/fujitest.s", from: "have:   lda     #FNDEVF", to: "show:   PUTS"), t-asm)
#ex((path: "listings/common/fujitest.s", from: "ok:     PUTS    5, 2, tssid", to: "        PUTS    9, 2, tver"), t-asm)

It also shows `ACKSEQ` and `ERR` from the status page. Power the console off and on and run it again: `ACKSEQ` reads 01 again, because the cartridge saw the power go and started its count over with the console (@ch-mailbox).

#sect[In C]

fujinet-lib fills a struct with the reply, so the C version reads like any FujiNet C program on any computer. Only the screen is the 5200’s.

#ex((path: "listings/c/acfg.c", from: "    if (!fuji_a5200_present())", to: "    for (;;)"), t-c)

`fuji_get_adapter_config_extended()` is a macro over `fuji_bus_call()`: no parameters, a reply the size of `AdapterConfigExtended`. `mt_text` copies each field onto the screen and stops at its NUL.
