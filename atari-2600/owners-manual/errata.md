# Owner's Manual — where the sources differ from the book

The manual is written to the **intended** behaviour of the FujiNet 2600
cartridge (Thom's call, 2026-10-07): what the on-screen hints, the READMEs and
the hardware design promise. Every place the current sources do something
else is listed here, with the file and line, so it can be fixed in the source
(or the book changed). Paths are relative to `~/Workspace`. Sources as of
2026-10-07; commits are in README.md.

## CONFIG (`fujinet-config/atari-2600`, `ea103e0`)

| # | Source | It does | The book says | Fix |
|---|---|---|---|---|
| C1 | `src/browse.asm:673` (`THINT: "SEL=UP"`), header comment `:4-5` | Hint reads SEL=UP, but `:142-146` opens the ACTIONS menu (README.md:55 agrees with the menu) | Screen shows **SEL=MENU**; GAME SELECT opens ACTIONS (§7) | Change the hint string to `SEL=MENU` |
| C2 | `src/wifi.asm:108-117` (`APPVBL`) | CONNECTING (`WS_CONN`) reads no input; WIFI FAILED reads it but only acts on `WS_SELECT` — so the **SEL=SKIP** hint (`:556`) does nothing and WIFI FAILED is a dead end until RESET/power-off | GAME SELECT on WIFI FAILED goes on to FN HOSTS (§6, §19) | Act on `IN_SEL` in `WS_FAIL` (and `WS_CONN`): `CFGOTO` the hosts bank |
| C3 | `src/boot.asm` (`APPVBL`/`AVFAIL`, `:29-33`, `:63-144`) | BOOT FAILED reads no input; returns to the browser after ~3 s. `README.md:59` says "FIRE dismisses a failure" | "After a few seconds you are back in the browser" (§8) — consistent with the code; README.md:59 is the odd one out | Either read FIRE in `AVFAIL` or fix the README |
| C4 | `src/info.asm:140-154` | FIRE/SELECT on FN INFO always returns to **Hosts**, even when INFO was chosen in the browser | "Press the red button to go back" (§10) | Return to the bank that opened it |
| C5 | `src/hosts.asm:594-596` | LOBBY boots `ec.tnfs.io:/a2600/lobby.bin`; `ec.tnfs.io` has no `/a2600` folder (TNFS listing 2026-10-07; `README.md:121-126` admits it). It also overwrites host slot 8 when `ec.tnfs.io` is not already in a slot (`:370-456`) | ACTIONS ▸ LOBBY loads the Lobby (§11) | Publish `fujinet-lobby/atari-2600/build/lobby.bin` there (the Lobby has not been built yet) |
| C6 | `src/fujinet.inc:166`, `src/fujilib.inc:416` | The console's GAME RESET switch is read but no screen uses it | "The menu does not use the GAME RESET switch" (§5) — matches | — |
| C7 | `src/browse.asm:19-23` vs `:150-157` | Comment says moving the cursor re-lists; it does not | — | Comment only |
| C8 | `README.md:127-140` | Names cut to 11 characters; WiFi list capped at 12 | Documented as-is (§6, §7) | Scrolling names are the planned fix |
| C9 | `src/boot.asm` + adapter `lib/device/fujiDevice/fujiDevice.cpp:637-651`, `lib/bus/rs232/rs232.cpp:53-58` | MOUNT_IMAGE's ACK arrives only after the whole ROM transfer, and CONFIG blanks the display while it waits, so the BOOTING bar probably never fills; CONFIG gives up after ~9 s (`src/fujilib.inc:55-56`) and may show an error on a slow load that later completes | BOOTING shows a bar that fills as it loads (§8) | ACK the mount first, then stream; or poll `FN_R_BOOT_PCT` during the transfer |

## The cartridge and its firmware (`fn-2600`, `2600-experiment`, `7432186c0`)

| # | Source | It does | The book says |
|---|---|---|---|
| F1 | `pico/atari-2600/firmware/include/fujiconfigrom.h:1` ("from fujidir.bin"), `pico/atari-2600/build-cart.sh:13-17` | The cartridge's power-on program is the bring-up browser `fujidir`, not CONFIG. CONFIG's `make rom.h` writes into `~/Workspace/fujinet-firmware/pico/atari-2600` (`fujinet-config/atari-2600/Makefile:12,21-23`) | Power ON brings up the FujiNet menu (CONFIG) |
| F2 | `pico/atari-2600/firmware/boards/fujivcs.cmake:20` (`PICO_PLATFORM rp2040`), `include/vcs_pins.h` (`DIR_PIN`); `fujinet-hardware/.../Rev1/README.md:137-155, 209` | Cart firmware still targets the RP2040 Rev0 board; Rev1 (RP2354A) is unbuilt and untested | Describes Rev1 as the product |
| F3 | `build-platforms/platformio-fujiversal-atari2600.ini:1-17`, `lib/hardware/fn_pico_blob_data.cpp:1-5`, `docs/fujiversal-flashing.md:10-14` | No automatic cart-firmware flashing from the ESP32; the first RP flash is SWD (TP1-TP3) | "New versions, and how to load them, are announced at fujinet.online" (§18) — no owner update path exists yet |
| F4 | `pico/atari-2600/firmware/src/main.c:8-12`, `include/fuji_mailbox.h:726-732` | The cartridge RESET button (SW1) resetting both chips back to CONFIG is still bring-up checklist item 6 (`Rev1/README.md:21,231`) | The cartridge's RESET always brings back the FujiNet menu (§2, §5, §8) |
| F5 | `lib/media/rs232/diskType.cpp:73-92` | Only `.BIN`/`.ROM` are cartridge images; `.A26` mounts as a generic disk and nothing is sent to the cart (probably stuck on BOOTING) | Rename `.A26` to `.BIN` (§8) |
| F6 | `data/webui/config/` | No `fujiversal-atari2600.yaml`; the build falls back to `BUILD_RS232.yaml`, so the web control panel shows serial, printer, modem and CP/M panels that mean nothing on a 2600 (`Rev1/README.md:152-153`) | Web control panel described generically (§10) |
| F7 | `include/pinmap/fujiversal-atari2600.h:35-37` | SD card-detect wired (IO42) but disabled | — |
| F8 | `include/pinmap/fujiversal-atari2600.h:19-21` | No Button A/B/C, so the usual "power on + B" config reset does not exist | Not mentioned |

## Hardware (`fujinet-hardware`, `e26c9b4`)

| # | Source | It does | The book says |
|---|---|---|---|
| H1 | `ATARI-2600/Fujiversal-Atari2600-Rev1/case/Fujiversal-Atari2600-CartShell.scad:41` | `include <board-anchors.scad>` — not committed; generated by `tools/gen_pcb.py:562-582`. The book's `tools/cart_anchors.py` generates it into `build/` | — |
| H2 | `case/case-spec.md:3,22-23` | Names `Fujiversal-Atari2600-Shell.scad` (the clamshell), which is not on disk or in git | The book shows the full-size cart shell only |
| H3 | `CartShell.scad:349-352` | `part="rear"` exports the print orientation (mirrored), not assembled; the book's `tools/cartviews.scad` uses `rear_half()` directly | — |
| H4 | `Rev1/README.md:97-99, 224` | Console-only power (≈250-300 mA peak) and fit in the 2600 Jr / 7800 are unmeasured | Recommends a USB-C charger on a Jr or 7800 or if the picture jumps (§4) |
| H5 | `tools/placement.py` (`J_SD` "slot east"), `CartShell.scad` `sd_slot()` | "Right edge" in the hardware docs is the board's top view, seen from the console's rear — from the player's seat the microSD is on the **left** | Uses player's-eye directions (§2) |
| H6 | `CartShell.scad` `sd_z`, TF-015 | The book says to insert the card "printed side toward the back of the cartridge, contacts first", inferred from the card sitting above F.Cu (which faces the console rear) with its contacts toward the board | **Verify on a built unit** |

## Other manuals and READMEs that still describe Rev0

`atari-2600/programmers-handbook/parts/01-unpack.typ:4`;
`atari-2600/theory-of-operation/parts/part2.typ:202-300` (and its board renders are Rev0);
`fn-2600/pico/atari-2600/README-fujinet.md:105-119`;
`fujinet-config/atari-2600/README.md:37`; `fujinet-lobby/atari-2600/README.md:41`.
Rev1: RP2354A, no '245 buffers, P-FET power path, WS2812 + red LED, microSD on the side.

## The online library (`apps.irata.online`, listed 2026-10-07 by `make library`)

| # | It has | The book says |
|---|---|---|
| L1 | `/Atari_2600/` holds `battleship.bin`, `fujitzee.bin`, `texas.bin` — **no `5card.bin`** (and no 5 Card Stud image has been built: `fujinet-5cardstud/atari-2600/build/` was empty) | 5 Card Stud is `5CARD.BIN` in `Atari_2600` (§8, §12) |
| L2 | The folder is `Atari_2600` (underscore) | — (the classic ports' relays advertise `TNFS://apps.irata.online/Atari2600/Games/...`, a folder that does not exist) |
| L3 | `mule/players-manual/content/platforms.yaml:308` and its wiki use `irata.online`, which resolves to a LAN address here; the public name is `apps.irata.online` | `apps.irata.online` (§16) |
| L4 | `lobby.fujinet.online/view?platform=a2600` answers "No servers available for a2600" | The Lobby lists 2600 tables (§11) |

## The games

| # | Source | It does | The book says |
|---|---|---|---|
| G1 | `servers/fujinet-game-system/{5cardstud,battleship,fujitzee,texasholdem}/*/lobbyClient.go` | No Atari 2600 client is registered with the Lobby, and the four 2600 clients ignore the Lobby's server appkey and use the endpoint built into the image | "Choose a … table in the Lobby" (§12-15) |
| G2 | `fujinet-texasHoldEm/atari-2600/` | Only `build/` (gitignored) exists — no committed 2600 source; its How to Play text (`build/cdmenu.lst`) still says "5 CARD STUD / 1 HOLE CARD / 4 FACE UP" | Texas Hold'em described from 5 Card Stud's controls and the server's rules (§13) |
| G3 | `fujinet-5cardstud/atari-2600/build.sh:28` | `FUJI_FIRMWARE` default points at a tree without `emu/` / `tools/` (same in `fujinet-config` and `fujinet-lobby` `run.sh` for `FN2600`) | — |
| G4 | Controls differ per game: Battleship RESET = menu (`README.md:198-203`); 5 Card Stud / Hold'em RESET or stick-left = menu, hold SELECT = purses (`README.md:272-281`); Fujitzee SELECT = menu, RESET = poll (`README.md:110-118`); Lobby SELECT = name, RESET = refresh (`README.md:52-64`); M.U.L.E. SELECT = end turn, hold RESET = leave. Name keyboards differ too (CONFIG: SELECT ▸ ACCEPT/CANCEL/CLEAR; Lobby: SELECT deletes, RESET done; games: OK/DEL/SPC keys; Fujitzee: RST=DONE) | Each game documented as it is |
| G5 | `fujinet-multiplayer-mule/clients/atari-2600/README.md:55, 192-193` | Detached "left difficulty A = mute" row; "registers only the Atari client" is out of date | — |

## The networked classics (`fujinet-2600-*`)

| # | Source | It does | The book says |
|---|---|---|---|
| N1 | each `build/endpoint.inc` | Dodge 'Em, Dragster, Tennis and Video Olympics fall back to `127.0.0.1` without a Lobby appkey (Combat's points at `fujinet.online:9600`); `N:` prefixes inconsistent | "As each one is ready it will appear in the Lobby" (§17) |
| N2 | `server/*_relay_server.py` | Lobby registration only with `--lobby-url` (off by default); appkeys 24-27 "pending provisioning" | — |
| N3 | `fujinet-2600-video-olympics/server/vo_relay_server.py:584` (port 9600), appkey 24 | Collides with Combat's relay (`combat_relay_server.py:545,553`) | — |
| N4 | `fujinet-2600-dodgem/server/dodgem_relay_server.py:4` | Comment says "Dodge 'Em's 9602"; default is 9603 (`:563`); Tennis is 9602 | — |
| N5 | `fujinet-2600-dodgem/src/dmsess.inc:21-34, 321-331`; `PORTING.md:852-898` | The connecting screen is a plain colour with no words, and it waits ~64 polls (about a second) for an opponent before silently starting local play | Book shows Combat's CONNECTING / WAITING FOR AN OPPONENT screens as the family's (§17) |
| N6 | `fujinet-2600-tennis/src/tnsess.inc:480` | `STSERVE: "BUTTON SERVES"` is 13 characters; the cartridge drops the 13th, so the screen reads `BUTTON SERVE` | The book's screen shows what is drawn |
| N7 | `fujinet-2600-dodgem/src/dmcap.inc:46-48` | Reads each console's **right** difficulty switch (the other ports read the left) | "The difficulty switches cross the wire too" (§17) |
| N8 | all five | Not run on real hardware; the Nagle (`setNoDelay`) change is still needed in the adapter's TCP protocol | — |
| N9 | `fujinet-2600-combat/build/endpoint.inc` | Built for `N:TCP://fujinet.online:9600/`, and the client adds its own `N:` in front; nothing accepted a connection on 9600 on 2026-10-07, so the wait for a relay could not be measured | — |
| N10 | `fujinet-2600-video-olympics` | Local play (NO NETWORK) needs paddles in BOTH ports, as the 1977 game always did | "for two players on one console" (§17) — consistent |
