# FujiNet Programming Guide for the RCA Studio II

The FujiNet programming manual for the RCA Studio II: the memory map and the
mailbox the console writes to by reading, the cartridge's text display, living
in 512 bytes, the 1802 runtime, far calls across the cartridge's pages, the
keypads and the beeper, eleven worked programs in CDP1802 assembly (a netcat
among them), the command reference, glyphs, tiles and mosaics, and walkthroughs
of Battleship, 5 Card Stud and CONFIG. This is the wiki condensation; the full
illustrated edition is the PDF in `studio2/programmers-handbook/` of the
manuals repository, styled after the 1977 *RCA Studio II Owner's Manual*.

See also the [FujiNet-Network-Protocol-Handbook](FujiNet-Network-Protocol-Handbook)
for everything the `N:` device can say once you can reach it.

## Contents

- [Your FujiNet cartridge](#your-fujinet-cartridge)
- [Installing the tools](#installing-the-tools)
- [The memory map](#the-memory-map)
- [How the mailbox works](#how-the-mailbox-works)
- [The text display](#the-text-display)
- [Living in 512 bytes](#living-in-512-bytes)
- [The 1802 runtime](#the-1802-runtime)
- [Pages and far calls](#pages-and-far-calls)
- [Keypads and sound](#keypads-and-sound)
- [The programs](#the-programs)
- [Command reference](#command-reference)
- [Battleship, 5 Card Stud and CONFIG](#battleship-5-card-stud-and-config)
- [Things that cost real time](#things-that-cost-real-time)
- [Troubleshooting](#troubleshooting)
- [Sources of truth](#sources-of-truth)

## Your FujiNet cartridge

An RP2354B answers every read the CDP1802 makes, in software: it serves the
program, the 64 x 128 picture the 1861 fetches by DMA, and the mailbox. Behind
it, over USB, an ESP32-S3 runs the FujiNet firmware's RS-232 build
(`fujiversal-studio2`). CONFIG is built into the cartridge and served at
power-on.

**No cartridge has been built yet.** Everything here ran in the FujiNet MAME
model of the cartridge, which compiles the cartridge's own firmware sources,
against `fujinet-pc` built from the same revision.

## Installing the tools

- **Macroassembler AS** 1.42 (`asl`), run with `-U` (case-sensitive). One `-i`
  with a colon-separated list of *relative* paths: a second `-i` replaces the
  first, and a long absolute list is cut short silently.
- **Python 3** for `checkrom.py`, `mkst2.py` and `st2.py` (firmware
  `pico/studio2/tools/`).
- **MAME** with the cartridge: `fujinet-firmware/pico/studio2/emu/apply.sh
  mame`, then `make SUBTARGET=studio2 SOURCES=src/mame/rca/studio2.cpp
  REGENIE=1 NOWERROR=1`. `FUJINET=1` serves CONFIG; `FUJINET_BOOT=x.st2`
  serves an image from power-on; **always set `FUJINET_TCP`** (unset, the
  model tries 127.0.0.1:9995). MAME must run from its own tree for
  `-autoboot_script`.
- **fujinet-pc**: `./build.sh -p RS232` in the firmware; BoIP on in
  `fnconfig.ini`. One MAME at a time per fujinet-pc.
- MAME keys: keypad A is Q W E / A S D / Z X C, left Alt for 0; keypad B the
  numeric pad; F3 is CLEAR.

## The memory map

| Range | What |
|---|---|
| `$0000-$03FF` | BIOS ROM |
| `$0400-$07FF` | cartridge: the runtime from `$0400`; `"FUJI"` at `$07FC` claims the mailbox |
| `$0800-$09FF` | console RAM, 512 bytes, all the program's |
| `$0A00` | cartridge, a program may use it |
| `$0B00` | the park page: RF rests here |
| `$0C00-$0FFF` | cartridge: the program's code starts here |
| `$x000-$x3FF` | never (x = 1-F): the BIOS may answer there too |
| `$x400-$xFFF` | cartridge, x = 1-D |
| `$E400-$E7FF` | the reply window (1K) |
| `$E800` | the status page |
| `$E9`, `$EA`, `$EB` | mailbox hotspots: REGSEL, REGDATA, TX |
| `$EC`-`$EF` | text engine hotspots: cursor, PUTC, op, parameter |
| `$F400-$FFFF` | the picture, served by position: **never read it** |

An image is an ST2 file: a 256-byte header (`"RCA2"`, block count, title, the
page each block goes to) and up to 64 blocks of 256 bytes, 16,640 bytes in all.
Without the claim the image is a *game*: no mailbox, and only power-off gets
back to CONFIG.

## How the mailbox works

The edge has **no write strobe**: the console writes by reading. A read of
`$E900+n` then `$EA00+v` sets register n to v; a read of `$EB00+b` appends b to
the TX stream (320 bytes). Hotspots read `$FF`. RF is the pointer, read only
with `LDN`, parked on page `$0B` between hotspot reads.

| Register | No. | Value |
|---|---|---|
| DEVICE | `$00` | `$70` FUJI, `$71`-`$78` network, `$45` clock ... |
| CMD | `$01` | the command |
| NPARAM | `$02` | parameters, at most 8 |
| DATA_RST | `$05` | any: the TX stream starts over |
| SEQ | `$10` | ACKSEQ + 1, skipping 0: launch |
| BOOTLOCK | `$11` | `$B5`: arm a staged image |
| CONFIG | `$14` | `$C5`: stage CONFIG and arm it |

Parameters go as size (1, 2 or 4) then value, low first; then the payload. The
cartridge paints the reply at `$E400`, the status page at `$E800` (ACKSEQ
`+$00` last, STAT `+$01`, ERR `+$02`, REPLYCMD `+$03`, RXLEN `+$04`, BOOT_STATE
`+$06`, MAGIC `'F','N'` `+$09`, MODE `+$12`, ARMED `+$1C`, SWAPS `+$23`).

**Sequence numbers** come from the cartridge's ACKSEQ + 1, never a counter in
RAM: CLEAR keeps ACKSEQ (the next is 2), power-off resets it (the next is 1).

**Timeouts**: the cartridge allows 5 s, 60 s for MOUNT_IMAGE and COPY_FILE, 90 s
for a network channel's OPEN, STATUS, READ and CLOSE. The runtime waits 12 s by
default (`V_TMO`, set by `fn_beg`); raise it *above* the cartridge's limit after
`fn_beg`, or a retry reuses the same SEQ and is ignored.

```
        FNBEGIN NETDEV, NCOPEN, 2
        LDI     NMREAD
        FCALL   fn_pb
        LDI     NTRNONE
        FCALL   fn_pb
        LDR     R8, url
        FCALL   fn_str
        SLOW    95              ; past the cart's 90
        FCALL   fn_go
        BNZ     failed
```

## The text display

The cartridge serves a 64 x 128 picture and draws text into it: 16 columns by
10 rows of 4-dot by 12-scanline cells. `$ECrc` moves the cursor, `$EDcc` draws
a character, `$EFvv` pushes a parameter, `$EEop` runs an operation:

| Op | Code | Parameters |
|---|---|---|
| CLS | `$00` | |
| INV_ON / INV_OFF | `$01` / `$02` | |
| CLREOL / SCROLL | `$03` / `$04` | SCROLL: rows 1-9 up, row 9 blank |
| PRINT / PRINT_PAD | `$10` / `$11` | offset lo, hi, max: text straight from the reply window |
| MARQUEE / MQ_OFF | `$20` / `$21` | a too-long PRINT scrolls along its row |
| REPEAT | `$30` | char, count |
| GLYPH | `$40` | code `$80-$9F`, 12 rows, bit 3 the left dot |
| TILE / MOSAIC | `$41` / `$42` | 16 tiles of 2 x 4; cells of 2 x 3 tiles |

Characters `$20-$7F` (lower case as small capitals), `$01-$0B` the suits, a
block, four arrows, "10" and a card back, `$80-$9F` your glyphs. PUTC never
scrolls. Scanlines 120-127 are the cartridge's status strip (the boot progress
bar). On a television a dot is about three scanlines wide.

## Living in 512 bytes

`$0800-$080F` are the runtime's (`V_TMO`, `V_SEQ`, `V_CNT`, `V_LAST`, `V_KTMP`,
`V_KLAST`, `V_KTIME`, `V_T`); the program's start at `V_APP` (`$0810`); the
stack runs down from `$09FF`. The display interrupt saves two bytes *below* R2
at any moment. The reply window is a free 1K of read-only memory until the next
launch.

## The 1802 runtime

From the firmware's `pico/studio2/testrom/`, unchanged: `fujinet.inc`,
`s2macro.inc`, `s2call.inc` (at `ORG 0400H`: the entry the BIOS calls, the
display interrupt, SCRT, the hand-over), `fujilib.inc`, `fujidisp.inc`,
`input.inc`. Registers: R0 DMA, R1 interrupt, R2 stack (X = 2), R3 PC,
R4/R5/R7 call/return/jump (`FCALL`, `FRET`, `FJMP`), R6 link, R8-R9 scratch,
RA-RC yours, RD.0 the beep, RE frames, RF hotspots.

`checkrom.py` refuses: any `$C0-$CF` instruction (3 cycles: a DMA line comes
up a byte short) except the interrupt's one marked `!3CYCLE`; `IDL` (it reads
through R0, which points at the picture); RF with anything but `LDN`. Keep X on
console RAM for `OUT` and `IRX`.

## Pages and far calls

A short branch reaches only its page and long branches are banned: `FIT n`
before every routine that branches (fitcheck measures them), `FJMP` and `FCALL`
across pages. Never fall through into a FIT's gap: `$00` is `IDL`. CONFIG's
`RFIT` also skips `$x000-$x3FF`.

## Keypads and sound

`OUT 2` sends a key number (from M(R(X)), so X points at `V_KTMP`) to the
CD4515; EF3 reads pad A, EF4 pad B. `in_scan` gives the held key (`$A0+k`,
`$B0+k`), `in_get` a fresh or repeating one (24 frames, then every 6). The tone
is Q: the interrupt holds Q on while RD.0 counts down, one per frame
(`LDI 8; PLO RD` beeps).

## The programs

| Program | Does |
|---|---|
| hello | text, symbols, the frame count, a key (bring-up's) |
| fujitest | GET_ADAPTERCONFIG_EXTENDED, printed from the reply window (bring-up's) |
| netget | an HTTP GET: OPEN, STATUS until settled, READ, show, CLOSE |
| fujidir | MOUNT_HOST, OPEN_DIRECTORY, READ_DIR_ENTRY to `$7F,$7F`, CLOSE |
| fujiboot | MOUNT_HOST, SET_DEVICE_FULLPATH, MOUNT_IMAGE, BOOT_STATE, `fn_boot` (bring-up's) |
| appkey | the shared name (creator 1, app 1, key 0), then a key of our own |
| clock | SETTZ (`$74`), then GET_ISO_LOCAL and GET_ISO_UTC |
| keys | both keypads lit, the beeper |
| glyphs | GLYPH, TILE, MOSAIC, REPEAT, inverse |
| pages | one program on fourteen pages |
| netcat | TCP lines both ways: SCROLL, a shadow screen, CONFIG's keyboard |

All eleven run in `emu/verify.sh` against the bench and pass.

## Command reference

The ESP32-S3 runs the RS-232 build; the cards are the same as the 7800's (same
revision). _byte_ = size 1 + value; _word_ = size 2 + two bytes, low first.

### FUJI device `$70`

| Command | Code | nparam | Notes |
|---|---|---|---|
| GET_ADAPTERCONFIG_EXTENDED / _CONFIG | `$C4` / `$E8` | 0 | 240 / 140 bytes; IP text at 140 |
| SCAN_NETWORKS / GET_SCAN_RESULT | `$FD` / `$FC` | 0 / 1 | count; 33-byte SSID + RSSI |
| SET_SSID / GET_SSID | `$FB` / `$FE` | 1 / 0 | byte (ignored, required); exactly 97 bytes |
| GET_WIFISTATUS / GET_WIFI_ENABLED | `$FA` / `$EA` | 0 | 3 = connected |
| RESET, STATUS, DEVICE_READY | `$FF`, `$53`, `$00` | 0, 1, 0 | |
| READ / WRITE_HOST_SLOTS | `$F4` / `$F3` | 0 | 8 x 32 bytes |
| MOUNT_HOST | `$F9` | 1 | host slot |
| READ / WRITE_DEVICE_SLOTS | `$F2` / `$F1` | 0 | |
| SET_DEVICE_FULLPATH | `$E2` | 3 | device, host, mode; 256-byte path |
| MOUNT_IMAGE / UNMOUNT_IMAGE | `$F8` / `$E9` | 2 / 1 | pushes the file into the cartridge; 60 s |
| MOUNT_ALL / SET_BOOT_MODE / CONFIG_BOOT | `$D7` / `$D6` / `$D9` | 0 / 1 / 1 | |
| OPEN_DIRECTORY | `$F7` | 1 | host; 256 bytes: path, NUL, filter |
| READ_DIR_ENTRY | `$F6` | 2 | maxlen (never 31), flags; `$7F,$7F` ends |
| SET / GET_DIRECTORY_POSITION | `$E4` / `$E5` | 1 / 0 | one word |
| CLOSE_DIRECTORY | `$F5` | 0 | |
| COPY_FILE | `$D8` | 2 | hosts from 1; payload `src\|dst` |
| SET / GET_HOST_PREFIX, GET_DEVICE_FULLPATH | `$E1` / `$E0`, `$DA` | 1 | |
| OPEN_APPKEY | `$DC` | 0 | 6 bytes: creator (word), app, key, mode, reserved 0 |
| READ / WRITE / CLOSE_APPKEY | `$DD` / `$DE` / `$DB` | 0 / 1 / 0 | READ: word length + value |
| GENERATE_GUID | `$BB` | 0 | 36 characters |
| HASH, BASE64, QR code | `$C8`-`$C2`, `$D0`-`$C9`, `$BC`-`$BF` | | |

NAK on this build: `$F0`, `$EB`, `$E7`, `$E6`, `$E3`, `$DF`, `$D5`, `$D4`, `$D3`,
`$D2`, `$D1`, `$C1`, `$BA`, `$A0`-`$A9`, `$90`, `$3F`.

### Network devices `$71`-`$78`

OPEN `$4F` (mode 4/8/12/13, translation; payload the devicespec), STATUS `$53`
(two zeros; reply: waiting word, connected, status), READ `$52` (one word),
WRITE `$57` (one word, then the bytes), CLOSE `$43`; SET_PARSER `$FC` (parser
is the *second* byte), PARSE `$50`, QUERY `$51`; SET_PARAMETER `$FB`;
SET_HTTP_MODE `$4D`; SEEK/TELL `$25`/`$26`; TRANSLATION/SET_EOL/SET_INT_RATE
`$54`/`$4C`/`$5A`; file operations `$20`-`$2B`; CHDIR/GETCWD `$2C`/`$30`;
ACCEPT/CLOSE_CLIENT `$41`/`$63`; GET_REMOTE/SET_DESTINATION `$72`/`$44`;
USERNAME/PASSWORD `$FD`/`$FE`. NAK: `$FF`, `$FA`, `$E3`, `$81`, `$80`, `$45`,
`$3F`.

### Disk `$31`-`$38`, printer `$40`, clock `$45`, modem `$50`

Disk: READ/WRITE/PUT `$52`/`$57`/`$50` (sector as one parameter), STATUS `$53`.
Printer: WRITE `$57` (bytes as payload). Clock: GETTIME `$93` (6 bytes),
GET_ISO_LOCAL `$49`, GET_ISO_UTC `$5A` (25 bytes), other formats `$54 $50 $53
$4D $47 $4C $9A` and lower-case alternate-zone twins; `$74` sets the adapter's
zone (and saves it), `$99` the alternate zone. Modem: STATUS/WRITE/STREAM
`$53`/`$57`/`$58` and seven set-up commands.

### The cartridge itself

Every register, status field, error, boot state, text operation and symbol by
its firmware name: see the PDF's "Command Reference: The Cartridge Itself".
`FN_R_LINK` (`$E815`) is not latched; use STAT bit 0.

## Battleship, 5 Card Stud and CONFIG

- **Battleship** (`fujinet-battleship/studio2/`): all four boards on one
  screen as mosaic cells (16 tiles; a square's tile is the game field byte ORed
  with a mark), the family's network rules (CLOSE starts the next request,
  settle STATUS on two agreeing readings above the shortest following state's
  length, check STATUS byte 3 and the reply length), requests streamed into the
  TX stream and never built in RAM.
- **5 Card Stud** (`fujinet-5cardstud/studio2/`): cards as rank + suit cells,
  hole cards as two app glyphs, the shared name app key, a 100 s network wait.
- **CONFIG** (`fujinet-config/studio2/`): baked into the cartridge
  (`baked/fujiconfigrom.h`), 4,152 bytes; a directory page in one
  READ_DIR_ENTRY in block mode; an on-screen keyboard of all of `$20-$7F` that
  the netcat reuses unchanged.

Run the games against your own servers (`fujinet-game-system`, `GO_PROD`
unset), never the public ones, with MAME throttled: the servers' clocks are
real time.

## Things that cost real time

- No write strobe: everything is a read, which is why the mailbox and the text
  engine are hotspot pages.
- A 3-cycle instruction shortens a DMA line (in MAME); the runtime bans them.
- The naive hand-over failed three times in four; it now waits for the bottom
  of a frame.
- MAME's 1802 never runs its reset at power-on; a Lua read of the address space
  fires hotspots.
- In AS `^` is power and `!` is XOR.
- A poll loop that sleeps misses key presses; tests against servers must be
  throttled.

## Troubleshooting

| Symptom | Cause |
|---|---|
| AS cannot open an include that is there | one `-i`, colon-separated, relative paths |
| checkrom refuses a 3-cycle opcode | use a short branch, or `FJMP` |
| "no FujiNet cartridge" | the image lacks `S2CLAIM`; or `FUJINET`/`FUJINET_BOOT` unset |
| `fn_go` returns `$FF` | `SLOW` above the cartridge's limit; or `FUJINET_TCP` unset |
| ERR 2 on OPEN_APPKEY or SET_SSID | the payload is short: 6 / 97 bytes |
| the picture slips | a read of `$F400-$FFFF`, an `IDL`, or a changed interrupt routine |
| keys go missing | the loop sleeps; read the keypads every frame |
| `FAILED 03E02` booting | MOUNT_IMAGE's wait must pass 60 s |

## Sources of truth

| What | Revision |
|---|---|
| fujinet-firmware `pico/studio2`, `pico/common`, RS232 build | 07e9bbaa9 |
| fujinet-config `studio2/` | 86c763d |
| fujinet-5cardstud `studio2/` | 1008f9a |
| fujinet-battleship `studio2/` | 87b8cc7 |
| servers `fujinet-game-system` | 19770c3 |
| fujinet-hardware `RCA-Studio-II/FujiNet-StudioII-Rev0` | 0e539b8 |
