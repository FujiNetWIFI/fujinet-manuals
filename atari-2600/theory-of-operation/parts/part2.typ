#import "../lib.typ": *

#part("II", "Hardware: Fujiversal-Atari2600 Rev0",
  [The cartridge board as designed: the edge, the bus buffers, the RP2040
   and its timing budget, the ESP32-S3 and its peripherals, power, mechanics,
   and the exact status of a design that has been checked in CAD and never
   built.])

= The cartridge edge <ch-edge>
The board is a 2×12 gold-finger edge at 2.54 mm pitch, fingers 1.5 × 7.0 mm
starting 0.5 mm from the edge, on a 32.4 mm tab with 45° shoulders rising to
the full 54.4 mm board width 25.7 mm above the edge. The geometry and the
orientation were taken from a working prototype's gerbers; the component
face goes toward the console's rear. #v-cad #src[Fujiversal-Atari2600/README.md]

#tbl(
  tab((auto, auto, auto, auto),
    th[Pin], th[Signal], th[Pin], th[Signal],
    [1], [A7], [13], [D3],
    [2], [A6], [14], [D4],
    [3], [A5], [15], [D5],
    [4], [A4], [16], [D6],
    [5], [A3], [17], [D7],
    [6], [A2], [18], [A12],
    [7], [A1], [19], [A10],
    [8], [A0], [20], [A11],
    [9], [D0], [21], [A9],
    [10], [D1], [22], [A8],
    [11], [D2], [23], [+5 V],
    [12], [GND], [24], [GND],
  ),
  [The edge. Pins 1--12 are on the label face (B.Cu, toward the console front), 13--24 on the component face (F.Cu, toward the rear); pin 1 is behind pin 24. #src[bus-buffers.kicad\_sch J1]],
) <tbl-edge>

A12 is the only decode the console offers: it is high for every access to
`$1000`--`$1FFF` and low for everything else, and the cartridge is expected
to drive the data bus whenever it is high and the processor is reading.
Nothing tells the cartridge which of those two conditions holds. The two
schemes that switch banks from addresses *below* A12 --- UA on
`$0200`--`$027F` and FE on `$01FE` --- show that a cartridge has always
been free to watch the bus when it is not selected, and this one does the
same when those boards are emulated (#ref(<ch-mappers>)).

#fig(image("../images/sch/bus-buffers.png", width: 100%),
  [The edge and the three bus buffers, from the Rev0 schematic. U3 and U4 are fixed A→B; U5 carries the data byte and its direction is `BUF_DIR`, pulled up to 3.3 V.])

= Bus buffering <ch-buffers>
The RP2040's GPIOs are not 5 V tolerant, and the 2600's bus is an NMOS
bus at 5 V. Every one of the 21 lines therefore crosses a 74LVC245A
powered at 3.3 V: U3 carries A0--A7 and U4 A8--A12, both wired A→B
permanently, and U5 carries D0--D7 with its DIR pin on the RP2040's GP26.
#src[vcs\_pins.h:19-27; README "The RP pin map"]

Four properties of the part make the choice. Its inputs are 5 V tolerant,
so the console's highs are safe. Its 3.3 V outputs clear the NMOS bus's TTL
input threshold of 2.0 V, which is the same margin the PlusCart-Pico
already relies on. It has I#sub[off] circuitry, so an unpowered buffer
presents a high impedance to a powered console. And at 3.3 V a single
supply is enough, which the dual-supply 74LVC8T245 would not have allowed
cleanly: that part references its DIR pin to V#sub[CCA], so with the 5 V
port as A a 3.3 V GPIO could not reach V#sub[IH], and with the 3.3 V port
as A the direction sense inverts relative to the firmware's convention.
#v-design #src[README "Why 74LVC245A and not the 74LVC8T245"]

