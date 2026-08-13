# Programming the FujiNet for the Mattel Intellivision

*A programmer's guide and command reference for driving FujiNet from IntyBASIC through the cartridge's shared-memory mailbox. Everything is PEEK and POKE.*

This is the wiki edition of the *FujiNet Programmer's Guide for Intellivision* (the print-styled PDF lives in the `fujinet-manuals` repository under `intv/fujinet-programmers-guide/`). It covers the mailbox protocol, the Network and Fuji device command sets, AppKeys, the reusable `fujinet.bas` library, and three complete networked games — **5 Card Stud**, **Battleship** and **Fujitzee** — together with their Go servers. By the last section you will have a working *netcat* on an Intellivision.

> **Source-verified.** Every command byte, cell address, byte offset and wire format here was read out of the sources, not remembered: the cartridge firmware (`fujinet-firmware/pico/intellivision/` — `fuji_mailbox.h`, `fujinet.c`, `fujibus.h`), the ESP32-S3 command handlers (`lib/device/rs232/`, `lib/bus/rs232/`, `lib/device/fujiDevice/`, `include/fujiCommandID.h`, `include/fujiDeviceID.h`), the CONFIG client (`fujinet-config/intv/`), the three game clients, and the game servers (`fujinet-game-system`). The example programs compile with IntyBASIC v1.4.2 and assemble with as1600 without errors.

See also: [Fujinet Intellivision Mailbox Protocol](Fujinet-Intellivision-Mailbox-Protocol) for the firmware-side view of the same mailbox, and the [AppKey Registry Page](AppKey-Registry-Page).

---

## Contents

