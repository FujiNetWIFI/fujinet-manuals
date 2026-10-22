# Errata — where the sources and the book differ

The manual is written to the **intended release behaviour** of the H89 FujiNet
software (Thom's decision, October 2026). Every place where today's source
differs from what the book says is listed here, with file and line, so it can
be fixed in the source or accepted in the book.

Sources examined (Oct 12, 2026; for the second edition's card and start-up,
Oct 18, 2026):

| Repo | Branch / commit |
|---|---|
| fujinet-firmware | `master` 7e8e647 (PR #2042, merged Oct 18: the reworked card's pin map, /OE on IO21, DIR on IO22); first edition `master` 0bc531d3d with the disk fixes on `h89-disk-fixes` 7ab84ae64, merged Oct 14 as #1935 and #1972 |
| fujinet-h89 | `hdos-fn-driver` dff02cc (FN.DVD is not on `main` cea13e8); the card's start-up from `card-setup-mark` 4cb0024 (item 13) |
| fujinet-config | `add-h89` 6f48e0f; 1823324 builds against the fujinet-lib below (item 13) |
| fujinet-lib | `h89-keep-esp32-running` 9e6d4dd; `h89-setup-after-reset` d08f584 (item 13) |
| fujinet-go-h89-desktop | 8dc059d (firmware pinned at master 6b8187701); `card-reset-bus-hold` 51f411d (item 13); `card-rev11` 6ceac07 (PR #2), the reworked V1.1 card (items 32-36) |
| fujinet-hardware | `H89/H89-ESP32 Schematic v1.28.pdf`; Collado, *How to control the H89-FujiNet 82C55 in Mode 2* Rev 1.0 |
| this repo | `h89/learn/H89-ESP32-FUJINET.pdf` (J. Travis, Rev 1.1 schematic, KiCad); `images/photo/board.jpg` (KiCad render of the V1.1 board) |

## Release state

1. **Nothing is released yet.** The book's software lives on four unmerged
   branches (table above). fujinet-config `Makefile:24-27` keeps the H89 out of
   `PLATFORMS` and CI (`.github/workflows/ci.yml:25-28`), and says no fujinet-lib
   release supports the H89. The book says the disk images "can be had from the
   FujiNet project" (Ch. 5).
2. **The H89 firmware has never run on a real card.** fujinet-firmware 723f2e23f
   ("Build the H89 card as RS232 over the 82C55") says *Not tested: not flashed
   on the card yet, so PPIChannel itself has never run.* Every hardware
   behaviour in the book (handshake, start-up, flashing) is from source and the
   emulator only. The same holds for #2042's pin map: it has not run on a
   reworked card (item 33).
3. **Resolved Oct 14, 2026: the firmware disk fixes FNDISK needs** were
   unmerged at the first edition (7ab84ae64 on `h89-disk-fixes`). They went into
   master as #1935 and #1972: a read/write after an unmount crashed; disk STATUS
   `S` fell through to WRITE; a request with no sector field aborted; a write
   one sector past the end grew the image; the MS-DOS boot disk sat in slot 1.
4. **The FujiNet-Flasher has no "Heathkit H89" platform** yet; the book's
   Chapter 9 tells the reader to choose it. Today the only image is
   `fn-h89/firmware/fujinet-H89-v1.6.2-dev.zip` (built from ece203da5, *before*
   the disk fixes).
5. **No H89 folder on the public servers.** `tnfs.fujinet.online:/` and
   `apps.irata.online:/` have no H89 folder (listed Oct 12, 2026). The book says
   "look for the H89 folder" (Ch. 6, Ch. 8). Pick the folder name and post the
   FujiNet disks there.

## Hardware

6. **Resolved by the Rev 1.1 schematic: PORT SEL and J3.** Schematic v1.28
   (Aug 2024) had neither: D0H was wired straight to the 74LS02. The book's
   mapping was inferred from the V1.0 board's J2 pin names and MAME
   `h89bus.h:8-75`. Rev 1.1 confirms it: J1 IO_PORT_SEL takes IO_SERL_0_L
   (320Q), IO_SERL_1_L (330Q), IO_LP_L (340Q) or /IO_CASS_DISK_170Q, and J3 is
   /INTE_ENA.
7. **J3 left open** (Thom's decision). The 82C55A's INTR is active high, the
   H89's /INTn lines active low; on Rev 1.1 INTR drives them through Q1
   (2N3904, open collector), so a jumper on J3 would pull a line low while INTR
   is high. The emulator leaves INTR unconnected (`core/machine/FujiNetCard.h`).
8. **Resolved: the three-pin header left of PORT SEL** is JP1, BA2. Its common
   pin goes to U1's chip-select NOR: on 0 it takes A2 as it is (ports 320-323),
   on 4 inverted by U1B (324-327). The book now says to put it on 0. (The
   first edition, from the V1.0 photo, said "leave as supplied.")
9. **Resolved: the second 74LVC245** is U5 on Rev 1.1, in place of the V1.0's
   divider resistors ("Replace resistors with 74LVC245" in the title block).
   U4 is now the ESP32 module.
10. **Resolved on V1.1** (U5's silkscreen says PC7 for /OBF). **V1.0's
    silkscreen J2 said PC6 for /OBF.** The 82C55A's /OBF is PC7 in Mode 2, and
    all software reads bit 7 (`fujinet-lib/bus/h89/portio.c:28`,
    `fujinet-h89/common/h89.inc`). Probably a silkscreen slip; the book's
    circuit description uses PC7.
11. **25-pin connector, pin 23.** Schematic v1.28 labels J2-23 "+5V", and Rev 1.1
    has VCC on J5-23; MAME's bus has pin 23 as −5 V (`h89bus.h:47`). Check the
    board.
12. **3.3 V supply and USB.** Rev 1.1 settles the supply: the bus's +5 V reaches
    the DevKitC through D2 (1N5819), and the module's own regulator makes 3.3 V
    for it, U3, U5 and the microSD card. D2 keeps USB power off the bus, so USB
    with the H89 on is safe. **USB with the H89 off** is not settled: with VCC
    down, R1 no longer holds U3's /OE high and DIR floats, so U3 may drive the
    unpowered 82C55A's port A. The book says to flash with the Computer on
    (Ch. 9) and to unplug USB when done (Ch. 10). Confirm with J. Travis.
13. **Superseded by the rework (Oct 18, 2026): EN after reset.** PC2 no longer
    reaches the ESP32 (item 32), so there is nothing left to trust or not; the
    book's acceptance test writes the mode word every time. The first edition's
    item: **EN after reset: not to be trusted (Oct 13, 2026).** On Jeff Tranter's
    H89, HDOS CONFIG hung at "Contacting FujiNet..." while CP/M CONFIG worked.
    After a reset the 82C55A's bus hold can make PC2 read 1 while port A is not
    in Mode 2, and fujinet-lib 9e6d4dd (like fujinet-h89's `card_on` and FNON)
    took EN high to mean "already set up" and skipped the mode word. Heath
    CP/M's BIOS sends a mode word to 323Q at every cold boot, which is why CP/M
    was fine. Whatever sets the card up now leaves A5H in port B (wired to
    nothing) and trusts only that: fujinet-lib d08f584, fujinet-h89 4cb0024,
    FNON in fujinet-go-h89-desktop 51f411d, which also models the reset this
    way. The book (Ch. 4 "Reset", Ch. 11 "Starting the FujiNet") no longer says
    the divider holds the ESP32 in reset. Still to measure on a real card:
    whether the ESP32 keeps running or is held in reset after SHIFT+RESET, and
    whether a running ESP32 survives the few-microsecond EN dip after a mode
    word.
14. **Resolved by the rework: LED D1** was never driven
    (`include/pinmap/heathkit_h89.h:23-27`, before #2042: IO22's LED is active
    high but `leds.cpp` drives LEDs active low). The rework removes D1 and R7,
    and IO22 now reads DIR.
15. **The designer's bring-up note** writes port C (`Out 0xD2,...`) before the
    mode set. After reset every 82C55A port is an input, so those writes do
    nothing. It also calls control word C0H "port B mode 1" (it is group B
    mode 0). The book's procedures set the mode first. They are verified in the
    emulator, which models reset-to-input (`FujiNetCard.cpp:47-67`).

## Firmware

16. **Drives are not remounted at start-up.** "Enable CONFIG boot disk" defaults
    to on (`lib/config/fnConfig.h:477`), and slots are mounted at start-up only
    when it is off (`src/main.cpp:564-565`). Since the rework only power-on
    restarts the ESP32: after SHIFT+RESET the drives stay mounted.
    CONFIG's exit sends `fuji_set_boot_config(0)` (`fujinet-config main.c:43`),
    but `fujicmd_set_boot_config` only unmounts slot 0's boot disk; it does not
    persist (`lib/device/fujiDevice/fujiDevice.cpp:1462-1483`). The book tells
    the reader to run CONFIG + ESC after power-on, or to set the web option to
    No (Ch. 6 "When the FujiNet Starts"). **Risk:** with the option off, slots on
    network hosts are mounted at start-up before WiFi may be up.
17. **NEW DISK is refused by the RS232 firmware,** and CONFIG still assigns the
    empty file it leaves (`fujinet-config dist.h89/README.md:37-39`,
    `src/select_slot.c:147-166`). The book describes N as working, and says only
    100K suits the drivers.
18. **The web page's serial-port and emulator settings** appear on the H89
    (`data/webui/config/BUILD_RS232.yaml`), though meaningless over the 82C55A
    (`lib/hardware/PPIChannel.h:38-39`). The book says some settings do
    nothing. `data/webui/device_specific/BUILD_H89/` holds only `.keep`.
19. **The reply to GET_ADAPTERCONFIG in the emulator** shows "Dummy Cafe" / the
    PC's hostname / 127.0.0.1 (fujinet-pc's `fnDummyWiFi.cpp:88-106`). The
    book's screens replace them with an example network (see FIGURES.md).
20. **First-call race.** The drivers allow 1 s for the ESP32 to take the first
    byte (`fujinet-h89 common/fujibus.inc:17`). Since the rework the ESP32
    starts only at power-on, alongside the H89, which then boots from its
    floppy; a driver call that beats a slow ESP32 (over about 1.2 s) may still
    fail ("The FujiNet isn't answering."), and the book says to wait a moment
    and try again. The keyed-in Communication Test has no timeout, so it is
    immune.

## CONFIG (fujinet-config add-h89)

21. **ESC does not cancel the WiFi name/password prompts.** The buffers are
    cleared before editing (`src/h89/input.c:603,609`), so ESC "restores" an
    empty string and the flow continues (`src/set_wifi.c:35-47`). The book
    doesn't promise ESC there.
22. **Copy mode: RETURN on a file** overwrites `source_path`
    (`src/h89/input.c:376`), so the copy gets the wrong source. The book tells
    the reader to press C. Apple II has the same pattern.
23. **Shared-code messages are in capitals** (CONNECTION SUCCESS!, …), unlike the
    H89's own; one reads `COULD NOT WS_SCAN NETWORKS` (`src/set_wifi.c:59`).
24. **`dist.h89/README.md`** says "Neither OS has a FujiNet disk driver yet"
    (`:34`; also `mount_and_boot.c:10-12`, `system.c:30-32`). FNDISK and FN.DVD
    exist. It also says CONFIG.COM needs "a 64K system" (`:3`); FNDISK needs
    62K, and the tests run CONFIG on 62K.
25. **Custom new-disk size** is an `unsigned short`; values over 65535 wrap.
26. **Signal meter at -1 dBm.** The emulator's dummy RSSI 255 shows as -1 dBm
    with 4 bars (`src/h89/screen.c:542-555` reads it signed). The book's scan
    screen uses example strengths laid out by the same code.
27. **Info screen "CONFIG" version** is the git hash of the tree it was built in
    (`GIT_VERSION`); the capture showed the manuals repo's hash. The book shows
    fujinet-config's 6f48e0f.

## FNDISK / FN.DVD (fujinet-h89)

28. **FN.DVD is HDOS 2.0/3.0 only** (`hdos/fn/hdos.inc:4-6` uses HDOS 2.0/3.0's addresses).
29. **FN.DVD has no INIT.** The book says blank HDOS images must be made
    elsewhere (`hdosfs.py blank`).
30. **CP/M BIOS-80 and other CP/Ms are refused** by the version check
    (`cpm/fndisk/loader.asm:26,41-50`).
31. **Write to a read-only slot under CP/M** gives `Bdos Err On E: Bad Sector`
    (verified in the emulator). It is a firmware NAK of a `"rb"` mount
    (`fujiDevice.cpp:596-598`), not an FNDISK check.

## The V1.1 card and the rework (second edition, Oct 18, 2026)

32. **The rework is a bodge on the V1.1 board.** fujinet-firmware #2042 takes
    the ESP32's EN, IO0 and IO2 off the card, removes D1 and R7 (IO22), and
    wires /OE (PC1) to IO21 and DIR (PC0) to IO22. The book describes the
    result; how the wires and cuts are made is J. Travis's. Confirm against a
    reworked card.
33. **#2042 has not run on a reworked card** ("Not flashed or run on the
    reworked card", the PR). FujiNet Go H89 6ceac07 models the reworked card,
    and the acceptance test, the port check and the screens are from it.
34. **The Rev 1.1 schematic and the V1.1 render differ.** The schematic (Oct 13
    export) has J10 /OE_GPIO (/OE to IO17, IO16 or IO0) and JP2 /RESET_ON (EN
    through a jumper); the render of the V1.1 board has neither, and wires /OE
    to IO0 and EN straight to U5. The book follows the board, and the rework
    makes both moot.
35. **fujinet-lib, fujinet-h89 and CONFIG still start the card the old way.**
    `port_init` (`bus/h89/portio.c:100-127`) and fujinet-h89's `card_on`
    (`common/card.inc:13-37`) write 06H to port C (PC2, once EN, now goes
    nowhere), wait 200 ms and leave A5H in port B, which lights four of the
    lamps. Harmless, but the comments ("an ESP32 that was held in reset starts
    now", "IO0 strap") are stale. fujinet-h89's FNBOOT (`boot/fnboot.asm:7-38`)
    pulses EN to restart the ESP32, which no longer happens.
36. **Port B now drives eight lamps** (D3-D10 through RN1, lit by a 0). After any
    mode word all eight light; fujinet-lib's mark leaves four. The book's Port
    Test uses them (O321,252), but they cannot be seen with the cabinet closed,
    so it checks the read-back instead.

## Book choices to confirm

- The HA-88-3's 320 port is called its "second port, DCE, alternate terminal"
  from the H88 manual p. 5-5.
- CP/M slot letters start after the BIOS's drives: D: on an H-17 system with
  three drives (A:–C:).
- **48K HDOS** (`tools/check-48k.sh`, emulator): CONFIG.ABS runs on 48K *before*
  FN.DVD is loaded, and gets "?02 NOT ENOUGH RAM FOR THIS PROGRAM" after
  `LOAD FN:`. On 64K (HDOS says 56K), both run. The book says 48K, with 64K to run
  CONFIG after the drives have been used. A `-DFN_UNITS=4` FN.DVD (1K smaller,
  `fndvd.asm:16`) was not tried.
