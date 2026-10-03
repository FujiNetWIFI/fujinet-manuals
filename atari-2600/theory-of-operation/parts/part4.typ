#import "../lib.typ": *

#part("IV", "Software: the adapter firmware",
  [`fujiversal-atari2600`, the ESP32-S3 build of `fujinet-firmware`: the
   transport that selects USB, the devices the bus assembles, how a disk
   image becomes a pushed cartridge, and how one flash image carries both
   chips' firmware.])

= Nothing here knows the console <ch-transport>
The adapter firmware's build for this board is `fujiversal-atari2600`. Its
platform definition is three lines: the bus is RS232, the platform macro is
`BUILD_RS232`, and the pin map is `PINMAP_FUJIVERSAL_ATARI2600`, with USB
host and CDC-ACM host support enabled. There is no `BUILD_ATARI2600`. The
console's identity --- the 4K window, the mailbox, the text planes, the
mappers --- lives entirely on the RP2040, and the ESP32-S3 sees only
FujiBus packets arriving over a serial channel, exactly as it does for the
Odyssey², Astrocade, Arcadia, ColecoVision and Channel F boards.
#src[build-platforms/platformio-fujiversal-atari2600.ini; include/pinmap/fujiversal-atari2600.h:3-9]

== Selecting USB

The RS232 bus has three transports: a wired UART, a USB CDC-ACM host, and
bus-over-IP for the PC build. Which one a board gets is decided by the
*absence* of UART pins in its pin map: if neither `PIN_UART1_RX` nor
`PIN_UART2_RX` is defined, `rs232.h` defines `FUJINET_OVER_USB` and the
bus's serial member becomes an `ACMChannel` instead of a `UARTChannel`.
The 2600 pin map deliberately defines neither. #src[lib/bus/rs232/rs232.h:22-28, 127-133; fujiversal-atari2600.h:11-12]

The pin map supplies one more thing the bus needs: which USB device to
accept. `FN_USB_EXPECTED_VID` is `0xCafe`, TinyUSB's default and what the
cartridge enumerates as; the product id is left unchecked because it varies
with the cartridge's compiled interface set. The VID alone also rejects an
RP2040 sitting in its ROM bootloader, which enumerates as `0x2E8A`, so the
bus never tries to talk FujiBus to a cartridge waiting to be flashed.
#src[fujiversal-atari2600.h:61-65; rs232.cpp:243-258]

`ACMChannel` owns the ESP-IDF USB host stack. At set-up the bus boosts the
USB service tasks to priority 24 --- just above the WiFi task --- so that
enumeration wins the CPU during the boot race, and drops them to 20 once
WiFi has associated. A reconnect task runs for the life of the program,
reopening the device whenever it reappears, so that an RP2040 reset or
replug --- which a cartridge swap or a bootloader round-trip causes --- is
noticed without an adapter reboot. #src[rs232.cpp:27-30, 148-154; lib/hardware/ACMChannel.h:65-72]

= The device set <ch-devices>
`src/main.cpp` assembles the same devices on the bus for every RS232
board. #src[src/main.cpp:346-366]

#tbl(
  tab((auto, auto, 1fr),
    th[Device id], th[Class], th[What it answers],
    [`$70`], [FUJI (`rs232Fuji`)], [the adapter itself: WiFi scan and connect, host slots, directories, device slots, MOUNT_IMAGE, app keys, adapter configuration, the clock-free status calls. `GET_ADAPTERCONFIG_EXTENDED` (`$C4`) is the first command every bring-up client sends],
    [`$45`], [CLOCK (`rs232Clock`)], [APETime-compatible time and date, extended with additional return formats],
    [`$40`], [PRINTER (`rs232Printer`)], [a file-backed printer on the SD card or flash],
    [`$50`], [SERIAL (`rs232Modem`)], [the R: modem emulation],
    [`$71`--`$78`], [NETWORK (`rs232Network`, an `NDevice`)], [N1:--N8:, the network units: OPEN a URL on a protocol adapter (HTTP, HTTPS, TCP, TLS, TNFS, and the rest), READ, WRITE, STATUS, CLOSE, and the parser and JSON helpers],
  ),
  [The devices on the bus. Commands are dispatched through the device classes' tables and the `fujiDevice` mixins; nothing is per-console. #src[lib/device/rs232/]],
) <tbl-devices>

From the console program's point of view a FujiNet command is three
register values --- device, command, parameter count --- and a stream. The
FUJI device's command set is the same one every FujiNet platform exposes;
the _Programmer's Handbook_ carries the full card for each. Two that
matter for the mechanism are OPEN_DIRECTORY and SET_DEVICE_FULLPATH, which
both read *exactly* 256 bytes of payload. A short payload fails the
adapter's read, which is why the cartridge's path-buffer emit pads to 256
and why the client has to know the buffer's length to pad the rest
itself. #src[vcs\_cart.h:239-248; fuji\_mailbox.h:175-182]

= Media: the image as a stream <ch-media>
`MediaTypeROM`, the RS232 build's media class for a `.bin` cartridge
image, is what makes MOUNT_IMAGE push. It does not serve sectors; its
read and write entry points simply refuse. Instead, on mount it resolves
a memory-map sibling --- the image's name with `.cfg` (or `.CFG`, for a
case-sensitive host) in place of its extension --- and exposes two
streams: the map, if it exists, and the image. The bus pushes those to
device `$FF` as the DBC frames of #ref(<ch-boot>), the map first, so that the
cartridge has the scheme's name in hand before the image's last chunk
closes and `vcs_set_image` chooses the mapper. A missing map is not an
error; the cartridge falls back to size detection, and the log says so
because a wrong map boots to garbage with no other clue.
#v-emu #src[lib/media/rs232/diskTypeROM.cpp:31-130]

