# FujiNet Programming Guide for the Emerson Arcadia 2001

The FujiNet programming manual for the Emerson ARCADIA-2001: the memory map
and the mailbox the console reaches by reads alone, the 2637's text display,
living in 288 bytes, the 2650 library and the 2650's 8K pages, the hand
controllers and the tone, eleven worked programs in 2650 assembly (a NetCat
among them), the command reference, programs bigger than 8K (protocol 2), the
2637 up close, and how Battleship, 5 Card Stud and CONFIG are built. This is
the wiki condensation; the full illustrated edition is the PDF in
`arcadia/programmers-handbook/` of the manuals repository, styled after the
1982 Emerson *ARCADIA-2001 Owner's Manual*.

See also the [FujiNet-Owners-Manual-for-the-Emerson-Arcadia-2001](FujiNet-Owners-Manual-for-the-Emerson-Arcadia-2001)
for the player's side, and the
[FujiNet-Network-Protocol-Handbook](FujiNet-Network-Protocol-Handbook) for
everything the `N:` device can say.

## Contents

- [Your FujiNet cartridge](#your-fujinet-cartridge)
- [Installing the tools](#installing-the-tools)
- [The memory map](#the-memory-map)
- [How the mailbox works](#how-the-mailbox-works)
- [The text display](#the-text-display)
- [Living in 288 bytes](#living-in-288-bytes)
- [The 2650 library](#the-2650-library)
- [Pages, blocks and pointers](#pages-blocks-and-pointers)
- [Hand controllers and sound](#hand-controllers-and-sound)
- [The programs](#the-programs)
- [Bigger than 8K: protocol 2](#bigger-than-8k-protocol-2)
- [The 2637 up close](#the-2637-up-close)
- [Command reference](#command-reference)
- [Battleship, 5 Card Stud and CONFIG](#battleship-5-card-stud-and-config)
- [Things that cost real time](#things-that-cost-real-time)
- [Sources of truth](#sources-of-truth)

## Your FujiNet cartridge

Two chips. The **game chip**, an RP2354A, answers every read the console's
Signetics 2650 makes: it serves your program as a mask ROM would, and a
mailbox beside it. The **network chip**, an ESP32-S3, is the FujiNet itself,
running the firmware's `fujiversal-arcadia` build (`BUILD_RS232`) and talking
to the game chip over USB. CONFIG is baked into the game chip and served at
power-on. The cartridge's RESET restarts both chips; it is the only way back
to CONFIG from a program.

Assembly is the only language: no compiler has ever targeted the Arcadia. No
cartridge has been built yet; everything was run on the FujiNet MAME model of
the cartridge, which compiles the cartridge's own firmware sources.

## Installing the tools

- **Macroassembler AS** (1.42 build 306), `CPU 2650`: `asl` and `p2bin`.
- **Python 3** for the cartridge's `mkimage.py`, `checkrom.py` and
  `checkdepth.py`.
- **MAME** with the cartridge grafted in: `pico/arcadia/emu/apply.sh
  ~/Workspace/mame`, then `make REGENIE=1` (or `SUBTARGET=arcadia
  SOURCES=src/mame/arcadia/arcadia.cpp`). No BIOS: the console has none.
- **fujinet-pc** from the firmware's RS-232 build, with `[BOIP] enabled=1`.

```
FUJINET_TCP=127.0.0.1:9963 ./mame arcadia -cartslot fujinet -cart hello.bin
```

Always set `FUJINET_TCP`; unset it means `127.0.0.1:9995`. One MAME to one
fujinet-pc. MAME's left keypad is the numeric pad (CLEAR `-`, ENTER `+`), the
disc the arrows, START/SELECT/OPTION `1`, `5`, `O`.

The build is the firmware's: `asl -q -L`, `p2bin -r $0000-$2FFF -l 0`,
`mkimage.py` folds the two 4K blocks into the 8,192-byte image, `FUJI` is
stamped at image `0x1CFC`, then `checkrom.py`.

## The memory map

| Console | Is |
|---|---|
| `$0000-$0FFF` | cartridge block 1 (image `0x0000-0x0FFF`) |
| `$1000-$17FF` | nothing |
| `$1800-$1AFF` | the 2637, the screen, the RAM, the controllers |
| `$2000-$2FFF` | cartridge block 2 (image `0x1000-0x1FFF`); the mailbox at `$2B00` |
| `$4000`, `$6000` | aliases of the blocks (A14 is not on the connector) |
| `$3000`, `$5000`, `$7000` | read `$FF` |

The connector carries A0-A13, D0-D7, +5 V and ground: no write strobe, no
clock, no reset. A12 is the chip select. A client has 6,912 bytes: `$0020` to
`$0FFF` and `$2000` to `$2AFF`. The header is `BCTA,UN START` at `$0000` and a
`RETC,UN` guard at `$0003`. The claim, `FUJI` at `$2CFC`, keeps the mailbox
alive when the image boots; an image without it kills the mailbox for the
session.

## How the mailbox works

Writing is reading:

| Read | Sends |
|---|---|
| `$2D00`+n | REGSEL: arm register n |
| `$2E00`+v | REGDATA: the armed register = v |
| `$2F00`+b | append b to the TX stream |

Registers: DEVICE `$00` (`$70` Fuji, `$71-$78` N:, `$45` clock), CMD `$01`,
NPARAM `$02`, DATA_RST `$05`, RXSLICE `$06`, SEQ `$10`, BOOTLOCK `$11`.
The TX stream is NPARAM × (size 1/2/4, value low first), then the payload;
320 bytes at most.

Writing SEQ launches. The game chip sends the request over USB, paints the
reply at `$2B00` (256 bytes a slice, up to four slices) and the status page
at `$2C00`, and ACKSEQ last:

| At | Holds |
|---|---|
| `$2C00` | ACKSEQ |
| `$2C01` | bit 0 link up |
| `$2C02` | ERR (0 ok) |
| `$2C03` | `$06` ACK / `$15` NAK |
| `$2C04` | RXLEN |
| `$2C06-$2C08` | boot state, percent, error |
| `$2C09` | `F`, `N` |
| `$2C0B` | protocol version, 2 |
| `$2C0C` | SLICE_ECHO |
| `$2C0E` | 60 Hz tick |

Rules:

- **SEQ = ACKSEQ + 1**, 255 then 1, never a counter of your own: the
  console's RESET does not reset the cartridge.
- **Wait as long as the cartridge may**: 5 s, 60 for MOUNT_IMAGE and
  COPY_FILE, 90 for a network channel's OPEN, STATUS, READ and CLOSE. The
  runtime's `FNCOMMIT` gives up after about 6 s; the handbook's `FNGO` keeps
  polling the same SEQ for 90 more. Never launch again after a timeout of
  your own.
- In MAME a transaction completes inside the read that writes SEQ, so a
  program that waits too little works there.

Page-0 code (block 1) reaches the mailbox through big-endian pointer words:

```
FNREGWR:
        LODA,R0 *FSELP,R1       ; arm the register
        LODA,R0 *FDATP,R2       ; deliver the value
        RETC,UN
```

## The text display

13 rows of 16 cells at `$1800-$18CF`; a byte is two colour bits and a 6-bit
glyph. The glyphs are not ASCII: `$10-$19` digits, `$1A-$33` A-Z,
`$34-$37` `. , + $`, `$38-$3F` the eight user-defined characters, `$01-$0F`
graphics. No lowercase, no `/ - _ :` (`fujidisp.inc` loads them as UDCs).

`$19F9`: bit 7 character height (set 8 × 8: the 13 rows fill only the top
half; clear 8 × 16, as CONFIG), bit 6 the pot multiplexer, 3-5 character
colour, 0-2 screen colour (0 white ... 7 black). A cell of exactly `$C0`
switches the rest of its row to block graphics.

`DPRINT` prints `(DSTRP)` from cell R2 + 1 (the auto-increment store), and
can print straight out of the reply window.

## Living in 288 bytes

`$18D0-$18EF` (32), `$18F8-$18FB` (4) and, in the 13-row mode, `$1A00-$1AFF`
(256). The runtime keeps `FSTRP` at `$18EB` and `DSTRP` at `$18ED`, and the
boot stub at `$18E0-$18EA` during a swap. CONFIG uses all 292 bytes. The
2650's return addresses are on the chip, so there is no stack. Read the reply
window in place rather than copying it; copy what must outlive the next
transaction first. Nothing clears the RAM at a RESET.

## The 2650 library

`fujilib.inc`: `FNREGWR`, `FNSTART`, `FNPARB`, `FNTXSTR`, `FNPATH` (256-byte
padded), `FNCOMMIT`, `FNSLICE`, `FNCHECK`, and the pointer words.
`fujidisp.inc`: `DINIT`, `DCLS`, `DXLAT`, `DPRINT`, `DHEX`, `SCAN`, `GETKEY`.
The handbook adds `FNBEGIN`/`PUTS` macros, `FNPARW`, `FNTXN`, `FNGO`,
`BKINIT`, `WAITF`, `DREPLY`, `FAIL`, and the N: routines `NOPEN`, `NSTAT`,
`NREAD`, `NWRITE`, `NCLOSE`.

Conventions: R0 data, R1/R2 arguments, R3 a counter; `LPSL $02` (COM: logical
compares); a load sets CC, a store does not. The return stack is eight deep:
the firmware's `checkdepth.py` counts calls only, one node a label, and so
misses fall-through and branches; the handbook's `depthcheck.py` counts them
and agrees with the games' hand audits.

## Pages, blocks and pointers

A load, store or ALU instruction reaches only its own 8K page; branches and
indirect addresses carry 15 bits; the pointer word itself must be in the
instruction's page. Block 1 is page 0 (with the RAM and the 2637), block 2
page 1 (with the mailbox). AS stops a build that breaks the rule ("target not
on same page"). Use `DWBE`, not `DW`, for pointers: the 2650 reads them high
byte first. `ZBSR`/`ZBRR` reach `$0000-$003F` from any page; CONFIG keeps 30
vectors there and saves about 180 bytes.

Traps: `EORZ R1` is R0 XOR R1 into R0; indexed instructions move R0; CC after
a call is the callee's last; `BCTA` and `BCFA` differ by one letter.

## Hand controllers and sound

| Left | Right | bit 3 | bit 2 | bit 1 | bit 0 |
|---|---|---|---|---|---|
| `$1900` | `$1904` | 1 | 4 | 7 | CLEAR |
| `$1901` | `$1905` | 2, Action | 5 | 8 | 0 |
| `$1902` | `$1906` | 3 | 6 | 9 | ENTER |

The Action buttons are the keypad's 2: one wire. `$1908`: START bit 0, OPTION
bit 1, SELECT bit 2. The discs are pots, valid only in the vertical blank:
`$19FF` left, `$19FE` right, vertical with `$19F9` bit 6 clear and horizontal
with it set; up/left near `$00`, down/right near `$FF`. Read one axis a frame
and decide from both kept values. Tone: `$18FD` bits 0-6 pitch
(f = 15,734 / (2 (n + 1)) Hz), `$18FE` bits 0-2 loudness, 3 tone on, 4 noise.

## The programs

| Program | Does |
|---|---|
| hello | the 64 glyphs, a UDC, the keypad columns |
| fujitest | GET_ADAPTERCONFIG_EXTENDED: SSID, version, IP |
| pads | both keypads, both discs, the buttons, a tone per key |
| netget | an HTTP GET through N:, STATUS until it settles, READ, CLOSE |
| netcat | a TCP line terminal; characters from a disc-turned wheel |
| fujidir | MOUNT_HOST, OPEN_DIRECTORY (256 bytes), READ_DIR_ENTRY to `$7F $7F` |
| fujiboot | MOUNT_HOST, SET_DEVICE_FULLPATH, MOUNT_IMAGE, BOOTLOCK, the swap |
| appkey | the shared player name, and a key of our own |
| clock | SETTZ_ALT, then GET_ISO_LOCAL and GET_ISO_UTC |
| sprites | colours, block graphics, the box glyphs, two sprites and their collisions |
| fujibank | protocol 2: pages, cartridge RAM, the tick |

All eleven pass `emu/verify.sh` in MAME against the book's bench.

The boot swap: write BOOTLOCK = `$B5`, copy the 11-byte stub
`20 92 93 0C 98 E9 1F 00 00 2D FE` to `$18E0` and jump to it; it reads `$2DFE`
through a pointer at `$18E9` and jumps to `$0000` of the new image.

## Bigger than 8K: protocol 2

An APPBANK image is 8,192 + k × 2,048 bytes (k = 1-31, at most 71,680) with
the claim. Console `$0800-$0FFF` is a window on one 2K page; a read of
`$2D80`+n selects page n, from fixed code. 1K of cartridge RAM at
`$0600-$07FF` and `$2900-$2AFF` reads as ROM and is written by reads:
REGSEL `$14-$17` + REGDATA v sets the pointer, REGSEL `$18` then one REGDATA a
byte, a bare REGSEL `$14` to close. The tick at `$2C0E/F` counts 60 Hz (read
HI, LO, HI). Never store into cartridge space: there is no R/W line, and on a
console that is a bus fight. M.U.L.E. (51,200 bytes) is the reason protocol 2
exists.

## The 2637 up close

Multicolour mode (`$18FD` bit 7) gives each cell its own background. `$C0`
starts block graphics (3 × 2 blocks a cell); `$19F8` bit 7 makes the whole
screen graphics, bit 6 adds the lower screen at `$1A00` (26 rows, and only 84
bytes of RAM). Glyphs `$04-$0B` are a box-drawing kit. Four sprites: images
are UDCs `$38-$3B`; positions `$18F0-$18F7` (vertical = 256 - line,
horizontal = 43 + pixel); colours and sizes `$19FA-$19FB`; collisions `$19FC`
(with characters) and `$19FD` (with each other), 0 for a hit, read in the
blank.

## Command reference

The network chip runs the RS-232 build, so the commands are the other RS-232
carts': the Fuji device's 54 (WiFi, hosts, mounting, directories, COPY_FILE,
app keys, hashes, base64, QR codes), the network device's 29, disk, printer,
clock (12) and modem. Notable edges: SET_SSID wants a parameter and exactly
97 bytes; OPEN_DIRECTORY and SET_DEVICE_FULLPATH 256; OPEN_APPKEY six,
reserved byte included; READ_DIR_ENTRY at least 36 so a folder keeps its `/`;
COPY_FILE's hosts count from 1; RANDOM_NUMBER and UNMOUNT_HOST are NAKed on
this build.

## Battleship, 5 Card Stud and CONFIG

- **Battleship**: 26-row multicolour; two framed boards fill the screen;
  both disc axes, one a frame from a cache; network code in block 2 where the
  mailbox is direct; the screen itself is the occupancy map for placing ships.
- **5 Card Stud**: the same library; the table's state (154 + 33 a player) is
  walked a byte at a time with `RXNEXT`, crossing slices; the length must be
  exact before a byte is believed.
- **CONFIG**: 6,501 of 6,912 bytes, thanks to zero-page vectors and the block
  split; all 292 bytes of RAM; screens entered by branches (the 2650's stack
  is a ring, so abandoned frames are harmless); the boot waits on progress,
  not a fixed time. Baked into the firmware with `build-cart.sh --bake`.

## Things that cost real time

- MAME's `machine.time.seconds` is an integer: count frames.
- Unthrottled MAME outruns the network: `THROTTLE=1` for live servers.
- `pgrep -f` matches its own shell: kill by pid.
- Game servers keep their tables between tests; restart them. Battleship's
  READY toggles.
- AS: parenthesise macro arguments; macros before their callers; `&&` binds
  tighter than comparisons; `DWBE` not `DW`; never `p2bin -s`.
- The pots are good only in the vertical blank; the mux shares `$19F9`.
- `DINIT`'s 8 × 8 characters fill half the picture.

## Sources of truth

| What | Where | Revision |
|---|---|---|
| Cartridge firmware, runtime, tools, MAME device | fujinet-firmware `pico/arcadia`, `pico/common` | `e3923e881` |
| CONFIG | fujinet-config `arcadia/` | `6f0a60a` |
| Battleship | fujinet-battleship `arcadia/` | `3f2a548` |
| 5 Card Stud | fujinet-5cardstud `arcadia/` | `d5db857` |
| Game servers | FujiNetWIFI/servers `fujinet-game-system` | `0945622` |
| Macroassembler AS | | 1.42 Beta, build 306 |
