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
- [Part II — The Prototype Board, by Example](#part-ii--the-prototype-board-by-example)
  - [4. The prototype board, and how to think about it](#4-the-prototype-board-and-how-to-think-about-it)
  - [5. MSX: when the board fits](#5-msx-when-the-board-fits)
  - [6. The Color Computer: when the board is not enough](#6-the-color-computer-when-the-board-is-not-enough)
  - [7. Hardware decisions you will face](#7-hardware-decisions-you-will-face)
- [Part III — The RP2350 bus interface](#part-iii--the-rp2350-bus-interface)
  - [8. Inside the fujiversal firmware](#8-inside-the-fujiversal-firmware)
  - [9. Writing the PIO for your bus](#9-writing-the-pio-for-your-bus)
  - [10. Bringing the RP2350 up](#10-bringing-the-rp2350-up)
- [Part IV — The ESP32 device firmware](#part-iv--the-esp32-device-firmware)
  - [11. Where a bus platform fits in fujinet-firmware](#11-where-a-bus-platform-fits-in-fujinet-firmware)
  - [12. Adding the platform to the build system](#12-adding-the-platform-to-the-build-system)
  - [13. Device classes](#13-device-classes)
  - [14. Media classes](#14-media-classes)
  - [15. The host ROM and CONFIG](#15-the-host-rom-and-config)
  - [16. The client library](#16-the-client-library)
- [Part V — Integration & validation](#part-v--integration--validation)
  - [17. The bring-up milestone ladder](#17-the-bring-up-milestone-ladder)
  - [18. Troubleshooting](#18-troubleshooting)
  - [19. Design exercise: a bus nobody has built yet](#19-design-exercise-a-bus-nobody-has-built-yet)
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

> **Important** — Note the 5 V point, because it corrects a natural assumption (and an error in this guide's first edition): the RP2350's direct connection to a 5 V bus is *intentional and supported*, not a hazard to be buffered away. Level shifting in this design is an **ESP32** concern, not an RP2350 one. See [Chapter 7](#7-hardware-decisions-you-will-face).

### The two decisions

Resist the urge to frame a bring-up as "which existing bus do I copy?" That is the wrong question and it leads to brittle designs. There are really only **two** decisions about how FujiNet talks to a machine, sitting underneath one overriding goal.

**The goal: look like a boot device.** The best user experience asks the least of the user — power on, and FujiNet is simply *there*. No second peripheral to own, no driver to side-load first, no disk to boot from something else. So wherever the machine allows it, FujiNet should **look like a normal boot device** and come up from bare metal. Hold this goal in mind; it decides close calls.

**Decision 1 — do you connect through an existing disk interface, or not?**

- **No (the common case):** FujiNet speaks **FEP-004** ([Chapter 3](#3-the-fujibus-protocol-fep-004)) directly, over whatever transport the machine offers — a serial port, or a microcontroller you place on the parallel expansion bus. Cartridge ports and card slots fall here, and this is the path the rest of the guide builds.
- **Yes:** Some machines already have a peripheral *disk* interface with a documented protocol — Atari's SIO, the Tandy CoCo's DriveWire. FujiNet can ride it by presenting as a drive, and the wire protocol could even be *FEP-004 carried inside* the disk protocol. But "could" is not "should": whether it makes sense depends entirely on the disk protocol, and you cannot judge that without understanding it first. Studying that protocol **is** the job in this case.

**Decision 2 — which microcontroller sits on the bus** — is the electrical question from the previous section: count your signal lines (ESP32 for few, RP2350 for many), and remember the RP2350 takes 5 V directly.

> **Note** — The two decisions are independent, and the UX goal often breaks the tie. Riding a disk interface can be less work, but it frequently costs the bare-metal-boot experience: the user may have to own a disk controller or load its software before FujiNet appears. A cartridge or card slot lets FujiNet present a boot ROM and come up on its own. When in doubt, favour the path that boots from bare metal.

When the answer to Decision 1 is "no disk interface" and the transport is a parallel expansion bus, you cannot simply hang the ESP32 on that bus: parallel CPU buses are **fast and unforgiving**. A Z80 or an 8088 expects valid data within tens of nanoseconds of asserting a read strobe; an ESP32 running FreeRTOS and a WiFi stack cannot meet that deadline. An RP2350 can — its Programmable I/O (PIO) blocks are deterministic state machines that react in single clock cycles, and a whole core can be dedicated to the bus. That is why a wide parallel-bus platform uses the two-chip design, and why this guide — and the prototype board it is built around — exists.

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

Active-low signals are written `/IOR`. Hexadecimal is `0x1234`; an I/O *port* is also `0x300`. GPIO numbers are `GP17`. Callouts use levels: **Note** (background), **Tip** (shortcut), **Important** (must get right), **Caution** (electrical/UX hazard).

## 2. System architecture

### The physical stack

A bring-up rig is three boards plus an adapter:

| Board | Role | Repo reference |
| --- | --- | --- |
| **Waveshare Core2350B** | RP2350B (component `U1`); ~48 GPIO, enough for a 20-bit address bus + data + control | `FujiNet:WaveShare-Core-RP2350B` |
| **Freenove ESP32-S3-CAM** | ESP32 + WiFi + microSD (component `U2`) | `FujiNet:ESP32-S3-CAM` |
| **Universal prototype board** | Seats both dev boards; routes every GPIO to a generic bus header through solder jumpers | `fujiversal-pcb-prototype/Bus-proto` |
| **Bus adapter** | Converts the universal bus header into the machine's physical connector | `CoCo-adapter`, `MSX-adapter`, (or yours) |

> **Note** — The Freenove board may need a hardware tweak before its microSD works: one SD pin must be grounded by a solder bridge. The prototype README flags this; confirm against your board revision before assembly.

### Why the inter-board bus is shaped like an ISA slot

The prototype board's generic bus header uses the footprint of an 8-bit ISA edge connector (`Connector:Bus_ISA_8bit`) — a **practical choice of a cheap, available 62-pin connector** whose signal set is a superset of most 8-bit buses, *not* a sign that ISA is the reference platform. Each per-machine adapter (`MSX-adapter`, `CoCo-adapter`) carries a matching `Bus_ISA_8bit` on the board side and the real machine connector on the other.

The board's **default** GPIO routing follows the ISA pin roles, but that is a starting assignment you customise per bus, not a fixed pinout — Chapter 4 is the full design rationale, and Chapters 5–6 show it bent to fit MSX and CoCo.

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

# Part II — The Prototype Board, by Example

What the prototype board is, why it is built the way it is, and how to bend it to a new bus — taught through two real bring-ups: **MSX**, where the board fits cleanly, and the **Color Computer**, where it does not and has to be coaxed.

## 4. The prototype board, and how to think about it

Before any platform, understand the board every platform is brought up on: `fujiversal-pcb-prototype/Bus-proto` (`Universal-proto-v1`). It is not an ISA card, not a cartridge — it is a *development fixture* designed so you can try any bus without spinning a new PCB each time.

### Why the board exists

It does four things and nothing more:

1. **Seats the two dev boards** — the Waveshare Core2350B (`U1`, RP2350) and the Freenove ESP32-S3-CAM (`U2`) — and wires the USB link between them.
2. **Distributes power** with a selectable source (`J9`) and reverse protection (`D1`).
3. **Routes every RP2350 GPIO** to a generic, bus-shaped header (`J1`) through a field of solder jumpers, so you choose what reaches the bus.
4. **Brings every signal out to 0.1″ breakout headers** (`J2` bus side, `J3`/`J4` GPIO side) so you can probe — or patch — anything.

There are **no buffers, no glue logic, no decode** — those are decisions left to you, because they depend on the bus.

### Why the header is shaped like an ISA slot

The generic bus header `J1` has the footprint of an 8-bit ISA edge connector. This is a **practical convenience, not a statement that the board is an ISA card**: an 8-bit ISA edge is a cheap, available 62-pin connector with a sane pitch, and its signal set is a comfortable *superset* of most 8-bit buses. The per-machine adapters carry a matching `Bus_ISA_8bit` on one side and the real machine connector on the other.

> **Important** — Do not read the ISA-shaped header as "ISA is the reference platform." It is a generic interconnect that happens to use an ISA footprint. The worked examples are MSX and CoCo precisely to keep that distinction honest.

### The default GPIO routing

Because the header is ISA-shaped, the board's **default** jumper routing maps each GPIO to the ISA pin of the same role. Treat this as a starting assignment, not a fixed pinout:

| GP | default | GP | default | GP | default |
| --- | --- | --- | --- | --- | --- |
| `GP0`–`GP7` | `A0`–`A7` | `GP8`–`GP15` | `A8`–`A15` | `GP16`–`GP19` | `A16`–`A19` |
| `GP20`–`GP27` | `D0`–`D7` | `GP28` | strobe 1 | `GP29` | strobe 2 |
| `GP30` | strobe 3 | `GP31` | strobe 4 | `GP32` | select / `AEN` |
| `GP33` | clock | `GP34` | latch / `ALE` | `GP35` | reset |

`GP36`–`GP47` are unassigned spares on the breakout headers. The four "strobe" pins are wired to ISA's `/MEMR`/`/MEMW`/`/IOR`/`/IOW` by default; a different bus repurposes them (the MSX example does exactly that).

### The jumper farm is a routing decision, not a checklist

Thirty-nine solder jumpers sit between the GPIO map and the header. **This is the board's customisation mechanism, and it is the part people misuse.** The jumpers are not a ritual — you do *not* "cut them all and bridge them back." You make a **per-signal routing decision**:

| Jumpers | Default | What deciding means |
| --- | --- | --- |
| `JP1`–`JP36` | bridged | Each connects one GPIO to its default header pin. *Leave bridged* the signals your bus uses in their default role; *cut* the ones it does not, to free that GPIO or header pin. |
| `JP37`–`JP39` | open | Optional straps for alternate routing. *Bridge* one only when a specific need calls for it. |

The design question to ask from the start: *which of my bus's signals fall on the default GPIO, which do not, and how will I bring the strays in?* MSX and CoCo are the two answers — "almost all of them do" and "several of them don't."

### The breakout headers are also patch points

`J2` and `J3`/`J4` are the obvious logic-analyzer taps, and you will live on them during bring-up. But they have a second job: they are how you **add** a connection the board does not route by default. If your bus needs a signal on a GPIO the default map never wired to the header, you do not respin the board — you run a jumper wire from the GPIO breakout to where it needs to go. The CoCo example turns on exactly this.

### Customising the board for your bus

A sequence of decisions, not a procedure:

1. **Enumerate the bus signals** the interface must see (address, data, selects, strobes, clocks, reset — and any oddities).
2. **Match them to the default routing.** Which land where they already are? Which need a jumper cut and re-bridged elsewhere? Which are not on the header at all and must be patched from a breakout?
3. **Decide the byte-pipe and ROM addresses** — where can the host reach four registers, and is there a window to present a boot ROM in?
4. **Decide voltage and power** — almost always "nothing to do" on an RP2350.

## 5. MSX: when the board fits

The MSX bring-up is the easy case, and the right one to study first, because the prototype board's default routing nearly matches the machine.

### The decisions

- **Disk interface? No.** The MSX has cartridge and expansion slots but no standard peripheral *disk* protocol to ride, so FujiNet speaks **FEP-004** directly (Decision 1).
- **Look like a boot device? Yes, and MSX makes it easy.** An MSX cartridge whose ROM begins with the signature bytes `0x41 0x42` ("AB") at `0x4000` is found by the BIOS at power-on, which calls the cartridge's `INIT` entry. So FujiNet presents a ROM with that header and *is* a normal, auto-starting cartridge — bare-metal boot, nothing pre-installed.
- **Which microcontroller?** The cartridge bus is wide, so RP2350, which also takes the 5 V bus directly.

### Mapping MSX onto the board

The MSX cartridge is a Z80 bus. The board's default routing absorbs it almost untouched — and where it does not match exactly, the four "strobe" jumpers are simply *repurposed* rather than rerouted:

| MSX signal | GPIO | Note |
| --- | --- | --- |
| `A0`–`A15` | `GP0`–`GP15` | Default address routing, unchanged. |
| `D0`–`D7` | `GP20`–`GP27` | Default data routing, unchanged. |
| `/RD`, `/WR`, `/IORQ`, `/MERQ` | `GP28`–`GP31` | The four default "strobe" pins, *repurposed* from ISA's `/MEMR`/`/MEMW`/`/IOR`/`/IOW` to the Z80's four control lines. No rewiring — just a different meaning in the PIO. |
| `/SLTSL` | `GP32` | The default select pin (ISA's `AEN`), now the cartridge slot-select. |
| `CLOCK` | `GP33` | The default clock pin. |
| `RESET` | `GP35` | The default reset pin. |

From `boards/msx_proto_260402.pio`. Nothing is cut or patched; the only adaptation is in firmware (what the PIO calls each pin), not in copper. *That* is what "the board fits" means.

### The byte pipe and the boot ROM

MSX memory-maps the byte pipe. The four registers live at `0xBFFC`–`0xBFFF` (a free spot high in the cartridge's page-2 window), and the boot ROM occupies `0x4000`–`0xBFFF`:

```text
IO_BASE      0xBFFC      ; GETC=+0  STATUS=+1  PUTC=+2  CONTROL=+3
IO_FLAG_AVAIL 0x80       ; STATUS bit 7 set when a byte is waiting
BUS_ROM_BASE 0x4000      ; the cartridge ROM window (AB header lives here)
```

> **Note** — `0xBFFC` is not arbitrary: the `fujinet-bringup` `iotest` MSX `portio` reads and writes the *same* `0xBFFC` byte pipe (`IO_OFFSET = 0x8000 + 0x3FFC`). The relay MVP and the production board expose the identical four registers at the identical address.

The `MSX-adapter` is mostly straight wiring, and the RP2350 meets the 5 V bus directly. There is little to *decide* here — which is exactly why MSX is the example to cut your teeth on.

## 6. The Color Computer: when the board is not enough

The CoCo bring-up is the instructive case, because the prototype board, as designed, **does not have enough of the right signals connected** for it. A UX judgement call, a hardware shortfall, and four different ways to fix it all show up here.

### The decision that sets the tone: cartridge, not DriveWire

The CoCo *does* have a disk interface FujiNet could ride: **DriveWire**, a serial disk protocol, which is how FujiNet's existing CoCo support works. So Decision 1 has a real "yes" available. Why does the prototype-board bring-up choose the cartridge port instead?

**Because of the boot-device goal.** Riding DriveWire means the user must have Disk BASIC and a DriveWire setup in place before FujiNet appears — a peripheral and pre-installed software, exactly what the UX goal says to avoid. The cartridge port **autostarts a Program Pak**: on power-up the Color BASIC ROM hands control to a cartridge at `0xC000`, so a FujiNet cartridge comes up from bare metal with nothing installed. The worse-effort path wins because it is the better experience.

### Where the board comes up short

The 6809 cartridge edge brings signals the ISA-shaped default routing never anticipated: *two* phase clocks (`E` and `Q`, where ISA has one), plus cartridge control lines — `/CART`, `/SLENB`, `/HALT`, `/NMI`, `SND` — with no analogue in the default map at all. The board simply does not route all of them to where the `CoCo-adapter` can reach them. Put plainly: **as built, the proto board does not have enough signals connected for CoCo.** That is not a defect; it is the expected outcome of a generic fixture meeting a specific machine.

### Four ways to add the missing connections

None of these is "correct"; they trade reworkability against permanence against effort:

| Approach | What it is | Best when |
| --- | --- | --- |
| **Breakout jumpers** | Run a jumper wire from a `J3`/`J4` GPIO breakout pin to where the signal must go. *This is how the team manages CoCo today.* | You are still iterating; you want to move it tomorrow |
| **Solder front** | Omit those breakout headers and solder a wire directly between the two pads. | The routing is settled and you want it low-profile |
| **Solder back** | Run the wire on the back of the board. | The front is crowded; clearance matters |
| **Wire-wrap** | Fit long wire-wrap posts and wire-wrap the connections. | Many signals to patch; you value reworkable-but-robust |

The point of listing them is not to pick a winner — it is to show that "the board doesn't have the signal" is a solvable problem with a spectrum of answers, and which you choose is a judgement about your build, not a rule.

### The fingerprints of a tight fit

When the board does not match the machine, the firmware shows it. Two artefacts in `boards/coco_proto_260402.pio`:

1. **Relocated pins.** The file still carries the original assignment as a comment — `CTS=16`, `SCS=17`, `CLOCK=18` — above the assignment actually used — `CTS=32`, `SCS=30`, `CLOCK=33`. The signals were moved to whatever GPIO could be reached after patching.
2. **A defensive pull-up.** One unused middle pin (`GP31`) is pulled up in firmware "to avoid a false zero" on the bus. A stray or repurposed line often needs a small defensive measure; budget for one or two.

### The byte pipe and the boot ROM

```text
IO_BASE      0xFF41     ; STATUS=+0  GETC=+1  CONTROL=+2  PUTC=+3  (note order)
IO_FLAG_AVAIL 0x02      ; STATUS bit set when a byte is waiting
BUS_ROM_BASE 0xC000     ; the /CTS cartridge ROM window (autostart vector here)
```

The register order and available-bit position *differ from MSX* — chosen to fall on convenient bits and addresses for the 6809 code. That is fine: the byte pipe is a contract about four registers, not their exact offsets. Timing references the `E` clock and `R/W` (a 6809 has no separate read/write strobes), the other reason the CoCo PIO looks different from the MSX one.

## 7. Hardware decisions you will face

### Voltage: usually nothing to do

On an RP2350 board this is the shortest decision in the guide: the RP2350 interfaces to a 5 V bus **directly** ([Chapter 1](#choosing-the-interface-esp32-or-rp2350)), so there is no level shifter and no "5 V problem." Both worked examples connect straight to the 5 V cartridge bus.

A translator becomes **mandatory** only on the narrow-bus **ESP32** path, which is not 5 V tolerant — the `fujinet-bringup` H89 example drives a `74LVC245` from the ESP32 via `OE`/`DIR` for exactly this reason. On an RP2350 you would add buffering only for *signal integrity* on a long or heavily-loaded bus, never for protection.

### The adapter, from patched header to PCB

"Adapter" is a spectrum, not a deliverable you need up front:

| Stage | What the adapter is |
| --- | --- |
| Bench bring-up | Jumper wires from the breakout headers to the machine's connector. No PCB at all. |
| Settling | A scrap of perfboard, or wire-wrap, fixing the routing you proved on the bench. |
| Reproducible | A small PCB — machine edge on one side, `Bus_ISA_8bit` on the other — like the `MSX-adapter` and `CoCo-adapter`. |

### Power

Bring `+5V` and `GND` from the machine to the board's power header through `J9` (source select); `D1` blocks back-feed. The Freenove ESP32 module may need its microSD pin grounded by a solder bridge before SD works — confirm against your revision.

> **Caution** — Decide the power source *before* connecting to a live machine. During bench bring-up, power from USB and leave the machine's `+5V` disconnected so you never tie two supplies together. Switch to bus power only once the interface is otherwise proven.

### First power-on, in groups

Bring a board up in layers so a fault is contained — and note what this is *not*: it is not "cut every jumper first." For a clean-fit bus (MSX) you change no jumpers; for a tight-fit bus (CoCo) you first make your deliberate routing changes, then stage the bring-up. Either way the staging is about **observability**:

1. **RP2350 alone**, on USB, no bus: confirm it enumerates as a USB CDC device. Nothing should warm up.
2. **ESP32 alone**: flash it, confirm WiFi and SD.
3. **Bus, address + select**, watched at the breakouts: confirm the PIO sees the machine address the interface, and only when it should.
4. **Bus, strobes + data**: run the loopback of [Chapter 10](#10-bringing-the-rp2350-up).
5. **In the machine**: only now move from the bench to a real slot and switch `J9` to bus power.

> **Tip** — Keep a powered USB hub with per-port power between your workstation and both dev boards. You will reflash each many times; per-port power lets you cycle one without disturbing the other or the bus.

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

The four registers are the two ends of the multicore FIFO dressed up as bus-visible ports. `IO_BASE`, the register offsets, `IO_FLAG_AVAIL`, `BUS_ROM_BASE`/`BUS_ROM_TOP` are all `.define`s in the board's `.pio` file — re-pointing the byte pipe at your bus's address map is mostly changing those constants.

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

`process_command()` implements `FUJICMD_OPEN` (select a RAM bank), `FUJICMD_WRITE` (fill it), `FUJICMD_CLOSE` (activate it), `FUJICMD_RESET` (revert). Your build needs no change here.

## 9. Writing the PIO for your bus

The PIO is where a bus's specifics live. Chapter 8 described the three state machines in the abstract; the differences between the **real** MSX and CoCo `.pio` files *are* the design decisions you will face.

| Decision | MSX (`msx_proto_260402.pio`) | CoCo (`coco_proto_260402.pio`) |
| --- | --- | --- |
| What "selected" means | `/SLTSL` low — a ready-made slot-select line | `/CTS` or `/SCS` low — two selects you decode |
| Timing reference | none needed; the select line frames the cycle | the 6809 `E` clock edges |
| Read vs write | `/RD` / `/WR` (separate Z80 strobes) | a single `R/W` level |
| Data-direction flip | tri-state when the FIFO empties or `/SLTSL` releases | flip `pindirs` with side-set around `E` |
| Byte pipe | memory-mapped, `0xBFFC` | `0xFF41` in the `/SCS` I/O spot |
| ROM window | `0x4000` (AB-header cartridge) | `0xC000` (autostart Program Pak) |

### Pin defines and the BusSignals union

Every board file opens with pin `.define`s that must match how the board is actually routed (Chapters 4–6) and a `BusSignals` union whose bit layout *is* that routing. Derive them from your routing table, not from another bus's file.

```c
// MSX BusSignals (16-bit address, separate Z80 strobes)
typedef union {
  struct {
    uint32_t addr:16;     // A0..A15  GP0..GP15
    uint32_t resv:4;
    uint32_t data:8;      // D0..D7   GP20..GP27
    uint32_t rd:1, wr:1, iorq:1, memrq:1;   // GP28..GP31
  } __attribute__((packed));
  uint32_t combined;
} __attribute__((packed)) BusSignals;
```

### Decode: the `wait_sel` decision

**MSX — a ready-made select line.** The cartridge slot hands the card a single `/SLTSL`, asserted exactly when this slot is addressed. So `wait_sel` is almost nothing:

```text
; MSX wait_sel  (SLTSL pin configured inverted, so "wait 1" = /SLTSL low)
.program wait_sel
.wrap_target
        wait 1 gpio SLTSL_PIN [WAIT_CYCLES]   ; selected
        irq 0
        wait 0 gpio SLTSL_PIN                  ; deselected
.wrap
```

**CoCo — decode it yourself.** The cartridge port has two selects (`/CTS`, `/SCS`) and no single "card selected" line, so the program reads the pins, masks the two select bits, and qualifies on `R/W` and the `E` clock:

```text
; CoCo wait_sel  (decode /CTS or /SCS, then time against E)
idle:
        mov osr, ~pins          ; all pins, inverted
        out x, NUM_PINS         ; grab the /CTS /SCS bits
        jmp !x idle             ; both high -> not us
        jmp pin send            ; R/W high (read)? no need to wait
        wait 1 gpio CLOCK_PIN    ; else wait for E
send:
        irq IRQ_SEL             ; selected
        wait 0 gpio CLOCK_PIN    ; end of this bus cycle
```

The lesson is the decision: *does your bus give you a select line, or must you synthesise one from address-decode and strobes?* If it hands you one (MSX), `wait_sel` is trivial. If not (CoCo, and most backplane buses), you decode — in PIO, or with a little external logic that produces a single select line and reduces the problem to the MSX case.

### Driving data: the `read` decision

`read` puts a byte on `D0–D7` when core 1 supplies one and tri-states the pins otherwise. The decision: *what edge tells you the cycle is ending?* MSX keys off the select line; CoCo keys off the `E` clock, using a side-set bit to flip `pindirs` in lockstep:

```text
; CoCo read  (side-set flips data-pin direction around E)
.program read
.side_set 1 opt
        mov x, ~null  side 1            ; D0-7 start as inputs
.wrap_target
        pull block                      ; byte from core 1
        out pins, DATA_WIDTH
        mov osr, ~null
        out pindirs, DATA_WIDTH side 0  ; drive D0-7
        wait 1 gpio CLOCK_PIN           ; through the E cycle
        wait 0 gpio CLOCK_PIN
        mov osr, null
        out pindirs, DATA_WIDTH side 1  ; release D0-7
.wrap
```

Identify your timing reference first and the `read` program writes itself. `send_bus` carries no per-bus decision — it samples GPIO and autopushes — so it is copied unchanged between board files.

### Building the board into fujiversal

```cmake
# CMakeLists.txt — RP2350 board set
if(BOARD STREQUAL "msx_proto_260402"
   OR BOARD STREQUAL "coco_proto_260402"
   OR BOARD STREQUAL "<your_board>")              # <-- new
    set(PICO_BOARD  "pimoroni_pga2350" CACHE STRING "" FORCE)
    set(PICO_PLATFORM "rp2350-arm-s"   CACHE STRING "" FORCE)
    set(PICO_CHIP   "rp2350"           CACHE STRING "" FORCE)
endif()
```

> **Important** — If your routing uses any GPIO above 31 (as both examples do — selects and reset live up there), the build **must** define `PICO_PIO_USE_GPIO_BASE=1` so the PIO can reach the upper bank. `setup_state_machine()` in `setup_sm.cpp` rejects an illegal span — heed its return codes when a state machine silently fails to start.

### Generating the host ROM

```bash
# 1. build the host loader + CONFIG for your platform (fujinet-config)
make PLATFORM=<platform>          # -> config-<platform>.rom   (Chapter 15)

# 2. build the RP2350 firmware with that ROM
cd ../fujiversal
make ROM_FILE=../fujinet-config/config-<platform>.rom BOARD=<your_board>
# -> build/<your_board>/fujiversal_<your_board>.uf2
```

> **Note** — Applying all of this to a bus that has *no* board file yet — decoding it from scratch, choosing the byte-pipe address, writing the union — is the design exercise in [Chapter 19](#19-design-exercise-a-bus-nobody-has-built-yet), worked through for the 8-bit ISA bus.

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

## 11. Where a bus platform fits in fujinet-firmware

The ESP32 never sees your bus — not MSX, not CoCo, not anything. It sees a CDC-ACM serial port carrying FujiBus packets — exactly what the firmware's `rs232` bus already consumes (the same class used by the real RS-232 FujiNet). The two existing `fujiversal` targets, `fujiversal-rs232` and `fujiversal-drivewire`, prove the pattern.

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

The `FUJINET_OVER_USB` switch is the whole story: built for the RP2350-over-USB path, `_serial` is an `ACMChannel` (USB-CDC *host*). A tandem bus platform uses this, identical to `fujiversal-rs232`.

> **Important** — For a tandem bus-based platform you usually write **no new bus class and no new device classes on the ESP32**. You add a build target and a pin map, and reuse `rs232`. New ESP32 code is needed only when your platform exposes a device the existing set lacks, or a disk image format not already handled. The deep work is the PIO (Part III) and the host side (Chapters 15–16).

## 12. Adding the platform to the build system

### The build platform file

```ini
; build-platforms/platformio-fujiversal-<platform>.ini
[fujinet]
build_bus      = RS232          ; reuse the FujiBus serial bus
build_platform = BUILD_RS232    ; ... and its device/media set

[env:fujiversal-<platform>]
build_type = debug
build_flags =
    ${env.build_flags}
    -D PINMAP_FUJIVERSAL_<PLATFORM>     ; <-- new pin map
    -D CONFIG_USB_HOST_ENABLED=1        ; ESP32-S3 is the USB *host*
    -D CONFIG_USB_CDC_ACM_HOST_ENABLED=1
platform         = espressif32@${fujinet.esp32s3_platform_version}
platform_packages = ${fujinet.esp32s3_platform_packages}
board            = esp32-s3-wroom-1-n16r8
```

Three lines carry the design: `build_bus = RS232` chooses the FujiBus transport; the two `CONFIG_USB_*` flags make the ESP32-S3 a USB host so it can open the RP2350's CDC port; `PINMAP_FUJIVERSAL_<PLATFORM>` selects your board's pins.

### The pin map

On a `fujiversal` board the ESP32 pin map is small — the heavy bus I/O is on the RP2350.

```c
// include/pinmap/fujiversal_<platform>.h   (mirror fujiversal_rs232.h)
#ifdef PINMAP_FUJIVERSAL_<PLATFORM>
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
pio run -e fujiversal-<platform>
pio run -e fujiversal-<platform> -t upload
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

For a stock build you change nothing here — the `rs232` set registers itself.

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

A flat sector image (a `.dsk`/`.img` of a floppy or hard disk) maps directly onto block reads and needs no new class; a structured format would. Start flat.

> **Tip** — `discover_disktype()` dispatches on file extension. When you add a format, register its extension there so mounting `disk.img` from CONFIG picks the right `MediaType` automatically.

## 15. The host ROM and CONFIG

The emulated ROM the RP2350 serves is built by `fujinet-config`. This is code that runs **on the host CPU**, as platform-specific as the PIO.

`fujinet-config` builds, per platform, two things baked into one ROM image:

1. **A loader** — in whatever form the machine autostarts (the boot-device goal): MSX wants a cartridge ROM with the `AB` header at `0x4000`; CoCo wants an autostart Program Pak at `0xC000`; a PC ISA card wants an option ROM (`0x55 0xAA`, length, entry point) the BIOS calls during its expansion-ROM scan. It brings up the byte pipe, asks FujiNet to mount the boot disk, and boots it or launches CONFIG.
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
make PLATFORM=<platform>   # builds loader + CONFIG -> config-<platform>.rom
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
    <platform>/   <-- you add this
  Makefile        PLATFORMS = coco apple2 atari c64 msx msdos adam  (+ yours)
```

`common/` is the bulk of the library and is shared verbatim. Each `bus/<platform>/` provides the same small surface:

| File | Responsibility |
| --- | --- |
| `portio.s` / `portio.h` | `inb`/`outb` to ports `0x300`–`0x303` (8088 `IN`/`OUT`) |
| `fujinet-bus-<platform>.c` | `fuji_bus_call` / `fuji_bus_read` / `fuji_bus_write`: build the FujiBus packet (header, descriptors, AUX, payload, checksum), SLIP-encode, stream out `PUTC`, read the SLIP reply back via `GETC` |

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

A program that opens an `N:` URL never sees FujiBus framing: it calls `network_open()` in `common/`, which calls `fuji_bus_call()`, which calls your `bus/<platform>` primitives, which hit the byte pipe.

```bash
make <platform>     # builds fujinet.lib for your backend
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
| 6 | CONFIG boots | The host runs the boot ROM (cartridge / Program Pak / option ROM), the loader runs, CONFIG draws on screen |
| 7 | Mount + boot a disk | CONFIG mounts a `.img`; the machine boots it |
| 8 | `N:` works | A program opens `N:HTTP://…` and reads data over WiFi |

> **Note** — Milestones 1–3 are exactly the `fujinet-bringup` MVP ([Chapter 1](#start-at-fujinet-bringup)): a minimal byte relay plus `iotest` proving two-way communication, with the FujiNet firmware running as a PC build. They need **no host bus board at all** — you can reach milestone 3 before the bus adapter PCB even arrives. Milestone 5 is the `fujinet-bringup` "Hello World" (fetch the adapter config) succeeding for the first time. Order your work so the slow-to-fabricate adapter is never on the critical path.

## 18. Troubleshooting

| Symptom | Layer | Likely cause and cure |
| --- | --- | --- |
| Machine hangs/crashes the moment the interface is connected | 1 | The decode is too loose — it answers cycles that aren't ours. (On ISA, forgetting to gate I/O on `AEN` low is the classic case.) Tighten `wait_sel`. Or a signal is mis-routed and two drivers fight — check your routing. |
| Interface does nothing; no PIO IRQ | 2 | `wait_sel` decode never matches. Wrong `IO_BASE`, wrong strobe polarity (strobes are usually active-**low**), or a needed signal not routed to its GPIO. Probe `J2` vs `J3`/`J4`. |
| PIO IRQs fire on every bus cycle | 2 | `wait_sel` not pre-qualifying the address window. Add window decode, or feed a decoded select line from adapter logic. |
| Host reads our port, gets `0xFF`/garbage | 2–3 | Data not driven in time, or direction backwards. Check the `read` program's `pindirs` flip timing against the strobe, and the buffer `DIR` term. |
| Bytes go out but no reply | 3–4 | Loopback (M3) first. If loopback is fine, the ESP32 isn't opening the CDC port (`CONFIG_USB_CDC_ACM_HOST_ENABLED`?) or the RP2350 is still in verbose `printf` mode stealing the channel. |
| `fuji_bus_call` returns failure though bytes flow | 4 | Framing bug: checksum (add-with-fold, not XOR), little-endian `length`, or a descriptor/AUX mismatch. Diff your encoder against `FujiBusPacket.cpp`. |
| Host never runs the boot ROM | 5 | ROM not where/what the machine autostarts from — wrong `BUS_ROM_BASE`, or a bad header (MSX `AB`, CoCo autostart bytes, PC option-ROM `0x55 0xAA`). Verify served bytes at the ROM window with the analyzer on the memory-read strobe. |
| CONFIG draws garbage characters | 5 | Host-side rendering — `fujinet-config/src/<platform>/screen.c` wrong charset/addresses. A byte-pipe problem would corrupt *data*, not just glyphs. |
| Intermittent corruption at speed | 1 | Unbuffered 5 V bus ringing, or missing decoupling at the adapter. Add the `74LVC` buffers. |

## 19. Design exercise: a bus nobody has built yet

The two worked examples were real — code you can open in the repository. This closing chapter applies the same method to a bus that has *no* board file, no adapter, and no firmware yet — the 8-bit IBM PC/XT ISA bus — purely as a reasoning exercise.

> **Important** — Everything here is *illustrative and unbuilt*. The addresses, the PIO sketch, and the build names are a worked design, not a proven port. Its value is the reasoning, not the numbers. Verify every choice on a logic analyzer if you ever build it.

### The method: what changes from one bus to the next

Walk this diff for any new bus — ISA below, or a 6502 cartridge port, S-100 backplane, Apple slot — and you have your design. Everything *not* in this table is shared and unchanged.

| What changes per bus | Where you change it |
| --- | --- |
| Disk interface, or not | Decision 1 (Ch. 1): a disk interface to ride, or FEP-004 direct. Favour whatever boots from bare metal. |
| Connector and voltage | The adapter (Ch. 6–7); on an RP2350, voltage is usually nothing to do. |
| Signal-to-GPIO routing | The jumpers and patches (Ch. 4–6): which signals land on the default map, which you reroute, which you wire in from the breakouts. |
| The decode rule | `wait_sel` (Ch. 9): what "selected" means, and the timing reference (clock edge, chip-select, or strobe). |
| Data-direction timing | The `read` program (Ch. 9): which edge flips `pindirs`. |
| Byte-pipe + ROM address | `IO_BASE` / `BUS_ROM_BASE` and the register offsets — wherever the host can reach four registers and present a boot ROM. |
| Host loader + screens | `fujinet-config/src/<platform>/`. |
| Client port I/O | `fujinet-lib` `bus/<platform>/portio.*`. |

FujiBus framing, the ESP32 device/media classes, the `N:` stack, and the byte-pipe model never appear here — they do not change.

### Working the diff for ISA

- **Disk interface? No.** A PC/XT has no peripheral disk-serial bus to ride, so FEP-004 direct. **Boot device? Yes** — the BIOS scans `0xC0000`–`0xDFFFF` for option ROMs marked `0x55 0xAA` + length + entry; present one at `0xC8000` and FujiNet boots from bare metal.
- **The decode rule — and the trap.** ISA gives no ready-made select line, so this is the CoCo-style "decode it yourself" case with one extra hazard: `AEN`. An I/O cycle is *ours* only when "address in our port window AND a command strobe asserted AND `AEN` low". `AEN` is high during DMA; ignore it and the interface answers DMA addresses and crashes the machine. The ROM window is simpler — address in `0xC8000…` AND `/MEMR` — and ignores `AEN`.
- **Signal routing — the one place ISA is easy.** ISA is the bus the default routing was drawn from, so it lands almost untouched: `A0`–`A19`→`GP0`–`GP19`, `D0`–`D7`→`GP20`–`GP27`, the four strobes→`GP28`–`GP31`, `AEN`→`GP32`. Caveat: `send_bus` samples only `GP0`–`GP31`, so gate `AEN` (at `GP32`) inside `wait_sel` rather than reading its level in core 1.
- **Data direction.** No single clock; flip `pindirs` on the active strobe edge.
- **Byte pipe + ROM.** Four I/O ports at `0x300`–`0x303`, option ROM at `0xC8000`.

### What you would build next

If the design survives the bench (milestones 0–5), the artifacts are the familiar five, and *only* these: a `boards/isa_proto.pio`, a `fujiversal` CMake board (+`PICO_PIO_USE_GPIO_BASE=1`), a `platformio-fujiversal-isa.ini` (`build_bus = RS232`), a `fujinet-config/src/isa/` option-ROM loader, and a `fujinet-lib/bus/isa/` with `IN`/`OUT` `portio`. Nothing in the FujiBus, device, media, or `N:` layers changes — the entire payoff of the tandem design.

> **Tip** — The fastest bring-up of any brand-new bus: feed the PIO a single decoded "selected" line from a small GAL on the adapter (so `wait_sel` reduces to the MSX form), put the byte pipe wherever the host can do four `peek`/`poke`s, and reuse `BUILD_RS232` whole — exactly the `fujinet-bringup` philosophy, all the way down.

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
| `J2` | 2×13 header | Bus-side breakout (logic-analyzer tap) |
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
| `fujiversal/boards/*.pio` | Per-board PIO + pin defines + `BusSignals` union (`msx_proto`, `coco_proto`; add yours) |
| `fujiversal/setup_sm.cpp` | Generic PIO state-machine setup helper |
| `fujiversal/FujiBusPacket.*` | FujiBus encoder/decoder (RP2350 copy) |
| `fujiversal/CMakeLists.txt` | Board selection, `PICO_PIO_USE_GPIO_BASE` |
| `fujiversal-pcb-prototype/Bus-proto/` | `Universal-proto-v1` board (jumpers, breakouts) |
| `fujiversal-pcb-prototype/*-adapter/` | The `MSX-adapter` and `CoCo-adapter` (templates for yours) |
| `fujiversal-pcb-prototype/parts.pretty/ISA_8bit*` | ISA edge footprints |
| `fujinet-firmware/build-platforms/platformio-fujiversal-*.ini` | Build targets (`rs232`, `drivewire`; add yours) |
| `fujinet-firmware/lib/bus/rs232/` | FujiBus transport + `systemBus` (reused as-is) |
| `fujinet-firmware/lib/device/rs232/` | Device classes (Fuji, disk, network, printer, …) |
| `fujinet-firmware/lib/media/` | Image formats (`MediaType`) |
| `fujinet-firmware/include/pinmap/` | Pin maps (add `fujiversal_<platform>.h`) |
| `fujinet-lib-experimental/bus/<plat>/` | Per-platform transport + port I/O (add `bus/<platform>/`) |
| `fujinet-lib-experimental/common/` | Shared `network`, `json`, `fuji` code |
| `fujinet-config/src/<plat>/` | Host loader + CONFIG screens (add `src/isa/`) |

"Add …" marks the artifacts a new platform creates; everything else is reused.

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
| 1 | Bus adapter PCB / patched header | you make (Chapter 7) |
| 1–2 | `74LVC245` (data) + `74LVC` buffers (addr/strobe) | for the buffered adapter |
| 1 | GAL/ATF16V8 (optional) | card-select decode for `wait_sel` |
| — | 0.1 µF + 10 µF decoupling, headers, jumper wire | |
| 1 | USB hub with per-port power | reflash without disturbing the bus |
| 1 | Logic analyzer (≥8 ch, ≥24 MS/s) | `J2`/`J3`/`J4` probing |
| 1 | ISA slot extender or socketed breakout | saves the card-edge gold during bring-up |

---

*FujiNet Platform Bring-Up Guide — Revision 3, June 2026. Built from sources in `fujinet-bringup`, `fujiversal`, `fujiversal-pcb-prototype`, `fujinet-firmware`, `fujinet-lib-experimental`, and `fujinet-config`. The network is as easy as the disk drive — once the bus says so.*
