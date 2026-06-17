# FujiNet Platform Bring-Up Guide

A developer / engineering manual for **adding new platform support to FujiNet**
using the ESP32 + RP2350 *bus-interface tandem* design, built around the
project's **prototype board**. It is deliberately not a recipe: it explains why
the board is designed the way it is, then works two real bring-ups — **MSX**
(where the board fits) and the **Tandy Color Computer** (where it does not, and
has to be coaxed) — so you can see the decisions and reason about your own
machine. The chain it covers end to end: the two decisions → prototype-board
design → RP2350 PIO → ESP32 device firmware → host ROM → client library.

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

- **fujinet-bringup** — the canonical *first step* (Chris Osborn / FozzTexx):
  the minimal byte-relay firmware (`esp32/`, `rp2350/`) and the `iotest` host
  two-way-comms test with per-platform `portio` examples. The guide opens by
  sending you here before any custom hardware.
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

Where the prototype is deliberately incomplete or a design has a real hazard,
the guide says so plainly. (Note: per `fujinet-bringup`, the RP2350's direct
connection to a 5 V bus is *supported*, not a hazard — see `errata.md` for the
Rev. 1 correction.)

## Structure

- **Part I — Orientation:** start at `fujinet-bringup`; the two decisions
  (disk-interface-or-not → FEP-004; ESP32 vs RP2350) and the boot-device goal;
  the tandem architecture; the FujiBus (FEP-004) protocol.
- **Part II — The prototype board, by example:** why the board exists and how
  to think about it; **MSX** (the board fits) and the **Color Computer** (the
  board isn't enough — four ways to patch missing signals); the hardware
  decisions (voltage, adapter, power, staged power-on).
- **Part III — The RP2350 bus interface:** the `fujiversal` firmware internals,
  and the PIO *decisions* read from the real `msx_proto` / `coco_proto` files.
- **Part IV — The ESP32 device firmware:** reusing the `rs232`/FujiBus transport,
  the build target + pin map, device & media classes, the host ROM, and the
  client-library backend.
- **Part V — Integration & validation:** the milestone ladder, a troubleshooting
  matrix, and a worked **design exercise** applying the method to a bus nobody
  has built yet (ISA, clearly marked illustrative).
- **Appendices:** FujiBus reference, ISA 62-pin pinout (for the design exercise),
  jumper/test-point reference, repository map, glossary, BOM.

> The reframe from "ISA recipe" to "proto-board design reasoning with MSX/CoCo
> examples" was Chris Osborn's (FozzTexx) review feedback; see `errata.md`.

## Photos

The diagrams (architecture, packet layout, layer stack, pinouts) are rendered
natively in Typst, so the guide is complete without photography. A handful of
real-hardware photos and logic-analyzer captures would strengthen the hardware
chapters; the shot list is in `FIGURES.md`.
