# Errata

Corrections folded into `manual.typ` and `wiki/Platform-Bring-Up-Guide.md`.

## Rev. 3 → Rev. 4 — factual + spelling corrections (Chris Osborn / FozzTexx, June 2026)

Seven fixes from Chris's third pass:

1. **`iotest` platform count.** It does *not* have working `portio` for ~a dozen
   platforms. Working examples are **CoCo, MS-DOS, and MSX**; **H89 is in
   progress**; there are no others (build makefiles exist for more, but without
   working `portio`). Corrected everywhere the inflated list appeared.
2. **American spelling.** Converted all British spellings (labour→labor,
   favour→favor, customise→customize, recognise→recognize, judgement→judgment,
   programme→program, synthesise→synthesize, organise→organize, behaviour→behavior,
   internalise→internalize, generalise→generalize).
3. **"Fast and unforgiving" was about the wrong thing.** Bus timing, not CPU
   MHz: a **1 MHz 6809 (CoCo) is tighter than a 4 MHz Z80**, and keeping up with
   the CoCo bus required running the **RP2350 at double clock (250 MHz)**. Ch1
   rewritten to say this.
4. **The RP2350 does NOT do SLIP.** SLIP packet generation/decoding happens at
   the *endpoints* — the host 8-bit's client library and the ESP32 — not the pico,
   which is a transparent byte relay. Ch8 "Two cores" + "USB transport" corrected;
   the stale DBC-frame-sniffing code listing removed.
5. **ROM activation is via the `IO_CONTROL` register**, not a `FUJICMD_CLOSE`
   packet (no longer true). Ch8 "Switching the emulated ROM" rewritten; the
   `case IO_CONTROL` now shows `rom_activate(...)`; DBC/RAMROM glossary + device
   notes de-claimed accordingly.
6. **CoCo `read` side-set/`pindirs` is a PicoROM leftover.** The direction-
   switching in `coco_proto_260402.pio` is vestigial from PicoROM (which has a
   `74LVC245`); the proto cart has no `245` and the RP2350 drives the bus
   directly. Ch9 no longer presents it as the model — added a Caution to strike
   those lines when reading the CoCo file.
7. **Flashing is `make upload`** (picotool, over USB, no buttons). The
   BOOTSEL-button mass-storage drag is only the *recovery* path for a bricked
   board. Ch10 corrected.

## Rev. 2 → Rev. 3 — reframe from ISA recipe to design reasoning (Chris Osborn / FozzTexx, June 2026)

Chris's second review reframed the document's whole approach. The guide had
become "here's how to do ISA," a recipe; it should teach *reasoning* on the
prototype board through real examples. Changes:

1. **The decisions, corrected (§1).** Removed the "three ways / copy an existing
   bus" framing — that is the wrong question. There are **two** decisions:
   (1) connect through an existing *disk interface* or not — if not, the protocol
   is **FEP-004**; if so, it *could* be FEP-004 inside the disk protocol, but only
   if that makes sense, which requires understanding the disk protocol. (2) ESP32
   vs RP2350 (already covered). Over it all: **look like a normal boot device**
   (bare-metal boot, no other peripherals, nothing pre-installed) for the best UX.
2. **Honest identity.** This is a guide to *using the prototype board*, taught
   through design rationale and examples — not a generic bring-up cookbook. Title,
   subtitle, and intro now say so.
3. **The board chapter leads with *why*, not "cut the jumpers."** New Chapter 4
   explains why the board exists, why the header is ISA-shaped (a generic 62-pin
   connector, *not* "ISA is the reference"), and frames the jumper farm as a
   per-signal *routing decision* — not a ritual of cutting everything. The
   breakout headers are also presented as *patch points* for adding connections.
4. **Real worked examples replace the ISA recipe (Chapters 5–6).** Pivoted to
   **MSX** (the board fits cleanly — Z80 strobes land on the default pins,
   AB-header cartridge boot) and **CoCo** (the board does *not* have enough signals
   connected — two phase clocks plus `/CART`/`/SLENB`/etc.; closed four ways:
   breakout jumpers / solder front / solder back / wire-wrap; the cartridge-vs-
   DriveWire choice is the boot-device UX decision in action). Chapter 9 now
   teaches the PIO *decisions* from the real `msx_proto`/`coco_proto` files.
5. **ISA demoted to a design exercise (Chapter 19).** ISA — the user's original
   ask — is kept only as a clearly-marked *illustrative, unbuilt* exercise that
   applies the method to a bus with no board file. The rest of the firmware/PIO
   chapters are de-ISA'd (generic `<platform>` placeholders).


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
   drop into `fujinet-lib-experimental`. `iotest` ships working `portio` examples
   for CoCo, MS-DOS, and MSX (H89 in progress) to crib from. (The "~14 platforms"
   figure in the original Rev. 2 text was wrong — corrected in Rev. 4 above.)

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
