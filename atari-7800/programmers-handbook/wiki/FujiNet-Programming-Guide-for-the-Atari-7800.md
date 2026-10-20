# FujiNet Programming Guide for the Atari 7800

The FujiNet programming manual for the Atari 7800 ProSystem: the memory map and
the mailbox, the text display three ways, living in 4K, the 6502 library, C with
fujinet-lib and 7800basic on the mailbox, eight worked programs in all three
languages, the command reference, the tile engine, and walkthroughs of
Battleship and CONFIG. This is the wiki condensation; the full illustrated
edition is the PDF in `atari-7800/programmers-handbook/` of the manuals
repository, styled after the 1986 *ATARI 7800 ProSystem Owner's Manual*.

See also the [FujiNet-Network-Protocol-Handbook](FujiNet-Network-Protocol-Handbook)
for everything the `N:` device can say once you can reach it.

## Contents

- [Your FujiNet cartridge](#your-fujinet-cartridge)
- [Installing the tools](#installing-the-tools)
- [The memory map](#the-memory-map)
- [How the mailbox works](#how-the-mailbox-works)
- [The text display](#the-text-display)
- [Living in 4K](#living-in-4k)
- [The three libraries](#the-three-libraries)
- [The programs](#the-programs)
- [Banks and SuperGame](#banks-and-supergame)
- [Command reference](#command-reference)
- [Battleship](#battleship)
- [CONFIG](#config)
- [Things that cost real time](#things-that-cost-real-time)
- [Troubleshooting](#troubleshooting)
- [Sources of truth](#sources-of-truth)

## Your FujiNet cartridge

An RP2354B microcontroller and 512K of static RAM sit on the cartridge edge.
The console reads the RAM itself — its address and data lines go straight to
the chip — and the RP2354B only decides which 8K page each slot of the address
space shows, so MARIA can read the cartridge at full speed. Behind it, over
USB, an ESP32-S3 runs the FujiNet firmware (`fujiversal-atari7800`).

The console sees a signed boot block at power-on, a 512-byte loader at `$0600`,
a mailbox from `$0800` to `$0FFF`, a POKEY at `$0450`, a High Score Cart when
one is installed, and up to 448K of program laid out the way any of ten real
7800 boards would lay it out.

**The board is a Rev0 design that has not yet been built.** Everything here ran
in host tests and the MAME cartridge model. The cartridge edge has no reset
line; the console's RESET switch is a bit in `SWCHB`.

## Installing the tools

- **cc65 2.19**: `ca65`, `ld65`, `cc65`, `cl65`.
- **fujinet-lib** with the `atari7800` target: `fujinet-lib-experimental`,
  branch `add-atari7800` (PR #152) until it merges; `make atari7800`.
- **7800basic**, built natively: `make LEX=flex 7800preprocess`, then
  `make LEX=flex 7800optimize`, then `make LEX=flex` (the two lexers share
  `lex.yy.c`; never build them in parallel). dasm 2.20.16 on the PATH.
- **MAME** with the cartridge: `fujinet-firmware/pico/atari-7800/emu/apply.sh
  mame`, then `make SUBTARGET=a7800 SOURCES=src/mame/atari/a7800.cpp REGENIE=1`;
  run with `-cartslot fujinet`. MAME must run from its own tree for
  `-autoboot_script`.
- **fujinet-pc**: `./build.sh -p RS232` in the firmware; its `[BOIP]` port is
  where the cartridge connects (`FUJINET_TCP`, default `127.0.0.1:9995`).
- Or **FujiNet Go Atari 7800**, which has all of it inside: *Open Cartridge…*
  runs any `.a78`, and a claimed program keeps the mailbox.

## The memory map

| Range | What |
|---|---|
| `$0000`–`$003F` | TIA (INPTCTRL `$01`), MARIA |
| `$0040`–`$00FF`, `$0140`–`$01FF` | zero page and stack: console RAM |
| `$0280` | RIOT: joysticks, switches |
| `$0450`–`$045F` | the cartridge's POKEY |
| `$0600`–`$07FF` | the loader |
| `$0800`–`$0BFF` | reply window (read) |
| `$0C00`–`$0CFB` | status page (read) |
| `$0D00`–`$0DFF` | registers and one-shots (write) |
| `$0F00`–`$0FFF` | TX stream (write) |
| `$1000`–`$17FF`, `$3000`–`$3FFF` | High Score Cart RAM and ROM, when on |
| `$1800`–`$27FF` | console RAM, 4K |
| `$4000`–`$7FFF` | cartridge RAM (16K) if the claim asks |
| `$8000`–`$FFFF` | the program; the claim at `$FF70` |

The cartridge's mode is at `$0C12`: 0 BOOT (the boot block), 1 LOAD (the
loader filling the RAM), 2 GAME (an image, mailbox off), 3 APP (an image that
keeps the mailbox). What makes an APP is the **claim**: ten bytes at `$FF70`,
`"FUJI"`, version 1, kind+1 (the board layout; 0 lets the cartridge decide),
flags (bit 0: 16K of RAM at `$4000`), three zeros.

Rules for every program:

1. **Never store to `$00`–`$1F`** until you mean to lock INPTCTRL; a lock stops
   games you boot from going through the console's BIOS. Sound through the
   POKEY at `$0450`; MARIA's `WSYNC` at `$24`.
2. **Never use a read-modify-write instruction on `$0D00`–`$0FFF`.**
3. **Never `JMP ($xxFF)`.**
4. **Set your own stack**: the loader leaves S at `$16`.

## How the mailbox works

A register is one store: _V_ to `$0D00`+_n_. A transaction:

1. DEVICE (`$0D00`), CMD (`$0D01`), NPARAM (`$0D02`); DATA_RST (`$0D05`).
2. Parameters into `$0F00`, one store a byte: size (1, 2, 4) then the value,
   low byte first; then the payload. 320 bytes, eight parameters at most.
3. SEQ (`$0D10`) = ACKSEQ (`$0C00`) + 1; 0 becomes 1. **Never keep your own
   counter**: the cartridge outlives a power cycle of the console.
4. Wait for ACKSEQ = SEQ; the cartridge paints it last.
5. ERR (`$0C02`) 0? REPLY_CMD (`$0C03`) `$06`? The reply is at `$0800`, RXLEN
   (`$0C04`) bytes, at most 1024.

```
        lda     #$70            ; device, command, no parameters
        sta     FN_REGSEL+FN_REG_DEVICE
        lda     #$C4            ; GET_ADAPTERCONFIG_EXTENDED
        sta     FN_REGSEL+FN_REG_CMD
        lda     #0
        sta     FN_REGSEL+FN_REG_NPARAM
        sta     FN_REGSEL+FN_REG_DATA_RST
        lda     FN_ACKSEQ       ; the next sequence number
        clc
        adc     #1
        bne     @seq
        lda     #1              ; 0 is reserved
@seq:   sta     FN_REGSEL+FN_REG_SEQ   ; launch
@wait:  cmp     FN_ACKSEQ       ; painted last
        bne     @wait
```

The cartridge allows 5 seconds a transaction, 60 for MOUNT_IMAGE and
COPY_FILE, 90 for the network device's OPEN, STATUS, READ and CLOSE; a
program's own wait must be longer. In MAME a transaction completes inside the
store to SEQ.

## The text display

MARIA draws from display lists; a text row is an *indirect* object pointing at
character codes. **MARIA cannot read the mailbox**: copy reply text to RAM
first.

| | Assembly | C | 7800basic |
|---|---|---|---|
| Library | `fujidisp.s` | `maria.s` (CONFIG's tile engine) | built in |
| Mode | 320A, 40 × 24 | 320B indirect, 32 × 24 tiles | 320A, `plotchars`, `plotmap` |
| Text lives | `$4000` (cart RAM) | `$4000` (cart RAM) | `$2200`–`$27FF` |

## Living in 4K

| | Assembly | C | 7800basic |
|---|---|---|---|
| Zero page | `$40`–`$DF`; library `$E0`–`$EB` | cc65 and `ZEROPAGE` | temps `$40`–`$4A`; `a`–`z` `$E6`–`$FF` |
| Stack page | stack | stack | `var0`–`var99` `$140`–`$1A3`, stack from `$1C2` |
| `$1800`–`$27FF` | free | `CONSOLE` | DLL `$1800`, lists `$1880`–`$1FFF`; free `$2200`–`$27FF` |
| `$4000`–`$7FFF` | screen, `BSS` | data, heap, tile map, C stack | (with `32kRAM`) |

The reply window is free memory: read replies in place.

## The three libraries

**Assembly** — the bring-up's `fujilib.s`: `fn_chk` (magic), `fn_beg`
(`FN_DEV`, `FN_CMD`, `FN_NPR`; timeout `FN_TMO` = 16, ~11 s), `fn_pb`, `fn_pw`,
`fn_txb`, `fn_path` (padded to 256), `fn_go` (A = ERR, `$FF` no answer),
`fn_ack` (`$EE` on NAK), `fn_blk`, `fn_boot`. The handbook adds `devdefs.inc`,
`netdefs.inc` and the `FNBEGIN dev, cmd, nparam` macro.

**C** — fujinet-lib's `atari7800` target: its `crt0.s` (never touches
INPTCTRL), `atari7800-fujinet.cfg` (32K ROM at `$8000`, 16K RAM at `$4000`),
`atari7800-romstamp.py`. Use the ordinary `fuji_*`, `network_*`, `clock_*`
calls; `fujinet-atari7800.h` adds `fuji_a7800_present()`, `_mode()`,
`_boot_state()`, `_boot()`, `_config()`, `_tv()`, `_hsc()` and more. The bus
layer (`fujinet-bus-atari7800.h`): `fn_regwr()`, `fn_tx()`, `fn_commit()`,
the `FN_*` cells, and `fuji_bus_call()` for any command. No conio, no
`clock()`, no TIA.

**7800basic** — `incbasic fujinet.bas` first (the mailbox's names: in BASIC a
register's name is its address, `FN_CMD = $C4` is one `STA $0D01`), then
`incbasic fujilib.bas` after the main loop (`fn_chk`, `fn_beg`, `fn_pb`,
`fn_pw`, `fn_pad`, `fn_go`, `fn_hex`; arguments in `fn_dev`, `fn_cmd`,
`fn_npr`, `fn_val`, `fn_valhi`, `fn_tmo`; result in `fn_res`).
`tools/basfix.py` stamps the claim; `7800header` writes the `.a78`. Rules:

- No one-letter variable names (`a`–`z` are 7800basic's).
- No arithmetic on a mailbox name.
- **No expression in an array index**: `FN_REPLY[ix + 2]` compiles silently
  into nonsense. `dim` a name at the field's address.
- **No expression in a `for` bound**: `to n - 1` silently drops the `- 1`.
- 7800basic locks INPTCTRL at start-up; `const NOTIALOCK = 1` and
  `const NOTIALOCKMUTE = 1` keep it unlocked (use the POKEY for sound).

## The programs

Eight programs, each in all three languages, verified in MAME against
`fujinet-pc` by `emu/verify.sh` (which reads the screen through MARIA's
display lists):

| Program | Shows |
|---|---|
| hello | text, and that a FujiNet cartridge answers |
| first contact | GET_ADAPTERCONFIG_EXTENDED: SSID, IP, firmware |
| netget | an HTTP GET through `N:`, a line at a time |
| directory | MOUNT_HOST, OPEN_DIRECTORY, READ_DIR_ENTRY until `$7F,$7F` |
| boot | MOUNT_HOST, SET_DEVICE_FULLPATH, MOUNT_IMAGE, watch BOOT_STATE, BOOTLOCK, `JMP $0600` |
| appkey | the shared name (1:1:0), then a key written and read back |
| clock | GET_ISO_LOCAL and GET_ISO_UTC |
| banks | a transaction from each of three SuperGame banks |

## Banks and SuperGame

16K banks; the last is fixed at `$C000`; a store anywhere in `$8000`–`$BFFF`
picks the bank shown there. Switch from the fixed bank; keep everything MARIA
reads (font, tiles) and the mailbox library there. A FujiNet app names the
scheme in its claim's kind byte: 3 SuperGame, 5 SuperGame with RAM. In C:
a linker config with `BANK0`–`BANK2` at `$8000`, a crt0 with the claim's kind,
`#pragma code-name`, and `tools/checkbanks.py` (fujinet-lib's romstamp takes
48K at most). In 7800basic: `set romsize 128k`, `bank N`, `gosub x bankN`,
`return otherbank`; font and library in bank 8.

## Command reference

The cartridge's ESP32 runs the firmware's RS232 build. Conventions: _byte_ =
size 1 + value; _word_ = size 2 + two bytes, low first.

### FUJI device `$70`

| Command | Code | nparam | Notes |
|---|---|---|---|
| GET_ADAPTERCONFIG_EXTENDED / _CONFIG | `$C4` / `$E8` | 0 | 240 / 140 bytes |
| SCAN_NETWORKS | `$FD` | 0 | reply: count |
| GET_SCAN_RESULT | `$FC` | 1 | byte index; 33-byte SSID + signed RSSI |
| SET_SSID | `$FB` | 1 | byte (ignored, required); payload exactly 97 bytes |
| GET_SSID | `$FE` | 0 | 97 bytes |
| GET_WIFISTATUS / GET_WIFI_ENABLED | `$FA` / `$EA` | 0 | 3 = connected |
| RESET | `$FF` | 0 | restarts the ESP32 |
| STATUS / DEVICE_READY | `$53` / `$00` | 1 / 0 | |
| READ_HOST_SLOTS / WRITE_HOST_SLOTS | `$F4` / `$F3` | 0 | 8 × 32 bytes |
| MOUNT_HOST | `$F9` | 1 | host slot |
| READ_DEVICE_SLOTS / WRITE_DEVICE_SLOTS | `$F2` / `$F1` | 0 | |
| SET_DEVICE_FULLPATH | `$E2` | 3 | device, host, mode; 256-byte path |
| MOUNT_IMAGE / UNMOUNT_IMAGE | `$F8` / `$E9` | 2 / 1 | the push into the cartridge; 60 s |
| MOUNT_ALL / SET_BOOT_MODE / CONFIG_BOOT | `$D7` / `$D6` / `$D9` | 0 / 1 / 1 | |
| OPEN_DIRECTORY | `$F7` | 1 | host; 256 bytes: path, NUL, filter |
| READ_DIR_ENTRY | `$F6` | 2 | maxlen (never 31), flags; `$7F,$7F` ends |
| SET / GET_DIRECTORY_POSITION | `$E4` / `$E5` | 1 / 0 | one word |
| CLOSE_DIRECTORY | `$F5` | 0 | |
| COPY_FILE | `$D8` | 2 | hosts from 1; payload `src\|dst` |
| SET / GET_HOST_PREFIX | `$E1` / `$E0` | 1 | |
| GET_DEVICE_FULLPATH | `$DA` | 1 | |
| OPEN_APPKEY | `$DC` | 0 | 6 bytes: creator (word), app, key, mode, reserved 0 |
| READ / WRITE / CLOSE_APPKEY | `$DD` / `$DE` / `$DB` | 0 / 1 / 0 | READ: word length + value |
| GENERATE_GUID | `$BB` | 0 | 36 characters |
| HASH INPUT / COMPUTE / LENGTH / OUTPUT | `$C8`–`$C5` | 1 | also `$C3`, `$C2` |
| BASE64 encode / decode | `$D0`–`$CD` / `$CC`–`$C9` | | |
| QR code | `$BC`–`$BF` | | |

NAK on this build: `$F0`, `$EB`, `$E7` NEW_DISK, `$E6` UNMOUNT_HOST, `$E3`,
`$DF`, `$D5`, `$D4`, `$D3` RANDOM_NUMBER, `$D2` GET_TIME, `$D1`, `$C1`, `$BA`,
`$A0`–`$A9`, `$90`, `$3F`.

### Network devices `$71`–`$78`

| Command | Code | nparam | Notes |
|---|---|---|---|
| OPEN | `$4F` | 2 | mode, translation; payload the devicespec |
| STATUS | `$53` | 2 | two zeros; 4 bytes: waiting (word), connected, status |
| READ | `$52` | 1 | one word, ≤ waiting and ≤ 1024 |
| WRITE | `$57` | 1 | one word; payload |
| CLOSE | `$43` | 0 | |
| SET_PARSER / PARSE / QUERY | `$FC` / `$50` / `$51` | 2 / 0 / 0 | parser 0 none, 1 JSON, 2 HTML, 3 XML |
| SET_PARAMETER | `$FB` | 2 | 0 query flags, 1 line ending |
| SET_HTTP_MODE | `$4D` | 2 | 0 body, 1 collect, 2 get, 3 set headers, 4 POST data |
| SEEK / TELL | `$25` / `$26` | 1 / 0 | four-byte offset |
| TRANSLATION / SET_EOL / SET_INT_RATE | `$54` / `$4C` / `$5A` | | |
| RENAME, DELETE, LOCK, UNLOCK, MKDIR, RMDIR | `$20`–`$2B` | 2 | payload the devicespec |
| CHDIR / GETCWD | `$2C` / `$30` | 0 | |
| ACCEPT / CLOSE_CLIENT | `$41` / `$63` | 0 | TCP server |
| GET_REMOTE / SET_DESTINATION / USERNAME / PASSWORD | `$72` / `$44` / `$FD` / `$FE` | 0 | |

### Disk `$31`–`$38`, printer `$40`, clock `$45`, modem `$50`

Clock replies, measured: GETTIME `$93` 6 bytes (D, M, Y, H, M, S); `$54` 7
bytes; GET_ISO_LOCAL `$49` / GET_ISO_UTC `$5A` 25 bytes with the NUL; ProDOS
`$50` 4; SOS `$53` 19; `$4D` 8; zone name `$47`, its length `$4C`; `$9A`
GETTIME in the alternate zone. `$74` sets the adapter's zone, `$99` the
alternate. Disk READ/WRITE/PUT `$52`/`$57`/`$50` (one sector-number
parameter), STATUS `$53`; printer WRITE `$57`; modem STATUS/WRITE/STREAM
`$53`/`$57`/`$58` and seven configuration commands.

### The cartridge itself

Registers `$14` SLICE_ACK, `$15` TV, `$16` HSC (0 off, 1 on, 2 forget, 3
install). One-shots (the loader's): `$0DFE` SWAP, `$0DFD` GO, `$0DFC` CONFIG,
`$0DFB` GO_BIOS. Leave with `JMP $0600` (boot the armed image) or `JMP $0603`
(CONFIG), after `SEI` and `$7F` to `CTRL`. POKEY at `$0450`: RANDOM is the
only live read; no interrupts. Board layouts at `$0C14`: 0 ROM, 1 ROM+POKEY,
2 SuperGame, 3 SG+POKEY, 4 SG+RAM, 5 SG 9-bank, 6 RAM, 7 Absolute, 8
Activision, 9 HSC.

## Battleship

The merged 7800 port (`fujinet-battleship` `87b8cc7`): a shared game, and a
7800 layer of `graphics.c`, `input.c`, `osk.c`, `sound.c` (POKEY) and one
`fujinet.c` through which every call reaches the cartridge
(`CUSTOM_FUJINET_CALLS`, because the 7800's `fuji_*` are macros). Each server
request is `network_open`/`network_read`/`network_close` with `bin=1`: the
509-byte game state in binary, one READ. The art is the MS-DOS client's, fitted
into the tile engine's 128 tiles by `mkchr.py`. A local server
(`fujinet-game-system/battleship`, `go run .`) needs MAME in real time:
`THROTTLE=1`.

## CONFIG

`fujinet-config` `atari7800/`: hosts, files, copy, WiFi, info (TV, INPTCTRL,
HSC), boot, lobby, on the tile engine. Draws straight out of the reply window;
`fujiraw.c` streams the payloads assembled from pieces. Baked into the
firmware with `build-cart.sh --bake`.

## Things that cost real time

- MARIA's DMA windows (280–420 ns) are too short for a microcontroller: a real
  SRAM serves the game, and nothing MARIA reads may live in the mailbox.
- Only the first INPTCTRL lock counts.
- MAME hides the BIOS's reads; mode changes are write-triggered.
- 7800basic's silent miscompiles (index and `for`-bound expressions).
- ITC Eras's cap height is wrong in the font files (`tools/fixeras.py`).
- Game servers count real seconds: `THROTTLE=1`.
- The clock's command names mislead; measured replies above.
- A font in a switched bank breaks the picture while the program waits.

## Troubleshooting

| Symptom | Cause |
|---|---|
| `fn_go` returns `$FD` | No magic at `$0C09`: not a FujiNet cartridge, or no claim (GAME mode) |
| Every transaction after the first: no answer | Your own sequence counter; use ACKSEQ + 1 |
| ERR 2 on network | Wait longer (90 s budget); check the server |
| REPLY_CMD `$15` | Command not on this build, or wrong parameter shape |
| OPEN_APPKEY times out | Missing the sixth, reserved byte |
| Reply text shows as garbage | MARIA reading the mailbox; copy to RAM |
| BASIC copies wrong bytes | Expression in an array index |
| BOOT_STATE `$80` | BOOT_ERR: 1 too big, 2 truncated, 3 no layout, 4 store busy |
| Yellow screen after boot | The loader's stores below `$1000` don't reach the cartridge |
| Banked app runs as garbage | Claim kind 0 and no `.a78` type: name the layout |

## Sources of truth

| Source | Revision |
|---|---|
| `fujinet-firmware` `pico/atari-7800`, `pico/common`, device dispatch | `07e9bbaa9` |
| fujinet-lib `atari7800` (PR #152) | `1ebf9d0` |
| `fujinet-config` `atari7800/` | `f38ed1d` |
| `fujinet-battleship` | `87b8cc7` |
| 7800basic | `e7c18d2` (v0.41) |
| cc65 | 2.19 |
