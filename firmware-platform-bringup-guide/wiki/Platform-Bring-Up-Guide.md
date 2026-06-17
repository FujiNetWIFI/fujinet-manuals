# FujiNet Platform Bring-Up Guide

*A developer's manual for adding new platform support to FujiNet, using the 8-bit PC ISA bus as the worked example.*

This is the GitHub-wiki edition of the **FujiNet Platform Bring-Up Guide**. A typeset PDF with the same content lives next to it (`fujinet-platform-bringup-guide.pdf`).

Every register value, pin assignment, packet field, and source excerpt here was transcribed from the live project sources, not from secondary documentation:

| Source | Contents |
| --- | --- |
| **`fujinet-bringup`** | **START HERE** — minimal byte relay + `iotest` host test; the bring-up MVP |
| `fujiversal` | RP2350 bus-interface firmware — PIO, USB-CDC bridge, ROM emulation |
| `fujiversal-pcb-prototype` | Universal proto board, ISA / CoCo / MSX adapters, footprints |
| `fujinet-lib-experimental` | Host client — FujiBus framing over the I/O byte pipe |
| `fujinet-firmware` | ESP32 device firmware — `lib/bus`, `lib/device`, `lib/media` |
| `fujinet-config` | Host-side ROM / CONFIG image served by the RP2350 |
| [FEP-004](https://github.com/FujiNetWIFI/fujinet-firmware/wiki/FEP-004) | FujiNet serial-encapsulation protocol proposal |

## Contents

- [Part I — Orientation](#part-i--orientation)
  - [1. Introduction](#1-introduction)
  - [2. System architecture](#2-system-architecture)
  - [3. The FujiBus protocol (FEP-004)](#3-the-fujibus-protocol-fep-004)
- [Part II — Hardware bring-up](#part-ii--hardware-bring-up)
  - [4. The ISA bus in one sitting](#4-the-isa-bus-in-one-sitting)
  - [5. Anatomy of the universal prototype board](#5-anatomy-of-the-universal-prototype-board)
  - [6. Building the ISA adapter](#6-building-the-isa-adapter)
  - [7. Hardware configuration and first power-on](#7-hardware-configuration-and-first-power-on)
- [Part III — The RP2350 bus interface](#part-iii--the-rp2350-bus-interface)
  - [8. Inside the fujiversal firmware](#8-inside-the-fujiversal-firmware)
  - [9. Writing the ISA PIO program](#9-writing-the-isa-pio-program)
  - [10. Bringing the RP2350 up](#10-bringing-the-rp2350-up)
- [Part IV — The ESP32 device firmware](#part-iv--the-esp32-device-firmware)
  - [11. Where ISA fits in fujinet-firmware](#11-where-isa-fits-in-fujinet-firmware)
  - [12. Adding the platform to the build system](#12-adding-the-platform-to-the-build-system)
  - [13. Device classes](#13-device-classes)
  - [14. Media classes](#14-media-classes)
  - [15. The host ROM and CONFIG](#15-the-host-rom-and-config)
  - [16. The client library](#16-the-client-library)
- [Part V — Integration & validation](#part-v--integration--validation)
  - [17. The bring-up milestone ladder](#17-the-bring-up-milestone-ladder)
  - [18. Troubleshooting](#18-troubleshooting)
  - [19. Porting to a bus that is not ISA](#19-porting-to-a-bus-that-is-not-isa)
- [Appendices](#appendices)

---

# Part I — Orientation

## 1. Introduction

FujiNet is a network and storage peripheral for retro computers. To a 1980s machine it looks like a fast disk drive, a printer, an RS-232 modem, a real-time clock, and a handful of other devices; behind that façade it is an ESP32 microcontroller with WiFi, an SD card, and a small army of internet protocol adapters. **Bringing up a platform** means making FujiNet appear as those familiar peripherals on a machine it has never run on before.

### Start at fujinet-bringup

> **Important** — Before anything in this guide, clone and read the **`fujinet-bringup`** repository. It is the project's canonical, deliberately-minimal first step, and it exists so you can prove two-way communication with your machine *before* committing to PCBs, PIO programs, or ROM emulation. This guide is what comes after — the production tandem design — but `fujinet-bringup` is where the work actually begins.

`fujinet-bringup` contains three small pieces and one method:

- **`iotest`** — a tiny host-side program (it runs on your retro machine) that echoes bytes between the keyboard/screen and the bus. You port it by writing a `portio` for your platform.
- **`esp32` / `rp2350`** — minimal *byte-relay* firmware for the microcontroller; it does nothing but shuttle bytes between the host bus (on GPIO) and a USB serial port. No FujiNet logic at all.
- **The method** — get those two talking, then point the relay's USB port at the FujiNet firmware running as a *PC build* and run a "Hello World" that asks FujiNet for its version. Only once that works do you graduate to the on-board, ROM-emulating design this guide details.

This inverts the risk. The hard, scary part of a bring-up is the electrical and timing layer; `fujinet-bringup` lets you nail that with a breadboard, a relay, and a terminal loop before a single custom board is fabricated.

#### The host-side contract: `portio`

Whichever path you take, the host always talks to FujiNet through five routines — the same contract `iotest`, this guide's client library ([Chapter 16](#16-the-client-library)), and the production firmware all share:

```c
// the portio contract (fujinet-bringup iotest/src/<platform>/portio.*)
void     port_init(void);
bool     port_available(void);                 // is a byte waiting?
int      port_getc(void);                      // read one byte, or -1
int      port_getc_timeout(uint16_t ticks);
uint16_t port_getbuf(void *buf, uint16_t len, uint16_t timeout);
void     port_putc(uint8_t c);                 // write one byte
uint16_t port_putbuf(void *buf, uint16_t len);
```

`iotest` already ships working `portio` examples and build makefiles for roughly a dozen platforms — `adam`, `apple2`, `atari`, `c64`, `coco`, `dragon`, `h89-cpm`, `msdos`, `msx`, `vic20`, and more — so for many machines you are adapting an example, not starting blank. The host loop itself is just:

```c
// iotest/src/main.c  (the entire two-way test)
port_init();
while (1) {
    if (kbhit())          port_putc(cgetc());   // key  -> bus -> relay -> USB
    if (port_available()) putchar(port_getc()); // USB -> relay -> bus -> screen
}
```

### Choosing the interface: ESP32 or RP2350

The first design decision `fujinet-bringup` asks you to make is *which microcontroller sits on the bus*, and it turns on one number: how many bus signal lines you must manage.

| Bus width | Interface | Why |
| --- | --- | --- |
| **≤ 8 signal lines** | ESP32 can do it | Few enough lines to bit-bang from the ESP32's GPIO. The ESP32 is **not** 5 V tolerant, so it needs a level translator (the `fujinet-bringup` H89 example drives a `74LVC245` via `OE`/`DIR`). The H89 reaches FujiNet through an i8255 PPI this way. |
| **> 8 signal lines** | use an RP2350 | Enough GPIO for a wide address/data/control bus, *and* — per `fujinet-bringup` — the RP2350 can interface to 5 V signal lines **directly, without a level shifter**. That capability is the main reason to reach for it. |

ISA, with 20 address + 8 data + several control lines, is firmly in RP2350 territory — which is why this guide's worked example uses one.

> **Important** — Note the 5 V point, because it corrects a natural assumption (and an error in this guide's first edition): the RP2350's direct connection to a 5 V bus is *intentional and supported*, not a hazard to be buffered away. Level shifting in this design is an **ESP32** concern, not an RP2350 one. See [Chapter 6](#6-building-the-isa-adapter).

### Three ways to bring up a platform

| Strategy | How it works | Examples |
| --- | --- | --- |
| **Adapt an existing serial bus** | The machine already has a multi-drop serial peripheral bus with a documented protocol. FujiNet becomes another device on that bus, speaking the native protocol directly on the ESP32. | Atari SIO, CoCo DriveWire |
| **FEP-004 serial encapsulation** | The machine has a UART or a simple serial link but no peripheral protocol. FujiNet defines its own framing — FEP-004 — over that link, and a small host-side driver speaks it. | RS-232, MSX (serial) |
| **Bus-interface tandem** | The machine has no serial bus, only a parallel CPU expansion bus (cartridge slot, ISA, S-100, Apple slot…). A second microcontroller, an RP2350, sits directly on that parallel bus and bridges it to the ESP32. **This guide.** | ISA, MSX (cartridge), CoCo (cartridge) |

The tandem design exists because parallel CPU buses are **fast and unforgiving**. A Z80 or an 8088 expects valid data on the bus within tens of nanoseconds of asserting a read strobe. An ESP32 running FreeRTOS and a WiFi stack cannot meet that deadline. The RP2350 can: its Programmable I/O (PIO) blocks are deterministic state machines that react to bus signals in single clock cycles, and its second core can be dedicated to the bus.

### The division of labour

This is the single most important idea in the guide.

```
   Host computer           RP2350 (fujiversal)         ESP32-S3 (firmware)
  CPU + parallel   <--->   PIO bus interface    <--->   devices, media,
  expansion bus    bus     ROM + I/O window      USB    N: protocols
  (ISA, slot)              USB-CDC device       CDC     WiFi + SD
  -------------            -----------------            ---------------
  nanoseconds              milliseconds                 internet time
  hard real time           soft real time
```

- **The host** runs unmodified software. To it, FujiNet is a ROM in its address space plus a few I/O registers.
- **The RP2350** (`fujiversal`) emulates a ROM chip and a small bank of I/O registers on the host's bus. The ROM holds the host-side loader and CONFIG program. The I/O registers are a **byte pipe**: the host pushes and pulls bytes through them, and the RP2350 shuttles those bytes over USB to the ESP32.
- **The ESP32** (`fujinet-firmware`) runs the entire FujiNet device stack and receives FujiBus packets over USB exactly as if they had arrived on any other FujiNet transport.

> **Important** — Because the ESP32 sees a *serial stream of FujiBus packets*, a bus-based platform reuses the firmware's existing serial transport — the `rs232` bus class — almost unchanged. The genuinely platform-specific engineering concentrates in two places: the **RP2350 PIO program** (Part III) and the **host ROM + client library** (Part IV). The ESP32 side is mostly a build-system and pin-map exercise. This is the payoff of the tandem design.

### Conventions

Active-low signals are written `/IOR`. Hexadecimal is `0x1234`; an I/O *port* is also `0x300`. GPIO numbers are `GP17`. Callouts use four levels: **Note** (background), **Tip** (shortcut), **Important** (must get right), **⚠️ Magic Smoke** (can destroy hardware).

## 2. System architecture

### The physical stack

A bring-up rig is three boards plus an adapter:

| Board | Role | Repo reference |
| --- | --- | --- |
| **Waveshare Core2350B** | RP2350B (component `U1`); ~48 GPIO, enough for a 20-bit address bus + data + control | `FujiNet:WaveShare-Core-RP2350B` |
| **Freenove ESP32-S3-CAM** | ESP32 + WiFi + microSD (component `U2`) | `FujiNet:ESP32-S3-CAM` |
| **Universal prototype board** | Seats both dev boards; routes every GPIO to a generic bus header through solder jumpers | `fujiversal-pcb-prototype/Bus-proto` |
| **Bus adapter** | Converts the universal bus header into the machine's physical connector | `CoCo-adapter`, `MSX-adapter`, (new) ISA adapter |

> **Note** — The Freenove board may need a hardware tweak before its microSD works: one SD pin must be grounded by a solder bridge. The prototype README flags this; confirm against your board revision before assembly.

### Why the inter-board bus is shaped like ISA

When the prototype board was designed, its generic bus header was given the footprint of an 8-bit ISA edge connector (`Connector:Bus_ISA_8bit`, footprint `parts:ISA_8bit`). Both the CoCo and MSX adapters carry a matching `Bus_ISA_8bit` connector on the universal-board side, and the machine's real connector on the other.

For an ISA bring-up the adapter is therefore **nearly a pass-through**: the universal board's GPIO map was drawn directly from the ISA signal list (`GP0`=`A0`, `GP20`=`D0`, `GP28`=`/MEMR`…). The ISA adapter's job is not signal translation but **electrical conditioning** — getting the 5 V ISA bus safely in and out of a 3.3 V RP2350.

### The two firmware images and one ROM image

| Image | Runs on | Built from |
| --- | --- | --- |
| `fujiversal` UF2 | RP2350 | `fujiversal/` — `make ROM_FILE=… BOARD=…` |
| FujiNet firmware | ESP32-S3 | `fujinet-firmware/` — PlatformIO env |
| Host ROM | host CPU (served by RP2350) | `fujinet-config/` — per-platform loader + CONFIG |

The host ROM is *data* compiled into the RP2350 image (`build/<board>/rom.h`). Build it **first**, then build `fujiversal` with `ROM_FILE` pointing at it.

### The five communication layers

| Layer | Owner | Responsibility |
| --- | --- | --- |
| 5 — Device / media | ESP32 | Fuji, disk, `N:`, printer, clock; image formats; `N:` protocol adapters |
| 4 — FujiBus (FEP-004) | ESP32 ⇄ host lib | device + command + AUX fields + payload, SLIP-framed, checksummed |
| 3 — Byte pipe | RP2350 ⇄ host | the 4 I/O registers: `GETC` / `STATUS` / `PUTC` / `CONTROL` |
| 2 — Bus interface (PIO) | RP2350 | ROM emulation, address decode, drive/sample the data bus |
| 1 — Physical bus | adapter + board | voltage levels, connector, timing, AEN / strobes |

This guide is organised bottom-up: Part II builds layer 1, Part III builds layers 2–3, Part IV builds layers 4–5.

## 3. The FujiBus protocol (FEP-004)

FujiBus is the packet protocol the ESP32 and the host exchange. It is the working implementation of the FEP-004 proposal and is identical whether the bytes travel over RS-232, an MSX serial port, or the USB-CDC link between the RP2350 and the ESP32. The authoritative implementations are `FujiBusPacket.cpp` (in both `fujiversal/` and `fujinet-firmware/lib/bus/rs232/`) and the C encoder in `fujinet-lib-experimental`.

### Framing: SLIP

Every packet is wrapped in SLIP (RFC 1055). A frame both **starts and ends** with `END`.

| Symbol | Byte | Meaning |
| --- | --- | --- |
| `END` | `0xC0` | Frame delimiter (before and after every frame) |
| `ESC` | `0xDB` | Escape prefix |
| `ESC_END` | `0xDC` | Follows `ESC` to mean a literal `0xC0` |
| `ESC_ESC` | `0xDD` | Follows `ESC` to mean a literal `0xDB` |

Any `0xC0` in the payload is sent as `0xDB 0xDC`; any `0xDB` as `0xDB 0xDD`.

### The packet header

Inside the SLIP frame is a fixed six-byte header, then optional field descriptors, optional AUX fields (little-endian), and an optional payload.

```
+--------+---------+-------------+----------+--------+----------+-----------+
| device | command | length (LE) | checksum | descr  | fields…  | payload…  |
|   1    |    1    |     2       |    1     |   1    |   AUX    |           |
+--------+---------+-------------+----------+--------+----------+-----------+
```

| Offset | Field | Meaning |
| --- | --- | --- |
| 0 | `device` | Destination device ID |
| 1 | `command` | Command ID; in a reply, `ACK` (`0x06`) or `NAK` (`0x15`) |
| 2–3 | `length` | Total decoded packet length **including** the header, little-endian |
| 4 | `checksum` | 8-bit add-with-carry-fold over the whole packet with this byte zeroed |
| 5 | `descr` | First field descriptor; `0x00` if there are no AUX fields |

> **Note** — `sizeof(fujibus_header) == 6` and the checksum byte is at offset 4 (both `static_assert`-ed). Preserve this layout exactly if you re-implement the header — the firmware reads it as a packed C struct.

### The checksum (not a plain XOR)

```c
uint8_t calcChecksum(const ByteBuffer &buf) {
    uint16_t chk = 0;
    for (size_t i = 0; i < buf.size(); ++i) {
        chk += buf[i];
        chk = (chk >> 8) + (chk & 0xFF);   // fold carry
    }
    return (uint8_t) chk;
}
```

### Field descriptors and AUX

The `descr` byte (and any additional descriptor bytes) encodes how many AUX values follow and how wide each is.

| `descr & 0x07` | Fields | Each | `FUJI_FIELD_*` |
| --- | --- | --- | --- |
| 0 | 0 | — | `NONE` |
| 1 | 1 | 1 byte | `A1` |
| 2 | 2 | 1 byte | `A1_A2` |
| 3 | 3 | 1 byte | `A1_A2_A3` |
| 4 | 4 | 1 byte | `A1_A2_A3_A4` |
| 5 | 1 | 2 bytes | `B12` (a `uint16`) |
| 6 | 2 | 2 bytes | `B12_B34` (two `uint16`) |
| 7 | 1 | 4 bytes | `C1234` (a `uint32`) |

The lookup tables in the code are `numFieldsTable = {0,1,2,3,4,1,2,1}` and `fieldSizeTable = {0,1,1,1,1,2,2,4}`. Bit 7 of a descriptor (`FUJI_DESCR_ADDTL_MASK`, `0x80`) means "another descriptor byte follows", letting a packet mix field widths. AUX values are little-endian immediately after all descriptor bytes; anything left over is the payload.

You rarely hand-assemble descriptors: the client library exposes `fuji_bus_call(device, cmd, fields, a1, a2, a3, a4, data, len, reply, reply_len)` plus `FUJICALL_*` macros named for exactly these field codes.

### Devices

A packet's first byte selects a device. The RP2350 also watches this byte: a packet addressed to `0xFF` (`FUJI_DEVICEID_DBC`, the bus controller itself) is consumed by the RP2350 and never reaches the ESP32 (see [Chapter 8](#8-inside-the-fujiversal-firmware)).

| ID | Symbol | Device |
| --- | --- | --- |
| `0x31`–`0x3F` | `DISK` … `DISK_LAST` | Virtual disk drives (block devices) |
| `0x40`–`0x43` | `PRINTER` … `PRINTER_LAST` | Printers / voice |
| `0x45` | `CLOCK` | Real-time clock (APETime) |
| `0x50`–`0x53` | `SERIAL` | Serial / modem passthrough |
| `0x5A` | `CPM` | CP/M console |
| `0x70` | `FUJINET` | The Fuji control device (mounts, hosts, config) |
| `0x71`–`0x78` | `NETWORK` … `NETWORK_LAST` | `N:` network units (8 of them) |
| `0x99` | `MIDI` | MIDI |
| `0xFF` | `DBC` | Bus controller (RP2350) — intercepted locally |

Commands are a single byte, many printable ASCII: `'O'` (`0x4F`) open, `'R'` (`0x52`) read, `'W'` (`0x57`) write, `'S'` (`0x53`) status, `'C'` (`0x43`) close. The Fuji control device uses the high range `0xD0`–`0xFF`. The complete enum is `fujiCommandID.h`.

### Request and response

1. The host builds a packet, SLIP-encodes it, and streams it out through `PUTC`.
2. The ESP32 decodes, dispatches to the addressed device, and acts.
3. The ESP32 replies with a packet whose `command` is `ACK` (`0x06`) on success — carrying any requested data as payload — or `NAK` (`0x15`).
4. The host polls `STATUS` for the `available` bit, then reads the reply through `GETC`.

> **Note** — The FEP-004 draft left "reply packet structure" and "how to signal data availability" open. The shipping code resolves them: replies are *full FujiBus packets*, and availability is the `STATUS` register's `available` bit — no platform-specific interrupt line required.

---

# Part II — Hardware Bring-Up

## 4. The ISA bus in one sitting

You must decode the bus **exactly** — a card that mis-decodes a cycle does nothing or corrupts the machine. If you are porting to a different bus, this is the chapter you replace.

### Two address spaces, four strobes

The 8088 has *separate* I/O and memory address spaces, each with its own read and write strobe.

| Strobe | Active | Cycle |
| --- | --- | --- |
| `/MEMR` | low | CPU reads memory — drive `D0–D7` if the address is our ROM |
| `/MEMW` | low | CPU writes memory |
| `/IOR` | low | CPU reads an I/O port — drive `D0–D7` if the port is ours |
| `/IOW` | low | CPU writes an I/O port — latch `D0–D7` if the port is ours |

On the universal board these are `GP28`–`GP31`.

### The signals that matter, and AEN above all

| Signal | Dir (card) | Why you care |
| --- | --- | --- |
| `A0–A19` | in | 20-bit memory address. I/O ports decode only `A0–A9`. |
| `D0–D7` | bi | 8-bit data. Drive only during *your* read cycles. |
| `AEN` | in | **Address Enable.** High during DMA. An I/O card MUST qualify decode with `AEN` low, or it responds to DMA addresses and crashes the machine. |
| `ALE` / `BALE` | in | Address valid to latch on the falling edge. |
| `RESET DRV` | in | Active-high system reset. |
| `CLK` / `OSC` | in | ~4.77 MHz bus clock / 14.318 MHz oscillator. |
| `I/O CH RDY` | out (o.c.) | Wait-state line; pull low to stretch a cycle. |
| `IRQ2–7`, `DRQ/DACK` | — | Interrupts / DMA. Not used by the polled byte pipe. |

> **Important** — `AEN` is the easiest signal to get wrong and the most destructive. The decode condition for *any* I/O port on ISA is "address matches **and** `AEN` is low". The universal board routes `AEN` to `GP32` precisely so the PIO can gate on it.

### Decoding our two windows

- **A boot ROM** (optional) in the expansion-ROM region `0xC0000`–`0xDFFFF`. The BIOS scans this region in 2 KB steps for option ROMs marked by `0x55 0xAA`, a length byte, and an entry point. We place ours at `0xC8000`.
- **An I/O window of four ports** (the byte pipe). The prototype range `0x300`–`0x31F` is conventional; we use `0x300`–`0x303` for `GETC`, `STATUS`, `PUTC`, `CONTROL`. (Compare the MSX build at `0xBFFC` and the CoCo build at `0xFF41` — the byte pipe is identical; only the decode address changes.)

### Timing, and why FujiNet hides behind a poll

A PC/XT bus read gives a card a few hundred nanoseconds to drive `D0–D7`. The PIO can meet that for a value it *already has* (a ROM byte, or whatever is in the byte-pipe FIFO). It cannot fetch a fresh byte from the ESP32 (USB + WiFi latency is milliseconds) inside one cycle.

The byte pipe is designed around this. The host never blocks the bus for the network: it reads `STATUS`, and only when `available` is set does it read `GETC`, returning a byte the RP2350 already buffered. The slow path runs entirely between bus cycles — which is why a FujiNet card does not normally need to assert `I/O CH RDY`.

## 5. Anatomy of the universal prototype board

The board is `fujiversal-pcb-prototype/Bus-proto` (`Universal-proto-v1`).

### The GPIO-to-ISA map

| GP | ISA | GP | ISA | GP | ISA |
| --- | --- | --- | --- | --- | --- |
| `GP0`–`GP7` | `A0`–`A7` | `GP8`–`GP15` | `A8`–`A15` | `GP16`–`GP19` | `A16`–`A19` |
| `GP20`–`GP27` | `D0`–`D7` | `GP28` | `/MEMR` | `GP29` | `/MEMW` |
| `GP30` | `/IOR` | `GP31` | `/IOW` | `GP32` | `AEN` |
| `GP33` | `CLK` | `GP34` | `ALE` | `GP35` | `RESET` |

`GP36`–`GP47` are unassigned spares brought out to the breakout headers. (Schematic net labels: `GP0_ISA_A0` … `GP35_ISA_RESET`.)

> **Note** — This map is also your PIO pin-define table. In [Chapter 9](#9-writing-the-isa-pio-program) these exact numbers become `.define A0_PIN 0`, `.define D0_PIN 20`, `.define IOR_PIN 30` in `boards/isa_proto.pio`.

### Connectors and headers

| Ref | What | Use |
| --- | --- | --- |
| `J1` | `Bus_ISA_8bit` edge | The universal bus header. The adapter mates here. |
| `J2` | ISA Breakout | Every ISA-side signal on 0.1″ pins — logic-analyzer tap. |
| `J3` / `J4` | Pico GPIO Breakout 1 & 2 | Every RP2350 GPIO on 0.1″ pins. |
| `J5`–`J8` | `Conn_01x20` | Seats for the Core2350B and ESP32-S3 modules. |
| `J9` | `Conn_02x02` | Power-source selection. |
| `U1` / `U2` | modules | WaveShare Core2350B / Freenove ESP32-S3-CAM. |
| `D1` | diode | Power-rail protection. |

> **Note** — There are **no buffer ICs** on this board, and the RP2350's GPIO connect to the 5 V ISA bus **directly** through the solder jumpers. Per the `fujinet-bringup` guidance this is *intentional and supported*: the RP2350 can interface to 5 V signal lines directly without a level shifter, which is precisely why it — and not the ESP32 — is the right chip for a wide 5 V bus like ISA ([Chapter 1](#choosing-the-interface-esp32-or-rp2350)). Level shifting in this design is an **ESP32** concern ([Chapter 6](#6-building-the-isa-adapter)), not an RP2350 one. The solder jumpers are your per-signal isolation control during bring-up — that is their job, not damage control.

### The solder-jumper farm

| Jumpers | Default | Function |
| --- | --- | --- |
| `JP1`–`JP36` | bridged | One per bus signal. **Cut** one to lift that signal — to isolate it, splice a buffer in series, or free the GPIO. |
| `JP37`–`JP39` | open | Optional configuration straps. **Bridge** only when an option calls for it. |

The discipline these enable: **verify the board one signal at a time**. Cut every jumper, bring the RP2350 up with no bus connection, then bridge signals back in groups (power/ground, then address, then strobes, then data), checking each at the breakout headers.

### Power

The board can take power from the ISA bus (`+5V`, with `±12V`/`-5V` on the edge), from USB, or from a bench supply. `J9` selects the source; `D1` blocks back-feed. ESP rails are `E_5V` / `E_3v3`.

> **Caution** — Decide your power source *before* you plug into a PC. During bench bring-up, power from USB and leave the ISA `+5V` jumper open; switch to bus power only once the card is otherwise proven.

## 6. Building the ISA adapter

Because the universal board's bus header is already an 8-bit ISA edge — and because the RP2350 takes the 5 V bus directly ([Chapter 1](#choosing-the-interface-esp32-or-rp2350)) — the ISA adapter is the simplest of the family: mostly a card edge, power, and optional signal-integrity buffering.

| Adapter | Machine edge | Universal side |
| --- | --- | --- |
| `CoCo-adapter` | `CoCo-edge` (`P1`) | `Bus_ISA_8bit` |
| `MSX-adapter` | `MSX-Edge` (`J1`) | `Bus_ISA_8bit` |
| **ISA-adapter** (you build it) | real ISA gold fingers (`parts:ISA_8bit`) | `Bus_ISA_8bit` |

The CoCo and MSX adapters *re-map* signals (their net labels show the 6809/Z80 pinout translated onto the ISA-shaped header). For ISA the signals already line up one-to-one, so the adapter's job is electrical.

### The card edge

Use the `parts:ISA_8bit` footprint. Two mechanical details:

1. **Orientation** — gold fingers and key notch must follow the ISA mechanical spec, or the card is electrically backwards.
2. **Thickness and gold** — 1.6 mm FR-4 with hard-gold fingers; ENIG wears. A slot *extender* or socketed breakout saves the fingers during bring-up.

### The 5-volt bus: less of a problem than you think

Here is where the first edition of this guide was wrong, so read carefully. Because the worked example uses an **RP2350**, the 5 V ISA bus is *not* a voltage-protection problem: per `fujinet-bringup`, the RP2350 interfaces to 5 V signal lines directly, and the universal board's direct, jumper-routed connection is the intended baseline. Buffering on an RP2350 adapter is **optional**, added for *signal integrity* on a real, loaded backplane — not to keep the chip alive.

| Approach | What you do | When |
| --- | --- | --- |
| Direct (the baseline) | RP2350 GPIO straight to the 5 V bus through the jumpers. Supported; this is how the prototype is built. | RP2350 on a short, lightly-loaded bus — start here |
| Buffered (optional) | `74LVC245` transceivers on data, `74LVC` buffers on address/strobe. Adds drive strength, isolates bus capacitance, offloads data-direction switching. | A production RP2350 card in a real, fully-populated slot |
| Translator (mandatory) | The same `74LVC245`/`74LVC` parts, but now **required** — to protect a *non-5 V-tolerant ESP32*. The `fujinet-bringup` H89 example drives one via `OE`/`DIR`. | Any **ESP32** interface (the narrow-bus path) |

For the RP2350 the choice is direct vs. buffered for signal quality; a translator is only **mandatory** on the ESP32 path.

A buffered adapter needs the data transceiver's **direction** driven. `D0–D7` are inputs except during a host read of *our* address:

```text
DIR(A->B, card drives bus) = our_read_cycle
  our_read_cycle = (/IOR low AND AEN low AND port in 0x300..0x303)
                OR (/MEMR low AND addr in ROM window 0xC8000..)
OE# (enable)    = our_cycle  (read OR write of one of our windows)
```

Produce these with a small GAL/ATF16V8 or a couple of `74LVC` gates, **or** let the RP2350 drive the `245` direction from a spare GPIO (`GP36`–`GP39`) — the PIO already computes "we are selected and this is a read."

> **Note** — MSX/CoCo dodge most of this because their cartridge edges are closer to the RP2350's comfort zone and their `read` PIO flips pin directions in step with the system clock. On ISA there is no convenient single clock edge to hang the data-direction flip on — you decode it from the strobes. Plan the buffer direction logic early; it is the adapter's only real complexity.

### Power and decoupling

Bring `+5V`/`GND` (and `±12V`/`-5V` if wanted) from the ISA edge to the universal board's power header, gated by `J9`. Put 10 µF bulk + 0.1 µF per buffer IC at the adapter; backplane power is noisy.

## 7. Hardware configuration and first power-on

### ISA jumper and strap settings

| Control | Setting for ISA | Reason |
| --- | --- | --- |
| `JP1`–`JP36` | bridged for `A0–A19`, `D0–D7`, `/MEMR`, `/MEMW`, `/IOR`, `/IOW`, `AEN`, `RESET`; rest cut | Connect only the signals the ISA PIO uses |
| `JP37`–`JP39` | open | No optional strap needed for the baseline build |
| `J9` power | USB during bench bring-up; bus `+5V` only when deployed | Avoid tying USB and ISA `+5V` together |
| microSD mod | apply per board revision | The Freenove SD pin-to-ground bridge |

### Test points and probing

| Probe at | To answer |
| --- | --- |
| `J2` `AEN`, `/IOR`, `A0–A9` | Is the host addressing our port, and is `AEN` low when it does? |
| `J3`/`J4` `GP20–GP27` | Is the RP2350 driving `D0–D7` at the right instant, and releasing after? |
| `J3`/`J4` `GP30`/`GP31` | Does the PIO see `/IOR` / `/IOW` cleanly, or is there ringing? |
| `J2` `I/O CH RDY` | Is anything stretching the cycle unexpectedly? |

Trigger the analyzer on `/IOR` falling with `AEN` low to capture exactly our read cycles.

### The power-on sequence

1. **Continuity, unpowered** — confirm `+5V`↔`GND` not shorted; each bridged jumper connects the expected GPIO to the expected ISA pin.
2. **RP2350 alone** — USB only, no bus. Confirm it enumerates as USB CDC. Nothing warms up.
3. **ESP32 alone** — power and flash; confirm WiFi and SD. Still no bus.
4. **Bus, address only** — bridge address + `AEN`; watch the PIO latch addresses. Data jumpers still cut.
5. **Bus, full** — bridge `/IOR`/`/IOW`/`/MEMR` + data jumpers. Run the loopback test of [Chapter 10](#10-bringing-the-rp2350-up).
6. **In the machine** — only now, with the adapter buffered, move the card into a real slot and switch `J9` to bus power.

> **Tip** — Keep a powered USB hub with per-port power between your workstation and both dev boards. You will reflash the RP2350 and ESP32 many times; per-port power lets you cycle one without disturbing the other or the bus.

---

# Part III — The RP2350 Bus Interface

## 8. Inside the fujiversal firmware

`fujiversal` is a single Pico-SDK application that emulates a ROM chip and a four-register I/O window on the host's bus, and bridges that window to the ESP32 over USB.

### Two cores

- **Core 1 — `romulan()`**: the bus loop. Runs `__time_critical_func`, sets up the PIO, then spins forever pulling latched bus words from a PIO FIFO and responding. The only code allowed to touch the bus.
- **Core 0 — `main()`**: the USB bridge. Runs TinyUSB, moves bytes between host (via core 1) and ESP32 (via USB-CDC), maintains SLIP framing, intercepts the packets addressed to the bus controller, and feeds the watchdog.

The two cores exchange single bytes through the SDK's multicore FIFO, buffered by a 1 KB ring on each side.

### The three PIO state machines

| State machine | Job |
| --- | --- |
| `wait_sel` | Watch the select/decode signals; raise an IRQ when the host addresses the card. **This encodes your bus's decode rule.** |
| `send_bus` | On that IRQ, sample all 32 low GPIO in one instruction and autopush the 32-bit word to the RX FIFO. Core 1 reads it as a `BusSignals` union. |
| `read` | Drive `D0–D7` with a byte core 1 supplies, manage data-pin direction (high-Z except during a read of our address), release the bus when the cycle ends. |

### The BusSignals union (MSX shown)

```c
typedef union {
  struct {
    uint32_t addr:16;     // A0..A15  on GP0..GP15
    uint32_t resv:4;
    uint32_t data:8;      // D0..D7   on GP20..GP27
    uint32_t rd:1;        // /RD
    uint32_t wr:1;        // /WR
    uint32_t iorq:1;      // /IORQ
    uint32_t memrq:1;     // /MEMRQ
  } __attribute__((packed));
  uint32_t combined;
} __attribute__((packed)) BusSignals;
```

The bit layout *is* the GPIO map.

### ROM emulation and the I/O window

```c
// from romulan(), main.cpp — the per-cycle decode
if (IO_BASE <= bus.addr && bus.addr < IO_TOP) {
    unsigned io_reg = (bus.addr - IO_BASE) & 0x3;
    switch (io_reg) {
    case IO_GETC:   pio_put_fifo(PSM_READ, sio_hw->fifo_rd); break;   // byte from ESP32
    case IO_STATUS: pio_put_fifo(PSM_READ,
                       sio_hw->fifo_st & SIO_FIFO_ST_VLD_BITS
                         ? IO_FLAG_AVAIL : 0x00); break;              // is a byte ready?
    case IO_PUTC:   sio_hw->fifo_wr = bus.combined; break;            // byte to ESP32
    case IO_CONTROL: break;
    }
}
else if (BUS_ROM_BASE <= bus.addr && bus.addr < BUS_ROM_TOP) {
    pio_put_fifo(PSM_READ, rom_ptr[bus.addr - BUS_ROM_BASE]);         // serve a ROM byte
}
```

The four registers are the two ends of the multicore FIFO dressed up as bus-visible ports. `IO_BASE`, the register offsets, `IO_FLAG_AVAIL`, `BUS_ROM_BASE`/`BUS_ROM_TOP` are all `.define`s in the board's `.pio` file — re-pointing the byte pipe at ISA's address map is mostly changing those constants.

### ROM bank-switching: the one packet the RP2350 keeps

The host-side loader swaps the emulated ROM's contents with FujiBus packets addressed to `FUJI_DEVICEID_DBC` (`0xFF`). Core 0 sniffs the second byte of every frame and, if it is `0xFF`, consumes the packet locally:

```c
if (command_size == 2 && input != FUJI_DEVICEID_DBC) {
    // second byte isn't 0xFF -> not for us, push to ESP32
}
else if (command_size > 1 && input == SLIP_END) {
    process_command(command_buf);     // a complete DBC frame: handle locally
}
```

`process_command()` implements `FUJICMD_OPEN` (select a RAM bank), `FUJICMD_WRITE` (fill it), `FUJICMD_CLOSE` (activate it), `FUJICMD_RESET` (revert). An ISA build needs no change here.

## 9. Writing the ISA PIO program

This builds `boards/isa_proto.pio`. The repo ships `msx_proto_260402.pio` and `coco_proto_260402.pio`; an ISA file does not yet exist. Use the MSX file as your structural template (it, like ISA, has separate I/O and memory strobes) and change three things: the pin defines, the decode in `wait_sel`, and the data-direction timing in `read`.

> **Important** — The PIO listings here are a **worked starting point** in the style of the shipping `.pio` files, not a build the repository has proven on silicon. Bring them up with a logic analyzer ([Chapter 10](#10-bringing-the-rp2350-up)). Every value traces to the GPIO map and the ISA decode rules.

### Pin defines and constants

```text
.pio_version 1

.define public DATA_WIDTH   8
.define public ADDR_WIDTH   20          ; ISA carries A0..A19

.define public A0_PIN       0           ; A0..A19  -> GP0..GP19
.define public D0_PIN       20          ; D0..D7   -> GP20..GP27
.define public MEMR_PIN     28          ; /MEMR
.define public MEMW_PIN     29          ; /MEMW
.define public IOR_PIN      30          ; /IOR
.define public IOW_PIN      31          ; /IOW
.define public AEN_PIN      32          ; AEN  (HIGH during DMA)
.define public CLK_PIN      33          ; bus CLK
.define public ALE_PIN      34          ; address latch enable
.define public RESET_PIN    35          ; RESET DRV

; --- byte-pipe registers, in ISA I/O space (ports 0x300..0x303) ---
.define public IO_BASE      0x300
.define public IO_GETC      0
.define public IO_STATUS    1
.define public IO_PUTC      2
.define public IO_CONTROL   3
.define public IO_FLAG_AVAIL 0x80

; --- boot ROM window, in the expansion-ROM region ---
.define public BUS_ROM_BASE 0xC8000
.define public BUS_ROM_TOP  0xCC000     ; 16 KB option ROM

.define public IRQ_SEL 0
```

### The BusSignals union for ISA

```c
typedef union {
  struct {
    uint32_t addr:20;     // A0..A19  on GP0..GP19
    uint32_t data:8;      // D0..D7   on GP20..GP27 -- starts at bit 20
    uint32_t memr:1;      // /MEMR    GP28
    uint32_t memw:1;      // /MEMW    GP29
    uint32_t ior:1;       // /IOR     GP30
    uint32_t iow:1;       // /IOW     GP31
  } __attribute__((packed));
  uint32_t combined;
} __attribute__((packed)) BusSignals;
```

> **Caution** — `send_bus` samples GPIO 0–31, so `AEN` (`GP32`), `CLK` (`GP33`), `ALE` (`GP34`), `RESET` (`GP35`) are *above* the 32-bit sample window. The baseline design gates `AEN` inside `wait_sel` (which can `wait` on any GPIO) rather than reading it in the latched word. If your decode needs `AEN`'s level in core 1, move data down to free low bits or sample with a second `mov`.

### Decode: the wait_sel program

The ISA "we are selected" condition has two forms — an I/O cycle (valid only when `AEN` is low) and a memory (ROM) cycle. Compare the MSX `wait_sel`, which gates on `/SLTSL`; here we gate on `AEN` and the strobes.

```text
.program wait_sel
.wrap_target
idle:
        wait 0 gpio AEN_PIN          ; an I/O cycle requires AEN low
        wait 0 gpio IOR_PIN  [1]     ; (illustrative) block until /IOR falls
        irq IRQ_SEL                  ; tell send_bus + core1 we are selected
        wait 1 gpio IOR_PIN          ; hold until the strobe releases
.wrap
```

> **Note** — The single-strobe `wait` above is simplified to show the shape. A complete ISA `wait_sel` must select on `/IOR` *or* `/IOW` *or* `/MEMR`, and pre-qualify the address against the I/O or ROM window so it does not IRQ on every bus cycle. Two ways: (a) decode the high address bits with a few `mov`/`jmp` before the `wait`, or (b) decode the window in external logic (a GAL on the adapter) and feed a single "card selected" line to one GPIO — reducing `wait_sel` to the MSX form. Option (b) is faster to bring up and recommended for the first board; the CoCo/MSX boards effectively use (b) since the cartridge edge gives them a ready-made select line.

### Driving data: the read program

```text
.program read
.side_set 1 opt
        mov x, ~null  side 1         ; X = all ones; start with D0-7 as inputs
.wrap_target
        pull block                   ; wait for core1 to provide the byte
        out pins, DATA_WIDTH         ; place it on D0-D7
        mov osr, ~null
        out pindirs, DATA_WIDTH side 0   ; drive D0-D7 (outputs)
        wait 0 gpio IOR_PIN          ; ... while /IOR (or /MEMR) is low
        wait 1 gpio IOR_PIN          ; host has latched; cycle ending
        mov osr, null
        out pindirs, DATA_WIDTH side 1   ; release D0-D7 back to inputs
.wrap
```

`send_bus` needs no ISA-specific change — keep it verbatim from the MSX file.

### Wiring it into core 1

ISA distinguishes I/O reads from writes by which strobe is active, so fold the strobe into the register index (the way the CoCo build folds `R/W`):

```c
if (IO_BASE <= bus.addr && bus.addr < IO_BASE + 4) {
    unsigned io_reg = (bus.addr - IO_BASE) & 0x3;
    if (!bus.iow) {                       // an I/O write cycle
        if (io_reg == IO_PUTC) sio_hw->fifo_wr = bus.data;
    } else if (!bus.ior) {                // an I/O read cycle
        if (io_reg == IO_GETC)
            pio_put_fifo(PSM_READ, sio_hw->fifo_rd);
        else if (io_reg == IO_STATUS)
            pio_put_fifo(PSM_READ,
                sio_hw->fifo_st & SIO_FIFO_ST_VLD_BITS ? IO_FLAG_AVAIL : 0);
    }
}
else if (!bus.memr && BUS_ROM_BASE <= bus.addr && bus.addr < BUS_ROM_TOP) {
    pio_put_fifo(PSM_READ, rom_ptr[bus.addr - BUS_ROM_BASE]);
}
```

### Adding the board to the build

```cmake
# CMakeLists.txt — add isa_proto to the RP2350 board set
if(BOARD STREQUAL "msxrp2350"
   OR BOARD STREQUAL "msx_proto_260402"
   OR BOARD STREQUAL "coco_proto_260402"
   OR BOARD STREQUAL "isa_proto")                 # <-- new
    set(PICO_BOARD "pimoroni_pga2350" CACHE STRING "Pico board type" FORCE)
    set(PICO_PLATFORM "rp2350-arm-s" CACHE STRING "Pico platform" FORCE)
    set(PICO_CHIP "rp2350" CACHE STRING "Pico chip" FORCE)
    # PICO_PIO_USE_GPIO_BASE=1 is required: ISA uses GP0..GP35.
endif()
```

> **Important** — ISA touches GPIO above 31 (`AEN`=`GP32`, `RESET`=`GP35`). The build **must** define `PICO_PIO_USE_GPIO_BASE=1` (the existing RP2350 boards do) so the PIO can address the upper GPIO bank. `setup_state_machine()` in `setup_sm.cpp` computes the GPIO base/range and rejects an illegal span — heed its return codes.

### Generating the host ROM

```bash
# 1. build the host-side loader + CONFIG for ISA (in fujinet-config)
make PLATFORM=isa            # see Chapter 15  ->  config-isa.rom

# 2. build the RP2350 firmware with that ROM baked in
cd ../fujiversal
make ROM_FILE=../fujinet-config/config-isa.rom BOARD=isa_proto
# -> build/isa_proto/fujiversal_isa_proto.uf2
```

## 10. Bringing the RP2350 up

### Flash and enumerate

Hold BOOTSEL while plugging the Core2350B into USB; it mounts as mass storage. Copy the `.uf2` (or `picotool load`). On reset it should enumerate as a USB CDC-ACM serial device — the port the ESP32 will later own. Open it from your workstation first; you have a debug console before the ESP32 is in the loop.

### The loopback test

With the RP2350 on USB and a terminal on its CDC port:

1. Send a byte from the terminal; confirm (logic analyzer on `J3`/`J4`, or a tiny host test program) that a host read of `GETC` returns it and that `STATUS` showed `available` first.
2. Have the host write a byte to `PUTC`; confirm it arrives on the terminal.

That round trip exercises both PIO directions, the multicore FIFO, and the USB bridge — layers 2–3 — without any FujiNet firmware running.

> **Tip** — Build `fujiversal` with `USE_STDIO` / `VERBOSE_DEBUG` for `printf` over the CDC port during bring-up, then turn it off: the debug build steals the same CDC channel the ESP32 needs, so a verbose RP2350 and a connected ESP32 cannot coexist.

---

# Part IV — The ESP32 Device Firmware

## 11. Where ISA fits in fujinet-firmware

The ESP32 never sees ISA. It sees a CDC-ACM serial port carrying FujiBus packets — exactly what the firmware's `rs232` bus already consumes (the same class used by the real RS-232 FujiNet and the MSX serial bring-up). The two existing `fujiversal` targets, `fujiversal-rs232` and `fujiversal-drivewire`, prove the pattern.

### The rs232 bus IS the FujiBus transport

`lib/bus/rs232/` is misleadingly named: it is the FujiBus/FEP-004 engine, not an RS-232 UART driver. It contains its own `FujiBusPacket.cpp` and a `systemBus` that reads/writes whole packets:

```cpp
// lib/bus/rs232/rs232.h  (abridged)
class systemBus {
    std::forward_list<virtualDevice *> _daisyChain;
    IOChannel *_port;
#if FUJINET_OVER_USB
    ACMChannel _serial;        // USB-CDC host channel  <-- the fujiversal path
#else
    UARTChannel _serial;       // a real UART
#endif
    std::unique_ptr<FujiBusPacket> readBusPacket(int first = -1);
    void writeBusPacket(FujiBusPacket &packet);
    void sendReplyPacket(fujiDeviceID_t source, bool ack, const void *data, size_t length);
    void addDevice(virtualDevice *pDevice, fujiDeviceID_t device_id);
};
extern systemBus SYSTEM_BUS;
```

The `FUJINET_OVER_USB` switch is the whole story: built for the RP2350-over-USB path, `_serial` is an `ACMChannel` (USB-CDC *host*). ISA uses this, identical to `fujiversal-rs232`.

> **Important** — For a tandem bus-based platform you usually write **no new bus class and no new device classes on the ESP32**. You add a build target and a pin map, and reuse `rs232`. New ESP32 code is needed only when your platform exposes a device the existing set lacks, or a disk image format not already handled. The deep work is the PIO (Part III) and the host side (Chapters 15–16).

## 12. Adding the platform to the build system

### The build platform file

```ini
; build-platforms/platformio-fujiversal-isa.ini
[fujinet]
build_bus      = RS232          ; reuse the FujiBus serial bus
build_platform = BUILD_RS232    ; ... and its device/media set

[env:fujiversal-isa]
build_type = debug
build_flags =
    ${env.build_flags}
    -D PINMAP_FUJIVERSAL_ISA            ; <-- new pin map
    -D CONFIG_USB_HOST_ENABLED=1        ; ESP32-S3 is the USB *host*
    -D CONFIG_USB_CDC_ACM_HOST_ENABLED=1
platform         = espressif32@${fujinet.esp32s3_platform_version}
platform_packages = ${fujinet.esp32s3_platform_packages}
board            = esp32-s3-wroom-1-n16r8
```

Three lines carry the design: `build_bus = RS232` chooses the FujiBus transport; the two `CONFIG_USB_*` flags make the ESP32-S3 a USB host so it can open the RP2350's CDC port; `PINMAP_FUJIVERSAL_ISA` selects your board's pins.

### The pin map

On a `fujiversal` board the ESP32 pin map is small — the heavy bus I/O is on the RP2350.

```c
// include/pinmap/fujiversal_isa.h   (sketch; mirror fujiversal_rs232.h)
#ifdef PINMAP_FUJIVERSAL_ISA
#define PIN_LED_WIFI     GPIO_NUM_..   // white WiFi LED
#define PIN_LED_BUS      GPIO_NUM_..   // bus activity LED
#define PIN_BUTTON_A     GPIO_NUM_..
// USB host D+/D- and SD pins per the Freenove ESP32-S3-CAM board
#endif
```

> **Note** — Match the shared LED/button conventions (white = WiFi, amber = bus, Button A + safe-reset) so the existing `lib/hardware` LED/boot logic "just works."

### Partitions and flashing

Reuse `fujinet_partitions_16MB.csv`. Build and flash:

```bash
pio run -e fujiversal-isa
pio run -e fujiversal-isa -t upload
```

## 13. Device classes

A FujiNet "device" is a class derived from `virtualDevice` that handles FujiBus packets for one device ID. The `rs232` device set you inherit covers the whole standard feature list.

| Device ID | Class (`lib/device/rs232/`) | Function |
| --- | --- | --- |
| `0x70` | `rs232Fuji` | Mounts, host slots, app-keys, hashing, adapter config — the CONFIG back end |
| `0x31`–`0x3F` | `rs232Disk` + media | Virtual disk drives |
| `0x71`–`0x78` | `rs232Network` | The `N:` device — 8 units |
| `0x40`–`0x43` | `rs232Printer` | Printer emulation to PDF |
| `0x50`–`0x53` | `rs232Modem` | Modem / serial passthrough |
| `0x45` | clock | APETime real-time clock |
| `0x5A` | `rs232CPM` | CP/M console |

### The virtualDevice contract

```cpp
// lib/bus/rs232/rs232.h
class virtualDevice {
protected:
    fujiDeviceID_t _devnum;
    virtual void rs232_process(FujiBusPacket &packet) = 0;   // per-command dispatch (a switch)
    virtual void rs232_status(FujiStatusReq reqType) = 0;    // 4 status bytes
    virtual void shutdown() {}
public:
    fujiDeviceID_t id() { return _devnum; }
    bool is_config_device = false;   // true for the disk that boots CONFIG
    bool device_active = true;
};
```

To add a device, subclass `virtualDevice`, implement those two methods, and register an instance:

```cpp
SYSTEM_BUS.addDevice(new myDevice(), FUJI_DEVICEID_SOMETHING);
```

For a stock ISA build you change nothing here — the `rs232` set registers itself.

## 14. Media classes

A media class turns a host disk-image file on the SD card into the sectors a virtual disk device serves. They live in `lib/media/`, one directory per platform, behind the `MediaType` interface in `lib/media/media.h`.

**Reuse first.** `rs232Disk` presents *block* storage: the host reads/writes 512-byte sectors by number (the FujiBus disk command carries the sector as a 32-bit `C1234` field). If your platform's software is happy with raw block images, the existing path serves them and you add nothing.

**Add a class only** when the host expects an image format with structure the firmware must understand (a header, an interleave, a non-512 sector size):

```cpp
// the shape of a MediaType (lib/media/media.h)
class MediaType {
public:
    virtual bool read(uint32_t blockNum, uint16_t *readcount) = 0;
    virtual bool write(uint32_t blockNum, bool verify)        = 0;
    virtual bool format(uint16_t *responsesize)               = 0;
    virtual mediatype_t mount(fnFile *f, uint32_t disksize)   = 0;
    virtual void unmount()                                    = 0;
    static  mediatype_t discover_disktype(const char *filename); // by extension
};
```

For ISA, a flat sector image (a `.img` of a 360 KB / 720 KB floppy or a hard disk) maps directly onto block reads and needs no new class. Start flat.

> **Tip** — `discover_disktype()` dispatches on file extension. When you add a format, register its extension there so mounting `disk.img` from CONFIG picks the right `MediaType` automatically.

## 15. The host ROM and CONFIG

The emulated ROM the RP2350 serves is built by `fujinet-config`. This is code that runs **on the host CPU**, as platform-specific as the PIO.

`fujinet-config` builds, per platform, two things baked into one ROM image:

1. **A loader** — on ISA an option ROM (`0x55 0xAA`, length, entry point) the BIOS calls during its expansion-ROM scan. It brings up the byte pipe, asks FujiNet to mount the boot disk, and boots it or launches CONFIG.
2. **The CONFIG application** — the full-screen UI for WiFi hosts, TNFS browsing, and mounting images into the eight disk slots. Its screen text lives in `fujinet-config/src/<platform>/screen.c`, rendered in the machine's native character set.

### How the loader talks to FujiNet

```text
put_byte(b):   outb(IO_BASE+IO_PUTC, b)
get_byte():    while (!(inb(IO_BASE+IO_STATUS) & IO_FLAG_AVAIL)) ;
               return inb(IO_BASE+IO_GETC)
```

On ISA those are 8088 `IN`/`OUT` to ports `0x300`–`0x303`. On MSX they are memory reads/writes at `0xBFFC`; on CoCo at `0xFF41`. **Only the access method and addresses change** — which is why the client library is mostly shared C with a thin per-platform shim.

```bash
# in fujinet-config
make PLATFORM=isa          # builds loader + CONFIG -> config-isa.rom
```

The output is consumed by `fujiversal` (`ROM_FILE=…`), converted to a C array (`build/<board>/rom.h`), and served from `BUS_ROM_BASE`.

## 16. The client library

`fujinet-lib` is the C library application programmers link against. The experimental tree, `fujinet-lib-experimental`, is the FujiBus-native version and the template for your port.

### The backend pattern

```text
fujinet-lib-experimental/
  include/        fujinet-bus.h, fujinet-bus-ezcall.h, FUJI_FIELD_*, FujiDCB
  common/         network.c, network_json.c, fuji_*.c   (platform-independent)
  bus/
    apple2/  atari/  c64/  coco/  msx/  msdos/  adam/    (one dir per platform)
    isa/     <-- you add this
  Makefile        PLATFORMS = coco apple2 atari c64 msx msdos adam   (+ isa)
```

`common/` is the bulk of the library and is shared verbatim. Each `bus/<platform>/` provides the same small surface:

| File | Responsibility |
| --- | --- |
| `portio.s` / `portio.h` | `inb`/`outb` to ports `0x300`–`0x303` (8088 `IN`/`OUT`) |
| `fujinet-bus-isa.c` | `fuji_bus_call` / `fuji_bus_read` / `fuji_bus_write`: build the FujiBus packet (header, descriptors, AUX, payload, checksum), SLIP-encode, stream out `PUTC`, read the SLIP reply back via `GETC` |

Compare `bus/msdos/portio.s` (real PC `IN`/`OUT`) — the ISA backend is closest to it. The public surface:

```c
// include/fujinet-bus.h
bool   fuji_bus_call(uint8_t device, uint8_t fuji_cmd, uint8_t fields,
                     uint8_t aux1, uint8_t aux2, uint8_t aux3, uint8_t aux4,
                     const void *data, size_t data_length,
                     void *reply, size_t reply_length);
size_t fuji_bus_read (uint8_t device, void *buffer, size_t length);
size_t fuji_bus_write(uint8_t device, const void *buffer, size_t length);
```

A program that opens an `N:` URL never sees FujiBus framing: it calls `network_open()` in `common/`, which calls `fuji_bus_call()`, which calls your `bus/isa` primitives, which hit the ports.

```bash
make isa            # builds fujinet.lib for the isa backend
```

`SRC_DIRS = common bus/%PLATFORM%` already composes the shared core with your backend; no other Makefile change is needed.

> **Tip** — Bring the library up against the loopback of [Chapter 10](#10-bringing-the-rp2350-up) before the full firmware is ready: a host program that calls `fuji_bus_write()` and watches bytes appear on the RP2350's USB console proves your SLIP encoder and port I/O independent of the ESP32.

---

# Part V — Integration & Validation

## 17. The bring-up milestone ladder

Bring a platform up in the order the layers stack, lowest first. Each rung is independently testable.

| M | Milestone | Proven when… |
| --- | --- | --- |
| 0 | Boards seated, power correct | Continuity passes; nothing warms up on USB; `J9` set for bench |
| 1 | RP2350 enumerates | The Core2350B appears as a USB CDC device |
| 2 | ESP32 alive | Firmware flashed; WiFi joins; SD mounts |
| 3 | Byte pipe loopback | A host `GETC` returns an injected byte; a host `PUTC` reaches the USB console |
| 4 | Address decode | The PIO IRQ fires on *our* I/O cycles and ROM reads, and **not** during DMA (`AEN` high) |
| 5 | FujiBus ACK | A `fuji_bus_call()` returns `ACK` from the ESP32 (the Fuji device answers an adapter-config query) |
| 6 | CONFIG boots | The host fetches the option ROM, runs the loader, CONFIG draws on screen |
| 7 | Mount + boot a disk | CONFIG mounts a `.img`; the machine boots it |
| 8 | `N:` works | A program opens `N:HTTP://…` and reads data over WiFi |

> **Note** — Milestones 1–3 are exactly the `fujinet-bringup` MVP ([Chapter 1](#start-at-fujinet-bringup)): a minimal byte relay plus `iotest` proving two-way communication, with the FujiNet firmware running as a PC build. They need **no host bus board at all** — you can reach milestone 3 before the ISA adapter PCB even arrives. Milestone 5 is the `fujinet-bringup` "Hello World" (fetch the adapter config) succeeding for the first time. Order your work so the slow-to-fabricate adapter is never on the critical path.

## 18. Troubleshooting

| Symptom | Layer | Likely cause and cure |
| --- | --- | --- |
| Machine hangs/reboots the instant the card is inserted | 1 | I/O decode not gated on `AEN` — the card answers DMA. Confirm `AEN`-low is in `wait_sel`. Or a 5 V signal fights an RP2350 output: check buffering/jumpers. |
| Card does nothing; no PIO IRQ | 2 | `wait_sel` decode never matches. Wrong `IO_BASE`, wrong strobe polarity (ISA strobes are active-**low**), or an address jumper cut. Probe `J2` vs `J3`/`J4`. |
| PIO IRQs fire on every bus cycle | 2 | `wait_sel` not pre-qualifying the address window. Add window decode, or feed a decoded select line from adapter logic. |
| Host reads our port, gets `0xFF`/garbage | 2–3 | Data not driven in time, or direction backwards. Check the `read` program's `pindirs` flip timing against the strobe, and the buffer `DIR` term. |
| Bytes go out but no reply | 3–4 | Loopback (M3) first. If loopback is fine, the ESP32 isn't opening the CDC port (`CONFIG_USB_CDC_ACM_HOST_ENABLED`?) or the RP2350 is still in verbose `printf` mode stealing the channel. |
| `fuji_bus_call` returns failure though bytes flow | 4 | Framing bug: checksum (add-with-fold, not XOR), little-endian `length`, or a descriptor/AUX mismatch. Diff your encoder against `FujiBusPacket.cpp`. |
| BIOS never runs the option ROM | 5 | ROM not on a 2 KB boundary, bad `0x55 0xAA`/length/checksum header, or `BUS_ROM_BASE` outside `0xC0000`–`0xDFFFF`. Verify served bytes at `0xC8000` with the analyzer on `/MEMR`. |
| CONFIG draws garbage characters | 5 | Host-side rendering — `fujinet-config/src/<platform>/screen.c` wrong charset/addresses. A byte-pipe problem would corrupt *data*, not just glyphs. |
| Intermittent corruption at speed | 1 | Unbuffered 5 V bus ringing, or missing decoupling at the adapter. Add the `74LVC` buffers. |

## 19. Porting to a bus that is not ISA

The *method* is unchanged; specific things move.

| What changes per bus | Where you change it |
| --- | --- |
| Connector and voltage | A new adapter PCB; level-shifting depends on bus voltage/drive |
| Signal-to-GPIO mapping | If the bus does not match the ISA-shaped header, the adapter re-wires it (as CoCo/MSX do), and the PIO `.define`s follow |
| The decode rule | `wait_sel` in the `.pio`: which lines mean "selected", and the timing reference (clock edge, chip-select, or strobe) |
| Data-direction timing | The `read` program: what edge to flip `pindirs` on. Synchronous buses hang it on the clock; asynchronous ones on the strobe |
| Byte-pipe address | `IO_BASE` / `BUS_ROM_BASE` and the register offsets |
| Host loader + screens | `fujinet-config/src/<platform>/` |
| Client port I/O | `fujinet-lib` `bus/<platform>/portio.*` |

Everything else — FujiBus framing, the ESP32 device/media classes, the `N:` stack, the byte-pipe model — is shared and unchanged.

> **Tip** — The fastest bring-up of a brand-new bus: feed the PIO a single decoded "card selected" line from a GAL on the adapter (so `wait_sel` reduces to the MSX form), put the byte pipe wherever the host can do four `peek`/`poke`s, and reuse `BUILD_RS232` whole.

---

# Appendices

## Appendix A — FujiBus quick reference

**Frame:** `END` (`0xC0`) · header · descriptors · AUX (little-endian) · payload · `END`. SLIP escapes: `0xC0`→`0xDB 0xDC`, `0xDB`→`0xDB 0xDD`.

**Header (6 bytes):** `device`, `command`, `length` (u16 LE, total incl. header), `checksum` (add-with-carry-fold, this byte zeroed during calc), `descr` (first field descriptor).

**Field descriptors** (`descr & 0x07`; bit 7 = more follow): `0`=none · `1`=1×u8 · `2`=2×u8 · `3`=3×u8 · `4`=4×u8 · `5`=1×u16 · `6`=2×u16 · `7`=1×u32.

**Replies:** `command` = `ACK` `0x06` (success, optional payload) or `NAK` `0x15` (failure).

**Device IDs:** `0x31`–`0x3F` disk · `0x40`–`0x43` printer · `0x45` clock · `0x50`–`0x53` serial · `0x5A` CP/M · `0x70` Fuji control · `0x71`–`0x78` network · `0x99` MIDI · `0xFF` bus controller (DBC).

**Common commands** (`fujiCommandID.h` is authoritative):

| Cmd | Name | Cmd | Name |
| --- | --- | --- | --- |
| `0x4F` `'O'` | `OPEN` | `0xF8` | `MOUNT_IMAGE` |
| `0x52` `'R'` | `READ` | `0xF9` | `MOUNT_HOST` |
| `0x57` `'W'` | `WRITE` | `0xF7` | `OPEN_DIRECTORY` |
| `0x53` `'S'` | `STATUS` | `0xF6` | `READ_DIR_ENTRY` |
| `0x43` `'C'` | `CLOSE` | `0xE8` | `GET_ADAPTERCONFIG` |
| `0x50` `'P'` | `PARSE`/`PUT` | `0xD9` | `CONFIG_BOOT` |
| `0x51` `'Q'` | `QUERY` | `0x80` | `JSON_PARSE` |
| `0x06` | `ACK` | `0x81` | `JSON_QUERY` |
| `0x15` | `NAK` | `0xFF` | `RESET` |

## Appendix B — ISA 8-bit (PC/XT) 62-pin pinout

Pin rows: A = component side, B = solder side. "GP" = the universal board's GPIO assignment for the signals FujiNet uses.

| A | Signal | GP | | B | Signal | GP |
| --- | --- | --- | --- | --- | --- | --- |
| A1 | `/I/O CH CK` | — | | B1 | `GND` | — |
| A2–A9 | `D7`…`D0` | `27`…`20` | | B2 | `RESET DRV` | `35` |
| A10 | `I/O CH RDY` | — | | B3 | `+5V` | — |
| A11 | `AEN` | `32` | | B11 | `/SMEMW` | `29` |
| A12–A31 | `A19`…`A0` | `19`…`0` | | B12 | `/SMEMR` | `28` |
| | | | | B13 | `/IOW` | `31` |
| | | | | B14 | `/IOR` | `30` |
| | | | | B20 | `CLK` | `33` |
| | | | | B28 | `ALE` | `34` |
| | | | | B30 | `OSC` | — |
| | | | | B4–B26 | `IRQ2–7`, `DRQ/DACK` | — |
| | | | | B5/B7/B9 | `-5V`/`-12V`/`+12V` | — |

Schematic net names confirm this: `~{SMEMR}`/`~{SMEMW}`, `~{IOR}`/`~{IOW}`, `AEN`, `ALE`, `CLK`, `OSC`, `IO_READY`, `IRQ2`–`IRQ7`, `DRQ1`–`DRQ3`, `~{DACK0}`–`~{DACK3}`, `TC`, and `BA00`–`BA19` (buffered address).

## Appendix C — Universal board jumper & test-point reference

| Ref | Type / default | Function |
| --- | --- | --- |
| `JP1`–`JP36` | solder, bridged | One per bus signal; cut to isolate or insert a buffer |
| `JP37`–`JP39` | solder, open | Optional configuration straps |
| `J1` | `Bus_ISA_8bit` | Universal bus header — adapter mates here |
| `J2` | 2×13 header | ISA-side breakout (logic-analyzer tap) |
| `J3`, `J4` | headers | RP2350 GPIO breakouts |
| `J5`–`J8` | 1×20 | Core2350B and ESP32-S3 module seats |
| `J9` | 2×2 | Power-source selection |
| `U1` / `U2` | modules | WaveShare Core2350B / Freenove ESP32-S3-CAM |
| `D1` | diode | Power-rail protection |

There are no buffer ICs; add level-shifting on the adapter (Chapter 6).

## Appendix D — Repository map

| Path | Contents |
| --- | --- |
| `fujinet-bringup/README.md` | **Start here.** The bring-up-first method (relay + `iotest` + PC firmware) |
| `fujinet-bringup/iotest/` | Host two-way-comms test + per-platform `portio` examples (~14 platforms) |
| `fujinet-bringup/esp32/`, `…/rp2350/` | Minimal byte-relay firmware (GPIO bus ⟷ USB serial) |
| `fujiversal/main.cpp` | Core 0 USB bridge + core 1 `romulan()` bus loop + DBC handler |
| `fujiversal/boards/*.pio` | Per-board PIO + pin defines + `BusSignals` union (add `isa_proto.pio`) |
| `fujiversal/setup_sm.cpp` | Generic PIO state-machine setup helper |
| `fujiversal/FujiBusPacket.*` | FujiBus encoder/decoder (RP2350 copy) |
| `fujiversal/CMakeLists.txt` | Board selection, `PICO_PIO_USE_GPIO_BASE` |
| `fujiversal-pcb-prototype/Bus-proto/` | `Universal-proto-v1` board (jumpers, breakouts) |
| `fujiversal-pcb-prototype/*-adapter/` | CoCo / MSX adapters (templates for the ISA adapter) |
| `fujiversal-pcb-prototype/parts.pretty/ISA_8bit*` | ISA edge footprints |
| `fujinet-firmware/build-platforms/platformio-fujiversal-*.ini` | Build targets (add `…-isa.ini`) |
| `fujinet-firmware/lib/bus/rs232/` | FujiBus transport + `systemBus` (reused as-is) |
| `fujinet-firmware/lib/device/rs232/` | Device classes (Fuji, disk, network, printer, …) |
| `fujinet-firmware/lib/media/` | Image formats (`MediaType`) |
| `fujinet-firmware/include/pinmap/` | Pin maps (add `fujiversal_isa.h`) |
| `fujinet-lib-experimental/bus/<plat>/` | Per-platform transport + port I/O (add `bus/isa/`) |
| `fujinet-lib-experimental/common/` | Shared `network`, `json`, `fuji` code |
| `fujinet-config/src/<plat>/` | Host loader + CONFIG screens (add `src/isa/`) |

"Add …" marks the artifacts a new ISA platform creates; everything else is reused.

## Appendix E — Glossary

- **AEN** — Address Enable. High during ISA DMA; an I/O card must decode only when it is low.
- **Byte pipe** — the four I/O registers (`GETC`, `STATUS`, `PUTC`, `CONTROL`) through which the host streams bytes to/from the RP2350.
- **DBC** — device ID `0xFF`, the bus controller (RP2350) itself; DBC packets are consumed locally for ROM bank-switching.
- **FEP-004** — the FujiNet protocol proposal that FujiBus implements.
- **FujiBus** — the SLIP-framed packet protocol the host and ESP32 exchange.
- **fujiversal** — the RP2350 firmware that emulates the bus interface.
- **Option ROM** — a BIOS-scanned expansion ROM (`0x55 0xAA` header) in `0xC0000`–`0xDFFFF`; FujiNet's boot loader on ISA.
- **PIO** — the RP2350's Programmable I/O — deterministic state machines that implement the bus timing.
- **RAMROM** — the RP2350's swappable emulated-ROM image, bank-switched via DBC commands.
- **Tandem design** — the ESP32 + RP2350 pairing for bus-based platforms.

## Appendix F — Bill of materials (one bring-up rig)

| Qty | Item | Note |
| --- | --- | --- |
| 1 | Waveshare Core2350B (RP2350B) | `U1`; ≥40 usable GPIO |
| 1 | Freenove ESP32-S3-CAM (dual-USB, microSD) | `U2`; may need SD-pin ground mod |
| 1 | Universal-proto-v1 PCB + headers | `fujiversal-pcb-prototype` |
| 1 | ISA adapter PCB | you fabricate (Chapter 6) |
| 1–2 | `74LVC245` (data) + `74LVC` buffers (addr/strobe) | for the buffered adapter |
| 1 | GAL/ATF16V8 (optional) | card-select decode for `wait_sel` |
| — | 0.1 µF + 10 µF decoupling, headers, jumper wire | |
| 1 | USB hub with per-port power | reflash without disturbing the bus |
| 1 | Logic analyzer (≥8 ch, ≥24 MS/s) | `J2`/`J3`/`J4` probing |
| 1 | ISA slot extender or socketed breakout | saves the card-edge gold during bring-up |

---

*FujiNet Platform Bring-Up Guide — Revision 2, June 2026. Built from sources in `fujinet-bringup`, `fujiversal`, `fujiversal-pcb-prototype`, `fujinet-firmware`, `fujinet-lib-experimental`, and `fujinet-config`. The network is as easy as the disk drive — once the bus says so.*
