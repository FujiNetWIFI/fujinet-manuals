# Image manifest

All CONFIG screens are typeset directly in the Apple II ROM font —
**no screenshots are needed for this manual.** Only photographs are
required, and each one currently renders as a labeled placeholder box
in the PDF.

Photos: JPG/PNG, reasonably high resolution; most print ~3.2–4.5 in
wide. Period styling tip: the 1984 IIc manual shot hardware on a
plain light sweep with soft shadows — a sheet of white poster board
works great.

| # in PDF | Target file in `images/` | Shot description | Status |
|---|---|---|---|
| COVER | `cover-photo.jpg` | FujiNet plugged into an Apple IIc (or IIGS) on a desk, monitor showing CONFIG — the "hero" | ⬜ NEEDED |
| TITLE | `parts-spread.jpg` | flat-lay: FujiApple, DB-19 adapter, IDC20 cable, microSD card (the "what you get" spread) | ⬜ NEEDED |
| FIG 1-1 | `fujiapple-front.jpg` | FujiApple straight on, case visible: both LEDs, buttons, microSD slot edge (callout leaders point at these) | ⬜ NEEDED |
| FIG 1-2 | `fujiapple-rear.jpg` | FujiApple rear/side: IDC20 port and USB-C visible | ⬜ NEEDED |
| FIG 2-1 | `db19-adapter.jpg` | DB-19 adapter attached to the FujiApple (or alongside with cable) | ⬜ NEEDED |
| FIG 2-2 | `hookup-iic.jpg` | hand plugging FujiNet into the IIc's external disk port (echoes IIc manual Fig 1-4/1-5) | ⬜ NEEDED |
| FIG 2-3 | `hookup-iigs.jpg` | FujiNet connected to the IIGS rear SmartPort | ⬜ NEEDED |
| FIG 2-4 | `liron-card.jpg` | Liron card in a IIe (or on its own), FujiNet + adapter connected | ⬜ NEEDED |
| FIG 2-5 | `softsp-diskii.jpg` | Disk II / 5.25 controller with IDC20 ribbon to FujiNet — show correct plug alignment | ⬜ NEEDED |
| FIG 2-6 | `microsd.jpg` | inserting the microSD card | ⬜ NEEDED (optional) |

When a file lands in `images/`, flip its entry to `true` in the
`photos` dictionary at the top of `manual.typ` and re-run `make` —
the placeholder box is replaced by the real photo. (Typst can't test
for a file's existence, so the dictionary is the switch.)

Note: `parts-spread.jpg` is used twice — on the title page and as the
Chapter 1 opener banner. `cover-photo.jpg` doubles as the wiki
edition's hero image.

Hardware facts asserted in the manual, worth double-checking against
a production FujiApple Rev1.1:

* white LED = WiFi, amber LED = SmartPort/Disk II bus activity
* two buttons: A (function TBD by firmware) and Reset
* USB-C connector; powered entirely from the disk port otherwise
* push-push microSD, FAT32 only
