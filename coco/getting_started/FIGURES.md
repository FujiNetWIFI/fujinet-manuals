# Figures — photo shot list

Most illustrations in this manual are rendered from the
`fujinet-hardware` Rev000 case models (`make images`) or typeset
directly from the CONFIG source — no photography needed. Four
photographs remain for Thom. Drop each file into `images/` and flip
its entry to `true` in the `photos` dictionary at the top of
`manual.typ`.

Style notes: these sit in a 1980 Radio Shack manual, which used clean
B&W product photography and line art. Shoot straight, well-lit, plain
background; the placeholders show the layout box each photo fills
(roughly 2:1 landscape).

| File | Shot | Used in |
|------|------|---------|
| `insert-cartridge.jpg` | ✅ **received** — the CocoFuji seated in the cartridge slot, label up | Installation, Fig. 3 |
| `serial-plug.jpg` | ✅ **received** — the DIN-4 plug in the **SERIAL I/O** jack, CASS/JOYSTK labels visible | Installation, Fig. 4 |
| `full-setup.jpg` | The complete outfit: CoCo with CocoFuji installed, serial cable routed to the back, TV/monitor showing the CONFIG Host Slots screen | The Program Library, Fig. 17 |
| `microsd-insert.jpg` | (Optional — not currently placed) Fingertip pushing a microSD card into the cartridge's card slot | spare |

## Verified-against-source notes

- Hardware facts (connector edge, ports edge, button/LED positions,
  DIP switch = A14/A15 ROM select, serial pinout, cart-port power)
  were measured from `CoCo-FujiNet-Rev000` STLs and schematic.
- The ↺ marking sits by the **Safe Reset** button + orange BUS LED;
  the A marking by **Button A** + white WiFi LED (schematic: SW3/SW2,
  D3/D2). Button A is the one nearest the CoCo's front when installed.
- CONFIG screens are typeset from `fujinet-config/src/coco/screen.c`
  strings (lowercase = inverse video on the VDG; CLS fill colors:
  hosts=blue, drives=red, browser=orange, wifi=cyan, info=magenta,
  shadows = SG4 `color|0x03` rows with `|0x0B` first cell).
- Boot banner from `hdbdw3cc2.rom` strings; the loading splash
  (Fig. 6) is the genuine `fujinet_bitmap[]` PMODE 4 image extracted
  from `fujinet-config/src/coco/cfgload/cfgload.c` by
  `tools/make_loading.py`.
- The Lobby figure (Fig. 16) is typeset from Thom's real-device
  screenshot (bright-green-on-field-green theme, THOMCOCO handle).
- Default host slots from firmware `BUILD_COCO/fnconfig.ini`
  (SD + apps.irata.online); the manual shows a taught configuration
  with tnfs.fujinet.online and fujinet.pl added.
