#import "../lib.typ": *

#part("I", "Overview",
  [What the cartridge is, what the console gives it to work with, and how
   the work is divided between the console, the cartridge microcontroller and
   the adapter.])

= Introduction <ch-intro>
From the console's side of the connector, the FujiNet cartridge is 4K of
ROM whose contents change. From the network's side it is a FujiNet
adapter: a WiFi device that mounts disk images from SD cards and TNFS
servers, opens TCP and HTTP connections, keeps the time, and answers the
same command set every other FujiNet answers. Between the two sits an
RP2040 that serves the 6507 bus one access at a time and an ESP32-S3 that
does everything else. This document explains the mechanism end to end:
the board, the two firmware images, and the shape of a console program
that uses them.

== What the console gives the cartridge

The Atari 2600 cartridge edge carries thirteen address lines, eight data
lines, +5 V and ground. Every other signal in the console stays inside it.
@tbl-absent lists what is missing and what each absence costs the design;
the rest of this document is largely the set of answers.

#tbl(
  tab((auto, 1fr),
    th[Absent at the edge], th[Consequence for a cartridge that wants to be more than a ROM],
    [R/W], [A store and a fetch look identical: an address appears, and that is all. The cartridge cannot be told to write, so it must infer a write from where the address points and recover the data by watching the bus (#ref(<ch-write>)).],
    [Clock (φ2)], [There is no edge to time against. An access is detected only by the address *changing*, and the cartridge must settle, decode and drive inside the cycle without knowing where in the cycle it is (#ref(<ch-timing>)).],
    [Chip select beyond A12], [The cartridge is selected for the whole of `$1000`--`$1FFF` and nothing finer. Every page it wants for itself is a page taken from the program.],
    [Reset], [The console's RESET switch is a bit in a RIOT register the cartridge never sees. A console restart begins with whatever bank was last selected still mapped, and all cartridge state intact (#ref(<ch-client>)).],
    [Interrupts], [The 6507 has no NMI, no SO and no SYNC, and nothing in the console drives IRQ. This one is a gift: every bus access comes from the program's own instruction stream, so a static scan of the program can prove things an emulator can only sample (#ref(<ch-ram>)).],
  ),
  [What the cartridge edge does not carry.],
) <tbl-absent>

Two more constraints are the console's rather than the connector's. The
6507 can address 8K and the cartridge gets the top 4K of it: sixteen
pages of 256 bytes for the program, the text it shows, the replies it
reads and the registers it writes. And the console has 128 bytes of RAM,
mirrored at `$0100` so that the stack lives in the same 128 bytes. There
is no framebuffer: the processor builds every scanline as the beam draws
it. On every other machine FujiNet runs on, "draw a string" is a memory
write. Here it would be a kernel.

== The cartridge-mailbox family

This is the sixth FujiNet cartridge built on the *mailbox* pattern, after
the Odyssey², Bally Astrocade, Arcadia 2001, ColecoVision and Channel F.
The pattern is the same on each: the console writes a request into
registers the cartridge decodes, the cartridge carries it to the adapter
over USB as a FujiBus packet, and the reply is painted into memory the
console reads back. The protocol engine, `fujimail.c`, is byte-identical
across the 2600, ColecoVision and Channel F ports; what differs per
console is how a request gets into it, and that is where the 2600 is
hardest. The Astrocade, Arcadia and ColecoVision edges carry no write
strobe either, and those ports push both directions through the read
path. The 2600 port instead takes real stores, because the 6507 drives the
data bus during one and the cartridge can see it. #src[fuji\_mailbox.h:7-25]

== How to read this document

Part II is the board: the edge, the buffers, the two microcontrollers,
power and mechanics, and the honest status of a design that exists in
CAD. Part III is the cartridge firmware on the RP2040, bottom-up from the
bus loop to the USB link. Part IV is the adapter firmware on the ESP32-S3,
which turns out to contain nothing specific to this console. Part V is
the console side: what a client program is, how it talks to the mailbox,
and how it draws. Part VI is verification: what the emulator model and
the host tests prove, and what they cannot.

Every figure and constant was transcribed from the sources listed in the
colophon, and the source is cited beside it in the form
#src[file:line]. Quantitative claims carry one of five tags:

#block(inset: (left: 1.5em), {
  set par(leading: 0.9em)
  [#v-emu --- observed in the MAME cartridge model against a live
  `fujinet-pc`.\
  #v-host --- proven by a host-side C test of the shared decode or codec.\
  #v-cad --- checked in KiCad (ERC, DRC, netlist audit).\
  #v-design --- a figure from a datasheet or a comment, not yet measured on
  this board.\
  #v-none --- described in a README as required but absent from the source.]
})

#important[
  No part of this design has run on a physical Atari 2600. The board has
  not been fabricated. Everything above the bus loop has been exercised
  against a real FujiNet adapter through an emulator model that compiles
  the cartridge's own sources; the bus loop itself has not. #ref(<ch-gaps>)
  lists what that leaves open, including five defects found in the source
  while this document was being written.
]

== One transaction, end to end

A console program wants the adapter's network configuration. It opens the
cartridge's decode gate with two stores carrying two specific values, then
sets three registers --- device `$70`, command `$C4`, parameter count 0 ---
each with a pair of stores: one to arm the register, one to commit the
value. It commits a sequence number one higher than the cartridge's
acknowledged sequence. The RP2040's bus core, which has been watching the
address lines settle and sampling the data lines on the two pages it never
drives, has by now queued six events to its other core. That core frames
a FujiBus packet, sends it over USB CDC to the ESP32-S3, and waits. The
ESP32-S3 decodes the packet, dispatches it to its FUJI device, and answers
with a 240-byte reply. The RP2040 copies the reply into the 512-byte
window at `$1B00`, writes the reply length, the error code and the link
status into the status page, and last of all writes the sequence number
into `$1F00`. The console, which has been polling `$1F00`, sees the match
and reads the SSID straight out of `$1B00` --- and, if it wants it on the
screen, streams it byte by byte into a text-row register and asks the
cartridge to render it. The program never held the reply in RAM, because
it has nowhere to put it. #v-emu #src[testrom/fujitest.asm]

= System architecture <ch-arch>
== The physical stack

#fig(
  {
    set text(size: 8pt)
    align(center, stack(dir: ltr, spacing: 0pt,
      nodebox("Atari 2600", sub: "6507 · TIA · RIOT\n1.19 MHz bus", fill: c-con, w: 72pt, h: 60pt),
      biarrow(w: 30pt, label: "A0-A12, D0-D7"),
      nodebox("3 × 74LVC245A", sub: "3.3 V, 5 V-tolerant\nDIR on GP26", fill: panel, w: 72pt, h: 60pt),
      biarrow(w: 30pt, label: "21 lines"),
      nodebox("RP2040", sub: "fujivcs\ncore1: bus · core0: USB", fill: c-rp, w: 80pt, h: 60pt),
      biarrow(w: 30pt, label: "USB CDC"),
      nodebox("ESP32-S3", sub: "fujiversal-atari2600\nWiFi · SD · FujiBus devices", fill: c-esp, w: 90pt, h: 60pt),
      biarrow(w: 30pt, label: "802.11 · SPI"),
      nodebox("Network / SD", sub: "TNFS · HTTP · TCP\nmicroSD", fill: panel, w: 66pt, h: 60pt),
    ))
  },
  [The signal path. Everything left of the buffers is the console's; everything from the RP2040 rightward is on the cartridge board. The USB link between the two microcontrollers is the only connection between them: there is no UART.],
) <fig-stack>

The design is a tandem of two microcontrollers because neither can do the
other's job. The 6507 bus gives a cartridge on the order of 500 ns from
the address settling to the data being required at the connector
(#ref(<ch-timing>)), with no wait state and no handshake; a missed cycle does not
slow the console down, it serves the wrong byte. That rules out any
processor that also runs a WiFi stack, TLS, a filesystem and a web server.
The RP2040 is given the bus and nothing else, with one of its two cores
dedicated to it, running from SRAM with interrupts disabled. The
ESP32-S3 is given everything else and never touches the bus. USB joins
them, with the ESP32-S3 as host and the RP2040 enumerating as a CDC
serial device --- the same arrangement as the Intellivision, Astrocade and
other Fujiversal boards, so the adapter firmware is shared. #src[main.c:1-12]

== Five layers

#fig(
  layers(
    ("5", "Devices", "ESP32-S3", "FUJI, clock, printer, modem, N: network units; disk images; the FujiNet command set"),
    ("4", "FujiBus", "RP2040 ⇄ ESP32-S3", "SLIP-framed packets: device, command, parameters, payload, checksum; reply is ACK or NAK plus data"),
    ("3", "Mailbox", "RP2040 ⇄ 6507 program", "Registers on page $1D, a TX stream on page $1E, a painted reply window and status page, text planes"),
    ("2", "Bus server", "RP2040 core1", "Detect an access from the address changing; drive ROM, or sample a store; bank switching; mappers for booted games"),
    ("1", "Physical bus", "Edge + buffers", "A0-A12 and D0-D7 at 5 V NMOS levels through 74LVC245A to 3.3 V GPIO; DIR turnaround"),
  ),
  [The five layers of a transaction. Part II builds layer 1, Part III layers 2--4 from the cartridge side, Part IV layers 4--5 on the adapter, Part V layer 3 from the console side.],
) <fig-layers>

== Three programs

#tbl(
  tab((auto, auto, 1fr),
    th[Program], th[Runs on], th[What it is],
    [`fujivcs`], [RP2040], [The cartridge firmware: the bus server on core1, the mailbox service and USB device on core0, the glyph compositor, the mappers, a baked-in boot client. Built by `pico/atari-2600/build-cart.sh` from `pico/atari-2600/firmware/`.],
    [`fujiversal-atari2600`], [ESP32-S3], [A build of `fujinet-firmware` with `BUILD_RS232`, the FujiBus transport over USB CDC host, and the pin map in `include/pinmap/fujiversal-atari2600.h`. Nothing in it knows the console exists.],
    [the client], [6507], [A 4K--32K image laid out as N banks of 2K plus a fixed 2K half, carrying the four-byte claim `FUJI`. The firmware ships one baked in; CONFIG and Battleship are the two real ones.],
  ),
  [The three programs. A booted game is a fourth: an ordinary cartridge image, served by whichever bank-switching scheme it shipped on.],
) <tbl-programs>

== Division of labour

The guiding rule is that work goes to whichever side has the resources
for it, and the console has almost none. @tbl-division is the result.

#tbl(
  tab((auto, 1fr),
    th[Who], th[Holds or does],
    [Console (6507, 128 bytes)], [A cursor, a few flags, the sequence number it last committed, and the display kernel's scanline counter. It streams bytes between cartridge pages and never buffers them.],
    [Cartridge (RP2040)], [The served window and its decode; four 256-byte path buffers (the working directory, a filter, a copy source, an edit scratch); the reply (up to 1024 bytes); the font and the composed text planes; the Battleship board tables; two 32K image buffers; the mappers; the FujiBus codec and USB device.],
    [Adapter (ESP32-S3)], [WiFi, TCP/TLS, HTTP, TNFS, the SD card, disk-image handling, the host and device slot model, configuration, the web UI, and the RP2040's firmware image for field updates.],
  ),
  [Who holds what.],
) <tbl-division>
