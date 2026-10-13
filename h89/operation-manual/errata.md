# Errata — where the sources and the book differ

The manual is written to the **intended release behaviour** of the H89 FujiNet
software (Thom's decision, October 2026). Every place where today's source
differs from what the book says is listed here, with file and line, so it can
be fixed in the source or accepted in the book.

Sources examined (Oct 12, 2026):

| Repo | Branch / commit |
|---|---|
| fujinet-firmware | `master` 0bc531d3d; H89 disk fixes on `h89-disk-fixes` 7ab84ae64 (worktree `~/Workspace/fn-h89`) |
| fujinet-h89 | `hdos-fn-driver` dff02cc (FN.DVD is not on `main` cea13e8) |
| fujinet-config | `add-h89` 6f48e0f |
| fujinet-lib | `h89-keep-esp32-running` 9e6d4dd |
| fujinet-go-h89-desktop | 8dc059d (firmware pinned at master 6b8187701) |
| fujinet-hardware | `H89/H89-ESP32 Schematic v1.28.pdf`; Collado, *How to control the H89-FujiNet 82C55 in Mode 2* Rev 1.0 |

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
   emulator only.
3. **The firmware disk fixes FNDISK needs are unmerged** (7ab84ae64 on
   `h89-disk-fixes`). On master: a read/write after an unmount crashes; disk
   STATUS `S` falls through to WRITE (`lib/device/rs232/disk.cpp:386-389`); a
   request with no sector field aborts; a write one sector past the end grows
   the image (`lib/media/rs232/diskTypeImg.cpp:30,67`); the MS-DOS boot disk
   sits in slot 1 (`lib/device/rs232/rs232Fuji.cpp:38`).
4. **The FujiNet-Flasher has no "Heathkit H89" platform** yet; the book's
   Chapter 9 tells the reader to choose it. Today the only image is
   `fn-h89/firmware/fujinet-H89-v1.6.2-dev.zip` (built from ece203da5, *before*
   the disk fixes).
5. **No H89 folder on the public servers.** `tnfs.fujinet.online:/` and
   `apps.irata.online:/` have no H89 folder (listed Oct 12, 2026). The book says
   "look for the H89 folder" (Ch. 6, Ch. 8). Pick the folder name and post the
   FujiNet disks there.

## Hardware

6. **PORT SEL and J3 are not in schematic v1.28** (Aug 2024). There, D0H is wired
   straight to the 74LS02 and D8H/E0H/78H are unconnected stubs. The V1.0 board
   (Oct 31, 2025) has both headers. The book's mapping (320Q = /SER0 D0H–D7H,
   330Q = /SER1, 340Q = /LP1, 170Q = /CASS with the 444-61 PROM) is inferred from
   the J2 pin names and MAME `h89bus.h:8-75`. **Confirm with J. Travis /
   N. Collado.**
7. **J3 left open** (Thom's decision). The 82C55A's INTR is active high, the
   H89's /INTn lines active low; a jumper on J3 could hold an interrupt line.
   The emulator says INTR isn't wired (`core/machine/FujiNetCard.h:33`).
8. **The three-pin header left of PORT SEL** has an unreadable label in the photo
   (something like "/BA2 — AUX"). The book says "leave as supplied."
9. **U4 on the prototype area** (20 pins). The photo's schematic title block
   reads "Added second 74LVC245"; the book calls U4 "a second 74LVC245" with an
   asterisk.
10. **Silkscreen J2 says PC6 for /OBF.** The 82C55A's /OBF is PC7 in Mode 2, and
    all software reads bit 7 (`fujinet-lib/bus/h89/portio.c:28`,
    `fujinet-h89/common/h89.inc`). Probably a silkscreen slip; the book's
    circuit description uses PC7.
11. **J2-23 power pin.** The schematic labels J2-23 "+5V"; MAME's bus has pin 23
    as −5 V (`h89bus.h:47`). Check the board.
12. **3.3 V supply.** Schematic v1.28: LD1117V33 from +12 V. The V1.0 board shows
    a TO-92 "Q1" and +5 V labels by the module; the book says only "3.3 volts
    made on the card." Confirm, and whether **USB may be plugged in with the H89
    on** (the DevKit's own regulator would be in parallel with the card's).
    Chapter 9 assumes it may (Collado's note flashes that way).
13. **Does EN stay low after reset?** The 82C55A's port C bus-hold pulls against
    the 3.3K leg of the divider. Check that the ESP32 really is held in reset
    after power-on.
14. **LED D1 is not driven.** `include/pinmap/heathkit_h89.h:23-27`: IO22's LED
    is active high but `leds.cpp` drives LEDs active low, so it is left unused.
    The book says "reserved; the present firmware leaves it dark."
15. **The designer's bring-up note** writes port C (`Out 0xD2,...`) before the
    mode set. After reset every 82C55A port is an input, so those writes do
    nothing. It also calls control word C0H "port B mode 1" (it is group B
    mode 0). The book's procedures set the mode first. They are verified in the
    emulator, which models reset-to-input (`FujiNetCard.cpp:47-67`).

## Firmware

16. **Drives are not remounted at start-up.** "Enable CONFIG boot disk" defaults
    to on (`lib/config/fnConfig.h:477`), and slots are mounted at start-up only
    when it is off (`src/main.cpp:564-565`). Every H89 reset restarts the ESP32.
    CONFIG's exit sends `fuji_set_boot_config(0)` (`fujinet-config main.c:43`),
    but `fujicmd_set_boot_config` only unmounts slot 0's boot disk; it does not
    persist (`lib/device/fujiDevice/fujiDevice.cpp:1462-1483`). The book tells
    the reader to run CONFIG + ESC after each reset, or to set the web option to
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
20. **First-call race.** After a cold card start, the drivers allow 1 s for the
    ESP32 to take the first byte (`fujinet-h89 common/fujibus.inc:17`). If the
    ESP32 boots slower than about 1.2 s, the first call may fail ("The FujiNet
    isn't answering."). The keyed-in Communication Test has no timeout, so it is
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

28. **FN.DVD is HDOS 2.0 only** (`hdos/fn/hdos.inc:4-6` uses HDOS 2.0's addresses).
29. **FN.DVD has no INIT.** The book says blank HDOS images must be made
    elsewhere (`hdosfs.py blank`).
30. **CP/M BIOS-80 and other CP/Ms are refused** by the version check
    (`cpm/fndisk/loader.asm:26,41-50`).
31. **Write to a read-only slot under CP/M** gives `Bdos Err On E: Bad Sector`
    (verified in the emulator). It is a firmware NAK of a `"rb"` mount
    (`fujiDevice.cpp:596-598`), not an FNDISK check.

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