With the console on U5's A side, *DIR high is console → RP2040* and *DIR
low is RP2040 → console*. High is the boot value, and a 10 k pull-up holds
it high while the RP2040 is in reset, so a cartridge powered from its USB
port with the console switched off cannot back-drive the bus. The firmware
sets GP26 high at start-up before it enables anything else, and it drives
the data pins at the RP2040's lowest strength, 2 mA, because they only ever
face a buffer input and a gentler edge bounds any contention during a
direction flip. #v-code #src[main.c:41-51]

#finding(1)[
  The firmware never drives DIR low. `main.c` sets GP26 high at boot, and
  the `DATA_DRIVE` and `DATA_RELEASE` macros only set and clear the
  RP2040's own output enables. As written, the cartridge's data byte never
  reaches the console, and when core1 drives, its 3.3 V outputs fight U5's
  B-side outputs, which are still pointed at it. Both READMEs record the
  fix --- `DATA_DRIVE` must clear DIR as it sets the output enables, and
  `DATA_RELEASE` must release the enables first and then set DIR --- and
  both say the cartridge must not be inserted in a powered console with a
  driving firmware until it is done. The 74LVC245A needs about 5--8 ns to
  turn around. #v-none #src[vcs\_pins.h:59-60; README-fujinet.md:114-119]
]

= The RP2040 as bus server <ch-rp2040>
#fig(image("../images/sch/cart-rp2040.png", width: 100%),
  [The RP2040 sheet: the bus nets `RA0`--`RA12` and `RD0`--`RD7`, `BUF_DIR` on GPIO26, the QSPI flash, the 12 MHz crystal, and the RESET steering diode D1 that lets one button reset both chips.])

The RP2040 (U1) carries the bus on contiguous GPIO groups so that each
field is one shift of the SIO input register. @tbl-gpio is the map; it is
the one the netlist audit checks against the firmware headers. #v-cad
#src[vcs\_pins.h:36-44; tools/check\_nets.py]

