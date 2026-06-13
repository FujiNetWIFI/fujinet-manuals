# Figure manifest

All artwork in this edition is generated — there are no photo
placeholders. Two kinds of figures:

## 1. Rendered hardware illustrations (`images/`)

Produced by `make images` from `fujinet-hardware/ATARI/FN32ROV-1.7.1/3D/`
via `tools/stl2png.py` (flat-shaded, black contour, transparent PNG).

| File | View | Used on |
|---|---|---|
| fujinet-hero.png | 400/800-style case, front 3/4 (azim 32, elev 16) | cover, "Meet" case-style row |
| fujinet-rear34.png | rear 3/4 (azim 212, elev 20) | intro corner art, "Meet" rear diagram, "Hooking It Up" |
| fujinet-front-flat.png | front elevation (azim 90, elev 4) | "Meet" front diagram, "Lights and Buttons" |
| fujinet-top.png | top-down oblique (azim 90, elev 58), with `tools/buttons.stl` — three generated button caps seated in the top-face holes (the case STLs ship with the holes empty) | "Lights and Buttons" — buttons A/B/C marked |
| fujinet-rear-flat.png | rear elevation (azim 270, elev 4) | (spare) |
| sio-plug.png | SIO plug pin-face 3/4 (azim 60, elev 28) | "Hooking It Up" |
| fujinet-xl.png | XL-style case 3/4 | "Meet" case-style row |
| fujinet-xe.png | XE-style case rear 3/4 | "Meet" case-style row |
| fujinet-logo.png, fujinet-logo-white.png | project wordmark (copied from ../owners_guide) | cover, black page, back cover |

## 2. Drawn CONFIG screens (in `manual.typ` itself)

Typeset in the EightBit Atari ROM font on GR.0 blue; all strings,
key labels and line positions taken from `fujinet-config`
`src/atari/screen.c` (June 2026): network scan, main screen
(HOST LIST / DRIVE SLOTS), file browser (DISK IMAGES), MOUNT TO
DRIVE SLOT, COPY TO HOST SLOT, FUJINET CONFIG info screen.
Host/file names shown (HomeNet, Jumpman.atr, …) are illustrative.

## Worth checking against a production unit

These physical-layout claims were derived from the FN32ROV-1.7.1
3D models, PCB model and schematic — please sanity-check them on a
real device and correct the labels in `manual.typ` if needed:

- [x] Button order confirmed by Thom (June 2026): A closest to the
      edge, B right next to it. NOTE: Thom described C as "in the
      middle", but the repo's 400/800 case model places its third
      hole near the opposite edge (y = +21.7, +11.5, −22.2 mm on the
      case seam) — the figure draws and labels the model's geometry,
      captioned "C on its own". If production cases center C, adjust
      `tools/make_buttons.py` and the marks in `manual.typ`.
- [ ] LED order across the three front holes (hardware carries
      WiFi / BT / SIO LEDs; Bluetooth is disabled in firmware, so the
      manual documents only WiFi and SIO and never names BT).
- [ ] microSD slot side vs. power-switch/USB side (drawn: SD on the
      left edge, switch + USB on the right edge, viewed from the
      front).
