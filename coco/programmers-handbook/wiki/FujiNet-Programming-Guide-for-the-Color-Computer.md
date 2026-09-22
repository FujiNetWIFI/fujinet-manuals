# FujiNet Programming Guide for the Color Computer

How to write programs that talk to a FujiNet from a TRS-80 Color
Computer: the two ROM vectors that carry everything, the shape of a
command, and a reference for every command the adapter answers on this
bus — in 6809 assembly and in C.

This is the wiki edition of the *FujiNet Programmer's Handbook for the
TRS-80 Color Computer*. The PDF carries the same material with a worked
example in both languages on every command, four complete programs, and
their full listings. For what lives at the far end of a URL — the
schemes the `N:` device speaks — see the
[FujiNet-Network-Protocol-Handbook](FujiNet-Network-Protocol-Handbook).

## Contents

1. [The DriveWire connection](#the-drivewire-connection)
2. [The shape of a command](#the-shape-of-a-command)
3. [First contact](#first-contact)
4. [The tools](#the-tools)
5. [Command reference: the Fuji device](#command-reference-the-fuji-device)
6. [Command reference: the network device](#command-reference-the-network-device)
7. [Command reference: the other devices](#command-reference-the-other-devices)
8. [Command reference: DriveWire itself](#command-reference-drivewire-itself)
9. [Not answered on this bus](#not-answered-on-this-bus)
10. [Error and status codes](#error-and-status-codes)
11. [Known firmware bugs](#known-firmware-bugs)
12. [FujiNet under OS-9](#fujinet-under-os-9)

---

## The DriveWire connection

The FujiNet hangs off the Color Computer's four-pin serial DIN and
answers the DriveWire protocol. Disk BASIC already knows how to talk to
a DriveWire server, so the FujiNet's own commands ride along in a
conversation the machine was already having.

Everything goes through two indirect vectors Disk BASIC leaves in ROM:

| Vector | Routine | Dragon |
|---|---|---|
| `$D93F` | `DWRead` | `$F9FE` |
| `$D941` | `DWWrite` | `$FA00` |

Both take the buffer in `X` and the count in `Y`.

* **`DWWrite`** sends `Y` bytes from `X`. `X` ends one past the last byte,
  `Y` ends zero. Everything else is preserved. No error return.
* **`DWRead`** reads `Y` bytes into `X` and gives up after about a second
  and a half. **The zero flag is set when every byte arrived** — that is
  the test you want; the carry means a framing error. `X` survives, `Y`
  comes back holding a 16-bit sum of the bytes received, and all three
  accumulators are clobbered.

```
DWREADV EQU     $D93F
DWWRITV EQU     $D941

        ldx     #BUFFER
        ldy     #LENGTH
        jsr     [DWWRITV]
```

Baud is set by the adapter's model switches, to match how many cycles
the CPU spends between bits:

| Model setting | Speed |
|---|---|
| Color Computer 1 | 38,400 |
| Color Computer 2 | 57,600 |
| Color Computer 3 | 115,200 |
| Dragon | 57,600 |
| High-speed UART cartridge | 921,600 |
| DriveWire over IP | TCP port 65504 |

### Is anybody there?

Opcode `$A5` answers with the seven characters `FUJINET` — no length, no
terminator, no command byte. A plain DriveWire server does not answer it,
so it tells a FujiNet from anything else that serves disks, and it fails
in a second and a half rather than hanging.

```c
extern byte dwread(byte *s, int l);
extern byte dwwrite(byte *s, int l);

byte fujinet_present(void)
{
    byte op = 0xA5;
    byte buf[8];

    dwwrite(&op, 1);
    if (!dwread(buf, 7))
        return 0;
    buf[7] = '\0';
    return !strcmp((char *) buf, "FUJINET");
}
```

---

## The shape of a command

There is no header, no length field, no checksum and no acknowledgement.
The adapter reads an opcode and from that opcode knows exactly how many
more bytes to take. If you and it disagree about that number the
conversation becomes nonsense from that point on, permanently.

### Two frames

```
The FujiNet control device:

  E2 | command | 0 to 3 aux bytes | payload, if any

The network device:

  E3 | unit | command | aux1 | aux2 | payload, if any
```

The network device **always consumes exactly two aux bytes**, whether the
command uses them or not. A network command with no parameters is still
five bytes on the wire. The control device has no such rule; its aux
count is per command.

The one exception is `SEEK`, whose parameter is four bytes, not two.

### Big-endian, for once

Any parameter wider than a byte goes high byte first — which is the
6809's own order, so a CMOC structure goes straight out of the door with
no swapping, no packing directives and no helper macros:

```c
struct {
    uint8_t  opcode;
    uint8_t  unit;
    uint8_t  cmd;
    uint16_t len;      /* already big-endian */
} r;

r.opcode = 0xE3;
r.unit   = unit;
r.cmd    = 'R';
r.len    = 512;

dwwrite((uint8_t *) &r, sizeof(r));
```

Four replies are little-endian, because the firmware sends a raw host
integer rather than a declared big-endian one:
`GET_DIRECTORY_POSITION`, `RANDOM_NUMBER`, the network device's `TELL`,
and the write-sector checksum. Everything else is high byte first.

### The three meta-commands

Three command bytes never reach a device; the bus answers them, and they
are the same three on `$E2` and `$E3`:

| Byte | Name | Behaviour |
|---|---|---|
| `$00` | `DEVICE_READY` | writes back `$01`. Loop until it does. |
| `$02` | `SEND_ERROR` | one byte: `$01` is success. |
| `$01` | `SEND_RESPONSE` | the reply the last command parked. You supply the count. |

### The three-step dance

```
CoCo -> E2 00              ready?
FN   -> 01                 yes
CoCo -> E2 FA              GET_WIFISTATUS
CoCo -> E2 00              ready?
FN   -> 01                 yes
CoCo -> E2 02              how did it go?
FN   -> 01                 fine
CoCo -> E2 00              ready?
FN   -> 01                 yes
CoCo -> E2 01              give it here
FN   -> 03                 connected
```

Eleven bytes to learn one, and under a millisecond at 115,200 baud.

On the network device every step carries the unit and two aux bytes, and
`SEND_RESPONSE` takes the length in its aux word and pads the reply to
it. The clock, `$E5`, skips the dance entirely: write the frame, read the
reply.

### Getting the length wrong

Pad fixed-size fields to their full size. Read exactly as many bytes as
a command's reply is. Send the aux bytes even when they are ignored. A
command that reads 256 bytes when you sent 200 takes the front of your
next command as the rest, and there is no recovery short of a reset.

### One error byte for the whole bus

The error byte and the parked response are kept once for the bus, not
once per device. Finish one command before starting another; do not send
a control-device command between a network command and its
`SEND_RESPONSE`, and do not interleave two `N:` units.

---

## First contact

`GET_ADAPTERCONFIG_EXTENDED` — `$C4`, no parameters, 240 bytes back. It
answers before the WiFi is up and its text fields spare you writing a
print-an-address routine.

```asm
        lda     #$C4
        jsr     FNCMD0          ; $E2 $C4, then the verdict
        bne     FAILED

        ldx     #CFG
        ldy     #240
        jsr     FNGRSP
        bne     FAILED
; ssid  CFG+0
; fw    CFG+125
; ip    CFG+140
```

```c
#include <cmoc.h>
#include <coco.h>
#include <fujinet-fuji.h>

int main(void)
{
    AdapterConfigExtended ac;

    putchar(12);                /* clear */
    printf("FUJINET FIRST CONTACT\n");

    if (!fuji_get_adapter_config_extended(&ac))
    {
        printf("NO ANSWER\n");
        return 1;
    }

    printf("NETWORK.. %s\n", ac.ssid);
    printf("ADDRESS.. %s\n", ac.sLocalIP);
    printf("FIRMWARE. %s\n", ac.fn_version);

    return 0;
}
```

---

## The tools

* **CMOC** — Pierre Sarrazin's C compiler for the 6809. Targets Disk
  Extended Color BASIC by default and emits a `.BIN` for `LOADM`; also
  targets OS-9.
* **LWTOOLS** — William Astle's `lwasm`, `lwlink`, `lwar`. Build with
  `lwasm --6809 --format=decb -o PROG.BIN prog.asm`.
* **Toolshed** — `decb` and `os9` for making disk images.
* **fujinet-lib** — the C client library, with a Color Computer port
  built with CMOC. A release unpacks flat: three headers, three `.inc`
  files, one `.lib`.

```
$ cmoc -Ifujinet -o WEATHER.BIN weather.c fujinet/fujinet-coco-4.7.9.lib
```

There is no shipped assembler library; the handbook develops one
(`fn.inc`, `fnlow.asm`, `fnnet.asm`, `cocoio.asm`) and prints it in full.

### Reading the return

The `fuji_` calls return a `bool` and leave the adapter's raw byte in
`fn_device_error`. The `network_` calls return a small device-agnostic
code — `FN_ERR_OK` is 0 — and leave the raw byte in the same place.
`network_read()` returns the count, or the *negative* of an error code.

---

## Command reference: the Fuji device

Device `$E2`. Frame: `E2 | command | aux | payload`. No unit byte.

Conventions: a *byte* parameter is one byte; a *word* is two, high byte
first, unless the row says otherwise. *Reply* is what `SEND_RESPONSE`
gives you and exactly how many bytes to ask for.
### 12.1 The bus answers three

| Command | Code | Frame | Aux | Payload | Reply |
|---|---|---|---|---|---|
| `DEVICE_READY` | `$00` | `E2 00` | none | none | one byte, always `$01` |
| `SEND_ERROR` | `$02` | `E2 02` | none | none | one byte: `$01` for success, otherwise a code from Appendix B |
| `SEND_RESPONSE` | `$01` | `E2 01` | none | none | as many bytes as the last command parked — you must know the count |

### 12.2 WiFi and the adapter

| Command | Code | Frame | Aux | Payload | Reply |
|---|---|---|---|---|---|
| `GET_ADAPTERCONFIG_EXTENDED` | `$C4` | `E2 C4` | none | none | 240 bytes — `ssid[33]` `hostname[64]` then the binary `localIP` `gateway` `netmask` `dnsIP` four bytes each, `mac[6]` `bssid[6]` `fn_version[15]` at offset 125, then the text forms: `sLocalIP[16]` at 140, `sGateway[16]`, `sNetmask[16]`, `sDnsIP[16]`, `sMacAddress[18]` at 204, `sBssid[18]` |
| `GET_ADAPTERCONFIG` | `$E8` | `E2 E8` | none | none | 140 bytes — the first 140 of the extended form: `ssid[33]` `hostname[64]` `localIP[4]` `gateway[4]` `netmask[4]` `dnsIP[4]` `mac[6]` `bssid[6]` `fn_version[15]` |
| `GET_WIFISTATUS` | `$FA` | `E2 FA` | none | none | one byte: `$03` connected, `$06` disconnected |
| `GET_WIFI_ENABLED` | `$EA` | `E2 EA` | none | none | one byte: non-zero if the radio is switched on |
| `SCAN_NETWORKS` | `$FD` | `E2 FD` | none | none | one byte: how many networks were found |
| `GET_SCAN_RESULT` | `$FC` | `E2 FC n` | *byte*: which result, 0 to count−1 | none | 34 bytes: `ssid[33]` then a signed `rssi` byte |
| `SET_SSID` | `$FB` | `E2 FB + 97` | none | **exactly 97 bytes**: `ssid[33]` then `password[64]`, both NUL-padded | none |
| `GET_SSID` | `$FE` | `E2 FE` | none | none | 97 bytes: `ssid[33]` then `password[64]` |

### 12.3 Hosts and prefixes

| Command | Code | Frame | Aux | Payload | Reply |
|---|---|---|---|---|---|
| `READ_HOST_SLOTS` | `$F4` | `E2 F4` | none | none | 256 bytes: eight slots of 32, each a NUL-terminated name |
| `WRITE_HOST_SLOTS` | `$F3` | `E2 F3 + 256` | none | 256 bytes: all eight slots, 32 each | none |
| `MOUNT_HOST` | `$F9` | `E2 F9 n` | *byte*: the host slot, 0 to 7 | none | none |
| `UNMOUNT_HOST` | `$E6` | `E2 E6 n` | *byte*: the host slot, 0 to 7 | none | none |
| `SET_HOST_PREFIX` | `$E1` | `E2 E1 n + 256` | *byte*: the host slot, 0 to 7 | 256 bytes: the prefix, NUL-padded | none |
| `GET_HOST_PREFIX` | `$E0` | `E2 E0 n` | *byte*: the host slot, 0 to 7 | none | 256 bytes: the prefix, NUL-terminated inside |

### 12.4 Directories

| Command | Code | Frame | Aux | Payload | Reply |
|---|---|---|---|---|---|
| `OPEN_DIRECTORY` | `$F7` | `E2 F7 n + 256` | *byte*: the host slot, 0 to 7 | 256 bytes: the path, and optionally a NUL then a filename pattern then another NUL | none |
| `READ_DIR_ENTRY` | `$F6` | `E2 F6 len flags` | *byte*: the most bytes you will accept, usually 36. <br> *byte*: flags — see below | none | as many bytes as the first aux byte said |
| `CLOSE_DIRECTORY` | `$F5` | `E2 F5` | none | none | none |
| `GET_DIRECTORY_POSITION` | `$E5` | `E2 E5` | none | none | two bytes — **low byte first** |
| `SET_DIRECTORY_POSITION` | `$E4` | `E2 E4 hi lo` | *word*: the position, **high byte first** | none | none |

### 12.5 Device slots and mounting

| Command | Code | Frame | Aux | Payload | Reply |
|---|---|---|---|---|---|
| `READ_DEVICE_SLOTS` | `$F2` | `E2 F2` | none | none | 152 bytes: four slots of 38 — host slot, mode, `file[36]` |
| `WRITE_DEVICE_SLOTS` | `$F1` | `E2 F1 + 152` | none | 152 bytes: all four slots, 38 each | none |
| `SET_DEVICE_FULLPATH` | `$E2` | `E2 E2 ds hs mode + 256` | *byte*: the drive slot, 0 to 3. <br> *byte*: the host slot, 0 to 7. <br> *byte*: mode — `$00` stores the name without opening it | 256 bytes: the file name, NUL-padded | none |
| `GET_DEVICE_FULLPATH` | `$DA` | `E2 DA n` | *byte*: the drive slot, 0 to 3 | none | 256 bytes: the full path, NUL-terminated inside |
| `MOUNT_IMAGE` | `$F8` | `E2 F8 ds mode` | *byte*: the drive slot, 0 to 3. <br> *byte*: access — `$01` read, `$02` read and write | none | none |
| `UNMOUNT_IMAGE` | `$E9` | `E2 E9 n` | *byte*: the drive slot, 0 to 3 | none | none |
| `MOUNT_ALL` | `$D7` | `E2 D7` | none | none | none |
| `NEW_DISK` | `$E7` | `E2 E7 + 259` | none | 259 bytes: disks, host slot, drive slot, then `filename[256]` | none |
| `COPY_FILE` | `$D8` | `E2 D8 src dst + 256` | *byte*: the source host slot. <br> *byte*: the destination host slot | 256 bytes: `sourcepath` NUL `destpath` NUL | none |

### 12.6 Booting and resetting

| Command | Code | Frame | Aux | Payload | Reply |
|---|---|---|---|---|---|
| `SET_BOOT_MODE` | `$D6` | `E2 D6 n` | *byte*: 0 #tt("/autorun.dsk") · 1 #tt("/mount-and-boot.dsk") · 2 the Game Lobby over TNFS · 3 #tt("/hisioboot-fujinet.dsk") | none | none |
| `CONFIG_BOOT` | `$D9` | `E2 D9 n` | *byte*: non-zero to keep the CONFIG disk, zero to stop inserting it | none | none |
| `RESET` | `$FF` | `E2 FF` | none | none | **none, and no acknowledgement** — the adapter reboots |

### 12.7 App keys

| Command | Code | Frame | Aux | Payload | Reply |
|---|---|---|---|---|---|
| `OPEN_APPKEY` | `$DC` | `E2 DC + 6` | none | 6 bytes: `creator` (word, high byte first), `app`, `key`, `mode` — 0 read, 1 write, 2 read 256 — and a reserved byte | none |
| `READ_APPKEY` | `$DD` | `E2 DD` | none | none | 66 bytes: a length (word, high byte first) then 64 bytes of data |
| `WRITE_APPKEY` | `$DE` | `E2 DE hi lo + 64` | *word*: how many bytes are meaningful, high byte first | **always 64 bytes**, whatever the length says | none |
| `CLOSE_APPKEY` | `$DB` | `E2 DB` | none | none | none |

### 12.8 Base64

| Command | Code | Frame | Aux | Payload | Reply |
|---|---|---|---|---|---|
| `BASE64_ENCODE_INPUT / DECODE_INPUT` | `$D0 / $CC` | `E2 D0 hi lo + len` | *word*: how many bytes follow, high byte first. Zero is refused | that many bytes | none |
| `BASE64_ENCODE_COMPUTE / DECODE_COMPUTE` | `$CF / $CB` | `E2 CF` | none | none | none |
| `BASE64_ENCODE_LENGTH / DECODE_LENGTH` | `$CE / $CA` | `E2 CE` | none | none | 4 bytes, **high byte first** |
| `BASE64_ENCODE_OUTPUT / DECODE_OUTPUT` | `$CD / $C9` | `E2 CD hi lo` | *word*: how many bytes to take, high byte first. Zero, or more than the buffer holds, is refused | none | that many bytes |

### 12.9 Hashing

| Command | Code | Frame | Aux | Payload | Reply |
|---|---|---|---|---|---|
| `HASH_INPUT` | `$C8` | `E2 C8 hi lo + len` | *word*: how many bytes follow, high byte first. Zero is refused | that many bytes | none |
| `HASH_COMPUTE` | `$C7` | `E2 C7 algo` | *byte*: 0 MD5 · 1 SHA-1 · 2 SHA-256 · 3 SHA-512 | none | none |
| `HASH_COMPUTE_NO_CLEAR` | `$C3` | `E2 C3 algo` | *byte*: the algorithm, as above | none | none |
| `HASH_LENGTH` | `$C6` | `E2 C6 mode` | *byte*: 1 for hexadecimal text, anything else for raw bytes | none | one byte: how long the output will be |
| `HASH_OUTPUT` | `$C5` | `E2 C5 mode` | *byte*: 1 for hexadecimal text, anything else for raw bytes | none | the hash, as many bytes as `HASH_LENGTH` said |
| `HASH_CLEAR` | `$C2` | `E2 C2` | none | none | none |

### 12.10 QR codes

| Command | Code | Frame | Aux | Payload | Reply |
|---|---|---|---|---|---|
| `QRCODE_INPUT` | `$BC` | `E2 BC hi lo + len` | *word*: how many bytes follow, high byte first | that many bytes — the text to encode | none |
| `QRCODE_ENCODE` | `$BD` | `E2 BD ver ecc short` | *byte*: version, masked to 0--127; 0 chooses one. <br> *byte*: error correction, masked to 0--3 — low, medium, quartile, high. <br> *byte*: non-zero to shorten the text through the adapter's own URL shortener first | none | none |
| `QRCODE_LENGTH` | `$BE` | `E2 BE mode` | *byte*: output mode — 0 binary · 1 ANSI · 2 bitmap · 3 SVG · 4 ATASCII · 5 PETSCII | none | 4 bytes, high byte first |
| `QRCODE_OUTPUT` | `$BF` | `E2 BF hi lo` | *word*: how many bytes to take, high byte first | none | that many bytes |

### 12.11 Odds and ends

| Command | Code | Frame | Aux | Payload | Reply |
|---|---|---|---|---|---|
| `RANDOM_NUMBER` | `$D3` | `E2 D3` | none | none | 4 bytes — **low byte first** |
| `GENERATE_GUID` | `$BB` | `E2 BB` | none | none | 37 bytes: a UUIDv4 as text, with its terminator |
| `STATUS` | `$53  'S'` | `E2 53` | none | none | 4 bytes, all zero |


---

## Command reference: the network device

Device `$E3`. Frame: `E3 | unit | command | aux1 | aux2 | payload`.

`N:` is unit 1, `N2:` through `N8:` are units 2 to 8. **Every frame
carries the unit and exactly two aux bytes**, used or not. Unrecognised
commands here fail cleanly — `SEND_ERROR` answers `$90` and the bus stays
in step.

### Open modes

| Mode | Access | HTTP method |
|---|---|---|
| `$04` | read | GET |
| `$05` | — | DELETE |
| `$06` | directory | — |
| `$07` | directory, alternate | — |
| `$08` | write | PUT |
| `$09` | append | DELETE with headers |
| `$0C` | read and write | GET with headers |
| `$0D` | — | POST |
| `$0E` | — | PUT with headers |

### Translation modes

| Mode | Line endings |
|---|---|
| `$00` | none |
| `$01` | CR — the Color Computer's own |
| `$02` | LF |
| `$03` | CR LF |
| `$04` | PETSCII |
### 13.1 The lifecycle five

| Command | Code | Frame | Aux | Payload | Reply |
|---|---|---|---|---|---|
| `OPEN` | `$4F  'O'` | `E3 unit 4F mode trans + 256` | *byte*: the open mode — `$04` read, `$06` directory, `$07` directory alternate, `$08` write, `$09` append, `$0C` read and write; for HTTP the same byte is the method. <br> *byte*: translation — `$00` none, `$01` CR, `$02` LF, `$03` CR LF, `$04` PETSCII | 256 bytes: the devicespec, NUL-padded | none |
| `CLOSE` | `$43  'C'` | `E3 unit 43 00 00` | two bytes, ignored — send zeros | none | none |
| `STATUS` | `$53  'S'` | `E3 unit 53 00 00` | two bytes, ignored | none | 4 bytes: bytes waiting (word, **high byte first**), connected, the channel's error byte |
| `READ` | `$52  'R'` | `E3 unit 52 hi lo` | *word*: how many bytes to read, high byte first | none | that many bytes, through `SEND_RESPONSE` |
| `WRITE` | `$57  'W'` | `E3 unit 57 hi lo + len` | *word*: how many bytes follow, high byte first | that many bytes | none |

### 13.2 Line discipline and position

| Command | Code | Frame | Aux | Payload | Reply |
|---|---|---|---|---|---|
| `TRANSLATION` | `$54  'T'` | `E3 unit 54 00 mode` | *byte*, ignored. <br> *byte*: the translation mode — **aux2, not aux1** | none | none |
| `SET_EOL` | `$4C  'L'` | `E3 unit 4C hi lo + len` | *word*: how many bytes of line ending follow, high byte first | that many bytes | none |
| `SET_INT_RATE` | `$5A  'Z'` | `E3 unit 5A rate 00` | *byte*: milliseconds between checks | none | none |
| `SEEK` | `$25  '%'` | `E3 unit 25 + 4` | *a four-byte offset*, high byte first — **not the usual two** | none | none |
| `TELL` | `$26  '&'` | `E3 unit 26 00 00` | two bytes, ignored | none | 4 bytes — **low byte first** |

### 13.3 Parsers and queries

| Command | Code | Frame | Aux | Payload | Reply |
|---|---|---|---|---|---|
| `SET_PARSER` | `$FC` | `E3 unit FC 00 mode` | *byte*, ignored. <br> *byte*: 0 none · 1 JSON · 2 HTML · 3 XML — **aux2, not aux1** | none | none |
| `PARSE` | `$50  'P'` | `E3 unit 50 00 00` | two bytes, ignored | none | none |
| `QUERY` | `$51  'Q'` | `E3 unit 51 00 00 + 256` | two bytes, ignored | 256 bytes: the query, NUL-padded | none directly — the result becomes the channel's contents, so ask `STATUS` and then `READ` |
| `SET_PARAMETER` | `$FB` | `E3 unit FB type value` | *byte*: 0 sets the query flags, 1 sets the parser's line ending. <br> *byte*: the value | none | none |
| `SET_HTTP_MODE` | `$4D  'M'` | `E3 unit 4D 00 mode` | *byte*, ignored. <br> *byte*: 0 body · 1 collect response headers · 2 read the collected headers · 3 set a request header · 4 set the POST data — **aux2** | none | none |

### 13.4 Filesystem operations

| Command | Code | Frame | Aux | Payload | Reply |
|---|---|---|---|---|---|
| `DELETE` | `$21  '!'` | `E3 unit 21 mode 00 + 256` | *byte*: mode, passed to the filesystem. <br> *byte*, ignored | 256 bytes: the devicespec, NUL-padded | none |
| `RENAME` | `$20` | `E3 unit 20 mode 00 + 256` | *byte*: mode. *byte*, ignored | 256 bytes: `path,newname`, NUL-padded | none |
| `LOCK / UNLOCK` | `$23  '#'  /  $24  '\$'` | `E3 unit 23 mode 00 + 256` | *byte*: mode. *byte*, ignored | 256 bytes: the devicespec | none |
| `MKDIR / RMDIR` | `$2A  '*'  /  $2B  '+'` | `E3 unit 2A mode 00 + 256` | *byte*: mode. *byte*, ignored | 256 bytes: the devicespec | none |
| `CHDIR` | `$2C  ','` | `E3 unit 2C 00 00 + 256` | two bytes, ignored | 256 bytes: the new prefix, NUL-padded | none |
| `GETCWD` | `$30  '0'` | `E3 unit 30 00 00` | two bytes, ignored | none | the prefix — ask for 256 bytes and it is zero-padded to fit |

### 13.5 Sockets and credentials

| Command | Code | Frame | Aux | Payload | Reply |
|---|---|---|---|---|---|
| `ACCEPT` | `$41  'A'` | `E3 unit 41 00 00` | two bytes, ignored | none | none |
| `CLOSE_CLIENT` | `$63  'c'` | `E3 unit 63 00 00` | two bytes, ignored | none | none |
| `GET_REMOTE` | `$72  'r'` | `E3 unit 72 00 00` | two bytes, ignored | none | 256 bytes: the remote address as text |
| `SET_DESTINATION` | `$44  'D'` | `E3 unit 44 hi lo + len` | *word*: how many bytes follow, high byte first | that many bytes: the destination, as text | none |
| `USERNAME / PASSWORD` | `$FD / $FE` | `E3 unit FD 00 00 + 256` | two bytes, ignored | 256 bytes, NUL-padded | none |


### Reading a channel

`STATUS` returns four bytes: bytes waiting (word, high byte first),
connected, and the channel's own error byte. Ask it before every read and
read **no more than** it said — the adapter pads the reply with zeros up
to the length you name.

Zero waiting is not an error; it is the usual state of a quiet socket.
The end of a resource is error **136**, or zero waiting with the
connected byte clear.

```asm
        ldx     #STBUF
        jsr     NTSTAT
        ldd     STBUF           ; big-endian, so LDD
        beq     NOTHING
        cmpd    #RXMAX
        bls     TAKEIT
        ldd     #RXMAX
TAKEIT  ldx     #RXBUF
        tfr     d,y
        jsr     NTREAD
```

---

## Command reference: the other devices

### The clock — `$E5`

**The clock is a single round trip.** The bus runs the handler first and
then rewrites the command to `SEND_RESPONSE`, so there is no
`DEVICE_READY`, no `SEND_ERROR` and no second exchange: write the frame,
read the reply.

Most read commands take an optional third byte — `$01` selects the
alternate timezone set with `$99`. Strings come back NUL-terminated.

### 14.1 The clock

| Command | Code | Frame | Aux | Payload | Reply |
|---|---|---|---|---|---|
| `GET_TIME (simple)` | `$54  'T'` | `E5 54 [alt]` | *byte*, optional: `$01` to use the alternate timezone | none | 7 bytes: century, year, month (1--12), day, hour, minute, second |
| `GET_TIME (APETIME)` | `$93` | `E5 93 [alt]` | *byte*, optional: the alternate-timezone flag | none | 6 bytes: day, month (1--12), year (two digits), hour, minute, second |
| `GET_TIME (hundredths)` | `$4D  'M'` | `E5 4D [alt]` | *byte*, optional: the alternate-timezone flag | none | 8 bytes: the seven of the simple form, then hundredths (0--99) |
| `GET_TIME (ProDOS)` | `$50  'P'` | `E5 50 [alt]` | *byte*, optional | none | 4 bytes in the ProDOS date and time format |
| `GET_TIME (SOS)` | `$53  'S'` | `E5 53 [alt]` | *byte*, optional | none | the string `YYYYMMDD0HHMMSS000` and a NUL — 19 bytes |
| `GET_TIME (ISO)` | `$49  'I'  /  $5A  'Z'` | `E5 49 [alt]` | *byte*, optional — ignored by `$5A` | none | `YYYY-MM-DDTHH:MM:SS+HHMM` and a NUL — 25 bytes |
| `GET_TZ` | `$47  'G'` | `E5 47` | none — this one takes no flag byte | none | the adapter's timezone string and a NUL |
| `SET_TZ` | `$74  't'  /  $99` | `E5 74 hi lo + len` | *word*: how many bytes of timezone follow, high byte first | that many bytes | none |

### 14.2 CP/M

| Command | Code | Frame | Aux | Payload | Reply |
|---|---|---|---|---|---|
| `CPM_BOOT` | `$42  'B'` | `E4 42` | none | none | none |
| `CPM_READ` | `$52  'R'` | `E4 52 hi lo` | *word*: how many bytes to take, high byte first | none | that many bytes from the console |
| `CPM_WRITE` | `$57  'W'` | `E4 57 hi lo + len` | *word*: how many bytes follow | that many bytes | none |
| `CPM_STATUS` | `$53  'S'` | `E4 53` | none | none | 2 bytes: how many are waiting, high byte first |

### 14.3 The printer

| Command | Code | Frame | Aux | Payload | Reply |
|---|---|---|---|---|---|
| `PRINT` | `$50  'P'` | `50 byte` | *byte*: the character to print | none | none |


### The printer

`$50` is a bus opcode, not a device: one byte per call, no command byte,
no handshake, no reply. `$46` (print flush) is accepted and ignored.

### The modem

FujiNet has a full AT-command modem and it is **not reachable from the
Color Computer** — the code compiles but nothing in this build ever
constructs it. For a terminal, open an `N:TELNET://` or `N:TCP:` channel.

---

## Command reference: DriveWire itself

Answered by the bus: no device, no command byte, no handshake.

### 15.1 Reading a sector

| Command | Code | Frame | Aux | Payload | Reply |
|---|---|---|---|---|---|
| `OP_READEX` | `$D2` | `D2 drive lsn2 lsn1 lsn0` | *byte*: the drive, 0 to 3. <br> *three bytes*: the logical sector number, **high byte first** | none | 256 bytes, then you send a 16-bit checksum **high byte first**, then one status byte comes back |

### 15.2 Writing a sector

| Command | Code | Frame | Aux | Payload | Reply |
|---|---|---|---|---|---|
| `OP_WRITE` | `$57  'W'` | `57 drive lsn2 lsn1 lsn0 + 256` | *byte*: the drive. <br> *three bytes*: the sector, high byte first | 256 bytes of data, then a 16-bit checksum **low byte first** | one status byte |

### 15.3 The clock, the short way

| Command | Code | Frame | Aux | Payload | Reply |
|---|---|---|---|---|---|
| `OP_TIME` | `$23  '#'` | `23` | none | none | 6 bytes: year minus 1900, month (1--12), day, hour, minute, second |

### 15.4 Identification and reset

| Command | Code | Frame | Aux | Payload | Reply |
|---|---|---|---|---|---|
| `OP_JEFF` | `$A5` | `A5` | none | none | the seven characters `FUJINET`, with no terminator |
| `OP_DWINIT` | `$5A  'Z'` | `5A` | none | none | one byte, always `$04` |
| `OP_RESET` | `$F8 / $FE / $FF` | `FF` | none | none | none |
| `OP_NOP` | `$00` | `00` | none | none | none |
| `OP_NAMEOBJ_MNT` | `$01` | `01 len + name` | *byte*: the length of the name | that many bytes | one byte, `$01` |

### The sector protocol

```
read    D2 drive lsn(3, high byte first)
        -> 256 bytes
        -> you send a 16-bit checksum, HIGH byte first
        <- one status byte

write   57 drive lsn(3) + 256 bytes + checksum, LOW byte first
        <- one status byte
```

The checksum is a plain 16-bit sum of the block's bytes, and `DWRead`
computes it for you — it is what it leaves in `Y`. Note the two
byte orders. Note also that **the write checksum is read and then
discarded**: the comparison is commented out in the firmware, so a
corrupted write is written.

| Status | Meaning |
|---|---|
| `$00` | success |
| `$F4` | read error |
| `$F5` | write error |
| `$F6` | invalid or inactive drive |
| 211 | past the end of the image |
| 243 | your checksum did not match (read only) |

A short write — fewer than 256 data bytes — makes the adapter discard its
input and send **no status byte at all**.

### Virtual serial channels

Sixteen queues each way. Dispatched, but nothing on the FujiNet side
fills the inbound queues today, so they are plumbing with nothing plumbed
to them.

| Opcode | Name | Reads |
|---|---|---|
| `$43` | `SERREAD` `'C'` | returns the first non-empty channel and one byte |
| `$63` | `SERREADM` `'c'` | a channel and a count |
| `$C3` | `SERWRITE` | a channel and one byte — **no bounds check on the channel** |
| `$64` | `SERWRITEM` | channel, one discarded byte, a count, then that many bytes |
| `$80`–`$8F` | `FASTWRITE` | channel is the low nybble; one data byte follows |
| `$45` | `SERINIT` `'E'` | one byte |
| `$C5` | `SERTERM` | one byte |
| `$44` | `SERGETSTAT` `'D'` | two bytes |
| `$C4` | `SERSETSTAT` | a channel and a code; code `$28` drains 26 more |

### Accepted and ignored

`$46` print flush, `$47` get status (reads two), `$53` set status (reads
two), `$49` init, `$54` terminate.

`$52` `'R'` and `$72` `'r'` are **not** dispatched — only the extended
forms `$D2` and `$F2` are. Anything else at all falls to the unhandled
path, which drains and discards the receive buffer.

---

## Not answered on this bus

### On the Fuji device — answered with silence

A command that reaches no handler does nothing, sends nothing, and —
because the dispatcher clears the error code to *success* before it looks
for a handler — reports `$01` afterwards. Worse, its aux bytes and
payload are never read and become the front of your next command.

`$F0` `ENABLE_UDPSTREAM`, `$EB` `SET_BAUDRATE`, `$E3` `SET_HSIO_INDEX`,
`$DF` `SET_SIO_EXTERNAL_CLOCK`, `$D5`/`$D4` `ENABLE`/`DISABLE_DEVICE`,
`$D2` `GET_TIME` (use `$E5` or the `$23` opcode), `$D1`
`DEVICE_ENABLE_STATUS`, `$C1` `GET_HEAP`, `$A0`–`$A9`
`GET_DEVICE1..10_FULLPATH` (use `$DA`), `$90` `UPDATE_FIRMWARE`, `$3F`
`HSIO_INDEX`, `$06`/`$15` ACK/NAK.

fujinet-lib ships Color Computer stubs for several of these that return
true without sending anything.

### On the network device — answered with an error

These fail cleanly: `SEND_ERROR` answers `$90` and the bus stays in step.

`$FF` `GET_DSTATS_VALUE`, `$FA` `SET_UNIT`, `$E3` `SET_HSIO_INDEX`,
`$81` `QUERY_ALT`, `$80` `PARSE_ALT`, `$45` `GET_ERROR`, `$3F`
`HSIO_INDEX`.

Note the sixth. Other FujiNet platforms fetch a channel's error with
`NET_GET_ERROR` `$45`; on this bus that command does not exist and the
error comes from the bus meta-command `$02` addressed to the unit. If you
are porting from an Atari or an Apple II, that is the substitution.

---

## Error and status codes

The byte `SEND_ERROR` returns.

| Code | Meaning | Code | Meaning |
|---|---|---|---|
| 1 | success | 206 | address in use |
| 131 | channel is write-only | 207 | not connected |
| 132 | invalid command | 208 | server not running |
| 135 | channel is read-only | 209 | no connection waiting |
| **136** | **end of file — not a failure** | 210 | service not available |
| 138 | general timeout | 211 | connection aborted |
| 144 | fatal error; also what a refused command sets | 212 | bad username or password |
| 146 | not implemented | 213 | could not parse the document |
| 151 | file exists | 214 | general client error |
| 162 | no space on device | 215 | general server error |
| 165 | devicespec not understood | 255 | could not allocate buffers |
| 166 | invalid seek position | | |
| 167 | access denied | | |
| 170 | file not found | | |
| 200 | connection refused | | |
| 201 | network unreachable | | |
| 202 | socket timeout | | |
| 203 | network down | | |
| 204 | connection reset | | |
| 205 | connection already in progress | | |

**136 is not a failure.** A program that treats end-of-file as an error
reports one every time it successfully reads a whole file.

### WiFi status — the reply to `$FA`

1 no SSID available · **3 connected** · 4 connection failed · 5
connection lost · **6 disconnected**

### fujinet-lib's own codes

`FN_ERR_OK` 0 · `FN_ERR_IO_ERROR` 1 · `FN_ERR_BAD_CMD` 2 ·
`FN_ERR_OFFLINE` 3 · `FN_ERR_WARNING` 4 · `FN_ERR_NO_DEVICE` 5 ·
`FN_ERR_UNKNOWN` `$FF`

The Color Computer's mapping is blunt: exactly `$01` becomes
`FN_ERR_OK`, everything else becomes `FN_ERR_IO_ERROR`. To tell
end-of-file from connection-refused, read `fn_device_error`.

---

## Known firmware bugs

Named so that somebody can fix them. When they are fixed this page is
wrong and owes an edit.

| Where | What |
|---|---|
| `COPY_FILE` `$D8` | the handler asks for its payload as a string but nothing sets the frame's data length, so the copy-spec reads empty **and your 256 bytes stay in the receive buffer**. It wedges the bus. Do not send it. |
| `SET_PARSER` `$FC` | the firmware reads the mode from **aux2**; fujinet-lib's `network_json_parse()` puts it in aux1, so it quietly selects no parser and every query comes back empty. Send the five-byte frame yourself. |
| Clock `SET_TZ` | the length is byte-swapped twice — the frame decoder converts it from big-endian and the clock handler swaps it again. A three-byte name arrives as 768 and the adapter waits for bytes that never come. Use the web interface. |
| `BASE64_*_OUTPUT`, `QRCODE_OUTPUT` | the firmware reads a two-byte length; fujinet-lib's Color Computer calls send none, so two bytes of your next command are eaten. Build the four-byte frame. |
| `fuji_unmount_host_slot()` | sends `$F9` (mount), not `$E6` (unmount). It re-mounts the slot. |
| `GET_REMOTE` `$72` | guarded `#ifndef ESP_PLATFORM` — works on FujiNet-PC, always errors on hardware. |
| `OP_SERWRITE` `$C3` | no bounds check on the channel number, where its multi-byte cousin has one. |
| `FUJI_RESET` `$FF` | reboots without bracketing the transaction, so the verdict you ask for afterwards never arrives. |
| `OP_DWINIT` `$5A` | always returns `$04`; the branch that would return the real feature set is compiled out. |

---

## FujiNet under OS-9

OS-9 boots over DriveWire perfectly well and a FujiNet is a DriveWire
server, so the disk service needs nothing from this page. Everything
else does, for one reason: **under OS-9 the Disk BASIC ROM is not
mapped**. `$D93F` and `$D941` are not vectors any more, and fujinet-lib's
Color Computer build calls through them by construction — it cannot be
linked into an OS-9 module.

Only two routines touch the hardware. Replace them and everything above
is unchanged. For the memory-mapped ports — Becker, the CoCo 3 FPGA's
DriveWire window, the high-speed UART cartridge — that is about a dozen
instructions: status at `$FF41`, data at `$FF42`, bit 1 meaning a byte is
waiting.

```asm
@byte   ldu     #$2000      ; a timeout
@wait   lda     $FF41
        bita    #$02
        bne     @got
        leau    -1,u
        bne     @wait
        bra     @timeout
@got    lda     $FF42
        sta     ,x+
        leay    -1,y
        bne     @byte
```

Two details that cost real time to find: **mask interrupts**, because the
port holds one byte and an OS-9 clock tick will take it; and **keep the
timeout**, because the retry loop above depends on `DWRead` giving up,
and a poll loop with no timeout hangs where it should retry.

For the bit-banger — which is what a FujiNet cartridge actually plugs
into — take `DWRead` and `DWWrite` from your NitrOS-9 or DriveWire
sources and put them behind those two names. They are cycle-counted
routines maintained by people with oscilloscopes and they are not
reprinted here. NitrOS-9 also has them resident, in a subroutine module a
program can `F$Link` and call at fixed offsets.

```
$ cmoc --os9 -o fnstat fnstat.c fnbus.c dwport.c
$ os9 copy fnstat /dd/CMDS/fnstat
```

---

*The FujiNet Programming Guide for the Color Computer — wiki edition. The
PDF and this page are kept in sync by hand; when the two disagree, the
firmware sources win.*