= One image, two chips <ch-flash>
A Fujiversal board is flashed as one image. The RP2040's firmware is built
alongside the ESP32's and embedded in `firmware.bin` as read-only data; the
FujiNet flasher writes the ESP32 over the CP2102N exactly as it does for
every other board, and the ESP32 then flashes the cartridge itself through
the USB link using the RP2040's PICOBOOT protocol. After a successful flash
the ESP32 records the image's SHA-256 in NVS and on every later boot
compares it with what the cartridge reports: a running cartridge with a
matching hash is left alone, one in BOOTSEL is always flashed, and one
running a different image is asked to reboot into BOOTSEL and reflashed.
#src[docs/fujiversal-flashing.md]

Getting the RP2040 into BOOTSEL has four paths, in order of preference,
and this board wires three of them:

#tbl(
  tab((auto, 1fr, auto),
    th[Path], th[Mechanism], th[On Rev0],
    [1200-baud request], [Setting the CDC line to 1200 baud is the convention every Pico tool uses for "reboot into the bootloader". The cartridge firmware must link `pico_usb_reset` *and* define `PICO_ENABLE_USB_RESET_VIA_BAUD_RATE`], [cartridge-side; not in the current `fujivcs` link set #v-none],
    [RUN and BOOTSEL lines], [The ESP32 holds `PIN_RP2040_BOOTSEL` low across a pulse on `PIN_RP2040_RUN`. Works with a bricked or hung cartridge firmware], [IO5 → QSPI_SS, IO4 → RUN, through 1 k #v-cad],
    [The BOOTSEL button], [Hold while pressing RESET; the next ESP32 boot finds it in BOOTSEL], [SW2 + SW1 #v-cad],
    [The mailbox doorbell], [The console writes `$B5`, `$4A` to registers `$12`, `$13` (#ref(<ch-link>))], [needs a working firmware and a console #v-emu],
  ),
  [Ways into the RP2040's bootloader.],
) <tbl-bootsel>

#note[
  The hardware README records that the PICOBOOT client is not yet on the
  `2600-experiment` branch, and the flashing guide's board table lists
  only the Intellivision, CoCo and MSX boards. On this branch the first
  flash of a Rev0 board is therefore over the SWD pads with a debug probe,
  and the embedded-image path is the design intent rather than the
  current state. #v-none #src[Fujiversal-Atari2600/README.md "Flashing"; docs/fujiversal-flashing.md:8-14]
]
