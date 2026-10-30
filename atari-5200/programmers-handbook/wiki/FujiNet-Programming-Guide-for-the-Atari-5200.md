# FujiNet Programming Guide for the Atari 5200

The FujiNet programming manual for the Atari 5200: the memory map and the
mailbox the console reaches by reads alone, the text display three ways, living
in 16K, the 6502 library and C with fujinet-lib, the controllers, ten worked
programs in both languages, the command reference, display lists and players,
and walkthroughs of Battleship, 5 Card Stud and CONFIG. This is the wiki
condensation; the full illustrated edition is the PDF in
`atari-5200/programmers-handbook/` of the manuals repository, styled after the
1982 *ATARI 5200 Owner's Manual*.

See also the [FujiNet-Network-Protocol-Handbook](FujiNet-Network-Protocol-Handbook)
for everything the `N:` device can say once you can reach it.

## Contents

- [Your FujiNet cartridge](#your-fujinet-cartridge)
- [Installing the tools](#installing-the-tools)
- [The memory map](#the-memory-map)
- [How the mailbox works](#how-the-mailbox-works)
- [The text display](#the-text-display)
- [Living in 16K](#living-in-16k)
- [The libraries](#the-libraries)
- [Controllers, keypad and sound](#controllers-keypad-and-sound)
- [The programs](#the-programs)
- [Booting another image](#booting-another-image)
- [Banks and the Super Cart](#banks-and-the-super-cart)
- [Command reference](#command-reference)
- [Battleship, 5 Card Stud and CONFIG](#battleship-5-card-stud-and-config)
- [Things that cost real time](#things-that-cost-real-time)
- [Troubleshooting](#troubleshooting)
- [Sources of truth](#sources-of-truth)

## Your FujiNet cartridge

An RP2354B on the cartridge edge answers every read the console makes of the
cartridge, as a ROM would, through a 74HCT541 that only the console's own
cartridge enables can open. Behind it, over USB, an ESP32-S3 runs the FujiNet
firmware (`fujiversal-atari5200`).

The console sees CONFIG at power-on, a mailbox at `$B000`-`$B7FF`, and up to
128K of program served as a plain ROM, a two-chip board, Bounty Bob Strikes Back
or a Super Cart.

**The board is a Rev0 design that has not yet been built.** Everything here ran
in host tests and the MAME cartridge model. The edge has no reset line and no
read/write line; the RESET key is a keypad key.

## Installing the tools

- **cc65 2.19**: `ca65`, `ld65`, `cc65`, `cl65`. cc65's `atari5200` target is
  the C library.
- **fujinet-lib** with the `atari5200` target: `tschak909/fujinet-lib`, branch
  `add-atari5200` (FujiNetWIFI/fujinet-lib PR #139) until it merges;
  `make atari5200`. Its 5200 header `fujinet-atari5200.h` is in
  `bus/atari5200/`: put that on the include path as well as `include/`.
- **MekkoGX**, branch `add-atari5200` (FozzTexx/MekkoGX PR #27): the start-up
  code `atari5200-crt0.s`, the linker configuration `atari5200-fujinet.cfg` and
  the checker `atari5200-romstamp.py`.
- **MAME** with the cartridge: `fujinet-firmware/pico/atari-5200/emu/apply.sh
  mame`, then `make SUBTARGET=a5200 SOURCES=src/mame/atari/atari400.cpp
  REGENIE=1`; run with `-cartslot fujinet`. MAME must run from its own tree for
  `-autoboot_script`. The cartridge dials `FUJINET_TCP` (default
  `127.0.0.1:9995`).
- **fujinet-pc**, the RS232 build (`./build.sh -p RS232`), from firmware new
  enough to know the `.a52` extension.

There is no FujiNet Go for the 5200.

## The memory map

| Address | What |
|---|---|
| `$0000`-`$3FFF` | RAM, 16K |
| `$4000`-`$BFFF` | the cartridge |
| `$C000` | GTIA |
| `$D400` | ANTIC |
| `$E800` | POKEY |
| `$F800`-`$FFFF` | the BIOS |

In the cartridge window a FujiNet program (an APP) has `$4000`-`$AFFF` and
`$B800`-`$BFDF`; the mailbox is `$B000`-`$B7FF`; the claim and the BIOS header
are `$BFE0`-`$BFFF`:

| Address | What |
|---|---|
| `$BFE0` | `"FUJI"`, version 1, board + 1 (0 = from the size), flags 0 |
| `$BFE7` | `$02`: PAL-compatible, for the two-port BIOS |
| `$BFE8` | 20-character title, unseen |
| `$BFFD` | `$FF`: skip the BIOS title screen |
| `$BFFE` | start address |

`MODE` at `$B412`: 0 BOOT (CONFIG), 2 GAME (no claim, no mailbox), 3 APP.

Never store into `$4000`-`$BFFF`; never use a read-modify-write instruction
there; read the hotspot pages only with `LDA`/`LDX`/`LDY`/`BIT` absolute or
absolute-indexed from a page-aligned base; never read one hotspot twice in a
row; never `JMP ($xxFF)`; never point ANTIC at `$B000`-`$B7FF`.

## How the mailbox works

With no read/write line, everything the console sends travels in the address of
a read:

| Address | Read it to |
|---|---|
| `$B000`-`$B3FF` | learn: the reply, up to 1K |
| `$B400`-`$B4FB` | learn: the status page |
| `$B500`+n | say: select register n |
| `$B600`+v | say: set the selected register to v |
| `$B700`+b | say: append the byte b to the TX stream |

Registers: `$00` DEVICE, `$01` CMD, `$02` NPARAM, `$05` DATA_RST, `$06`
RXSLICE, `$10` SEQ, `$11` BOOTLOCK (`$B5`), `$12`/`$13` BOOTSEL (`$B5`, `$4A`),
`$14` CONFIG (`$C5`).

```asm
        ldx     #FN_REG_CMD
        lda     FN_REGSEL,x     ; select register $01
        ldy     #$C4            ; GET_ADAPTERCONFIG_EXTENDED
        lda     FN_REGDATA,y    ; ...and set it
```

The TX stream is NPARAM × {size 1/2/4, value low first}, then the payload; 320
bytes, at most 8 parameters. Launch with SEQ = `ACKSEQ` + 1 (255 wraps to 1);
the cartridge paints the reply, `ERR` (`$B402`), `REPLYCMD` (`$B403`, `$06`
ACK) and `RXLEN` (`$B404`), and copies SEQ into `ACKSEQ` (`$B400`) last. The
count starts over at 0 at every power-on and hand-over. Budgets: 5 s, 60 s for
MOUNT_IMAGE and COPY_FILE, 90 s for the network device's OPEN/CLOSE/STATUS/READ.

## The text display

ANTIC mode 2, 40 × 24, from a 1K-aligned font in ROM. `fujidisp.s` (assembly,
screen at `$1000`) and CONFIG's `antic.c` (C, screen at `$3C00`) draw the same
screen from the same font. cc65's own conio is a 20 × 24 mode-6 screen at
`$3E20`: link with `__RESERVED_MEMORY__` of at least `0x1E0`, or the C stack
lands on it. Set the BIOS shadows (`SDLSTL/H` `$05/$06`, `SDMCTL` `$07`,
`COLOR0-4` `$0C-$10`); the VBI copies them.

## Living in 16K

Zero page `$00`-`$18` is the BIOS's layout (POKMSK, RTCLOK, CRITIC, ATRACT,
display and colour shadows, PADDL0-7); both start-up files keep it. Vectors at
`$0200`-`$021B`. Assembly: KEY at `$19`, the library at `$E0`-`$ED`, BSS from
`$0300`, the screen at `$1000`; `a52.cfg`'s ZEROPAGE starts at `$19`, on top of
KEY, so put variables in BSS. C: zero page from `$1D`, RAM from `$021C`, a 1K
stack under the reserved top. A hand-over clears all of RAM; keep what must last
in an appkey.

## The libraries

**Assembly** (the bring-up's `testrom/`): `fn_beg` (DEVICE/CMD/NPARAM from
`FN_DEV`/`FN_CMD`/`FN_NPR`, rewinds TX, `FN_TMO` = 12 s), `fn_pb`, `fn_pw`,
`fn_txb` (**takes its byte in Y**: count string loops in X), `fn_path` (256-byte
padded), `fn_go` (launch and wait, frames counted by the VBI; returns ERR or
`$FF`), `fn_ack` (`$EE` on NAK), `fn_boot`, `fn_config`.

**C**: fujinet-lib's usual `fuji_*`, `network_*`, `clock_*`, plus
`fujinet-atari5200.h`: `fuji_a5200_present()`, `fuji_a5200_boot_state()` and
friends, `fuji_a5200_boot()`, `fuji_a5200_config()`, `fuji_a5200_key`,
`fn_default_timeout`, `fn_device_error`. Below it, `fn_regwr()`, `fn_tx()`,
`fn_commit()`. cc65's Atari targets compile `'\n'` as `$9B`: spell out
`0x0A`/`0x0D`. cc65 drops an inline `lda` whose value is unused: switch banks in
assembly.

## Controllers, keypad and sound

| Part | Read from |
|---|---|
| Stick | `PADDL0` (X) / `PADDL1` (Y) for controller 1, 114 at rest |
| Bottom (fire) button | GTIA `TRIG0` `$C010`, 0 while held |
| Top button | POKEY `SKSTAT` bit 3 `$E80F`, clear while held |
| Keypad | POKEY `KBCODE` by interrupt: `KEY` / `fuji_a5200_key` = code + 1 |

Key codes: 0-9, `$0A` *, `$0B` #, `$0C` START, `$0D` PAUSE, `$0E` RESET.
**Write `$04` to `CONSOL` (`$C01F`) before reading the stick**: bit 2 turns the
pots on, nobody else sets it, and MAME does not model it. The keypad runs with
POKEY's debouncing off, so a held key interrupts on every scan: count it once,
then ignore it for four frames. POKEY sound: `AUDF1`/`AUDC1` at
`$E800`/`$E801`, `$A8` a pure tone at volume 8.

## The programs

Ten programs, each in ca65 assembly and in C, all verified in MAME against a
running fujinet-pc (`emu/verify.sh`, 20/20):

| Program | Shows |
|---|---|
| hello | the screen, the frame counter, the keypad, the cartridge's magic |
| first contact | GET_ADAPTERCONFIG_EXTENDED: SSID, IP, firmware |
| pads | stick, both buttons, keypad, a POKEY tone |
| netget | an HTTP GET through N: |
| netcat | a TCP conversation, with an on-screen keyboard |
| dir | a directory on the SD card |
| boot | push an image into the cartridge and hand over |
| appkey | the shared player name, and a key of our own |
| clock | local time and UTC |
| bank | a 64K Super Cart: transactions from both banks |

## Booting another image

MOUNT_HOST `$F9`, SET_DEVICE_FULLPATH `$E2` (device, host, mode, 256-byte path),
MOUNT_IMAGE `$F8` (60 s): the FujiNet pushes the file (`.a52` or `.bin`; a
`.cfg` sibling's `mapper=` line chooses the board). Watch BOOTSTATE `$B406`
(2 ready, `$80` failed, BOOTERR `$B408` says why) and BOOTPCT `$B407`. Then:
BOOTLOCK = `$B5`, wait for ARMED `$B41C`, quiet the machine (interrupts, DMA,
chips and RAM to 0), `JMP $B5F0`: the cartridge serves `JMP ($FFFC)` there and
swaps the image in on the read of its last byte, so the BIOS starts it as at
power-on. `fn_boot` / `fuji_a5200_boot()`. Back to CONFIG: register `$14` =
`$C5`, then the same hand-over (`fn_config` / `fuji_a5200_config()`).

## Banks and the Super Cart

64K or 128K in 32K banks, switched by reads: `$BFE0`-`$BFFF` the last bank (the
power-on bank), `$BFD0`/`$BFD4`/`$BFD8`/`$BFDC` banks 0-3. Use `BIT`. The claim at
`$BFE0` is itself a hotspot. Keep everything that runs or is read by ANTIC
during a switch identical in every bank: the handbook's programs give each bank
only `$A000`-`$AFFF` of its own.

## Command reference

The FUJI device `$70` (54 commands), the network devices `$71`-`$78` (29),
disk `$31`-`$38`, printer `$40`, clock `$45` and modem `$50`, each with a card
and examples in both languages, checked against the firmware's dispatch tables
by `tools/cmdcheck.py`. See the PDF.

## Battleship, 5 Card Stud and CONFIG

Both games are one program for every client with a 5200 layer
(`src/atari5200/`): ANTIC mode 4 in the top 4K of RAM
(`__RESERVED_MEMORY__=0x1000`), input folded into key codes, POKEY sound,
fujinet-lib for the network and appkeys. The server address comes from appkey
creator 1, app 1, key 5 (Battleship) or key 1 (5 Card Stud), as `server?query`.
CONFIG (`fujinet-config/atari5200/`) is a 32K APP in C baked into the cartridge;
it launches MOUNT_IMAGE without waiting so its progress bar moves during the
push. The games and CONFIG currently build against fujinet-lib-experimental's
`atari5200` target.

## Things that cost real time

- A held keypad key counts many times (debouncing off).
- The stick needs `CONSOL` bit 2; MAME does not care.
- No read/write line: a store into the window fights the bus.
- Two reads of one address in a row can merge on the four-port console.
- An old fujinet-pc does not know `.a52`, says yes to MOUNT_IMAGE and pushes
  nothing.
- `fn_txb` takes its byte in Y.
- cc65 reads `'\n'` as `$9B`.
- `a52.cfg`'s zero page starts on top of KEY.
- cc65's conio screen is where the C stack goes.
- fujinet-lib #139's 5200 header is outside `include/`.

## Troubleshooting

Check `ERR` (`$B402`) and `REPLYCMD` (`$B403`) first. ERR 1: no link. ERR 2:
the FujiNet took longer than the budget. ERR 3: a parameter size other than
1, 2, 4. `$FF` from `fn_go`: the hotspot reads went wrong, or SEQ repeated. NAK:
the command was refused. BOOTSTATE stuck at 0: not a cartridge image, or an old
fujinet-pc. No mailbox after a boot: no claim, or a two-chip/Bounty Bob image.

## Sources of truth

| What | Where |
|---|---|
| Cartridge, library, test programs | fujinet-firmware `pico/atari-5200`, `pico/common` @ `7a53805c8` |
| Command dispatch, fujinet-pc | fujinet-firmware @ `f0b62cb09` |
| fujinet-lib atari5200 | tschak909/fujinet-lib `add-atari5200` @ `7cf47dc` (PR #139) |
| Start-up, cfg, romstamp | tschak909/MekkoGX `add-atari5200` @ `faeb3fd` (PR #27) |
| CONFIG | fujinet-config main @ `1bd6ec8` |
| Battleship | fujinet-battleship main @ `3f2a548` |
| 5 Card Stud | fujinet-5cardstud main @ `d5db857` |
| cc65 | V2.19 `92fa7cb23` |