#tbl(
  tab((auto, auto, 1fr),
    th[RP2040], th[Net], th[Through],
    [GP2--GP9], [A0--A7], [U3 (DIR high, A→B always) from the edge],
    [GP10--GP14], [A8--A12], [U4 (DIR high; channels 5--7 unused, inputs tied to ground)],
    [GP15--GP22], [D0--D7], [U5, bidirectional],
    [GP26], [BUF_DIR], [U5 DIR, 10 k pull-up to 3.3 V],
    [GP25], [RP_LED], [green activity LED],
    [GP0 / GP1], [RP_TX / RP_RX], [test pads TP4 / TP5 only],
    [SWCLK / SWDIO], [], [test pads TP1 / TP2, ground on TP3],
    [USB_DP / USB_DM], [], [27 Ω series to the ESP32-S3's IO20 / IO19],
    [RUN], [], [10 k pull-up; RESET button via D1; ESP32-S3 IO4 through 1 k],
    [QSPI_SS], [], [10 k pull-up; BOOTSEL button; ESP32-S3 IO5 through 1 k],
  ),
  [The RP2040 pin map. The address wiring is the PlusCart-Pico's, unchanged; the data byte moved from GP22--GP29 to GP15--GP22 so that a stock module brings every pin out and so that it could be put behind a buffer. #src[vcs\_pins.h:6-17]],
) <tbl-gpio>

The rest of the RP2040's support is Raspberry Pi's minimal reference
design: a 12 MHz ABM8 crystal with 15 pF loads and a 1 k drive limiter, a
W25Q16JV 2 MB QSPI flash, 100 nF on every supply pin, 1 µF on the
internal regulator's input and output, and 10 µF bulk on 3.3 V. The core
runs from the internal 1.1 V regulator, raised to 1.15 V by the firmware
before it sets the system clock to 250 MHz. #v-design #src[main.c:34-36; BOM]

The RP2040 has no USB connection to the outside world. Its USB pair goes
only to the ESP32-S3, so a PC cannot see it as a mass-storage device for
a first flash; that is done over the SWD pads (#ref(<ch-flash>)). The two
buttons on the RP2040 side are RESET, which resets both chips through a
BAT54C common-cathode pair, and BOOTSEL, which holds QSPI_SS low so that a
RESET lands the RP2040 in its ROM bootloader.

= The timing budget <ch-timing>
The cartridge is given no clock, so this chapter has to reason about a
cycle it cannot see. @fig-read-cycle draws one, using the MOS 6500 family's
published AC characteristics at 1 MHz as the bound; the 6507 in the 2600 is
driven at 1.193182 MHz (the 3.579545 MHz colour clock divided by three),
an 838 ns cycle. #v-design

#fig(
  timing((
    ("φ2 (not at the edge)", ((0, 419, "lo"), (419, 419, "edge"), (419, 838, "hi"), (838, 838, "edge"), (838, 1000, "lo"))),
    ("A0-A12 at the 6507", ((0, 30, "valid", "prev"), (30, 300, "x"), (300, 868, "valid", "address N"), (868, 1000, "x"))),
    ("A0-A12 at the RP2040", ((0, 40, "valid", "prev"), (40, 320, "x"), (320, 880, "valid", "after U3/U4 + sync"), (880, 1000, "x"))),
    ("D0-D7 (read)", ((0, 320, "z", "undriven"), (320, 450, "x"), (450, 870, "valid", "cart drives D"), (870, 1000, "z"))),
    ("core1", ((0, 320, "act", "settle: sample until two reads agree"), (320, 450, "act", "decode, drive"), (450, 880, "act", "spin while addr == N"), (880, 1000, "act", "release"))),
  ), 1000,
  ticks: ((0, "0"), (300, "≤300"), (419, "419"), (738, "738"), (838, "838 ns"))),
  [A read cycle as the cartridge experiences it. Time zero is the fall of φ2 that begins the cycle. The address is guaranteed stable within 300 ns of it (t#sub[ADS]) and the data must be valid 100 ns before the next fall (t#sub[DSU]), so the window is about 440 ns at the 6507's pins in the worst case; the firmware's working figure is "roughly 500 ns" once the buffers and the RP2040's two-flop input synchroniser are paid for. Neither has been measured. #v-design #src[main.c:28-33]],
) <fig-read-cycle>

Three things in the figure are the whole design of the bus loop.

/ The address does not arrive at once.: Thirteen lines through two
  buffers do not change together, and a single sample can catch a mixture
  of the old address and the new, which on this bus means serving a byte
  from somewhere else entirely. The loop therefore reads the address
  until two consecutive reads agree before it believes it.
  #src[vcs\_cart.c:50-55]

/ There is no event to wait for.: The loop detects an access by the
  address *changing* from the one it last served. It cannot know whether
  the current cycle is a fetch or a store, or whether it is early or late
  in the cycle; it can only respond to the address as fast as possible
  and keep responding until the address moves on.

/ The budget is spent in nanoseconds.: At 250 MHz a core cycle is 4 ns.
  The settle test, the page decode, the bank-pointer lookup and the drive
  are each a handful of instructions, but a single miss in the XIP flash
  cache is on the order of the whole budget, which is why core1 runs
  entirely from SRAM (#ref(<ch-cores>)) and why the served image never lives in
  flash. #src[boards/fujivcs.cmake:15-19]

A *write* cycle looks different only on the data lines, and only on the
two pages the cartridge has declared write-only. @fig-write-cycle is the
same cycle for a store to the control page.

#fig(
  timing((
    ("φ2 (not at the edge)", ((0, 419, "lo"), (419, 419, "edge"), (419, 838, "hi"), (838, 838, "edge"), (838, 1000, "lo"))),
    ("A0-A12 at the RP2040", ((0, 40, "valid", "prev"), (40, 320, "x"), (320, 880, "valid", "$1Dxx / $1Exx"), (880, 1000, "x"))),
    ("D0-D7 (write)", ((0, 619, "z", "undriven / previous"), (619, 619, "edge"), (619, 868, "valid", "6507 drives data"), (868, 1000, "z"))),
    ("core1", ((0, 320, "act", "settle"), (320, 880, "act", "sample D0-D7 until the address changes; keep sample n−1"), (880, 1000, "act", "decode"))),
  ), 1000,
  ticks: ((0, "0"), (419, "419"), (619, "≤619"), (838, "838 ns"))),
  [A store to a write-only page. The 6507 drives the data bus from no later than 200 ns after φ2 rises (t#sub[MDS]) and holds it at least 30 ns after φ2 falls (t#sub[HW]) --- the same minimum as the address hold (t#sub[HA]). The last data sample before the address changes is therefore inside the valid window, and the one before it is the one the cartridge keeps. #v-design],
) <fig-write-cycle>

The address hold and the write-data hold have the same datasheet minimum.
That equality is the margin the technique rests on: the data is still
valid when the address begins to change, so the sample taken just before
the address moved is good, and keeping the *second-to-last* sample rather
than the last one guards against the sampling loop catching the bus as it
begins to turn over. How fast the loop samples sets the granularity --- two
SIO reads and a compare per iteration, a few tens of nanoseconds --- and
that figure, like every other in this chapter, is a design value.

#note[
  The buffers add about 3 ns each way, and a direction turnaround on U5
  about 5--8 ns. These are small against the budget, but the turnaround
  happens on every transition between a cycle the cartridge drives and one
  it does not, and the firmware does not yet perform it at all (Finding 1).
  The hardware README's checklist asks for the address-to-data delay to be
  scoped at the edge against the 6507's read window before the board is
  trusted.
]

= The ESP32-S3 and its peripherals <ch-esp32>
#fig(image("../images/sch/esp32s3-sd.png", width: 100%),
  [The ESP32-S3-WROOM-1-N16R8, the push-push microSD socket on SPI, the EN and BOOT buttons, and the WS2812B status LED.])

The adapter side is an ESP32-S3-WROOM-1-N16R8 module (U6): 16 MB flash
and 8 MB octal PSRAM, which is what the FujiNet firmware's network
protocol adapters, TLS and web UI need. Its connections to the rest of
the board are few, and all of them are listed in the pin map header the
firmware is built against. #v-cad #src[include/pinmap/fujiversal-atari2600.h]

#tbl(
  tab((auto, auto, 1fr),
    th[ESP32-S3], th[Net], th[Purpose],
    [IO19 / IO20], [USB D− / D+], [Native USB, acting as *host* for the RP2040's CDC device, through 27 Ω series resistors R7 / R8. This is the cartridge link; it has no GPIO of its own in the pin map.],
    [IO38 / IO39 / IO40 / IO41], [SD MOSI / SCK / MISO / CS], [microSD in SPI mode, with a 4×10 k pull-up array.],
    [IO42], [SD card detect], [Wired to the socket's switch with a 10 k pull-up; left unused in the pin map until its polarity is confirmed on hardware.],
    [IO48], [LED_STRIP], [One WS2812B-2020-V6 through 330 Ω. A 3.3 V-rated part, so no level shifting on its data line. The firmware uses it as a combined status light: white for WiFi up, an orange flicker for bus activity.],
    [IO43 / IO44], [UART0 TX / RX], [The module's own console and flashing UART, to the CP2102N. Not the cartridge link.],
    [IO4], [RUN_CTL], [To the RP2040's RUN through 1 k: pulse low to reset it.],
    [IO5], [BOOTSEL_CTL], [To the RP2040's QSPI_SS through 1 k: hold low across a RUN pulse to force its bootloader.],
    [EN / IO0], [], [The S3 RESET and BOOT buttons; EN is also pulled low by the shared RESET button via D1.],
  ),
  [The ESP32-S3's connections. IO26--IO37 are the module's own flash and PSRAM and strapping pins 0, 3, 45 and 46 are avoided; the SD, LED and recovery pins are the same as the Intellivision board's, so one firmware image serves both. #src[fujiversal-atari2600.h:30-66]],
) <tbl-s3>

#fig(image("../images/sch/usb-uart.png", width: 100%),
  [USB-C with a CP2102N bridge and the UMH3N dual-transistor auto-program circuit, DevKitC-1 style, so that `esptool` can reset the S3 into its bootloader without a button press.])

USB-C (J3) provides power and the S3's programming port. A CP2102N (U7)
bridges it to UART0, and a UMH3N dual transistor (U8) implements the
standard DTR/RTS auto-program sequence. Three ESD5Z5.0 diodes protect the
USB lines and VBUS; 5.1 k pull-downs on CC1 and CC2 declare a UFP sink.
The CP2102N's VBUS-sense pin is fed through a 22 k / 47 k divider so that
the bridge enumerates only when a host is actually present. #v-cad #src[usb-uart.kicad\_sch; BOM]

= Power <ch-power>
#fig(image("../images/sch/power.png", width: 90%),
  [Two SS34 Schottky diodes OR the console's +5 V and USB VBUS into VIN, which feeds an AP63203 synchronous buck.])

The board accepts power from the console's +5 V (edge pin 23) and from USB
VBUS, each through an SS34 Schottky diode so that neither can feed the
other. The ORed rail feeds an AP63203WU 3.3 V, 2 A buck converter with a
6.8 µH inductor, 2×22 µF on its input and 2×22 µF on its output. Every
other supply on the board --- both microcontrollers, the buffers, the SD
card, the LED --- is on that 3.3 V rail; nothing but the OR diode is
connected to the edge's +5 V. #v-cad #src[power.kicad\_sch; README "Power"]

#tbl(
  tab((auto, auto, 1fr),
    th[Condition], th[Estimate at 3.3 V], th[Basis],
    [Idle, WiFi associated], [≈60 mA], [ESP32-S3 datasheet typicals plus the RP2040 at 250 MHz; the README's figure],
    [WiFi transmit bursts], [up to ≈350 mA], [ESP32-S3 datasheet peak],
    [Drawn from the console's +5 V], [≈250 mA peak], [The 3.3 V figures through the buck's efficiency, with margin],
  ),
  [The power budget as estimated in the hardware README. The 2600 supplies its +5 V from its own 7805 fed by a 9 V adapter. None of these numbers has been measured, and the README's checklist asks for the console's 5 V to be watched under WiFi load before a 2600 Jr is trusted with the board. #v-design],
) <tbl-power>

The decoupling follows the reference designs: 100 nF on every IOVDD,
USB_VDD, ADC_AVDD and DVDD pin of the RP2040; 1 µF on its regulator's
input and output; 10 µF bulk on 3.3 V and at the edge's +5 V; 22 µF ×5 on
the S3's supply for transmit bursts; 4.7 µF on the CP2102N. #src[BOM]

= Mechanics <ch-mech>
#fig(
  grid(columns: (1fr, 1fr), column-gutter: 10pt, align: center,
    image("../images/board-top.png", height: 2.9in),
    image("../images/board-bottom.png", height: 2.9in)),
  [Rev0, component face and label face, rendered from the KiCad project with its bundled 3D models. Every part sits on the component face above the shoulders; the label face carries only the fingers and their necks.])

The board is 54.4 × 88 mm, 1.6 mm, four layers, ENIG, with a 30° bevel on
the insertion edge. Only the tab and shoulders enter the console. The
finger strip is a rule area on both faces --- no tracks, vias or pour
between the fingers --- and each finger continues as a masked 0.5 mm neck
to 10 mm from the edge, where the routing picks it up; the inner planes
stop 9 mm from the edge, clear of the bevel. The two GND fingers are back
to back, so each is stitched to the inner ground plane by a via 1.27 mm
outboard of its neck rather than on the neck, where it would short the
finger behind it. USB-C and the microSD slot exit the top edge, and the
S3's antenna overhangs it by 6.4 mm into a pocket in the shell. Four M3
holes take a printed two-piece clamshell, 58 × 71 × 10 mm, over the
full-width part of the board. #v-cad #src[README "Mechanics", "Routing notes"; case/case-spec.md]

The RP2040 is rotated so that A0--A9 leave its south face directly above
U3, which sits directly above the A0--A7 fingers in the same order; A10--A12
and D0--D2 leave the east face toward U4; D3--D7 the north face; USB and
QSPI the west face toward the S3 and the flash. U5 sits over the data
fingers. The intent is the shortest possible bus, and it is the reason the
layout could be autorouted to completion. #src[README "How the bus is ordered"]

= Status of the hardware <ch-hwstatus>
Rev0 was generated on 2026-09-27 from `tools/design.py` and
`tools/placement.py`: schematic, four-layer layout, 100% routed, and
fabrication outputs exported for JLCPCB (gerbers, BOM and CPL; 78
assembled parts, all on the component face). *The board has not been
built or tested.* @tbl-hwstatus is the verification that has been done, all
of it in CAD. #src[README "Status"]

#tbl(
  tab((auto, 1fr),
    th[Check], th[Result],
    [ERC, `--severity-all`], [0 violations],
    [DRC, `--schematic-parity`], [0 errors, 0 unconnected, 0 parity. 81 warnings, all silkscreen cosmetics],
    [`tools/check_nets.py`], [355 of 355 checks pass. It reads `vcs_pins.h`, `fujivcs.cmake`, `fujivcs.h` and `fujiversal-atari2600.h` directly and traces every edge pin through its buffer to the right GPIO; it also checks DIR, the output enables, the unused-input ties, the QSPI flash, the USB link, RUN/BOOTSEL, SD, LED and UART. A mutation test (D0 from GP15 to GP16, SD CS from 41 to 42) fails 9 checks, as it should],
    [3D], [Every placed part has a bundled model],
    [Firmware], [`build-cart.sh` builds `fujivcs.uf2` and `checksram.py` confirms core1 is SRAM-resident; the `fujiversal-atari2600` PlatformIO environment builds with the updated pin map (with a temporary web-UI config copied from the Astrocade board, which `2600-experiment` does not yet carry)],
    [Shell], [Both halves render in OpenSCAD as 2-manifold],
    [Parts], [Every LCSC code resolves to the part named and all are in stock],
  ),
  [What has been verified on Rev0, and how. #v-cad],
) <tbl-hwstatus>

== What only hardware can answer

The README ends with a checklist of what CAD cannot verify. It is
reproduced here because it is the shortest honest statement of the
board's status, and because Part VI depends on it.

+ *DIR in firmware.* `DATA_DRIVE` must clear GP26 (Finding 1). Until then,
  never insert the cartridge in a powered console with a firmware that
  drives.
+ *Fit in a real 2600* --- heavy sixer, four-switch, Jr and 7800: the
  fingers must seat and the shell must clear the slot surround.
+ *Console 5 V under WiFi bursts* at the edge pin, especially on a Jr.
+ *Timing on a scope:* address to data at the edge against the 6507's
  read window. Budget about 500 ns; the buffers add about 3 ns each way
  plus the DIR turnaround.
+ *Back-power:* with USB-C power and the console off, the console must stay
  dead (DIR high, and the buffers' I#sub[off]).
+ *RESET* must bring up the browser; *BOOTSEL + RESET* must enumerate the
  RP2040 (VID 0x2E8A) on the S3.
+ *microSD card-detect polarity* on IO42, then set `PIN_CARD_DETECT`.
+ *JLC placement rotations:* check the preview against the pin-1 marks.
+ *WiFi RSSI* inside the shell.
