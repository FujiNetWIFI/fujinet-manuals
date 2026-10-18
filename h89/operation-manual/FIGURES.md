# Figures

Every picture in the book, where it comes from, and what still needs Thom.

## Photographs to take (placeholders in the book)

The book shows a dashed box with the shot described in it until the photo
arrives. Put the JPEG in `images/photo/` and swap the `photo-slot(...)` for an
`image(...)` in the part named.

| Pictorial | Part | Shot |
|---|---|---|
| 3-3 | `parts/03-setup.typ` | The H89 with its cabinet shell tilted back, showing the CPU logic circuit board and its accessory sockets. |
| 3-5 | `parts/03-setup.typ` | The FujiNet card seated on P504 and P510, beside the floppy disk interface board. Ideally from an angle that shows the component side facing the right way. |
| (cover) | `images/cover-board.png` | Optional: a photo of a reworked V1.1 card for the cover, in place of the KiCad render. `tools/duotone.sh` makes the three-tone print; its crop and mask are set for the render in `board.jpg`. |

## Drawn

| Pictorial | Source |
|---|---|
| 3-1 the card | `figs.typ` `card()`, measured from `images/photo/board.jpg` (the KiCad render of the V1.1 board) at half scale; the rework (D1 and R7 removed, EN/IO0/IO2 cut, wires to IO21/IO22) drawn from fujinet-firmware #2042 |
| 3-2 the jumpers | `figs.typ` `jumpers()`: JP1, J1 and J3, in board order |
| 3-4 the sockets | `figs.typ` `sockets()`, schematic, not to scale |
| 4-1 the port map | `figs.typ` `portmap()`, after H88 p. 5-6 |
| 11-1 block diagram | `figs.typ` `blocks()`, from the Rev 1.1 schematic and the #2042 pin map |
| cover | `images/cover-board.png` from `tools/duotone.sh` (inks eyedropped from the H88 cover), from the V1.1 render |

## Screens (captured, not typed)

Every H19 screen and session in the book was captured from the real programs
on FujiNet Go H89's headless machine (`h89_session_run`: VirtualH89 + the
82C55 card + the FujiNet firmware in-process), then read back cell by cell
against the 444-29 character ROM (`tools/ppm2cells.py`) and set in the
H19 Screen font. Nothing is retyped.

| Screens | Captured by |
|---|---|
| `screens/hosts`, `drives`, `browse-*`, `filter*`, `mount-image`, `newdisk-size`, `copy-host`, `info`, `wifi-*`, `host-edit`, `mounting`, `exit-*` | `tools/shots-config.sh` |
| `screens/hdos-*`, `cpm-*` | `tools/shots-drivers.sh` |
| `screens/mtr-*` | `tools/run-acctest.sh` |

**Touched screens.** The emulator's FujiNet has a stand-in WiFi ("Dummy Cafe",
127.0.0.1, the PC's hostname, every network at -1 dBm).
`tools/screenfix.py` replaces those with an example network (Workshop,
192.168.1.89, FujiNet, six neighbours with plausible strengths) on the 25th
line and the Info, WiFi Networks and password screens. It uses the same
layout rules as CONFIG's `src/h89/screen.c` and `ui.c`. The acceptance test's
reply line gets the same names. Every other cell is as the terminal showed
it.

The captures use a CONFIG built with `-DH89_RIG_KEYS` (`tools/rigcfg.sh`)
because the emulator's typing drops ESC; the backtick stands in for it.
Nothing on screen differs.

## Verify on a real card

- [ ] PORT SEL positions vs bus selects (320Q = D0H–D7H); J3 left open is safe.
- [ ] JP1 on 0 puts the card at 320-323 (the book reads it from the schematic).
- [ ] The rework as built: EN, IO0 and IO2 cut, D1 and R7 off, /OE to IO21 and DIR to IO22 (errata 32).
- [ ] Which of the three rows of pads (J4/J7/J8, J5/J9/J11) carry the bus connectors.
- [ ] Whether U2 (PLCC) or U6 (DIP) is fitted.
- [ ] Which way the card faces in the socket pair (Pictorial 3-5 photo).
- [ ] Whether the card fits P505/P511 beside an HA-88-3 at P504, etc. (clearance).
- [ ] USB with the H89 off: does U3 drive the unpowered 82C55A (errata 12)?
- [ ] The FujiNet-Flasher reaches the DevKitC's loading mode by itself (auto-reset), with the H89 on.
- [ ] The ESP32 keeps running, and its drives stay mounted, through SHIFT+RESET.
- [ ] The lamps: all lit after the Port Test's O323,300; PB0, PB2, PB4, PB6 after O321,252.
- [ ] The ESP32 boots in under ~1 s (the drivers' first-byte timeout).
- [ ] Current drawn from +5 V and +12 V; board dimensions (Specifications shows "to be measured").
- [ ] The microSD breakout: push-in or friction slot; which way the label faces.
- [ ] What ships in the package (Parts List says board + one shunt).
- [x] HDOS 48K: checked in the emulator (`tools/check-48k.sh`). CONFIG runs before FN.DVD is loaded, not after.
