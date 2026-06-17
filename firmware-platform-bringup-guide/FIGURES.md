# Photo / capture shot list

The guide is complete with native Typst diagrams and needs no photography to be
usable. These optional real-hardware shots would strengthen the hardware
chapters (Part II) and the bring-up chapters (Part III). All are "nice to have,"
not blockers.

Drop files in `images/` and wire them into `manual.typ` where a placeholder note
points (search for "Figure" callouts in Chapters 5–7 and 10). Strip EXIF/GPS
before committing: `jpegtran -copy none in.jpg > out.jpg`.

## Hardware (Part II)

1. **proto-board-top.jpg** — `Universal-proto-v1` populated with the Core2350B
   (`U1`) and ESP32-S3-CAM (`U2`) seated, looking straight down. Annotate `J1`
   (bus header), `J2`/`J3`/`J4` breakouts, the `JP*` jumper farm, `J9` power.
2. **jumper-farm.jpg** — macro of a few `JP1`–`JP36` solder jumpers, one bridged
   and one cut, to show the isolation technique.
3. **isa-adapter.jpg** — the fabricated ISA adapter (card-edge gold fingers on
   one side, `Bus_ISA_8bit` connector on the other). If buffered, show the
   `74LVC245`s.
4. **isa-adapter-installed.jpg** — adapter mated to the universal board, card in
   an ISA slot or slot extender.
5. **microsd-mod.jpg** — the Freenove ESP32-S3-CAM SD-pin-to-ground solder bridge
   (the `<insert details…>` item from the prototype README), once confirmed.
6. **bench-rig.jpg** — the full bench setup: both dev boards on USB through a
   powered hub, logic analyzer on the breakouts. The Part II closing plate.

## Bring-up / debugging (Part III)

7. **la-iocycle.png** — logic-analyzer capture of one ISA I/O read cycle:
   `/IOR` falling with `AEN` low, the address on `A0–A9`, and the RP2350 driving
   `D0–D7`. The single most useful figure in the whole guide.
8. **la-romfetch.png** — a `/MEMR` fetch from the option-ROM window `0xC8000`.
9. **la-aen-reject.png** — a DMA cycle (`AEN` high) where the card correctly does
   **not** respond — proof the `AEN` gate works.
10. **config-onscreen.jpg** — CONFIG drawn on the host's screen once milestone 6
    is reached (the payoff shot).

## Notes for verification (flag anything that turns out wrong)

- The exact `JP37`–`JP39` (open) jumper functions were not fully traced from the
  KiCad netlist; the guide describes them as "optional configuration straps."
  Confirm their nets against `Universal-proto-v1.kicad_sch` and tighten the text
  if they have specific roles.
- The ISA I/O window (`0x300`–`0x303`) and option-ROM base (`0xC8000`) are
  recommended/illustrative choices, not yet fixed in firmware — adjust if the
  team standardises on different addresses.
- The `boards/isa_proto.pio` listings are a design starting point, not a
  silicon-proven build (no ISA board file exists in `fujiversal` yet). Update
  once a real ISA PIO is brought up.
