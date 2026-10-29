#import "../lib.typ": *

#opener-art.update((sub: [one transaction · SSID · address · version],
  art: tvrow("fujitest", w: 1.6in)))
= First Contact <first>

The first program to talk to the FujiNet asks it the simplest question it answers: who are you, and where? GET_ADAPTERCONFIG_EXTENDED, command `$C4` of the FUJI device, `$70`, takes no parameters and answers with 240 bytes: the network’s name, the adapter’s addresses as numbers and as text, and its firmware version.

`fujitest.asm` is the cartridge bring-up’s own first contact, unchanged. It is in `listings/runtime/`.

== Build it and run it

```
cd listings/asm && ./build.sh fujitest
emu/run.sh listings/asm/build/fujitest.st2
```

On the bench the screen shows the network as `Dummy Cafe`, which is what `fujinet-pc` calls the computer’s own network, the address as `127.0.0.1`, and the firmware the adapter was built from.

== Is anyone there?

Before anything else the program asks whether a FujiNet cartridge is plugged in at all. `fn_chk` reads two bytes of the status page, which a cartridge paints with `'F'` and `'N'`; with no cartridge, the console reads whatever the bus floats to.

#excerpt-at(auto, "listings/runtime/fujitest.asm", "main:   FCALL   d_cls", n: 12)

== The transaction

Three registers, no parameters, and the launch:

#excerpt-at(auto, "listings/runtime/fujitest.asm", "have:   LDI     FNDEVF", to: "show:")

`fn_beg` takes the device in R9.1 and the command in R9.0: the handbook’s own programs say the same with `FNBEGIN FNDEVF, FNCADPX, 0`.

== The reply

#wide(at: bottom, {
  align(center, bytefield(
    ([ssid], 0.75in), ([hostname], 1.05in), ([4 × 4 numbers], 0.8in), ([mac, bssid], 0.65in),
    ([fn\_version], 0.8in), ([sLocalIP], 0.65in), ([gateway, netmask, dns], 1.15in), ([mac, bssid as text], 0.95in)))
  align(center, grid(columns: 8, column-gutter: 0pt,
    ..((0.75in, "0"), (1.05in, "33"), (0.8in, "97"), (0.65in, "113"), (0.8in, "125"),
       (0.65in, "140"), (1.15in, "156"), (0.95in, "204")).map(c => box(width: c.at(0),
       align(left, text(size: 6.4pt, fill: gray, c.at(1)))))))
  align(center, text(size: 7.6pt, style: "italic")[GET_ADAPTERCONFIG_EXTENDED’s 240 bytes, at their offsets. Text fields end in a NUL.])
})

Nothing of it needs to cross into the console. The program prints each field where it lies in the reply window, with PRINT:

#excerpt-at(auto, "listings/runtime/fujitest.asm", "show1:  PUTS    10H, t_ssid", n: 9)

The SSID can be 32 characters long and the screen is 16 wide, so its row is armed with MARQUEE first: a PRINT that does not fit scrolls along the row instead of wrapping.

== SEQ and ERR

The last row shows the sequence number the cartridge answered and its ERR byte: `SEQ 01  ERR 00`, the first transaction since the console was turned on, without error. Press CLEAR and the program runs again, but the cartridge was not reset: the next transaction is number 2. Turn the console off and on, and it is number 1.
