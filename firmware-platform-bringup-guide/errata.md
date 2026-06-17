# Errata

Corrections folded into `manual.typ` and `wiki/Platform-Bring-Up-Guide.md`.

## Rev. 1 → Rev. 2 — incorporate `fujinet-bringup` (Chris Osborn / FozzTexx, June 2026)

Chris pointed out that a platform bring-up should **always start with the
[`fujinet-bringup`](../../fujinet-bringup) repo**, which Rev. 1 omitted — it
jumped straight to the production `fujiversal` ROM-emulation board. The repo is
the canonical first step and changes three things:

1. **Bring-up-first methodology (new §1.2–1.3).** The recommended path is to get
   *two-way byte communication* working first, using a **minimal byte relay**
   (the `esp32/` or `rp2350/` firmware in `fujinet-bringup`) plus the **`iotest`**
   host program, talking to the FujiNet firmware running as the **RS232 PC
   build** — *before* building ROM emulation or an on-board ESP32. The host-side
   `portio` you write for `iotest` (`port_init` / `port_putc` / `port_getc` /
   `port_available`, plus buffered/timeout variants) is the same code you later
   drop into `fujinet-lib-experimental`. `iotest` already ships `portio` examples
   and build makefiles for ~14 platforms (adam, apple2, atari, c64, coco, dragon,
   h89-cpm, msdos, msx, …) to crib from.

2. **ESP32-vs-RP2350 decision (new §1.3).** Count your bus signal lines: **≤ 8
   lines → an ESP32 can be the interface; > 8 lines → use an RP2350.** ISA
   (20 address + 8 data + control) needs the RP2350; the H89 example uses an
   ESP32 with an i8255 PPI.

3. **5 V level-shifting — CORRECTION (§5, §6).** Rev. 1's "Magic Smoke" warning
   claimed the RP2350's direct, unbuffered connection to the 5 V bus was a hazard
   "living on borrowed time." **That was wrong.** Per `fujinet-bringup`, *the
   RP2350 can interface to 5 V signal lines directly without a level shifter* —
   that capability, with its high pin count, is exactly *why* it is the
   recommended interface for wide buses. It is the **ESP32** that is not 5 V
   tolerant and needs a translator (the `fujinet-bringup` H89 example drives a
   `74LVC245` via `OE`/`DIR` from the ESP32). The warning has been corrected; the
   genuine remaining hazard (mixing power sources; putting the ESP32 directly on
   5 V) is retained.

Also added: `fujinet-bringup` to the canonical-sources list and the repository
map; an "iotest two-way comms" rung at the bottom of the milestone ladder; and
the note that the relay byte-pipe and the `fujiversal` 4-register byte pipe
expose the *same* `port_*` contract (MSX `iotest` even uses the same `0xBFFC`).

## Open items still flagged (see FIGURES.md)

- ISA I/O window `0x300–0x303` and option-ROM base `0xC8000` are recommended,
  not yet fixed in firmware.
- `JP37–JP39` exact functions not fully traced from the KiCad netlist.
- `boards/isa_proto.pio` listings are a design starting point, not silicon-proven
  (no ISA `.pio` exists in `fujiversal` yet).
