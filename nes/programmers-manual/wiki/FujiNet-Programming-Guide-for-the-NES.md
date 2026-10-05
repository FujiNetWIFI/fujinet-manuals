# FujiNet Programming Guide for the NES

The FujiNet cartridge gives the Nintendo Entertainment System a network adapter, a file server, a clock and app-key storage.
This guide shows how to drive it from your own programs, in 6502 assembly (ca65) and in C (cc65 + fujinet-lib).
It is the wiki edition of the *FujiNet Programmer's Manual for the NES*. The PDF has diagrams, every command card, annotated listings and screenshots.

> **Status.** The cartridge (RP2354B + two 512K SRAMs, USB to an ESP32-S3) exists as firmware, a schematic and two emulators; no board has been built. Every program here was built and run in a patched MAME against a live fujinet-pc.

## Contents

1. [The cartridge](#the-cartridge)
2. [Tools](#tools)
3. [The mailbox](#the-mailbox)
4. [Your first transaction](#your-first-transaction)
5. [The network device](#the-network-device)
6. [The Fuji device](#the-fuji-device)
7. [Booting an image](#booting-an-image)
8. [The clock and other devices](#the-clock-and-other-devices)
9. [The libraries](#the-libraries)
10. [Pictures, pads and sound](#pictures-pads-and-sound)
11. [The games](#the-games)
12. [CONFIG and the Lobby](#config-and-the-lobby)
13. [Error codes](#error-codes)
14. [Netcat](#netcat)

---

## The cartridge

Two 512K static RAMs stand in for the PRG and CHR ROM, so the console addresses them at full speed.
An RP2354B watches every CPU write and banks the RAMs the way the game's original mapper would. It also serves 4K of its own at `$5000` (the mailbox and a 2K loader ROM) and 8K of work RAM at `$6000`.
A USB link runs to an ESP32-S3 with the FujiNet firmware.

| Address | What |
|---|---|
| `$4020-$4FFF` | open bus |
| `$5000-$53FF` | reply window (1K, cart-painted) |
| `$5400-$54FF` | status page (cart-painted) |
| `$5500-$55FF` | registers: `STA $5500+n` sets register n |
| `$5600-$56FF` | raw REGDATA (unused by programs) |
| `$5700-$57FF` | TX stream: any store appends a byte |
| `$5800-$5FFF` | loader ROM (2K, cart-served) |
| `$6000-$7FFF` | work RAM (8K, cart-served) |
| `$8000-$FFFF` | PRG SRAM, through the mapper |

**Power-on:** the cartridge serves the reset vector itself. The vector points at the loader, which copies CONFIG (32K, baked into the cart's flash) into the SRAMs in about 0.17 s.

**The claim:** an image must carry `FUJI` at `$FFF0` (the last 16 bytes of PRG). Without it the cartridge stops answering `$5000-$57FF` for the session.

**Mappers:** 0 NROM, 1 MMC1, 2 UxROM, 3 CNROM, 4 MMC3, 7 AxROM, 11 Color Dreams, 30 UNROM-512, 34 BNROM/NINA-001, 66 GxROM, 71 Camerica, 206 Namco 108.
The limits are 512K PRG, 512K CHR and 32K WRAM. MMC5 extras, the MMC2/4 latches and expansion audio are not possible.

## Tools

- **cc65 2.19** (`ca65`, `ld65`, `cl65`).
- **fujinet-lib-experimental**, branch `add-nes`: `make nes` gives `r2r/nes/fujinet.nes.lib`. It also provides three files:
  - `makefiles/nes-fujinet.cfg`: NROM, with `$FFF0-$FFF9` reserved for the claim.
  - `makefiles/nes-romstamp.py`: stamps the claim and rejects RMW instructions aimed at the mailbox.
  - `makefiles/platforms/nes.mk`.
- **checkrom.py** (in `fujinet-firmware/pico/nes/tools`) checks the header, the claim, the reset vector and RMW opcodes.
- **fujinet-pc** (the RS-232 build), with BoIP on `127.0.0.1:9995`.
- **MAME**: run `fujinet-firmware/pico/nes/emu/apply.sh ~/mame`, rebuild with `make REGENIE=1`, then `./mame nes -nes_slot fujinet -cart prog.nes`.
- **FujiNet Go NES Desktop**: MesenCE plus a built-in FujiNet.
  - BoIP is on port 11506 and the web configuration on `localhost:11507`.
  - *Open Cartridge…* runs your ROM in place of CONFIG; *Import Cartridge to SD…* puts it on the SD card.

Building a C program:

```sh
L=~/fujinet-lib-experimental
cl65 -t nes -O -I $L/include -C $L/makefiles/nes-fujinet.cfg -m hello.map -o hello.nes hello.c $L/r2r/nes/fujinet.nes.lib
python3 $L/makefiles/nes-romstamp.py --stamp --map hello.map hello.nes
```

## The mailbox

### The one rule

**Only `STA`/`STX`/`STY` to `$5500-$57FF`, plain or indexed. Never a read-modify-write instruction.**
`INC`, `DEC`, `ASL`, `LSR`, `ROL` and `ROR` write the old value back first, and on these pages every write is an event.
In C, never use `++` or `|=` on a mailbox address. The cartridge drops the dummy write and counts it in `DIAG_RMW` (`$5413`).

### Status page

| Address | Name | Meaning |
|---|---|---|
| `$5400` | ACKSEQ | last sequence answered; painted **last** |
| `$5401` | STATUS | bit 0 link up, bit 1 busy |
| `$5402` | ERR | 0 OK, 1 no link, 2 timeout, 3 bad frame, 4 too big |
| `$5403` | REPLY_CMD | `$06` ACK / `$15` NAK |
| `$5404-5` | RXLEN | reply length, LE |
| `$5406` | BOOT_STATE | 0 idle, 1 transferring, 2 ready, `$80` failed |
| `$5407` | BOOT_PCT | 0-100 |
| `$5408` | BOOT_ERR | 1 too big, 2 truncated, 3 no mapper, 4 store busy |
| `$5409-A` | MAGIC | `'F'`, `'N'` |
| `$540B` | PROTO_VER | 1 |
| `$5413` | DIAG_RMW | RMW dummy writes dropped |
| `$5414` | MAPPER | mapper of the running image |
| `$5415` | LINK | 1 once the FujiNet was seen |
| `$5416-8` / `$5419-B` | BOOT_GOT / BOOT_TOT | image bytes so far / size, 24-bit |

### Registers

| Reg | Address | Name | Meaning |
|---|---|---|---|
| `$00` | `$5500` | DEVICE | `$70` Fuji, `$71-$78` network, `$45` clock |
| `$01` | `$5501` | CMD | command |
| `$02` | `$5502` | NPARAM | parameters in the TX stream |
| `$05` | `$5505` | DATA_RST | rewind the TX stream |
| `$10` | `$5510` | SEQ | send the transaction |
| `$11` | `$5511` | BOOTLOCK | `$B5`: arm the loader |

### The TX stream

The stream holds NPARAM parameters, each a size byte (1, 2 or 4) followed by that many value bytes, little-endian, and then the raw payload.
The limit is 320 bytes in all; anything past that is dropped.

### A transaction

1. `$5505` ← any; `$5500` ← device; `$5501` ← command; `$5502` ← NPARAM.
2. Store the parameters and payload to `$5700`.
3. `$5510` ← **ACKSEQ + 1, skipping 0**. Take it from the cartridge, never from a counter of your own: Reset restarts the CPU but not the cartridge.
4. Wait until `$5400` equals it.
5. If ERR = 0 and REPLY_CMD = `$06`, the reply is RXLEN bytes at `$5000`.
   It holds still until your next commit, so you can read it, draw it or stream it back out.

**Timeouts:**

| Who waits | How long |
|---|---|
| The cart, for an ordinary transaction | 5 s |
| The cart, for MOUNT_IMAGE and COPY_FILE | 60 s |
| The cart, for the USB link to come up | 3 s |
| `fn_go` (fujilib.s) | about 11 s |
| `fn_commit()` (fujinet-lib) | about 12 s |

The NMI is harmless mid-transaction as long as it never writes `$5500-$57FF`.

## Your first transaction

C:

```c
/* hello.c -- the first transaction, in C.
 *
 * Asks the FujiNet for its adapter configuration and puts the network name,
 * the IP address and the firmware version on the screen. */

#include <conio.h>
#include <fujinet-fuji.h>
#include <fujinet-nes.h>

static AdapterConfigExtended ac;

void main(void)
{
  clrscr();
  cputs("FUJINET NES\r\n\r\n");

  if (!fuji_nes_present()) {            /* 'F','N' and version 1? */
    cputs("NO FUJINET CARTRIDGE");
    for (;;) ;
  }

  if (!fuji_get_adapter_config_extended(&ac)) {
    cputs("NO ANSWER");
    for (;;) ;
  }

  cprintf("SSID %s\r\n", ac.ssid);
  cprintf("IP   %s\r\n", ac.sLocalIP);
  cprintf("FW   %.15s\r\n", ac.fn_version);
  for (;;) ;
}
```

Assembly, using the bring-up's `fujilib.s` and this guide's `book.inc` macros:

```asm
; hello.s -- the first transaction, in assembly.
;
; Asks the FujiNet for GET_ADAPTERCONFIG_EXTENDED and puts the network name,
; the IP address and the firmware version on the screen, straight out of the
; reply window.

        .include "book.inc"
        .export main

AC_SSID = 0                     ; char[33]
AC_VER  = 125                   ; char[15]
AC_SIP  = 140                   ; char[16], the IP already as text

        .segment "CODE"
.proc main
        PUTS    2, 2, title
        jsr     fn_chk          ; 'F','N' in the status page?
        beq     have
        PUTS    5, 2, nocart
        jmp     show

have:   CALL    FNDEVF, FNCADPX, 0
        jsr     fn_go           ; commit, wait for ACKSEQ
        jne     fail            ; A = FN_ERR, or FNEWAIT
        jsr     fn_ack          ; did the FujiNet say ACK?
        jne     fail

        PUTS    5, 2, tssid
        ldx     #AC_SSID        ; window offset
        ldy     #24             ; at most 24 characters
        jsr     disp_rpl
        PUTS    7, 2, tip
        ldx     #AC_SIP
        ldy     #16
        jsr     disp_rpl
        PUTS    9, 2, tver
        ldx     #AC_VER
        ldy     #15
        jsr     disp_rpl
        jmp     show

fail:   pha
        PUTS    5, 2, tfail
        pla
        jsr     disp_hex

show:   PUTS    12, 2, tseq     ; persists across a console Reset
        lda     FN_ACKS
        jsr     disp_hex
        jsr     disp_on
:       jmp     :-
.endproc

        .segment "RODATA"
title:  .byte "FUJINET NES", 0
nocart: .byte "NO FUJINET CARTRIDGE", 0
tssid:  .byte "SSID ", 0
tip:    .byte "IP   ", 0
tver:   .byte "FW   ", 0
tfail:  .byte "FAILED: $", 0
tseq:   .byte "ACKSEQ $", 0
```

The reply is `AdapterConfigExtended`, 240 bytes:

| Offset | Bytes | Field |
|---|---|---|
| 0 | 33 | `ssid` |
| 33 | 64 | `hostname` |
| 97 | 4 each | `localIP`, `gateway`, `netmask`, `dnsIP` (binary) |
| 113 | 6 each | `macAddress`, `bssid` |
| 125 | 15 | `fn_version` |
| 140 | 16 each | `sLocalIP`, `sGateway`, `sNetmask`, `sDnsIP` (text) |
| 204 | 18 each | `sMacAddress`, `sBssid` (text) |

### fujilib.s (zero page `$E0-$EF` is the library's)

| Routine | Does |
|---|---|
| `fn_chk` | Z set if the magic bytes are present |
| `fn_rw` | register X = A |
| `fn_beg` | device/command/nparam from `fn_dev`/`fn_cmd`/`fn_npr`, then DATA_RST |
| `fn_txb` / `fn_pb` / `fn_pw` | append a raw byte / a 1-byte param / a 2-byte param (A lo, X hi) |
| `fn_path` | append the string at `fn_ptr`, NUL-padded to 256 |
| `fn_go` | commit and wait; A = ERR, or `$FF` if never answered |
| `fn_ack` | A = 0 if ACK, `$EE` if NAK |
| `fn_blk` / `fn_boot` | arm BOOTLOCK / jump to the loader |

## The network device

Devices `$71-$78` are N1: to N8:. A connection goes OPEN → STATUS/READ (and WRITE) → CLOSE. A file is over when STATUS shows 0 bytes waiting and error 136.

```c
/* netget.c -- read a text file over HTTP and print it. */

#include <conio.h>
#include <fujinet-network.h>

static const char url[] = "N:HTTP://127.0.0.1:8765/hello.txt";
static char buf[256];

void main(void)
{
  int16_t n, i;

  clrscr();
  cputs("NETGET\r\n\r\n");

  network_init();
  if (network_open(url, OPEN_MODE_READ, OPEN_TRANS_NONE) != FN_ERR_OK) {
    cputs("OPEN FAILED");
    for (;;) ;
  }

  /* network_read() returns once it has len bytes or the file has ended. */
  while ((n = network_read(url, buf, sizeof buf)) > 0) {
    for (i = 0; i < n; i++) {
      if (buf[i] == '\n')
        cputs("\r\n");
      else
        cputc(buf[i]);
    }
  }

  network_close(url);
  cputs("\r\n-- END --");
  for (;;) ;
}
```

JSON: OPEN, SET_PARSER (`$FC`, parser 1), PARSE, then QUERY a path and READ the value:

```c
/* json.c -- fetch a JSON document and pick fields out of it. */

#include <conio.h>
#include <fujinet-network.h>

static const char url[] = "N:HTTP://127.0.0.1:8765/hello.json";
static const char *const paths[] = {
  "/name", "/console", "/year", "/mailbox/base", "/mailbox/reply"
};
static char value[128];

void main(void)
{
  uint8_t i;

  clrscr();
  cputs("JSON\r\n\r\n");

  network_init();
  if (network_open(url, OPEN_MODE_READ, OPEN_TRANS_NONE) != FN_ERR_OK
      || network_json_parse(url) != FN_ERR_OK) {
    cputs("OPEN/PARSE FAILED");
    for (;;) ;
  }

  for (i = 0; i < 5; i++) {
    if (network_json_query(url, paths[i], value) < 0)
      value[0] = '\0';
    cprintf("%-14s %s\r\n", paths[i], value);
  }

  network_close(url);
  for (;;) ;
}
```

| Cmd | Name | Params | Payload / reply |
|---|---|---|---|
| `$4F` | OPEN | mode(1), trans(1) | payload: URL. Modes: 4 read/GET, 5 DELETE, 6 dir, 8 write/PUT, 9 append, 12 rw / GET with headers, 13 POST |
| `$43` | CLOSE | | |
| `$53` | STATUS | | reply: avail(2), connected(1), error(1) |
| `$52` | READ | count(2) | reply: ≤ count bytes (≤ 1024 on NES) |
| `$57` | WRITE | count(2) | payload: bytes (≤ 317 on NES) |
| `$FC` | SET_PARSER | x(1), parser(1) | 0 none, 1 JSON, 2 HTML, 3 XML |
| `$50` | PARSE | | |
| `$51` | QUERY | | payload: path |
| `$FB` | SET_PARAMETER | which(1), value(1) | 0 query flags, 1 line ending |
| `$54` | TRANSLATION | x(1), trans(1) | 0 none, 1 CR, 2 LF, 3 CRLF, 4 PETSCII |
| `$4C` | SET_EOL | | payload: EOL bytes |
| `$4D` | HTTP mode | x(1), mode(1) | 0 body, 1 collect hdrs, 2 get hdrs, 3 set hdrs, 4 POST data |
| `$25` / `$26` | SEEK / TELL | offset(4) / – | TELL reply: 4 bytes |
| `$2C` / `$30` | CHDIR / GETCWD | | path / reply: text |
| `$FD` / `$FE` | USERNAME / PASSWORD | | text |
| `$20` `$21` `$23` `$24` `$2A` `$2B` | RENAME DELETE LOCK UNLOCK MKDIR RMDIR | mode(1), x(1) | URL (`old,new` for rename) |
| `$41` / `$63` | ACCEPT / CLOSE_CLIENT | | |
| `$44` / `$72` | SET_DESTINATION / GET_REMOTE | | `host:port` / reply 256 (ESP32 NAKs) |
| `$5A` | interrupt rate | ms(1) | no effect on the NES |

**A missing parameter does not NAK, it restarts the FujiNet.** Always send every parameter.

## The Fuji device

```c
/* dir.c -- list a directory on a TNFS host. */

#include <conio.h>
#include <string.h>
#include <fujinet-fuji.h>

#define HOST  7                         /* host slot 8: ec.tnfs.io */
#define ROWS  20

static HostSlot hosts[8];
static char path[256];
static char entry[32];

void main(void)
{
  uint8_t n;

  clrscr();
  if (!fuji_get_host_slots(hosts, 8)) {
    cputs("NO HOST SLOTS");
    for (;;) ;
  }
  cprintf("DIR OF %s\r\n\r\n", (char *) hosts[HOST]);

  /* The path and an optional filter travel as one 256-byte block:
     "/" NUL "*.nes" NUL. Here there is no filter. */
  memset(path, 0, sizeof path);
  path[0] = '/';

  if (!fuji_mount_host_slot(HOST) || !fuji_open_directory(HOST, path)) {
    cputs("CANNOT OPEN");
    for (;;) ;
  }

  for (n = 0; n < ROWS; n++) {
    if (!fuji_read_directory(30, 0, entry))
      break;
    if (entry[0] == 0x7F)               /* $7F = end of directory */
      break;
    cprintf(" %s\r\n", entry);
  }

  fuji_close_directory();
  for (;;) ;
}
```

```c
/* appkey.c -- count how many times this program has been run. */

#include <conio.h>
#include <fujinet-fuji.h>

#define CREATOR 0x5E5E                  /* a scratch creator id */
#define APP     0x01
#define KEY     0x00

static uint8_t data[MAX_APPKEY_LEN + 2];

void main(void)
{
  uint16_t len = 0;
  uint16_t runs = 0;

  clrscr();
  cputs("APPKEY\r\n\r\n");

  fuji_set_appkey_details(CREATOR, APP, DEFAULT);

  /* A key that has never been written reads back empty. */
  if (fuji_read_appkey(KEY, &len, data) && len >= 2)
    runs = data[0] | (data[1] << 8);

  ++runs;
  data[0] = runs & 0xFF;
  data[1] = runs >> 8;

  if (!fuji_write_appkey(KEY, 2, data)) {
    cputs("WRITE FAILED");
    for (;;) ;
  }

  cprintf("THIS PROGRAM HAS RUN\r\n%u TIME%s.\r\n", runs, runs == 1 ? "" : "S");
  cputs("\r\nPRESS RESET TO COUNT AGAIN.");
  for (;;) ;
}
```

App keys: OPEN_APPKEY with 6 bytes (creator(2), app, key, mode 0 read / 1 write, 0), then READ (reply: length(2) + data) or WRITE (payload ≤ 64). A key never written reads as length 0.

| Cmd | Name | Params / payload | Reply |
|---|---|---|---|
| `$FF` | RESET | | none: the FujiNet reboots (times out) |
| `$FE` | GET_SSID | | 97: ssid(33), password(64) |
| `$FD` / `$FC` | SCAN_NETWORKS / GET_SCAN_RESULT | – / index(1) | count(1) / ssid(33), rssi(1) |
| `$FB` | SET_SSID | payload 97 (send all) | |
| `$FA` | GET_WIFISTATUS | | 3 connected, 6 not |
| `$EA` | GET_WIFI_ENABLED | | 1/0 |
| `$F4` / `$F3` | READ / WRITE HOST_SLOTS | – / payload 256 | 256: 8 × 32 |
| `$F9` / `$E6` | MOUNT_HOST / UNMOUNT_HOST | host(1) | |
| `$E1` / `$E0` | SET / GET HOST_PREFIX | host(1) (+ prefix) | GET: 256 |
| `$F2` / `$F1` | READ / WRITE DEVICE_SLOTS | – / payload 304 | 304: 8 × {host(1), mode(1), name(36)} |
| `$E2` | SET_DEVICE_FULLPATH | dev(1), host(1), mode(1), path | |
| `$DA` | GET_DEVICE_FULLPATH | dev(1) | 256 |
| `$F8` | MOUNT_IMAGE | dev(1), mode(1) | answered after the image is pushed |
| `$E9` | UNMOUNT_IMAGE | dev(1) | |
| `$D7` | MOUNT_ALL | | |
| `$E7` | NEW_DISK | payload 262 | |
| `$D8` | COPY_FILE | src(1), dst(1), 1-based; `src\|dst` | |
| `$D9` / `$D6` | CONFIG_BOOT / SET_BOOT_MODE | value(1) | |
| `$F7` | OPEN_DIRECTORY | host(1); path NUL filter NUL | |
| `$F6` | READ_DIR_ENTRY | maxlen(1), flags(1) | maxlen bytes; `$7F` = end; flag `$80` adds 12 bytes of details |
| `$F5` | CLOSE_DIRECTORY | | |
| `$E5` / `$E4` | GET / SET DIRECTORY_POSITION | – / pos(2) | 2 |
| `$DC` `$DD` `$DE` `$DB` | OPEN / READ / WRITE / CLOSE APPKEY | see above | |
| `$E8` / `$C4` | GET_ADAPTERCONFIG / _EXTENDED | | 140 / 240 |
| `$53` | STATUS | | 4 zeros |
| `$00` | DEVICE_READY | | 512 × `'A'` |
| `$D3` | RANDOM_NUMBER | | 4 |
| `$BB` | GENERATE_GUID | | 37 |
| `$D0-$CD` / `$CC-$C9` | BASE64 encode / decode: INPUT, COMPUTE, LENGTH, OUTPUT | len(2) for INPUT/OUTPUT | |
| `$C8` `$C7` `$C3` `$C6` `$C5` `$C2` | HASH: INPUT, COMPUTE, COMPUTE_NO_CLEAR, LENGTH, OUTPUT, CLEAR | alg: 0 MD5, 1 SHA1, 2 SHA256, 3 SHA512, 4 SHA224, 5 SHA384 | |
| `$BC` `$BD` `$BE` `$BF` | QR: INPUT, ENCODE, LENGTH, OUTPUT | ENCODE: version, ecc, shorten | |

Library notes:

- `fuji_set_device_filename(mode, host, dev, path)` takes its arguments in the opposite order to the wire, and `path` must be a 256-byte buffer.
- Pass `""`, not NULL, as the filter to `fuji_open_directory_filter()`.
- `fuji_copy_file()` pads the spec to 256 bytes, so give a full destination name.
- `NEW_DISK`, `RANDOM_NUMBER` and `CLOSE_APPKEY` have no NES wrapper; use `fuji_bus_call()`.

## Booting an image

The sequence is MOUNT_HOST, SET_DEVICE_FULLPATH (device 0, mode 1), MOUNT_IMAGE (device 0, read), then BOOTLOCK `$B5`, then SEI with `$2000`, `$2001` and `$4015` set to 0, then `JMP $5800`.
**MOUNT_IMAGE does not answer until the whole image has been pushed into the cartridge's staging store** (256K RAM or 1.5 MB flash). While it is outstanding, BOOT_PCT and BOOT_GOT/BOOT_TOT show progress.

```c
/* boot.c -- fetch a cartridge image from the SD card and run it. */

#include <conio.h>
#include <fujinet-fuji.h>
#include <fujinet-nes.h>

#define HOST  0                         /* host slot 1: the SD card */
#define SLOT  0                         /* device slot 1 */
#define MODE_READ 1                     /* disk access mode: read only */

static char path[256] = "/nesbook/hello.bin";

void main(void)
{
  clrscr();
  cprintf("BOOTING %s\r\n\r\n", path);

  if (!fuji_mount_host_slot(HOST)
      || !fuji_set_device_filename(MODE_READ, HOST, SLOT, path)) {
    cputs("CANNOT MOUNT");
    for (;;) ;
  }

  /* MOUNT_IMAGE does not answer until the whole image has crossed the
     link into the cartridge's staging store. */
  if (!fuji_mount_disk_image(SLOT, MODE_READ)
      || fuji_nes_boot_state() != FUJI_NES_BOOT_READY) {
    cprintf("FAILED, BOOT ERROR %u", fuji_nes_boot_error());
    for (;;) ;
  }

  cprintf("%lu BYTES STAGED\r\n", fuji_nes_boot_total());
  fuji_set_boot_config(0);              /* don't come back to CONFIG */
  fuji_nes_boot();                      /* never returns */
}
```

fujinet-lib waits about 12 s; the cart allows MOUNT_IMAGE 60 s. For big images, launch the mount without waiting and poll, as the assembly `boot.s` and CONFIG do:

```c
fn_regwr(FNR_DATA_RST, 0);
fn_regwr(FNR_DEVICE, 0x70);
fn_regwr(FNR_CMD, 0xF8);                  /* MOUNT_IMAGE */
fn_regwr(FNR_NPARAM, 2);
fn_tx(1); fn_tx(0);                       /* device slot 0 */
fn_tx(1); fn_tx(1);                       /* mode: read */
want = FN_ACKSEQ + 1;
if (want == 0)
  want = 1;
fn_regwr(FNR_SEQ, want);
while (FN_ACKSEQ != want) {
  /* wait a frame, draw fuji_nes_boot_percent() */
}
```

Images are recognised by extension: `.nes` (since firmware commit da3973c10), `.bin`, `.rom`, `.int`, `.itv` and `.chf`.
The loader copies 1K slices to PRG (`$8000 + LOAD_OFF*1K`) or to CHR (through `$2006/$2007`), acks each one at `$5514`, then jumps to `($FFFC)`. Getting back to CONFIG takes a power cycle.

## The clock and other devices

```c
/* clock.c -- the FujiNet's network time, once a second. */

#include <conio.h>
#include <time.h>
#include <fujinet-clock.h>

static uint8_t now[26];

/* One second of vblanks, counted by cc65's NMI handler in clock(). */
static void second(void)
{
  clock_t t = clock() + 60;

  while (clock() < t)
    ;
}

void main(void)
{
  clrscr();
  cputs("CLOCK\r\n\r\n");

  for (;;) {
    if (clock_get_time(now, TZ_ISO_STRING) == FN_ERR_OK) {
      gotoxy(0, 3);
      cprintf("%.10s\r\n%.8s", now, now + 11);   /* date, then time */
    }
    second();
  }
}
```

| Cmd | Reply |
|---|---|
| `$49` I / `$5A` Z | ISO 8601 in the FujiNet's zone / UTC (25 + NUL) |
| `$93` / `$9A` | D M Y(−2000) H M S (6), system / alternate zone |
| `$54` T / `$4D` M | century Y M D h m s (7) / + hundredths (8) |
| `$50` P / `$53` S | ProDOS (4) / SOS (19) |
| `$47` G / `$4C` L | the zone / its length + 1 |
| `$74` t / `$99` | set the system zone (saved) / the alternate zone |

The other devices:

- **Disks** (`$31-$38`): READ `$52` takes a 4-byte sector and returns 512 bytes. A sector write does not fit the 320-byte TX stream.
- **Printer** (`$40`): WRITE `$57` with the payload as the text.
- **Modem** (`$50`): unusable from the NES, because its replies are unframed.

## The libraries

fujinet-lib's NES bus maps `fuji_bus_call(device, cmd, fields, aux1..aux4, buf, len)` onto the mailbox.

- READs are capped at 1024 bytes and WRITEs at 317.
- An app-key READ strips the 2-byte length prefix.
- A call without `FUJI_FIELD_REPLY` leaves the reply in the window, with its length in `fuji_bus_call_rlen`.

NES-only calls in `fujinet-nes.h`:

- `fuji_nes_present()`
- `fuji_nes_boot_state/percent/error/got/total()`
- `fuji_nes_boot()`
- `fuji_nes_kbd_detect/getc/scan()`, for the Family BASIC and Subor keyboards
- `fn_regwr()`, `fn_tx()` and `fn_commit()`, for hand-built transactions (see CONFIG's `fujiraw.c`)

## Pictures, pads and sound

- Write the PPU only in vblank or with rendering off. cc65's conio queues writes in `$0200-$04FF`, and its NMI lands about 70 per frame. A 32×24 redraw is about 11 frames.
- cc65's NMI resets the scroll every frame.
- cc65's `waitvsync()` polls `$2002` and can suppress an NMI. Wait for `clock()` to change instead.
- cc65 always links its font into CHR. The games put their own tiles at `$1000`.
- Data and BSS live in the cart's 8K WRAM at `$6000`, which is lost at power-off. Use app keys for anything that must persist.
- Controller: write 1 then 0 to `$4016`, then make 8 reads: A, B, Select, Start, Up, Down, Left, Right.
- Sound: pulse timer = `111861/Hz − 1`. Keep the sweep negate bit set (`$4001` = `$08`) or low notes are muted.

## The games

All four are cc65 C, with shared code in `src/` and an NES layer in `src/nes/`. They are NROM with 32K PRG and 8K CHR (the cc65 font at `$0000`, the game tiles at `$1000`), state lives in cart WRAM, and each server poll is one HTTP GET with `bin=1` (packed little-endian structures).

| Game | Repo | Notes |
|---|---|---|
| 5 Card Stud | fujinet-5cardstud | `Game` 418 B (154 + 33/player); shadow screen + attribute palette for the greyed hole card; 233 tiles |
| Battleship | fujinet-battleship (add-nes, uncommitted) | `blitShadow()` whole-screen copy with NMI and rendering off; NMI-tick `waitvsync()`; 256/256 tiles |
| Fujitzee | fujinet-fujitzee | 599-byte `Game` checked at compile time; active column via attribute palette 1; 12-sprite cursor at `$7F00` |
| Texas Hold'em | fujinet-texasHoldEm | 5 Card Stud's NES layer plus community cards (`Game` 429 B), skip-unchanged-repaint checksum |

Lobby hand-off (`quit()`): find the `ec.tnfs.io` host slot, mount `nes/lobby.nes`, boot it. The NES Lobby image does not exist yet.
Lobby app keys use creator 1, app 1: key 0 is the name, and keys 1/3/5/8 hold the server for 5CS, Fujitzee, Battleship and Hold'em.

## CONFIG and the Lobby

CONFIG lives in fujinet-config `nes/`. It is cc65 + fujinet-lib, styled after Family BASIC, and baked into the cart by `build-cart.sh`.

- Its states are CHECK_WIFI, CONNECT_WIFI, SET_WIFI, HOSTS, FILES and INFO.
- It pages directories with SET_DIRECTORY_POSITION plus 16 × READ_DIR_ENTRY(27).
- It boots with a non-blocking MOUNT_IMAGE and a bar drawn from BOOT_PCT, timing out after 65 s.
- The Family BASIC and Subor keyboards are supported.
- There is no Lobby in CONFIG yet.

## Error codes

**Network STATUS error:**

| Code | Meaning | Code | Meaning |
|---|---|---|---|
| 1 | OK | 136 | end of file |
| 138 | timeout | 144 | general |
| 165 | invalid devicespec | 170 | file not found |
| 200 | refused | 207 | not connected |
| 212 | bad user/pass | 213 | JSON parse failed |
| 214 | client error | 215 | server error |

**Mailbox ERR:** 0 OK, 1 no link, 2 timeout, 3 bad frame, 4 too big.

## Netcat

A terminal for the NES. You enter a URL (default `N:TCP://BBS.FOZZTEXX.COM:23/`) on an on-screen keyboard and connect. Telnet IAC and ANSI codes are filtered out.

- **Start** types a line, which is sent with CR LF.
- A **Family BASIC/Subor keyboard** sends each key directly.
- **Select** hangs up.

The pane scrolls a RAM shadow copy, because cc65's NMI resets the scroll every frame.

```c
/* netcat.c -- a network terminal for the NES.
 *
 * Asks for a URL (N:TCP://host:port/ or N:TELNET://...), connects, and then
 * shows whatever the other end sends. Press Start to type a line on the
 * on-screen keyboard -- Start again sends it -- or just type, if a Family
 * BASIC or Subor keyboard is plugged in. Select hangs up. */

#include <conio.h>
#include <string.h>
#include <fujinet-network.h>
#include <fujinet-nes.h>
#include "pad.h"
#include "osk.h"
#include "term.h"

#ifndef DEFAULT_URL
#define DEFAULT_URL "N:TCP://BBS.FOZZTEXX.COM:23/"
#endif

#define URL_MAX   120
#define LINE_MAX   60
#define OSK_TOP    17                   /* conio row of the keyboard */
#define EDIT_ROW   15                   /* conio row of the line being typed */

static char url[URL_MAX + 1] = DEFAULT_URL;
static char line[LINE_MAX + 3];
static uint8_t buf[128];
static uint8_t kbd;                     /* FUJI_NES_KBD_* */

/* ---- small screen helpers ---- */

static void blank(uint8_t y, uint8_t n)
{
  while (n--)
    cclearxy(0, y++, 32);
}

static void title(const char *s)
{
  revers(1);
  cclearxy(0, 0, 32);
  cputsxy(1, 0, s);
  revers(0);
}

static void help(const char *s)
{
  blank(27, 1);
  cputsxy(1, 27, s);
}

/* Show the last `rows` x 30 characters of s, so the end of a long string --
   where the typing happens -- is always in view. */
static void show_field(uint8_t y, uint8_t rows, const char *s)
{
  uint8_t len = strlen(s), skip = 0, i;

  if (len >= rows * 30)
    skip = len - rows * 30 + 1;
  blank(y, rows);
  gotoxy(1, y);
  for (i = skip; i < len; i++) {
    if ((i - skip) % 30 == 0)
      gotoxy(1, y + (i - skip) / 30);
    cputc(s[i]);
  }
  revers(1);
  cputc(' ');                           /* the cursor */
  revers(0);
}

/* Edit s in place with the joypad keyboard (or a real one). Returns when
   DONE is pressed. */
static void edit(char *s, uint8_t max, uint8_t y, uint8_t rows)
{
  char c;
  uint8_t len;

  show_field(y, rows, s);
  for (;;) {
    frame();
    c = osk_input(pad_poll());
    if (!c && kbd)
      c = fuji_nes_kbd_getc();
    if (!c)
      continue;
    len = strlen(s);
    if (c == OSK_DONE || c == FUJI_NES_KEY_ENTER)
      return;
    if (c == OSK_DEL) {
      if (len)
        s[len - 1] = '\0';
    } else if (c >= ' ' && c <= '~' && len < max) {
      s[len] = c;
      s[len + 1] = '\0';
    } else
      continue;
    show_field(y, rows, s);
  }
}

/* ---- the two screens ---- */

static void ask_url(void)
{
  clrscr();
  title("NETCAT");
  cputsxy(1, 3, "CONNECT TO:");
  osk_draw(OSK_TOP);
  help("A KEY  B DEL  SEL SHIFT  ST GO");
  edit(url, URL_MAX, 5, 4);
}

/* Telnet servers open with IAC option negotiation, and BBSes send ANSI
   colour codes. Neither means anything here: swallow them. */
static uint8_t skip_iac, in_esc;

static void receive(uint8_t c)
{
  if (skip_iac) {                       /* IAC cmd opt: drop cmd and opt */
    --skip_iac;
    return;
  }
  if (c == 0xFF) {
    skip_iac = 2;
    return;
  }
  if (in_esc) {                         /* ESC [ params letter */
    if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z'))
      in_esc = 0;
    return;
  }
  if (c == 0x1B) {
    in_esc = 1;
    return;
  }
  term_putc(c);
}

static void send(const char *s, uint16_t n)
{
  network_write(url, (uint8_t *) s, n);
}

static void session(void)
{
  uint16_t avail;
  uint8_t connected, err, pad, i;
  int16_t n;
  char c;

  clrscr();
  title(url);
  term_clear();
  term_flush();
  help("CONNECTING...");

  if (network_open(url, OPEN_MODE_RW, OPEN_TRANS_NONE) != FN_ERR_OK) {
    help("CANNOT CONNECT. PRESS A.");
    while (!(pad_poll() & PAD_A))
      frame();
    return;
  }
  help("ST TYPE A LINE   SEL HANG UP");
  skip_iac = in_esc = 0;

  for (;;) {
    frame();

    /* What has the other end sent? STATUS says how much is waiting. */
    if (network_status(url, &avail, &connected, &err) != FN_ERR_OK)
      break;
    if (avail) {
      n = network_read_nb(url, buf, avail < sizeof buf ? avail : sizeof buf);
      for (i = 0; n > 0 && i < (uint8_t) n; i++)
        receive(buf[i]);
      term_flush();
    } else if (!connected)
      break;

    pad = pad_poll();
    if (pad & PAD_SELECT)
      break;

    c = kbd ? fuji_nes_kbd_getc() : 0;
    if (c == FUJI_NES_KEY_ENTER)
      send("\r\n", 2);
    else if (c >= ' ' && c <= '~')
      send(&c, 1);

    if (pad & PAD_START) {              /* compose a line */
      line[0] = '\0';
      blank(EDIT_ROW, 27 - EDIT_ROW);   /* the keyboard covers the pane */
      osk_draw(OSK_TOP);
      help("ST SEND");
      edit(line, LINE_MAX, EDIT_ROW, 1);
      strcat(line, "\r\n");
      send(line, strlen(line));
      term_repaint();                   /* back from the shadow copy */
      help("ST TYPE A LINE   SEL HANG UP");
    }
  }

  network_close(url);
  help("DISCONNECTED. PRESS A.");
  while (!(pad_poll() & PAD_A))
    frame();
}

void main(void)
{
  if (!fuji_nes_present()) {
    clrscr();
    cputs("NO FUJINET CARTRIDGE");
    for (;;) ;
  }
  network_init();
  kbd = fuji_nes_kbd_detect();

  for (;;) {
    ask_url();
    session();
  }
}
```

```c
/* term.c -- the terminal pane.
 *
 * cc65's NMI handler puts the scroll back to 0,0 every frame, so the pane
 * cannot be scrolled by the PPU. Instead every character goes into a shadow
 * copy of the pane in RAM, scrolling is a memmove of that copy, and
 * term_flush() sends the rows that changed to the screen through conio,
 * whose writes are queued for the vblank NMI. A burst of text costs one
 * redraw, not one per line. */

#include <conio.h>
#include <string.h>
#include "term.h"

static char shadow[TERM_ROWS][TERM_COLS];
static uint8_t dirty[TERM_ROWS];
static uint8_t col, row;

void term_clear(void)
{
  memset(shadow, ' ', sizeof shadow);
  memset(dirty, 1, sizeof dirty);
  col = row = 0;
}

static void scroll(void)
{
  memmove(shadow[0], shadow[1], (TERM_ROWS - 1) * TERM_COLS);
  memset(shadow[TERM_ROWS - 1], ' ', TERM_COLS);
  memset(dirty, 1, sizeof dirty);
}

static void newline(void)
{
  col = 0;
  if (row == TERM_ROWS - 1)
    scroll();
  else
    ++row;
}

void term_putc(char c)
{
  if (c == '\r') {
    col = 0;
    return;
  }
  if (c == '\n') {
    newline();
    return;
  }
  if (c == '\b') {
    if (col)
      --col;
    return;
  }
  if (c < 0x20 || c > 0x7E)             /* nothing else has a glyph */
    return;

  if (col == TERM_COLS)
    newline();
  shadow[row][col++] = c;
  dirty[row] = 1;
}

void term_flush(void)
{
  uint8_t r, c;

  for (r = 0; r < TERM_ROWS; r++) {
    if (!dirty[r])
      continue;
    gotoxy(TERM_LEFT, TERM_TOP + r);
    for (c = 0; c < TERM_COLS; c++)
      cputc(shadow[r][c]);              /* queued; written in the next vblank */
    dirty[r] = 0;
  }
}

void term_repaint(void)
{
  memset(dirty, 1, sizeof dirty);
  term_flush();
}
```
