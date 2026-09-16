# FujiNet Programming Guide for the ColecoVision

The FujiNet programming manual for the ColecoVision — the cartridge mailbox, the
Z80 assembler and Z88DK C client libraries, the complete command reference, and
four worked programs. This is the wiki condensation; the full illustrated
edition is the PDF in `coleco/programmers-handbook/` of the manuals repository.

See also the [FujiNet-Network-Protocol-Handbook](FujiNet-Network-Protocol-Handbook)
for everything the `N:` device can say once you can reach it.

## Contents

- [Your FujiNet Cartridge](#your-fujinet-cartridge)
- [Installing the tools](#installing-the-tools)
- [The mailbox](#the-mailbox)
- [First contact](#first-contact)
- [The Z80 and C libraries](#the-z80-and-c-libraries)
- [The network device](#the-network-device)
- [The Fuji device](#the-fuji-device)
- [Boot, swap, and the mappers](#boot-swap-and-the-mappers)
- [Command reference](#command-reference)
- [The four programs](#the-four-programs)
- [FujiNet Go Coleco Desktop](#fujinet-go-coleco-desktop)
- [Error and status codes](#error-and-status-codes)

## Your FujiNet Cartridge

The 30-pin ColecoVision cartridge connector carries A0–A14, D0–D7, four
pre-decoded chip selects (one per 8K block), power and ground — **no /RD, no
/WR, no clock, no reset**. The selects assert for reads *and* writes and the
cartridge cannot tell them apart, which is why every real ColecoVision mapper
takes its bank number from the address. So both directions of the mailbox ride
the read path:

- **console → cart**: reads inside a hotspot page; the low address byte *is* the
  payload. Reading `$FF41` "sends" `$41`.
- **cart → console**: bytes the cartridge paints into the 32K window it already
  serves; by the time the Z80 reads them they are just ROM.

Inside the shell, an RP2040 serves the window and decodes the hotspots, talking
over USB to an ESP32-S3 (a stock FujiNet). Under MAME the same sources run and
forward FujiBus over TCP to a `fujinet-pc`.

```
 YOUR PROGRAM  <--mailbox-->  RP2040  <--USB-->  ESP32-S3  <--WiFi-->  THE WORLD
   Z80 $8000                window server        FujiNet
```

The window is 32K at `$8000`–`$FFFF`; the mailbox owns only the top 2K. The
console, not the window, is scarce — about 700 usable bytes of RAM — so the
whole 1K reply is handed over as directly addressable ROM and programs read it
in place.

## Installing the tools

Everything builds with **Z88DK** (`zcc` and `z88dk-z80asm`); the C clients also
link **os7lib**, a binding of the ColecoVision BIOS (OS-7).

```sh
# Z88DK: a nightly from nightly.z88dk.org, or from source:
git clone --recursive https://github.com/z88dk/z88dk.git
cd z88dk && export PATH="$PWD/bin:$PATH" ZCCCFG="$PWD/lib/config" && ./build.sh

# os7lib:
git clone https://github.com/tschak909/os7lib.git
cd os7lib && make && export OS7LIB=$PWD

# the bench: fujinet-pc (BoIP on 127.0.0.1:9995) + MAME with the cart grafted:
cd fujinet-firmware/pico/coleco
./emu/apply.sh ~/Workspace/mame
make -C ~/Workspace/mame -j$(nproc) NOWERROR=1 REGENIE=1
./run.sh <client>            # windowed, or --headless "STRING" for a verdict
```

A ColecoVision client is a 32768-byte image: `55 AA` header, code and data below
`$F800`, and the `FUJI` claim at cart offset `$7CFC`. `checkrom.py` enforces it.

## The mailbox

All addresses are console addresses (cart offset + `$8000`).

**Window map**

| Console | Name | What |
|---|---|---|
| `$8000-$F7FF` | — | your program, 30K |
| `$F800-$FBFF` | `FN_REPLY` | the whole 1K reply, in one piece |
| `$FC00-$FC0C` | status | ACKSEQ, STATUS, ERR, REPLYCMD, RXLEN, BOOT_*, `F`/`N`, PROTOVER |
| `$FCFC` | claim | `FUJI` signature |
| `$FD00` | REGSEL | read `+r` (r<`$80`) arms register r; `$FDFE` = armed ROM swap |
| `$FE00` | REGDAT | read `+v` delivers v to the armed register |
| `$FF00` | TXPAGE | read `+v` appends v to the TX stream |

**Status bytes** — `$FC00` ACKSEQ · `$FC01` STATUS (bit0 link) · `$FC02` ERR ·
`$FC03` REPLYCMD (`$06` ACK / `$15` NAK) · `$FC04/05` RXLEN · `$FC06` BOOTSTAT ·
`$FC07` BOOTPCT · `$FC08` BOOTERR · `$FC09/0A` `F`,`N` · `$FC0B` PROTOVER.

**Registers** — `$00` DEVICE · `$01` COMMAND · `$02` NPARAM · `$05` DATA_RST
(rewind TX) · `$06` RXSLICE (vestigial, one slice) · `$10` SEQ · `$11` BOOTLOCK
(`$B5`) · `$12/$13` BOOTSEL.

**TX stream** — NPARAM parameters, each `{size 1|2|4, LE value}`, then the raw
payload. Max 320 bytes, max 8 parameters.

**One transaction, the five moves**

1. **Begin** — rewind TX (reg `$05`); set DEVICE, COMMAND, NPARAM.
2. **Stream** — append parameters then payload with `$FF00+v` reads.
3. **Commit** — SEQ = ACKSEQ + 1 (wrap 255→1; 0 reserved).
4. **Wait** — poll `FN_ACKSEQ` until it echoes; then read ERR, REPLYCMD, RXLEN.
5. **Read** — the reply is at `$F800`, in place.

**The rules.** Derive SEQ from the cart's own persisted ACKSEQ, never a local
counter — a console RESET restarts your program but not the cartridge. The cart
paints ACKSEQ *last*, so a sequence match means the whole reply is ready. The
reply window is never cleared, so believe only `FN_RXLEN` bytes. And **the
vblank NMI cannot be masked and lands mid-transaction — its handler must never
read `$F800` or above.** Timeouts: 5 s per transaction, 60 s for `MOUNT_IMAGE`.

## First contact

`GET_ADAPTERCONFIG_EXTENDED` (device `$70`, command `$C4`) takes no parameters
and returns a 240-byte struct: SSID at +0, firmware version at +125, dotted IP
text at +140.

```asm
        call    FNPRES        ; Z if 'F','N' present
        jr      nz,NOCART
        ld      d,$70
        ld      e,$C4
        call    FNSTART
        call    FNCOMMIT      ; carry = never answered
        or      a             ; A = FN_ERR
        jr      nz,LERR
        call    FNACKED       ; Z if ACK
; reply at $F800: ssid +0, fw +125, ip +140
```

```c
    AdapterConfigExtended ac;
    if (!fuji_coleco_present()) { show("NO FUJINET CART"); for(;;); }
    if (fuji_get_adapter_config_extended(&ac)) {
        show(ac.ssid); show(ac.sLocalIP); show(ac.fn_version);
    }
```

The C examples in this guide use **fujinet-lib-experimental**, the portable
FujiNet C library the game ports link (`network_*`, `fuji_*`, `fuji_coleco_*`,
`clock_*`). The assembly examples drive the mailbox directly with `fujimail.inc`.

## The Z80 and C libraries

The book also ships a low-level C library, `fujilib.c`, that mirrors the
assembly `fujimail.inc` one-for-one (`FNREGWR`/`fn_regwr`, `FNSTART`/`fn_start`,
`FNP8`/`fn_param8`, `FNP16`/`fn_param16`, `FNTXPAD`/`fn_tx_padded`,
`FNCOMMIT`/`fn_commit`, `FNACKED`/`fn_acked`, `FNRLEN`/`fn_reply_len`,
`FNPRES`/`fn_present`). It *is* fujinet-lib's ColecoVision bus laid bare — use it
directly only for the few commands the portable library does not wrap (disk and
printer I/O, `RANDOM_NUMBER`).

Two C traps, both from sccz80 (and they apply to fujinet-lib's coleco bus too):

- A mailbox "write" done as `(void)FN_REGSEL[reg];` is **discarded** — store
  through a `volatile` sink (`FN_TOUCH`). Check with `zcc +coleco -O2 -a`: two
  loads, not one.
- **Never index the reply window as `FN_REPLY[i]`** — the macro's cast-constant
  is mis-indexed. Read through a `volatile unsigned char *` local.

In assembly neither applies: `ld a,(hl)` always performs the read.

## The network device

Devices `$71`–`$78` (`N:`, N1:–N8:). Give one a devicespec URL, and it is a byte
pipe with a status word.

- **OPEN** `$4F` — params mode (4 read, 8 write, 12 read/write) and translation
  (0 none); payload the devicespec padded to 256.
- **STATUS** `$53` — two zero params; reply is `avail` (word), `connected`,
  `devstatus` (1 SUCCESS, 136 EOF).
- **READ** `$52` — word count (≤ avail, ≤ 1024); reply lands at `$F800`.
- **WRITE** `$57` — word count + that many payload bytes (keep under the 320-byte
  TX stream).
- **CLOSE** `$43`.

The discipline: nothing may run between a READ and the code that renders its
bytes, because every transaction repaints the reply window. There is no
interrupt line back from the cartridge — polling `FN_ACKSEQ` is the only
completion mechanism.

## The Fuji device

Device `$70` is the adapter: WiFi, host slots, directories, mounting, utilities.
Highlights: `SCAN_NETWORKS`/`GET_SCAN_RESULT` (RSSI is signed dBm); `SET_SSID`
wants one ignored param and exactly 97 payload bytes; fixed-size struct payloads
must be sent full (256-byte paths, all-8 host slots); directory end is two `$7F`
bytes, and reading past it on an SD host poisons `SET_DIRECTORY_POSITION` for the
session.

## Boot, swap, and the mappers

`SET_DEVICE_FULLPATH` names the file, then `MOUNT_IMAGE` — and while it is
outstanding the ESP32 pushes the image to the RP2040 as FujiBus frames to device
`$FF` (DBC). Watch `FN_BOOTSTAT` (idle→xfer→ready) and `FN_BOOTPCT`. When ready,
arm BOOTLOCK (`$B5`), copy a stub to RAM, blank the VDP, read `$FDFE` to flip the
cartridge, and `JP $0000`. A claimed image keeps the mailbox alive afterward; a
game shuts it down for the session. Pushed images up to 128K are served through
the real MegaCart / Activision / X-in-1 / SGC mappers.

## Command reference

The full illustrated reference — every dispatched command on every device, with
a paired Z80/C example — is in the PDF. The devices reachable on this build:

- **`$70` Fuji** — WiFi & adapter, host slots, directories, files, app keys,
  base64/hash/QR, utilities.
- **`$71`–`$78` network** — the lifecycle five plus JSON channels, seek/tell,
  line discipline, filesystem verbs, TCP accept, UDP, credentials.
- **`$31`–`$38` disk · `$40` printer · `$45` clock (APETime) · `$50` modem** —
  reachable but not yet exercised on the ColecoVision.
- **the cartridge itself** — the hotspot decode, the register file, and the DBC
  push on device `$FF`.

## The four programs

- **NETCAT** — a terminal for `N:`: open a devicespec, then status/read/draw in a
  loop, with the on-screen keyboard for composing a line. Holds one connection
  open for the session. (`coleco/programmers-handbook/listings/netcat`.)
- **5 CARD STUD** — live multiplayer poker (`5card.carr-designs.com`). The 418-byte
  game state is read in place out of the reply window; one transaction per read
  via `network_read_nb`; the vblank NMI kept tiny; quits to the FujiNet Lobby by
  network-booting `coleco/lobby.rom`. (`fujinet-5cardstud/src/coleco`.)
- **BATTLESHIP** — live multiplayer (`battleship.carr-designs.com`). Same
  state-in-window shape through a `CUSTOM_FUJINET_CALLS` hook; GRAPHICS II driven
  as a cellmap; the empty-cell shadow packed to one bit per cell.
  (`fujinet-battleship/src/coleco`.)
- **CONFIG** — the browse-and-boot client the cartridge serves at power-on
  (`fujinet-firmware/pico/coleco/testrom/fujicfg.c`); the stand-in for the future
  `fujinet-config/coleco` port. Host list, rename, WiFi scan/join, file browser,
  and the boot swap. The on-screen keyboard runs no transactions, so an edit
  survives in the reply window.

## FujiNet Go Coleco Desktop

A self-contained ColecoVision with a FujiNet built in — the friendliest bench.
It pairs the clean-room **adamcore** emulator with an in-process `libfujinet`
built from the `colecovision-bringup` branch, and ships GNOME, KDE, macOS and
Windows frontends, each with a Z80 + VDP debugger and drag-and-drop mounting.
Downloads: `github.com/FujiNetWIFI/fujinet-go-coleco-desktop/releases`
(deb/rpm/tar.gz, Windows zip and installer, macOS bundle, flatpaks). Build:
`cmake -B build && cmake --build build`.

**You must supply an `OS7.rom`.** The ColecoVision BIOS is copyrighted Coleco
firmware and is not redistributed; put an exactly-8192-byte `OS7.rom` in
`~/.local/share/fujinet-go-coleco/roms/` (or use *Import BIOS…*), per
`COMPLIANCE.md`.

## Error and status codes

**FN_ERR** (`$FC02`) — 0 OK · 1 NOLINK · 2 TIMEOUT · 3 BADFRAME · 4 TOOBIG ·
`$FF` client EWAIT (the cart never answered).

**FN_REPLYCMD** (`$FC03`) — `$06` ACK · `$15` NAK.

**FN_BOOTSTAT** — 0 idle · 1 xfer · 2 ready · `$80` failed.
**FN_BOOTERR** — 1 too big · 2 truncated · 3 no mapping · 4 store busy.

**NET_STATUS devstatus** — 1 SUCCESS · 136 END_OF_FILE · others per-protocol
(see the Network Protocol Handbook).

**GET_WIFISTATUS** — 3 connected · other values not connected.

---

*The FujiNet Programming Guide for the ColecoVision — wiki edition. The PDF and
this page are kept in sync by hand; when in doubt, the firmware sources win.*
