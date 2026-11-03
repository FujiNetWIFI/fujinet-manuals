# Owner's Manual — where the sources differ from the book

The manual is written to the **intended** behaviour of the FujiNet 5200
cartridge (Thom's rule for the owner's manuals, set with the 2600's): what the
on-screen hints, the READMEs and the hardware design promise. Every place the
current sources do something else is listed here, with the file and line, so
it can be fixed in the source (or the book changed). Paths are relative to
`~/Workspace`; revisions are in README.md. Sources as of 2026-10-30.

## CONFIG (`fujinet-config/atari5200`, `cb44218`)

| # | Source | It does | The book says | Fix |
|---|---|---|---|---|
| C1 | `atari5200/fujiin.c:11-12`; nothing in `atari5200/` or fujinet-lib's `bus/atari5200/crt0.s` writes `CONSOL` (`$C01F`) bit 2 | Reads the stick from `PADDL0/1` without turning the pots on. The Programmer's Handbook (`parts/09-pads.typ:16`) says the pots then read nothing on a real console; MAME ignores the bit, so every capture works | The stick moves the bar (§5). §19 has a row for "the joystick does nothing, but the keypad works" | Write `$04` to `CONSOL` in the crt0 (as cc65's joystick driver and M.U.L.E.'s crt0 do). Same in every game's crt0 |
| C2 | `atari5200/fujiin.c:13-14`, `atari5200/README.md:48` | Calls `TRIG0` the "top fire" and `SKSTAT` bit 3 the "lower fire". `TRIG0` is the **bottom** button (MAME's a5200 inputs, the 1982 Owner's Manual: "the bottom buttons are the fire buttons") | Bottom button = `#` = open; top button = `*` = back (§5) — what the code does | Comments and README only |
| C3 | `atari5200/fujiedit.c:38-45` | The keyboard holds `$20`–`$5F`; CASE lowers A–Z only, so `` ` { \| } ~ `` cannot be typed | Says so, and points to the web panel and `fnconfig.ini` (§6, §10) | Add a row for `$60`–`$7E` |
| C4 | `atari5200/constants.h:40-41`, `atari5200/st_lobby.c:29-72` | PLAY GAME LOBBY boots `ec.tnfs.io:/atari5200/lobby.a52`; `ec.tnfs.io` has no `/atari5200` (root: apple2, atari, c64, coco, intv, msdos, utils), and `fujinet-lobby` has no 5200 client. If all eight hosts are full it overwrites host 8 | Describes the Lobby, with a "being finished" note (§11); host 8 documented | Build and publish the 5200 Lobby |
| C5 | `atari5200/fujiraw.c:59-62` | A FujiNet refusal (NAK) leaves ERR at 0, so it shows as `ERROR 00` | Not mentioned | Show NAK as its own code |
| C6 | `atari5200/st_copy.c:1-11` | Copies one file; a game's `.CFG` sidecar is not copied with it | Says so (§9) | — |

## The cartridge and its firmware (`fujinet-firmware` `f703133d0`; `pico/atari-5200` last changed `7a53805c8`)

| # | Source | It does | The book says |
|---|---|---|---|
| F1 | `lib/media/rs232/diskType.cpp:86-96` | `.A52`, `.BIN`, `.ROM` are cartridge images; `.CAR` is not on the list (mounts as a disk, CONFIG shows `?NOT A CARTRIDGE IMAGE`), although a `.car` header inside an `.a52` is honoured (`pico/atari-5200/firmware/src/a52map.c:167-175`) | Rename `.CAR` to `.A52` (§8, §19) |
| F2 | `pico/atari-5200/firmware/src/fuji_cart.c:2-3, 66-80` | No reset line: a console power cycle is the only way back to CONFIG | Documented as the way back (§5, §8, §19) |
| F3 | `pico/atari-5200/firmware/src/fuji_cart.c:85`, `src/fuji_load.c:52` | The red light comes on once an image is handed over, off at power-off | "Game light" (§2) |
| F4 | `data/webui/config/` | No `fujiversal-atari5200.yaml`; the web panel falls back to `BUILD_RS232.yaml` (serial, printer, modem panels that mean nothing on a 5200) | Web control panel described generally (§10) |
| F5 | `include/pinmap/fujiversal-atari5200.h:32` | microSD card-detect is wired (IO42) but left unconnected | — |
| F6 | `include/pinmap/fujiversal-atari5200.h:12-15`; `pico/atari-5200/firmware/include/a52_cart.h:42` | Still describe the cart as "a separate board joined only by USB" (PROVISIONAL), and pin 26's sense as "12 V-safe"; Rev0 is one board and pin 26 is 5 V (`fujinet-hardware/ATARI-5200/FujiNet-5200-Rev0/README.md:285-286`) | — |
| F7 | `fujinet-hardware/.../README.md:271-279` (Flashing) | The RP is flashed by the S3, by BOOTSEL+RESET, or over SWD; there is no owner-facing update procedure yet | "New versions, and how to load them, are announced at fujinet.online" (§18) |

## The games

| # | Source | It does | The book says |
|---|---|---|---|
| G1 | `th-5200` (branch `add-atari5200` = local `add-atari7800` `a7b2a80`, 11 files uncommitted) | The Texas Hold'em 5200 port is not committed anywhere; the published `/ATARI-5200/FUJINET/Texas Hold'em.a52` (md5 `339055f8…`) was built from this tree | Full section (§13) |
| G2 | `fk-5200` (`678f8b0`, 8 files uncommitted) | The Fujirkle 5200 port is uncommitted, and **not published** (`/ATARI-5200/FUJINET` has no Fujirkle) | Section with a "not yet in the library" note (§16) |
| G3 | `bs-5200/src/screens.c:353-354`, `src/atari5200/fujinet.c:108-166` | `5` at the table list tries the Lobby; when it is missing, Battleship stays at its table list (the other games go on to CONFIG) | "leaves Battleship for the Lobby" (§14) |
| G4 | `bs-5200/src/atari5200/vars.h:78`; `fujinet-multiplayer-mule/clients/mekkogx/Makefile:558` (`BACK_KEY_NAME "LOWER FIRE"`); `fz-5200/src/atari5200/osk.c:93-94`; `fk-5200/src/atari5200/vars.h:107-116`; every port's `input.c` header | The ports call `TRIG0` "top fire" and `SKSTAT` "lower fire", so on-screen hints such as `press LOWER FIRE to rotate` and `LOWER FIRE RUBS OUT` name what is physically the **top** button | Describes the physical buttons; §14 notes the screen's wording |
| G5 | `fcs-5200/src/util.c:115-135`, `th-5200/src/util.c:106-175`, `fz-5200/src/atari5200/fujinet.c:120-182`, `fk-5200/src/atari5200/fujinet.c:129-194` | Quit tries `ec.tnfs.io:/atari5200/lobby.a52`, shows `LOBBY NOT AVAILABLE`, then returns to CONFIG | "leave the game, for the Lobby" (§12–16); §11 and §19 explain the gap |
| G6 | `servers/fujinet-game-system/*/server/lobbyClient.go` (`origin/main` `0945622`) | No game server registers an `atari5200` client; `lobby.fujinet.online/view?platform=atari5200` answers "No servers available" | §11 note |
| G7 | `fujinet-multiplayer-mule` (local `main` `bfa3569`, `origin/main` `c5e3c9a`) | `apps.irata.online:/mule/atari5200/mule.a52` (md5 `ff5e9b50…`) was built from commits not yet pushed | §17 |
| G8 | `fz-5200/src/atari5200/input.c:97-114` | In Fujitzee `1` and the top button are help; `PAUSE`/`*` the menu; `START` refreshes; `RESET` quits — each game maps the keypad differently (5 Card Stud `PAUSE` = help, Hold'em `PAUSE` = menu, Battleship `RESET` = nothing) | Each section has its own chart; Quick Reference summarises |

## Hardware (`fujinet-hardware`, `ATARI-5200/FujiNet-5200-Rev0`, `1e04ba8`)

| # | Source | It does | The book says |
|---|---|---|---|
| H1 | `case/board-anchors.scad` (the only case file) | No shell exists. The book draws its own (`tools/make_cart.py`) round the anchor file's outline, screw holes, button pinholes, light windows, top-edge openings and 30 × 20 mm label recess; the label design is the book's | Drawings throughout; inside cover note |
| H2 | `README.md:31-32` | Rev0 is not built; everything ran in MAME and host tests | Describes Rev0 as the product |
| H3 | `README.md:176-179` | The original four-port (CA018087) feeds the cart from VR1, a 0.5 A 78M05 shared with the console; a WiFi burst (~470 mA) can pull it into limit. The universal boards feed the cart from the adapter (pin 11) | "Four-port consoles: use a charger" (§4) — the owner cannot easily tell the two four-port boards apart |
| H4 | `README.md:267-269` | Power-on race: USB-C before the console avoids it | "Plug the charger in before you turn the console on" (§4) |

**To verify on a built Rev0:** what RESET (SW1) does in the middle of a game
(the book: restart the cartridge, then power-cycle); the microSD card's
orientation (the book: contacts first, printed side toward the label — J3 is
on F.Cu, the label side); that the two lights show through a shell; console-
only power on a two-port and a universal four-port; the keypad overlay card's
size against a real CX52 (it is drawn, not to scale).

## The bench (not the product)

- `~/Workspace/servers` is behind `origin/main` (Fujirkle #80 "Let clients
  replay another player's move", "Fujirkle - Update clients", Hold'em and
  blackjack commits). Against that stale Fujirkle server the 5200 client shows
  scores such as 12544 and FINAL ROUND at the start of a game. The book's
  captures use servers archived from `origin/main` `0945622`.
- The book's game captures run bench copies of the published images with the
  server address pointed at localhost (`tools/patchurl.py`); nothing else
  differs.

## Other manuals

- `atari-5200/programmers-handbook/parts/01-unpack.typ:6` says the ESP32-S3 is
  joined "over a USB cable"; Rev0 is one board (the S3 is the USB host on
  IO19/20, `fujinet-hardware/.../README.md:3-4,19`).
