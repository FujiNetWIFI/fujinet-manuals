#import "../lib.typ": *

= First Contact <first-contact>

`fujitest` is the cartridge’s own first program, and the shortest that talks
to the FujiNet: one command, GET_ADAPTERCONFIG_EXTENDED (`$C4`), and its
answer on the screen. Burned to an ordinary 8K EPROM it is also the
cartridge’s first hardware test: there it shows NO FUJINET CART and the two
bytes it found where the magic should be.

#shot("fujitest", [fujitest, against the bench’s fujinet-pc])

== Is there a FujiNet?

#excerpt-at(auto, "listings/runtime/fujitest.asm", "        BSTA,UN FNCHECK", to: "; ---- cartridge present")

`FNCHECK` compares `$2C09` and `$2C0A` with `F` and `N`. On a FujiNet
cartridge the game chip paints them at power-on; on an EPROM they are
whatever the EPROM holds there -- zero, for an image built by `mkimage.py`.

== The question

#excerpt-at(auto, "listings/runtime/fujitest.asm", "FOUND:  BSTA,UN FNSTART", to: "HALT2:")

`FNSTART` rewinds the TX stream and sets DEVICE to `$70`; the two `FNREGWR`
calls set CMD and NPARAM. There is nothing to stream. `FNCOMMIT` launches
and waits, and R0 comes back 0. (`fujitest` checks ERR but not REPLY: this
command is never refused. The handbook’s `FNGO` checks both.)

== The answer

GET_ADAPTERCONFIG_EXTENDED answers with 240 bytes, and the program reads
three fields of it straight out of the window:

#bytefield(([ssid], 0.6in), ([hostname], 0.85in), ([ip, gw, mask, dns], 0.95in),
  ([mac, bssid], 0.65in), ([version], 0.6in), ([IP text], 0.6in),
  ([gw, mask, dns text], 0.95in), ([mac, bssid text], 0.85in))
#align(center, text(size: 8.6pt)[at 0, 33, 97, 113, 125, 140, 156 and 204; every text field ends in a NUL])

#excerpt-at(auto, "listings/runtime/fujitest.asm", "GOTCFG: LODI,R2 0", to: "TSTR:")

`FNSLICE` with R2 = 0 makes sure the window shows the first 256 bytes; all
240 are in it. `SETSTR FNRDATA+125` points `DPRINT` into the reply window,
and the firmware version goes to the screen without one byte of it passing
through the console’s RAM.

The binary fields are there too: at 97, the IP address as four bytes. The
text fields are easier to print, and every program in this book uses them.

#note[fujinet-pc is always "on WiFi", whatever the computer it runs on is
connected to, and calls the network `Dummy Cafe`. The real cartridge
reports the network it has joined.]

== Run it twice

Press the console’s RESET and `fujitest` runs again, and its transaction
gets a new sequence number: the cartridge kept the last one, and
`FNCOMMIT` reads it every time. That is the reset rule of Section 4, and the
bring-up’s test for it: a program that kept its own counter would write 1
again, the cartridge would answer nothing, and the screen would never
change.