1. [Introduction](#introduction)
2. [The Cartridge Mailbox](#the-cartridge-mailbox)
3. [Your First Transaction](#your-first-transaction)
4. [Survival Rules for IntyBASIC Network Code](#survival-rules-for-intybasic-network-code)
5. [The Network Device](#the-network-device)
6. [The Fuji Device](#the-fuji-device)
7. [The Clock Device](#the-clock-device)
8. [The fujinet.bas Library](#the-fujinetbas-library)
9. [Game One: 5 Card Stud](#game-one-5-card-stud)
10. [Game Two: Battleship](#game-two-battleship)
11. [Game Three: Fujitzee](#game-three-fujitzee)
12. [The Lobby](#the-lobby)
13. [Error Codes](#error-codes)
14. [The Library: fujinet.bas](#the-library-fujinetbas)
15. [netcat.bas](#netcatbas)
16. [kbd.bas](#kbdbas)

---

## Introduction

The Intellivision has no peripheral bus a FujiNet could sit on, so the Intellivision FujiNet takes a different road: **the cartridge itself is the peripheral.** Inside the cartridge are two computers:

```
Intellivision --CP-1610 bus--> RP2040/RP2350 (Minty fork) --USB CDC--> ESP32-S3 fujiversal-rs232 --WiFi--> Internet
   your game        PEEK/POKE $9C00-$9F3F mailbox           FujiBus/SLIP
```

The RP2040 (or RP2350) serves your program's ROM **and** maps a small window of cartridge RAM at `$9C00`–`$9F3F` that both sides can read and write: the **mailbox**. Your program fills in a request — device, command, parameters, maybe a payload — and rings a bell. The RP2040 re-encodes it as a FujiBus packet and relays it over an internal USB serial link to an ESP32-S3 running the standard `fujiversal-rs232` build of fujinet-firmware. The reply lands back in the mailbox.

Because the RP2040↔ESP32 wire format is byte-for-byte the FujiBus framing used elsewhere, **every device and command ID below is the same one used by every other FujiNet platform.**

What you can do from IntyBASIC:

* Open network connections by URL — `N:HTTPS://…`, `N:TCP://host:port/`, TELNET, UDP, TNFS and more — then read, write and poll them.
* Scan WiFi, manage host/device slots, browse server directories, mount disk images — and *boot another ROM over the network*.
* Store small records (player name, saved game, server URL) on the FujiNet with AppKeys.
* Read the real-world clock in seven formats.
* Use the FujiNet as a coprocessor: Base64, MD5/SHA hashes, QR codes.

---

## The Cartridge Mailbox

The mailbox is 832 locations at `$9C00`–`$9F3F`. Each holds one byte in the low 8 bits of a 16-bit word — **always mask reads with `AND 255`**. It sits at the *top* of the `$8000`–`$9FFF` window so `$8000`–`$9BFF` (7168 words) stays free for JLP RAM (or your scratch buffers).

### Memory map

| Address | Name | Who writes | Meaning |
|---|---|---|---|
| `$9C00` | MAGIC0 | RP2040 | ASCII `F` (70) — mailbox present |
| `$9C01` | MAGIC1 | RP2040 | ASCII `N` (78) |
| `$9C02` | PROTO_VER | RP2040 | protocol version, currently 1 |
| `$9C03` | SEQ | Inty | bump to start a transaction (wraps, skip 0) |
| `$9C04` | ACKSEQ | RP2040 | set equal to SEQ when the reply is ready |
| `$9C05` | DEVICE | Inty | device id (`$70` Fuji, `$71` N1:, …) |
| `$9C06` | CMD | Inty | command id |
| `$9C07` | NPARAM | Inty | parameter count, 0–8 |
| `$9C08/09` | TXLEN | Inty | payload length, little-endian |
| `$9C0A` | STATUS | RP2040 | diagnostic only: 0 idle, 1 busy, 2 ok, 3 err |
| `$9C0B` | ERR | Inty | link result of last transaction ([errors](#error-codes)) |
| `$9C0C/0D` | RXLEN | RP2040 | reply payload length, little-endian |
| `$9C0E` | REPLY_CMD | RP2040 | `$06` ACK or `$15` NAK |
| `$9C0F` | LINK | RP2040 | 1 if the ESP32-S3 is up on the USB link |
| `$9C10-17` | PARAM_SIZE | Inty | size of each parameter: 1, 2 or 4 bytes |
| `$9C18` | BOOT_STATE | RP2040 | network-boot progress: 0 idle, 1 opening, 2 transfer, 3 mapping, `$80` failed |
| `$9C19` | BOOT_PCT | RP2040 | network-boot progress, 0–100 |
| `$9C1A` | BOOT_ERR | RP2040 | failure reason ([errors](#error-codes)) |
| `$9C1B` | DOORBELL | Inty | write `$B5` → RP2040 reboots to BOOTSEL for reflashing |
| `$9C20-3F` | PARAM_VAL | Inty | 8 slots × 4 bytes, little-endian |
| `$9C40-$9D3F` | TX | Inty | request payload, up to 256 bytes |
| `$9D40-$9F3F` | RX | RP2040 | reply payload, up to 512 bytes |

### The handshake

1. Fill in DEVICE, CMD, NPARAM, the parameter table, TXLEN and the TX payload — everything **except SEQ**.
2. Read ACKSEQ, add 1 (wrap past 255, skip 0), write it to SEQ. **Last.** Writing SEQ is what submits the request.
3. Poll until ACKSEQ equals the SEQ you wrote (the library allows 900 frames ≈ 15 s).
4. Check REPLY_CMD: `$06` = ACK, reply at RX with its length in RXLEN. Anything else → ERR holds the link-level reason.

> **Always derive the new SEQ from the ACKSEQ the RP2040 itself publishes, never from your own counter.** Console Reset restarts your program and zeroes IntyBASIC variables — but not the RP2040. A locally-counted SEQ recomputes the value it already used, and your first transaction after every reset silently hangs.

The interlock is a sequence number, not a busy flag: re-poking the same SEQ mid-flight is a no-op, so a retry can never make the RP2040 run a command twice. STATUS (`$9C0A`) is diagnostic — poll ACKSEQ.

### Parameters and payloads

Commands take up to eight numeric parameters (the "aux" bytes of other platforms). Parameter *i* is one word at `PARAM_SIZE + i` (its size: 1, 2 or 4) plus up to four words at `PARAM_VAL + i*4` (value, little-endian, one byte per word). Bulk data — URLs, filenames, passwords — goes in TX with the count in TXLEN.

Replies stay in RX until the next transaction. **Read replies in place** — IntyBASIC has 228 eight-bit variables and a game-server reply is 400+ bytes. PEEK straight out of RX; copy only what must survive the next transaction into scratch RAM below `$9C00`.

### Timeouts, the link byte, and network boot

The RP2040 gives an ordinary command 5 seconds on the USB link, MOUNT_IMAGE 60, and waits up to 3 seconds for the ESP32 to enumerate before the very first command. LINK (`$9C0F`) shows the live link state.

`MOUNT_IMAGE` on this platform *boots the selected ROM*: the ESP32 pushes the file (+ optional `.cfg` sibling) back through the cartridge, the RP2040 decodes it straight into cartridge ROM space, remaps, and resets the console. Progress is published out-of-band in BOOT_STATE / BOOT_PCT / BOOT_ERR so your wait loop can draw a progress bar. Flat `.bin`, Intellicart `.rom`, and `.bin`+`.cfg` (including JLP variables) all load; a mapping that would collide with the mailbox is refused.

### Declaring the window

```basic
    ASM MEMATTR $8000, $9BFF, "+RWN"
```

Stop at `$9BFF`. On real hardware the RP2040 maps the mailbox regardless, but jzIntv's `--fujinet` emulation registers its own handler for `$9C00`–`$9FFF` — a cartridge that claims those addresses as plain RAM *shadows the emulated FujiNet* and the mailbox never comes up under emulation.

---

## Your First Transaction

```basic
' hello.bas -- ask the Fuji device for its WiFi status
    GOTO main

    INCLUDE "fujinet.bas"

    CONST COL_WHITE = 7

main:
    MODE 0, 0, 0, 0, 0 : WAIT
    CLS
    PRINT AT 0 COLOR COL_WHITE, "FUJINET HELLO"
    PRINT AT 20, "WAITING FOR MAILBOX"

    GOSUB fn_wait_mailbox
    IF fn_ok = 0 THEN
        PRINT AT 40, "NO MAILBOX - IS THIS"
        PRINT AT 60, "A FUJINET CARTRIDGE?"
        GOTO halt
    END IF

    ' One transaction: device $70 (Fuji), command $FA (GET WIFI STATUS),
    ' no parameters, no payload. The one-byte reply lands in FN_RX.
    mb_dev = $70
    mb_cmd = $FA
    mb_nparam = 0
    #fn_txlen = 0
    GOSUB fn_transact

    IF fn_ok = 0 THEN
        PRINT AT 40, "TRANSACTION FAILED "
        PRINT AT 60, "FN ERR = "
        PRINT AT 69, <2>#mb_err
        GOTO halt
    END IF

    IF (PEEK(FN_RX) AND 255) = 3 THEN
        PRINT AT 40, "WIFI IS CONNECTED  "
    ELSE
        PRINT AT 40, "WIFI NOT CONNECTED "
    END IF

halt:
    WAIT
    GOTO halt
```

That is genuinely all there is.

---

## Survival Rules for IntyBASIC Network Code

Every rule below was paid for in debugging time on the three games.

* **Jump over your includes.** INCLUDE pastes text in place, and falling into a `PROCEDURE` or `DATA` block corrupts the return stack. Line one of your program: `GOTO main`.
* **Respect the memory map.** IntyBASIC compiles into `$5000`–`$6FFF` and keeps going past the end if you outgrow it — into `$7000`, which is *not* safe on modern cartridge PCBs. Add `ASM ORG $D000` so cold code lands in `$C100`–`$FFFF`. (Fujitzee's boot genuinely hung on real hardware from a 20-word spill jzIntv forgave.) Safe ranges: `$2000-$2FFF`, `$5000-$6FFF`, `$A000-$BFFF`, `$C100-$FFFF`.
* **Parenthesize `(PEEK(x) AND 255)`.** IntyBASIC's `=` binds *tighter* than `AND` — `PEEK(x) AND 255 = 0` compiles as `PEEK(x) AND (255 = 0)`, which is always zero.
* **Mask into 16-bit variables.** IntyBASIC v1.4.2 silently drops the `AND 255` when the destination of `var = PEEK(...) AND 255` is an 8-bit variable (no ANDI is emitted). `#`-prefixed 16-bit destinations compile correctly.
* **Nest IFs instead of chaining AND.** Two equality comparisons joined by `AND`, where a side comes from a `DEF FN` containing its own `AND 255`, can miscompile to always-false.
* **Use `<.n>` not `<n>` in PRINT.** Zero-padded `<n>` can print garbage in unused leading digits; space-padded `<.n>` initializes its pad register.
* **Wait for key release.** `CONT1.KEY` = 12 means "nothing pressed" — wait for it before reading a new key. And check `CONT1.B1`/`B2` *before* `CONT1.BUTTON` (BUTTON masks all three action buttons).

---

## The Network Device

Devices `$71`–`$78` are eight independent connections, N1: through N8:. A connection is named by a **devicespec** staged in TX at OPEN:

```
N:PROTOCOL://HOST[:PORT]/PATH[?QUERY]
```

Protocols: HTTP, HTTPS, TCP, UDP, TELNET, TNFS, FTP, SMB, NFS, SSH. TLS, redirects and DNS are the ESP32's job.

Life cycle: **OPEN → STATUS (until data) → READ/WRITE → CLOSE.** Two subtleties: for HTTP, *the actual request happens at the first STATUS*, and STATUS reports bytes available *so far* — poll until two consecutive reads agree (the library's `api_call` does). An HTTP error page is still a readable body — check the status error byte (1 = success), not just the byte count.

### Command reference

| Cmd | Name | Parameters / payload | Reply |
|---|---|---|---|
| `$4F` 'O' | OPEN | p0 mode, p1 translation (0 none, 1 CR, 2 LF, 3 CRLF, 4 PETSCII); payload devicespec | ACK/NAK |
| `$43` 'C' | CLOSE | — | |
| `$52` 'R' | READ | p0 length (2 bytes) | data in RX |
| `$57` 'W' | WRITE | p0 length (2); payload data | |
| `$53` 'S' | STATUS | p0 0, p1 type | 4 bytes: avail lo, avail hi, connected, error |
| `$FC` | CHANNEL MODE | p0 0, p1: 0 raw, 1 JSON, 2 SGML | |
| `$50` 'P' | PARSE | — (JSON/SGML mode) | |
| `$51` 'Q' | QUERY | payload: query path e.g. `/0/name` | then STATUS len + READ |
| `$4D` 'M' | HTTP CHANNEL | p0 0, p1: 0 body, 1 collect hdrs, 2 get hdrs, 3 set hdrs, 4 POST data | |
| `$54` 'T' | TRANSLATION | p0 0, p1 mode | |
| `$4C` 'L' | SET EOL | p0/p1 EOL bytes (p0=0 restores default) | |
| `$25` '%' | SEEK | p0 offset (4) — HTTP does a Range request | |
| `$26` '&' | TELL | — | 4-byte LE offset |
| `$30` '0' | GETCWD | — | 256-byte prefix |
| `$2C` ',' | CHDIR | payload path | |
| `$FD` | USERNAME | payload | |
| `$FE` | PASSWORD | payload | |
| `$41` 'A' | TCP ACCEPT | — (listening socket: `N:TCP://:6502/`) | |
| `$63` 'c' | TCP CLOSE CLIENT | — | |
| `$44` 'D' | UDP SET DESTINATION | payload `host:port` | |
| `$20` | RENAME | payload `old,new` | |
| `$21` '!' | DELETE | payload spec | |
| `$23`/`$24` | LOCK / UNLOCK | payload spec | |
| `$2A`/`$2B` | MKDIR / RMDIR | payload spec | |

STATUS with no channel open and p1 = 1/2/3/4 returns the adapter's IP / netmask / gateway / DNS, 4 bytes each.

OPEN access modes:

| Mode | Meaning | Protocols |
|---|---|---|
| 4 | READ / HTTP GET | all |
| 5 | HTTP DELETE | HTTP(S) |
| 6 | DIRECTORY | filesystem protocols |
| 8 | WRITE / HTTP PUT | all |
| 9 | APPEND / HTTP DELETE+headers | file / HTTP(S) |
| 12 | READ-WRITE / HTTP GET+header access | sockets, HTTP(S) — what the games use |
| 13 | HTTP POST | HTTP(S) |
| 14 | HTTP PUT+header access | HTTP(S) |

---

## The Fuji Device

Device `$70` is the FujiNet's control panel. Everything CONFIG does, your program can do.

### WiFi

| Cmd | Name | Parameters / payload | Reply |
|---|---|---|---|
| `$FA` | GET WIFI STATUS | — | 1 byte: 3 = connected (other values are ESP32 WL codes) |
| `$FD` | SCAN NETWORKS | — | 1 byte: count |
| `$FC` | GET SCAN RESULT | p0 index | 34 bytes: SSID[33] + RSSI (signed) |
| `$FB` | SET SSID | p0 any (required!); payload 97 bytes: ssid[33]+password[64] | joins & saves |
| `$FE` | GET SSID | — | 97 bytes |
| `$EA` | GET WIFI ENABLED | — | 1 byte |

> **The exact-length payload rule.** The ESP32 handler for a fixed-size payload fails if *fewer* bytes arrive than it expects — SET SSID wants exactly 97, OPEN DIRECTORY and SET DEVICE FULLPATH exactly 256. Pad with NULs to the documented size.

### Hosts, directories, mounts

| Cmd | Name | Parameters / payload | Reply |
|---|---|---|---|
| `$F4` | READ HOST SLOTS | — | 256 bytes: 8 × 32 |
| `$F3` | WRITE HOST SLOTS | payload 256 bytes (all 8 at once) | |
| `$F9` | MOUNT HOST | p0 slot 0–7 | |
| `$E1`/`$E0` | SET / GET HOST PREFIX | p0 slot; payload/reply prefix | |
| `$F7` | OPEN DIRECTORY | p0 slot; payload 256: path NUL filter NUL padding | |
| `$F6` | READ DIR ENTRY | p0 maxlen, p1 flags (0 plain, `$80` details) | name (+`/` on dirs); EOF = two `$7F` |
| `$F5` | CLOSE DIRECTORY | — | |
| `$E5`/`$E4` | GET / SET DIR POSITION | p0 pos (2) | 2 bytes LE |
| `$F2`/`$F1` | READ / WRITE DEVICE SLOTS | 8 × {host, mode, name[36]} | |
| `$E2` | SET DEVICE FULLPATH | p0 dev slot, p1 host slot, p2 mode; payload 256 | |
| `$DA` | GET DEVICE FULLPATH | p0 slot | path |
| `$F8` | MOUNT IMAGE | p0 slot, p1 flags (1 read) | **boots the ROM on Intellivision** (60 s budget) |
| `$E9` | UNMOUNT IMAGE | p0 slot | |
| `$D7` | MOUNT ALL | — | |
| `$E7` | NEW DISK | payload {sectors u16, size u16, host, dev, name[256]} | |
| `$D8` | COPY FILE | p0 src, p1 dst; payload spec | |
| `$D9`/`$D6` | CONFIG BOOT / SET BOOT MODE | p0 | (no effect on Inty — CONFIG boots from cartridge flash) |

With `$80` in READ DIR ENTRY's flags, a 12-byte prefix precedes the name: modified date (6), size (4 LE), flags (1: bit 0 directory, bit 1 truncated), media type (1).

### AppKeys

Up to 64 bytes (256 in mode 2) stored on the FujiNet, addressed by creator id (16-bit, registered on the [AppKey Registry Page](AppKey-Registry-Page)), app id and key id.

| Cmd | Name | Parameters / payload | Reply |
|---|---|---|---|
| `$DC` | OPEN APPKEY | payload 6 bytes: creator lo, creator hi, app, key, mode (0 read, 1 write, 2 read-256), reserved 0 | |
| `$DD` | READ APPKEY | — | **2-byte LE length prefix**, then the data |
| `$DE` | WRITE APPKEY | payload = value | |
| `$DB` | CLOSE APPKEY | — | |

All six OPEN bytes are required — a 5-byte payload reads back as a timeout. The length prefix on READ is specific to this bus (the reply describes itself). Game-system slots (creator 1, app 1): key 0 shared player name, key 1 five card stud, key 3 fujitzee, key 5 battleship.

### Adapter information

`$C4` GET ADAPTERCONFIG EXTENDED returns 240 bytes (`$E8` returns the first 140, without strings):

| Offset | Size | Field | | Offset | Size | Field |
|---|---|---|---|---|---|---|
| 0 | 33 | ssid | | 125 | 15 | fn_version |
| 33 | 64 | hostname | | 140 | 16 | sLocalIP |
| 97 | 4 | localIP | | 156 | 16 | sGateway |
| 101 | 4 | gateway | | 172 | 16 | sNetmask |
| 105 | 4 | netmask | | 188 | 16 | sDnsIP |
| 109 | 4 | dnsIP | | 204 | 18 | sMacAddress |
| 113 | 6 | macAddress | | 222 | 18 | sBssid |
| 119 | 6 | bssid | | | | |

### Utility and coprocessor commands

| Cmd | Name | Notes |
|---|---|---|
| `$FF` | RESET | reboots the ESP32 (link drops and returns) |
| `$00` | DEVICE READY | replies 512 × 'A' — link self-test |
| `$BB` | GENERATE GUID | fresh unique id |
| `$53` | STATUS | p0 = 1: per-slot mount timestamps |
| `$D0/$CF/$CE/$CD` | BASE64 ENCODE input/compute/length/output | input: p0 len + payload; length: 4-byte reply; output: p0 len |
| `$CC/$CB/$CA/$C9` | BASE64 DECODE | mirror set |
| `$C8/$C7/$C6/$C5` | HASH input/compute/length/output | compute p0: 0 MD5, 1 SHA-1, 2 SHA-256, 3 SHA-512; length/output p0: 1 = hex text |
| `$C3`/`$C2` | HASH compute-no-clear / clear | |
| `$BC/$BD/$BE/$BF` | QR input/encode/length/output | encode p0 version, p1 ecc, p2 shorten |

---

## The Clock Device

Device `$45`, the APETime command set. GET commands accept optional p0 = 1 to use the *alternate* time zone set with `$74`.

| Cmd | Name | Reply |
|---|---|---|
| `$93` | GET TIME | 6 bytes: day, month, year−2000, hour, minute, second |
| `$9A` | GET TZ TIME | same 6 bytes, always alternate zone |
| `$47` 'G' | GET SIMPLE | 7 bytes: century, year, month, day, hour, minute, second |
| `$4D` 'M' | GET SIMPLE + HUNDREDTHS | 8 bytes |
| `$50` 'P' | GET PRODOS | 4 bytes packed |
| `$53` 'S' | GET SOS | NUL-terminated string |
| `$49` 'I' | GET ISO LOCAL | NUL-terminated ISO-8601 |
| `$5A` 'Z' | GET ISO UTC | NUL-terminated ISO-8601 |
| `$99` | SET TZ | payload POSIX TZ, saved |
| `$74` 't' / `$54` 'T' | SET ALT TZ | payload POSIX TZ, session only |
| `$4C` 'L' | GET TZ LENGTH | 1 byte |

---

## The fujinet.bas Library

The full listing is [at the bottom of this page](#the-library-fujinetbas). Include it after your opening `GOTO`:

```basic
    GOTO main
    INCLUDE "fujinet.bas"
main:
```

| Procedure | In | Out | Purpose |
|---|---|---|---|
| `fn_wait_mailbox` | — | `fn_ok` | wait ≤3 s for the mailbox magic at boot |
| `fn_transact` | `mb_dev`, `mb_cmd`, `mb_nparam`, `#fn_txlen`, staged params/payload | `fn_ok`, `#mb_err` | run one transaction (SEQ from ACKSEQ, 15 s guard, ACK check) |
| `fn_param` | `pm_i`, `pm_size`, `#pm_val` | — | stage parameter *i* |
| `fn_putstr` | `#fn_src`, `fn_len` | advances `#fn_txlen` | append bytes (ROM `DATA` via VARPTR, or RAM) to TX |
| `fn_strlen` | `#fn_src`, `ls_max` | `fn_len` | measure a NUL-padded field (so padding never leaks into a URL) |
| `net_open` | devicespec staged in TX | `fn_ok` | OPEN N1: mode 12, no translation |
| `net_status` | — | `#net_avail`, `#net_err`, `fn_ok` | STATUS; folds "error ≠ 1" into fn_ok |
| `net_read` | `#net_readlen` | `#net_gotlen`, data at FN_RX | READ (captures RXLEN before CLOSE clobbers it) |
| `net_write` | `fn_len` bytes at FN_TX | `fn_ok` | WRITE |
| `net_close` | — | `fn_ok` | CLOSE |
| `api_call` | URL in TX, `#net_readlen` | `fn_ok`, reply in FN_RX | open → settle-poll STATUS → clamp → read → close |
| `appkey_open` | `ak_creator_lo/hi`, `ak_app`, `ak_key`, `ak_mode` | `fn_ok` | select a key |
| `appkey_read` | `#fn_src` (dest), `ls_max` | `fn_len`, NUL-terminated dest | read (handles the 2-byte length prefix) |
| `appkey_write` | `#fn_src`, `fn_len` | `fn_ok` | write |
| `appkey_close` | — | `fn_ok` | close |
| `fn_putnum` | `pn_val` (0–999) | appends to TX | decimal ASCII for URLs like `/attack/47` |

The library owns scratch RAM `$9100`–`$917F` (`SC_NAME` player name, `SC_ENDPT` endpoint, `SC_QUERY`); the games start their own buffers at `$9180`.

---

## Game One: 5 Card Stud

Sources: [fujinet-5cardstud `intv/`](https://github.com/FujiNetWIFI/fujinet-5cardstud) — server: [fujinet-game-system](https://github.com/FujiNetWIFI/fujinet-game-system).

A thin client that draws whatever the server says the table looks like — it never knows the rules of poker. Flow: boot → name from AppKey 1/1/0 (validated to A–Z 0–9, with one retry for a cold USB link) → Lobby room from AppKey 1/1/1 (`split_room_url`) → table select → poll loop.

URLs are composed byte-by-byte from `DATA` literals (IntyBASIC has no strings):

```
N:https://5card.carr-designs.com/state?table=r1&player=THOM&bin=1
```

Paths: `tables?bin=1`, `state`, `move/XX` (2-char code), `leave` — all with `?table=…&player=…&bin=1`. `bin=1` selects the server's binary serialization: fixed offsets, little-endian u16s, every string lowercased and NUL-terminated (hence "size + 1" fields). (`&be=1` big-endian exists but was retired on Inty after byte-order bugs; little-endian is the well-trodden road.)

**Tables reply:** count (1), then 36-byte records: table[9] name[21] players[6] (literal `"2 / 8"`).

**Game reply** (≤ 418 bytes):

| Offset | Size | Field | Notes |
|---|---|---|---|
| 0 | 81 | lastResult | one-shot message |
| 81 | 1 | round | 0 wait, 1–4 streets, 5 showdown |
| 82 | 2 | pot | u16 LE |
| 84 | 1 | activePlayer | signed, `$FF` none, 0 = you |
| 85 | 1 | moveTime | server-computed, minus 4 s network grace |
| 86 | 1 | viewing | 1 = spectator |
| 87 | 1 | validMoveCount | |
| 88 | 65 | validMoves[5] | 13 each: code[3] + name[10] |
| 153 | 1 | playerCount | |
| 154 | 33×N | players | name[9] status(1) bet(2 LE) move[8] purse(2 LE) hand[11] |

Wire index 0 is always you (the server rotates per client). Hands are ASCII pairs (`2`–`9`,`t`,`j`,`q`,`k`,`a` × `d`,`h`,`c`,`s`; `??` = hidden). Validation is layered: length ≥ 154, round ≤ 5, playerCount ≤ 8, then length ≥ 154 + 33 × playerCount — a short read leaves stale bytes from a previous larger reply in RX, and an HTTP error page fails the sanity gates instead of rendering as garbage.

Rendering is differential (the STIC has no page-flip): full CLS only when the layout changes; otherwise only changed cells are poked, one `WAIT` per seat so no burst outruns vblank. Your turn: the server *names* the moves (`FO` fold, `CH` check, `CA` call, `BL`/`BH` bet, `RA` raise, `BB` bring-in); the client draws them, counts down moveTime, and submits the highlighted one on timeout.

Server: Go/gin; per-table mutex; bots move in 3 s, humans get 39 s; a hidden `test` table is reserved for client developers.

---

## Game Two: Battleship

Sources: [fujinet-battleship `intv/`](https://github.com/FujiNetWIFI/fujinet-battleship).

Four 10×10 boards at once — via the STIC's **colored-squares mode**: a BACKTAB word with bit 12 set and bit 11 clear is four independently colored 4×4-pixel quadrants. `board.bas` wraps it (`cs_fill`, read-modify-write `cs_plot`, `board_cell`); mind that the bottom-right quadrant's high color bit lives at bit 13, and the update mask must clear-and-re-add the enable bit (preserving it doubles bit 12 into bit 13 and the card snaps back to text mode).

The game's rule: one shot lands on the same coordinate of *every* opposing board. Requests add `&bin=1&v=2` (v2 reveals the winner's ships at game over).

**State reply:** header — playerCount (1), prompt[33], status (1: 0 lobby, 1 place, 10 start, 11 miss, 12 hit, 13 sunk, 99 over), playerStatus (1: 0 playing, 1 defeated, 2 viewing, 3 ready, 10 placing), activePlayer (1, signed), moveTime (1). Then:

* **Lobby:** serverName[21] + 10-byte records {name[9], ready}.
* **In play:** lastAttackPos (1), myShips[10] (yours [0..4], winner's [5..9] at game over; each byte = cell + 100×direction, 0 across / 1 down), then 115-byte records {name[9], status, gamefield[100], shipsLeft[5]}. Gamefield: 0 unknown, 1 hit, 2 miss.

Endpoints: `/state`, `/ready`, `/place/25,113,4,167,89` (five encoded ships), `/attack/47`, `/leave`, `/tables`. Placement is validated client-side against a local occupancy map; the server's myShips echo is authoritative (covers reconnects). Miss/hit/sunk sounds pair status with lastAttackPos so they fire once per event, not per poll. Timing: bots 3 s, humans 45 s (250 s alone), +5 s after a status change, 4 s grace.

---

## Game Three: Fujitzee

Sources: [fujinet-fujitzee `intv/`](https://github.com/FujiNetWIFI/fujinet-fujitzee).

A 15-category scorecard per player doesn't fit a 20×12 screen — so the client shows one player's card at a time (disc pages it; the view auto-snaps to whoever's turn begins), beside a permanent seat strip, dice row and prompt.

**State reply** (same shape every round):

| Offset | Size | Field | Notes |
|---|---|---|---|
| 0 | 1 | playerCount | seats + spectators, up to 12 |
| 1 | 21 | serverName | |
| 22 | 41 | prompt | |
| 63 | 1 | round | 0 lobby, 1–13, 99 over |
| 64 | 1 | rollsLeft | |
| 65 | 1 | activePlayer | signed |
| 66 | 1 | moveTime | |
| 67 | 1 | viewing | |
| 68 | 6 | dice | 5 ASCII `1`–`6` + NUL; empty at turn start |
| 74 | 6 | keepRoll | 5 ASCII `0`/`1` + NUL — 1 rerolls |
| 80 | 15 | validScores | signed; `$FF` not selectable |
| 95 | 42×N | players | name[9] alias(1) scores[16] (u16 LE) |

Scores: 0–5 upper, 6–7 computed upper total/bonus, 8–14 lower (14 = Fujitzee), 15 running total; `$FFFF` unset. In the lobby `scores[0]` doubles as the ready flag (1 ready, `$FFFE` spectator). Note the ceiling: 95 + 12×42 = 599 bytes exceeds the 512-byte RX window — at most 9 player records fit; seats cap at 6, so play is unaffected, but a spectator-heavy table can make polls fail the length gate.

Your turn is a two-mode machine: **DICE** (toggle keep flags, submit `/roll/01100`) and **SCORE** (pick a category, submit `/score/11` — wire index, skipping computed rows 6–7). Out of rolls, the client auto-enters SCORE mode parked on the best open category. When *someone else* scores, the client diffs their scores against a per-poll shadow and flashes the picked cell for ¾ s — so a bot's instant move is still a visible event. Rolls animate on every card via rollsLeft/turn-change detection.

Endpoints: `/state`, `/ready`, `/roll/:keep`, `/score/:index`, `/leave`, `/tables`. Timing: bots 3 s, humans 45 s (15 s penalized, 250 s alone), start countdowns 31/6/3 s. All scoring is server-side.

---

## The Lobby

The [FujiNet Lobby](https://lobby.fujinet.online) is the directory of live game rooms:

* **Game servers upsert themselves** — POSTing a GameServer JSON record (game, region, server URL with `?table=` per room, cur/max players, per-platform client download URLs) whenever a room's population changes; game results at match end. Development servers talk to `qalobby.fujinet.online`.
* **The Lobby client hands off through AppKeys** — writing `https://server/?table=id` into the game's registered slot (creator 1 / app 1 / key 1, 3 or 5) and booting the game client.
* **The game rejoins on its own** — reading its slot at boot, splitting at the `?` (validating `table=` + alphanumerics; the value goes into URLs unescaped). Picking a table by hand writes the slot back (console reset rejoins); deliberately quitting clears it.

Treat both the shared username slot (key 0) and the room slots as hostile input — validate byte-by-byte.

---

## Error Codes

**Mailbox link (`ERR`, `$9C0B`):** 0 OK · 1 ENOLINK (no USB link — check LINK, wait, retry) · 2 ETIMEOUT · 3 EBADFRAME · 4 ETOOBIG.

**Network status error byte:** 1 SUCCESS · 131 write-only/read-only family (131/135) · 132 invalid command · 136 EOF · 138 timeout · 144 general · 146 not implemented · 151 file exists · 162 no space · 165 invalid devicespec · 166 invalid POINT · 167 access denied · 170 file not found · 200 connection refused · 201 network unreachable · 202 socket timeout · 203 network down · 204 connection reset · 205 already in progress · 206 address in use · 207 not connected · 208 server not running · 209 no connection waiting · 210 service unavailable · 211 connection aborted · 212 bad credentials · 213 could not parse JSON · 214 client error (HTTP 4xx) · 215 server error (HTTP 5xx) · 255 could not allocate buffers.

**Network boot (`BOOT_ERR`, `$9C1A`):** 1 REJECTED (bad ROM header) · 2 TRUNCATED · 3 NOMAP (no `.cfg`, no header, unknown size) · 4 MAILBOX (mapping collides with the mailbox) · 5 CFGBAD.

---

## The Library: fujinet.bas

```basic
' fujinet.bas -- FujiNet mailbox transport + network/appkey primitives.
'
' Mailbox layout is the hand-synchronized copy of
' fujinet-firmware/pico/intellivision/firmware/fuji_mailbox.h, exactly as
' proven working by intv/fujitest.bas in that repo. Do not change these
' addresses without re-checking that file.
'
' MEMATTR intentionally stops at $9BFF, short of the $9C00-$9FFF mailbox
' itself: on real PiRTO II hardware the RP2040 maps that whole window as
' RAM unconditionally (inty_cart.c hardcodes it, independent of what this
' .cfg says), so declaring less here doesn't affect real hardware or what
' POKE can reach at runtime. But jzIntv's --fujinet peripheral emulation
' registers its own handler for $9C00-$9FFF *after* the cart's generic
' MEMATTR RAM, and its layered bus dispatch lets whichever peripheral
' registered first answer a given address -- so declaring the full
' $8000-$9FFF range here (as fujitest.bas does) silently shadows the
' emulator's FujiNet peripheral with inert RAM, and the mailbox never
' comes up under --fujinet even though it works on real hardware.
    ASM MEMATTR $8000, $9BFF, "+RWN"

    CONST FN_MAGIC0     = $9C00
    CONST FN_MAGIC1     = $9C01
    CONST FN_SEQ        = $9C03
    CONST FN_ACKSEQ     = $9C04
    CONST FN_DEVICE     = $9C05
    CONST FN_CMD        = $9C06
    CONST FN_NPARAM     = $9C07
    CONST FN_TXLEN_LO   = $9C08
    CONST FN_TXLEN_HI   = $9C09
    CONST FN_ERR        = $9C0B
    CONST FN_RXLEN_LO   = $9C0C
    CONST FN_RXLEN_HI   = $9C0D
    CONST FN_REPLY_CMD  = $9C0E
    CONST FN_PARAM_SIZE = $9C10
    CONST FN_PARAM_VAL  = $9C20
    CONST FN_TX         = $9C40
    CONST FN_RX         = $9D40

    CONST FUJICMD_ACK = $06
    CONST FUJICMD_NAK = $15

    ' Fuji device (config/appkey) commands.
    CONST FUJI_DEVICEID       = $70
    CONST FUJICMD_OPEN_APPKEY  = $DC
    CONST FUJICMD_CLOSE_APPKEY = $DB
    CONST FUJICMD_WRITE_APPKEY = $DE
    CONST FUJICMD_READ_APPKEY  = $DD

    ' Network device (N1:) commands.
    CONST NET_DEVICEID = $71
    CONST NETCMD_OPEN   = $4F
    CONST NETCMD_CLOSE  = $43
    CONST NETCMD_READ   = $52
    CONST NETCMD_WRITE  = $57
    CONST NETCMD_STATUS = $53

    ' $0C is HTTP "GET with header access" and, on file/socket protocols,
    ' plain READ-WRITE -- the same value serves both names.
    CONST OPEN_MODE_HTTP_GET_H = $0C
    CONST OPEN_MODE_RW = $0C
    CONST OPEN_TRANS_NONE = $00

    ' Scratch RAM ($9000-$97FF) -- ours, outside the mailbox proper. Holds
    ' state that must survive across multiple mailbox transactions (the
    ' mailbox's own TX/RX buffers get overwritten by every call).
    CONST SC_NAME    = $9100 ' playerName, 9 bytes (8 + NUL)
    CONST SC_ENDPT   = $9110 ' serverEndpoint, 64 bytes
    CONST SC_QUERY   = $9150 ' query (?table=...&player=...), 48 bytes

    ' fn_ok: 1 = last transaction produced ACK, 0 = timeout or NAK.
    ' mb_err: FN_ERR value on failure (0 on timeout, since the RP2040 never answered).
    DIM fn_ok, #mb_err
    DIM mb_dev, mb_cmd, mb_nparam, mb_seq
    DIM #fn_txlen
    DIM #fn_t          ' generic frame-count timeout counter
    DIM #fn_src         ' VARPTR source for putstr/getstr
    DIM fn_len, fn_i    ' generic length/index for putstr/getstr

' ---------------------------------------------------------------------------
' fn_wait_mailbox: bounded wait for the RP2040 magic bytes at boot.
' Sets fn_ok = 1 if the mailbox came up within 180 frames (3s), else 0.
' ---------------------------------------------------------------------------
fn_wait_mailbox: PROCEDURE
    #fn_t = 0
    WHILE ((PEEK(FN_MAGIC0) AND 255) <> 70) AND ((PEEK(FN_MAGIC1) AND 255) <> 78) AND (#fn_t < 180)
        #fn_t = #fn_t + 1
        WAIT
    WEND
    IF #fn_t >= 180 THEN
        fn_ok = 0
    ELSE
        fn_ok = 1
    END IF
END

' ---------------------------------------------------------------------------
' fn_transact: issue the transaction described by mb_dev/mb_cmd/mb_nparam/
' #fn_txlen (payload already staged at FN_TX) and block for the reply.
' seq is ALWAYS derived from the RP2040's own FN_ACKSEQ, never from a local
' counter -- a console reset zeroes IntyBASIC vars but not the RP2040, so a
' locally incrementing seq would recompute the same value forever and never
' trigger a second transaction after the first boot.
' Sets fn_ok = 1 on ACK, 0 on timeout/NAK (mb_err holds the reason).
'
' mb_err/net_err are deliberately 16-bit (#-prefixed), not the 8-bit plain
' variables their DIM comments once declared them as: IntyBASIC v1.4.2
' silently drops the AND 255 mask on any assignment of the literal shape
' "plain_var = PEEK(...) AND 255" (with or without wrapping parens) when
' the destination is an 8-bit variable -- confirmed by reading the
' generated .lst, no ANDI instruction is emitted at all, so whatever
' garbage sits in the peeked word's upper byte survives into the
' variable. #-prefixed (16-bit) destinations don't hit this; the ANDI
' shows up correctly. net_err in particular is compared with "<> 1"
' immediately after, so a stray upper byte there would misreport a good
' status as a failure.
' ---------------------------------------------------------------------------
fn_transact: PROCEDURE
    POKE (FN_DEVICE), mb_dev
    POKE (FN_CMD), mb_cmd
    POKE (FN_NPARAM), mb_nparam
    POKE (FN_TXLEN_LO), #fn_txlen AND 255
    POKE (FN_TXLEN_HI), #fn_txlen / 256

    mb_seq = (PEEK(FN_ACKSEQ) AND 255) + 1
    IF mb_seq = 0 THEN mb_seq = 1
    POKE (FN_SEQ), mb_seq

    #fn_t = 0
    WHILE ((PEEK(FN_ACKSEQ) AND 255) <> mb_seq) AND (#fn_t < 900)
        #fn_t = #fn_t + 1
        WAIT
    WEND

    IF #fn_t >= 900 THEN
        fn_ok = 0
        #mb_err = 0
        RETURN
    END IF

    IF (PEEK(FN_REPLY_CMD) AND 255) <> FUJICMD_ACK THEN
        fn_ok = 0
        #mb_err = (PEEK(FN_ERR) AND 255)
        RETURN
    END IF

    fn_ok = 1
END

' ---------------------------------------------------------------------------
' fn_param: stage transaction parameter #pm_i (0-based), #pm_size bytes
' (1 or 2), value #pm_val, little-endian, into the mailbox's param table.
' ---------------------------------------------------------------------------
DIM pm_i, pm_size
DIM #pm_val
fn_param: PROCEDURE
    POKE (FN_PARAM_SIZE + pm_i), pm_size
    POKE (FN_PARAM_VAL + pm_i * 4), #pm_val AND 255
    IF pm_size > 1 THEN POKE (FN_PARAM_VAL + pm_i * 4 + 1), #pm_val / 256
END

' ---------------------------------------------------------------------------
' fn_putstr: append fn_len ASCII bytes into FN_TX, starting at the current
' #fn_txlen, from the address in #fn_src -- either VARPTR of a ROM DATA
' label (a literal like lit_tables(0)) or a RAM address (a scratch buffer
' like SC_NAME, or even FN_RX). PEEK is uniform across ROM/RAM on the
' CP-1610's unified address space, so one procedure covers both. Advances
' #fn_txlen.
' ---------------------------------------------------------------------------
fn_putstr: PROCEDURE
    FOR fn_i = 0 TO fn_len - 1
        POKE (FN_TX + #fn_txlen + fn_i), PEEK(#fn_src + fn_i) AND 255
    NEXT fn_i
    #fn_txlen = #fn_txlen + fn_len
END

' ---------------------------------------------------------------------------
' fn_strlen: scan the NUL-padded field at #fn_src (max ls_max bytes) and set
' fn_len to the length up to (but not including) the first NUL. Use this
' before fn_putstr whenever the source is a fixed-width padded field (table
' id, player name) -- putstr has no idea where the real string ends, and
' blindly copying the full padded width embeds a literal $00 byte plus
' whatever garbage follows it into the URL, which is sent as-is (the URL's
' length is a byte count, not NUL-terminated, so nothing downstream stops
' at that NUL either -- it corrupts the HTTP request on the wire).
' ---------------------------------------------------------------------------
DIM ls_max
fn_strlen: PROCEDURE
    fn_len = 0
    WHILE (fn_len < ls_max) AND ((PEEK(#fn_src + fn_len) AND 255) <> 0)
        fn_len = fn_len + 1
    WEND
END

' ---------------------------------------------------------------------------
' net_open: open devicespec (ASCII bytes already staged at FN_TX, length in
' #fn_txlen) for HTTP GET. Leaves fn_ok set.
' ---------------------------------------------------------------------------
net_open: PROCEDURE
    mb_dev = NET_DEVICEID
    mb_cmd = NETCMD_OPEN
    mb_nparam = 2
    pm_i = 0 : pm_size = 1 : #pm_val = OPEN_MODE_HTTP_GET_H : GOSUB fn_param
    pm_i = 1 : pm_size = 1 : #pm_val = OPEN_TRANS_NONE : GOSUB fn_param
    GOSUB fn_transact
END

' ---------------------------------------------------------------------------
' net_status: query byte count available. Result in #net_avail; fn_ok as usual.
' ---------------------------------------------------------------------------
DIM #net_avail
' net_err: the 4th byte of the NDeviceStatus reply (nDevStatus_t). 1 =
' SUCCESS. For an HTTP-backed devicespec, the *actual* GET is deferred
' until this first STATUS call (see NetworkProtocolHTTP::status_file()/
' http_transaction() in fujinet-firmware) and its result code lands here
' -- an HTTP error response (e.g. a 400) still has a real, readable body
' (the error page), so `avail` alone can't tell it apart from a good
' response. Checking net_err is what actually can.
DIM #net_err
net_status: PROCEDURE
    mb_dev = NET_DEVICEID
    mb_cmd = NETCMD_STATUS
    mb_nparam = 2
    pm_i = 0 : pm_size = 1 : #pm_val = 0 : GOSUB fn_param
    pm_i = 1 : pm_size = 1 : #pm_val = 0 : GOSUB fn_param
    #fn_txlen = 0
    GOSUB fn_transact
    IF fn_ok THEN
        #net_avail = (PEEK(FN_RX) AND 255) + (PEEK(FN_RX + 1) AND 255) * 256
        #net_err = (PEEK(FN_RX + 3) AND 255)
        IF #net_err <> 1 THEN fn_ok = 0
    ELSE
        #net_avail = 0
    END IF
END

' ---------------------------------------------------------------------------
' net_read: read #net_readlen bytes into FN_RX (reply payload lands there
' directly -- callers PEEK it in place, per the "never buffer in IntyBASIC
' variables" rule). fn_ok as usual.
' ---------------------------------------------------------------------------
DIM #net_readlen
' #net_gotlen: the actual byte count the RP2040/FujiNet peripheral reported
' receiving (RXLEN), captured here because the CLOSE transaction that
' follows in api_call overwrites FN_RXLEN_LO/HI with its own (always 0)
' reply length -- callers need this checked before that happens.
DIM #net_gotlen
net_read: PROCEDURE
    mb_dev = NET_DEVICEID
    mb_cmd = NETCMD_READ
    mb_nparam = 1
    pm_i = 0 : pm_size = 2 : #pm_val = #net_readlen : GOSUB fn_param
    #fn_txlen = 0
    GOSUB fn_transact
    IF fn_ok THEN
        #net_gotlen = (PEEK(FN_RXLEN_LO) AND 255) + (PEEK(FN_RXLEN_HI) AND 255) * 256
    ELSE
        #net_gotlen = 0
    END IF
END

' ---------------------------------------------------------------------------
' net_write: send fn_len bytes already staged at FN_TX out the open
' channel. The byte count rides twice -- as parameter 0 (the command's
' length argument) and as the transaction payload length -- and both come
' from fn_len here. fn_ok as usual. The three games never write to the
' network (their moves are GET query strings), but a TCP/TELNET client
' needs this, so the library carries it.
' ---------------------------------------------------------------------------
net_write: PROCEDURE
    mb_dev = NET_DEVICEID
    mb_cmd = NETCMD_WRITE
    mb_nparam = 1
    pm_i = 0 : pm_size = 2 : #pm_val = fn_len : GOSUB fn_param
    #fn_txlen = fn_len
    GOSUB fn_transact
END

' ---------------------------------------------------------------------------
' net_close
' ---------------------------------------------------------------------------
net_close: PROCEDURE
    mb_dev = NET_DEVICEID
    mb_cmd = NETCMD_CLOSE
    mb_nparam = 0
    #fn_txlen = 0
    GOSUB fn_transact
END

' ---------------------------------------------------------------------------
' api_call: full round trip -- open the URL staged at FN_TX/#fn_txlen,
' check status, read up to #net_readlen bytes (caller sets this to the max
' expected reply size, e.g. 418 for /state, 361 for /tables), close.
' Leaves fn_ok = 1 and the reply in FN_RX on success.
' ---------------------------------------------------------------------------
' ac_i/#ac_prev: loop counter and previous STATUS reading for api_call's
' stabilization poll (see below).
DIM ac_i
DIM #ac_prev
api_call: PROCEDURE
    GOSUB net_open
    IF fn_ok = 0 THEN RETURN

    ' The RP2040/ESP32 can report STATUS as soon as *some* bytes of the
    ' real internet response have arrived, well before the full response
    ' does -- open+status+read all happening within the same poll can
    ' easily race ahead of that. Rather than guess a fixed delay, poll
    ' STATUS repeatedly and treat two consecutive equal (nonzero)
    ' readings as "the download has settled" before committing to a
    ' read length. Bounded to ~20 frames (~0.33s) of polling so a
    ' genuinely stuck connection still falls through to the normal
    ' fn_ok=0/timeout handling instead of hanging here.
    #ac_prev = 0
    FOR ac_i = 0 TO 19
        WAIT
        GOSUB net_status
        IF fn_ok = 0 THEN RETURN
        IF #net_avail > 0 AND #net_avail = #ac_prev THEN EXIT FOR
        #ac_prev = #net_avail
    NEXT ac_i

    IF #net_avail < #net_readlen THEN #net_readlen = #net_avail

    GOSUB net_read
    GOSUB net_close   ' close regardless of read result
END

' ---------------------------------------------------------------------------
' AppKey. The wire struct (fujiDevice.h's `struct appkey`, packed) is 6
' bytes: creator_lo, creator_hi, app, key, mode, reserved. mode: 0=read,
' 1=write. Sending only 5 bytes (omitting reserved) leaves the firmware's
' transaction_get() blocked waiting for a byte that never arrives, which
' reads back as a timeout, not a protocol error -- easy to misdiagnose.
' appkey_open must be followed by appkey_read or appkey_write, then
' appkey_close, mirroring the C client's read_appkey()/write_appkey().
' ---------------------------------------------------------------------------
DIM ak_creator_lo, ak_creator_hi, ak_app, ak_key, ak_mode

appkey_open: PROCEDURE
    mb_dev = FUJI_DEVICEID
    mb_cmd = FUJICMD_OPEN_APPKEY
    mb_nparam = 0
    POKE (FN_TX + 0), ak_creator_lo
    POKE (FN_TX + 1), ak_creator_hi
    POKE (FN_TX + 2), ak_app
    POKE (FN_TX + 3), ak_key
    POKE (FN_TX + 4), ak_mode
    POKE (FN_TX + 5), 0 ' reserved
    #fn_txlen = 6
    GOSUB fn_transact
END

' Reads into SC_ names buffer at address #fn_src (caller sets), up to
' fn_len bytes. Actual byte count returned in fn_len after the call (from
' RXLEN); callers should NUL-terminate at that offset.
' Caller sets #fn_src (destination) and ls_max (destination buffer size,
' including room for the NUL this always writes at fn_len). Clamps to
' ls_max-1 bytes copied -- appkeys can be up to 64 bytes but destinations
' like SC_NAME are much smaller, and always NUL-terminates at fn_len so a
' short stored value doesn't leave trailing bytes undefined for callers
' (like compose_url via fn_strlen) that scan for the terminator.
appkey_read: PROCEDURE
    mb_dev = FUJI_DEVICEID
    mb_cmd = FUJICMD_READ_APPKEY
    mb_nparam = 0
    #fn_txlen = 0
    GOSUB fn_transact
    IF fn_ok THEN
        ' The rs232 transport (rs232Fuji::fujicore_read_app_key, verified
        ' against fujinet-firmware source and a live byte dump) prepends
        ' a 2-byte little-endian length ahead of the actual appkey bytes
        ' -- unlike a network READ, an appkey READ takes no length
        ' parameter, so the firmware makes the reply self-describing
        ' instead. This is specific to appkey reads on this transport;
        ' network reads carry no such prefix. RXLEN (FN_RXLEN_LO/HI)
        ' covers the prefix + data together, so use the embedded prefix
        ' itself as the real data length and skip past it.
        fn_len = (PEEK(FN_RX) AND 255) + (PEEK(FN_RX + 1) AND 255) * 256
        IF fn_len > ls_max - 1 THEN fn_len = ls_max - 1
        FOR fn_i = 0 TO fn_len - 1
            POKE (#fn_src + fn_i), PEEK(FN_RX + 2 + fn_i) AND 255
        NEXT fn_i
        POKE (#fn_src + fn_len), 0
    ELSE
        fn_len = 0
    END IF
END

' Writes fn_len bytes from #fn_src (an SC_ buffer) as the appkey payload.
appkey_write: PROCEDURE
    mb_dev = FUJI_DEVICEID
    mb_cmd = FUJICMD_WRITE_APPKEY
    mb_nparam = 0
    FOR fn_i = 0 TO fn_len - 1
        POKE (FN_TX + fn_i), PEEK(#fn_src + fn_i) AND 255
    NEXT fn_i
    #fn_txlen = fn_len
    GOSUB fn_transact
END

appkey_close: PROCEDURE
    mb_dev = FUJI_DEVICEID
    mb_cmd = FUJICMD_CLOSE_APPKEY
    mb_nparam = 0
    #fn_txlen = 0
    GOSUB fn_transact
END

' ---------------------------------------------------------------------------
' fn_putnum: append the decimal (no leading zeros) representation of pn_val
' (0-999) into FN_TX at the current #fn_txlen. IntyBASIC has no built-in
' itoa; three digits covers every value the game servers take in a URL
' (board positions, score indices, ship placements).
' ---------------------------------------------------------------------------
DIM pn_val, pn_h, pn_t, pn_o, pn_started
fn_putnum: PROCEDURE
    pn_h = pn_val / 100
    pn_t = (pn_val / 10) % 10
    pn_o = pn_val % 10
    pn_started = 0
    IF pn_h > 0 THEN
        POKE (FN_TX + #fn_txlen), pn_h + 48 : #fn_txlen = #fn_txlen + 1
        pn_started = 1
    END IF
    IF pn_t > 0 OR pn_started THEN
        POKE (FN_TX + #fn_txlen), pn_t + 48 : #fn_txlen = #fn_txlen + 1
    END IF
    POKE (FN_TX + #fn_txlen), pn_o + 48 : #fn_txlen = #fn_txlen + 1
END
```

---

## netcat.bas

The traditional closing program: a line-mode terminal. Type any `N:` devicespec on the on-screen keyboard — the same character grid FujiNet CONFIG uses for WiFi SSIDs, ported as `kbd.bas` (below) with the value display widened to a **three-row, 60-character tail-anchored window over a 256-byte buffer**, so long URLs wrap and then scroll while you type. The disc moves the highlight, the action button types the highlighted character, and the bottom row offers `SPC` `DEL` `OK` `ESC` (keypad: `0` space, `CLEAR` backspace, `ENTER` = OK).

`OK` on the URL screen dials; a failed connection keeps your text for editing, and `ESC` restores the default (tcpbin.com's echo service, so an untouched `OK` demonstrates the whole loop with no server of your own). In the terminal, the action button opens the keyboard to compose a line (`OK` sends it plus CR LF), and keypad `CLEAR` hangs up and returns to the URL screen. The terminal keeps a 200-byte shadow of its cells so it repaints intact after the keyboard has been over it; while the keyboard is open the connection is simply not polled — incoming bytes wait on the FujiNet and drain when the terminal returns.

A ready-to-build copy of this program (with `fujinet.bas` and `kbd.bas`, Makefile and jzIntv run script) lives in the `netcat` repository under `intv/`.

```basic
' netcat.bas -- a line-mode network terminal in IntyBASIC. Type any N:
' devicespec on the on-screen keyboard (the same character grid FujiNet
' CONFIG uses for WiFi SSIDs), connect, and everything the far end sends
' scrolls up rows 0-9 of the screen. The action button opens the keyboard
' again to compose a line; OK sends it (plus CR LF). The default URL is
' tcpbin.com's echo service, so an untouched OK at the URL screen gives a
' self-test needing no server of your own.
'
' URL screen:  disc + action button  pick characters on the grid
'              OK (or keypad ENTER)  connect
'              ESC                   restore the default URL
'              keypad 0 / CLEAR      space / backspace
'              The URL buffer holds 256 bytes; rows 0-2 are a 60-character
'              window that scrolls once a long URL outgrows them.
'
' Terminal:    action button         open the keyboard to compose a line
'                                    (OK sends + CR LF, ESC cancels)
'              keypad CLEAR          hang up, back to the URL screen
'
' While the keyboard is open the connection is not polled; incoming bytes
' simply wait on the FujiNet and are drained when the terminal returns.
'
' Build:  intybasic netcat.bas netcat.asm && as1600 -o netcat netcat.asm
    GOTO main

    INCLUDE "fujinet.bas"
    INCLUDE "kbd.bas"

    CONST TERM_CELLS = 200      ' rows 0-9 are the terminal
    CONST STATUS_ROW = 220      ' row 11: status + key hints

    ' Scratch RAM, ours, above fujinet.bas's buffers (which end at $917F).
    CONST SC_URL  = $9200       ' devicespec, 256 bytes (255 chars + NUL)
    CONST SC_LINE = $9300       ' composed line, 253 bytes (252 + NUL)
    CONST SC_TERM = $9400       ' 200-byte shadow of the terminal cells

' The default devicespec (24 bytes): "N:TCP://TCPBIN.COM:4242/"
lit_spec:
    DATA 78,58,84,67,80,58,47,47,84,67,80,66,73,78
    DATA 46,67,79,77,58,52,50,52,50,47
    CONST LEN_SPEC = 24

    DIM term_pos, nc_i, nc_c, nc_cr, nc_row, tc_i

' ---------------------------------------------------------------------------
' term_clear_row: blank the terminal row term_pos sits in, screen and
' shadow both -- called on entering a fresh row so wrapped-around output
' never interleaves with a stale line. Uses its own loop variable (tc_i):
' it's called from term_putc/term_newline while those run inside the
' receive loop's "FOR nc_i = 0 TO #net_gotlen - 1" in main -- reusing nc_i
' here would clobber that outer loop's counter on every line break.
' ---------------------------------------------------------------------------
term_clear_row: PROCEDURE
    nc_row = (term_pos / 20) * 20
    FOR tc_i = 0 TO 19
        #BACKTAB(nc_row + tc_i) = CS_BLACK
        POKE (SC_TERM + nc_row + tc_i), 32
    NEXT tc_i
END

' ---------------------------------------------------------------------------
' term_putc: draw ASCII nc_c at the terminal cursor, handling CR/LF and
' wrap-around, mirroring every cell into SC_TERM so the display can be
' repainted after the keyboard has been over it. GROM cards 0-94 cover
' ASCII 32-126 directly.
' ---------------------------------------------------------------------------
term_putc: PROCEDURE
    IF nc_c = 13 THEN nc_cr = 1 : GOSUB term_newline : RETURN
    IF nc_c = 10 THEN
        ' collapse the LF of a CR LF pair; a bare LF is a newline
        IF nc_cr = 0 THEN GOSUB term_newline
        nc_cr = 0
        RETURN
    END IF
    nc_cr = 0
    IF nc_c < 32 OR nc_c > 126 THEN RETURN
    #BACKTAB(term_pos) = (nc_c - 32) * 8 + COL_NORMAL
    POKE (SC_TERM + term_pos), nc_c
    term_pos = term_pos + 1
    IF term_pos >= TERM_CELLS THEN term_pos = 0
    IF (term_pos % 20) = 0 THEN GOSUB term_clear_row
END

term_newline: PROCEDURE
    term_pos = (term_pos / 20) * 20 + 20
    IF term_pos >= TERM_CELLS THEN term_pos = 0
    GOSUB term_clear_row
END

' ---------------------------------------------------------------------------
' term_init / term_repaint: reset the pane, or redraw all 200 cells from
' the shadow after the keyboard borrowed the screen.
' ---------------------------------------------------------------------------
term_init: PROCEDURE
    term_pos = 0
    nc_cr = 0
    FOR nc_i = 0 TO TERM_CELLS - 1
        POKE (SC_TERM + nc_i), 32
    NEXT nc_i
END

term_repaint: PROCEDURE
    FOR nc_i = 0 TO TERM_CELLS - 1
        nc_c = PEEK(SC_TERM + nc_i) AND 255
        IF nc_c < 32 OR nc_c > 126 THEN nc_c = 32
        #BACKTAB(nc_i) = (nc_c - 32) * 8 + COL_NORMAL
    NEXT nc_i
END

' ---------------------------------------------------------------------------
' seed_url: (re)load the default devicespec into SC_URL.
' ---------------------------------------------------------------------------
seed_url: PROCEDURE
    FOR nc_i = 0 TO LEN_SPEC - 1
        POKE (SC_URL + nc_i), PEEK(VARPTR lit_spec(0) + nc_i) AND 255
    NEXT nc_i
    POKE (SC_URL + LEN_SPEC), 0
END

' ---------------------------------------------------------------------------
' url_screen: full-screen URL editor on the character grid. Returns with
' fn_ok = 1 and the accepted devicespec NUL-terminated in SC_URL. ESC
' restores the default and keeps editing (there is nothing to cancel to).
' ---------------------------------------------------------------------------
url_screen: PROCEDURE
us_again:
    CLS
    PRINT AT STATUS_ROW COLOR COL_DIM, "TYPE URL - OK DIALS "
    #ge_dst = SC_URL
    #g_max = 256
    GOSUB grid_entry
    IF fn_ok = 0 THEN
        GOSUB seed_url
        GOTO us_again
    END IF
    IF g_len = 0 THEN
        GOSUB seed_url
        GOTO us_again
    END IF
END

' ---------------------------------------------------------------------------
' compose_line: the same grid over the terminal screen. On OK, sends the
' line plus CR LF out the open channel. Restores the terminal afterward.
' ---------------------------------------------------------------------------
compose_line: PROCEDURE
    CLS
    PRINT AT STATUS_ROW COLOR COL_DIM, "OK SENDS - ESC BACK "
    POKE SC_LINE, 0             ' fresh line every time
    #ge_dst = SC_LINE
    #g_max = 253
    GOSUB grid_entry

    IF fn_ok THEN
        #fn_txlen = 0
        #fn_src = SC_LINE : ls_max = 253 : GOSUB fn_strlen : GOSUB fn_putstr
        POKE (FN_TX + #fn_txlen), 13
        POKE (FN_TX + #fn_txlen + 1), 10
        fn_len = #fn_txlen + 2
        GOSUB net_write
    END IF

    CLS
    GOSUB term_repaint
    PRINT AT STATUS_ROW COLOR COL_DIM, "BTN TYPE - CLR URL  "
END

main:
    MODE 0, 0, 0, 0, 0 : WAIT
    CLS
    PRINT AT 0 COLOR COL_NORMAL, "FUJINET NETCAT"
    PRINT AT 40, "CONNECTING TO FUJINET"
    GOSUB fn_wait_mailbox
    IF fn_ok = 0 THEN
        PRINT AT 40, "NO CARTRIDGE MAILBOX "
        GOTO halt
    END IF
    GOSUB seed_url

dial:
    GOSUB url_screen

    ' Open the accepted devicespec: read-write, no translation (we handle
    ' CR LF ourselves).
    CLS
    PRINT AT 0 COLOR COL_NORMAL, "DIALING..."
    #fn_txlen = 0
    #fn_src = SC_URL : ls_max = 255 : GOSUB fn_strlen : GOSUB fn_putstr
    mb_dev = NET_DEVICEID
    mb_cmd = NETCMD_OPEN
    mb_nparam = 2
    pm_i = 0 : pm_size = 1 : #pm_val = OPEN_MODE_RW : GOSUB fn_param
    pm_i = 1 : pm_size = 1 : #pm_val = OPEN_TRANS_NONE : GOSUB fn_param
    GOSUB fn_transact
    IF fn_ok = 0 THEN
        PRINT AT 40 COLOR COL_ERROR, "CONNECT FAILED"
        PRINT AT 60 COLOR COL_DIM, "PRESS BUTTON TO EDIT"
con_wait:
        WAIT
        GOSUB in_poll
        IF in_btn = 0 THEN GOTO con_wait
        GOTO dial                  ' SC_URL still holds the typo -- fix it
    END IF

    CLS
    GOSUB term_init
    GOSUB term_clear_row
    PRINT AT STATUS_ROW COLOR COL_DIM, "BTN TYPE - CLR URL  "

term_loop:
    WAIT

    ' --- receive: anything waiting? read up to 64 bytes and print it ---
    GOSUB net_status
    IF fn_ok = 0 THEN
        PRINT AT STATUS_ROW COLOR COL_ERROR, "CONNECTION LOST     "
lost_wait:
        WAIT
        GOSUB in_poll
        IF in_btn = 0 THEN GOTO lost_wait
        GOSUB net_close            ' free the unit regardless
        GOTO dial
    END IF
    IF #net_avail > 0 THEN
        #net_readlen = #net_avail
        IF #net_readlen > 64 THEN #net_readlen = 64
        GOSUB net_read
        IF fn_ok THEN
            FOR nc_i = 0 TO #net_gotlen - 1
                nc_c = PEEK(FN_RX + nc_i) AND 255
                GOSUB term_putc
            NEXT nc_i
        END IF
    END IF

    ' --- input ---
    GOSUB in_poll
    IF in_btn THEN GOSUB compose_line
    IF in_key = KEYPAD_CLEAR THEN
        GOSUB net_close
        GOTO dial
    END IF
    GOTO term_loop

halt:
    WAIT
    GOTO halt
```

---

## kbd.bas

The on-screen keyboard netcat uses, ported from `fujinet-config/intv`'s `input.bas`:

```basic
' kbd.bas -- edge-detected input + on-screen character-grid keyboard,
' ported from fujinet-config/intv (input.bas + the scr_recolor helper from
' screen.bas), with one change: the value display spans THREE rows (0-2)
' instead of one, a 60-character tail-anchored window onto a buffer of up
' to 256 bytes -- long N: URLs wrap across the rows and scroll once they
' outgrow them.
'
' All 95 printable characters (32-126) fit in 6 rows x 16 columns, so the
' cursor position IS the character (ch = 32 + gy*16 + gx) -- no SHIFT/SYM
' paging. A row of action buttons (SPC/DEL/OK/ESC) sits below the grid.
' The keypad works too: 0 = space, CLEAR = backspace, ENTER = accept.
'
' grid_entry contract (same as fujinet-config's): caller sets #ge_dst
' (destination buffer) and #g_max (its size, including the NUL) BEFORE
' calling, and primes the buffer -- NUL at offset 0 for a fresh field, or
' existing NUL-terminated text to edit (it is preserved and editable).
' #ge_dst is mutated live REGARDLESS of accept or cancel. Returns fn_ok =
' 1 (OK button or keypad ENTER) or 0 (ESC button only); g_len holds the
' final length and #ge_dst is NUL-terminated there. g_len is an 8-bit
' variable, so the ceiling is #g_max = 256 (255 characters + NUL) -- one
' character shy of what the mailbox TX window could carry to an OPEN, and
' #g_max must be the 16-bit variable it is: as an 8-bit variable, 256
' would silently wrap to 0 and disable grid_append's overflow guard.
'
' Screen layout used by grid_entry (rows 9 and 11 are never touched, so
' the caller can keep hints there):
'   rows 0-2   value window (60 cells, tail-anchored, green cursor block)
'   rows 3-8   the character grid
'   row  10    SPC / DEL / OK / ESC

    ' Color-stack mode foreground colors.
    CONST CS_BLACK      = 0
    CONST CS_BLUE       = 1
    CONST CS_RED        = 2
    CONST CS_TAN        = 3
    CONST CS_DARKGREEN  = 4
    CONST CS_GREEN      = 5
    CONST CS_YELLOW     = 6
    CONST CS_WHITE      = 7

    CONST COL_NORMAL   = CS_WHITE
    CONST COL_HILIGHT  = CS_YELLOW
    CONST COL_DIM      = CS_BLUE
    CONST COL_ERROR    = CS_RED
    CONST COL_VALUE    = CS_TAN
    CONST COL_CURSOR   = CS_GREEN

    CONST SCREEN_COLS = 20
    DEF FN screenpos(aColumn, aRow) = (((aRow)*SCREEN_COLS)+(aColumn))

    ' Disc directions (as reported by in_poll).
    CONST DISC_UP     = $0004
    CONST DISC_RIGHT  = $0002
    CONST DISC_DOWN   = $0001
    CONST DISC_LEFT   = $0008

    ' Keypad, as decoded by CONT.KEY.
    CONST KEYPAD_0      = 0
    CONST KEYPAD_CLEAR  = 10
    CONST KEYPAD_ENTER  = 11
    CONST KEYPAD_NONE   = 12

    ' Grid geometry. Value rows 0-2; charset rows 3-8; actions row 10.
    CONST VAL_ROW0        = 0
    CONST VAL_ROWS        = 3
    CONST VAL_CELLS       = 60    ' VAL_ROWS * SCREEN_COLS
    CONST GRID_ROW0       = 3
    CONST GRID_COL0       = 2
    CONST GRID_ROWS       = 6
    CONST GRID_COLS       = 16
    CONST GRID_ACTION_ROW = 10
    CONST GRID_ACT_COL0   = 2    ' SPC
    CONST GRID_ACT_COL1   = 7    ' DEL
    CONST GRID_ACT_COL2   = 12   ' OK
    CONST GRID_ACT_COL3   = 17   ' ESC

    CONST IN_REPEAT_DELAY = 18   ' frames held before auto-repeat (~0.3s)
    CONST IN_REPEAT_RATE  = 6    ' frames between repeats (~0.1s)

    DIM in_disc, in_pdisc, in_rdelay
    DIM in_braw, in_btn, in_pbtn
    DIM in_key, in_pkey

' ---------------------------------------------------------------------------
' in_poll: call once per frame (after WAIT). Sets, per call:
'   in_disc - DISC_UP/DOWN/LEFT/RIGHT on a fresh press or an auto-repeat
'             tick while held; 0 otherwise.
'   in_btn  - 1 on a fresh action-button press (any of B0/B1/B2).
'   in_key  - the decoded keypad value on a fresh press, else KEYPAD_NONE.
' Uses the unqualified CONT.* pseudo-variables (both controllers OR'd).
' ---------------------------------------------------------------------------
in_poll: PROCEDURE
    in_disc = 0
    IF CONT.UP THEN in_disc = DISC_UP
    IF CONT.DOWN THEN in_disc = DISC_DOWN
    IF CONT.LEFT THEN in_disc = DISC_LEFT
    IF CONT.RIGHT THEN in_disc = DISC_RIGHT

    IF in_disc <> 0 THEN
        IF in_disc <> in_pdisc THEN
            in_rdelay = IN_REPEAT_DELAY
        ELSE
            IF in_rdelay > 0 THEN
                in_rdelay = in_rdelay - 1
                in_disc = 0
            ELSE
                in_rdelay = IN_REPEAT_RATE
            END IF
        END IF
    END IF
    in_pdisc = 0
    IF CONT.UP THEN in_pdisc = DISC_UP
    IF CONT.DOWN THEN in_pdisc = DISC_DOWN
    IF CONT.LEFT THEN in_pdisc = DISC_LEFT
    IF CONT.RIGHT THEN in_pdisc = DISC_RIGHT

    in_braw = 0
    IF CONT.B0 OR CONT.B1 OR CONT.B2 THEN in_braw = 1
    IF in_braw <> 0 AND in_pbtn = 0 THEN
        in_btn = 1
    ELSE
        in_btn = 0
    END IF
    in_pbtn = in_braw

    in_key = KEYPAD_NONE
    IF CONT.KEY <> KEYPAD_NONE AND CONT.KEY <> in_pkey THEN
        in_key = CONT.KEY
    END IF
    in_pkey = CONT.KEY
END

' ---------------------------------------------------------------------------
' grid_entry -- see the header comment for the contract.
' ---------------------------------------------------------------------------
    DIM g_x, g_y, g_px, g_py, g_len, g_ch, ga_idx
    DIM #ge_dst, #g_max
    DIM k_row, k_col, k_i, k_c, k_max, k_color
    DIM #k_word

grid_entry: PROCEDURE
    GOSUB grid_draw_charset
    GOSUB grid_draw_actions

    g_len = 0
    WHILE (g_len < #g_max - 1) AND ((PEEK(#ge_dst + g_len) AND 255) <> 0)
        g_len = g_len + 1
    WEND
    GOSUB grid_draw_value

    g_x = 0 : g_y = 0
    g_px = 255 : g_py = 255

    DO WHILE 1
        WAIT
        GOSUB grid_draw_cursor
        GOSUB in_poll

        IF in_disc = DISC_UP AND g_y > 0 THEN g_y = g_y - 1
        IF in_disc = DISC_DOWN AND g_y < GRID_ROWS THEN g_y = g_y + 1
        IF in_disc = DISC_LEFT AND g_x > 0 THEN g_x = g_x - 1
        IF in_disc = DISC_RIGHT THEN
            IF g_y = GRID_ROWS THEN
                IF g_x < 3 THEN g_x = g_x + 1
            ELSE
                IF g_x < GRID_COLS - 1 THEN g_x = g_x + 1
            END IF
        END IF
        IF g_y = GRID_ROWS AND g_x > 3 THEN g_x = 3

        IF in_key = KEYPAD_0 THEN g_ch = 32 : GOSUB grid_append
        IF in_key = KEYPAD_CLEAR THEN GOSUB grid_backspace
        IF in_key = KEYPAD_ENTER THEN
            fn_ok = 1
            EXIT DO
        END IF

        IF in_btn <> 0 THEN
            IF g_y < GRID_ROWS THEN
                g_ch = 32 + g_y * GRID_COLS + g_x
                IF g_ch <= 126 THEN GOSUB grid_append
            ELSE
                IF g_x = 0 THEN g_ch = 32 : GOSUB grid_append
                IF g_x = 1 THEN GOSUB grid_backspace
                IF g_x = 2 THEN
                    fn_ok = 1
                    EXIT DO
                END IF
                IF g_x = 3 THEN
                    fn_ok = 0
                    EXIT DO
                END IF
            END IF
        END IF
    LOOP
END

' grid_draw_charset: paints all 96 cells (95 real chars + one always-blank).
grid_draw_charset: PROCEDURE
    FOR g_y = 0 TO GRID_ROWS - 1
        FOR g_x = 0 TO GRID_COLS - 1
            g_ch = 32 + g_y * GRID_COLS + g_x
            IF g_ch > 126 THEN g_ch = 32
            #BACKTAB((GRID_ROW0 + g_y) * SCREEN_COLS + GRID_COL0 + g_x) = (g_ch - 32) * 8 + COL_VALUE
        NEXT g_x
    NEXT g_y
END

grid_draw_actions: PROCEDURE
    PRINT AT screenpos(GRID_ACT_COL0, GRID_ACTION_ROW) COLOR COL_DIM,"SPC"
    PRINT AT screenpos(GRID_ACT_COL1, GRID_ACTION_ROW) COLOR COL_DIM,"DEL"
    PRINT AT screenpos(GRID_ACT_COL2, GRID_ACTION_ROW) COLOR COL_DIM," OK"
    PRINT AT screenpos(GRID_ACT_COL3, GRID_ACTION_ROW) COLOR COL_DIM,"ESC"
END

' grid_recolor: change only the COLOR of k_max+1 already-drawn cells on row
' k_row starting at column k_col -- the glyphs underneath stay. (The
' scr_recolor helper from fujinet-config's screen.bas, renamed so a program
' including this file can keep its own s_* variables.)
grid_recolor: PROCEDURE
    FOR k_i = 0 TO k_max
        #k_word = (#BACKTAB(k_row * SCREEN_COLS + k_col + k_i) AND $FFF8) + k_color
        #BACKTAB(k_row * SCREEN_COLS + k_col + k_i) = #k_word
    NEXT k_i
END

' grid_draw_cursor: un-highlight the previous cell (g_px/g_py), highlight
' the current one (g_x/g_y). g_px=255 on the very first call skips the
' un-highlight.
grid_draw_cursor: PROCEDURE
    IF g_px <> 255 THEN
        IF g_py = GRID_ROWS THEN
            ga_idx = g_px : GOSUB grid_action_col
            k_row = GRID_ACTION_ROW : k_max = 2 : k_color = COL_DIM
            GOSUB grid_recolor
        ELSE
            g_ch = 32 + g_py * GRID_COLS + g_px
            IF g_ch > 126 THEN g_ch = 32
            #BACKTAB((GRID_ROW0 + g_py) * SCREEN_COLS + GRID_COL0 + g_px) = (g_ch - 32) * 8 + COL_VALUE
        END IF
    END IF

    IF g_y = GRID_ROWS THEN
        ga_idx = g_x : GOSUB grid_action_col
        k_row = GRID_ACTION_ROW : k_max = 2 : k_color = COL_HILIGHT
        GOSUB grid_recolor
    ELSE
        g_ch = 32 + g_y * GRID_COLS + g_x
        IF g_ch > 126 THEN g_ch = 32
        #BACKTAB((GRID_ROW0 + g_y) * SCREEN_COLS + GRID_COL0 + g_x) = (g_ch - 32) * 8 + COL_HILIGHT
    END IF

    g_px = g_x : g_py = g_y
END

' grid_action_col: given ga_idx (0-3), sets k_col to that action button's
' starting column.
grid_action_col: PROCEDURE
    IF ga_idx = 0 THEN k_col = GRID_ACT_COL0
    IF ga_idx = 1 THEN k_col = GRID_ACT_COL1
    IF ga_idx = 2 THEN k_col = GRID_ACT_COL2
    IF ga_idx = 3 THEN k_col = GRID_ACT_COL3
END

' grid_draw_value: tail-anchored 60-cell window (rows 0-2) onto #ge_dst,
' with a trailing cursor block. A value longer than 59 characters scrolls:
' the window always shows the tail, where typing is happening.
grid_draw_value: PROCEDURE
    k_i = 0
    IF g_len > VAL_CELLS - 1 THEN k_i = g_len - (VAL_CELLS - 1)
    FOR k_col = 0 TO VAL_CELLS - 1
        k_c = 32
        IF k_i + k_col < g_len THEN k_c = PEEK(#ge_dst + k_i + k_col) AND 255
        IF k_c < 32 OR k_c > 126 THEN k_c = 32
        #BACKTAB(VAL_ROW0 * SCREEN_COLS + k_col) = (k_c - 32) * 8 + COL_VALUE
    NEXT k_col
    IF g_len - k_i < VAL_CELLS THEN
        #BACKTAB(VAL_ROW0 * SCREEN_COLS + (g_len - k_i)) = (95 - 32) * 8 + COL_CURSOR
    END IF
END

grid_append: PROCEDURE
    IF g_len >= #g_max - 1 THEN RETURN
    POKE (#ge_dst + g_len), g_ch
    g_len = g_len + 1
    POKE (#ge_dst + g_len), 0
    GOSUB grid_draw_value
END

grid_backspace: PROCEDURE
    IF g_len = 0 THEN RETURN
    g_len = g_len - 1
    POKE (#ge_dst + g_len), 0
    GOSUB grid_draw_value
END
```
