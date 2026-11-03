# Owner's Manual — where the sources differ from the book

The manual is written to the **intended** behaviour of the FujiNet Arcadia 2001
cartridge (Thom's rule for the owner's manuals, set with the 2600's): what the
on-screen hints, the READMEs and the hardware design promise. Every place the
current sources do something else is listed here, with the file and line, so
it can be fixed in the source (or the book changed). Paths are relative to
`~/Workspace`; revisions are in README.md. Sources as of 2026-11-03.

## CONFIG (`fujinet-config/arcadia`, main `6f0a60a`)

| # | Source | It does | The book says | Fix |
|---|---|---|---|---|
| C1 | `arcadia/hosts.inc:204-246`, `arcadia/build.sh:17-18` | GAME LOBBY (key 9) boots `ec.tnfs.io:/arcadia/lobby.bin`; `ec.tnfs.io` has no `/arcadia` (TNFS listing and its HTTP mirror, 2026-11-03), so it ends in MOUNT ERROR. When no host is `ec.tnfs.io` it overwrites host 8 | Describes the Lobby, with a "being finished" note (§11); host 8 documented | Publish the Lobby (G1) |
| C2 | `fujinet-firmware/pico/common/src/fujimail.c:6, 212-220` vs `arcadia/wifi.inc:91-157` | The cartridge gives SCAN_NETWORKS the default 5 s; CONFIG waits up to ~21 s. A slow scan would list only OTHER NETWORK (read from the code, not seen) | "SCANNING stays on the screen while it listens" (§6) | Give SCAN the 60 s `txn_timeout` class |
| C3 | `arcadia/README.md:140-143`, `arcadia/boot.inc:70`, `arcadia/README.md:28` | "Known limits" (stale boot registers, COPY_FILE timeout) and the "> 8K = ROM TOO BIG" note predate fujimail's fixes and protocol 2: over 8K now gives STAGE ERROR (03) unless it is an APPBANK image; ROM TOO BIG is over 70K | §8's error table follows the firmware | Update the README and the comment |
| C4 | `arcadia/wifi.inc:11-24, 47-88` | WAITING FOR LINK never shows against fujinet-pc (the link is up at once), and CONNECTING goes straight to 100% (fujinet-pc is always connected). The book's text describes the real cartridge; its screens are the bench's | §6 | — (bench only) |

## The Lobby and the games

| # | Source | It does | The book says |
|---|---|---|---|
| G1 | `fujinet-lobby` branch `arcadia` (`b94520a`, pushed, no PR) | The Arcadia Lobby client is not on main and not deployed to `ec.tnfs.io:/arcadia/lobby.bin`; the production Lobby lists no `arcadia` clients (`lobby.fujinet.online/viewFull`, 2026-11-03), and FujiNetWIFI/servers has no `arcadia` entries | §11 with a "being finished" note; its screens come from the branch, against the bench Lobby with POSTed rooms (`emu/rooms.sh`) |
| G2 | `fujinet-fujitzee/.gitignore:31` (`fujitzee.*`) | Catches `arcadia/fujitzee.asm`, the Arcadia port's top file: it was **never committed**, so nobody else can build the published `Fujitzee.bin`. The bench uses the working-tree copy (md5 `59d8166d`) | §15 |
| G3 | `fujinet-texasHoldEm` | The Arcadia port is on the tschak909 fork's `add-arcadia` (`84acc8f`), no PR to the upstream repo. (The published `Texas Hold 'em.bin` carried a private `127.0.0.1:8093` endpoint until Thom rebuilt it on 2026-11-03; the new one matches a clean build of `origin/add-arcadia` byte for byte, md5 `f44a54c9`) | §13 |
| G4 | `fujinet-5cardstud/arcadia/nament.inc:8`, same in th/bs/fz | The name is not kept: every boot starts from `ARCADIA`. None of the games reads the Lobby's appkeys (its name or its chosen table) | "The game asks YOUR NAME, with ARCADIA already spelled" (§12); the Lobby "remembers" its own name (§11) |
| G5 | `fujinet-5cardstud/arcadia/lobby.inc:83` (and th, bs, fz) | Digits 1-8 jump to a table row, but `2` is the Action button's wire, so `2` joins the highlighted row | Not mentioned (the book teaches the disc and ENTER) |
| G6 | `Golf (Europe).bin` on `apps.irata.online:/Arcadia/` | Stops at `NO. OF PLAYERS` from the FujiNet cartridge (book bench, MAME, 2026-11-03); MAME plays it only with its `golf` mapper (`mame/src/devices/bus/arcadia/rom.cpp`, `slot.cpp:155-175`: the high 2K at `$4000`). The other 47 load and play (firmware M5 soak, 48/48 byte-identical streams) | §8, §17, §20: Golf does not play yet. FujiNet Go plays it from a local file (its own Golf mapper) |
| G7 | `fujinet-multiplayer-mule/cmd/muleserver/main.go:71` | Advertises `tnfs://irata.online/mule/arcadia/mule.bin` to the Lobby, but the production Lobby lists no M.U.L.E. rooms | §16 loads it from the browser |

## The cartridge and its firmware (`fujinet-firmware` origin/master `e3923e881`)

| # | Source | It does | The book says |
|---|---|---|---|
| F1 | `.github/workflows/release.yml:19-44` | `FUJIVERSAL-ARCADIA` is not in the release matrix (INTV, MSX and DRIVEWIRE are): there is no firmware download for the Arcadia cartridge, and FujiNet-Flasher has no Arcadia entry | "Announced at fujinet.online" (§19) |
| F2 | `lib/media/rs232/diskType.cpp:89-96` | `.BIN`, `.ROM` (and INT ITV CHF NES SMS A78 A52 ST2 COL) are cartridge images; `.ARC` is not (mounts as a disk: NOT A CART), although the FujiNet Go desktop opens `.arc` locally | Rename `.ARC` to `.BIN` (§8, §20) |
| F3 | `include/pinmap/fujiversal-arcadia.h:34-35` | microSD card-detect is wired on Rev0 (IO42) but the pin map leaves it unconnected | — |
| F4 | `fujinet-hardware/.../FujiNet-Arcadia-Rev0/README.md:211-220` | The firmware still builds for a stock Pico (`pico/arcadia/firmware/boards/fujiarcadia.cmake:3`): no RP2354 board file, no VSENSE serve gate, no S3-driven RP update (`PIN_RP2040_RUN`/`BOOTSEL`), no return to CONFIG when the console goes off on USB power | §5: on USB power the cartridge keeps the last game until its RESET |
| F5 | `pico/arcadia/firmware/src/main.c:21-23` | The red light is turned on once at start and never changed | "Game light: red whenever the cartridge has power and its game chip is running" (§2) |
| F6 | `pico/arcadia/README.md:192-198` | "Hardware status" says nothing is designed and level shifters are needed; Rev0 exists (330 R into 5 V-tolerant pins) | — |

## The web control panel

| # | Source | It does | The book says |
|---|---|---|---|
| W1 | `data/webui/config/`, `build_webui.py:22-27` | No `fujiversal-arcadia.yaml`; the panel falls back to `BUILD_RS232.yaml` (serial, printer, modem, CP/M panels that mean nothing on an Arcadia) | The panel described generally (§10) |

## Hardware (`fujinet-hardware/Emerson-Arcadia/FujiNet-Arcadia-Rev0`, untracked)

| # | Source | It does | The book says |
|---|---|---|---|
| H1 | `tools/edge_geom.py:30` (`VERIFIED = False`), README "PROVISIONAL — DO NOT ORDER YET" | Pin-1 end, finger size, outline, shell and insertion depth unmeasured; nothing built | The cartridge described as designed (§2, §21) |
| H2 | `tools/gen_pcb.py:776-782`, `tools/design.py:275-311` | All parts, so the RESET button, the service buttons and both lights, are on the face toward the **television** | Says so, and draws the back (§2, §5, Fig. 2, Fig. 7) |
| H3 | `case/board-anchors.scad` only | No shell exists; the book draws its own (light windows, RESET hole, pinholes on the back; USB-C notch on top; microSD notch on the right side) | "Cartridge shell: to come" (§21) |
| H4 | `README.md:143-161` | Console-only power adds 25-64% to the ADV-1's 12 V / 0.5 A adapter load | "We recommend a charger whenever you play" (§4) |

## To verify on a built Rev0

- The cartridge's RESET followed by the console's RESET brings back CONFIG (§5): read from the design (SW1 resets both chips; the cart then serves the baked CONFIG), not tried.
- The lights are visible from the player's seat (they face the television).
- WAITING FOR LINK lasts "a few seconds" on a cold start.
- Look-alike consoles (Tele-Fever, Leisure-Vision, Hanimex MPT-03, Palladium ...): shell, pinout and PAL timing unknown; the book says "not yet tried".
- Which controller CONFIG reads: the left one (player 1, `$1900-$1902`), as Space Mission's "Left Controller" suggests.

## The bench (not the product)

- MAME runs the FujiNet cartridge's mailbox without bus timing: an 8K game and even M.U.L.E.'s 51,200 bytes arrive at once, so BOOTING is shown at 100%.
- The INFO and SELECT NETWORK screens have fujinet-pc's invented names and addresses swapped for ordinary ones in screen RAM before the snapshot (`emu/tour.sh` SWAP/POKES), as the 5200 book does.

## Other pages

- `fujinet-bring-up-pages/arcadia-2001/arcadia-2001.html` (2026-10-21) still says: master bakes the fujicfg stand-in (fixed by #2259), there is no bank switching (#2180), no PCB (Rev0 is routed) and no FujiNet Go (v0.1.0 published).
