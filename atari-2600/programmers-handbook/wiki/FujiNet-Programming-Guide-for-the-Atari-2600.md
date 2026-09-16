# FujiNet Programming Guide for the Atari 2600

The FujiNet programming manual for the Atari 2600 (Video Computer System): the
cartridge window and the mailbox, the cartridge-composed text display, living in
128 bytes of RAM, the 6502 library and batari Basic on the same mailbox, seven
worked programs in both languages, the command reference, and a walkthrough of
Battleship. This is the wiki condensation; the full illustrated edition is the
PDF in `atari-2600/programmers-handbook/` of the manuals repository, styled after
the 1977 *Video Computer System Owner's Manual*.

See also the [FujiNet-Network-Protocol-Handbook](FujiNet-Network-Protocol-Handbook)
for everything the `N:` device can say once you can reach it.

## Contents

- [Your FujiNet cartridge](#your-fujinet-cartridge)
- [Installing the tools](#installing-the-tools)
- [The cartridge window](#the-cartridge-window)
- [How the mailbox works](#how-the-mailbox-works)
- [The text display](#the-text-display)
- [Living in 128 bytes](#living-in-128-bytes)
- [The 6502 library](#the-6502-library)
- [batari Basic on the mailbox](#batari-basic-on-the-mailbox)
- [The programs](#the-programs)
- [Command reference](#command-reference)
- [Battleship](#battleship)
- [CONFIG](#config)
- [Things that cost real time](#things-that-cost-real-time)
- [Trouble shooting](#trouble-shooting)
- [Sources of truth](#sources-of-truth)

## Your FujiNet cartridge

Two computers in the shell. An RP2040 sits on the cartridge edge and does what
a cartridge does — answers every fetch within the 838 ns the 6507 allows and
serves a 4K window — and, over USB CDC, an ESP32-S3 running the
`fujiversal-rs232` FujiNet firmware carries the WiFi, the SD card and the
protocols. The console never sees the ESP32-S3; it sees sixteen pages of
cartridge memory.

The cartridge edge carries A0–A12, D0–D7, +5V and ground. **No read/write line,
no clock, no reset, and the 6507 has no interrupts.** Both facts shape
everything that follows.

Nothing here needs real hardware: the FujiNet cartridge model in MAME is the
RP2040 firmware's own `fujimail.c` and `vcs_render.c` compiled into MAME, and
it talks to a real `fujinet-pc` over bus-over-IP. Every program in the guide was
verified that way.

## Installing the tools

- **Macroassembler AS** (`asl`, `p2bin`) for the assembly programs — the family's
  assembler. `listings/asm/build.sh` runs the equate check, the assembler, the
  image, the claim stamp and the static check.
- **batari Basic** and **dasm** (2.20.x from `github.com/dasm-assembler/dasm`)
  for the BASIC programs. `export bB=~/Workspace/batari-Basic`;
  `listings/bas/build.sh prog` does the rest.
- **MAME with the FujiNet cartridge**: `fn-2600/pico/atari-2600/emu/apply.sh
  ~/Workspace/mame` then build; the slot option is `-cartslot fujinet`.
  MAME must run from its own tree or `-autoboot_script` is silently ignored;
  set `SDL_VIDEODRIVER=dummy` where there is no display.
- **fujinet-pc-rs232**: `./run-fujinet` in its `build/dist`; bus-over-IP on
  `127.0.0.1:9995`, one client at a time — a stray MAME hangs the next run.
- `emu/run.sh image.bin [harness]` runs a program; `probe.lua`, `txn.lua`,
  `text.lua`, `frames.lua`, `boottest.lua` are the harnesses.

## The cartridge window

The 6507 has thirteen address lines; `$1000`–`$1FFF` selects the cartridge
(and `$F000` is the same place). Sixteen pages for everything:

| Address | Region |
|---|---|
| `$1000`–`$17FF` | 2K banked client code; a store to `$1D80`+bank switches |
| `$1800`–`$1AFF` | six 128-byte text planes, composed by the cartridge |
| `$1B00`–`$1CFF` | the 512-byte reply window (one of two slices) |
| `$1D00`–`$1DFF` | control page, **write-only**: `$00`–`$7F` arm a register, `$80`–`$FF` one-shot operations |
| `$1E00`–`$1EFF` | TX stream, **write-only**: a store anywhere appends its data byte |
| `$1F00`–`$1F1F` | status cells |
| `$1F10` | the claim `FUJI` |
| `$1F20`–`$1FFB` | the client's fixed tail (220 bytes) |
| `$1FFC`, `$1FFE` | RESET and BRK vectors |

**The image** is N 2K banks then the 2K fixed half, (N+1)×2048 bytes; N is 1,
3, 7 or 15 (MAME's loader). Only the top 256 bytes of the fixed half are
served: the claim, the header, the tail, the vectors. **An image without `FUJI`
at `$1F10` is a game, and the mailbox goes dead for the session.** The build
stamps the claim at file offset (size − 2048) + `$710`.

**Reset survival.** No reset line reaches the cartridge; the RESET switch is a
RIOT bit the program reads. A restart begins with the last bank still mapped,
so the RESET vector points into the fixed tail at a cold stub that reselects
bank 0 — and the next sequence number comes from the cartridge, never from RAM.

**The static check** (`tools/checkrom.py`): size, claim, vector, no
`INC/DEC/ASL/LSR/ROL/ROR` abs/abs,X on `$1D00`–`$1EFF`, no indirect `JMP` on a
page boundary, no `STA (zp),Y`/`STA (zp,X)` anywhere. Because the 6507 has no
interrupts, it is a proof, not a heuristic.

## How the mailbox works

**Write sampling.** The cartridge declares two pages write-only, never drives
them, and recovers a stored byte by watching the address settle and keeping the
second-to-last data sample — the PlusROM / Superchip idiom.
`STA $1E00` appends a byte.

**A read of a write port is a write.** The cartridge cannot tell them apart, so
a register is never written in one store:

```
        lda     #value
        sta     FNRSEL+n        ; arm register n; the data is ignored
        sta     FNCMT           ; commit: register n = value, disarm
```

An arm carries no value; a commit with nothing armed is discarded; one stray
access changes nothing.

**Registers** (arm at `$1D00`+n, commit at `$1DFF`): `$00` DEVICE, `$01` CMD,
`$02` NPARAM, `$05` DATA_RST (rewind TX), `$06` RXSLICE, `$10` SEQ (launch),
`$11` BOOTLOCK (`$B5`), `$12`/`$13` BOOTSEL (`$B5` then `$4A`: reboot the
RP2040 to its bootloader).

**The TX stream**: NPARAM × { size byte 1|2|4, value little-endian } then the
raw payload, up to 320 bytes. `SET_DIRECTORY_POSITION` takes ONE parameter of
TWO bytes.

**Launch**: commit SEQ = ACKSEQ + 1 (wrapping 255→1; 0 is reserved). The
cartridge frames the request as FujiBus over USB, waits up to 5 s (60 s for
MOUNT_IMAGE / COPY_FILE), then paints the reply, REPLY_CMD, ERR, RXLEN, STATUS,
and **ACKSEQ last** — the single store that is the whole interlock. Poll
`$1F00` for the match.

**Status cells**: `$1F00` ACKSEQ · `$1F01` STATUS (bit0 link, bit1 busy) ·
`$1F02` ERR (0 ok, 1 no link, 2 timeout, 3 bad frame, 4 too big) · `$1F03`
REPLY_CMD (`$06` ACK / `$15` NAK) · `$1F04`–`05` RXLEN · `$1F06` BOOT_STATE ·
`$1F07` BOOT_PCT · `$1F08` BOOT_ERR · `$1F09`–`0A` `F`,`N` · `$1F0B` PROTO_VER
2 · `$1F0C` SLICE_ECHO · `$1F0D` TEXTGEN · `$1F0E` BANK · `$1F0F` FLAGS (bit1
claim honoured) · `$1F17`–`18` PATHLEN · `$1F19` BLITGEN.

**The reply window** is repainted only by a SEQ commit or a slice select;
between those it is stable, and a program streams bytes out of it — into a text
row, into the next request, into a path buffer — with no copy through RAM.
Battleship's largest reply, 509 bytes, fits slice 0, which is why the window is
512.

**The arming gate**: nothing on the control page decodes until `$B5` is stored
to `$1DFC` and then `$4A` to `$1DFD`.

**THE ONE RULE**: never a read-modify-write (`INC DEC ASL LSR ROL ROR`) on the
control or TX pages — three bus cycles at one address, and the cartridge cannot
sample that. Only `STA STX STY`. In batari Basic, `FNTX = FNTX + 1` is exactly
that.

**The recipe** (GET_ADAPTERCONFIG_EXTENDED, `$70`/`$C4`, no parameters):

```
        jsr     FNARM           ; once
        lda     #FNDEVF
        sta     FNDEV
        lda     #FNCADPX
        sta     FNCMD
        lda     #0
        sta     FNNPR
        jsr     FNBEG           ; DEVICE, CMD, NPARAM, DATA_RST
        jsr     FNGO            ; SEQ = ACKSEQ+1, wait; A = 0 if answered
        bne     FAILED
        jsr     FNACK           ; 0 = ACK
        bne     FAILED
        lda     FNRPLY+0        ; the SSID
```

```basic
 FNH_ARM1 = FNAM1 : FNH_ARM2 = FNAM2
 FNA_DEV = 0 : FNCMT = FNDEVF
 FNA_CMD = 0 : FNCMT = FNCADPX
 FNA_NPAR = 0 : FNCMT = 0
 FNA_DRST = 0 : FNCMT = 0
 fnseq = FNACKS + 1 : if fnseq = 0 then fnseq = 1
 FNA_SEQ = 0 : FNCMT = fnseq
wait
 drawscreen
 if FNACKS <> fnseq then goto wait
 if FNERR <> 0 then goto fail
 if FNRCMD <> 6 then goto fail
 ch = FNRPLY[0]
```

## The text display

No framebuffer and no character generator: **the cartridge composes the text**.
12 columns × 21 rows, a 3×5 glyph in a 4×6 cell, published as six 128-byte
planes at `$1800`, `$1880`, `$1900`, `$1980`, `$1A00`, `$1A80` — one per `GRP`
write of a 48-pixel six-copy player kernel, indexed by the absolute scanline
Y = row×6 + line. The 128-byte alignment is load-bearing: `LDA plane,Y` is
always four cycles. Bit 7 is the leftmost pixel; the left column of a pair is
bits 7–5, the right bits 3–1.

**Composing a row**: store the row to `$1DF0`, each character to `$1DF1`
(saturates at 12), then 0 to `$1DF2` to render. Wait for TEXTGEN (`$1F0D`) to
change before the next row — the render is on the cartridge's other core.

**The kernel** (`fujidisp.inc`): `DINIT` positions the players (16 NOPs + a
3-cycle store so RESP0 lands at cycle 38, RESP1 three later, HMP0 `$F0`, an
early HMOVE; NUSIZ `$03`, VDELP on) and `DLOOP` draws 262-line frames, calling
the client's `APPVBL` in the vertical blank. The 53-cycle body parks a byte in
the stack pointer (`TSX`/`TXS`), writes `GRP0` seven times (the seventh with the
don't-care Y), and blanks with three writes, not two. **Its four constants are
a one-pixel-wide window and must not be retimed.** Pixel 7 (bit 0 of plane 0)
cannot be drawn by any client.

The font folds lowercase to uppercase; `0`/`O`, `5`/`S`, `C`/`[` were redrawn
to differ. Harnesses compare rendered forms, not decoded text.

## Living in 128 bytes

RAM is `$80`–`$FF`, and the stack (`$0100`–`$01FF`) mirrors into it. Nothing is
copied: `FNRRPL` renders reply bytes into a row, `FNPRPL` appends them to the
next request, `FNWRPL` appends them to a cartridge path buffer. Four 256-byte
**path buffers** live in the cartridge (`$1DF3` append a char, `$1DF4` an
operation: 0 reset, 1 pop a component, 2 emit padded to 256, 3 emit raw, 4 pop
a char, 5–8 select 0–3, 9 commit, 10 seed); they survive a console reset.
**Blits** (six stores) do the loops the console cannot afford.

Zero page, three ways: the library keeps `$80`–`$8B` (FNSEQ, PAD3, SAVSP,
FNCNT, FNDEV/CMD/NPR, FNTMO, FNPTRL/H), FNPCNT `$8E`, INCUR/INPREV `$A8`–`$A9`;
the swap stub lands at `$80`–`$9D`. Battleship owns `$80`–`$BF` with the stack
above `$C0`. batari Basic's kernel owns `$80`–`$A3`, the playfield/`var0`–`47`
`$A4`–`$D3`, `a`–`z` `$D4`–`$ED`, `aux1`–`6` `$F0`–`$F5`, the stack `$F6`–`$FF`
(five `gosub`s).

## The 6502 library

`listings/common/`: `vcs.inc`, `fujinet.inc` (equates — **include before the
`ORG`**), `fujilib.inc` and `fujidisp.inc` (code — **include inside it**; the
other order assembles the transport at `$0000`), plus the guide's `netdefs.inc`
(the `N:` device) and `devdefs.inc` (other devices, more FUJI commands, appkeys,
the clock, the extended path ops, the blit port, the playfield masks).
`checkdefs.py` cross-checks the equates against `fuji_mailbox.h`.

| Routine | Does |
|---|---|
| `FNRW` | register X = A (arm + commit) |
| `FNARM` / `FNCHK` | open the gate / Z if a cartridge answers |
| `FNBEG` | DEVICE, CMD, NPARAM from FNDEV/FNCMD/FNNPR; rewind TX |
| `FNPB` / `FNPW` | a one-byte / two-byte (A lo, X hi) parameter |
| `FNGO` | SEQ = ACKSEQ+1, spin ~9 s; A = 0 ok, ERR, or `$FF` |
| `FNACK` | 0 ACK / `$EE` NAK |
| `FNROWA` / `FNENDR` / `FNRRPL` / `FNRSTR` / `FNHEX` | text rows |
| `FNPATH`, `FNPBEG`/`FNPCH`/`FNPSTR`/`FNPRPL`/`FNPEND` | 256-byte payloads |
| `FNWRST`/`FNWCH`/`FNWPOP`/`FNWTX`/`FNPWD`/`FNWSTR`/`FNWRPL` | the path buffer |
| `FNEOF` | Z if the reply is `$7F,$7F` |
| `FNBLK` / `FNSWAP` | arm the swap / copy the stub to `$80` and boot |
| `INSCAN` | joystick + switches, newly pressed |

`listings/dasm/` is the same library in dasm syntax, **generated** by
`tools/as2dasm.py` (labels lose colons, `DB`→`.byte`, `REPT`→`REPEAT`,
`LSR A`→`LSR`, `(X)&$FF`→`<X`, zero-page equates wrapped in `IFNCONST`).

## batari Basic on the mailbox

- **`set romsize 2k`.** The image is exactly bank 0 with `start` at `$1000`;
  `tools/bbfix.py` appends the fixed half (`fujitail.asm`: the claim, a cold
  stub, the vectors) and runs the static check, vouching for the two indirect
  stores in bB's own kernel. bB's own `bank` statements cannot be used — their
  trampolines and vectors sit in the mailbox.
- **The names.** bB emits any unknown name verbatim, so `include fujinet.h`,
  `fujibas.h` (`FNA_*` arm addresses, `FNH_*` hotspots), `netdefs.h`,
  `devdefs.h` give BASIC the mailbox: `FNH_TROW = 3` is `STA $1DF0`,
  `ch = FNRPLY[i]` is `LDA $1B00,X`.
- **A value must be a `const`** or bB compiles it as memory (`FNCMT = FNDEVF`
  became `LDA $0070`). `tools/mkfujiconst.py` generates `fujiconst.bas` and
  `build.sh` prepends it. Never `X = X + 1` on a mailbox name (it is an `INC`).
  Don't `dim` onto `a`–`z` names you use, or name a dim `c`/`i`.
- **Helpers** at the end of every program: `fnbeg` (dev/cmd/npar), `fngo`
  (launch, draw a frame per poll, `err`), `fnend` (render, wait for TEXTGEN).
- **Text**: `include fujitext.asm`, `const FT_ROW0`, `const FT_ROWS` — a
  minikernel that draws the cartridge's rows between the playfield and the
  score. Measured with `frames.lua`: stock playfield → 3 rows; `const
  pfrowheight = 6` → 10 rows, or 13 with `const noscore = 1`; a playfield
  under 120 lines (`pfrowheight` 5) wraps the overscan timer and breaks the
  frame. Compose a row per frame.
- **Budget**: ~800 bytes of BASIC after the kernel; `listings/bas/default.inc`
  drops `pf_drawing`/`pf_scrolling` for ~335 more; `noscore` another ~100.

## The programs

All in `listings/asm/` and `listings/bas/`, each verified in MAME against a
live `fujinet-pc`:

| | Assembly | BASIC | Shows |
|---|---|---|---|
| hello | `hello.asm` (M0, baked planes) | `hello.bas` | three rows of text |
| first contact | `fujitest.asm` | `arm.bas`, `text.bas` | SSID, IP, version; ACKSEQ 01→02 across RESET |
| netget | `netget.asm` | `netget.bas` | `N:` OPEN (mode 12) / STATUS until settled / READ ≤ 228 / rows per line / CLOSE |
| directory | `fujidir.asm` | `dir.bas` | MOUNT_HOST 0, OPEN_DIRECTORY via path buffer 0, READ_DIR_ENTRY(30,0) until `$7F,$7F` |
| boot | `fujiboot.asm` | `boot.bas` | SET_DEVICE_FULLPATH, MOUNT_IMAGE, BOOT_STATE, BOOTLOCK, the swap stub |
| appkey | `appkey.asm` | `appkey.bas` | the shared username (1/1/0); write and read back creator `$2600` |
| clock | `clock.asm` | `clock.bas` | GET_ISO_LOCAL / GET_ISO_UTC on device `$45` |

Rules the network program carries: STATUS until two readings agree; the 4th
STATUS byte is where an HTTP error shows; cap READ at 512; CLOSE at the start
of the next request; unsigned compares through the carry.

Booting: SET_DEVICE_FULLPATH (dev, host, mode + a 256-byte path) → MOUNT_IMAGE
(dev, mode); the adapter pushes the image to the cartridge (DBC device `$FF`,
NET_OPEN/WRITE/CLOSE frames; a `.cfg` sibling names the mapper); BOOT_STATE 1 →
2; commit `$B5` to BOOTLOCK; run the stub from `$80`: silence GRP/AUD/PF,
`SWACNT`/`SWBCNT` back to inputs, VBLANK, store to `$1DFE`, `TXS`,
`JMP ($1FFC)`. Mappers served: FLAT, F8, F6, F4, FA, E0, UA, FE, CV. A
bank-switch hotspot returns the *old* bank's byte.

## Command reference

Every command below is verified against the firmware's RS232 dispatch tables.
Parameters: *byte* = size 1 + value, *word* = size 2 + LE value. Replies land
at `$1B00`. A byte command not listed is answered with a NAK.

### FUJI device `$70`

| Command | Code | nparam | Params / payload → reply |
|---|---|---|---|
| GET_ADAPTERCONFIG_EXTENDED | `$C4` | 0 | → 240 bytes: ssid[33], hostname[64], binary IPs, mac, bssid, fn_version[15]@125, sLocalIP[16]@140, … |
| GET_ADAPTERCONFIG | `$E8` | 0 | → the first 140 bytes |
| SCAN_NETWORKS / GET_SCAN_RESULT | `$FD` / `$FC` | 0 / 1 | (index) → count / ssid[33]+rssi |
| SET_SSID | `$FB` | 1 | byte (ignored, required); payload **exactly 97**: ssid[33]+password[64] |
| GET_SSID | `$FE` | 0 | → 97 bytes |
| GET_WIFISTATUS / GET_WIFI_ENABLED | `$FA` / `$EA` | 0 | → 1 byte (3 = connected) |
| RESET | `$FF` | 0 | reboots the adapter |
| STATUS / DEVICE_READY | `$53` / `$00` | 1 / 0 | (request type) |
| READ_HOST_SLOTS / WRITE_HOST_SLOTS | `$F4` / `$F3` | 0 | → 8×hostname[32] / payload the same |
| MOUNT_HOST | `$F9` | 1 | host slot |
| READ_DEVICE_SLOTS / WRITE_DEVICE_SLOTS | `$F2` / `$F1` | 0 | the device-slot table |
| SET_DEVICE_FULLPATH | `$E2` | 3 | dev slot, host slot, mode(1); payload **256 bytes** path |
| MOUNT_IMAGE / UNMOUNT_IMAGE | `$F8` / `$E9` | 2 / 1 | dev slot, mode / dev slot |
| MOUNT_ALL / SET_BOOT_MODE / CONFIG_BOOT | `$D7` / `$D6` / `$D9` | 0/1/1 | |
| NEW_DISK | `$E7` | 0 | payload: sectors(w), size(w), host, dev, filename[256] |
| OPEN_DIRECTORY | `$F7` | 1 | host slot; payload **256 bytes**: path, NUL, filter |
| READ_DIR_ENTRY | `$F6` | 2 | maxlen (**30**), flags → entry; `$7F,$7F` = end |
| SET_DIRECTORY_POSITION / GET | `$E4` / `$E5` | 1 / 0 | **one word** |
| CLOSE_DIRECTORY | `$F5` | 0 | |
| COPY_FILE | `$D8` | 2 | src host, dst host (**1-based**); payload exact `src\|dstdir/` |
| SET_HOST_PREFIX / GET_HOST_PREFIX | `$E1` / `$E0` | 1 | host slot (+ prefix payload) |
| GET_DEVICE_FULLPATH | `$DA` | 1 | dev slot → path |
| OPEN_APPKEY | `$DC` | 0 | payload 6 bytes: creator(w), app, key, mode(0 r/1 w), **reserved** |
| READ_APPKEY / WRITE_APPKEY / CLOSE_APPKEY | `$DD` / `$DE` / `$DB` | 0/1/0 | READ → word length + value; WRITE: byte length + payload |
| GENERATE_GUID | `$BB` | 0 | → 36 chars + NUL |
| HASH INPUT / COMPUTE / LENGTH / OUTPUT / NO_CLEAR / CLEAR | `$C8 $C7 $C6 $C5 $C3 $C2` | w/1/1/1 | count+bytes; algorithm 0 MD5 1 SHA1 3 SHA256 4 SHA512; 1 = hex |
| BASE64 ENCODE / DECODE (INPUT COMPUTE LENGTH OUTPUT) | `$D0 $CF $CE $CD` / `$CC $CB $CA $C9` | | same four steps |
| QRCODE INPUT / ENCODE / LENGTH / OUTPUT / CLEAR | `$BC $BD $BE $BF $BA` | | version, ECC, shorten; mode 0 binary 2 bitmap |

NAK on this build: `$F0 $EB $E6 (UNMOUNT_HOST) $E3 $DF $D5 $D4 $D3 (RANDOM_NUMBER) $D2 $D1 $C1 $A0–$A9 $90 $3F`.

### Network devices `$71`–`$78`

| Command | Code | nparam | Notes |
|---|---|---|---|
| OPEN | `$4F` | 2 | mode (4 read/GET, 8 write/PUT, 12 GET with headers, 13 POST), translation (0–3); payload = `N:` devicespec |
| STATUS | `$53` | 2 | two zero bytes → avail(w), connected, devstatus (1 ok, 136 EOF) |
| READ | `$52` | 1 | word count ≤ 512 → the bytes |
| WRITE | `$57` | 1 | word count; payload the bytes |
| CLOSE | `$43` | 0 | |
| CHANNEL_MODE | `$FC` | 2 | byte (ignored), mode 0 protocol / 1 JSON |
| PARSE / QUERY | `$50` / `$51` | 0 | QUERY payload = the path; then STATUS + READ |
| SET_CHANNEL_MODE | `$4D` | 2 | HTTP: 0 body, 1 collect headers, 2 get headers, 3 set headers, 4 POST data |
| SEEK / TELL | `$25` / `$26` | 1 / 0 | 4-byte offset / position |
| TRANSLATION / SET_EOL / SET_INT_RATE | `$54` / `$4C` / `$5A` | 2 | |
| RENAME DELETE LOCK UNLOCK MKDIR RMDIR CHDIR GETCWD | `$20 $21 $23 $24 $2A $2B $2C $30` | 0 | payload the path |
| CONTROL / CLOSE_CLIENT | `$41` / `$63` | 0 | TCP server accept / hang up |
| GET_REMOTE / SET_DESTINATION / USERNAME / PASSWORD | `$72` / `$44` / `$FD` / `$FE` | 0 | |

NAK: `$FF $FB $FA $E3 $81 $80 $45 $3F`.

### Disk `$31`–`$38`, printer `$40`, clock `$45`, modem `$50`

- Disk: READ `$52` / WRITE `$57` / PUT `$50` with one word sector (512 bytes);
  FORMAT `$21`/`$22`, PERCOM `$4E`/`$4F` vestigial. `$53` is **not** a status.
- Printer: WRITE `$57` / PUT `$50` (payload < 255 bytes) / STATUS `$53` (1 param).
- Clock: GETTIME `$93` (7 bytes), GET_ISO_LOCAL `$49`, GET_ISO_UTC `$5A`
  (`2026-09-15T20:45:31+0000`), GET_PRODOS `$50`, GET_SOS `$53`,
  GET_SIMPLE_HUNDREDTHS `$4D`, GET_GENERAL `$47`, GETTZ_LEN `$4C`, GETTZTIME
  `$9A`, SETTZ `$99` (payload a POSIX TZ), SETTZ_ALT `$74`/`$54`.
- Modem: STATUS `$53`, WRITE `$57`, STREAM `$58`, CONTROL `$41`, CONFIGURE
  `$42`, SET_DUMP `$44`, LISTEN `$4C`, UNLISTEN `$4D`, BAUDRATELOCK `$4E`,
  AUTOANSWER `$4F`.

### The cartridge itself

One-shots (store to `$1D00`+): `$80`+b bank · `$F0` TROW · `$F1` TCHR · `$F2`
TEND · `$F3` PATH_CH · `$F4` PATH_OP · `$F5`–`$F9` BLIT SL SH DL DH CNT ·
`$FA` BLIT_GO (data = transform) · `$FC`/`$FD` ARM `$B5`/`$4A` · `$FE` SWAP ·
`$FF` COMMIT.

Blit transforms: 0 RAW, 1 TEXT (row from reply), 2 FIELD (10×10 → ten rows), 3
HULLS, 4 SEA, 5 CELL, 6 PAINT, 7 PATH (path buffer → row), 8 TCELL (one char
into one cell, dst = row×12+col), 9 CARD (five cards from `hand[11]`), 10
PFCLR, 11 PFIELD, 12 PFHULL, 13 PFCELL (the Battleship playfield tables: three
kinds HIT/MID/AUX × six registers, at plane bytes 30–89). **A blit is
single-slot: wait for BLITGEN to change before the next.**

## Battleship

`fujinet-battleship/atari2600`: seven 2K banks + tail, 16K. Lobby, game (board
kernel, cursor, cues, shots), net (one request with the picture up), menu
(RESET), name (keyboard + appkey), place (rolled fleet), comp (the screen in
passes). Entry codes in `BSENT` say what a bank does on entry; the tail's
trampoline resets the stack on every switch (two bytes leaked per poll
otherwise). Zero page `$80`–`$BF`, with `$AE`–`$B0` the game bank's edge memory
that must survive placement.

- URLs are streamed into TX with nothing assembled in RAM; the table id and
  player name live in cartridge path buffers and are emitted raw.
- The `?bin=1&v=2` state record is parsed in place: 38-byte header, then
  per-phase bodies; in play a 115-byte record per player (name, status, 100-cell
  field, five ships-left bytes); 509 bytes at four seats.
- Boards: the playfield tables composed by PFIELD/PFHULL/PFCELL/PFCLR; the
  kernel rewrites PF0–PF2 twice a line on deadlines; the frame is timer-locked
  and every frame is 262 (`make frames`, `make frames4`).
- Sound: one channel, a script engine, twelve cues numbered so each bank's are
  a prefix (`SNDLAST`).
- Checked by `make hosttest / layout / shot / drive / drive4 / frames /
  resettest / resetleave` and four build gates.

## CONFIG

`fujinet-config/atari-2600`: seven banks (hosts, browser, info, keyboard, WiFi,
boot, copy). All four cartridge path buffers in use (working directory / SSID,
filter / passphrase, copy source, edit scratch); the boot argument is path
buffer 0; no inverse video, so `>` marks the selection and content gets eleven
columns; the keyboard is 12×8 cells mapped onto ASCII 32–127
(`ch = 32 + row*12 + col`), shown through a PATH blit.

## Things that cost real time

- REGDATA and DATA are not console addresses; the reply is 512 not 256/1024;
  the claim and vectors are in the fixed half.
- A read of a write port is a write → arm/commit is the defence.
- A bank-switch hotspot returns the OLD bank's byte.
- Banking is a pointer swap, never a copy (a memcpy passed every test in MAME).
- UA and FE switch below A12.
- Size detection needs the `.cfg`, and the hint must be spent.
- A blit is single-slot on the RP2040 → BLITGEN.
- The equates drift (`$1C00` vs `$1D00`) → `checkdefs.py`.
- Equates and code go in different include files.
- The display's three bugs: the seventh GRP write, the VDELP drain, the
  LDX-vs-TSX cycle. Three glyph pairs redrawn.
- READ_DIR_ENTRY maxlen 30 not 31; SET_DIRECTORY_POSITION is one word; never
  read past `$7F,$7F`; 256-byte payloads exactly; the appkey's reserved byte;
  the swap stub's AUDV and SWACNT/SWBCNT stores.
- Battleship: the trampoline's stack leak; the settle-loop alias; a fleet does
  not fit in one overscan; a seam line past cycle 76 costs a second line; the
  four-seat recompose was 27.6 lines in 26.1.
- batari Basic: 4K puts the vectors on the status page; a non-`const` value is
  a memory load; a playfield under 120 lines wraps the timer; a row per frame.
- MAME: `SDL_VIDEODRIVER=dummy`; run from its own tree; one BoIP client; anchor
  the `pkill` pattern.

## Trouble shooting

| Symptom | Probable cause and remedy |
|---|---|
| No `F`,`N` at `$1F09` | wrong MAME slot (`-cartslot fujinet`) or no cartridge |
| FLAGS bit 1 clear | the claim is not at (size−2048)+`$710` |
| Nothing ever completes | the gate is closed, or the control page is one page off |
| ERR = 2 on everything | BASIC: a value without a `const`; asm: NPARAM mismatch; a stray MAME holding BoIP |
| ERR = 1 | no USB link / fujinet-pc not running |
| NAK with ERR = 0 | the adapter refused: parameter shape, short 256-byte payload, undispatched command |
| First transaction after RESET ignored | SEQ from a RAM counter; use ACKSEQ+1 |
| Wrong glyphs in wrong columns | the positioning constants were changed |
| Last row repeats below the text | VDELP toggled instead of GRP0/GRP1/GRP0 |
| Picture rolls (BASIC) | frame ≠ 262: fewer rows, `pfrowheight` 6, `noscore`, a row per frame |
| OPEN ok, STATUS empty / half a page | read STATUS again until two agree; devstatus ≠ 1 is the HTTP error |
| Booted game screams / no joystick | the stub forgot AUDV0/1 or SWACNT/SWBCNT |
| 8K game runs wrong banks | it is E0/UA/FE: add a `.cfg` |
| `Could not initialize SDL` | `SDL_VIDEODRIVER=dummy` |
| Harness never runs | MAME not started from its own tree |

## Sources of truth

| Source | Revision |
|---|---|
| `fn-2600/pico/atari-2600` (mailbox spec `firmware/include/fuji_mailbox.h`, firmware, MAME device, testroms, tools) | tree of 2026-09-15 |
| `fujinet-firmware` (RS232 build: `lib/device/rs232`, `lib/device/fujiDevice`, `include/fujiCommandID.h`) | `d38e32543` |
| `fujinet-battleship/atari2600` | `b59ec45` |
| `fujinet-config/atari-2600` | `b4e3805` |
| `batari-Basic` | `efd6dcd` (v1.7 native) |
| `dasm` | 2.20.16 |
| `fujinet-pc-rs232` | `2a9e2c23f` |
