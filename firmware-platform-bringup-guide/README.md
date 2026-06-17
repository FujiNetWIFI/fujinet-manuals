# FujiNet Platform Bring-Up Guide

A developer / engineering manual for **adding new platform support to FujiNet**
using the ESP32 + RP2350 *bus-interface tandem* design. The **8-bit PC ISA bus**
is the worked example, end to end: bus adapter → jumper/test-point config →
RP2350 PIO → ESP32 device firmware → host ROM → client library.

Two formats, same content:

| Format | File |
| --- | --- |
| Print PDF (Typst) | `fujinet-platform-bringup-guide.pdf` |
| GitHub wiki (Markdown) | `wiki/Platform-Bring-Up-Guide.md` |

## Building the PDF

Requires [Typst](https://typst.app/) 0.13+ (tested with 0.14.2).

```sh
make            # -> fujinet-platform-bringup-guide.pdf
make watch      # live recompile
make preview    # PNG of every page in preview/
make clean
```

Fonts are vendored in `fonts/` (Nimbus Sans for heads, Nimbus Roman for body,
Source Code Pro for listings — all from gsfonts / Adobe Source) and supplied to
Typst with `--font-path fonts`, so the build is self-contained. `pdffonts` on the
output shows only those three families — no fallback interlopers.

## Source-verified

Unlike a tutorial written from memory, every register value, pin assignment,
packet field, jumper, and source excerpt was transcribed from the live project
sources in the workspace:

- **fujiversal** — RP2350 bus-interface firmware (PIO state machines, USB-CDC
  bridge, ROM emulation, the `BusSignals` union, the DBC bank-switch path).
- **fujiversal-pcb-prototype** — the `Universal-proto-v1` board (GPIO↔ISA map,
  `JP1`–`JP39` solder jumpers, `J1`–`J9` connectors, `U1`/`U2` modules), and the
  `CoCo-adapter` / `MSX-adapter` / ISA edge footprints.
- **fujinet-lib-experimental** — the host client (`fuji_bus_call`, the
  `FUJICALL_*` / `FUJI_FIELD_*` macros, the per-platform `bus/<plat>/portio`
  pattern).
- **fujinet-firmware** — the ESP32 device firmware (`lib/bus/rs232` =
  FujiBus/FEP-004 transport, `lib/device`, `lib/media`, the
  `platformio-fujiversal-*.ini` build targets).
- **fujinet-config** — the host-side ROM / CONFIG image served by the RP2350.
- **[FEP-004](https://github.com/FujiNetWIFI/fujinet-firmware/wiki/FEP-004)** —
  the serial-encapsulation proposal that FujiBus implements.

Where the prototype is deliberately incomplete or electrically risky (e.g. the
direct, unbuffered 5 V↔3.3 V connection — the `MagicSmoke.svg` case), the guide
says so plainly and shows the production fix.

## Structure

- **Part I — Orientation:** the three bring-up strategies, the tandem
  architecture, and the FujiBus (FEP-004) protocol.
- **Part II — Hardware bring-up:** an ISA primer, the prototype board anatomy,
  building the ISA adapter (level-shifting), and the power-on checklist.
- **Part III — The RP2350 bus interface:** the `fujiversal` firmware internals
  and a worked `boards/isa_proto.pio`.
- **Part IV — The ESP32 device firmware:** reusing the `rs232`/FujiBus transport,
  the build target + pin map, device & media classes, the host ROM, and the
  client library backend.
- **Part V — Integration & validation:** the milestone ladder, a troubleshooting
  matrix, and how to generalise to a non-ISA bus.
- **Appendices:** FujiBus reference, ISA 62-pin pinout, jumper/test-point
  reference, repository map, glossary, BOM.

## Photos

The diagrams (architecture, packet layout, layer stack, pinouts) are rendered
natively in Typst, so the guide is complete without photography. A handful of
real-hardware photos and logic-analyzer captures would strengthen the hardware
chapters; the shot list is in `FIGURES.md`.
