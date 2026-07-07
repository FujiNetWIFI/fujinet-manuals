# Programming the FujiNet for the Atari 8-bit computers

*A programmer's guide and command reference for driving the FujiNet WiFi peripheral two ways: the **high road** — the N: handler (NDEV), from Atari BASIC and any language that speaks CIO — and the **low road** — the SIO bus itself, from 6502 assembly.*

This is the developer companion to *Getting Started with FujiNet — Owner's Guide for the Atari 400/800*. By the last section you will have written a working *netcat* in Atari BASIC. Every BASIC example takes the high road; every assembly example takes the low road.

> **Source-verified.** Every command byte, parameter, payload and error number here was read out of the FujiNet sources, not remembered: `fujinet-firmware` (`lib/bus/sio/`, `lib/device/sio/network.cpp`, `lib/device/sio/sioFuji.cpp`, `lib/device/fujiDevice.cpp`, `include/fujiCommandID.h`, `include/fujiDeviceID.h`), the N: handler `fujinet-nhandler` (`handler/src/ndev.s`), and the Action! library `NIO.ACT`. CIO/SIO facts come from the Atari 400/800 OS ROM source listing.

---

## Contents

1. [Two Roads to the FujiNet](#two-roads-to-the-fujinet)
2. [Getting the N: Handler](#getting-the-n-handler)
3. [The N: Device from BASIC](#the-n-device-from-basic)
4. [The XIO Commands (NDEV)](#the-xio-commands-ndev)
5. [Talking to SIO Directly](#talking-to-sio-directly)
6. [The Network Device — SIO Reference](#the-network-device--sio-reference)
7. [The Fuji Control Device — SIO Reference](#the-fuji-control-device--sio-reference)
8. [Telling Time](#telling-time)
9. [What NDEV Cannot Reach](#what-ndev-cannot-reach)
10. [Other Languages Through CIO](#other-languages-through-cio)
11. [FujiNet from Atari Logo](#fujinet-from-atari-logo)
12. [FujiNet in Action!](#fujinet-in-action)
13. [Error Codes](#error-codes)
14. [Command Quick Reference](#command-quick-reference)
15. [The NDEV Handler](#the-ndev-handler)
16. [netcat in Atari BASIC](#netcat-in-atari-basic)

---

## Two Roads to the FujiNet

The FujiNet is a small computer of its own — an ESP32 with WiFi — that plugs into the SIO port and presents itself as a cluster of **SIO devices**. There are two heights at which an Atari program can reach them.

* **The high road — the N: handler (NDEV).** NDEV is a CIO device handler, letter `N`, that you load into memory once. From then on the network is just another Atari device: `OPEN #1,4,0,"N:HTTP://..."`, then `INPUT`/`PRINT`/`GET`/`PUT`/`CLOSE`. Any language that speaks CIO speaks to the FujiNet.
* **The low road — the SIO bus itself.** Underneath NDEV you fill a **Device Control Block** at `$0300` and call the OS `SIOV` vector at `$E459`. This reaches the *whole* FujiNet — including the Fuji control device, which NDEV does not expose.

Take the high road for ordinary network I/O from a high-level language; take the low road for speed, for when NDEV is not present, or to reach a command NDEV cannot (mounting disks, scanning WiFi, the clock, the app-key store).

### The devices on the bus

| Device | Bus id | Reached by | What it is |
|---|---|---|---|
| Network | `$71`–`$78` | NDEV or SIO | `N1:`–`N8:` — TCP, UDP, HTTP, TNFS, FTP, SMB, SSH, TELNET |
| Fuji control | `$70` | SIO only | the device CONFIG talks to: mounts, hosts, slots, WiFi, clock, app keys |
| Clock (APETime) | `$45` | SIO only | time of day in several formats |

The Network device is really *eight* devices, one per channel: `N1:` is `$71`, `N2:` is `$72`, up to `N8:` at `$78`. The OS builds the on-wire id from the two DCB bytes `DDEVIC` and `DUNIT` — it sends `DDEVIC + DUNIT - 1` — so you set `DDEVIC` to `$71` and `DUNIT` to the channel number.

---

## Getting the N: Handler

NDEV is a small relocatable driver — an `AUTORUN.SYS` (or `NDEV.COM`) about a kilobyte long — that installs the `N:` device into the handler table (HATABS) and serves `N1:`–`N8:` until the next cold start. Three places to get it:

1. **The ready-made handler disk:** `https://apps.irata.online/Atari_8-bit/n-handler.atr`. `apps.irata.online` is directly reachable from a FujiNet **both** over HTTPS and over TNFS — add it as a host slot (the bare name `apps.irata.online`) and mount `n-handler.atr` straight off it.
2. **Any DOS disk:** every image in `https://apps.irata.online/Atari_8-bit/DOS/` carries the handler as its `AUTORUN.SYS`, so booting one installs `N:` automatically.
3. **Build it from source:** `https://github.com/FujiNetWIFI/fujinet-nhandler`, with the Atari handler under `handler/`. It is written for the MADS assembler and post-processed into a relocatable executable.

### ⚠ Important — DUP and Atari DOS 2

**NDEV cannot be used from the DUP menu of Atari DOS 2.0S, 2.0D, or 2.5.** When you return to DOS and its menu processor (`DUP.SYS`) loads, DUP inevitably overwrites the very region of memory NDEV relocated itself into — because NDEV lives just above `MEMLO`, and DUP claims that same space for its buffers. The handler is clobbered and `N:` stops answering.

This is a limitation of where DOS 2's DUP lives, not of the handler. Use `N:` from a *running* program (BASIC, an assembled binary, a language cartridge) rather than from the DOS menu; or use a DOS whose command processor leaves the handler alone (SpartaDOS, MyDOS). From within a program the handler is solid — it is only the DUP menu itself that steps on it.

---

## The N: Device from BASIC

With NDEV loaded, the network is an Atari device. Everything you know about `OPEN`, `CLOSE`, `INPUT`, `PRINT`, `GET`, `PUT` and `STATUS` applies unchanged.

### The device spec

```
Nx:SCHEME://host[:port]/path
```

`x` is the channel `1`–`8` (a bare `N:` means `N1:`). The scheme is one of `TCP`, `UDP`, `HTTP`, `HTTPS`, `TNFS`, `FTP`, `SMB`, `SSH`, `TELNET`, upper case.

### OPEN — mode and translation

`OPEN #ch,aux1,aux2,"Nx:..."` — *aux1* is the access mode, *aux2* the end-of-line translation.

| aux1 | Mode | | aux2 | Line endings |
|---|---|---|---|---|
| 4 | read (GET) | | 0 | none — binary |
| 6 | directory read | | 1 | CR |
| 8 | write (PUT) | | 2 | LF |
| 9 | append | | 3 | CR / LF |
| 12 | read / write | | | |
| 13 | HTTP POST | | | |
| 5 | HTTP DELETE | | | |

### Fetch a URL

```basic
10 DIM L$(255)
20 OPEN #1,4,2,"N:HTTP://fujinet.online/"
30 STATUS #1,S
40 IF S<>1 THEN GOTO 200
50 BW=PEEK(746)+PEEK(747)*256:REM BYTES WAITING
60 IF BW=0 THEN GOTO 30
70 INPUT #1,L$:PRINT L$:GOTO 30
200 REM  S=136 IS END OF FILE, THE NORMAL FINISH
210 CLOSE #1
```

### Reading — INPUT, GET, STATUS

`INPUT #ch,A$` reads one record (up to an EOL); `GET #ch,B` reads one byte. Before you read, ask how much is waiting. `STATUS #ch,S` runs the handler's status entry, which fills the four-byte OS status buffer **DVSTAT** at `$02EA` (decimal 746):

| PEEK | Meaning |
|---|---|
| `PEEK(746)+PEEK(747)*256` | bytes waiting to be read |
| `PEEK(748)` | connection: 1 = up, 0 = closed by far end |
| `PEEK(749)` | device error (1 = OK, **136 = end of file**) |

NDEV rides the SIO **PROCEED** interrupt (vector `$0202`) so a `GET` on an idle socket blocks politely instead of spinning.

### Writing — PRINT and PUT

`PRINT #ch;A$` writes a string and appends an EOL; a trailing `;` suppresses it; `PUT #ch,B` writes one byte. NDEV buffers writes in a 128-byte transmit buffer and sends them in bunches — see **XIO 15**, below, to flush early.

### Closing

`CLOSE #ch` flushes any buffered output, then tells the FujiNet to close the protocol. Always close what you open — there are only eight channels.

---

## The XIO Commands (NDEV)

Everything the Network device can do besides reading and writing is a CIO *special* command, issued from BASIC with `XIO cmd,#ch,aux1,aux2,"Nx:..."`.

### How XIO reaches NDEV

CIO routes any command of 14 or more to the handler's special entry, and NDEV:

1. If *cmd* is **15**, handles it itself — the put-buffer flush (below). It never reaches the wire.
2. Otherwise **asks the FujiNet** what the command expects (send, receive, or neither). If the FujiNet doesn't know the command, NDEV returns **error 146**, unimplemented.
3. If known, issues it using **the command number itself as the SIO command byte**, passing `aux1`/`aux2` through and the device-spec string as a 256-byte payload when the command sends data.

So **the XIO command number equals the SIO command byte.** `XIO 42` sends SIO command `$2A` = `*` = make-directory.

### XIO 15 — flush the put buffer

NDEV collects your `PUT`s and `PRINT`s in a 128-byte transmit buffer and sends them only when it fills, when an EOL (`$9B`) goes by, or when the channel closes. **XIO 15 sends whatever is buffered right now.** It is implemented *inside NDEV itself*; no other special command is. Use it for a prompt with no newline, or any interactive exchange where the far end is waiting on your half of a line.

```basic
10 OPEN #1,12,0,"N1:TCP://10.0.0.9:23/"
20 PRINT #1;"LOGIN: ";:REM  NO NEWLINE
30 XIO 15,#1,0,0,"N:":REM  PUSH IT OUT NOW
```

### The complete XIO command set

*cmd* is the number you give `XIO` (and the SIO command byte, in hex). Filesystem commands may be issued on any free IOCB; connection commands (parse, query, translation, channel mode, close-client, accept, flush) act on an already-`OPEN` channel.

| XIO | SIO | Char | Command — what it does |
|---|---|---|---|
| 15 | — | — | flush the transmit buffer now (handled inside NDEV) |
| 32 | `$20` | ` ` | rename a file; filespec is `"Nx:from,to"` |
| 33 | `$21` | `!` | delete a file |
| 35 | `$23` | `#` | lock a file (make read-only) |
| 36 | `$24` | `$` | unlock a file |
| 42 | `$2A` | `*` | make a directory |
| 43 | `$2B` | `+` | remove a directory |
| 44 | `$2C` | `,` | change directory (set the channel's path prefix) |
| 48 | `$30` | `0` | get current directory (reads the prefix back) |
| 65 | `$41` | `A` | TCP: accept a waiting client on a listening channel |
| 68 | `$44` | `D` | UDP: set the destination `"host:port"` for writes |
| 80 | `$50` | `P` | JSON: parse the document just read |
| 81 | `$51` | `Q` | JSON: set a query path; the value becomes readable |
| 84 | `$54` | `T` | set the translation mode (aux2 = 0/1/2/3) |
| 90 | `$5A` | `Z` | set the interrupt/status poll rate (aux1/aux2) |
| 99 | `$63` | `c` | TCP: close the current client, keep listening |
| 251 | `$FB` | — | set a JSON parameter (aux1 selects which) |
| 252 | `$FC` | — | set channel mode (aux2: 0 = protocol, 1 = JSON) |
| 253 | `$FD` | — | set the username (for FTP, SMB) — filespec is the name |
| 254 | `$FE` | — | set the password — filespec is the password |

### Working with files

```basic
10 XIO 42,#6,0,0,"N:TNFS://192.168.1.10/SAVES"
20 REM  ^ MAKE DIRECTORY /SAVES
30 XIO 32,#6,0,0,"N:TNFS://192.168.1.10/A.DAT,B.DAT"
40 REM  ^ RENAME A.DAT TO B.DAT (COMMA SEPARATES)
50 XIO 33,#6,0,0,"N:TNFS://192.168.1.10/B.DAT"
60 REM  ^ DELETE B.DAT
```

### Credentials (before OPEN)

```basic
10 XIO 253,#1,0,0,"N1:anonymous"
20 XIO 254,#1,0,0,"N1:guest@example.com"
30 OPEN #1,4,2,"N1:FTP://ftp.example.com/readme.txt"
```

### Reading JSON

FujiNet can pick a single value out of a JSON document so a BASIC program never parses braces. Suppose the resource at `status.json` returns this document:

```json
{
  "status": {
    "code": 200,
    "message": "All systems go"
  },
  "hosts": ["fujinet.online", "irata.online"]
}
```

```basic
10 DIM V$(255)
20 OPEN #1,4,0,"N:HTTPS://api.example.com/status.json"
30 XIO 252,#1,0,1,"N:":REM  CHANNEL MODE = JSON
40 XIO 80,#1,0,0,"N:":REM   PARSE THE DOCUMENT
50 XIO 81,#1,0,0,"N:/status/message":REM  QUERY PATH
60 INPUT #1,V$:PRINT V$:REM  PRINTS: ALL SYSTEMS GO
70 CLOSE #1
```

The path after the colon is a JSONPath-style selector: object members are names, array indices are numbers. Against the document above, `/status/message` selects the string `All systems go`; `/hosts/0` would select `fujinet.online`, and `/status/code` the number `200`. After `XIO 81` the value waits in the channel — read it with `INPUT` or `GET`.

### TCP servers and UDP

```basic
20 OPEN #1,12,0,"N1:TCP://:9000/":REM  NO HOST = LISTEN
30 XIO 65,#1,0,0,"N:":REM  ACCEPT A WAITING CLIENT
40 REM  ...CONVERSE...  XIO 99 DROPS THE CLIENT
70 OPEN #2,12,0,"N2:UDP://:5000/"
80 XIO 68,#2,0,0,"N2:192.168.1.50:5001":REM  AIM
90 PRINT #2;"PING"
```

---

## Talking to SIO Directly

Below NDEV is the bus itself. Every FujiNet command is, underneath, a SIO transaction: fill the DCB, call `SIOV`, read the result out of `DSTATS`.

### The Device Control Block (page three)

| Addr | Name | Holds |
|---|---|---|
| `$0300` | DDEVIC | device id — `$71` network, `$70` Fuji, `$45` clock |
| `$0301` | DUNIT | unit — the channel; the OS sends `DDEVIC+DUNIT-1` on the wire |
| `$0302` | DCOMND | command byte |
| `$0303` | DSTATS | before: data direction; after: the result code |
| `$0304` | DBUFLO/HI | buffer address (payload in or out) |
| `$0306` | DTIMLO | timeout, in seconds — `$1F` (31) is ample |
| `$0308` | DBYTLO/HI | byte count of the payload |
| `$030A` | DAUX1/2 | the two auxiliary bytes |

**DSTATS going in** sets the data direction: `$80` = Atari → FujiNet (payload sent), `$40` = FujiNet → Atari (reply read into `DBUF`), `$00` = no payload.

**DSTATS coming out** is the result: `1` success, `138` timeout, `139` NAK, `143` bad frame, `144` device error. The FujiNet's *own* errors do not appear here — `144` means "the device signalled an error," and you then issue a `STATUS` and read the extended error from the reply.

When you call `SIOV`, the OS builds a five-byte **command frame** — device id, command, aux1, aux2, checksum — and the FujiNet answers each stage with a byte: **ACK** (`$41`) or **NAK** (`$4E`) for the frame, then **COMPLETE** (`$43`) or **ERROR** (`$45`) after the work. Payload bytes flow in whichever direction `DSTATS` asked. The OS folds all of this into the `DSTATS` result.

### A reusable SIO call

```asm
DDEVIC  = $0300         ; the Device Control Block
SIOV    = $E459         ; OS serial-I/O entry
DVSTAT  = $02EA         ; 4-byte status buffer

; SIOCALL: A/Y point at a 12-byte DCB template.
;   copies it into the real DCB, calls SIOV, returns result in A.
SIOCALL sta  src+1
        sty  src+2
        ldy  #11           ; 12 bytes: $0300..$030B
copy    lda  $FFFF,y       ; src, patched just above
src     = copy+1
        sta  DDEVIC,y
        dey
        bpl  copy
        jsr  SIOV
        lda  $0303         ; DSTATS -> A
        rts
```

A DCB template is the twelve bytes in order — here, Network STATUS on N1:

```asm
;       DDEVIC DUNIT DCOMND DSTATS  DBUF   DTIM RES DBYT  DAUX
STATCB  .byte $71,$01,$53,$40 : .word DVSTAT
        .byte $1F,$00 : .word 4 : .byte $00,$00
;  lda #<STATCB : ldy #>STATCB : jsr SIOCALL
;  DVSTAT+0/+1 = bytes waiting, +2 = connected, +3 = error
```

---

## The Network Device — SIO Reference

The Network device answers at `$71` (N1:) through `$78` (N8:) — set `DDEVIC` to `$71`, `DUNIT` to the channel. These are the same bytes NDEV sends.

### OPEN — `$4F` `'O'`
Instantiate the protocol and connect. Direction `$80`. `DAUX1` = access mode, `DAUX2` = translation (Chapter 3 values). Payload is the device spec, padded to 256 bytes. **Returns** `DSTATS` = 1; on `144` read the extended error with STATUS.

### CLOSE — `$43` `'C'`
Tear the connection down. No payload, direction `$00`.

### READ — `$52` `'R'`
Receive `DAUX1`/`DAUX2` (16-bit count, low in `DAUX1`) bytes into `DBUF`. Direction `$40`. Ask STATUS first; never request more than is waiting.

### WRITE — `$57` `'W'`
Send `DAUX1`/`DAUX2` bytes from `DBUF`. Direction `$80`.

### STATUS — `$53` `'S'`
Read four bytes into `DBUF` (point at `DVSTAT`): bytes 0–1 waiting (low/high), byte 2 connection (1 up / 0 closed), byte 3 device error (1 OK, 136 EOF, else an [error code](#error-codes)).

```asm
; open N1:HTTP://.../ for read, drain to screen (COUT).
GET     lda #<OPENCB : ldy #>OPENCB : jsr SIOCALL
        bmi  GERR
LOOP    lda #<STATCB : ldy #>STATCB : jsr SIOCALL
        lda  DVSTAT+3 : cmp #136 : beq GDONE   ; end of file
        lda  DVSTAT : ora DVSTAT+1 : beq LOOP  ; nothing waiting
        ; set READ length = min(bytes waiting,128) -- omitted
        lda #<READCB : ldy #>READCB : jsr SIOCALL
        ; ... emit DBUF via COUT ...
        jmp  LOOP
GDONE   lda #<CLOSCB : ldy #>CLOSCB : jsr SIOCALL
GERR    rts
OPENCB  .byte $71,$01,$4F,$80 : .word SPEC
        .byte $1F,$00 : .word 256 : .byte $04,$02  ; read, LF
SPEC    .byte "N1:HTTP://fujinet.online/",$9B
        .res  256
```

### Filesystem commands (payload = the target spec, direction `$80`)

| Cmd | Char | Operation |
|---|---|---|
| `$21` | `!` | delete a file |
| `$20` | ` ` | rename a file (spec `"Nx:from,to"`) |
| `$23` | `#` | lock (make read-only) |
| `$24` | `$` | unlock |
| `$2A` | `*` | make directory |
| `$2B` | `+` | remove directory |
| `$2C` | `,` | change directory |
| `$30` | `0` | get current directory (direction `$40`) |

### JSON, credentials, channel mode

* **Set channel mode — `$FC`:** `DAUX2` = 0 protocol, 1 JSON.
* **Parse JSON — `$50` `'P'`:** parse the document just read. No payload.
* **Query JSON — `$51` `'Q'`:** send a JSONPath string (`$80`); the value becomes readable. `DAUX2` sets its translation.
* **Username / Password — `$FD` / `$FE`:** send the credential (`$80`) *before* OPEN.
* **Translation — `$54` `'T'`:** set the channel translation from `DAUX2`. No payload.
* **Set interrupt rate — `$5A` `'Z'`:** a 16-bit millisecond count in `DAUX1`/`DAUX2`.

### TCP and UDP

* **Accept client — `$41` `'A'`:** accept a waiting TCP client. No payload.
* **Close client — `$63` `'c'`:** drop the current client, keep listening.
* **Set UDP destination — `$44` `'D'`:** send `"host:port"` (`$80`).
* **Get UDP remote — `$72` `'r'`:** read the last sender's address (`$40`). *Low road only — see [gaps](#what-ndev-cannot-reach).*

### Inquire direction — `$FF`
Ask what direction a command uses: `DAUX1` = the command byte, reply one byte (`$00` none, `$40` read, `$80` write, `$FF` unknown). This is the call NDEV makes before every special command.

---

## The Fuji Control Device — SIO Reference

The device at `$70` is the one CONFIG talks to. **NDEV does not expose any of it** — this whole chapter is the low road only. Set `DDEVIC` to `$70`, `DUNIT` to `1`. Unlike the Network device, the Fuji device takes most small arguments in `DAUX1`/`DAUX2` and reserves the payload for bulk data.

### WiFi and the adapter

| Cmd | Operation | Parameters |
|---|---|---|
| `$FD` | scan networks | read 1 byte back = count of access points (`$40`) |
| `$FC` | get scan result | `DAUX1` = index; read 33 bytes (32-byte SSID + signed RSSI) |
| `$FB` | set SSID (join) | payload = 32-byte SSID + 64-byte password; `DAUX1` = 1 stores |
| `$FE` | get SSID | read the stored 96-byte SSID/password |
| `$FA` | get WiFi status | read 1 byte: 3 = connected, 6 = not |
| `$E8` | get adapter config | read the live config (below) |

**Get adapter config (`$E8`) reply:** SSID (32), hostname (64), local IP (4), gateway (4), netmask (4), DNS (4), MAC (6), BSSID (6), firmware version (15).

```asm
; scan, then read each access point
SCAN    lda #<SCANCB : ldy #>SCANCB : jsr SIOCALL
        lda  NBUF : sta COUNT       ; A = number of APs
        ldx  #0
SR      stx  RESCB+10               ; DAUX1 = index
        lda #<RESCB : ldy #>RESCB : jsr SIOCALL
        ; ENTRY = 32-byte SSID + 1 signed RSSI byte ...
        inx : cpx COUNT : bne SR
        rts
SCANCB  .byte $70,$01,$FD,$40 : .word NBUF
        .byte $1F,$00 : .word 1 : .byte $00,$00
RESCB   .byte $70,$01,$FC,$40 : .word ENTRY
        .byte $1F,$00 : .word 33 : .byte $00,$00
```

### Hosts and disk slots

**Host slots** (8) name where disks live; **disk slots** (8) are the drive bays `D1:`–`D8:`. Mounting is two steps: mount a host, then mount an image from it into a disk slot.

| Cmd | Operation | Parameters |
|---|---|---|
| `$F4` / `$F3` | read / write host slots | 8 × 32-byte names (256 bytes) |
| `$F2` / `$F1` | read / write device slots | 8 × 38-byte slot records |
| `$F9` / `$E6` | mount / unmount host | `DAUX1` = host slot |
| `$F8` / `$E9` | mount / unmount image | `DAUX1` = disk slot, `DAUX2` = mode (1 RO, 2 RW) |
| `$D7` | mount all | no parameters |
| `$E2` | set device filename | `DAUX1` = slot, `DAUX2` = host<<4 \| mode; payload = name |
| `$A0`–`$A9` | get device filename | `$A0` + slot; read the path (`$40`) |
| `$E7` | new (blank) disk | payload: sectors (2), sector size (2), host slot (1), disk slot (1), filename (256) |

A **device-slot record** is 38 bytes: host slot (1), access mode (1: 1 read, 2 read/write), filename (36).

```asm
MOUNT   lda #<MHOST : ldy #>MHOST : jsr SIOCALL   ; mount host
        lda #<MIMG  : ldy #>MIMG  : jsr SIOCALL   ; mount image
        rts
MHOST   .byte $70,$01,$F9,$00 : .word 0           ; DAUX1 = host slot 0
        .byte $1F,$00 : .word 0 : .byte $00,$00
MIMG    .byte $70,$01,$F8,$00 : .word 0           ; DAUX1 = disk slot 1,
        .byte $1F,$00 : .word 0 : .byte $01,$02   ; DAUX2 = 2 (R/W)
```

### Browsing a host

| Cmd | Operation | Parameters |
|---|---|---|
| `$F7` | open directory | `DAUX1` = host slot; payload = path, NUL, optional filter |
| `$F6` | read directory entry | `DAUX1` = max length, `DAUX2` = flags (`$80` appends date/size); first byte `$7F` = end |
| `$F5` | close directory | none |
| `$E5` / `$E4` | get / set directory position | paging |

### App keys — a place to keep state

Up to 64 bytes the FujiNet holds on its SD card, indexed by creator id, app id and key id.

* **Open app key — `$DC`:** payload = creator id (2, low first), app id (1), key id (1), mode (1: 0 read, 1 write).
* **Write app key — `$DE`:** after opening for write, send the data; length in `DAUX1`/`DAUX2` (16-bit).
* **Read app key — `$DD`:** after opening for read, read a 2-byte length then the data.
* **Close app key — `$DB`:** none.

### Utilities and housekeeping

| Cmd | Operation |
|---|---|
| `$FF` | reset the FujiNet |
| `$D9` / `$D6` | enable CONFIG boot / set boot mode (`DAUX1`) |
| `$D5` / `$D4` / `$D1` | enable / disable / query a device (`DAUX1` = device id) |
| `$D8` | copy a file between hosts |
| `$D3` | random number (read 4 bytes) |
| `$BB` | generate a GUID (read the 36-char string) |
| `$EB` | set SIO baud rate (`DAUX1` = index: 0 = 19200 … 6 = 921600) |
| `$E3` | set high-speed SIO index (`DAUX1` = index, `DAUX2` = 1 to save) |
| `$C8 $C7 $C6 $C5 $C2` | hash: input, compute, length, output, clear (algorithm after `$C7`: 0 MD5, 1 SHA-1, 2 SHA-256, 3 SHA-512) |
| `$D0 $CF $CE $CD` | Base64 encode: input, compute, length, output |
| `$CC $CB $CA $C9` | Base64 decode: input, compute, length, output |
| `$BC $BD $BE $BF` | QR: input, encode, length, output |

---

## Telling Time

### From the Fuji device — `$D2`

Send `$D2` to `$70`, read seven bytes:

| Off | Field |
|---|---|
| 0 | century (`$13` = 19 → 1900s, `$14` = 20 → 2000s) |
| 1 | year (0–99) |
| 2 | month (1–12) |
| 3 | day |
| 4 | hour (24-hour) |
| 5 | minute |
| 6 | second |

```asm
GETTIME lda #<TIMECB : ldy #>TIMECB : jsr SIOCALL
        ; NOW+0..6 = century, year, month, day, hour, min, sec
        rts
TIMECB  .byte $70,$01,$D2,$40 : .word NOW
        .byte $1F,$00 : .word 7 : .byte $00,$00
NOW     .res 7
```

### From the clock (APETime) device — id `$45`

FujiNet also emulates the APETime clock, which a good deal of existing Atari software understands. The command byte chooses the format: `$93` APETime binary, `$41` Atari binary, `$49` ISO-8601 local string, `$5A` ISO-8601 UTC string, `$50` ProDOS, `$99` set the time zone (payload = TZ string).

---

## What NDEV Cannot Reach

The high road is broad but not complete. Each gap is also an invitation — NDEV is open source.

* **The whole Fuji control device.** NDEV speaks only to the Network device (`$71`–`$78`). Everything on the Fuji device (`$70`) — mounting, WiFi, the clock, app keys, the browser, hashing, Base64, QR — NDEV never addresses. From BASIC there is no `XIO` that will mount a disk. *A worthy improvement:* a companion handler that surfaces the common Fuji commands as `XIO`s.
* **A handful of network sub-commands.** NDEV reaches a special command only if the FujiNet's inquiry (`$FF`) reports a known direction for it. A few are not in that table, so NDEV answers **error 146**: `$72` (UDP get remote), `$4D` (HTTP set-channel-mode/headers), `$FA` (set channel). None is fatal — the UDP sender you can read on the low road, HTTP verbs you select via the OPEN mode — but adding their rows to the firmware's inquiry table would let NDEV pass them through.
* **The 128-byte buffers.** NDEV's receive path caps a single read at 127 bytes (its buffers are 128 bytes each). A program reading through `GET`/`INPUT` never notices — the handler loops — but it cannot hand back a 512-byte block in one call the way a direct `READ` can. *An improvement:* a larger, page-aligned buffer, or a block-read command.
* **STATUS is four bytes.** The handler returns only the four `DVSTAT` bytes. Richer per-protocol status (an HTTP response code, an FTP reply line) is on the wire but not surfaced by NDEV today.

---

## Other Languages Through CIO

Nothing about NDEV is particular to Atari BASIC. It installs into the handler table, and **any language that can reach CIO can reach the FujiNet.**

* **The Assembler / Editor cartridge** (and Macro Assembler, MAC/65) assemble programs that call `CIOV` at `$E456` directly: set up an IOCB, load `X` with the IOCB number times sixteen, `JSR CIOV`. The special commands are command bytes 14+ in `ICCOM`.
* **Atari Logo** has no file words but has `.DEPOSIT`, `.EXAMINE`, `.CALL` — enough to drive an IOCB (next section).
* **And the rest** — Action!, Forth, cc65 C, Pascal — reach `N:` through CIO as BASIC does; some (Action!) skip NDEV and drive SIO.

---

## FujiNet from Atari Logo

Atari Logo is turtles and lists, but its three low-level primitives open a path to `N:`. The plan: build a three-byte stub in page six (`$0600`) that selects an IOCB and jumps to `CIOV`, then drive an IOCB with `.DEPOSIT`, calling the stub with `.CALL`.

CIO expects the IOCB number × 16 in `X`; `.CALL` enters an address with a plain `JSR` and sets no registers, so the stub sets `X` itself: `LDX #$10` (`162 16`) / `JMP $E456` (`76 86 228`).

```
TO NSETUP
  .DEPOSIT 1536 162   ; LDX #$10   (IOCB 1)
  .DEPOSIT 1537 16
  .DEPOSIT 1538 76    ; JMP $E456  (CIOV)
  .DEPOSIT 1539 86
  .DEPOSIT 1540 228
END

TO NPUTSPEC :SPEC :ADDR         ; the device spec, char by char
  IF EMPTYP :SPEC [.DEPOSIT :ADDR 155  STOP]   ; 155 = EOL
  .DEPOSIT :ADDR  ASCII FIRST :SPEC
  NPUTSPEC BUTFIRST :SPEC  :ADDR + 1
END

TO NOPEN :SPEC
  NPUTSPEC :SPEC 1280           ; device spec into $0500
  ; IOCB 1 is at $0350..$035F (848..)
  .DEPOSIT 850 3                ; ICCOM = 3 (OPEN)
  .DEPOSIT 852 0  .DEPOSIT 853 5 ; ICBAL/H = $0500
  .DEPOSIT 858 4                ; ICAX1 = 4 (read)
  .DEPOSIT 859 2                ; ICAX2 = 2 (LF)
  .CALL 1536
END

TO NGET                         ; read one byte (GET CHARACTERS)
  .DEPOSIT 850 7                ; ICCOM = 7
  .DEPOSIT 852 0  .DEPOSIT 853 5 ; ICBAL/H = $0500
  .DEPOSIT 856 1  .DEPOSIT 857 0 ; ICBLL/H = 1 byte
  .CALL 1536
  OUTPUT .EXAMINE 1280          ; the byte at $0500
END

TO NCLOSE
  .DEPOSIT 850 12              ; ICCOM = 12 (CLOSE)
  .CALL 1536
END
```

IOCB #1's control block begins at `$0350` (decimal 848): command at +2 (850), buffer address at +4/+5 (852/853), buffer length at +8/+9 (856/857), the aux bytes at +10/+11 (858/859). Change the stub's `LDX` operand (`16` for IOCB 1, `32` for 2, `48` for 3 …) to drive other channels.

---

## FujiNet in Action!

The OSS **Action!** language compiles to fast 6502 and reaches memory and the OS directly, so the natural way to use the FujiNet from Action! is the **low road** — fill the DCB, call `SIOV`, skip NDEV. The **NIO.ACT** library (in the repository's `learn/` folder, and reproduced in full in the PDF) does exactly that.

Action! names the DCB fields as `BYTE`/`CARD` variables at their page-three addresses and declares `SIOV` as a `PROC`:

```
BYTE DDEVIC = $0300   ; Device #
BYTE DUNIT  = $0301   ; Unit #
BYTE DCOMND = $0302   ; Command
BYTE DSTATS = $0303   ; direction / result
CARD DBUF   = $0304   ; buffer
BYTE DTIMLO = $0306   ; timeout secs
CARD DBYT   = $0308   ; payload length
BYTE DAUX1  = $030A
BYTE DAUX2  = $030B

PROC siov=$E459()     ; the OS SIO vector
```

Each routine is that pattern with the command byte and direction filled in — `$40` to receive, `$80` to send:

```
BYTE FUNC nopen(BYTE ARRAY ds, BYTE t)
  DDEVIC = $71
  DUNIT  = ngetunit(ds)
  DCOMND = 'O            ; OPEN
  DSTATS = $80           ; Atari -> FujiNet
  DBUF   = ds            ; the device spec
  DTIMLO = $1F
  DBYT   = 256
  DAUX1  = 12            ; read/write
  DAUX2  = t             ; translation
  siov()
RETURN (geterror(ds))

BYTE FUNC nread(BYTE ARRAY ds, BYTE ARRAY buf, CARD len)
  DDEVIC = $71
  DUNIT  = ngetunit(ds)
  DCOMND = 'R            ; READ
  DSTATS = $40           ; FujiNet -> Atari
  DBUF   = buf
  DTIMLO = $1F
  DBYT   = len
  DAUX   = len
  siov()
RETURN (geterror(ds))
```

`NIO.ACT` handles errors as NDEV does — when `DSTATS` is `144`, it issues a `STATUS` and reads the extended error from `DVSTAT+3` — and carries an optional PROCEED interrupt handler so a program can await data without a busy loop. Copy it, point `DDEVIC` at `$70`, and the Fuji control device is yours from Action! too.

---

## Error Codes

### DSTATS from a SIO call

| Code | Meaning |
|---|---|
| 1 | success |
| 138 | device timeout — nothing answered on the bus |
| 139 | device NAK — the frame was refused |
| 143 | bad frame — checksum mismatch |
| 144 | device error — the FujiNet signalled; read STATUS for the cause |

### The FujiNet's own error codes

When `DSTATS` is `144`, issue a Network `STATUS` and read byte 3 (or `PEEK(749)` through NDEV):

| Code | Name | Meaning |
|---|---|---|
| 1 | SUCCESS | no error |
| 136 | END OF FILE | the resource is fully read |
| 144 | GENERAL | a fatal device error |
| 146 | NOT IMPLEMENTED | command unknown to NDEV or the device |
| 151 | FILE EXISTS | on a make-directory or create |
| 162 | NO SPACE | the device is full |
| 165 | INVALID DEVICESPEC | the `N:` spec could not be parsed |
| 167 | ACCESS DENIED | permission refused |
| 170 | FILE NOT FOUND | no such file, or a network 404 |
| 200 | CONNECTION REFUSED | the far end refused, or is unreachable |
| 201 | NETWORK UNREACHABLE | no route to the host |
| 202 | SOCKET TIMEOUT | the connection timed out |
| 203 | NETWORK DOWN | the WiFi link is down |
| 204 | CONNECTION RESET | the far end reset the connection |
| 207 | NOT CONNECTED | operated on a closed channel |
| 208 | SERVER NOT RUNNING | a listening server returned nothing |
| 212 | BAD USER / PASSWORD | credentials rejected |
| 213 | CANNOT PARSE JSON | the document was not valid JSON |
| 255 | NO BUFFERS | the FujiNet could not allocate memory |

---

## Command Quick Reference

### Devices on the bus

| DDEVIC | DUNIT | Wire id | Device |
|---|---|---|---|
| `$71` | 1–8 | `$71`–`$78` | Network — N1: through N8: |
| `$70` | 1 | `$70` | Fuji control device |
| `$45` | 1 | `$45` | Clock (APETime) |

### BASIC / XIO summary (the high road)

| From BASIC | Does |
|---|---|
| `OPEN #ch,mode,trans,"Nx:..."` | connect (mode 4 read, 8 write, 12 r/w; trans 0/1/2/3) |
| `INPUT #ch,A$` / `GET #ch,B` | read a record / one byte |
| `PRINT #ch;A$` / `PUT #ch,B` | write a record / one byte |
| `STATUS #ch,S` | fill DVSTAT — `PEEK(746/747)` bytes, 748 conn, 749 error |
| `CLOSE #ch` | flush and disconnect |
| `XIO 15` | flush the transmit buffer now |
| `XIO 32/33/35/36` | rename / delete / lock / unlock |
| `XIO 42/43/44/48` | mkdir / rmdir / chdir / getcwd |
| `XIO 65/99` | TCP accept client / close client |
| `XIO 68` | UDP set destination |
| `XIO 80/81` | JSON parse / query |
| `XIO 84/90` | translation / interrupt rate |
| `XIO 252` | channel mode (aux2: 0 protocol, 1 JSON) |
| `XIO 253/254` | username / password |

### Network device — SIO command bytes (the low road)

| Cmd | Char | Operation |
|---|---|---|
| `$4F` | O | open connection (aux1 mode, aux2 trans, spec) |
| `$43` | C | close connection |
| `$52` | R | read waiting bytes (count in aux1/aux2) |
| `$57` | W | write bytes (count in aux1/aux2) |
| `$53` | S | channel status — 4 bytes |
| `$50` | P | JSON parse |
| `$51` | Q | JSON query |
| `$FC` | — | channel mode (aux2: 0 protocol, 1 JSON) |
| `$54` | T | set translation (aux2) |
| `$5A` | Z | set interrupt rate (aux1/aux2) |
| `$FD` / `$FE` | — | set username / password |
| `$2C` / `$30` | `,` `0` | change / get directory |
| `$20` | ` ` | rename (spec `"from,to"`) |
| `$21` `$23` `$24` | `!` `#` `$` | delete / lock / unlock |
| `$2A` / `$2B` | `*` `+` | make / remove directory |
| `$41` / `$63` | A c | TCP accept / close client |
| `$44` / `$72` | D r | UDP set destination / get remote |
| `$FF` | — | inquire a command's data direction |

### Fuji control device — SIO command bytes

| Cmd | Operation |
|---|---|
| `$FF` | reset FujiNet |
| `$FD` / `$FC` | scan networks / get scan result n |
| `$FB` / `$FE` | set / get SSID |
| `$FA` | get WiFi status |
| `$E8` / `$C4` | get adapter config / extended |
| `$F9` / `$E6` | mount / unmount host slot |
| `$F8` / `$E9` | mount / unmount disk image |
| `$D7` | mount all |
| `$F4` / `$F3` | read / write host slots |
| `$F2` / `$F1` | read / write device slots |
| `$E2` / `$A0`–`$A9` | set / get device filename |
| `$E7` | new (blank) disk |
| `$F7` `$F6` `$F5` | open / read / close directory |
| `$E5` / `$E4` | get / set directory position |
| `$DC $DD $DE $DB` | app key: open / read / write / close |
| `$D9` / `$D6` | CONFIG boot / boot mode |
| `$D5` / `$D4` / `$D1` | enable / disable / query device |
| `$D8` / `$D3` / `$BB` | copy file / random number / GUID |
| `$D2` | get time (7 bytes) |
| `$EB` / `$E3` | set baud rate / high-speed index |
| `$C8 $C7 $C6 $C5 $C2` | hash: input, compute, length, output, clear |
| `$D0 $CF $CE $CD` | Base64 encode: input, compute, length, output |
| `$CC $CB $CA $C9` | Base64 decode: input, compute, length, output |
| `$BC $BD $BE $BF` | QR: input, encode, length, output |

---

## The NDEV Handler

The complete source of the N: handler is at [`fujinet-nhandler/handler/src/ndev.s`](https://github.com/FujiNetWIFI/fujinet-nhandler/blob/master/handler/src/ndev.s), assembled with MADS, and is reproduced whole in **Appendix C of the PDF**. It is a CIO handler installed into HATABS as device `N`, with the six standard vectors — OPEN, CLOSE, GET, PUT, STATUS, SPECIAL — each built on a shared `DOSIOV` that copies a DCB template into page three and calls `SIOV`. Worth reading against Chapters 3–4: the SPECIAL routine's local handling of command 15 (flush), the inquiry (`$FF`) before every other special, the PUT buffer that flushes on EOL or when full, and the PROCEED interrupt that drives GET.

---

## netcat in Atari BASIC

A *netcat* on the high road: open a raw TCP socket, pump bytes both ways — the far end to the screen, the keyboard to the far end — until the far end hangs up or you press **BREAK**.

```basic
10 REM ===== FUJINET NETCAT (N: HANDLER) =====
20 DIM L$(255)
30 OPEN #1,12,0,"N1:TCP://192.168.1.5:9000/"
45 OPEN #2,4,0,"K:":REM  THE KEYBOARD
50 REM  --- MAIN PUMP ---
60 STATUS #1,S
70 IF PEEK(748)=0 THEN GOTO 900:REM  FAR END CLOSED
80 IF PEEK(749)=136 THEN GOTO 900:REM  EOF
90 BW=PEEK(746)+PEEK(747)*256
100 IF BW=0 THEN GOTO 200
110 REM  --- DRAIN THE SOCKET TO THE SCREEN ---
120 FOR I=1 TO BW
130 GET #1,B:PUT #16,B:REM  #16 = SCREEN (SEE BELOW)
140 NEXT I
200 REM  --- SEND A KEY IF ONE IS WAITING ---
210 IF PEEK(764)=255 THEN GOTO 60:REM  NO KEY DOWN
220 GET #2,K
230 PUT #1,K
240 XIO 15,#1,0,0,"N:":REM  FLUSH IT OUT NOW
250 GOTO 60
900 PRINT :PRINT "** CONNECTION CLOSED"
910 CLOSE #1:CLOSE #2:END
```

Three Atari touches earn their keep. `PEEK(764)` is the OS's "last key pressed" cell — `255` when nothing is down — so the pump never blocks on the keyboard while the socket has data. `XIO 15` flushes each keystroke the instant you type it, so the far end sees your typing live. And `PUT #16` is the old Atari BASIC trick for writing to the **screen editor:** BASIC multiplies the channel number by sixteen to index the IOCB, so channel 16 wraps to IOCB 0 — the `E:` editor BASIC reserves for itself and will not let you `PUT #0`. `PUT #16,B` slips a byte onto the screen through that back door.

On the other end, anything that speaks TCP will do — the classic test is the Unix `nc` itself, listening on the port you named:

```
$ nc -l 9000
HELLO FROM THE ATARI
and hello back from the laptop
the quick brown fox jumped over

** CONNECTION CLOSED
```

Type, and your keystrokes cross the room — or the world — and the reply paints onto a 1.79 MHz machine that predates the network it just joined. Fill the DCB, call the OS, read the reply; the rest is just 6502.

---

*This guide is free software, part of the [`fujinet-manuals`](https://github.com/FujiNetWIFI/fujinet-manuals) repository, released under the GNU General Public License v3. Questions? The FujiNet community answers day and night on [Discord](https://discord.gg/7MfFTvD).*
